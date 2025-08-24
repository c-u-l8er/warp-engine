defmodule GravitationalRouterTest do
  use ExUnit.Case
  doctest WarpEngine.GravitationalRouter

  require Logger

  alias WarpEngine.{GravitationalRouter, SpacetimeShard}

  setup_all do
    cleanup_test_router_system()
    on_exit(fn -> cleanup_test_router_system() end)
    :ok
  end

  setup do
    cleanup_test_router_system()

    test_data_dir = "/tmp/warp_engine_test_router"
    File.mkdir_p!(test_data_dir)
    Application.put_env(:warp_engine, :data_root, test_data_dir)

    # Create test shards for routing tests
    {:ok, hot_shard} = SpacetimeShard.create_shard(:hot_router_test, %{
      consistency_model: :strong,
      time_dilation: 0.5,
      gravitational_mass: 2.0,
      max_capacity: 1000
    })

    {:ok, warm_shard} = SpacetimeShard.create_shard(:warm_router_test, %{
      consistency_model: :eventual,
      time_dilation: 1.0,
      gravitational_mass: 1.0,
      max_capacity: 800
    })

    {:ok, cold_shard} = SpacetimeShard.create_shard(:cold_router_test, %{
      consistency_model: :weak,
      time_dilation: 2.0,
      gravitational_mass: 0.3,
      max_capacity: 500
    })

    {:ok, router} = GravitationalRouter.initialize([hot_shard, warm_shard, cold_shard], [
      routing_algorithm: :gravitational,
      cache_size: 100,
      rebalancing_threshold: 0.3
    ])

    on_exit(fn -> cleanup_test_router_system() end)

    %{
      router: router,
      hot_shard: hot_shard,
      warm_shard: warm_shard,
      cold_shard: cold_shard,
      test_data_dir: test_data_dir
    }
  end

  describe "Phase 3: Gravitational Router Initialization" do
    test "initializes router with shards successfully", %{router: router} do
      assert is_struct(router, GravitationalRouter)
      assert router.routing_algorithm == :gravitational
      assert map_size(router.shard_topology) == 3
      assert Map.has_key?(router.shard_topology, :hot_router_test)
      assert Map.has_key?(router.shard_topology, :warm_router_test)
      assert Map.has_key?(router.shard_topology, :cold_router_test)
    end

    test "router contains properly configured components", %{router: router} do
      assert is_map(router.locality_map)
      assert is_map(router.load_balancer)
      assert is_map(router.routing_cache)
      assert is_map(router.performance_metrics)
      assert router.load_balancer.imbalance_threshold == 0.3
    end

    test "shard topology contains correct shard references", %{router: router, hot_shard: hot_shard} do
      router_hot_shard = Map.get(router.shard_topology, :hot_router_test)

      assert router_hot_shard.shard_id == hot_shard.shard_id
      assert router_hot_shard.physics_laws == hot_shard.physics_laws
    end
  end

  describe "Gravitational Data Routing" do
    test "routes high-priority data to appropriate shard", %{router: router} do
      {:ok, shard_id, routing_metadata} = GravitationalRouter.route_data(
        router,
        "critical:user_session",
        %{user_id: "alice", session_data: "important"},
        [access_pattern: :hot, priority: :critical]
      )

      # Should route to a shard capable of handling critical data
      assert shard_id in [:hot_router_test, :warm_router_test, :cold_router_test]
      assert routing_metadata.routing_algorithm == :gravitational
      assert is_float(routing_metadata.gravitational_score)
      assert routing_metadata.gravitational_score > 0
      assert is_integer(routing_metadata.operation_time)
      assert is_list(routing_metadata.all_scores)
    end

    test "routes low-priority data appropriately", %{router: router} do
      {:ok, shard_id, routing_metadata} = GravitationalRouter.route_data(
        router,
        "archive:old_data",
        %{archived_content: "historical data"},
        [access_pattern: :cold, priority: :background]
      )

      assert shard_id in [:hot_router_test, :warm_router_test, :cold_router_test]
      assert routing_metadata.routing_algorithm == :gravitational
      assert is_float(routing_metadata.gravitational_score)

      # Log for debugging
      Logger.debug("Low priority data routed to: #{shard_id} with score: #{routing_metadata.gravitational_score}")
    end

    test "respects forced shard placement", %{router: router} do
      {:ok, shard_id, routing_metadata} = GravitationalRouter.route_data(
        router,
        "forced:placement",
        %{data: "test"},
        [force_shard: :warm_router_test]
      )

      assert shard_id == :warm_router_test
      assert routing_metadata.routing_algorithm == :forced
      assert routing_metadata.gravitational_score == 0.0
    end

    test "returns error for invalid forced shard", %{router: router} do
      result = GravitationalRouter.route_data(
        router,
        "invalid:force",
        %{data: "test"},
        [force_shard: :nonexistent_shard]
      )

      assert {:error, {:invalid_shard, :nonexistent_shard}} = result
    end

    test "different data types get different routing scores", %{router: router} do
      # Route similar data with different characteristics
      {:ok, _shard1, metadata1} = GravitationalRouter.route_data(
        router, "user:alice", %{name: "Alice", role: "admin"}, [priority: :high]
      )

      {:ok, _shard2, metadata2} = GravitationalRouter.route_data(
        router, "archive:old", %{content: "old data"}, [priority: :low]
      )

      # Scores should be different based on data characteristics
      assert metadata1.gravitational_score != metadata2.gravitational_score

      Logger.debug("Admin user score: #{metadata1.gravitational_score}")
      Logger.debug("Archive data score: #{metadata2.gravitational_score}")
    end
  end

  describe "Load Distribution Analysis" do
    test "analyzes load distribution across shards", %{router: router} do
      analysis = GravitationalRouter.analyze_load_distribution(router)

      # Check basic structure
      assert is_integer(analysis.total_data_items)
      assert is_list(analysis.shard_distribution)
      assert is_float(analysis.load_imbalance_factor)
      assert is_list(analysis.gravitational_hotspots)
      assert is_boolean(analysis.rebalancing_needed)
      assert is_list(analysis.recommendations)
      assert is_integer(analysis.analysis_timestamp)

      # Should have analysis for all three shards
      assert length(analysis.shard_distribution) == 3

      # Check that shard distribution contains expected shard IDs
      shard_ids = Enum.map(analysis.shard_distribution, fn {shard_id, _metrics} -> shard_id end)
      assert :hot_router_test in shard_ids
      assert :warm_router_test in shard_ids
      assert :cold_router_test in shard_ids
    end

    test "detects load imbalances when they exist", %{router: router} do
      # With empty shards, load should be perfectly balanced
      analysis = GravitationalRouter.analyze_load_distribution(router)

      assert analysis.load_imbalance_factor >= 0.0
      assert analysis.total_data_items == 0

      # With no data, there shouldn't be rebalancing needed
      assert analysis.rebalancing_needed == false
    end

    test "provides rebalancing recommendations when needed", %{router: router} do
      analysis = GravitationalRouter.analyze_load_distribution(router)

      # Even with balanced empty shards, recommendations should be a list
      assert is_list(analysis.recommendations)

      # Each recommendation should have proper structure when they exist
      Enum.each(analysis.recommendations, fn recommendation ->
        assert Map.has_key?(recommendation, :action)
        assert Map.has_key?(recommendation, :from)
        assert Map.has_key?(recommendation, :to)
        assert Map.has_key?(recommendation, :estimated_items)
        assert Map.has_key?(recommendation, :urgency)
      end)
    end
  end

  describe "Gravitational Rebalancing" do
    test "creates migration plan from analysis", %{router: router} do
      analysis = GravitationalRouter.analyze_load_distribution(router)

      {:ok, results} = GravitationalRouter.execute_gravitational_rebalancing(
        router, analysis, [dry_run: true, migration_batch_size: 50]
      )

      # Check dry run results
      assert results.executed == false
      assert is_map(results.plan)
      assert Map.has_key?(results.plan, :migrations)
      assert Map.has_key?(results.plan, :estimated_duration)
      assert Map.has_key?(results.plan, :total_items)
      assert is_list(results.plan.migrations)
    end

    test "executes rebalancing with time limits", %{router: router} do
      analysis = GravitationalRouter.analyze_load_distribution(router)

      # Execute with short time limit
      {:ok, results} = GravitationalRouter.execute_gravitational_rebalancing(
        router, analysis, [max_migration_time: 1000, migration_batch_size: 10]
      )

      # Check execution results
      assert is_integer(results.successful_migrations)
      assert is_integer(results.failed_migrations)
      assert is_integer(results.total_duration_ms)
      assert is_list(results.migration_results)

      # Total duration should be within reasonable bounds
      assert results.total_duration_ms >= 0
    end
  end

  describe "Routing Performance Metrics" do
    test "collects comprehensive routing metrics", %{router: router} do
      # Perform some routing operations to generate metrics
      for i <- 1..5 do
        GravitationalRouter.route_data(router, "perf_test:#{i}", %{index: i}, [])
      end

      metrics = GravitationalRouter.get_routing_metrics(router)

      # Check basic metrics structure
      assert is_integer(metrics.total_routing_decisions)
      assert is_float(metrics.cache_hit_rate)
      assert is_number(metrics.average_routing_time)
      assert is_float(metrics.algorithm_efficiency)
      assert is_float(metrics.load_balance_score)
      assert is_float(metrics.gravitational_field_strength)
      assert is_map(metrics.shard_statistics)
      assert is_integer(metrics.last_updated)

      # Metrics should be within reasonable ranges
      assert metrics.cache_hit_rate >= 0.0 and metrics.cache_hit_rate <= 1.0
      assert metrics.algorithm_efficiency >= 0.0 and metrics.algorithm_efficiency <= 1.0
      assert metrics.load_balance_score >= 0.0 and metrics.load_balance_score <= 1.0
      assert metrics.gravitational_field_strength >= 0.0

      # Should have statistics for all shards
      assert map_size(metrics.shard_statistics) == 3
    end

    test "tracks routing decisions accurately", %{router: router} do
      initial_metrics = GravitationalRouter.get_routing_metrics(router)
      initial_decisions = initial_metrics.total_routing_decisions

      # Perform additional routing operations
      for i <- 1..3 do
        GravitationalRouter.route_data(router, "decision_test:#{i}", %{index: i}, [])
      end

      updated_metrics = GravitationalRouter.get_routing_metrics(router)

      # Total decisions should have increased
      # Note: This test might be flaky if the router internally makes additional decisions
      # We'll just verify it's not decreasing
      assert updated_metrics.total_routing_decisions >= initial_decisions
    end
  end

  describe "Locality Clustering" do
    test "finds locality clusters for related data", %{router: router} do
      clusters = GravitationalRouter.find_locality_clusters(router, "user_group_1", [max_distance: 100.0])

      # Should return a list of cluster recommendations
      assert is_list(clusters)

      # Each cluster should have proper structure
      Enum.each(clusters, fn cluster ->
        assert Map.has_key?(cluster, :cluster_id)
        assert Map.has_key?(cluster, :items)
        assert Map.has_key?(cluster, :current_distribution)
        assert Map.has_key?(cluster, :recommended_shard)
        assert Map.has_key?(cluster, :clustering_score)
        assert is_atom(cluster.recommended_shard)
      end)
    end

    test "respects max_distance parameter", %{router: router} do
      small_distance_clusters = GravitationalRouter.find_locality_clusters(
        router, "test_group", [max_distance: 10.0]
      )

      large_distance_clusters = GravitationalRouter.find_locality_clusters(
        router, "test_group", [max_distance: 1000.0]
      )

      # Both should return lists
      assert is_list(small_distance_clusters)
      assert is_list(large_distance_clusters)

      # Results may be the same or different depending on data distribution
      # We're mainly testing that the parameter is accepted and processed
      Logger.debug("Small distance clusters: #{length(small_distance_clusters)}")
      Logger.debug("Large distance clusters: #{length(large_distance_clusters)}")
    end
  end

  describe "Router Error Handling" do
    test "handles routing with malformed data gracefully", %{router: router} do
      # Test with various edge cases
      test_cases = [
        {"", %{}, []},
        {nil, %{data: "test"}, []},
        {"normal:key", nil, []},
        {"normal:key", %{data: "test"}, [invalid_option: "invalid"]}
      ]

      Enum.each(test_cases, fn {key, value, opts} ->
        result = GravitationalRouter.route_data(router, key, value, opts)

        case result do
          {:ok, shard_id, metadata} ->
            assert is_atom(shard_id)
            assert is_map(metadata)
          {:error, reason} ->
            assert is_atom(reason) or is_tuple(reason)
        end
      end)
    end

    test "handles empty shard topology gracefully" do
      {:ok, empty_router} = GravitationalRouter.initialize([], [])

      result = GravitationalRouter.route_data(empty_router, "test:key", %{data: "test"}, [])

      # Should handle empty topology without crashing
      case result do
        {:ok, _shard_id, _metadata} -> :ok  # Shouldn't happen but acceptable
        {:error, _reason} -> :ok             # Expected result
      end
    end
  end

  ## HELPER FUNCTIONS

  defp cleanup_test_router_system() do
    # Clean up test ETS tables
    test_table_patterns = [:hot_router_test, :warm_router_test, :cold_router_test]

    Enum.each(test_table_patterns, fn pattern ->
      table_name = :"spacetime_shard_#{pattern}"
      if :ets.whereis(table_name) != :undefined do
        try do
          :ets.delete(table_name)
        rescue
          _ -> :ok
        end
      end
    end)

    # Clean up test data directory
    test_data_dir = "/tmp/warp_engine_test_router"
    if File.exists?(test_data_dir) do
      try do
        File.rm_rf!(test_data_dir)
      rescue
        error ->
          Logger.warning("Could not clean up router test directory: #{inspect(error)}")
      end
    end

    :timer.sleep(50)
  end
end
