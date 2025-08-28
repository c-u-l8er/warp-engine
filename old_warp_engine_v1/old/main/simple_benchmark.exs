# Simple WarpEngine Database Performance Benchmark

IO.puts """
🚀 WarpEngine Database Performance Benchmark
═══════════════════════════════════════

Testing the computational universe's performance claims:
• Sub-millisecond core operations
• Quantum entanglement efficiency
• Event horizon cache performance
• Entropy monitoring overhead
"""

# Start the system
Application.ensure_all_started(:warp_engine)
Process.sleep(2000)  # Give it time to fully initialize

IO.puts "✅ System started successfully!"

# Test 1: Core Operations Performance
IO.puts "\n🔬 Test 1: Core Operations Performance"

# Benchmark PUT operations
put_times = for i <- 1..1000 do
  key = "benchmark:put:#{i}"
  value = %{id: i, data: :crypto.strong_rand_bytes(100) |> Base.encode64(), timestamp: :os.system_time(:microsecond)}

  {time, {:ok, :stored, shard, op_time}} = :timer.tc(fn ->
    WarpEngine.cosmic_put(key, value)
  end)

  {time, op_time, shard}
end

# Extract the three values manually since unzip3 doesn't exist
wall_times = Enum.map(put_times, fn {wall, _op, _shard} -> wall end)
op_times = Enum.map(put_times, fn {_wall, op, _shard} -> op end)
shards = Enum.map(put_times, fn {_wall, _op, shard} -> shard end)
avg_put_wall = Enum.sum(wall_times) / length(wall_times)
avg_put_op = Enum.sum(op_times) / length(op_times)

IO.puts "   PUT Operations (1000 iterations):"
IO.puts "   • Average wall time: #{Float.round(avg_put_wall, 0)}μs"
IO.puts "   • Average operation time: #{Float.round(avg_put_op, 0)}μs"
IO.puts "   • Throughput: #{Float.round(1_000_000 / avg_put_wall, 0)} ops/second"
IO.puts "   • Shards used: #{shards |> Enum.uniq() |> Enum.join(", ")}"

# Benchmark GET operations
get_times = for i <- 1..1000 do
  key = "benchmark:put:#{i}"

  {time, result} = :timer.tc(fn ->
    WarpEngine.cosmic_get(key)
  end)

  case result do
    {:ok, _value, shard, op_time} -> {time, op_time, shard, :success}
    _ -> {time, 0, :unknown, :error}
  end
end

# Extract the four values manually
get_wall_times = Enum.map(get_times, fn {wall, _op, _shard, _result} -> wall end)
get_op_times = Enum.map(get_times, fn {_wall, op, _shard, _result} -> op end)
results = Enum.map(get_times, fn {_wall, _op, _shard, result} -> result end)
successful_gets = Enum.count(results, &(&1 == :success))
avg_get_wall = Enum.sum(get_wall_times) / length(get_wall_times)
avg_get_op = Enum.sum(get_op_times) / length(get_op_times)

IO.puts "\n   GET Operations (1000 iterations):"
IO.puts "   • Average wall time: #{Float.round(avg_get_wall, 0)}μs"
IO.puts "   • Average operation time: #{Float.round(avg_get_op, 0)}μs"
IO.puts "   • Throughput: #{Float.round(1_000_000 / avg_get_wall, 0)} ops/second"
IO.puts "   • Success rate: #{successful_gets}/1000 (#{Float.round(successful_gets/10, 1)}%)"

# Test 2: Quantum Entanglement Performance
IO.puts "\n⚛️  Test 2: Quantum Entanglement Performance"

# Create some entangled data
for i <- 1..100 do
  user_key = "user:#{i}"
  profile_key = "profile:#{i}"
  settings_key = "settings:#{i}"

  WarpEngine.cosmic_put(user_key, %{id: i, name: "User#{i}", email: "user#{i}@test.com"})
  WarpEngine.cosmic_put(profile_key, %{user_id: i, bio: "Test user #{i}", skills: ["elixir", "physics"]})
  WarpEngine.cosmic_put(settings_key, %{user_id: i, theme: "cosmic", notifications: true})

  # The quantum entanglement should happen automatically via patterns
end

# Benchmark quantum_get vs regular get
quantum_times = for i <- 1..100 do
  key = "user:#{i}"

  {time, result} = :timer.tc(fn ->
    WarpEngine.quantum_get(key)
  end)

  case result do
    {:ok, response} ->
      # Extract entangled count from the quantum_data structure
      entangled_count = if Map.has_key?(response, :quantum_data) do
        response.quantum_data.entangled_count || 0
      else
        0
      end
      {time, entangled_count, :success}
    _ -> {time, 0, :error}
  end
end

