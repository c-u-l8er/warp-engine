#!/usr/bin/env elixir

# Memory Pressure Test - Isolates memory/GC bottlenecks
# Tests how memory pressure affects performance scaling

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

IO.puts("🔧 Memory Pressure Test Configuration:")
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

# Memory-intensive workload that creates temporary objects
memory_workload = fn worker_id ->
  Enum.reduce(1..50, 0, fn _, acc ->
    # Create temporary data structures
    temp_data = Enum.map(1..100, fn i ->
      %{
        id: "#{worker_id}_#{i}",
        data: :crypto.strong_rand_bytes(200),  # 200 bytes per item
        metadata: %{
          timestamp: System.monotonic_time(:millisecond),
          worker: worker_id,
          iteration: i,
          nested: %{
            level1: %{level2: %{level3: "deep_nested_value_#{i}"}},
            array: Enum.map(1..10, &"item_#{&1}"),
            map: Enum.into(1..20, %{}, fn x -> {"key_#{x}", "value_#{x}"} end)
          }
        }
      }
    end)

    # Store some data to WarpEngine
    key = "mem_test:#{worker_id}:#{:rand.uniform(keyset)}"
    _ = WarpEngine.cosmic_put(key, temp_data)

    # Read some data back
    _ = WarpEngine.cosmic_get(key)

    # Force some garbage collection pressure
    if rem(acc, 10) == 0 do
      :erlang.garbage_collect()
    end

    acc + 1
  end)
end

# Benchmark runner
run_trial = fn procs ->
  # Record memory before
  memory_before = :erlang.memory(:total)

  # Warmup
  tasks = for i <- 1..procs do
    Task.async(fn ->
      deadline = System.monotonic_time(:millisecond) + warmup_ms
      spin = fn spin ->
        if System.monotonic_time(:millisecond) < deadline do
          _ = memory_workload.(i)
          spin.(spin)
        else
          :ok
        end
      end
      spin.(spin)
    end)
  end
  Task.await_many(tasks, warmup_ms + 10000)

  # Force GC after warmup
  :erlang.garbage_collect()
  memory_after_warmup = :erlang.memory(:total)

  # Measure
  start_time = System.monotonic_time(:millisecond)
  counters = :ets.new(:memory_counters, [:set, :public])
  :ets.insert(counters, {:ops, 0})

  tasks2 = for i <- 1..procs do
    Task.async(fn ->
      deadline = start_time + measure_ms
      spin = fn spin, local_ops ->
        if System.monotonic_time(:millisecond) < deadline do
          new_ops = memory_workload.(i)
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

  # Force GC after measurement
  :erlang.garbage_collect()
  memory_after_measure = :erlang.memory(:total)

  ops_per_sec = div(total_ops * 1000, max(duration, 1))

  %{
    ops: total_ops,
    ms: duration,
    ops_sec: ops_per_sec,
    memory_before: memory_before,
    memory_after_warmup: memory_after_warmup,
    memory_after_measure: memory_after_measure
  }
end

# Run benchmarks
IO.puts("\n🎯 Memory Pressure Performance Test")
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

  # Memory metrics
  IO.puts("   💾 Memory Metrics:")
  IO.puts("     Before: #{Float.round(best.memory_before / 1024 / 1024, 1)}MB")
  IO.puts("     After warmup: #{Float.round(best.memory_after_warmup / 1024 / 1024, 1)}MB")
  IO.puts("     After measure: #{Float.round(best.memory_after_measure / 1024 / 1024, 1)}MB")
  IO.puts("     Peak increase: #{Float.round((best.memory_after_warmup - best.memory_before) / 1024 / 1024, 1)}MB")

  # Test memory-specific metrics
  if procs >= 4 do
    IO.puts("   🔍 Memory Analysis:")

    # Check GC stats
    try do
      gc_stats = :erlang.statistics(:garbage_collection)
      IO.puts("     🗑️  GC count: #{gc_stats}")
    rescue
      _ -> IO.puts("     🗑️  GC stats unavailable")
    end

    # Check process memory
    try do
      process_memory = :erlang.memory(:processes)
      process_count = :erlang.memory(:processes_used)
      IO.puts("     🔄 Process memory: #{Float.round(process_memory / 1024 / 1024, 1)}MB (#{process_count} processes)")
    rescue
      _ -> IO.puts("     🔄 Process memory info unavailable")
    end

    # Check WSL memory pressure
    try do
      # Try to read /proc/meminfo for system memory info
      case File.read("/proc/meminfo") do
        {:ok, content} ->
          lines = String.split(content, "\n")
          mem_total = Enum.find_value(lines, "N/A", fn line ->
            if String.starts_with?(line, "MemTotal:") do
              String.replace(line, "MemTotal:", "") |> String.trim()
            end
          end)
          IO.puts("     🖥️  System memory: #{mem_total}")

        _ ->
          IO.puts("     🖥️  System memory info unavailable")
      end
    rescue
      _ -> IO.puts("     🖥️  System memory check failed")
    end
  end

  Process.sleep(1000)  # Cooldown between levels
end)

IO.puts("\n🎉 Memory Pressure Test Complete!")
IO.puts("💡 If memory pressure causes poor scaling, check:")
IO.puts("   • WSL memory limits")
IO.puts("   • Garbage collection frequency")
IO.puts("   • Process memory leaks")
IO.puts("   • System memory pressure")
