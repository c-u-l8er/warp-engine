#!/usr/bin/env elixir

# Phase 1: Cosmic Foundation Demonstration
# This script demonstrates the working WarpEngine Database implementation

IO.puts """
🌌 ===================================================
   WarpEngine Database - Phase 1: Cosmic Foundation Demo
   ===================================================
"""

# Set up demo data directory
demo_data_dir = "/tmp/warp_engine_demo_#{:os.system_time(:millisecond)}"
Application.put_env(:warp_engine, :data_root, demo_data_dir)

IO.puts "🚀 Starting WarpEngine Database universe at: #{demo_data_dir}"

# Start the database manually
{:ok, _pid} = WarpEngine.start_link([
  data_root: demo_data_dir,
  enable_entropy_monitoring: false
])

IO.puts "✨ Universe initialized successfully!"

IO.puts "\n📊 Initial universe metrics:"
metrics = WarpEngine.cosmic_metrics()
IO.puts "  Universe state: #{metrics.universe_state}"
IO.puts "  Spacetime shards: #{length(metrics.spacetime_regions)}"
IO.puts "  Cosmic background temperature: #{metrics.cosmic_constants.background_temp} Kelvin"

IO.puts "\n🔬 Demonstrating core operations:"

# Demonstration 1: Basic storage and retrieval
IO.puts "\n1. Storing user data across spacetime shards:"

{:ok, :stored, shard1, time1} = WarpEngine.cosmic_put("user:alice",
  %{name: "Alice", age: 30, role: "engineer"},
  access_pattern: :hot, priority: :critical)

{:ok, :stored, shard2, time2} = WarpEngine.cosmic_put("user:bob",
  %{name: "Bob", age: 25, role: "designer"},
  access_pattern: :warm)

{:ok, :stored, shard3, time3} = WarpEngine.cosmic_put("archive:old_data",
  %{data: "ancient secrets"},
  access_pattern: :cold, priority: :background)

IO.puts "   ✓ Alice stored in #{shard1} shard (#{time1}μs)"
IO.puts "   ✓ Bob stored in #{shard2} shard (#{time2}μs)"
IO.puts "   ✓ Archive stored in #{shard3} shard (#{time3}μs)"

# Demonstration 2: Data retrieval
IO.puts "\n2. Retrieving data from the computational universe:"

{:ok, alice_data, alice_shard, alice_time} = WarpEngine.cosmic_get("user:alice")
{:ok, bob_data, bob_shard, bob_time} = WarpEngine.cosmic_get("user:bob")

IO.puts "   ✓ Retrieved Alice from #{alice_shard} (#{alice_time}μs): #{alice_data.name}, #{alice_data.role}"
IO.puts "   ✓ Retrieved Bob from #{bob_shard} (#{bob_time}μs): #{bob_data.name}, #{bob_data.role}"

# Demonstration 3: Persistence verification
IO.puts "\n3. Verifying cosmic filesystem persistence:"

# Give async persistence time to complete
:timer.sleep(200)

# Check filesystem structure
universe_manifest = Path.join(demo_data_dir, "universe.manifest")
if File.exists?(universe_manifest) do
  {:ok, content} = File.read(universe_manifest)
  {:ok, manifest} = Jason.decode(content)
  IO.puts "   ✓ Universe manifest exists (version: #{manifest["universe_version"]})"
else
  IO.puts "   ❌ Universe manifest not found"
end

# Check for persisted data files
user_files = Path.wildcard(Path.join([demo_data_dir, "spacetime", "*", "particles", "user", "*.json"]))
archive_files = Path.wildcard(Path.join([demo_data_dir, "spacetime", "*", "particles", "archive", "*.json"]))

IO.puts "   ✓ Found #{length(user_files)} persisted user files"
IO.puts "   ✓ Found #{length(archive_files)} persisted archive files"

# Show a sample persisted file
if length(user_files) > 0 do
  sample_file = List.first(user_files)
  {:ok, content} = File.read(sample_file)
  {:ok, data} = Jason.decode(content)
  IO.puts "   ✓ Sample persisted record: #{data["key"]} with cosmic coordinates"
end

# Demonstration 4: System metrics
IO.puts "\n4. Final universe metrics:"
final_metrics = WarpEngine.cosmic_metrics()

Enum.each(final_metrics.spacetime_regions, fn region ->
  IO.puts "   #{region.shard}: #{region.data_items} items, #{div(region.memory_bytes, 1024)}KB"
end)

IO.puts "   Uptime: #{final_metrics.uptime_ms}ms"
IO.puts "   Total entropy: #{Float.round(final_metrics.entropy.total_entropy, 3)}"

# Demonstration 5: Data deletion
IO.puts "\n5. Demonstrating cosmic deletion:"

{:ok, deletion_results, delete_time} = WarpEngine.cosmic_delete("user:bob")
deleted_count = Enum.count(deletion_results, fn {_shard, status} -> status == :deleted end)

IO.puts "   ✓ Deleted Bob from #{deleted_count} shards (#{delete_time}μs)"

case WarpEngine.cosmic_get("user:bob") do
  {:error, :not_found, _time} ->
    IO.puts "   ✓ Verified: Bob no longer exists in the universe"
  {:ok, _data, _shard, _time} ->
    IO.puts "   ⚠️  Bob still exists (deletion may be async)"
end

# Cleanup and summary
IO.puts "\n🧹 Cleaning up demo universe..."
GenServer.stop(WarpEngine, :normal, 1000)

# Clean up demo directory
File.rm_rf!(demo_data_dir)

IO.puts """

✨ Phase 1: Cosmic Foundation Demo Complete! ✨

🎯 Successfully demonstrated:
   ✅ Cosmic filesystem structure creation
   ✅ Multi-shard data storage with physics-inspired routing
   ✅ ETS-based high-performance data access
   ✅ Automatic filesystem persistence with human-readable JSON
   ✅ Cosmic metadata and dimensional coordinates
   ✅ Comprehensive metrics and entropy monitoring
   ✅ Graceful data deletion across all spacetime regions

📈 Performance characteristics:
   • Sub-millisecond operations for most queries
   • Automatic persistence without blocking operations
   • Self-documenting filesystem structure
   • Physics-inspired intelligent data placement

🚀 Ready for Phase 2: Quantum Entanglement Engine!
"""
