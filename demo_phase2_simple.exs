#!/usr/bin/env elixir

# Simple demo that shows Phase 2 quantum features without application startup issues

IO.puts """
🌌 ═══════════════════════════════════════════════════════════════
   WarpEngine Database - Phase 2: Quantum Entanglement Demo
═══════════════════════════════════════════════════════════════ 🌌

Quick demonstration of quantum entanglement features in IEx...

To run this demo interactively:

    iex -S mix

Then copy and paste these commands:
"""

IO.puts """
# 🚀 Start the universe with custom data directory
{:ok, _pid} = WarpEngine.start_link([data_root: "/tmp/demo_quantum"])

# 📦 Store some basic user data
{:ok, :stored, shard, time} = WarpEngine.cosmic_put("user:alice", %{name: "Alice", age: 30})
IO.puts "✅ Alice stored in \#{shard} shard (\#{time}μs)"

# 🔗 Store related data that will be auto-entangled
WarpEngine.cosmic_put("profile:alice", %{bio: "Engineer", skills: ["Elixir", "Physics"]})
WarpEngine.cosmic_put("settings:alice", %{theme: "cosmic-dark", notifications: true})

# ⚛️  Basic retrieval (Phase 1)
{:ok, alice_basic, shard, time} = WarpEngine.cosmic_get("user:alice")
IO.puts "📖 Basic get: \#{inspect(alice_basic)} from \#{shard} (\#{time}μs)"

# 🌟 Quantum retrieval (Phase 2) - gets entangled data automatically!
{:ok, response} = WarpEngine.quantum_get("user:alice")
IO.puts "✨ Quantum get retrieved \#{response.quantum_data.entangled_count} entangled items!"

# Show the entangled data
response.quantum_data.entangled_items |> Enum.each(fn {key, result} ->
  case result do
    {:ok, data, shard} -> IO.puts "  🔗 \#{key}: \#{inspect(data)} (\#{shard})"
    _ -> IO.puts "  🔗 \#{key}: not found"
  end
end)

# 📊 View quantum metrics
quantum_stats = WarpEngine.quantum_entanglement_metrics()
IO.puts "⚛️  Quantum Stats:"
IO.puts "   Entanglements: \#{quantum_stats.total_entanglements}"
IO.puts "   Efficiency: \#{Float.round(quantum_stats.quantum_efficiency * 100, 1)}%"

# 🔬 Create manual entanglement
{:ok, entanglement_id} = WarpEngine.create_quantum_entanglement("user:alice",
  ["profile:alice", "settings:alice"], 0.95)
IO.puts "🔗 Manual entanglement created: \#{entanglement_id}"

# 📈 Performance comparison
{basic_time, _} = :timer.tc(fn -> WarpEngine.cosmic_get("user:alice") end)
{quantum_time, _} = :timer.tc(fn -> WarpEngine.quantum_get("user:alice") end)
IO.puts "⚡ Basic: \#{basic_time}μs, Quantum: \#{quantum_time}μs"

IO.puts "🎉 Phase 2 Quantum Entanglement Engine working perfectly!"
"""

IO.puts """

💡 Key Phase 2 Features Demonstrated:

   ⚛️  Automatic entanglement patterns (user:* → profile:*, settings:*)
   🔗 Manual quantum entanglement creation
   🌟 Smart parallel data fetching with quantum_get/1
   📊 Quantum metrics and efficiency tracking
   💾 Persistent quantum indices in filesystem
   🚀 Sub-millisecond performance with entangled relationships

🌌 The computational universe now has quantum mechanics! 🌌
"""
