# Polished benchmark runner: warmup + steady-state, median p50/p90

# Enable bench mode for maximum performance
Application.put_env(:warp_engine, :bench_mode, true)
Application.put_env(:warp_engine, :force_ultra_fast_path, true)

# Ensure we have enough numbered shards for the benchmark
Application.put_env(:warp_engine, :use_numbered_shards, true)
Application.put_env(:warp_engine, :num_numbered_shards, 24)

IO.puts("🔧 Benchmark configuration:")
IO.puts("   bench_mode: #{Application.get_env(:warp_engine, :bench_mode)}")
IO.puts("   use_numbered_shards: #{Application.get_env(:warp_engine, :use_numbered_shards)}")
IO.puts("   num_numbered_shards: #{Application.get_env(:warp_engine, :num_numbered_shards)}")

# _workers reserved for future use (default concurrency chosen by harness)
_workers = String.to_integer(System.get_env("WORKERS") || "12")
iterations = String.to_integer(System.get_env("OPS") || "100")
trials = String.to_integer(System.get_env("TRIALS") || "2")
keyset = String.to_integer(System.get_env("KEYSET") || "5000")

concurrency_levels = case System.get_env("CONC") do
  nil -> [1, 2, 3, 4, 6, 8, 12, 16, 20, 24]
  csv -> String.split(csv, ",") |> Enum.map(&String.to_integer/1)
end

warmup_ms = String.to_integer(System.get_env("WARMUP_MS") || "2000")
measure_ms = String.to_integer(System.get_env("MEASURE_MS") || "5000")

IO.puts("\n🎯 WarpEngine Benchmark (warmup #{warmup_ms}ms, measure #{measure_ms}ms, trials #{trials})")

{:ok, _} = Application.ensure_all_started(:warp_engine)

# Define the wait function for ETS tables
wait_for_ets_tables = fn shard_count ->
  max_wait = 5000  # 5 seconds max wait
  start_time = System.monotonic_time(:millisecond)

  wait_recursive = fn wait_recursive ->
    all_tables_exist = Enum.all?(0..(shard_count - 1), fn i ->
      table_name = :"spacetime_shard_#{i}"
      :ets.whereis(table_name) != :undefined
    end)

    if all_tables_exist do
      IO.puts("✅ All #{shard_count} ETS tables are ready")
      true
    else
      elapsed = System.monotonic_time(:millisecond) - start_time
      if elapsed > max_wait do
        IO.puts("❌ Timeout waiting for ETS tables after #{elapsed}ms")
        false
      else
        Process.sleep(100)
        wait_recursive.(wait_recursive)
      end
    end
  end

  wait_recursive.(wait_recursive)
end

# Wait for ETS tables to be created in bench mode
if Application.get_env(:warp_engine, :bench_mode, false) do
  IO.puts("⏳ Waiting for ETS tables to be created...")
  shard_count = Application.get_env(:warp_engine, :num_numbered_shards, 24)
  wait_for_ets_tables.(shard_count)
end

# Prime cached state once to avoid initial GenServer contention
_ = (try do GenServer.call(WarpEngine, :get_current_state, 5000) rescue _ -> :ok end)

run_trial = fn procs ->
  # Warmup
  tasks = for i <- 1..procs do
    Task.async(fn ->
      deadline = System.monotonic_time(:millisecond) + warmup_ms
      op = fn idx ->
        key_i = rem(idx, keyset)
        WarpEngine.cosmic_put("warm:#{i}:#{key_i}", %{i: i, k: key_i})
      end
      spin = fn spin, idx ->
        if System.monotonic_time(:millisecond) < deadline do
          op.(idx)
          spin.(spin, idx + 1)
        else
          :ok
        end
      end
      spin.(spin, 0)
    end)
  end
  Task.await_many(tasks, warmup_ms + 10_000)

  # Measure
  start = System.monotonic_time(:millisecond)
  counters = :ets.new(:bench_counters, [:set, :public])
  :ets.insert(counters, {:ops, 0})

  tasks2 = for i <- 1..procs do
    Task.async(fn ->
      deadline = start + measure_ms
      chunk = min(iterations, 200)
      spin = fn spin, local_ops, idx ->
        if System.monotonic_time(:millisecond) < deadline do
          new_idx = Enum.reduce(1..chunk, idx, fn _c, acc ->
            key_i = rem(acc, keyset)
            _ = WarpEngine.cosmic_put("bench:#{i}:#{key_i}", %{i: i, k: key_i})
            acc + 1
          end)
          # No WAL operations in bench mode
          spin.(spin, local_ops + chunk, new_idx)
        else
          :ets.update_counter(counters, :ops, {2, local_ops}, {:ops, 0})
        end
      end
      spin.(spin, 0, 0)
    end)
  end
  Task.await_many(tasks2, measure_ms + 20_000)
  total_ops = :ets.lookup_element(counters, :ops, 2)
  duration = System.monotonic_time(:millisecond) - start
  :ets.delete(counters)
  ops_per_sec = div(total_ops * 1000, max(duration, 1))
  %{ops: total_ops, ms: duration, ops_sec: ops_per_sec}
end

format_stats = fn results ->
  rates = Enum.map(results, & &1.ops_sec) |> Enum.sort()
  p50 = Enum.at(rates, div(length(rates) * 50, 100))
  p90 = Enum.at(rates, min(length(rates) - 1, div(length(rates) * 90, 100)))
  median = Enum.at(rates, div(length(rates), 2))
  %{p50: p50, p90: p90, median: median}
end

Enum.each(concurrency_levels, fn procs ->
  results = for _ <- 1..trials do
    r = run_trial.(procs)
    # Cooldown between trials (no WAL operations in bench mode)
    Process.sleep(200)
    r
  end
  stats = format_stats.(results)
  best = Enum.max_by(results, & &1.ops_sec)
  IO.puts("   • #{procs} processes: best #{best.ms}ms (#{best.ops_sec} ops/sec), median #{stats.median} (p50 #{stats.p50}, p90 #{stats.p90})")
  # Cooldown + flush between levels
  _ = WarpEngine.WALCoordinator.force_flush_all()
  Process.sleep(500)
end)
