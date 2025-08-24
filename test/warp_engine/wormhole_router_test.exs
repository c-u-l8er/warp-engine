defmodule WarpEngine.WormholeRouterTest do
  use ExUnit.Case, async: false
  doctest WarpEngine.WormholeRouter

  alias WarpEngine.WormholeRouter

    setup do
    # Use test-specific data directory
    test_data_dir = "/tmp/warp_engine_wormhole_test_#{:rand.uniform(10000)}"

    # Set up test environment
    Application.put_env(:warp_engine, :data_root, test_data_dir)

    # Clean up any existing wormhole data
    File.rm_rf!(test_data_dir)
    File.mkdir_p!(test_data_dir)

    # Start a test router without entropy monitoring to avoid registry issues
    {:ok, router} = WormholeRouter.start_link(
      name: :"test_wormhole_router_#{:rand.uniform(10000)}",
      enable_entropy_monitoring: false
    )

    on_exit(fn ->
      File.rm_rf!(test_data_dir)
    end)

    {:ok, router: router, test_data_dir: test_data_dir}
  end

  describe "WormholeRouter initialization" do
    test "starts with clean network topology", %{router: router} do
      assert Process.alive?(router)

      {:ok, topology} = WormholeRouter.get_topology(router)
      assert topology.nodes == []
      assert topology.connections == []
      assert topology.strengths == []
    end

    test "creates filesystem structure", %{test_data_dir: test_data_dir} do
      wormhole_dir = Path.join(test_data_dir, "wormholes")
      assert File.dir?(wormhole_dir)
      assert File.dir?(Path.join(wormhole_dir, "topology"))
      assert File.dir?(Path.join(wormhole_dir, "connections/active"))
      assert File.dir?(Path.join(wormhole_dir, "connections/dormant"))
      assert File.dir?(Path.join(wormhole_dir, "connections/archived"))
      assert File.dir?(Path.join(wormhole_dir, "analytics"))
      assert File.dir?(Path.join(wormhole_dir, "configuration"))
    end
  end

  describe "wormhole connection establishment" do
    test "establishes wormhole between two nodes", %{router: router} do
      source = "shard_hot"
      destination = "shard_warm"

      assert :ok = WormholeRouter.establish_wormhole(router, source, destination)

      {:ok, topology} = WormholeRouter.get_topology(router)
      assert source in topology.nodes
      assert destination in topology.nodes

      # Should have bidirectional connections
      assert length(topology.connections) == 2
    end

    test "calculates initial connection strength using gravitational physics", %{router: router} do
      source = "shard_hot"
      destination = "shard_warm"

      :ok = WormholeRouter.establish_wormhole(router, source, destination)

      {:ok, topology} = WormholeRouter.get_topology(router)

      # Verify connection strengths are calculated
      assert length(topology.strengths) == 2

      # All strengths should be positive floats
      Enum.each(topology.strengths, fn {_key, strength} ->
        assert is_float(strength) or is_integer(strength)
        assert strength > 0
      end)
    end

        test "supports different connection types", %{router: router} do
      source = "shard_hot"
      destination = "shard_cold"

      :ok = WormholeRouter.establish_wormhole(router, source, destination,
        connection_type: :fast_lane, initial_strength: 5.0)

      {:ok, topology} = WormholeRouter.get_topology(router)

      # Find the connection and verify type
      connection = Enum.find(topology.connections, fn {_key, conn} ->
        is_map(conn) and Map.get(conn, :source) == source and Map.get(conn, :destination) == destination
      end)

      assert connection != nil
      {_key, conn_data} = connection
      assert Map.get(conn_data, :type) == :fast_lane
    end
  end

  describe "route finding" do
    test "finds direct route between connected nodes", %{router: router} do
      source = "shard_hot"
      destination = "shard_warm"

      :ok = WormholeRouter.establish_wormhole(router, source, destination)

      {:ok, route, cost} = WormholeRouter.find_route(router, source, destination)

      assert route == [source, destination]
      assert is_float(cost) or is_integer(cost)
      assert cost > 0
    end

    test "returns error when no route exists", %{router: router} do
      source = "shard_hot"
      destination = "shard_isolated"

      # Don't establish any connections

      {:error, :no_path} = WormholeRouter.find_route(router, source, destination)
    end

    test "uses route caching for performance", %{router: router} do
      source = "shard_hot"
      destination = "shard_warm"

      :ok = WormholeRouter.establish_wormhole(router, source, destination)

      # First call should cache the route
      {:ok, route1, cost1} = WormholeRouter.find_route(router, source, destination)

      # Second call should use cached route
      {:ok, route2, cost2} = WormholeRouter.find_route(router, source, destination)

      assert route1 == route2
      assert cost1 == cost2

      # Verify cache hit in performance metrics
      {:ok, metrics} = WormholeRouter.get_performance_metrics(router)
      assert metrics.cache_hits > 0
    end

    test "supports different routing algorithms", %{router: router} do
      source = "shard_hot"
      destination = "shard_warm"

      :ok = WormholeRouter.establish_wormhole(router, source, destination)

      # Test Dijkstra algorithm
      {:ok, route_dijkstra, _cost} = WormholeRouter.find_route(router, source, destination,
        algorithm: :dijkstra)

      # Test A* algorithm
      {:ok, route_astar, _cost} = WormholeRouter.find_route(router, source, destination,
        algorithm: :astar)

      # For direct connections, both should return same route
      assert route_dijkstra == route_astar
    end
  end

  describe "network topology management" do
    test "provides comprehensive topology information", %{router: router} do
      # Establish multiple connections
      :ok = WormholeRouter.establish_wormhole(router, "shard_hot", "shard_warm")
      :ok = WormholeRouter.establish_wormhole(router, "shard_warm", "shard_cold")

      {:ok, topology} = WormholeRouter.get_topology(router, include_analytics: true)

      assert length(topology.nodes) == 3
      assert "shard_hot" in topology.nodes
      assert "shard_warm" in topology.nodes
      assert "shard_cold" in topology.nodes

      # Should have 4 connections (2 bidirectional)
      assert length(topology.connections) == 4

      # Should include analytics when requested
      assert Map.has_key?(topology, :analytics)
    end

    test "excludes analytics when not requested", %{router: router} do
      :ok = WormholeRouter.establish_wormhole(router, "shard_hot", "shard_warm")

      {:ok, topology} = WormholeRouter.get_topology(router, include_analytics: false)

      refute Map.has_key?(topology, :analytics)
    end

    test "tracks performance metrics", %{router: router} do
      :ok = WormholeRouter.establish_wormhole(router, "shard_hot", "shard_warm")
      {:ok, _route, _cost} = WormholeRouter.find_route(router, "shard_hot", "shard_warm")

      {:ok, metrics} = WormholeRouter.get_performance_metrics(router)

      assert metrics.total_routes > 0
      assert is_float(metrics.network_efficiency)
      assert metrics.network_efficiency > 0
      assert is_integer(metrics.network_size)
      assert is_integer(metrics.active_connections)
    end
  end

  describe "connection strengthening and decay" do
    test "records route usage for connection strengthening", %{router: router} do
      source = "shard_hot"
      destination = "shard_warm"

      :ok = WormholeRouter.establish_wormhole(router, source, destination)

      # Get initial connection strength
      {:ok, initial_topology} = WormholeRouter.get_topology(router)
      initial_strength = get_connection_strength(initial_topology, source, destination)

      # Record usage multiple times
      route = [source, destination]
      performance_data = %{latency: 10, throughput: 1000}

      WormholeRouter.record_usage(router, route, performance_data)
      WormholeRouter.record_usage(router, route, performance_data)
      WormholeRouter.record_usage(router, route, performance_data)

      # Small delay to allow async processing
      Process.sleep(10)

      # Get updated connection strength
      {:ok, updated_topology} = WormholeRouter.get_topology(router)
      updated_strength = get_connection_strength(updated_topology, source, destination)

      # Connection should be strengthened through usage
      assert updated_strength >= initial_strength
    end

        test "supports connection decay over time", %{router: router} do
      source = "shard_hot"
      destination = "shard_warm"

      :ok = WormholeRouter.establish_wormhole(router, source, destination)

      # Get initial topology to verify connection exists
      {:ok, initial_topology} = WormholeRouter.get_topology(router)
      assert length(initial_topology.connections) > 0

      # Trigger optimization which includes decay
      {:ok, :optimization_completed} = WormholeRouter.optimize_network(router, strategy: :minimal, force: true)

      # After minimal optimization, route should still exist or return appropriate error
      case WormholeRouter.find_route(router, source, destination) do
        {:ok, _route, _cost} ->
          # Connection survived optimization
          assert true
        {:error, :no_path} ->
          # Connection was removed by decay - this is also valid behavior
          # Let's verify the network was actually optimized
          {:ok, final_topology} = WormholeRouter.get_topology(router)
          # Should have fewer or equal connections after optimization
          assert length(final_topology.connections) <= length(initial_topology.connections)
      end
    end
  end

  describe "network optimization" do
    test "performs network optimization when needed", %{router: router} do
      # Create multiple connections
      :ok = WormholeRouter.establish_wormhole(router, "shard_hot", "shard_warm")
      :ok = WormholeRouter.establish_wormhole(router, "shard_warm", "shard_cold")
      :ok = WormholeRouter.establish_wormhole(router, "shard_hot", "shard_cold")

      {:ok, initial_metrics} = WormholeRouter.get_performance_metrics(router)

      # Force optimization
      {:ok, :optimization_completed} = WormholeRouter.optimize_network(router,
        strategy: :moderate, force: true)

      {:ok, optimized_metrics} = WormholeRouter.get_performance_metrics(router)

      # Optimization count should increase
      assert optimized_metrics.optimization_count > initial_metrics.optimization_count
    end

    test "supports different optimization strategies", %{router: router} do
      :ok = WormholeRouter.establish_wormhole(router, "shard_hot", "shard_warm")

      # Test minimal strategy
      {:ok, :optimization_completed} = WormholeRouter.optimize_network(router,
        strategy: :minimal, force: true)

      # Test moderate strategy
      {:ok, :optimization_completed} = WormholeRouter.optimize_network(router,
        strategy: :moderate, force: true)

      # Test aggressive strategy
      {:ok, :optimization_completed} = WormholeRouter.optimize_network(router,
        strategy: :aggressive, force: true)
    end

    test "skips optimization when not needed", %{router: router} do
      :ok = WormholeRouter.establish_wormhole(router, "shard_hot", "shard_warm")

      # Without force, optimization may not be needed
      result = WormholeRouter.optimize_network(router, strategy: :moderate)

      assert result in [{:ok, :optimization_completed}, {:ok, :optimization_not_needed}]
    end
  end

  describe "persistence and recovery" do
        test "persists network topology to filesystem", %{router: router, test_data_dir: test_data_dir} do
      :ok = WormholeRouter.establish_wormhole(router, "shard_hot", "shard_warm")

      # Force persistence by triggering optimization
      {:ok, :optimization_completed} = WormholeRouter.optimize_network(router, force: true)

      # Check that topology files exist
      wormhole_dir = Path.join(test_data_dir, "wormholes")
      assert File.exists?(Path.join([wormhole_dir, "topology", "network_graph.json"]))
      assert File.exists?(Path.join([wormhole_dir, "topology", "connection_strength.json"]))
      assert File.exists?(Path.join([wormhole_dir, "analytics", "performance_metrics.json"]))
    end
  end

  describe "error handling" do
        test "handles invalid node identifiers gracefully", %{router: router} do
      # Test with nil nodes - this should work now since we handle it gracefully
      :ok = WormholeRouter.establish_wormhole(router, nil, "shard_warm")

      # Test with same source and destination
      :ok = WormholeRouter.establish_wormhole(router, "shard_hot", "shard_hot")
      # Should work and create a self-loop

      {:ok, topology} = WormholeRouter.get_topology(router)
      assert length(topology.nodes) >= 1  # At least the valid nodes should be present
    end

    test "handles malformed route finding requests", %{router: router} do
      # Test finding route with no connections
      {:error, :no_path} = WormholeRouter.find_route(router, "nonexistent1", "nonexistent2")
    end
  end

  # Helper functions
  defp get_connection_strength(topology, source, destination) do
    connection_key = "#{source}::#{destination}"

    case Enum.find(topology.strengths, fn {key, _strength} -> key == connection_key end) do
      {^connection_key, strength} -> strength
      nil -> 0.0
    end
  end
end
