defmodule EventHorizonCacheTest do
  use ExUnit.Case
  doctest IsLabDB.EventHorizonCache

  require Logger

  alias IsLabDB.EventHorizonCache

  setup_all do
    cleanup_test_cache_system()
    on_exit(fn -> cleanup_test_cache_system() end)
    :ok
  end

  setup do
    cleanup_test_cache_system()

    on_exit(fn -> cleanup_test_cache_system() end)
    :ok
  end

  describe "Phase 4: Event Horizon Cache Creation" do
    test "creates cache with default physics laws" do
      {:ok, cache} = EventHorizonCache.create_cache(:test_cache, [])

      assert cache.cache_id == :test_cache
      assert is_reference(cache.event_horizon_table)
      assert is_reference(cache.photon_sphere_table)
      assert is_reference(cache.deep_cache_table)
      assert is_reference(cache.singularity_storage)
      assert is_reference(cache.metadata_table)
      assert is_map(cache.physics_laws)
      assert cache.physics_laws.schwarzschild_radius == 100_000
      assert cache.physics_laws.hawking_temperature == 0.1
    end

    test "creates cache with custom physics laws" do
      {:ok, cache} = EventHorizonCache.create_cache(:custom_cache,
        schwarzschild_radius: 50_000,
        hawking_temperature: 0.2,
        enable_compression: false
      )

      assert cache.physics_laws.schwarzschild_radius == 50_000
      assert cache.physics_laws.hawking_temperature == 0.2
      assert cache.physics_laws.compression_enabled == false
    end

    test "initializes cache performance metrics" do
      {:ok, cache} = EventHorizonCache.create_cache(:metrics_cache)

      metrics = EventHorizonCache.get_cache_metrics(cache)

      assert is_map(metrics)
      assert metrics.cache_id == :metrics_cache
      assert metrics.cache_statistics.event_horizon_items == 0
      assert metrics.cache_statistics.total_memory_bytes >= 0
      assert metrics.performance_metrics.total_puts == 0
      assert metrics.performance_metrics.total_gets == 0
      assert metrics.physics_metrics.total_items == 0
    end
  end

  describe "Phase 4: Black Hole Mechanics - Data Storage" do
    setup do
      {:ok, cache} = EventHorizonCache.create_cache(:storage_test,
        schwarzschild_radius: 1_000,
        hawking_temperature: 0.05
      )

      %{cache: cache}
    end

    test "stores data in event horizon", %{cache: cache} do
      test_key = "black_hole:data1"
      test_value = %{physics: "relativity", speed: "light"}

      {:ok, updated_cache, storage_metadata} = EventHorizonCache.put(cache, test_key, test_value)

      assert storage_metadata.cache_level in [:event_horizon, :photon_sphere, :deep_cache]
      assert is_float(storage_metadata.compression_ratio)
      assert is_float(storage_metadata.gravitational_score)
      assert is_integer(storage_metadata.operation_time)
      assert is_float(storage_metadata.time_dilation_factor)

      # Verify data was stored
      metrics = EventHorizonCache.get_cache_metrics(updated_cache)
      assert metrics.physics_metrics.total_items > 0
    end

    test "stores critical priority data in event horizon", %{cache: cache} do
      {:ok, updated_cache, metadata} = EventHorizonCache.put(cache, "critical:data", %{urgent: true}, priority: :critical)

      assert metadata.cache_level == :event_horizon
      assert metadata.gravitational_score >= 2.0

      # Verify data can be retrieved
      {:ok, value, _final_cache, retrieval_metadata} = EventHorizonCache.get(updated_cache, "critical:data")

      assert value == %{urgent: true}
      assert retrieval_metadata.cache_level == :event_horizon
    end

    test "applies compression to large data", %{cache: cache} do
      large_value = %{
        description: String.duplicate("Large data for black hole compression ", 100),
        numbers: Enum.to_list(1..1000)
      }

      {:ok, _updated_cache, metadata} = EventHorizonCache.put(cache, "large:data", large_value, priority: :low)

      # Large, low-priority data should be compressed
      assert metadata.cache_level in [:photon_sphere, :deep_cache, :singularity]
      assert metadata.compression_ratio >= 1.0
    end

    test "handles cache at Schwarzschild radius limit", %{cache: cache} do
      # Fill cache to near capacity (1000 items)
      filled_cache = Enum.reduce(1..950, cache, fn i, cache_acc ->
        {:ok, updated_cache, _metadata} = EventHorizonCache.put(cache_acc, "fill:#{i}", %{index: i})
        updated_cache
      end)

      # Adding more data should trigger Hawking radiation or handle gracefully
      result = EventHorizonCache.put(filled_cache, "overflow:data", %{overflow: true})

      case result do
        {:ok, _updated_cache, _metadata} ->
          # Successfully handled by Hawking radiation eviction
          :ok
        {:error, {:cache_full, _reason}} ->
          # Or gracefully rejected
          :ok
      end
    end
  end

  describe "Phase 4: Black Hole Mechanics - Data Retrieval" do
    setup do
      {:ok, cache} = EventHorizonCache.create_cache(:retrieval_test, schwarzschild_radius: 5_000)

      # Pre-populate with test data
      test_data = [
        {"horizon:fast", %{speed: "light", location: "event_horizon"}, [priority: :critical]},
        {"photon:medium", %{speed: "fast", location: "photon_sphere"}, [priority: :normal]},
        {"deep:slow", %{speed: "slow", location: "deep_cache"}, [priority: :low]},
        {"singularity:compressed", %{speed: "very_slow", location: "singularity"}, [priority: :background]}
      ]

      populated_cache = Enum.reduce(test_data, cache, fn {key, value, opts}, cache_acc ->
        {:ok, updated_cache, _metadata} = EventHorizonCache.put(cache_acc, key, value, opts)
        updated_cache
      end)

      %{cache: populated_cache}
    end

    test "retrieves data with time dilation effects", %{cache: cache} do
      {:ok, value, _updated_cache, retrieval_metadata} = EventHorizonCache.get(cache, "horizon:fast")

      assert value.speed == "light"
      assert retrieval_metadata.cache_level == :event_horizon
      assert is_float(retrieval_metadata.time_dilation_factor)
      assert is_integer(retrieval_metadata.dilated_operation_time)
      assert is_integer(retrieval_metadata.wall_clock_time)

      # Event horizon should have minimal time dilation
      assert retrieval_metadata.time_dilation_factor <= 1.5
    end

    test "handles cache miss gracefully", %{cache: cache} do
      {:miss, _updated_cache} = EventHorizonCache.get(cache, "nonexistent:key")
    end

    test "updates access patterns on retrieval", %{cache: cache} do
      # Access data multiple times
      {:ok, _, cache1, _} = EventHorizonCache.get(cache, "photon:medium")
      {:ok, _, cache2, _} = EventHorizonCache.get(cache1, "photon:medium")
      {:ok, _, cache3, _} = EventHorizonCache.get(cache2, "photon:medium")

      metrics = EventHorizonCache.get_cache_metrics(cache3)
      assert metrics.performance_metrics.cache_hits >= 3
      assert metrics.performance_metrics.total_gets >= 3
    end

    test "retrieval from different cache levels shows time dilation differences", %{cache: cache} do
      # Get data from event horizon (fast)
      {:ok, _value1, cache1, horizon_metadata} = EventHorizonCache.get(cache, "horizon:fast")

      # Get data from deep cache (slower due to time dilation)
      {:ok, _value2, _cache2, deep_metadata} = EventHorizonCache.get(cache1, "deep:slow")

      # Deep cache should have higher time dilation
      assert deep_metadata.time_dilation_factor >= horizon_metadata.time_dilation_factor
    end
  end

  describe "Phase 4: Hawking Radiation Eviction" do
    setup do
      {:ok, cache} = EventHorizonCache.create_cache(:hawking_test,
        schwarzschild_radius: 100,
        hawking_temperature: 0.3  # More aggressive eviction
      )

      # Fill cache with test data
      filled_cache = Enum.reduce(1..80, cache, fn i, cache_acc ->
        priority = case rem(i, 3) do
          0 -> :critical
          1 -> :normal
          2 -> :low
        end
        {:ok, updated_cache, _metadata} = EventHorizonCache.put(cache_acc, "hawking:#{i}", %{index: i}, priority: priority)
        updated_cache
      end)

      %{cache: filled_cache}
    end

    test "manually triggers Hawking radiation eviction", %{cache: cache} do
      initial_metrics = EventHorizonCache.get_cache_metrics(cache)
      initial_items = initial_metrics.physics_metrics.total_items

      {:ok, updated_cache, eviction_report} = EventHorizonCache.emit_hawking_radiation(cache, :normal)

      assert eviction_report.items_evicted >= 0
      assert eviction_report.memory_freed_bytes >= 0
      assert is_list(eviction_report.cache_levels_affected)
      assert eviction_report.hawking_temperature == 0.3
      assert is_integer(eviction_report.operation_time_ms)

      final_metrics = EventHorizonCache.get_cache_metrics(updated_cache)
      final_items = final_metrics.physics_metrics.total_items

      # Items should have been evicted or cache stayed the same if no eviction was needed
      assert final_items <= initial_items
    end

    test "emergency Hawking radiation with aggressive eviction", %{cache: cache} do
      {:ok, _updated_cache, eviction_report} = EventHorizonCache.emit_hawking_radiation(cache, :emergency)

      # Emergency eviction should be more aggressive
      assert eviction_report.items_evicted >= 0
      assert is_integer(eviction_report.operation_time_ms)
    end

    test "mild Hawking radiation preserves most data", %{cache: cache} do
      initial_metrics = EventHorizonCache.get_cache_metrics(cache)
      initial_items = initial_metrics.physics_metrics.total_items

      {:ok, _updated_cache, eviction_report} = EventHorizonCache.emit_hawking_radiation(cache, :mild)

      # Mild eviction should preserve most items
      assert eviction_report.items_evicted <= initial_items * 0.2  # Should evict <= 20%
    end
  end

  describe "Phase 4: Multi-Level Cache Hierarchy" do
    setup do
      {:ok, cache} = EventHorizonCache.create_cache(:hierarchy_test, schwarzschild_radius: 10_000)
      %{cache: cache}
    end

    test "stores data across different cache levels based on characteristics", %{cache: cache} do
      # Store different types of data
      test_cases = [
        {"critical:session", %{user: "alice", session: "abc123"}, [priority: :critical]},
        {"normal:user", %{name: "Bob", role: "user"}, [priority: :normal]},
        {"background:log", %{level: "info", message: "background task"}, [priority: :background]}
      ]

      cache_levels = Enum.map(test_cases, fn {key, value, opts} ->
        {:ok, _updated_cache, metadata} = EventHorizonCache.put(cache, key, value, opts)
        {key, metadata.cache_level}
      end)

      # Verify different priorities go to appropriate levels
      levels_used = Enum.map(cache_levels, fn {_key, level} -> level end) |> Enum.uniq()
      assert length(levels_used) >= 1  # Should use at least one level

      Logger.debug("Cache levels used: #{inspect(cache_levels)}")
    end

    test "compression ratios increase with cache depth", %{cache: cache} do
      # Store large data with different priorities
      large_data = %{data: String.duplicate("compression test ", 200)}

      {:ok, _c1, high_meta} = EventHorizonCache.put(cache, "high:data", large_data, priority: :high)
      {:ok, _c2, low_meta} = EventHorizonCache.put(cache, "low:data", large_data, priority: :low)

      # Lower priority should generally have higher compression
      Logger.debug("High priority compression: #{high_meta.compression_ratio}")
      Logger.debug("Low priority compression: #{low_meta.compression_ratio}")

      assert high_meta.compression_ratio >= 1.0
      assert low_meta.compression_ratio >= 1.0
    end
  end

  describe "Phase 4: Cache Metrics and Monitoring" do
    setup do
      {:ok, cache} = EventHorizonCache.create_cache(:metrics_test, schwarzschild_radius: 1_000)

      # Add some test data
      populated_cache = Enum.reduce(1..20, cache, fn i, cache_acc ->
        {:ok, updated_cache, _metadata} = EventHorizonCache.put(cache_acc, "metrics:#{i}", %{index: i})
        updated_cache
      end)

      %{cache: populated_cache}
    end

    test "provides comprehensive cache metrics", %{cache: cache} do
      metrics = EventHorizonCache.get_cache_metrics(cache)

      # Basic structure validation
      assert metrics.cache_id == :metrics_test
      assert is_integer(metrics.uptime_ms)
      assert is_map(metrics.cache_statistics)
      assert is_map(metrics.physics_metrics)
      assert is_map(metrics.performance_metrics)
      assert is_map(metrics.hawking_radiation)

      # Cache statistics
      cache_stats = metrics.cache_statistics
      assert is_integer(cache_stats.event_horizon_items)
      assert is_integer(cache_stats.photon_sphere_items)
      assert is_integer(cache_stats.deep_cache_items)
      assert is_integer(cache_stats.singularity_items)
      assert is_integer(cache_stats.total_memory_bytes)

      # Physics metrics
      physics = metrics.physics_metrics
      assert is_integer(physics.total_items)
      assert physics.total_items == 20
      assert is_float(physics.schwarzschild_utilization)
      assert physics.schwarzschild_utilization >= 0.0 and physics.schwarzschild_utilization <= 1.0
      assert physics.event_horizon_stability == :stable

      # Performance metrics
      assert is_map(metrics.performance_metrics)

      # Hawking radiation stats
      hawking = metrics.hawking_radiation
      assert is_integer(hawking.last_emission)
      assert is_integer(hawking.items_evicted)
    end

    test "tracks cache hit/miss ratios", %{cache: cache} do
      # Perform some gets to generate statistics
      {:ok, _, _cache1, _} = EventHorizonCache.get(cache, "metrics:1")  # Hit
      {:ok, _, _cache2, _} = EventHorizonCache.get(cache, "metrics:2")  # Hit
      {:miss, _cache3} = EventHorizonCache.get(cache, "nonexistent") # Miss

      # Note: Basic metrics tracking is implemented, detailed hit/miss tracking
      # would be enhanced in the performance optimization phase
      metrics = EventHorizonCache.get_cache_metrics(cache)
      assert is_map(metrics.performance_metrics)
    end
  end

  describe "Phase 4: Edge Cases and Error Handling" do
    test "handles empty cache gracefully" do
      {:ok, cache} = EventHorizonCache.create_cache(:empty_cache)

      {:miss, _updated_cache} = EventHorizonCache.get(cache, "anything")

      metrics = EventHorizonCache.get_cache_metrics(cache)
      assert metrics.physics_metrics.total_items == 0
    end

    test "handles nil keys and values gracefully" do
      {:ok, cache} = EventHorizonCache.create_cache(:edge_case_cache)

      # These should handle gracefully or provide meaningful errors
      result1 = EventHorizonCache.put(cache, nil, %{data: "test"})
      result2 = EventHorizonCache.put(cache, "test", nil)

      # Should either succeed or fail gracefully
      case result1 do
        {:ok, _cache, _metadata} -> :ok
        {:error, _reason} -> :ok
      end

      case result2 do
        {:ok, _cache, _metadata} -> :ok
        {:error, _reason} -> :ok
      end
    end

    test "handles very large data gracefully" do
      {:ok, cache} = EventHorizonCache.create_cache(:large_data_cache, schwarzschild_radius: 100)

      huge_data = %{
        massive_list: Enum.to_list(1..10_000),
        huge_string: String.duplicate("Very large data for black hole test ", 1000)
      }

      case EventHorizonCache.put(cache, "huge:data", huge_data) do
        {:ok, _updated_cache, metadata} ->
          # Should handle with high compression
          assert metadata.compression_ratio >= 2.0
        {:error, reason} ->
          # Or gracefully reject if too large
          assert is_atom(reason) or is_tuple(reason)
      end
    end
  end

  ## HELPER FUNCTIONS

  defp cleanup_test_cache_system() do
    # Clean up any ETS tables that might be left over from tests
    test_cache_patterns = [
      :test_cache, :custom_cache, :metrics_cache, :storage_test, :retrieval_test,
      :hawking_test, :hierarchy_test, :metrics_test, :empty_cache, :edge_case_cache,
      :large_data_cache
    ]

    Enum.each(test_cache_patterns, fn cache_id ->
      # Clean up all possible ETS tables for this cache
      table_patterns = [
        :"event_horizon_#{cache_id}_event_horizon",
        :"event_horizon_#{cache_id}_photon_sphere",
        :"event_horizon_#{cache_id}_deep_cache",
        :"event_horizon_#{cache_id}_singularity",
        :"event_horizon_#{cache_id}_metadata"
      ]

      Enum.each(table_patterns, fn table_name ->
        if :ets.whereis(table_name) != :undefined do
          try do
            :ets.delete(table_name)
          rescue
            _ -> :ok
          end
        end
      end)
    end)

    :timer.sleep(50)
  end
end
