#!/usr/bin/env elixir

# Simple Operations Performance Test - Identifies physics feature overhead
# Compares basic operations vs full physics operations to find bottlenecks

require Logger
Logger.configure(level: :info)
Logger.configure_backend(:console, level: :info)

# Configuration
Application.put_env(:warp_engine, :bench_mode, false)
Application.put_env(:warp_engine, :use_numbered_shards, true)
Application.put_env(:warp_engine, :num_numbered_shards, 24)

# Ensure clean state
_ = Application.stop(:warp_engine)
Process.sleep(100)

concurrency_levels = [1, 2, 4]
warmup_ms = 2000
measure_ms = 5000
trials = 1

IO.puts("🔧 Simple Operations Performance Test")
IO.puts("=" |> String.duplicate(60))
IO.puts("🎯 Goal: Identify physics feature performance overhead")
IO.puts("📊 Comparing: Basic ops vs Full physics ops")

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

# Pre-load some test data
IO.puts("📦 Pre-loading test data...")
Enum.each(1..1000, fn i ->
  WarpEngine.cosmic_put("test:simple:#{i}", "value_#{i}")
  WarpEngine.cosmic_put("test:complex:#{i}", %{
    id: i,
    data: "complex_value_#{i}",
    metadata: %{
      physics: %{
        gravitational_mass: :rand.uniform(),
        quantum_entanglement_potential: :rand.uniform(),
        temporal_weight: :rand.uniform()
      },
      nested: %{
        level1: %{
          level2: %{
            level3: "deep_nested_value_#{i}"
          }
        }
      }
    }
  })
end)
IO.puts("✅ Test data loaded")

# Test 1: Simple operations (minimal physics)
test_simple_operations = fn worker_id ->
  Enum.reduce(1..100, 0, fn _, acc ->
    # Simple get operations
    _ = WarpEngine.cosmic_get("test:simple:#{rem(worker_id + acc, 1000) + 1}")
    acc + 1
  end)
end

# Test 2: Complex operations (full physics)
test_complex_operations = fn worker_id ->
  Enum.reduce(1..100, 0, fn _, acc ->
    # Complex get operations with physics
    _ = WarpEngine.cosmic_get("test:complex:#{rem(worker_id + acc, 1000) + 1}")
    acc + 1
  end)
end

# Test 3: Mixed operations (realistic workload)
test_mixed_operations = fn worker_id ->
  Enum.reduce(1..100, 0, fn _, acc ->
    # Mix of simple and complex
    _ = WarpEngine.cosmic_get("test:simple:#{rem(worker_id + acc, 1000) + 1}")
    _ = WarpEngine.cosmic_get("test:complex:#{rem(worker_id + acc, 1000) + 1}")
    acc + 2
  end)
end

# Benchmark runner
run_trial = fn procs, test_fn, test_name ->
  # Warmup
  tasks = for i <- 1..procs do
    Task.async(fn ->
      deadline = System.monotonic_time(:millisecond) + warmup_ms
      spin = fn spin ->
        if System.monotonic_time(:millisecond) < deadline do
          _ = test_fn.(i)
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
  counters = :ets.new(:test_counters, [:set, :public])
  :ets.insert(counters, {:ops, 0})

  tasks2 = for i <- 1..procs do
    Task.async(fn ->
      deadline = start_time + measure_ms
      spin = fn spin, local_ops ->
        if System.monotonic_time(:millisecond) < deadline do
          new_ops = test_fn.(i)
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
  %{ops: total_ops, ms: duration, ops_sec: ops_per_sec, test: test_name}
end

# Run benchmarks for each test type
IO.puts("\n🎯 Performance Comparison Tests")
IO.puts("=" |> String.duplicate(60))

test_types = [
  {test_simple_operations, "Simple Operations"},
  {test_complex_operations, "Complex Operations"},
  {test_mixed_operations, "Mixed Operations"}
]

Enum.each(test_types, fn {test_fn, test_name} ->
  IO.puts("\n🔍 Testing: #{test_name}")
  IO.puts("-" |> String.duplicate(40))

  Enum.each(concurrency_levels, fn procs ->
    IO.puts("\n== Testing with #{procs} processes ==")

    results = for trial <- 1..trials do
      IO.puts("  Trial #{trial}/#{trials}...")
      result = run_trial.(procs, test_fn, test_name)
      Process.sleep(500)
      result
    end

    # Calculate statistics
    rates = Enum.map(results, & &1.ops_sec)
    best = Enum.max_by(results, & &1.ops_sec)

    IO.puts("   • #{procs} processes: best #{best.ms}ms (#{best.ops_sec} ops/sec)")
    IO.puts("     Test type: #{test_name}")

    # Performance analysis
    case test_name do
      "Simple Operations" ->
        IO.puts("     💡 Expected: High performance (minimal physics)")
      "Complex Operations" ->
        IO.puts("     💡 Expected: Lower performance (full physics)")
      "Mixed Operations" ->
        IO.puts("     💡 Expected: Medium performance (balanced)")
    end
  end)
end)

# Final analysis
IO.puts("\n📊 PERFORMANCE ANALYSIS SUMMARY")
IO.puts("=" |> String.duplicate(60))
IO.puts("🎯 This test identifies where the performance bottleneck is:")
IO.puts("   • If Simple ops are fast but Complex ops are slow → Physics overhead")
IO.puts("   • If all ops are slow → System-wide bottleneck")
IO.puts("   • If Mixed ops are significantly slower → Coordination overhead")
IO.puts("\n💡 Expected results:")
IO.puts("   • Simple: 100,000+ ops/sec")
IO.puts("   • Complex: 10,000-50,000 ops/sec")
IO.puts("   • Mixed: 25,000-75,000 ops/sec")

Logger.info("🎉 Simple Operations Performance Test Complete!")
