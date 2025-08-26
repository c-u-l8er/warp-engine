#!/usr/bin/env elixir

# Pure WAL Performance Test - Isolates WAL bottlenecks
# Tests only cosmic_put operations to measure WAL performance scaling

require Logger
Logger.configure(level: :info)
Logger.configure_backend(:console, level: :info)

# Configuration - MUST be set before application startup
Application.put_env(:warp_engine, :bench_mode, false)
Application.put_env(:warp_engine, :use_numbered_shards, true)
Application.put_env(:warp_engine, :num_numbered_shards, 24)

# Ensure clean state by stopping any existing application
_ = Application.stop(:warp_engine)
Process.sleep(100)  # Give time for cleanup

concurrency_levels = [1, 2, 4, 6, 12, 24]
warmup_ms = 2000
measure_ms = 5000
trials = 1
keyset = 10000

IO.puts("🔧 WAL-Only Benchmark Configuration:")
IO.puts("   bench_mode: #{Application.get_env(:warp_engine, :bench_mode)}")
IO.puts("   use_numbered_shards: #{Application.get_env(:warp_engine, :use_numbered_shards)}")
IO.puts("   num_numbered_shards: #{Application.get_env(:warp_engine, :num_numbered_shards)}")
IO.puts("   Concurrency levels: #{Enum.join(concurrency_levels, ",")}")

# Start system
{:ok, _} = Application.ensure_all_started(:warp_engine)

# Wait for ETS tables
wait_for_ets_tables = fn shard_count ->
  max_wait = 10000
  start_time = System.monotonic_time(:millisecond)

  recur = fn recur ->
    ready = Enum.all?(0..(shard_count - 1), fn i ->
      :ets.whereis(:"spacetime_shard_#{i}") != :undefined
    end)

    if ready do
      elapsed = System.monotonic_time(:millisecond) - start_time
      IO.puts("✅ All #{shard_count} ETS tables ready in #{elapsed}ms")
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

IO.puts("⏳ Waiting for ETS tables...")
:ok = (wait_for_ets_tables.(24) && :ok) || :ok

# Prime the system
_ = (try do GenServer.call(WarpEngine, :get_current_state, 5000) rescue _ -> :ok end)

# Simple WAL-only workload
wal_workload = fn worker_id ->
  Enum.reduce(1..100, 0, fn _, acc ->
    key = "wal_test:#{worker_id}:#{:rand.uniform(keyset)}"
    value = %{
      worker: worker_id,
      timestamp: System.monotonic_time(:millisecond),
      data: Base.encode64(:crypto.strong_rand_bytes(100))  # Base64-encoded random data
    }

    _ = WarpEngine.cosmic_put(key, value, ultra_fast: false)
    acc + 1
  end)
end

# Benchmark runner
run_trial = fn procs ->
  # Warmup
  tasks = for i <- 1..procs do
    Task.async(fn ->
      deadline = System.monotonic_time(:millisecond) + warmup_ms
      spin = fn spin ->
        if System.monotonic_time(:millisecond) < deadline do
          _ = wal_workload.(i)
          spin.(spin)
        else
          :ok
        end
      end
      spin.(spin)
    end)
  end
  Task.await_many(tasks, warmup_ms + 10000)

  # Measure
  start_time = System.monotonic_time(:millisecond)
  counters = :ets.new(:wal_counters, [:set, :public])
  :ets.insert(counters, {:ops, 0})

  tasks2 = for i <- 1..procs do
    Task.async(fn ->
      deadline = start_time + measure_ms
      spin = fn spin, local_ops ->
        if System.monotonic_time(:millisecond) < deadline do
          new_ops = wal_workload.(i)
          spin.(spin, local_ops + new_ops)
        else
          :ets.update_counter(counters, :ops, {2, local_ops}, {:ops, 0})
          :ok
        end
      end
      spin.(spin, 0)
    end)
  end

  Task.await_many(tasks2, measure_ms + 30000)
  total_ops = :ets.lookup_element(counters, :ops, 2)
  duration = System.monotonic_time(:millisecond) - start_time
  :ets.delete(counters)

  ops_per_sec = div(total_ops * 1000, max(duration, 1))
  %{ops: total_ops, ms: duration, ops_sec: ops_per_sec}
end

# Run benchmarks
IO.puts("\n🎯 WAL-Only Performance Test")
IO.puts("=" |> String.duplicate(60))

Enum.each(concurrency_levels, fn procs ->
  IO.puts("\n== Testing with #{procs} processes ==")

  results = for trial <- 1..trials do
    IO.puts("  Trial #{trial}/#{trials}...")
    result = run_trial.(procs)
    Process.sleep(500)  # Cooldown between trials
    result
  end

  # Calculate statistics
  rates = Enum.map(results, & &1.ops_sec)
  sorted_rates = Enum.sort(rates)
  n = length(sorted_rates)
  p50 = Enum.at(sorted_rates, div(n * 50, 100))
  p90 = Enum.at(sorted_rates, min(n - 1, div(n * 90, 100)))
  median = Enum.at(sorted_rates, div(n, 2))
  best = Enum.max_by(results, & &1.ops_sec)

  IO.puts("   • #{procs} processes: best #{best.ms}ms (#{best.ops_sec} ops/sec)")
  IO.puts("     median #{median} (p50 #{p50}, p90 #{p90})")

  # Test WAL-specific metrics
  if procs >= 4 do
    IO.puts("   🔍 WAL Metrics:")

    # Check WAL file sizes
    wal_dir = "/tmp/warp_engine_data/wal"
    case File.ls(wal_dir) do
      {:ok, files} ->
        wal_files = Enum.filter(files, &String.ends_with?(&1, ".wal"))
        total_size = Enum.reduce(wal_files, 0, fn file, acc ->
          case File.stat(Path.join(wal_dir, file)) do
            {:ok, %{size: size}} -> acc + size
            _ -> acc
          end
        end)
        IO.puts("     📁 WAL files: #{length(wal_files)}, Total size: #{Float.round(total_size / 1024, 1)}KB")

      _ ->
        IO.puts("     📁 WAL directory not accessible")
    end

    # Check shard sequence counters
    try do
      shard_0_seq = WarpEngine.WALShard.get_sequence_counter(:shard_0)
      IO.puts("     🔢 Shard 0 sequence: #{shard_0_seq}")
    rescue
      _ -> IO.puts("     🔢 Shard sequence info unavailable")
    end
  end

  Process.sleep(1000)  # Cooldown between levels
end)

IO.puts("\n🎉 WAL-Only Benchmark Complete!")
IO.puts("💡 If WAL performance scales poorly, check:")
IO.puts("   • WAL file I/O bottlenecks")
IO.puts("   • Shard locking contention")
IO.puts("   • Disk I/O saturation")
