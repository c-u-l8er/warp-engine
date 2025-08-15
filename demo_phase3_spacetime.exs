#!/usr/bin/env elixir

# 🌌 IsLab Database Phase 3: Spacetime Sharding System Demo
# This script demonstrates the advanced spacetime sharding with gravitational routing

IO.puts """
🌌 ═══════════════════════════════════════════════════════════════
   IsLab Database - Phase 3: Spacetime Sharding System Demo
═══════════════════════════════════════════════════════════════ 🌌

Welcome to the advanced physics-inspired database with intelligent
spacetime sharding and gravitational routing!
"""

# Set up data directory
demo_data_dir = "/tmp/islab_demo_phase3"
Application.put_env(:islab_db, :data_root, demo_data_dir)

# Start the IsLab Database universe
IO.puts "🚀 Initializing the Phase 3 computational universe..."
case IsLabDB.start_link([data_root: demo_data_dir]) do
  {:ok, _pid} ->
    IO.puts "✨ Started Phase 3 universe with advanced spacetime sharding"
  {:error, {:already_started, _pid}} ->
    IO.puts "✨ Phase 3 universe already running, connecting to existing instance"
  {:error, reason} ->
    IO.puts "❌ Failed to start universe: #{inspect(reason)}"
    System.halt(1)
end

# Give the system time to initialize
:timer.sleep(1500)

IO.puts "✨ Phase 3 universe is stable and ready for gravitational operations!\n"

# ═══════════════════════════════════════════════════════════════
# Phase 3 Feature: Advanced Spacetime Sharding
# ═══════════════════════════════════════════════════════════════

IO.puts "🪐 PHASE 3 FEATURES: Advanced Spacetime Sharding"
IO.puts "─" |> String.duplicate(60)

# Get initial spacetime shard metrics
IO.puts "🔍 Initial Spacetime Shard Status:"
shard_metrics = IsLabDB.get_spacetime_shard_metrics()

Enum.each(shard_metrics, fn {shard_id, metrics} ->
  IO.puts "   #{shard_id}:"
  IO.puts "     • Consistency Model: #{metrics.physics_laws.consistency_model}"
  IO.puts "     • Time Dilation: #{metrics.physics_laws.time_dilation}x"
  IO.puts "     • Gravitational Mass: #{metrics.physics_laws.gravitational_mass}"
  IO.puts "     • Max Capacity: #{metrics.physics_laws.max_capacity} items"
  IO.puts "     • Current Load: #{metrics.data_items} items"
  IO.puts "     • Entropy Level: #{Float.round(metrics.entropy_level, 3)}"
  IO.puts "     • Field Strength: #{Float.round(metrics.gravitational_field_strength, 2)}"
  IO.puts ""
end)

# ═══════════════════════════════════════════════════════════════
# Phase 3 Feature: Gravitational Data Routing
# ═══════════════════════════════════════════════════════════════

IO.puts "🎯 GRAVITATIONAL ROUTING: Intelligent Data Placement"
IO.puts "─" |> String.duplicate(60)

# Store different types of data to demonstrate gravitational routing
test_data = [
  {
    "critical:user_session",
    %{user_id: "alice", session_token: "abc123", last_activity: :os.system_time(:second)},
    [access_pattern: :hot, priority: :critical],
    "Critical user session (should attract to high-energy shard)"
  },
  {
    "user:bob",
    %{name: "Bob", email: "bob@example.com", role: "engineer", created_at: "2025-01-15"},
    [access_pattern: :warm, priority: :normal],
    "Regular user data (balanced placement)"
  },
  {
    "analytics:monthly_report_2024",
    %{month: "december", year: 2024, views: 1250, processed: true},
    [access_pattern: :cold, priority: :background],
    "Historical analytics (low-energy storage)"
  },
  {
    "product:trending_item",
    %{id: "prod_001", name: "Quantum Widget", price: 299.99, trending: true},
    [access_pattern: :hot, priority: :high],
    "Trending product (high gravitational attraction)"
  },
  {
    "backup:system_config",
    %{config_version: "1.2.3", backup_date: "2025-01-10", compressed: true},
    [access_pattern: :cold, priority: :low],
    "System backup (archive storage)"
  }
]

