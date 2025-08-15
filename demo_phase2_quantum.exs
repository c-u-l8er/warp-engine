#!/usr/bin/env elixir

# 🌌 IsLab Database Phase 2: Quantum Entanglement Demo
# This script demonstrates the new quantum entanglement features

# Mix.install([{:islab_db, path: "."}])

IO.puts """
🌌 ═══════════════════════════════════════════════════════════════
   IsLab Database - Phase 2: Quantum Entanglement Engine Demo
═══════════════════════════════════════════════════════════════ 🌌

Welcome to the physics-inspired database with quantum entanglement!
"""

# Set up data directory first
demo_data_dir = "/tmp/islab_demo_quantum"
Application.put_env(:islab_db, :data_root, demo_data_dir)

# Start the IsLab Database universe
IO.puts "🚀 Initializing the computational universe..."
case IsLabDB.start_link([data_root: demo_data_dir]) do
  {:ok, _pid} ->
    IO.puts "✨ Started new universe instance"
  {:error, {:already_started, _pid}} ->
    IO.puts "✨ Universe already running, connecting to existing instance"
  {:error, reason} ->
    IO.puts "❌ Failed to start universe: #{inspect(reason)}"
end

# Give the system time to initialize
:timer.sleep(1000)

IO.puts "✨ Universe is stable and ready for quantum operations!\n"

# ═══════════════════════════════════════════════════════════════
# Phase 1 Features: Basic Storage
# ═══════════════════════════════════════════════════════════════

IO.puts "📦 PHASE 1 FEATURES: Basic Cosmic Storage"
IO.puts "─" |> String.duplicate(50)

# Store some basic user data
IO.puts "Storing user data across spacetime shards..."

{:ok, :stored, shard1, time1} = IsLabDB.cosmic_put("user:alice",
  %{name: "Alice", role: "engineer", age: 30})

{:ok, :stored, shard2, time2} = IsLabDB.cosmic_put("user:bob",
  %{name: "Bob", role: "designer", age: 28})

IO.puts "✅ Alice stored in #{shard1} shard (#{time1}μs)"
IO.puts "✅ Bob stored in #{shard2} shard (#{time2}μs)"

# Basic retrieval
{:ok, alice_data, alice_shard, get_time} = IsLabDB.cosmic_get("user:alice")
IO.puts "📖 Retrieved Alice from #{alice_shard}: #{inspect(alice_data)} (#{get_time}μs)\n"

# ═══════════════════════════════════════════════════════════════
# Phase 2 Features: Quantum Entanglement
# ═══════════════════════════════════════════════════════════════

IO.puts "⚛️  PHASE 2 FEATURES: Quantum Entanglement Engine"
IO.puts "─" |> String.duplicate(50)

# Create related data that we want to entangle
IO.puts "Creating quantum-entangled data relationships..."

# Alice's extended profile
IsLabDB.cosmic_put("profile:alice",
  %{bio: "Senior Software Engineer", avatar: "alice.jpg", skills: ["Elixir", "Physics", "Quantum Computing"]})

IsLabDB.cosmic_put("settings:alice",
  %{theme: "cosmic-dark", notifications: true, language: "en"})

IsLabDB.cosmic_put("sessions:alice",
  %{active: true, last_login: "2025-01-15T14:30:00Z", devices: ["laptop", "phone"]})

# Bob's extended profile
IsLabDB.cosmic_put("profile:bob",
  %{bio: "UX Designer", avatar: "bob.jpg", skills: ["Design", "Psychology", "Art"]})

IsLabDB.cosmic_put("settings:bob",
  %{theme: "light", notifications: false, language: "en"})

# Manual quantum entanglement creation
IO.puts "\n🔗 Creating manual quantum entanglement for Alice's data..."

{:ok, entanglement_id} = IsLabDB.create_quantum_entanglement("user:alice",
  ["profile:alice", "settings:alice", "sessions:alice"],
  0.95)  # Very strong entanglement

IO.puts "✨ Quantum entanglement created! ID: #{entanglement_id}"

