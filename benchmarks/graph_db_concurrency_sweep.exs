#!/usr/bin/env elixir

# Graph DB Concurrency Sweep (actual WarpEngine + WeightedGraphDatabase)
# - Starts WarpEngine in bench mode with numbered shards
# - Compiles examples/weighted_graph_database.ex (uses EnhancedADT + WarpEngineIntegration)
# - Pre-generates GraphNode/GraphEdge datasets
# - Sweeps concurrency levels (1,2,3,4,6,8,12,16,20,24 or CONC env)
# - Warmups + multiple measured trials per level
# - Reports best/median/p50/p90 ops/sec

require Logger
Logger.configure(level: :info)
Logger.configure_backend(:console, level: :info)

# -------------------- Config --------------------
Application.put_env(:warp_engine, :bench_mode, true)
Application.put_env(:warp_engine, :force_ultra_fast_path, true)
Application.put_env(:warp_engine, :use_numbered_shards, true)

num_shards =
  case System.get_env("SHARDS") do
    nil -> :erlang.system_info(:schedulers_online)
    v -> String.to_integer(v)
  end

Application.put_env(:warp_engine, :num_numbered_shards, num_shards)

IO.puts("🔧 Benchmark configuration:")
IO.puts("   bench_mode: #{Application.get_env(:warp_engine, :bench_mode)}")
IO.puts("   use_numbered_shards: #{Application.get_env(:warp_engine, :use_numbered_shards)}")
IO.puts("   num_numbered_shards: #{Application.get_env(:warp_engine, :num_numbered_shards)}")

workers      = String.to_integer(System.get_env("WORKERS") || "#{num_shards}")
trials       = String.to_integer(System.get_env("TRIALS") || "5")
warmups      = String.to_integer(System.get_env("WARMUPS") || "1")
measure_ms   = String.to_integer(System.get_env("MEASURE_MS") || "4000")
warmup_ms    = String.to_integer(System.get_env("WARMUP_MS") || "2000")
keyset       = String.to_integer(System.get_env("KEYSET") || "50000")
repeat_chunk = String.to_integer(System.get_env("CHUNK") || "200")

concurrency_levels = case System.get_env("CONC") do
  nil -> [1, 2, 3, 4, 6, 8, 12, 16, 20, num_shards]
  csv -> String.split(csv, ",") |> Enum.map(&String.to_integer/1)
end

IO.puts("\n🎯 Graph DB Concurrency Sweep (warmup #{warmup_ms}ms, measure #{measure_ms}ms, trials #{trials})")
IO.puts("   Levels: #{Enum.join(concurrency_levels, ",")}")

# -------------------- Start system --------------------
{:ok, _} = Application.ensure_all_started(:warp_engine)

Logger.info("📚 Compiling WeightedGraphDatabase example...")
Code.compile_file("examples/weighted_graph_database.ex")
Logger.info("✅ WeightedGraphDatabase compiled")

# -------------------- Wait for ETS tables --------------------
wait_for_ets_tables = fn shard_count ->
  max_wait = 10_000
  start_time = System.monotonic_time(:millisecond)
  recur = fn recur ->
    ready = Enum.all?(0..(shard_count - 1), fn i ->
      :ets.whereis(:"spacetime_shard_#{i}") != :undefined
    end)
    if ready do
      IO.puts("✅ All #{shard_count} ETS tables are ready")
      true
    else
      elapsed = System.monotonic_time(:millisecond) - start_time
      if elapsed > max_wait do
        IO.puts("❌ Timeout waiting for ETS tables after #{elapsed}ms")
        false
      else
        Process.sleep(100)
        recur.(recur)
      end
    end
  end
  recur.(recur)
end

IO.puts("⏳ Waiting for ETS tables to be created...")
:ok = (wait_for_ets_tables.(num_shards) && :ok) || :ok

# Prime cached state to avoid first-call contention
_ = (try do GenServer.call(WarpEngine, :get_current_state, 5000) rescue _ -> :ok end)

# -------------------- Dataset --------------------
now_ns = fn -> System.monotonic_time(:nanosecond) end
measure_time = fn fun -> t0 = now_ns.(); res = fun.(); { (now_ns.() - t0) / 1_000_000, res } end

