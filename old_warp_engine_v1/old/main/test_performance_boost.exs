#!/usr/bin/env elixir

# Quick Performance Test for GenServer Bypass Optimization
# This test validates that our Phase 1 optimizations are working

Mix.install([
  {:jason, "~> 1.4"}
])

Code.prepend_path("lib")

# Load required modules
Code.require_file("lib/warp_engine/cosmic_constants.ex")
Code.require_file("lib/warp_engine/cosmic_persistence.ex")
Code.require_file("lib/warp_engine/wal_entry.ex")
Code.require_file("lib/warp_engine/wal.ex")
Code.require_file("lib/warp_engine/wal_operations.ex")
Code.require_file("lib/warp_engine/quantum_index.ex")
Code.require_file("lib/warp_engine/gravitational_router.ex")
Code.require_file("lib/warp_engine/spacetime_shard.ex")
Code.require_file("lib/warp_engine/event_horizon_cache.ex")
Code.require_file("lib/warp_engine/entropy_monitor.ex")
Code.require_file("lib/warp_engine.ex")

IO.puts """
🚀 WarpEngine Phase 1 Optimization Validation Test
════════════════════════════════════════════════

Testing GenServer bypass optimization for cosmic_put/get operations.
Expected improvement: 20-50x performance boost from Phase 1 optimizations.

Previous benchmark: 3,104 PUT ops/sec, 5,403 GET ops/sec
Target after Phase 1: 60,000-150,000 PUT ops/sec

Running quick performance validation...
"""

try do
  # Start WarpEngine with WAL enabled
  IO.puts "🌌 Starting WarpEngine with WAL optimizations..."
  {:ok, _pid} = WarpEngine.start_link([
    enable_wal: true,
    data_root: "/tmp/performance_test"
  ])

  # Wait for full initialization
  :timer.sleep(2000)

  # Quick PUT performance test (1000 operations)
  IO.puts "\n📊 Testing PUT performance (1000 operations)..."
  test_count = 1000

  put_start = :os.system_time(:microsecond)

  for i <- 1..test_count do
    key = "perf_test:#{i}"
    value = %{id: i, data: "test_data_#{i}", timestamp: :os.system_time(:microsecond)}

    case WarpEngine.cosmic_put(key, value) do
      {:ok, :stored, _shard, _time} -> :ok
      error -> IO.puts "PUT error: #{inspect(error)}"
    end
  end

  put_end = :os.system_time(:microsecond)
  put_total_time = put_end - put_start
  put_ops_per_sec = (test_count * 1_000_000) / put_total_time
  put_avg_latency = put_total_time / test_count

  IO.puts "   PUT Results:"
  IO.puts "   - Operations: #{test_count}"
  IO.puts "   - Total time: #{Float.round(put_total_time / 1000, 1)} ms"
  IO.puts "   - Throughput: #{Float.round(put_ops_per_sec, 0)} ops/sec"
  IO.puts "   - Average latency: #{Float.round(put_avg_latency, 0)} μs"

  # Quick GET performance test (1000 operations)
  IO.puts "\n📖 Testing GET performance (1000 operations)..."

  get_start = :os.system_time(:microsecond)

  for i <- 1..test_count do
    key = "perf_test:#{i}"

    case WarpEngine.cosmic_get(key) do
      {:ok, _value, _shard, _time} -> :ok
      {:error, :not_found, _time} -> :ok  # Acceptable
      error -> IO.puts "GET error: #{inspect(error)}"
    end
  end

  get_end = :os.system_time(:microsecond)
  get_total_time = get_end - get_start
  get_ops_per_sec = (test_count * 1_000_000) / get_total_time
  get_avg_latency = get_total_time / test_count

  IO.puts "   GET Results:"
  IO.puts "   - Operations: #{test_count}"
  IO.puts "   - Total time: #{Float.round(get_total_time / 1000, 1)} ms"
  IO.puts "   - Throughput: #{Float.round(get_ops_per_sec, 0)} ops/sec"
  IO.puts "   - Average latency: #{Float.round(get_avg_latency, 0)} μs"

  # Performance analysis
  IO.puts "\n🎯 PERFORMANCE ANALYSIS:"
  IO.puts "─" |> String.duplicate(40)

  # Compare with previous benchmarks
  previous_put = 3_104
  previous_get = 5_403

  put_improvement = put_ops_per_sec / previous_put
  get_improvement = get_ops_per_sec / previous_get

  IO.puts "PUT Performance:"
  IO.puts "  Previous: #{previous_put} ops/sec"
  IO.puts "  Current:  #{Float.round(put_ops_per_sec, 0)} ops/sec"
  IO.puts "  Improvement: #{Float.round(put_improvement, 1)}x"

  IO.puts "\nGET Performance:"
  IO.puts "  Previous: #{previous_get} ops/sec"
  IO.puts "  Current:  #{Float.round(get_ops_per_sec, 0)} ops/sec"
  IO.puts "  Improvement: #{Float.round(get_improvement, 1)}x"

  # Validation results
  IO.puts "\n✅ VALIDATION RESULTS:"

  target_put_min = 60_000
  target_put_max = 150_000

  cond do
    put_ops_per_sec >= target_put_max ->
      IO.puts "🎉 EXCELLENT: PUT performance #{Float.round(put_ops_per_sec, 0)} ops/sec EXCEEDS target range!"

    put_ops_per_sec >= target_put_min ->
      IO.puts "✅ SUCCESS: PUT performance #{Float.round(put_ops_per_sec, 0)} ops/sec meets Phase 1 target (60K-150K)!"

    put_ops_per_sec > previous_put * 5 ->
      IO.puts "⚡ GOOD: PUT performance improved #{Float.round(put_improvement, 1)}x (significant progress)"

    true ->
      IO.puts "⚠️  Phase 1 optimizations need further investigation"
      IO.puts "   Current: #{Float.round(put_ops_per_sec, 0)} ops/sec"
      IO.puts "   Target:  #{target_put_min}-#{target_put_max} ops/sec"
  end

  # System health check
  memory_mb = :erlang.memory(:total) / (1024 * 1024)
  process_count = :erlang.system_info(:process_count)

  IO.puts "\n🖥️  System Health:"
  IO.puts "   Memory usage: #{Float.round(memory_mb, 1)} MB"
  IO.puts "   Active processes: #{process_count}"

  if memory_mb < 200 and process_count < 200 do
    IO.puts "   ✅ System resource usage is optimal"
  else
    IO.puts "   ⚠️  High resource usage detected"
  end

  IO.puts "\n🌟 Test completed successfully!"

rescue
  error ->
    IO.puts "\n❌ Test failed with error:"
    IO.puts "   #{inspect(error)}"
    IO.puts "\n🔧 Troubleshooting:"
    IO.puts "   1. Check that all WAL optimizations are properly compiled"
    IO.puts "   2. Verify atomic counter and async file operations are working"
    IO.puts "   3. Ensure GenServer bypass is functioning correctly"
    System.halt(1)
end

IO.puts "\n🚀 WarpEngine Phase 1 optimization validation complete!"