# Extract quantum timing data manually
quantum_wall_times = Enum.map(quantum_times, fn {wall, _count, _result} -> wall end)
entangled_counts = Enum.map(quantum_times, fn {_wall, count, _result} -> count end)
quantum_results = Enum.map(quantum_times, fn {_wall, _count, result} -> result end)
successful_quantum = Enum.count(quantum_results, &(&1 == :success))
avg_quantum_wall = Enum.sum(quantum_wall_times) / length(quantum_wall_times)
avg_entangled = Enum.sum(entangled_counts) / length(entangled_counts)

IO.puts "   Quantum GET Operations (100 iterations):"
IO.puts "   • Average wall time: #{Float.round(avg_quantum_wall, 0)}μs"
IO.puts "   • Average entangled items: #{Float.round(avg_entangled, 1)}"
IO.puts "   • Success rate: #{successful_quantum}/100 (#{successful_quantum}%)"
IO.puts "   • Efficiency factor: #{Float.round(avg_entangled, 1)}x data retrieved per query"

# Test 3: System Metrics and Status
IO.puts "\n📊 Test 3: System Performance Metrics"

metrics = WarpEngine.cosmic_metrics()

IO.puts "   Universe Status:"
IO.puts "   • State: #{metrics.universe_state}"
IO.puts "   • Active phases: #{Enum.join(metrics.active_phases, ", ")}"
IO.puts "   • Total spacetime shards: #{length(metrics.spacetime_shards)}"

# Shard metrics
Enum.each(metrics.spacetime_shards, fn shard_metrics ->
  IO.puts "   • #{shard_metrics.shard_id}: #{shard_metrics.item_count} items, #{Float.round(shard_metrics.memory_mb, 1)}MB"
end)

# Test 4: Load Distribution Analysis
IO.puts "\n🌌 Test 4: Load Distribution Analysis"

load_analysis = WarpEngine.analyze_load_distribution()
IO.puts "   Load Balance Score: #{Float.round(load_analysis.balance_score * 100, 1)}%"
IO.puts "   Entropy Level: #{Float.round(load_analysis.system_entropy, 2)}"
IO.puts "   Recommendations: #{length(load_analysis.recommendations)} optimization suggestions"

# Test 5: Performance Validation Summary
IO.puts "\n🎯 Performance Validation Summary:"
IO.puts "   ═" |> String.duplicate(45)

# Check if we meet the claimed performance targets
put_target_met = avg_put_wall < 1000  # Sub-millisecond
get_target_met = avg_get_wall < 1000  # Sub-millisecond
quantum_efficient = avg_entangled > 1.5  # Reasonable entanglement

IO.puts "   Core Operations:"
IO.puts "   • PUT performance: #{if put_target_met, do: "✅", else: "⚠️ "} #{Float.round(avg_put_wall, 0)}μs (target: <1000μs)"
IO.puts "   • GET performance: #{if get_target_met, do: "✅", else: "⚠️ "} #{Float.round(avg_get_wall, 0)}μs (target: <1000μs)"
IO.puts "   • Quantum efficiency: #{if quantum_efficient, do: "✅", else: "⚠️ "} #{Float.round(avg_entangled, 1)}x retrieval factor"

memory_mb = :erlang.memory(:total) / (1024 * 1024)
process_count = :erlang.system_info(:process_count)

IO.puts "\n   System Resources:"
IO.puts "   • Memory usage: #{Float.round(memory_mb, 1)} MB"
IO.puts "   • Active processes: #{process_count}"
IO.puts "   • Universe uptime: #{Float.round(metrics.uptime_ms / 1000, 1)} seconds"

IO.puts "\n   Physics Systems Status:"
if Map.has_key?(metrics, :entropy_monitoring) do
  IO.puts "   • Entropy monitoring: ✅ Active"
else
  IO.puts "   • Entropy monitoring: ⚠️  Status unknown"
end

if Map.has_key?(metrics, :event_horizon_caches) do
  cache_count = length(metrics.event_horizon_caches)
  IO.puts "   • Event horizon caches: ✅ #{cache_count} active"
else
  IO.puts "   • Event horizon caches: ⚠️  Status unknown"
end

overall_performance = put_target_met and get_target_met and quantum_efficient

IO.puts "\n🏆 OVERALL ASSESSMENT:"
IO.puts "   #{if overall_performance, do: "✅ EXCELLENT", else: "⚠️  NEEDS OPTIMIZATION"} - WarpEngine Database is #{if overall_performance, do: "exceeding", else: "approaching"} performance targets"

if overall_performance do
  IO.puts "   🌌 The computational universe is performing optimally!"
  IO.puts "   🚀 Ready for production workloads and further enhancements"
else
  IO.puts "   🔧 Consider optimization or system tuning for production workloads"
end

IO.puts "\n✨ Benchmark completed successfully!"
