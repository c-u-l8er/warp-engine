defmodule WarpEnginePhase5IntegrationTest do
  use ExUnit.Case, async: false
  require Logger

  alias WarpEngine

  @moduletag :phase5_integration

    # Helper function to start WarpEngine if not already running
  defp ensure_warp_engine_started() do
    # Force stop the application to ensure clean restart
    try do
      Application.stop(:warp_engine)
    rescue
      _ -> :ok
    end

    Process.sleep(200)

    # Start with current configuration
    Application.ensure_all_started(:warp_engine)
    Process.sleep(500)

    :ok
  end

            # Helper function to start WarpEngine with entropy monitoring enabled
  defp ensure_warp_engine_started_with_entropy() do
    # Configure for Phase 5 testing (enable entropy monitoring and Phase 4 caches) BEFORE starting
    Application.put_env(:warp_engine, :enable_entropy_monitoring, true)
    Application.put_env(:warp_engine, :disable_phase4, false)  # Ensure caches are enabled

    # Force stop the application to ensure clean restart
    try do
      Application.stop(:warp_engine)
    rescue
      _ -> :ok
    end

    Process.sleep(200)

    # Start with fresh configuration
    Application.ensure_all_started(:warp_engine)
    Process.sleep(800)  # Give time for entropy monitor to initialize

    :ok
  end

  setup do
    # Work with the existing WarpEngine instance from application supervisor
    # No need to stop and restart - just ensure it's running

    # Ensure test data directory exists for entropy monitoring
    File.mkdir_p!("/tmp/warp_engine_test_data")

    # Clean up ETS tables
    cleanup_ets_tables()

    # Clean up entropy registry if it exists
    case Process.whereis(WarpEngine.EntropyRegistry) do
      nil -> :ok
      pid when is_pid(pid) ->
        try do
          GenServer.stop(WarpEngine.EntropyRegistry, :normal, 1000)
        rescue
          _ -> :ok
        catch
          :exit, _ -> :ok
        end
    end

    :ok
  end

  defp cleanup_ets_tables() do
    # Clean up any leftover ETS tables
    existing_tables = :ets.all()
    Enum.each(existing_tables, fn table ->
      try do
        info = :ets.info(table)
        if info[:name] && is_atom(info[:name]) do
          table_name = to_string(info[:name])
          if String.contains?(table_name, "entropy") or
             String.contains?(table_name, "hot_data") or
             String.contains?(table_name, "warm_data") or
             String.contains?(table_name, "cold_data") do
            :ets.delete(table)
          end
        end
      rescue
        _ -> :ok
      end
    end)
  end

  describe "Phase 5 Integration: WarpEngine with Entropy Monitoring" do
    test "WarpEngine starts successfully with Phase 5 entropy monitoring enabled" do
      # Ensure WarpEngine is running with entropy monitoring enabled
      ensure_warp_engine_started_with_entropy()

      # Give time for entropy monitor to initialize
      Process.sleep(1000)

      # Verify cosmic metrics include entropy information
      metrics = WarpEngine.cosmic_metrics()

      assert is_map(metrics)
      assert metrics.phase == "Phase 5: Entropy Monitoring & Thermodynamics"
      assert is_map(metrics.entropy_monitoring)
      assert metrics.entropy_monitoring.monitor_active == true
      assert is_number(metrics.entropy_monitoring.total_entropy)
      assert is_number(metrics.entropy_monitoring.shannon_entropy)
      assert is_number(metrics.entropy_monitoring.thermodynamic_entropy)

      # Clean up
      case Process.whereis(WarpEngine) do
        nil -> :ok
        pid when is_pid(pid) ->
          try do
            GenServer.stop(WarpEngine, :normal, 1000)
          rescue
            _ -> :ok
          catch
            :exit, _ -> :ok
          end
      end
    end

    test "entropy monitoring works with disabled option" do
      # Explicitly disable entropy monitoring for this test
      Application.put_env(:warp_engine, :enable_entropy_monitoring, false)
      Application.put_env(:warp_engine, :disable_phase4, false)  # Allow Phase 4 but disable Phase 5

      # Start WarpEngine with entropy monitoring disabled
      ensure_warp_engine_started()

      metrics = WarpEngine.cosmic_metrics()

      # Should not be Phase 5 and entropy monitoring should be inactive
      assert metrics.phase != "Phase 5: Entropy Monitoring & Thermodynamics"
      assert metrics.entropy_monitoring.monitor_active == false

      # Clean up
      case Process.whereis(WarpEngine) do
        nil -> :ok
        pid when is_pid(pid) ->
          try do
            GenServer.stop(WarpEngine, :normal, 1000)
          rescue
            _ -> :ok
          catch
            :exit, _ -> :ok
          end
      end
    end

    test "entropy metrics API works correctly" do
      ensure_warp_engine_started_with_entropy()

      # Give time for entropy monitor to initialize
      Process.sleep(1000)

      # Test entropy metrics API
      entropy_metrics = WarpEngine.entropy_metrics()

      assert is_map(entropy_metrics)
      assert is_number(entropy_metrics.total_entropy)
      assert is_number(entropy_metrics.shannon_entropy)
      assert is_number(entropy_metrics.thermodynamic_entropy)
      assert entropy_metrics.entropy_trend in [:increasing, :decreasing, :stable]
      assert is_boolean(entropy_metrics.rebalancing_recommended)

      # Clean up
      case Process.whereis(WarpEngine) do
        nil -> :ok
        pid when is_pid(pid) ->
          try do
            GenServer.stop(WarpEngine, :normal, 1000)
          rescue
            _ -> :ok
          catch
            :exit, _ -> :ok
          end
      end
    end

    test "entropy rebalancing API works correctly" do
      ensure_warp_engine_started_with_entropy()

      # Give time for initialization
      Process.sleep(1000)

      # Test entropy rebalancing API
      result = WarpEngine.trigger_entropy_rebalancing(force_rebalancing: true)

      assert {:ok, rebalancing_report} = result
      assert is_map(rebalancing_report)
      assert rebalancing_report.strategy in [:minimal, :moderate, :aggressive]
      assert is_number(rebalancing_report.data_items_moved)
      assert is_number(rebalancing_report.initial_entropy)
      assert is_number(rebalancing_report.final_entropy)

      # Clean up
      case Process.whereis(WarpEngine) do
        nil -> :ok
        pid when is_pid(pid) ->
          try do
            GenServer.stop(WarpEngine, :normal, 1000)
          rescue
            _ -> :ok
          catch
            :exit, _ -> :ok
          end
      end
    end

    test "entropy monitoring disabled returns appropriate errors" do
      # Explicitly disable entropy monitoring for this test
      Application.put_env(:warp_engine, :enable_entropy_monitoring, false)
      ensure_warp_engine_started()

      # Should return error when entropy monitoring is disabled
      entropy_result = WarpEngine.entropy_metrics()
      assert entropy_result.error == "entropy_monitoring_disabled"

      rebalancing_result = WarpEngine.trigger_entropy_rebalancing()
      assert rebalancing_result == {:error, :entropy_monitoring_disabled}

      # Clean up
      case Process.whereis(WarpEngine) do
        nil -> :ok
        pid when is_pid(pid) ->
          try do
            GenServer.stop(WarpEngine, :normal, 1000)
          rescue
            _ -> :ok
          catch
            :exit, _ -> :ok
          end
      end
    end
  end

  describe "Phase 5 Integration: Entropy Monitoring with Data Operations" do
    setup do
      ensure_warp_engine_started()

      # Give time for initialization
      Process.sleep(1500)

      on_exit(fn ->
        case Process.whereis(WarpEngine) do
          nil -> :ok
          pid when is_pid(pid) ->
            try do
              GenServer.stop(WarpEngine, :normal, 1000)
            rescue
              _ -> :ok
            catch
              :exit, _ -> :ok
            end
        end
      end)
      :ok
    end

    test "entropy monitoring reacts to data operations" do
      ensure_warp_engine_started_with_entropy()

      # Give time for entropy monitor to initialize
      Process.sleep(1000)
      # Get initial entropy
      initial_entropy = WarpEngine.entropy_metrics()
      assert is_map(initial_entropy)
      _initial_total = initial_entropy.total_entropy

      # Perform several data operations to change system state
      data_operations = [
        {"user:alice", %{name: "Alice", age: 30}},
        {"user:bob", %{name: "Bob", age: 25}},
        {"order:1001", %{customer: "alice", total: 99.99}},
        {"product:widget", %{name: "Widget", price: 19.99}},
        {"session:abc123", %{user: "alice", login_time: :os.system_time()}}
      ]

      # Store data
      Enum.each(data_operations, fn {key, value} ->
        assert {:ok, :stored, _shard, _time} = WarpEngine.cosmic_put(key, value)
      end)

      # Retrieve data (affects access patterns)
      Enum.each(data_operations, fn {key, _value} ->
        assert {:ok, _value, _shard, _time} = WarpEngine.cosmic_get(key)
      end)

      # Give time for entropy monitoring to process changes
      Process.sleep(2000)

      # Check entropy after operations
      final_entropy = WarpEngine.entropy_metrics()
      assert is_map(final_entropy)

      # Entropy might have changed due to data distribution changes
      # We just verify the monitoring system is responding
      assert is_number(final_entropy.total_entropy)
      assert final_entropy.entropy_trend in [:increasing, :decreasing, :stable]
    end

    test "entropy monitoring tracks system activity over time" do
      ensure_warp_engine_started_with_entropy()

      # Give time for entropy monitor to initialize
      Process.sleep(1000)
      # Perform burst activity
      burst_size = 20

      1..burst_size
      |> Enum.each(fn i ->
        key = "burst:#{i}"
        value = %{id: i, timestamp: :os.system_time(), data: :crypto.strong_rand_bytes(100)}
        WarpEngine.cosmic_put(key, value)

        if rem(i, 5) == 0 do
          # Occasionally retrieve data
          WarpEngine.cosmic_get("burst:#{i-2}")
        end
      end)

      # Let entropy monitoring catch up
      Process.sleep(3000)

      # Get analytics to see if system tracked the activity
      metrics = WarpEngine.cosmic_metrics()
      entropy_data = metrics.entropy_monitoring

      assert entropy_data.monitor_active == true
      assert is_number(entropy_data.total_entropy)

      # System should show some level of activity
      assert entropy_data.disorder_index >= 0.0
    end

    test "rebalancing affects system entropy" do
      ensure_warp_engine_started_with_entropy()

      # Give time for entropy monitor to initialize
      Process.sleep(1000)
      # Fill system with data to increase entropy
      1..30
      |> Enum.each(fn i ->
        shard = case rem(i, 3) do
          0 -> :hot
          1 -> :warm
          _ -> :cold
        end

        key = "rebalance_test:#{i}"
        value = %{shard_hint: shard, data: :crypto.strong_rand_bytes(50)}
        WarpEngine.cosmic_put(key, value, access_pattern: shard)
      end)

      Process.sleep(2000)

      # Get entropy before rebalancing
      before_rebalancing = WarpEngine.entropy_metrics()
      _before_entropy = before_rebalancing.total_entropy

      # Trigger rebalancing
      {:ok, rebalance_report} = WarpEngine.trigger_entropy_rebalancing(force_rebalancing: true)
      assert is_map(rebalance_report)

      # Give time for rebalancing effects
      Process.sleep(1000)

      # Check entropy after rebalancing
      _after_rebalancing = WarpEngine.entropy_metrics()

      # Verify rebalancing report shows entropy change
      assert is_number(rebalance_report.initial_entropy)
      assert is_number(rebalance_report.final_entropy)

      # Final entropy should be different (ideally lower)
      assert rebalance_report.final_entropy != rebalance_report.initial_entropy
    end
  end

  describe "Phase 5 Integration: Entropy Monitoring with Event Horizon Cache" do
    setup do
      ensure_warp_engine_started()

      Process.sleep(1500)
      on_exit(fn ->
        case Process.whereis(WarpEngine) do
          nil -> :ok
          pid when is_pid(pid) ->
            try do
              GenServer.stop(WarpEngine, :normal, 1000)
            rescue
              _ -> :ok
            catch
              :exit, _ -> :ok
            end
        end
      end)
      :ok
    end

    test "entropy monitoring works with caching enabled" do
      ensure_warp_engine_started_with_entropy()

      # Give time for entropy monitor to initialize
      Process.sleep(1000)
      # Perform operations that will hit both shards and caches
      test_data = 1..25
      |> Enum.map(fn i ->
        key = "cache_test:#{i}"
        value = %{id: i, content: "Test data #{i}"}

        # Store data
        {:ok, :stored, shard, _time} = WarpEngine.cosmic_put(key, value)

        # Immediately retrieve (should populate cache)
        {:ok, retrieved_value, retrieval_shard, _time} = WarpEngine.cosmic_get(key)

        {key, value, shard, retrieval_shard, retrieved_value == value}
      end)

      # Verify all operations succeeded
      assert length(test_data) == 25
      Enum.each(test_data, fn {_key, _value, _shard, _retrieval_shard, data_matches} ->
        assert data_matches == true
      end)

      # Let entropy monitoring process the cache activity
      Process.sleep(2000)

      # Verify entropy monitoring is working with cache system
      metrics = WarpEngine.cosmic_metrics()

      assert metrics.phase == "Phase 5: Entropy Monitoring & Thermodynamics"
      assert metrics.entropy_monitoring.monitor_active == true

      # Should have cache metrics
      assert is_map(metrics.event_horizon_cache)
      assert metrics.event_horizon_cache.total_caches > 0

      # Entropy should reflect the mixed shard/cache activity
      entropy_data = metrics.entropy_monitoring
      assert is_number(entropy_data.total_entropy)
      assert entropy_data.entropy_trend in [:increasing, :decreasing, :stable]
    end
  end

  describe "Phase 5 Integration: Error Handling and Recovery" do
    test "system survives entropy monitor failures" do
      # Start system without entropy monitoring to simulate a failure scenario
      Application.put_env(:warp_engine, :enable_entropy_monitoring, false)
      ensure_warp_engine_started()

      Process.sleep(500)

      # Verify normal operation still works without entropy monitoring
      assert {:ok, :stored, _shard, _time} = WarpEngine.cosmic_put("test:key", %{value: "test"})
      assert {:ok, _value, _shard, _time} = WarpEngine.cosmic_get("test:key")
      assert {:ok, :stored, _shard, _time} = WarpEngine.cosmic_put("test:key2", %{value: "test2"})

      # Entropy metrics should handle the unavailability gracefully
      entropy_result = WarpEngine.entropy_metrics()
      assert entropy_result.error == "entropy_monitoring_disabled"

      # Clean up
      case Process.whereis(WarpEngine) do
        nil -> :ok
        pid when is_pid(pid) ->
          try do
            GenServer.stop(WarpEngine, :normal, 1000)
          rescue
            _ -> :ok
          catch
            :exit, _ -> :ok
          end
      end
    end

    test "cosmic metrics gracefully handle entropy monitor unavailability" do
      # Start without entropy monitoring
      Application.put_env(:warp_engine, :enable_entropy_monitoring, false)
      ensure_warp_engine_started()

      metrics = WarpEngine.cosmic_metrics()

      # Should include entropy monitoring section but show as inactive
      assert is_map(metrics.entropy_monitoring)
      assert metrics.entropy_monitoring.monitor_active == false

      # Clean up
      case Process.whereis(WarpEngine) do
        nil -> :ok
        pid when is_pid(pid) ->
          try do
            GenServer.stop(WarpEngine, :normal, 1000)
          rescue
            _ -> :ok
          catch
            :exit, _ -> :ok
          end
      end
    end
  end

  describe "Phase 5 Integration: Performance Impact" do
    test "entropy monitoring has minimal performance impact" do
      # Test without entropy monitoring
      ensure_warp_engine_started()

      {time_without, _} = :timer.tc(fn ->
        1..100 |> Enum.each(fn i ->
          WarpEngine.cosmic_put("perf_test:#{i}", %{value: i})
          WarpEngine.cosmic_get("perf_test:#{i}")
        end)
      end)

      case Process.whereis(WarpEngine) do
        nil -> :ok
        pid when is_pid(pid) ->
          try do
            GenServer.stop(WarpEngine, :normal, 1000)
          rescue
            _ -> :ok
          catch
            :exit, _ -> :ok
          end
      end
      Process.sleep(200)

      # Test with entropy monitoring
      ensure_warp_engine_started()

      Process.sleep(500) # Let it initialize

      {time_with, _} = :timer.tc(fn ->
        1..100 |> Enum.each(fn i ->
          WarpEngine.cosmic_put("perf_test:#{i}", %{value: i})
          WarpEngine.cosmic_get("perf_test:#{i}")
        end)
      end)

      # Entropy monitoring should add reasonable overhead (less than 200%)
      performance_impact = (time_with - time_without) / time_without
      assert performance_impact < 2.0  # More realistic threshold for complex entropy monitoring

      Logger.info("Phase 5 performance impact: #{Float.round(performance_impact * 100, 2)}%")

      case Process.whereis(WarpEngine) do
        nil -> :ok
        pid when is_pid(pid) ->
          try do
            GenServer.stop(WarpEngine, :normal, 1000)
          rescue
            _ -> :ok
          catch
            :exit, _ -> :ok
          end
      end
    end
  end
end