# Demonstrate automatic entanglement patterns
IO.puts "\n🎯 Demonstrating automatic entanglement patterns..."
IO.puts "   (User data automatically entangles with profile, settings, and sessions)"

# Create a new user - should trigger automatic patterns
IsLabDB.cosmic_put("user:charlie",
  %{name: "Charlie", role: "physicist", age: 32})

IsLabDB.cosmic_put("profile:charlie",
  %{bio: "Quantum Physicist", avatar: "charlie.jpg", skills: ["Quantum Mechanics", "Mathematics"]})

:timer.sleep(200)  # Give pattern application time to complete

# ═══════════════════════════════════════════════════════════════
# Quantum Operations: Smart Data Retrieval
# ═══════════════════════════════════════════════════════════════

IO.puts "\n⚛️  QUANTUM OBSERVATION: Smart Data Retrieval"
IO.puts "─" |> String.duplicate(50)

IO.puts "🔬 Basic retrieval (Phase 1 style):"
{:ok, basic_alice, basic_shard, basic_time} = IsLabDB.cosmic_get("user:alice")
IO.puts "   Retrieved Alice: #{inspect(basic_alice)}"
IO.puts "   From shard: #{basic_shard}, Time: #{basic_time}μs"

IO.puts "\n🌟 Quantum retrieval (Phase 2 style):"
{:ok, quantum_response} = IsLabDB.quantum_get("user:alice")

IO.puts "   Primary Data: #{inspect(quantum_response.value)}"
IO.puts "   From shard: #{quantum_response.shard}, Time: #{quantum_response.operation_time}μs"

IO.puts "\n✨ Quantum Entangled Data Retrieved:"
IO.puts "   Entangled items: #{quantum_response.quantum_data.entangled_count}"
IO.puts "   Quantum efficiency: #{Float.round(quantum_response.quantum_data.quantum_efficiency * 100, 1)}%"

# Show entangled data
quantum_response.quantum_data.entangled_items
|> Enum.each(fn {key, result} ->
  case result do
    {:ok, data, shard} ->
      IO.puts "   🔗 #{key}: #{inspect(data)} (from #{shard})"
    {:error, :not_found} ->
      IO.puts "   🔗 #{key}: (not found)"
  end
end)

# ═══════════════════════════════════════════════════════════════
# Quantum Metrics and Analytics
# ═══════════════════════════════════════════════════════════════

IO.puts "\n📊 QUANTUM SYSTEM METRICS"
IO.puts "─" |> String.duplicate(50)

# Get comprehensive universe metrics
metrics = IsLabDB.cosmic_metrics()

IO.puts "🌌 Universe Status: #{metrics.universe_state}"
IO.puts "⏱️  Uptime: #{metrics.uptime_ms}ms"

# Spacetime shard statistics
IO.puts "\n🗂️  Spacetime Shard Statistics:"
Enum.each(metrics.spacetime_regions, fn region ->
  IO.puts "   #{region.shard}: #{region.data_items} items, #{region.memory_bytes} bytes"
end)

# Quantum entanglement statistics
quantum_stats = IsLabDB.quantum_entanglement_metrics()
IO.puts "\n⚛️  Quantum Entanglement Statistics:"
IO.puts "   Total entanglements: #{quantum_stats.total_entanglements}"
IO.puts "   Quantum relationships: #{quantum_stats.total_quantum_relationships}"
IO.puts "   Average strength: #{Float.round(quantum_stats.average_entanglement_strength, 3)}"
IO.puts "   Quantum efficiency: #{Float.round(quantum_stats.quantum_efficiency * 100, 1)}%"
IO.puts "   Superposition states: #{quantum_stats.superposition_count}"
IO.puts "   Collapsed states: #{quantum_stats.collapsed_count}"

# ═══════════════════════════════════════════════════════════════
# Performance Demonstration
# ═══════════════════════════════════════════════════════════════

IO.puts "\n🏃 PERFORMANCE DEMONSTRATION"
IO.puts "─" |> String.duplicate(50)