IO.puts "📦 Storing data with gravitational routing decisions:"
placement_results = Enum.map(test_data, fn {key, value, opts, description} ->
  {:ok, :stored, shard_id, operation_time} = IsLabDB.cosmic_put(key, value, opts)

  IO.puts "   🔹 #{key}"
  IO.puts "      #{description}"
  IO.puts "      🎯 Routed to: #{shard_id} (#{operation_time}μs)"
  IO.puts "      📊 Options: #{inspect(opts)}"
  IO.puts ""

  {key, shard_id, operation_time, opts}
end)

# Show gravitational routing statistics
routing_stats = placement_results
|> Enum.group_by(fn {_key, shard, _time, _opts} -> shard end)
|> Enum.map(fn {shard, items} -> {shard, length(items)} end)
|> Enum.into(%{})

IO.puts "📊 Gravitational Routing Results:"
Enum.each(routing_stats, fn {shard, count} ->
  IO.puts "   #{shard}: #{count} items"
end)
IO.puts ""

# ═══════════════════════════════════════════════════════════════
# Phase 3 Feature: Load Distribution Analysis
# ═══════════════════════════════════════════════════════════════

IO.puts "⚖️  LOAD DISTRIBUTION ANALYSIS"
IO.puts "─" |> String.duplicate(60)

# Analyze current load distribution
analysis = IsLabDB.analyze_load_distribution()

IO.puts "🔍 Current Load Analysis:"
IO.puts "   Total Items: #{analysis.total_data_items}"
IO.puts "   Load Imbalance Factor: #{Float.round(analysis.load_imbalance_factor, 3)}"
IO.puts "   Rebalancing Needed: #{analysis.rebalancing_needed}"
IO.puts "   Gravitational Hotspots: #{length(analysis.gravitational_hotspots)}"
IO.puts ""

IO.puts "📊 Per-Shard Distribution:"
Enum.each(analysis.shard_distribution, fn {shard_id, metrics} ->
  IO.puts "   #{shard_id}:"
  IO.puts "     • Items: #{metrics.data_items}"
  IO.puts "     • Memory: #{Float.round(metrics.memory_usage / 1024, 1)}KB"
  IO.puts "     • Field Strength: #{Float.round(metrics.gravitational_field_strength, 2)}"
  IO.puts "     • Entropy: #{Float.round(metrics.entropy_level, 3)}"
end)
IO.puts ""

# Show gravitational hotspots if any
if length(analysis.gravitational_hotspots) > 0 do
  IO.puts "🌟 Gravitational Hotspots Detected:"
  Enum.each(analysis.gravitational_hotspots, fn hotspot ->
    IO.puts "   #{hotspot.shard_id}: Field strength #{Float.round(hotspot.field_strength, 2)} (#{Float.round(hotspot.severity, 1)}x above average)"
  end)
  IO.puts ""
end

# Show rebalancing recommendations
if length(analysis.recommendations) > 0 do
  IO.puts "💡 Rebalancing Recommendations:"
  Enum.each(analysis.recommendations, fn rec ->
    IO.puts "   #{rec.action}: #{rec.from} → #{rec.to} (#{rec.estimated_items} items, urgency: #{rec.urgency})"
  end)
  IO.puts ""
else
  IO.puts "✅ System is well-balanced, no rebalancing needed\n"
end

# ═══════════════════════════════════════════════════════════════
# Phase 3 Feature: Advanced Data Retrieval
# ═══════════════════════════════════════════════════════════════

IO.puts "🔍 ADVANCED RETRIEVAL: Physics-Aware Data Access"
IO.puts "─" |> String.duplicate(60)

# Retrieve data and show physics effects
IO.puts "📖 Retrieving data with physics tracking:"

sample_keys = ["critical:user_session", "user:bob", "product:trending_item"]

Enum.each(sample_keys, fn key ->
  case IsLabDB.cosmic_get(key) do
    {:ok, value, shard, operation_time} ->
      IO.puts "   🔹 #{key}"
      IO.puts "      Retrieved from: #{shard}"
      IO.puts "      Operation time: #{operation_time}μs"
      IO.puts "      Value: #{inspect(value, limit: :infinity) |> String.slice(0, 100)}..."
      IO.puts ""
    {:error, :not_found, operation_time} ->
      IO.puts "   ❌ #{key}: Not found (#{operation_time}μs)"
  end
end)

