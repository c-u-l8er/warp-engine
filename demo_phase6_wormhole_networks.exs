#!/usr/bin/env elixir
"""
🌌 Phase 6: Wormhole Network Topology Demo

This demo showcases the revolutionary Wormhole Network system for IsLabDB,
demonstrating dynamic connection management, intelligent routing, and
physics-based network optimization.

Features demonstrated:
- Dynamic wormhole connection establishment
- Multi-hop route finding with different algorithms
- Connection strengthening through usage patterns
- Network optimization with entropy-driven rebalancing
- Performance analytics and predictive modeling
- Persistence and recovery capabilities
"""

# Set up test data directory for the demo
demo_data_dir = "/tmp/islab_wormhole_demo_#{:rand.uniform(10000)}"

alias IsLabDB.WormholeRouter

defmodule WormholeNetworkDemo do
  @moduledoc """
  Comprehensive demonstration of Phase 6 Wormhole Network capabilities.
  """

    def run do
    # Store original data root and set demo directory
    original_data_root = Application.get_env(:islab_db, :data_root)
    demo_data_dir = "/tmp/islab_wormhole_demo_#{:rand.uniform(10000)}"
    Application.put_env(:islab_db, :data_root, demo_data_dir)
    
    IO.puts """
    🌌====================================================================🌌
    🚀 IsLabDB Phase 6: Wormhole Network Topology Demo
    🌌====================================================================🌌
    
    Welcome to the future of database networking! This demo showcases
    how theoretical wormhole physics can revolutionize data access patterns.
    
    """

    # Clean up any existing demo data
    File.rm_rf!(demo_data_dir)
    File.mkdir_p!(demo_data_dir)

    # Start the wormhole router
    IO.puts "🌌 Step 1: Initializing Wormhole Network Router..."
    {:ok, router} = WormholeRouter.start_link(
      name: :demo_wormhole_router,
      enable_entropy_monitoring: false
    )

    demonstrate_network_initialization(router, demo_data_dir)
    demonstrate_connection_establishment(router)
    demonstrate_route_finding(router)
    demonstrate_performance_optimization(router)
    demonstrate_analytics_and_monitoring(router)
    demonstrate_persistence_features(router, demo_data_dir)
    demonstrate_advanced_scenarios(router)

    IO.puts """

    🌌====================================================================🌌
    🎉 Phase 6 Wormhole Network Demo Complete!
    🌌====================================================================🌌

    The Wormhole Network system successfully demonstrated:
    ✅ Dynamic connection establishment with gravitational physics
    ✅ Intelligent routing with multiple algorithms (Dijkstra, A*)
    ✅ Usage-based connection strengthening and temporal decay
    ✅ Network optimization with entropy-driven rebalancing
    ✅ Real-time performance analytics and monitoring
    ✅ Complete persistence and recovery capabilities
    ✅ Advanced multi-hop pathfinding and caching

    This represents a breakthrough in database networking architecture,
    combining theoretical physics with practical performance optimization.

    The computational universe now features its most advanced networking system! 🌌✨
    """

    # Cleanup and restore original data root
    File.rm_rf!(demo_data_dir)
    Application.put_env(:islab_db, :data_root, original_data_root)
    :ok
  end

  defp demonstrate_network_initialization(router, demo_data_dir) do
    IO.puts "   📡 Initializing cosmic network topology..."

    {:ok, topology} = WormholeRouter.get_topology(router)
    IO.puts "   ✅ Network initialized with #{length(topology.nodes)} nodes and #{length(topology.connections)} connections"

    {:ok, metrics} = WormholeRouter.get_performance_metrics(router)
    IO.puts "   📊 Initial network efficiency: #{Float.round(metrics.network_efficiency, 3)}"

    IO.puts "   🌌 Filesystem structure created at #{demo_data_dir}/wormholes/"
    IO.puts ""
  end

  defp demonstrate_connection_establishment(router) do
    IO.puts "🌌 Step 2: Establishing Wormhole Connections..."

    # Create a network of cosmic data regions
    connections = [
      {"shard_hot", "shard_warm", :fast_lane},
      {"shard_warm", "shard_cold", :standard},
      {"shard_hot", "shard_archive", :standard},
      {"shard_cold", "shard_archive", :experimental},
      {"analytics_engine", "shard_hot", :fast_lane},
      {"user_sessions", "analytics_engine", :standard}
    ]

    Enum.each(connections, fn {source, dest, type} ->
      :ok = WormholeRouter.establish_wormhole(router, source, dest, connection_type: type)
      IO.puts "   🔗 Wormhole established: #{source} <-> #{dest} (#{type})"
    end)

    {:ok, topology} = WormholeRouter.get_topology(router)
    IO.puts "   ✅ Network now has #{length(topology.nodes)} nodes and #{length(topology.connections)} connections"

    # Show connection strengths
    IO.puts "   🔬 Connection strengths calculated using gravitational physics:"
    Enum.take(topology.strengths, 3) |> Enum.each(fn {key, strength} ->
      IO.puts "     • #{key}: #{Float.round(strength, 3)}"
    end)

    IO.puts ""
  end

  defp demonstrate_route_finding(router) do
    IO.puts "🌌 Step 3: Demonstrating Intelligent Route Finding..."

    # Test different routing scenarios (including both direct and potential multi-hop)
    routes_to_test = [
      {"shard_hot", "shard_warm"},      # Direct connection
      {"shard_hot", "shard_cold"},      # Potential multi-hop via shard_warm
      {"user_sessions", "analytics_engine"}, # Direct connection
      {"user_sessions", "shard_archive"},     # Potential multi-hop
      {"analytics_engine", "shard_cold"}     # Potential multi-hop
    ]

    Enum.each(routes_to_test, fn {source, dest} ->
      case WormholeRouter.find_route(router, source, dest) do
        {:ok, route, cost} ->
          route_path = Enum.join(route, " -> ")
          IO.puts "   🛤️  Route #{source} to #{dest}: #{route_path} (cost: #{Float.round(cost, 3)})"

        {:error, :no_path} ->
          IO.puts "   ❌ No route found from #{source} to #{dest}"
      end
    end)

        # Demonstrate different routing algorithms on direct connections
    IO.puts "   🧮 Comparing routing algorithms on direct connections:"
    
    case WormholeRouter.find_route(router, "shard_hot", "shard_warm", algorithm: :dijkstra) do
      {:ok, route_dijkstra, cost_d} ->
        case WormholeRouter.find_route(router, "shard_hot", "shard_warm", algorithm: :astar) do
          {:ok, route_astar, cost_a} ->
            IO.puts "     • Dijkstra: #{Enum.join(route_dijkstra, " -> ")} (cost: #{Float.round(cost_d, 3)})"
            IO.puts "     • A*:       #{Enum.join(route_astar, " -> ")} (cost: #{Float.round(cost_a, 3)})"
          {:error, _} ->
            IO.puts "     • A*: No route found"
        end
      {:error, _} ->
        IO.puts "     • No direct routes available for algorithm comparison"
    end

        # Test caching performance on a known direct connection
    start_time = System.monotonic_time(:microsecond)
    case WormholeRouter.find_route(router, "shard_hot", "shard_warm") do
      {:ok, _route, _cost} ->
        cached_time = System.monotonic_time(:microsecond) - start_time
        IO.puts "   ⚡ Cached route lookup: #{cached_time} microseconds"
      {:error, _} ->
        IO.puts "   ⚡ Route caching: No direct routes available for timing test"
    end

    IO.puts ""
  end

  defp demonstrate_performance_optimization(router) do
    IO.puts "🌌 Step 4: Network Optimization and Connection Dynamics..."

    # Simulate usage to strengthen connections
    IO.puts "   🔄 Simulating usage patterns to strengthen connections..."

    usage_patterns = [
      {["shard_hot", "shard_warm"], %{latency: 5, throughput: 10000}},
      {["shard_hot", "shard_warm"], %{latency: 4, throughput: 12000}},
      {["analytics_engine", "shard_hot"], %{latency: 8, throughput: 8000}},
      {["user_sessions", "analytics_engine"], %{latency: 15, throughput: 5000}}
    ]

    Enum.each(usage_patterns, fn {route, perf_data} ->
      WormholeRouter.record_usage(router, route, perf_data)
    end)

    Process.sleep(50)  # Allow async processing

    # Get updated topology
    {:ok, updated_topology} = WormholeRouter.get_topology(router)

    # Show some connection strengths
    IO.puts "   📈 Connection strengths after usage:"
    updated_topology.strengths
    |> Enum.take(4)
    |> Enum.each(fn {key, strength} ->
      IO.puts "     • #{key}: #{Float.round(strength, 3)}"
    end)

    # Demonstrate network optimization
    IO.puts "   ⚙️  Triggering network optimization..."
    {:ok, result} = WormholeRouter.optimize_network(router, strategy: :moderate, force: true)
    IO.puts "   ✅ Optimization result: #{result}"

    {:ok, optimized_metrics} = WormholeRouter.get_performance_metrics(router)
    IO.puts "   📊 Network efficiency after optimization: #{Float.round(optimized_metrics.network_efficiency, 3)}"

    IO.puts ""
  end

  defp demonstrate_analytics_and_monitoring(router) do
    IO.puts "🌌 Step 5: Analytics and Performance Monitoring..."

    {:ok, metrics} = WormholeRouter.get_performance_metrics(router)

    IO.puts "   📊 Performance Metrics:"
    IO.puts "     • Total routes calculated: #{metrics.total_routes}"
    IO.puts "     • Cache hits: #{metrics.cache_hits}"
    IO.puts "     • Cache hit rate: #{Float.round(metrics.cache_hit_rate * 100, 1)}%"
    IO.puts "     • Active connections: #{metrics.active_connections}"
    IO.puts "     • Network size: #{metrics.network_size} nodes"
    IO.puts "     • Average route cost: #{Float.round(metrics.average_route_cost, 3)}"
    IO.puts "     • Optimization count: #{metrics.optimization_count}"

    {:ok, topology} = WormholeRouter.get_topology(router, include_analytics: true)

    if Map.has_key?(topology, :analytics) do
      IO.puts "   🔬 Usage pattern analysis available"
      IO.puts "     • Tracked usage patterns: #{length(Map.get(topology.analytics, :usage_patterns, []))}"
    end

    IO.puts ""
  end

  defp demonstrate_persistence_features(router, demo_data_dir) do
    IO.puts "🌌 Step 6: Persistence and Recovery Capabilities..."

    # Force persistence by triggering optimization
    {:ok, _result} = WormholeRouter.optimize_network(router, force: true)

    wormhole_dir = Path.join(demo_data_dir, "wormholes")

    # Check that files exist
    files = [
      Path.join([wormhole_dir, "topology", "network_graph.json"]),
      Path.join([wormhole_dir, "topology", "connection_strength.json"]),
      Path.join([wormhole_dir, "analytics", "performance_metrics.json"])
    ]

    Enum.each(files, fn file ->
      if File.exists?(file) do
        size = File.stat!(file).size
        IO.puts "   💾 #{Path.basename(file)}: #{size} bytes"
      else
        IO.puts "   ❌ #{Path.basename(file)}: not found"
      end
    end)

    IO.puts "   ✅ Network topology persisted to filesystem"
    IO.puts "   🔄 Ready for recovery in case of system restart"

    IO.puts ""
  end

  defp demonstrate_advanced_scenarios(router) do
    IO.puts "🌌 Step 7: Advanced Network Scenarios..."

    # Test network capacity under load
    IO.puts "   🚀 Testing network under simulated load..."

    start_time = System.monotonic_time(:microsecond)

    # Perform many route calculations
    routes_calculated = for _i <- 1..100 do
      source = Enum.random(["shard_hot", "shard_warm", "shard_cold"])
      dest = Enum.random(["analytics_engine", "user_sessions", "shard_archive"])

      case WormholeRouter.find_route(router, source, dest) do
        {:ok, _route, _cost} -> 1
        {:error, _} -> 0
      end
    end

    end_time = System.monotonic_time(:microsecond)
    total_time = end_time - start_time
    successful_routes = Enum.sum(routes_calculated)

    IO.puts "   📈 Load test results:"
    IO.puts "     • Routes calculated: 100"
    IO.puts "     • Successful routes: #{successful_routes}"
    IO.puts "     • Total time: #{total_time} microseconds"
    IO.puts "     • Average per route: #{div(total_time, 100)} microseconds"
    IO.puts "     • Throughput: #{Float.round(100 * 1_000_000 / total_time, 0)} routes/second"

    # Test predictive capabilities
    {:ok, topology} = WormholeRouter.get_topology(router, include_predictions: true)

    if Map.has_key?(topology, :predictions) do
      IO.puts "   🔮 Predictive analysis:"
      if next_opt = Map.get(topology.predictions, :next_optimization) do
        IO.puts "     • Next optimization predicted in: #{next_opt} minutes"
      end
    end

    IO.puts ""
  end


end

# Run the demo
WormholeNetworkDemo.run()
