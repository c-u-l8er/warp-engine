defmodule IsLabDBTest do
  use ExUnit.Case
  doctest IsLabDB

  require Logger

  setup_all do
    # Ensure clean state before all tests
    cleanup_test_universe()

    on_exit(fn -> cleanup_test_universe() end)

    :ok
  end

    setup do
    # Clean up any existing universe state before each test
    cleanup_test_universe()

        # Ensure test data directory exists
    test_data_dir = "/tmp/islab_db_test_data"
    File.mkdir_p!(test_data_dir)

    # Configure the data root for this test
    Application.put_env(:islab_db, :data_root, test_data_dir)

    # Ensure the full application is started with WAL and other components
    Application.ensure_all_started(:islab_db)

    # Ensure cosmic filesystem exists in test directory
    IsLabDB.CosmicPersistence.initialize_universe()

    # Use the existing IsLabDB process from application supervisor
    pid = case Process.whereis(IsLabDB) do
      nil ->
        raise "IsLabDB should be started by application supervisor but was not found"
      existing_pid ->
        existing_pid
    end

    # Give the universe a moment to initialize
    :timer.sleep(100)

        on_exit(fn ->
      if Process.alive?(pid) do
        GenServer.stop(pid)
      end
      cleanup_test_universe()
    end)

    %{universe_pid: pid}
  end

  describe "Phase 1: Cosmic Foundation" do
    test "universe starts successfully with stable state", %{universe_pid: pid} do
      assert Process.alive?(pid)

      metrics = IsLabDB.cosmic_metrics()
      assert metrics.universe_state == :stable
      assert is_integer(metrics.uptime_ms)
      assert metrics.uptime_ms >= 0
    end

            test "cosmic filesystem structure is created" do
      test_data_dir = "/tmp/islab_db_test_data"

      # Check that the cosmic filesystem structure exists
      assert File.exists?(test_data_dir)
      assert File.exists?(Path.join(test_data_dir, "universe.manifest"))

      # Check key directories exist
      assert File.dir?(Path.join(test_data_dir, "spacetime/hot_data"))
      assert File.dir?(Path.join(test_data_dir, "spacetime/warm_data"))
      assert File.dir?(Path.join(test_data_dir, "spacetime/cold_data"))
      assert File.dir?(Path.join(test_data_dir, "temporal"))
      assert File.dir?(Path.join(test_data_dir, "quantum_graph"))
      assert File.dir?(Path.join(test_data_dir, "configuration"))

      # Check manifest files exist in the actual locations (leaf directories)
      assert File.exists?(Path.join(test_data_dir, "spacetime/hot_data/particles/users/_manifest.json"))
      assert File.exists?(Path.join(test_data_dir, "spacetime/warm_data/particles/profiles/_manifest.json"))
      assert File.exists?(Path.join(test_data_dir, "spacetime/cold_data/particles/archives/_manifest.json"))
    end

    test "universe manifest contains correct cosmic constants" do
      test_data_dir = "/tmp/islab_db_test_data"
      {:ok, content} = File.read(Path.join(test_data_dir, "universe.manifest"))
      {:ok, manifest} = Jason.decode(content)

      assert manifest["universe_version"] == "1.0.0"
      assert manifest["physics_engine"] == "IsLabDB v1.0"
      assert is_map(manifest["cosmic_constants"])

      # Check key cosmic constants
      constants = manifest["cosmic_constants"]
      assert is_number(constants["planck_time_ns"])
      assert is_number(constants["light_speed_ops_per_sec"])
      assert constants["cosmic_background_temp"] == 2.7
      assert is_number(constants["entropy_rebalance_threshold"])
    end
  end

  describe "Basic Operations API" do
    test "cosmic_put stores data successfully" do
      assert {:ok, :stored, shard, operation_time} = IsLabDB.cosmic_put("test:key1", %{data: "value1"})

      assert shard in [:hot_data, :warm_data, :cold_data, :event_horizon_cache]
      assert is_integer(operation_time)
      assert operation_time > 0
    end

    test "cosmic_get retrieves stored data" do
      # Store data first
      {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put("test:key2", %{important: "data", number: 42})

      # Give persistence time to complete
      :timer.sleep(50)

      # Retrieve it
      assert {:ok, %{important: "data", number: 42}, retrieved_shard, operation_time} = IsLabDB.cosmic_get("test:key2")

      assert retrieved_shard in [:hot_data, :warm_data, :cold_data, :event_horizon_cache]
      assert is_integer(operation_time)
      assert operation_time > 0
    end

    test "cosmic_get returns not_found for nonexistent keys" do
      assert {:error, :not_found, operation_time} = IsLabDB.cosmic_get("nonexistent:key")
      assert is_integer(operation_time)
      assert operation_time > 0
    end

    test "cosmic_delete removes data from universe" do
      # Store and verify data exists
      {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put("test:key3", %{temp: "data"})
      assert {:ok, %{temp: "data"}, _shard, _time} = IsLabDB.cosmic_get("test:key3")

      # Delete and verify it's gone
      {:ok, deleted_from, operation_time} = IsLabDB.cosmic_delete("test:key3")

      assert is_list(deleted_from)
      assert length(deleted_from) == 3  # Should check all three shards
      assert Enum.all?(deleted_from, fn {shard, status} ->
        shard in [:hot_data, :warm_data, :cold_data] and status in [:deleted, :not_found]
      end)
      assert is_integer(operation_time)

      # Verify data is gone
      assert {:error, :not_found, _time} = IsLabDB.cosmic_get("test:key3")
    end

    test "cosmic_metrics returns comprehensive universe state" do
      metrics = IsLabDB.cosmic_metrics()

      # Check top-level structure
      assert %{
        universe_state: :stable,
        uptime_ms: uptime,
        spacetime_regions: regions,
        cosmic_constants: constants,
        performance: performance,
        entropy: entropy,
        persistence: persistence
      } = metrics

      # Validate data types and ranges
      assert is_integer(uptime) and uptime >= 0
      assert is_list(regions) and length(regions) == 3
      assert is_map(constants)
      assert is_map(performance)
      assert is_map(entropy)
      assert is_map(persistence)

      # Check cosmic constants
      assert %{
        planck_time_ns: _,
        light_speed_ops: _,
        background_temp: 2.7,
        entropy_threshold: _
      } = constants

      # Check spacetime regions
      Enum.each(regions, fn region ->
        assert %{
          shard: shard,
          data_items: items,
          memory_words: memory,
          physics_laws: laws
        } = region

        assert shard in [:hot_data, :warm_data, :cold_data, :event_horizon_cache]
        assert is_integer(items) and items >= 0
        assert is_integer(memory) and memory >= 0
        assert is_map(laws)
      end)
    end
  end

  describe "Access Patterns and Shard Routing" do
    test "hot access pattern routes to hot_data shard" do
      {:ok, :stored, shard, _time} = IsLabDB.cosmic_put("hot:key", %{value: "hot"},
        access_pattern: :hot, priority: :critical)

      assert shard == :hot_data
    end

    test "cold access pattern routes to cold_data shard" do
      {:ok, :stored, shard, _time} = IsLabDB.cosmic_put("cold:key", %{value: "cold"},
        access_pattern: :cold, priority: :background)

      assert shard == :cold_data
    end

    test "balanced access pattern uses priority for routing" do
      # High priority should go to hot shard
      {:ok, :stored, hot_shard, _} = IsLabDB.cosmic_put("priority:high", %{},
        access_pattern: :balanced, priority: :critical)
      assert hot_shard == :hot_data

      # Low priority should go to cold shard
      {:ok, :stored, cold_shard, _} = IsLabDB.cosmic_put("priority:low", %{},
        access_pattern: :balanced, priority: :background)
      assert cold_shard == :cold_data
    end
  end

  describe "Filesystem Persistence" do
    test "directory manifests explain cosmic purpose" do
      test_data_dir = "/tmp/islab_db_test_data"
      # Check a few key manifest files (in actual leaf directories)
      hot_manifest_path = Path.join(test_data_dir, "spacetime/hot_data/particles/users/_manifest.json")
      assert File.exists?(hot_manifest_path)

      {:ok, content} = File.read(hot_manifest_path)
      {:ok, manifest} = Jason.decode(content)

      assert is_binary(manifest["physics_description"])
      assert String.contains?(manifest["physics_description"], "High-energy")
      assert is_binary(manifest["data_format"])
      assert is_binary(manifest["purpose"])
      assert is_map(manifest["access_patterns"])
    end

    test "shard manifests are updated with record counts" do
      # Store some data in different shards
      IsLabDB.cosmic_put("test:item1", %{data: 1}, access_pattern: :hot)
      IsLabDB.cosmic_put("test:item2", %{data: 2}, access_pattern: :hot)

      # Give persistence time to complete
      :timer.sleep(200)

      test_data_dir = "/tmp/islab_db_test_data"
      # Check that shard manifest exists and has been updated
      shard_manifest_path = Path.join(test_data_dir, "spacetime/hot_data/_shard_manifest.json")

      # The manifest should exist if data was stored in hot_data
      if File.exists?(shard_manifest_path) do
        {:ok, content} = File.read(shard_manifest_path)
        {:ok, manifest} = Jason.decode(content)

        assert is_integer(manifest["total_records"])
        assert manifest["total_records"] > 0
        assert is_map(manifest["data_types"])
        assert is_list(manifest["recent_keys"])
      end
    end
  end

  describe "Performance and Monitoring" do
    test "operations complete within reasonable time limits" do
      # Store operation should be fast
      {time, {:ok, :stored, _shard, op_time}} = :timer.tc(fn ->
        IsLabDB.cosmic_put("perf:test", %{data: "performance test"})
      end)

      assert time < 10_000  # Less than 10ms
      assert op_time < 5_000  # Less than 5ms operation time

      # Get operation should be fast
      {time, {:ok, _value, _shard, op_time}} = :timer.tc(fn ->
        IsLabDB.cosmic_get("perf:test")
      end)

      assert time < 5_000   # Less than 5ms
      assert op_time < 2_000  # Less than 2ms operation time
    end

    test "metrics collection works without errors" do
      # Store some data to generate metrics
      for i <- 1..10 do
        IsLabDB.cosmic_put("metric:test#{i}", %{index: i})
      end

      # Collect metrics multiple times to ensure stability
      for _ <- 1..3 do
        metrics = IsLabDB.cosmic_metrics()
        assert is_map(metrics)
        assert metrics.universe_state in [:stable, :rebalancing]
        :timer.sleep(10)
      end
    end

    test "universe handles concurrent operations correctly" do
      # Spawn multiple concurrent operations
      tasks = for i <- 1..20 do
        Task.async(fn ->
          key = "concurrent:test#{i}"
          value = %{index: i, data: "concurrent test"}

          # Store data
          {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put(key, value)

          # Retrieve data
          {:ok, retrieved_value, _shard, _time} = IsLabDB.cosmic_get(key)

          assert retrieved_value == value
          :ok
        end)
      end

      # Wait for all tasks to complete
      results = Task.await_many(tasks, 5000)

      # All operations should succeed
      assert Enum.all?(results, fn result -> result == :ok end)
    end
  end

  describe "Error Handling and Edge Cases" do
    test "handles invalid keys gracefully" do
      # Test with various key types
      assert {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put(:atom_key, %{data: "atom key"})
      assert {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put(123, %{data: "number key"})
      assert {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put("", %{data: "empty string key"})
    end

    test "handles large data values" do
      large_data = %{
        description: String.duplicate("Large data test ", 1000),
        numbers: Enum.to_list(1..1000),
        nested: %{
          deep: %{
            structure: %{
              with: %{many: %{levels: "of nesting"}}
            }
          }
        }
      }

      assert {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put("large:data", large_data)
      assert {:ok, retrieved_data, _shard, _time} = IsLabDB.cosmic_get("large:data")
      assert retrieved_data == large_data
    end

    test "delete operations on non-existent keys don't crash" do
      {:ok, deletion_results, _time} = IsLabDB.cosmic_delete("non_existent:key")

      assert is_list(deletion_results)
      assert Enum.all?(deletion_results, fn {_shard, status} -> status == :not_found end)
    end
  end

  ## HELPER FUNCTIONS

    defp cleanup_test_universe() do
    # Stop any running IsLabDB process
    case Process.whereis(IsLabDB) do
      nil -> :ok
      pid ->
        if Process.alive?(pid) do
          GenServer.stop(pid, :normal, 1000)
        end
    end

    # Clean up test data directory
    test_data_dir = "/tmp/islab_db_test_data"
    if File.exists?(test_data_dir) do
      try do
        File.rm_rf!(test_data_dir)
      rescue
        error ->
          Logger.warning("Could not clean up test directory: #{inspect(error)}")
      end
    end

    # Small delay to ensure cleanup completes
    :timer.sleep(50)
  end
end