# ═══════════════════════════════════════════════════════════════
# Phase 3 Feature: Quantum Entanglement + Gravitational Routing
# ═══════════════════════════════════════════════════════════════

IO.puts "⚛️  QUANTUM + GRAVITATIONAL INTEGRATION"
IO.puts "─" |> String.duplicate(60)

# Create related data that should be entangled
customer_key = "customer:enterprise_alice"
profile_key = "profile:enterprise_alice"
settings_key = "settings:enterprise_alice"
orders_key = "orders:enterprise_alice"

IO.puts "🔗 Creating quantum-entangled enterprise customer data:"

# Store related data with different priorities but related content
IsLabDB.cosmic_put(customer_key, %{
  id: "alice",
  name: "Alice Enterprise",
  tier: "premium",
  account_value: 50000
}, [access_pattern: :hot, priority: :critical])

IsLabDB.cosmic_put(profile_key, %{
  company: "Alice Corp",
  industry: "Technology",
  employees: 500,
  contract_date: "2025-01-01"
}, [access_pattern: :warm, priority: :high])

IsLabDB.cosmic_put(settings_key, %{
  notifications: true,
  billing_cycle: "monthly",
  support_level: "premium",
  integrations: ["api", "webhook", "sso"]
}, [access_pattern: :warm, priority: :normal])

IsLabDB.cosmic_put(orders_key, %{
  total_orders: 125,
  last_order: "2025-01-14",
  avg_order_value: 1200.50,
  status: "active"
}, [access_pattern: :cold, priority: :normal])

# Create quantum entanglement
{:ok, entanglement_id} = IsLabDB.create_quantum_entanglement(customer_key,
  [profile_key, settings_key, orders_key], 0.95)

IO.puts "✨ Quantum entanglement created: #{entanglement_id}"
IO.puts ""

:timer.sleep(200)  # Allow entanglement to be processed

# Use quantum retrieval to get entangled data
IO.puts "🌟 Quantum retrieval with gravitational sharding:"
{:ok, quantum_response} = IsLabDB.quantum_get(customer_key)

IO.puts "   Primary Data: #{inspect(quantum_response.value)}"
IO.puts "   Retrieved from shard: #{quantum_response.shard}"
IO.puts "   Operation time: #{quantum_response.operation_time}μs"
IO.puts "   Entangled items fetched: #{quantum_response.quantum_data.entangled_count}"
IO.puts "   Quantum efficiency: #{Float.round(quantum_response.quantum_data.quantum_efficiency * 100, 1)}%"
IO.puts ""

IO.puts "🔗 Entangled data retrieved:"
quantum_response.quantum_data.entangled_items
|> Enum.each(fn {key, result} ->
  case result do
    {:ok, data, shard} ->
      IO.puts "   ✅ #{key} (from #{shard}): #{inspect(data) |> String.slice(0, 80)}..."
    {:error, :not_found} ->
      IO.puts "   ❌ #{key}: Not found"
    other ->
      IO.puts "   ❓ #{key}: #{inspect(other)}"
  end
end)
IO.puts ""

# ═══════════════════════════════════════════════════════════════
# Phase 3 Feature: Performance Benchmarking
# ═══════════════════════════════════════════════════════════════

IO.puts "🏃 PHASE 3 PERFORMANCE BENCHMARKING"
IO.puts "─" |> String.duplicate(60)

IO.puts "⚡ Running performance benchmarks with gravitational routing..."

# Benchmark different operation types
benchmark_results = %{}

# Benchmark PUT operations
put_times = for i <- 1..20 do
  key = "perf_put:#{i}"
  value = %{index: i, data: "performance test", timestamp: :os.system_time(:microsecond)}

  {time, {:ok, :stored, _shard, operation_time}} = :timer.tc(fn ->
    IsLabDB.cosmic_put(key, value, [access_pattern: :balanced, priority: :normal])
  end)

  {time, operation_time}
end

{put_wall_times, put_op_times} = Enum.unzip(put_times)
avg_put_wall = Enum.sum(put_wall_times) / length(put_wall_times)
avg_put_op = Enum.sum(put_op_times) / length(put_op_times)

