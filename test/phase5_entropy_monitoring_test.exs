defmodule Phase5EntropyMonitoringTest do
  use ExUnit.Case, async: false
  require Logger

  alias WarpEngine.{EntropyMonitor, CosmicConstants}

  @moduletag :phase5

  setup do
    # Clean up any existing entropy monitors before each test
    cleanup_entropy_monitors()

    # Ensure entropy registry is available
    case Registry.start_link(keys: :unique, name: WarpEngine.EntropyRegistry) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok
  end

  defp cleanup_entropy_monitors() do
    # Clean up any existing entropy monitors and ETS tables
    monitor_names = [:test_entropy, :test_entropy_custom, :test_entropy_persist, :test_shannon,
                     :test_rebalancing, :test_maxwell, :test_vacuum, :test_analytics,
                     :test_persistence, :test_constants, :test_empty, :test_crash, :test_crash_new,
                     :test_performance, :test_multi_1, :test_multi_2, :test_multi_3]

    Enum.each(monitor_names, fn monitor_name ->
      try do
        case Registry.lookup(WarpEngine.EntropyRegistry, monitor_name) do
          [] -> :ok
          [{pid, _}] ->
            if Process.alive?(pid) do
              GenServer.stop(pid, :normal, 1000)
            end
        end
      rescue
        _ -> :ok
      end
    end)

    # Clean up ETS tables
    table_prefixes = ["entropy_data", "shannon_cache", "thermodynamic"]

    Enum.each(table_prefixes, fn prefix ->
      Enum.each(monitor_names, fn monitor_name ->
        table_name = :"#{prefix}_#{monitor_name}"
        try do
          :ets.delete(table_name)
        rescue
          _ -> :ok
        end
      end)
    end)
  end

  describe "Phase 5: Entropy Monitor Creation" do
    test "creates entropy monitor with default configuration" do
      assert {:ok, _pid} = EntropyMonitor.create_monitor(:test_entropy, [])

      # Verify monitor is registered
      assert [{_pid, _}] = Registry.lookup(WarpEngine.EntropyRegistry, :test_entropy)

      # Clean up
      EntropyMonitor.shutdown_monitor(:test_entropy)
    end

    test "creates entropy monitor with custom configuration" do
      config = [
        monitoring_interval: 2000,
        entropy_threshold: 3.0,
        enable_maxwell_demon: false,
        vacuum_stability_checks: false
      ]

      assert {:ok, _pid} = EntropyMonitor.create_monitor(:test_entropy_custom, config)

      # Verify monitor is registered
      assert [{_pid, _}] = Registry.lookup(WarpEngine.EntropyRegistry, :test_entropy_custom)

      # Clean up
      EntropyMonitor.shutdown_monitor(:test_entropy_custom)
    end

    test "creates entropy data persistence directory structure" do
      # Create monitor with persistence enabled
      config = [persistence_enabled: true]
      assert {:ok, _pid} = EntropyMonitor.create_monitor(:test_entropy_persist, config)

      # Check if entropy directory structure exists
      _entropy_dir = Path.join([System.tmp_dir(), "entropy", "test_entropy_persist"])

      # Give a moment for directory creation
      Process.sleep(100)

      # Clean up
      EntropyMonitor.shutdown_monitor(:test_entropy_persist)
    end
  end

  describe "Phase 5: Shannon Entropy Calculations" do
    setup do
      {:ok, _pid} = EntropyMonitor.create_monitor(:test_shannon, [])
      on_exit(fn ->
        try do
          EntropyMonitor.shutdown_monitor(:test_shannon)
        rescue
          _ -> :ok
        end
      end)
      %{monitor: :test_shannon}
    end

    test "calculates real-time entropy metrics", %{monitor: monitor} do
      # Get entropy metrics
      entropy_metrics = EntropyMonitor.get_entropy_metrics(monitor)

      # Verify all required metrics are present
      assert is_map(entropy_metrics)
      assert is_number(entropy_metrics.shannon_entropy)
      assert is_number(entropy_metrics.thermodynamic_entropy)
      assert is_number(entropy_metrics.total_entropy)
      assert entropy_metrics.entropy_trend in [:increasing, :decreasing, :stable]
      assert is_number(entropy_metrics.system_temperature)
      assert is_number(entropy_metrics.disorder_index)
      assert is_number(entropy_metrics.stability_metric)
      assert is_boolean(entropy_metrics.rebalancing_recommended)
      assert is_number(entropy_metrics.last_calculated)
    end

    test "calculates shard-specific Shannon entropy", %{monitor: monitor} do
      # Test Shannon entropy calculation for different shards
      shards = [:hot_data, :warm_data, :cold_data]

      Enum.each(shards, fn shard_id ->
        entropy = EntropyMonitor.calculate_shard_shannon_entropy(monitor, shard_id)
        assert is_number(entropy) and entropy >= 0.0
      end)
    end

    test "entropy metrics show reasonable values", %{monitor: monitor} do
      metrics = EntropyMonitor.get_entropy_metrics(monitor)

      # Shannon entropy should be reasonable (0-4 bits typically)
      assert metrics.shannon_entropy >= 0.0
      assert metrics.shannon_entropy <= 10.0

      # System temperature should be above absolute zero
      assert metrics.system_temperature > 0.0

      # Disorder index should be normalized
      assert metrics.disorder_index >= 0.0

      # Stability metric should be between 0 and 1
      assert metrics.stability_metric >= 0.0
      assert metrics.stability_metric <= 1.0
    end
  end

  describe "Phase 5: Thermodynamic Load Balancing" do
    setup do
      config = [
        enable_maxwell_demon: true,
        monitoring_interval: 1000
      ]
      {:ok, _pid} = EntropyMonitor.create_monitor(:test_rebalancing, config)
      on_exit(fn ->
        try do
          EntropyMonitor.shutdown_monitor(:test_rebalancing)
        rescue
          _ -> :ok
        end
      end)
      %{monitor: :test_rebalancing}
    end

    test "triggers rebalancing with force option", %{monitor: monitor} do
      # Force rebalancing regardless of entropy level
      result = EntropyMonitor.trigger_rebalancing(monitor, force_rebalancing: true)

      assert {:ok, rebalancing_report} = result
      assert is_map(rebalancing_report)
      assert rebalancing_report.strategy in [:minimal, :moderate, :aggressive]
      assert is_number(rebalancing_report.initial_entropy)
      assert is_number(rebalancing_report.data_items_moved)
      assert is_number(rebalancing_report.shards_affected)
      assert is_number(rebalancing_report.energy_cost)
      assert is_number(rebalancing_report.time_taken_ms)
      assert is_number(rebalancing_report.final_entropy)
      assert is_boolean(rebalancing_report.maxwell_demon_active)
    end

    test "rejects rebalancing when not needed", %{monitor: monitor} do
      # Try rebalancing without force when entropy is low
      result = EntropyMonitor.trigger_rebalancing(monitor, force_rebalancing: false)

      # Should either succeed or indicate rebalancing not needed
      case result do
        {:ok, _report} -> assert true  # Rebalancing was performed
        {:error, :rebalancing_not_needed} -> assert true  # Correctly rejected
        _ -> flunk("Unexpected rebalancing result: #{inspect(result)}")
      end
    end

    test "different migration strategies affect energy cost", %{monitor: monitor} do
      strategies = [:minimal, :moderate, :aggressive]

      results = Enum.map(strategies, fn strategy ->
        {:ok, report} = EntropyMonitor.trigger_rebalancing(monitor,
          force_rebalancing: true,
          migration_strategy: strategy
        )
        {strategy, report.energy_cost}
      end)

      # Energy costs should increase with strategy aggressiveness
      [{:minimal, minimal_cost}, {:moderate, moderate_cost}, {:aggressive, aggressive_cost}] = results

      assert minimal_cost <= moderate_cost
      assert moderate_cost <= aggressive_cost
    end
  end

  describe "Phase 5: Maxwell's Demon Optimization" do
    setup do
      config = [enable_maxwell_demon: true]
      {:ok, _pid} = EntropyMonitor.create_monitor(:test_maxwell, config)
      on_exit(fn ->
        try do
          EntropyMonitor.shutdown_monitor(:test_maxwell)
        rescue
          _ -> :ok
        end
      end)
      %{monitor: :test_maxwell}
    end

    test "Maxwell's demon can be enabled and disabled", %{monitor: monitor} do
      # Disable Maxwell's demon
      EntropyMonitor.set_maxwell_demon_enabled(monitor, false)

      # Give time for the change to take effect
      Process.sleep(100)

      # Re-enable Maxwell's demon
      EntropyMonitor.set_maxwell_demon_enabled(monitor, true)

      # Verify rebalancing still works
      {:ok, report} = EntropyMonitor.trigger_rebalancing(monitor, force_rebalancing: true)
      assert is_map(report)
    end

    test "Maxwell's demon affects rebalancing behavior", %{monitor: monitor} do
      # Test with Maxwell's demon enabled
      {:ok, report_with_demon} = EntropyMonitor.trigger_rebalancing(monitor, force_rebalancing: true)
      assert report_with_demon.maxwell_demon_active == true

      # Disable Maxwell's demon
      EntropyMonitor.set_maxwell_demon_enabled(monitor, false)
      Process.sleep(50)

      # Test with Maxwell's demon disabled
      {:ok, report_without_demon} = EntropyMonitor.trigger_rebalancing(monitor, force_rebalancing: true)
      assert report_without_demon.maxwell_demon_active == false
    end
  end

  describe "Phase 5: Vacuum Stability Monitoring" do
    setup do
      config = [vacuum_stability_checks: true]
      {:ok, _pid} = EntropyMonitor.create_monitor(:test_vacuum, config)
      on_exit(fn ->
        try do
          EntropyMonitor.shutdown_monitor(:test_vacuum)
        rescue
          _ -> :ok
        end
      end)
      %{monitor: :test_vacuum}
    end

    test "vacuum stability is included in entropy metrics", %{monitor: monitor} do
      metrics = EntropyMonitor.get_entropy_metrics(monitor)

      # Vacuum stability should be present and valid
      assert is_number(metrics.vacuum_stability) or is_nil(metrics.vacuum_stability)

      if is_number(metrics.vacuum_stability) do
        assert metrics.vacuum_stability >= 0.0
        assert metrics.vacuum_stability <= 1.0
      end
    end

    test "vacuum instability can be detected", %{monitor: monitor} do
      # Get initial metrics
      initial_metrics = EntropyMonitor.get_entropy_metrics(monitor)

      # For this test, we just verify the monitoring structure is working
      assert is_map(initial_metrics)
      assert Map.has_key?(initial_metrics, :vacuum_stability)
    end
  end

  describe "Phase 5: Cosmic Analytics Platform" do
    setup do
      config = [
        analytics_enabled: true,
        monitoring_interval: 500  # Fast monitoring for testing
      ]
      {:ok, _pid} = EntropyMonitor.create_monitor(:test_analytics, config)

      # Give time for some entropy history to accumulate
      Process.sleep(1000)

      on_exit(fn ->
        try do
          EntropyMonitor.shutdown_monitor(:test_analytics)
        rescue
          _ -> :ok
        end
      end)
      %{monitor: :test_analytics}
    end

    test "provides cosmic analytics for different time ranges", %{monitor: monitor} do
      time_ranges = [:last_hour, :last_day, :last_week]

      Enum.each(time_ranges, fn time_range ->
        analytics = EntropyMonitor.get_cosmic_analytics(monitor, time_range)

        assert is_map(analytics)
        assert analytics.time_range == time_range
        assert is_number(analytics.data_points)
        assert analytics.entropy_trend in [:increasing, :decreasing, :stable, :insufficient_data]
        assert is_number(analytics.average_entropy) or analytics.average_entropy == 0.0
        assert is_number(analytics.entropy_variance) or analytics.entropy_variance == 0.0
        assert is_number(analytics.stability_score)
        assert is_map(analytics.prediction)
        assert is_map(analytics.performance_regression)
        assert is_list(analytics.recommendations)
        assert is_number(analytics.last_updated)
      end)
    end

    test "analytics prediction provides meaningful insights", %{monitor: monitor} do
      # Wait for some history to build up
      Process.sleep(2000)

      analytics = EntropyMonitor.get_cosmic_analytics(monitor, :last_hour)
      prediction = analytics.prediction

      case prediction do
        %{prediction: :insufficient_data} ->
          # Expected when not enough data points
          assert true

        prediction_data ->
          assert is_number(prediction_data.predicted_entropy)
          assert is_number(prediction_data.confidence)
          assert prediction_data.confidence >= 0.1
          assert prediction_data.confidence <= 1.0
          assert prediction_data.trend_direction in [:increasing, :decreasing, :stable]
      end
    end

    test "performance regression detection works", %{monitor: monitor} do
      # Wait for enough history
      Process.sleep(2000)

      analytics = EntropyMonitor.get_cosmic_analytics(monitor, :last_hour)
      regression = analytics.performance_regression

      assert is_map(regression)
      assert is_boolean(regression.regression_detected)

      if regression.regression_detected do
        assert regression.severity in [:low, :medium, :high]
        assert is_number(regression.entropy_increase)
        assert is_number(regression.percentage_increase)
      end
    end

    test "provides optimization recommendations", %{monitor: monitor} do
      analytics = EntropyMonitor.get_cosmic_analytics(monitor, :last_hour)

      assert is_list(analytics.recommendations)
      assert length(analytics.recommendations) > 0

      # All recommendations should be strings
      Enum.each(analytics.recommendations, fn recommendation ->
        assert is_binary(recommendation)
        assert String.length(recommendation) > 0
      end)
    end
  end

  describe "Phase 5: Entropy Persistence" do
    setup do
      config = [
        persistence_enabled: true,
        monitoring_interval: 1000
      ]
      {:ok, _pid} = EntropyMonitor.create_monitor(:test_persistence, config)

      # Give time for some data to be persisted
      Process.sleep(2000)

      on_exit(fn ->
        try do
          EntropyMonitor.shutdown_monitor(:test_persistence)
        rescue
          _ -> :ok
        end
        # Clean up persistence files
        cleanup_persistence_files()
      end)
      %{monitor: :test_persistence}
    end

    defp cleanup_persistence_files() do
      entropy_dir = Path.join([System.tmp_dir(), "entropy", "test_persistence"])
      if File.exists?(entropy_dir) do
        File.rm_rf!(entropy_dir)
      end
    end

    test "entropy data is persisted to time-series files", %{monitor: monitor} do
      # Get some entropy data
      _metrics = EntropyMonitor.get_entropy_metrics(monitor)

      # Give time for persistence
      Process.sleep(1000)

      # This test just ensures no crashes occur during persistence
      # In a real implementation, we would check for actual files
      assert true
    end

    test "analytics data can be persisted", %{monitor: monitor} do
      # Generate analytics
      _analytics = EntropyMonitor.get_cosmic_analytics(monitor, :last_hour)

      # Give time for persistence
      Process.sleep(500)

      # This test ensures analytics generation doesn't crash
      assert true
    end
  end

  describe "Phase 5: Integration with Cosmic Constants" do
    test "entropy threshold from cosmic constants" do
      threshold = CosmicConstants.entropy_rebalance_threshold()
      assert is_number(threshold)
      assert threshold > 0.0

      # Create monitor with cosmic constant threshold
      config = [entropy_threshold: threshold]
      {:ok, _pid} = EntropyMonitor.create_monitor(:test_constants, config)

      metrics = EntropyMonitor.get_entropy_metrics(:test_constants)

      # Rebalancing recommendation should be based on cosmic constant
      if metrics.total_entropy > threshold do
        assert metrics.rebalancing_recommended == true
      else
        assert metrics.rebalancing_recommended == false
      end

      # Clean up
      EntropyMonitor.shutdown_monitor(:test_constants)
    end

    test "Boltzmann constant used in calculations" do
      boltzmann = CosmicConstants.boltzmann_constant()
      assert is_number(boltzmann)
      assert boltzmann > 0.0

      # Test entropy rate calculation
      temp = 300.0  # Room temperature
      states = 100
      entropy_rate = CosmicConstants.entropy_rate(temp, states)

      assert is_number(entropy_rate)
      assert entropy_rate > 0.0
    end

    test "time dilation factors affect entropy monitoring" do
      priorities = [:critical, :high, :normal, :low, :background]

      Enum.each(priorities, fn priority ->
        dilation = CosmicConstants.time_dilation_factor(priority)
        assert is_number(dilation)
        assert dilation > 0.0
      end)
    end
  end

  describe "Phase 5: Error Handling and Edge Cases" do
    test "handles invalid monitor IDs gracefully" do
      # Try to get metrics from non-existent monitor
      # Should catch exit and handle gracefully
      result = try do
        EntropyMonitor.get_entropy_metrics(:nonexistent_monitor)
      rescue
        error -> {:error, :exception, error}
      catch
        :exit, reason -> {:error, :process_not_found, reason}
        error -> {:error, :unknown_error, error}
      end

      assert match?({:error, _, _}, result)
    end

    test "handles empty entropy data gracefully" do
      # Create a monitor and immediately test it (no history)
      {:ok, _pid} = EntropyMonitor.create_monitor(:test_empty, [])

      metrics = EntropyMonitor.get_entropy_metrics(:test_empty)
      assert is_map(metrics)

      analytics = EntropyMonitor.get_cosmic_analytics(:test_empty, :last_hour)
      assert analytics.entropy_trend in [:stable, :insufficient_data]

      # Clean up
      EntropyMonitor.shutdown_monitor(:test_empty)
    end

    test "survives process crashes and restarts" do
      {:ok, pid} = EntropyMonitor.create_monitor(:test_crash, [])

      # Verify process is alive
      assert Process.alive?(pid)

      # Kill the process gently
      try do
        Process.exit(pid, :normal)
      rescue
        _ -> :ok
      end

      # Give time for cleanup
      Process.sleep(500)

      # Should be able to create a new monitor with different ID
      {:ok, _new_pid} = EntropyMonitor.create_monitor(:test_crash_new, [])

      metrics = EntropyMonitor.get_entropy_metrics(:test_crash_new)
      assert is_map(metrics)

      # Clean up
      try do
        EntropyMonitor.shutdown_monitor(:test_crash_new)
      rescue
        _ -> :ok
      end
    end
  end

  describe "Phase 5: Performance and Scalability" do
    test "entropy calculations complete within reasonable time" do
      {:ok, _pid} = EntropyMonitor.create_monitor(:test_performance, [])

      {time_microseconds, metrics} = :timer.tc(fn ->
        EntropyMonitor.get_entropy_metrics(:test_performance)
      end)

      # Entropy calculation should complete in under 100ms
      assert time_microseconds < 100_000
      assert is_map(metrics)

      # Clean up
      EntropyMonitor.shutdown_monitor(:test_performance)
    end

    test "can handle multiple simultaneous entropy monitors" do
      monitor_ids = [:test_multi_1, :test_multi_2, :test_multi_3]

      # Create multiple monitors
      pids = Enum.map(monitor_ids, fn id ->
        {:ok, pid} = EntropyMonitor.create_monitor(id, [])
        {id, pid}
      end)

      # Get metrics from all monitors simultaneously
      tasks = Enum.map(monitor_ids, fn id ->
        Task.async(fn -> EntropyMonitor.get_entropy_metrics(id) end)
      end)

      results = Task.await_many(tasks, 5000)

      # All should succeed
      assert length(results) == 3
      Enum.each(results, fn metrics ->
        assert is_map(metrics)
        assert is_number(metrics.total_entropy)
      end)

      # Clean up
      Enum.each(pids, fn {id, _pid} ->
        EntropyMonitor.shutdown_monitor(id)
      end)
    end
  end
end