Logger.info("📦 Generating GraphNode/GraphEdge datasets (keyset=#{keyset})...")
{nodes_ms, nodes} = measure_time.(fn ->
  Enum.map(0..(keyset-1), fn i ->
    # Use plain ID without prefix; store_node will add "node:" internally
    WeightedGraphDatabase.GraphNode.new(
      "#{i}",
      "Node #{i}",
      %{bench: true, idx: i, attr: :erlang.phash2(i, 10)},
      :rand.uniform(),
      :rand.uniform(),
      DateTime.utc_now(),
      :bench
    )
  end)
end)

{edges_ms, edges} = measure_time.(fn ->
  Enum.map(0..(keyset-1), fn i ->
    # from/to are plain IDs; edge/store logic will add prefixes where appropriate
    from = "#{i}"
    to   = "#{rem(i+1, keyset)}"
    WeightedGraphDatabase.GraphEdge.new(
      "#{i}",
      from,
      to,
      :rand.uniform(),
      :rand.uniform(),
      :bench_rel,
      %{w: :rand.uniform()},
      DateTime.utc_now(),
      :rand.uniform()
    )
  end)
end)

Logger.info("📦 Data ready: nodes=#{Float.round(nodes_ms,1)}ms edges=#{Float.round(edges_ms,1)}ms")

# -------------------- Workloads (against real DB) --------------------
# Each op alternates between node and edge store via WeightedGraphDatabase API (uses WarpEngine under the hood)
store_chunk = fn worker_id, idx0 ->
  Enum.reduce(1..repeat_chunk, idx0, fn step, acc ->
    if rem(step, 2) == 0 do
      n = Enum.at(nodes, rem(acc, keyset))
      _ = WeightedGraphDatabase.store_node(n)
    else
      e = Enum.at(edges, rem(acc, keyset))
      _ = WeightedGraphDatabase.store_edge(e)
    end
    acc + 1
  end)
end

run_trial = fn procs ->
  # Warmup
  tasks = for i <- 1..procs do
    Task.async(fn ->
      deadline = System.monotonic_time(:millisecond) + warmup_ms
      spin = fn spin, idx ->
        if System.monotonic_time(:millisecond) < deadline do
          new_idx = store_chunk.(i, idx)
          spin.(spin, new_idx)
        else
          :ok
        end
      end
      spin.(spin, 0)
    end)
  end
  Task.await_many(tasks, warmup_ms + 20_000)

  # Measure
  start_time = System.monotonic_time(:millisecond)
  counters = :ets.new(:bench_counters, [:set, :public])
  :ets.insert(counters, {:ops, 0})

  tasks2 = for i <- 1..procs do
    Task.async(fn ->
      deadline = start_time + measure_ms
      spin = fn spin, local_ops, idx ->
        if System.monotonic_time(:millisecond) < deadline do
          new_idx = store_chunk.(i, idx)
          spin.(spin, local_ops + repeat_chunk, new_idx)
        else
          :ets.update_counter(counters, :ops, {2, local_ops}, {:ops, 0})
        end
      end
      spin.(spin, 0, 0)
    end)
  end
  Task.await_many(tasks2, measure_ms + 30_000)
  total_ops = :ets.lookup_element(counters, :ops, 2)
  duration  = System.monotonic_time(:millisecond) - start_time
  :ets.delete(counters)
  ops_per_sec = div(total_ops * 1000, max(duration, 1))
  %{ops: total_ops, ms: duration, ops_sec: ops_per_sec}
end

format_stats = fn results ->
  rates = results |> Enum.map(& &1.ops_sec) |> Enum.sort()
  n = length(rates)
  p50 = Enum.at(rates, div(n * 50, 100))
  p90 = Enum.at(rates, min(n - 1, div(n * 90, 100)))
  median = Enum.at(rates, div(n, 2))
  %{p50: p50, p90: p90, median: median}
end

Enum.each(concurrency_levels, fn procs ->
  results = for _ <- 1..trials do
    r = run_trial.(procs)
    Process.sleep(200)
    r
  end
  stats = format_stats.(results)
  best = Enum.max_by(results, & &1.ops_sec)
  IO.puts("   • #{procs} processes: best #{best.ms}ms (#{best.ops_sec} ops/sec), median #{stats.median} (p50 #{stats.p50}, p90 #{stats.p90})")

  # Force flush all WAL data to ensure clean state
  if Process.whereis(WarpEngine.WAL) do
    WarpEngine.WAL.force_flush()
  end

  Process.sleep(500)
end)
