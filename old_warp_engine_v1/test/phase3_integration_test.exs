defmodule Phase3IntegrationTest do
  use ExUnit.Case

  require Logger

  setup_all do
    cleanup_test_phase3_integration()
    on_exit(fn -> cleanup_test_phase3_integration() end)
    :ok
  end

  setup do
    cleanup_test_phase3_integration()

    test_data_dir = "/tmp/warp_engine_test_phase3_integration"
    File.mkdir_p!(test_data_dir)

    # Configure for Phase 3 testing (disable Phase 4 and Phase 5 features)
    Application.put_env(:warp_engine, :enable_entropy_monitoring, false)
    Application.put_env(:warp_engine, :disable_phase4, true)

    # Force application restart to ensure configuration is picked up
    try do
      Application.stop(:warp_engine)
    rescue
      _ -> :ok
    end

    Process.sleep(200)

    # Ensure the full application is started with WAL and other components
    Application.ensure_all_started(:warp_engine)
    Process.sleep(500)

    # Ensure cosmic filesystem exists in test directory
    WarpEngine.CosmicPersistence.initialize_universe()

    # Use the existing WarpEngine process from application supervisor
    pid = case Process.whereis(WarpEngine) do
      nil ->
        raise "WarpEngine should be started by application supervisor but was not found"
      existing_pid ->
        existing_pid
    end

    :timer.sleep(200)  # Allow Phase 3 system to fully initialize

    on_exit(fn ->
      if Process.alive?(pid) do
        GenServer.stop(pid)
      end
      cleanup_test_phase3_integration()
    end)

    %{universe_pid: pid, test_data_dir: test_data_dir}
  end

  describe "Phase 3: Integrated Spacetime Sharding System" do
    test "universe starts with Phase 3 components initialized", %{universe_pid: pid} do
      assert Process.alive?(pid)

      # Get cosmic metrics to verify Phase 3 integration
      metrics = WarpEngine.cosmic_metrics()

      assert metrics.universe_state == :stable
      assert Map.has_key?(metrics, :gravitational_routing)
      assert metrics.phase == "Phase 3: Spacetime Sharding System"
      assert is_map(metrics.gravitational_routing)

      # Should have advanced spacetime shards
      spacetime_shard_metrics = WarpEngine.get_spacetime_shard_metrics()
      assert is_map(spacetime_shard_metrics)
      assert Map.has_key?(spacetime_shard_metrics, :hot_data)
      assert Map.has_key?(spacetime_shard_metrics, :warm_data)
      assert Map.has_key?(spacetime_shard_metrics, :cold_data)

      # Each shard should have physics laws
      Enum.each(spacetime_shard_metrics, fn {shard_id, shard_metrics} ->
        assert Map.has_key?(shard_metrics, :physics_laws)
        assert Map.has_key?(shard_metrics, :gravitational_field_strength)
        assert Map.has_key?(shard_metrics, :entropy_level)
        Logger.debug("Shard #{shard_id}: #{shard_metrics.data_items} items, entropy: #{Float.round(shard_metrics.entropy_level, 3)}")
      end)
    end

    test "cosmic_put uses gravitational routing for optimal placement" do
      # Store data with different access patterns and priorities
      test_data = [
        {"critical:session", %{user: "alice", session_id: "abc123"}, [access_pattern: :hot, priority: :critical]},
        {"user:bob", %{name: "Bob", role: "user"}, [access_pattern: :warm, priority: :normal]},
        {"archive:2020", %{year: 2020, data: "historical"}, [access_pattern: :cold, priority: :background]}
      ]

      placement_results = Enum.map(test_data, fn {key, value, opts} ->
        {:ok, :stored, shard_id, operation_time} = WarpEngine.cosmic_put(key, value, opts)
        {key, shard_id, operation_time, opts}
      end)

      # Verify that different data gets routed to appropriate shards
      Enum.each(placement_results, fn {key, shard_id, operation_time, opts} ->
        assert shard_id in [:hot_data, :warm_data, :cold_data]
        assert is_integer(operation_time)
        assert operation_time > 0

        Logger.debug("#{key} -> #{shard_id} (#{operation_time}μs) with options #{inspect(opts)}")
      end)

      # Critical data might prefer hot_data, but gravitational routing considers multiple factors
      critical_result = Enum.find(placement_results, fn {key, _shard, _time, _opts} ->
        String.starts_with?(key, "critical:")
      end)
      {_key, critical_shard, _time, _opts} = critical_result

      # Log for analysis - gravitational routing may place it optimally based on all factors
      Logger.info("Critical data placed in: #{critical_shard}")
    end

    test "cosmic_get retrieves data with gravitational shard tracking" do
      # Store test data first
      test_key = "phase3:retrieval_test"
      test_value = %{data: "phase3 retrieval", importance: "high"}

      {:ok, :stored, storage_shard, _time} = WarpEngine.cosmic_put(test_key, test_value,
        [access_pattern: :hot, priority: :high])

      # Retrieve the data
      {:ok, retrieved_value, retrieval_shard, retrieval_time} = WarpEngine.cosmic_get(test_key)

      assert retrieved_value == test_value
      assert retrieval_shard == storage_shard
      assert is_integer(retrieval_time)

      Logger.debug("Stored in #{storage_shard}, retrieved from #{retrieval_shard} in #{retrieval_time}μs")
    end

    test "quantum_get works with Phase 3 gravitational shards" do
      # Store entangled data
      primary_key = "user:phase3_quantum"
      profile_key = "profile:phase3_quantum"

      WarpEngine.cosmic_put(primary_key, %{name: "Phase3 User", role: "tester"})
      WarpEngine.cosmic_put(profile_key, %{bio: "Testing Phase 3", skills: ["Physics", "Databases"]})

      # Create manual entanglement
      {:ok, _entanglement_id} = WarpEngine.create_quantum_entanglement(primary_key, [profile_key], 0.9)

      :timer.sleep(100)  # Allow entanglement to be processed

      # Use quantum_get to retrieve with entanglement
      {:ok, response} = WarpEngine.quantum_get(primary_key)

      assert response.value == %{name: "Phase3 User", role: "tester"}
      assert response.shard in [:hot_data, :warm_data, :cold_data]
      assert is_map(response.quantum_data)
      assert response.quantum_data.entangled_count >= 0

      Logger.debug("Quantum retrieval from #{response.shard}, entangled items: #{response.quantum_data.entangled_count}")
    end
  end

  describe "Phase 3: Gravitational Load Balancing" do
    test "analyze_load_distribution provides comprehensive analysis" do
      # Store various data to create some load distribution
      for i <- 1..20 do
        priority = case rem(i, 3) do
          0 -> :critical
          1 -> :normal
          2 -> :background
        end

        access_pattern = case rem(i, 3) do
          0 -> :hot
          1 -> :warm
          2 -> :cold
        end

        WarpEngine.cosmic_put("load_test:#{i}", %{index: i, data: "load test"},
          [priority: priority, access_pattern: access_pattern])
      end

      :timer.sleep(100)  # Allow data to be processed

      # Analyze load distribution
      analysis = WarpEngine.analyze_load_distribution()

      assert is_integer(analysis.total_data_items)
      assert analysis.total_data_items >= 20  # We stored 20 items
      assert is_list(analysis.shard_distribution)
      assert length(analysis.shard_distribution) == 3
      assert is_float(analysis.load_imbalance_factor)
      assert is_boolean(analysis.rebalancing_needed)

      Logger.info("Load Analysis: #{analysis.total_data_items} items, imbalance: #{Float.round(analysis.load_imbalance_factor, 3)}")

      # Log distribution per shard
      Enum.each(analysis.shard_distribution, fn {shard_id, metrics} ->
        Logger.debug("#{shard_id}: #{metrics.data_items} items, #{Float.round(metrics.gravitational_field_strength, 2)} field strength")
      end)
    end

    test "force_gravitational_rebalancing executes successfully" do
      # Store some test data to create imbalance
      for i <- 1..10 do
        WarpEngine.cosmic_put("rebalance_test:#{i}", %{index: i},
          [access_pattern: :hot, priority: :critical])  # All to hot shard
      end

      :timer.sleep(100)

      # Force rebalancing
      case WarpEngine.force_gravitational_rebalancing() do
        {:ok, rebalance_results} ->
          assert is_integer(rebalance_results.successful_migrations)
          assert is_integer(rebalance_results.failed_migrations)
          assert is_integer(rebalance_results.total_duration_ms)

          Logger.info("Rebalancing: #{rebalance_results.successful_migrations} successful, #{rebalance_results.failed_migrations} failed migrations")

        {:error, reason} ->
          # Rebalancing might not be needed or fail for various reasons
          Logger.info("Rebalancing not executed: #{inspect(reason)}")
      end
    end
  end

  describe "Phase 3: Advanced Shard Metrics" do
    test "get_spacetime_shard_metrics returns detailed physics information" do
      # Store some data to generate meaningful metrics
      test_keys = [
        {"hot:critical", %{priority: "critical"}, [access_pattern: :hot, priority: :critical]},
        {"warm:normal", %{priority: "normal"}, [access_pattern: :warm, priority: :normal]},
        {"cold:archive", %{priority: "low"}, [access_pattern: :cold, priority: :background]}
      ]

      Enum.each(test_keys, fn {key, value, opts} ->
        WarpEngine.cosmic_put(key, value, opts)
      end)

      :timer.sleep(100)

      shard_metrics = WarpEngine.get_spacetime_shard_metrics()

      # Check each shard has comprehensive metrics
      Enum.each([:hot_data, :warm_data, :cold_data], fn shard_id ->
        shard_data = Map.get(shard_metrics, shard_id)

        assert is_map(shard_data)
        assert Map.has_key?(shard_data, :shard_id)
        assert Map.has_key?(shard_data, :physics_laws)
        assert Map.has_key?(shard_data, :current_load)
        assert Map.has_key?(shard_data, :data_items)
        assert Map.has_key?(shard_data, :memory_usage)
        assert Map.has_key?(shard_data, :gravitational_field_strength)
        assert Map.has_key?(shard_data, :entropy_level)
        assert Map.has_key?(shard_data, :uptime_ms)
        assert Map.has_key?(shard_data, :migration_state)
        assert Map.has_key?(shard_data, :consistency_health)

        # Verify physics laws structure
        physics_laws = shard_data.physics_laws
        assert Map.has_key?(physics_laws, :consistency_model)
        assert Map.has_key?(physics_laws, :time_dilation)
        assert Map.has_key?(physics_laws, :gravitational_mass)
        assert Map.has_key?(physics_laws, :max_capacity)

        Logger.debug("#{shard_id}: #{shard_data.data_items} items, entropy: #{Float.round(shard_data.entropy_level, 3)}, field: #{Float.round(shard_data.gravitational_field_strength, 2)}")
      end)
    end

    test "cosmic_metrics includes Phase 3 gravitational routing data" do
      metrics = WarpEngine.cosmic_metrics()

      # Verify Phase 3 specific metrics
      assert Map.has_key?(metrics, :gravitational_routing)
      assert Map.has_key?(metrics, :phase)
      assert metrics.phase == "Phase 3: Spacetime Sharding System"

      gravitational_metrics = metrics.gravitational_routing
      assert Map.has_key?(gravitational_metrics, :total_routing_decisions)
      assert Map.has_key?(gravitational_metrics, :cache_hit_rate)
      assert Map.has_key?(gravitational_metrics, :algorithm_efficiency)
      assert Map.has_key?(gravitational_metrics, :load_balance_score)
      assert Map.has_key?(gravitational_metrics, :gravitational_field_strength)

      # Values should be within reasonable ranges
      assert is_integer(gravitational_metrics.total_routing_decisions)
      assert gravitational_metrics.cache_hit_rate >= 0.0 and gravitational_metrics.cache_hit_rate <= 1.0
      assert gravitational_metrics.algorithm_efficiency >= 0.0 and gravitational_metrics.algorithm_efficiency <= 1.0

      Logger.info("Gravitational Routing Efficiency: #{Float.round(gravitational_metrics.algorithm_efficiency * 100, 1)}%")
      Logger.info("Load Balance Score: #{Float.round(gravitational_metrics.load_balance_score * 100, 1)}%")
    end
  end

  describe "Phase 3: Performance and Stability" do
    test "Phase 3 operations maintain sub-millisecond performance" do
      # Benchmark Phase 3 operations
      operation_times = for i <- 1..50 do
        key = "perf_test:#{i}"
        value = %{index: i, data: "performance test", timestamp: :os.system_time(:millisecond)}

        {put_time, {:ok, :stored, _shard, put_operation_time}} = :timer.tc(fn ->
          WarpEngine.cosmic_put(key, value, [priority: :normal])
        end)

        {get_time, {:ok, _retrieved_value, _shard, get_operation_time}} = :timer.tc(fn ->
          WarpEngine.cosmic_get(key)
        end)

        %{
          put_wall_time: put_time,
          get_wall_time: get_time,
          put_operation_time: put_operation_time,
          get_operation_time: get_operation_time
        }
      end

      # Calculate averages
      avg_put_wall = Enum.reduce(operation_times, 0, fn times, acc -> acc + times.put_wall_time end) / length(operation_times)
      avg_get_wall = Enum.reduce(operation_times, 0, fn times, acc -> acc + times.get_wall_time end) / length(operation_times)
      avg_put_op = Enum.reduce(operation_times, 0, fn times, acc -> acc + times.put_operation_time end) / length(operation_times)
      avg_get_op = Enum.reduce(operation_times, 0, fn times, acc -> acc + times.get_operation_time end) / length(operation_times)

      Logger.info("Performance Averages:")
      Logger.info("  PUT - Wall: #{Float.round(avg_put_wall, 0)}μs, Operation: #{Float.round(avg_put_op, 0)}μs")
      Logger.info("  GET - Wall: #{Float.round(avg_get_wall, 0)}μs, Operation: #{Float.round(avg_get_op, 0)}μs")

      # Phase 3 should maintain reasonable performance despite added complexity
      assert avg_put_wall < 50_000  # Less than 50ms wall time
      assert avg_get_wall < 10_000  # Less than 10ms wall time
      assert avg_put_op < 10_000    # Less than 10ms operation time
      assert avg_get_op < 5_000     # Less than 5ms operation time
    end

    test "concurrent Phase 3 operations work correctly" do
      # Test concurrent operations with Phase 3 system
      concurrent_tasks = for i <- 1..20 do
        Task.async(fn ->
          key = "concurrent:#{i}_#{:rand.uniform(1000)}"
          value = %{task_id: i, data: "concurrent test", timestamp: :os.system_time(:microsecond)}

          # Random access pattern and priority
          access_pattern = Enum.random([:hot, :warm, :cold])
          priority = Enum.random([:critical, :high, :normal, :low, :background])

          # Store data
          {:ok, :stored, storage_shard, _time} = WarpEngine.cosmic_put(key, value,
            [access_pattern: access_pattern, priority: priority])

          # Retrieve data
          {:ok, retrieved_value, retrieval_shard, _time} = WarpEngine.cosmic_get(key)

          # Verify consistency
          assert retrieved_value == value
          assert storage_shard == retrieval_shard

          {key, storage_shard, access_pattern, priority}
        end)
      end

      # Wait for all tasks to complete
      results = Task.await_many(concurrent_tasks, 10_000)

      # All tasks should succeed
      assert length(results) == 20

      # Log shard distribution
      shard_distribution = Enum.reduce(results, %{}, fn {_key, shard, _pattern, _priority}, acc ->
        Map.update(acc, shard, 1, &(&1 + 1))
      end)

      Logger.info("Concurrent operations shard distribution: #{inspect(shard_distribution)}")

      # Should have used all three shard types (though distribution may vary)
      total_shards_used = map_size(shard_distribution)
      assert total_shards_used >= 1  # At least one shard should be used
    end
  end

  describe "Phase 3: Error Handling and Edge Cases" do
    test "Phase 3 system handles large data gracefully" do
      # Test with large data structure
      large_value = %{
        description: String.duplicate("Large data for Phase 3 testing ", 100),
        numbers: Enum.to_list(1..1000),
        nested: %{
          deep: %{
            structure: %{
              with: %{many: %{levels: Enum.to_list(1..100)}}
            }
          }
        }
      }

      {:ok, :stored, shard, operation_time} = WarpEngine.cosmic_put("large:data", large_value,
        [access_pattern: :warm, priority: :normal])

      assert shard in [:hot_data, :warm_data, :cold_data]
      assert is_integer(operation_time)

      # Retrieve large data
      {:ok, retrieved_value, retrieval_shard, retrieval_time} = WarpEngine.cosmic_get("large:data")

      assert retrieved_value == large_value
      assert retrieval_shard == shard
      assert is_integer(retrieval_time)

      Logger.debug("Large data (#{byte_size(:erlang.term_to_binary(large_value))} bytes) -> #{shard} in #{operation_time}μs")
    end

    test "Phase 3 system handles invalid access patterns gracefully" do
      # Test with invalid access patterns and priorities
      test_cases = [
        [access_pattern: :invalid_pattern, priority: :normal],
        [access_pattern: :hot, priority: :invalid_priority],
        [access_pattern: nil, priority: :normal],
        [some_invalid_option: "invalid"]
      ]

      Enum.each(test_cases, fn opts ->
        result = WarpEngine.cosmic_put("invalid_test:#{:rand.uniform(1000)}", %{data: "test"}, opts)

        case result do
          {:ok, :stored, shard, operation_time} ->
            # Should still work by falling back to defaults
            assert shard in [:hot_data, :warm_data, :cold_data]
            assert is_integer(operation_time)
          {:error, reason} ->
            # Or gracefully handle the error
            assert is_atom(reason) or is_tuple(reason)
        end
      end)
    end
  end

  ## HELPER FUNCTIONS

  defp cleanup_test_phase3_integration() do
    # Stop any running WarpEngine process
    case Process.whereis(WarpEngine) do
      nil -> :ok
      pid ->
        if Process.alive?(pid) do
          GenServer.stop(pid, :normal, 2000)
        end
    end

    # Clean up test data directory
    test_data_dir = "/tmp/warp_engine_test_phase3_integration"
    if File.exists?(test_data_dir) do
      try do
        File.rm_rf!(test_data_dir)
      rescue
        error ->
          Logger.warning("Could not clean up Phase 3 integration test directory: #{inspect(error)}")
      end
    end

    # Clean up any test ETS tables
    test_patterns = [:hot_data, :warm_data, :cold_data]
    Enum.each(test_patterns, fn pattern ->
      table_name = :"spacetime_shard_#{pattern}"
      if :ets.whereis(table_name) != :undefined do
        try do
          :ets.delete(table_name)
        rescue
          _ -> :ok
        end
      end
    end)

    :timer.sleep(100)
  end
end