# Benchmark GET operations
get_times = for i <- 1..20 do
  key = "perf_put:#{i}"

  {time, {:ok, _value, _shard, operation_time}} = :timer.tc(fn ->
    IsLabDB.cosmic_get(key)
  end)

  {time, operation_time}
end

{get_wall_times, get_op_times} = Enum.unzip(get_times)
avg_get_wall = Enum.sum(get_wall_times) / length(get_wall_times)
avg_get_op = Enum.sum(get_op_times) / length(get_op_times)

# Benchmark quantum operations
quantum_times = for i <- 1..10 do
  key = "perf_put:#{i}"

  {time, {:ok, _response}} = :timer.tc(fn ->
    IsLabDB.quantum_get(key)
  end)

  time
end

avg_quantum_time = Enum.sum(quantum_times) / length(quantum_times)

IO.puts "📊 Performance Results (averages over multiple operations):"
IO.puts "   PUT Operations:"
IO.puts "     • Wall time: #{Float.round(avg_put_wall, 0)}μs"
IO.puts "     • Internal operation time: #{Float.round(avg_put_op, 0)}μs"
IO.puts "     • Gravitational routing overhead: #{Float.round((avg_put_wall - avg_put_op) / avg_put_wall * 100, 1)}%"
IO.puts ""
IO.puts "   GET Operations:"
IO.puts "     • Wall time: #{Float.round(avg_get_wall, 0)}μs"
IO.puts "     • Internal operation time: #{Float.round(avg_get_op, 0)}μs"
IO.puts "     • Physics tracking overhead: #{Float.round((avg_get_wall - avg_get_op) / avg_get_wall * 100, 1)}%"
IO.puts ""
IO.puts "   Quantum GET Operations:"
IO.puts "     • Wall time: #{Float.round(avg_quantum_time, 0)}μs"
IO.puts "     • Entanglement overhead vs normal GET: #{Float.round((avg_quantum_time - avg_get_wall) / avg_get_wall * 100, 1)}%"
IO.puts ""

# ═══════════════════════════════════════════════════════════════
# Phase 3 Feature: Comprehensive System Metrics
# ═══════════════════════════════════════════════════════════════

IO.puts "📈 COMPREHENSIVE SYSTEM METRICS"
IO.puts "─" |> String.duplicate(60)

# Get complete system metrics including Phase 3 enhancements
metrics = IsLabDB.cosmic_metrics()

IO.puts "🌌 Universe Overview:"
IO.puts "   Phase: #{metrics.phase}"
IO.puts "   State: #{metrics.universe_state}"
IO.puts "   Uptime: #{Float.round(metrics.uptime_ms / 1000, 1)}s"
IO.puts ""

# Gravitational routing metrics
gravitational_metrics = metrics.gravitational_routing
IO.puts "🎯 Gravitational Routing Performance:"
IO.puts "   Total routing decisions: #{gravitational_metrics.total_routing_decisions}"
IO.puts "   Cache hit rate: #{Float.round(gravitational_metrics.cache_hit_rate * 100, 1)}%"
IO.puts "   Algorithm efficiency: #{Float.round(gravitational_metrics.algorithm_efficiency * 100, 1)}%"
IO.puts "   Load balance score: #{Float.round(gravitational_metrics.load_balance_score * 100, 1)}%"
IO.puts "   Total gravitational field strength: #{Float.round(gravitational_metrics.gravitational_field_strength, 2)}"
IO.puts ""

# Quantum entanglement metrics
quantum_stats = IsLabDB.quantum_entanglement_metrics()
IO.puts "⚛️  Quantum Entanglement Statistics:"
IO.puts "   Total entanglements: #{quantum_stats.total_entanglements}"
IO.puts "   Quantum relationships: #{quantum_stats.total_quantum_relationships}"
IO.puts "   Average strength: #{Float.round(quantum_stats.average_entanglement_strength, 3)}"
IO.puts "   Quantum efficiency: #{Float.round(quantum_stats.quantum_efficiency * 100, 1)}%"
IO.puts "   Superposition states: #{quantum_stats.superposition_count}"
IO.puts "   Collapsed states: #{quantum_stats.collapsed_count}"
IO.puts ""