# Benchmark basic vs quantum retrieval
basic_times = for _i <- 1..10 do
  {time, _result} = :timer.tc(fn -> IsLabDB.cosmic_get("user:alice") end)
  time
end

quantum_times = for _i <- 1..10 do
  {time, _result} = :timer.tc(fn -> IsLabDB.quantum_get("user:alice") end)
  time
end

avg_basic = Enum.sum(basic_times) / length(basic_times)
avg_quantum = Enum.sum(quantum_times) / length(quantum_times)

IO.puts "⚡ Average basic retrieval time: #{Float.round(avg_basic, 0)}μs"
IO.puts "⚛️  Average quantum retrieval time: #{Float.round(avg_quantum, 0)}μs"
IO.puts "📈 Quantum overhead: #{Float.round((avg_quantum - avg_basic) / avg_basic * 100, 1)}%"
IO.puts "💡 BUT: Quantum retrieval gets #{quantum_response.quantum_data.entangled_count}x more data!"

# ═══════════════════════════════════════════════════════════════
# Filesystem Structure
# ═══════════════════════════════════════════════════════════════

IO.puts "\n📁 FILESYSTEM PERSISTENCE"
IO.puts "─" |> String.duplicate(50)

IO.puts "🗂️  Cosmic filesystem structure created at: /tmp/islab_demo_quantum"
IO.puts "📋 Key directories:"

key_dirs = [
  "/tmp/islab_demo_quantum/universe.manifest",
  "/tmp/islab_demo_quantum/spacetime/hot_data/quantum_indices/",
  "/tmp/islab_demo_quantum/spacetime/warm_data/particles/user/",
  "/tmp/islab_demo_quantum/spacetime/cold_data/particles/"
]

Enum.each(key_dirs, fn dir ->
  if File.exists?(dir) do
    IO.puts "   ✅ #{dir}"
  else
    IO.puts "   ❓ #{dir} (may not exist yet)"
  end
end)

# Show some quantum indices if they exist
quantum_files = [
  "/tmp/islab_demo_quantum/spacetime/hot_data/quantum_indices/entanglements.json",
  "/tmp/islab_demo_quantum/spacetime/warm_data/quantum_indices/entanglements.json",
  "/tmp/islab_demo_quantum/spacetime/cold_data/quantum_indices/entanglements.json"
]

quantum_file = Enum.find(quantum_files, &File.exists?/1)

if quantum_file do
  IO.puts "\n🔮 Quantum Entanglement Persistence:"
  IO.puts "   Entanglements stored in: #{Path.basename(quantum_file)}"

  case File.read(quantum_file) do
    {:ok, content} ->
      case Jason.decode(content) do
        {:ok, entanglements} when is_list(entanglements) ->
          IO.puts "   Persisted entanglements: #{length(entanglements)}"
        _ ->
          IO.puts "   Quantum data format not recognized"
      end
    {:error, _} ->
      IO.puts "   Could not read quantum data"
  end
end

# ═══════════════════════════════════════════════════════════════
# Conclusion
# ═══════════════════════════════════════════════════════════════

IO.puts "\n" <> "═" |> String.duplicate(70)
IO.puts "🎉 PHASE 2 QUANTUM ENTANGLEMENT ENGINE: COMPLETE!"
IO.puts "═" |> String.duplicate(70)

IO.puts """
✨ Key Features Demonstrated:

   🔬 Phase 1 Foundation:
      • Sub-millisecond basic operations
      • Elegant filesystem persistence
      • Physics-inspired spacetime sharding

   ⚛️  Phase 2 Quantum Engine:
      • Automatic entanglement patterns
      • Smart parallel data fetching
      • Quantum observation mechanics
      • Persistent quantum indices
      • Enhanced metrics and analytics

   🚀 Next: Phase 3 will add Spacetime Sharding with gravitational routing
   🌌 Making databases as elegant as the universe itself!

Thanks for exploring the quantum-enhanced IsLab Database! 🌟
"""

IO.puts "\n🧹 Demo cleanup: /tmp/islab_demo_quantum directory can be safely deleted.\n"
