#!/usr/bin/env elixir

# Pure Shard Access Test - Isolates shard bottlenecks
# Tests only cosmic_get operations to measure shard access scaling

require Logger
Logger.configure(level: :info)
Logger.configure_backend(:console, level: :info)

# Configuration
Application.put_env(:warp_engine, :bench_mode, false)
Application.put_env(:warp_engine, :use_numbered_shards, true)
Application.put_env(:warp_engine, :num_numbered_shards, 24)

concurrency_levels = [1, 2, 4, 6, 12, 24]
warmup_ms = 2000
measure_ms = 5000
trials = 3
keyset = 10000

IO.puts("🔧 Shards-Only Benchmark Configuration:")
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

# Prime the system and pre-populate with test data
IO.puts("📦 Pre-populating shards with test data...")
Enum.each(1..keyset, fn i ->
  key = "test_key:#{i}"
  value = %{
    id: i,
    data: "test_data_#{i}",
    timestamp: System.monotonic_time(:millisecond)
  }
  WarpEngine.cosmic_put(key, value)
end)
IO.puts("✅ Pre-populated #{keyset} keys")

# Simple shard-access-only workload (read-only)
shard_workload = fn worker_id ->
  Enum.reduce(1..100, 0, fn _, acc ->
    # Random key access to test shard distribution
    key = "test_key:#{:rand.uniform(keyset)}"

    # This should hit different shards based on key hashing
    case WarpEngine.cosmic_get(key) do
      {:ok, _value, _shard_id} -> acc + 1
      _ -> acc  # Count as operation even if miss
    end
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
          _ = shard_workload.(i)
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
  counters = :ets.new(:shard_counters, [:set, :public])
  :ets.insert(counters, {:ops, 0})

  tasks2 = for i <- 1..procs do
    Task.async(fn ->
      deadline = start_time + measure_ms
      spin = fn spin, local_ops ->
        if System.monotonic_time(:millisecond) < deadline do
          new_ops = shard_workload.(i)
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
IO.puts("\n🎯 Shards-Only Performance Test")
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

  # Test shard-specific metrics
  if procs >= 4 do
    IO.puts("   🔍 Shard Metrics:")

    # Check ETS table sizes
    try do
      shard_0_size = :ets.info(:"spacetime_shard_0", :size)
      shard_12_size = :ets.info(:"spacetime_shard_12", :size)
      shard_23_size = :ets.info(:"spacetime_shard_23", :size)
      IO.puts("     📊 Shard sizes: 0=#{shard_0_size}, 12=#{shard_12_size}, 23=#{shard_23_size}")
    rescue
      _ -> IO.puts("     📊 Shard size info unavailable")
    end

    # Check memory usage
    memory = :erlang.memory(:total)
    IO.puts("     💾 Total memory: #{Float.round(memory / 1024 / 1024, 1)}MB")

    # Check process count
    process_count = :erlang.processes() |> length()
    IO.puts("     🔄 Total processes: #{process_count}")
  end

  Process.sleep(1000)  # Cooldown between levels
end)

IO.puts("\n🎉 Shards-Only Benchmark Complete!")
IO.puts("💡 If shard performance scales poorly, check:")
IO.puts("   • ETS table contention")
IO.puts("   • Process scheduling overhead")
IO.puts("   • Memory pressure and GC")
IO.puts("   • Shard distribution imbalance")