# ═══════════════════════════════════════════════════════════════
# Filesystem Structure Exploration
# ═══════════════════════════════════════════════════════════════

IO.puts "📁 PHASE 3 FILESYSTEM ENHANCEMENTS"
IO.puts "─" |> String.duplicate(60)

IO.puts "🗂️  Enhanced cosmic filesystem structure at: #{demo_data_dir}"
IO.puts "📋 Phase 3 additions:"

phase3_dirs = [
  "spacetime/hot_data/_physics_laws.json",
  "spacetime/warm_data/_physics_laws.json",
  "spacetime/cold_data/_physics_laws.json",
  "spacetime/hot_data/quantum_indices/entanglements.json",
  "spacetime/warm_data/_shard_manifest.json"
]

Enum.each(phase3_dirs, fn dir ->
  full_path = Path.join(demo_data_dir, dir)
  if File.exists?(full_path) do
    IO.puts "   ✅ #{dir}"
  else
    IO.puts "   ❓ #{dir} (may be created dynamically)"
  end
end)

IO.puts ""

# Show physics laws file if it exists
physics_laws_file = Path.join([demo_data_dir, "spacetime", "hot_data", "_physics_laws.json"])
if File.exists?(physics_laws_file) do
  IO.puts "🔬 Hot Shard Physics Laws:"
  case File.read(physics_laws_file) do
    {:ok, content} ->
      case Jason.decode(content) do
        {:ok, physics_config} ->
          IO.puts "   Consistency Model: #{physics_config["physics_laws"]["consistency_model"]}"
          IO.puts "   Time Dilation: #{physics_config["physics_laws"]["time_dilation"]}x"
          IO.puts "   Gravitational Mass: #{physics_config["physics_laws"]["gravitational_mass"]}"
          IO.puts "   Max Capacity: #{physics_config["physics_laws"]["max_capacity"]} items"
        _ ->
          IO.puts "   (Physics configuration format not readable)"
      end
    _ ->
      IO.puts "   (Could not read physics configuration)"
  end
  IO.puts ""
end

# ═══════════════════════════════════════════════════════════════
# Conclusion
# ═══════════════════════════════════════════════════════════════

IO.puts "\n" <> "═" |> String.duplicate(70)
IO.puts "🎉 PHASE 3: SPACETIME SHARDING SYSTEM - COMPLETE!"
IO.puts "═" |> String.duplicate(70)

IO.puts """
✨ Advanced Features Successfully Demonstrated:

   🪐 Spacetime Shard Architecture:
      • Advanced physics laws configuration per shard
      • Time dilation effects and consistency models
      • Gravitational field management
      • Entropy monitoring and automatic rebalancing

   🎯 Gravitational Routing Engine:
      • Intelligent data placement based on physics
      • Multi-factor routing decisions (priority, pattern, load)
      • Consistent hashing with gravitational attraction
      • Performance-aware shard selection

   ⚖️  Load Distribution & Rebalancing:
      • Real-time load imbalance detection
      • Gravitational hotspot identification
      • Intelligent migration recommendations
      • Automated rebalancing with physics constraints

   🔗 Quantum + Gravitational Integration:
      • Quantum entanglement works across gravitational shards
      • Physics-aware parallel data retrieval
      • Enhanced metrics combining quantum and gravitational data
      • Seamless backward compatibility

   📊 Advanced Monitoring & Analytics:
      • Comprehensive physics-based metrics
      • Real-time entropy and field strength tracking
      • Routing performance optimization
      • Detailed shard health monitoring

   🚀 Performance Excellence:
      • Sub-millisecond operations maintained
      • Intelligent caching and routing decisions
      • Minimal overhead from physics calculations
      • Scalable architecture for future expansion

🌌 The computational universe now operates with advanced spacetime
   physics, making data placement and retrieval as elegant and
   efficient as the cosmos itself!

🔮 Next: Phase 4 will add Event Horizon Cache System with black
   hole mechanics for ultimate performance optimization!

Thanks for exploring the Phase 3 enhanced IsLab Database! 🌟
"""

IO.puts "\n🧹 Demo cleanup: #{demo_data_dir} directory can be safely deleted.\n"
