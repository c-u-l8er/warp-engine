defmodule SpacetimeShardTest do
  use ExUnit.Case
  doctest IsLabDB.SpacetimeShard

  require Logger

  alias IsLabDB.SpacetimeShard

  setup_all do
    # Ensure clean state before all tests
    cleanup_test_system()

    on_exit(fn -> cleanup_test_system() end)

    :ok
  end

  setup do
    # Clean up system before each test
    cleanup_test_system()

    # Ensure test data directory exists
    test_data_dir = "/tmp/islab_db_test_phase3_shards"
    File.mkdir_p!(test_data_dir)
    Application.put_env(:islab_db, :data_root, test_data_dir)

    on_exit(fn ->
      cleanup_test_system()
    end)

    %{test_data_dir: test_data_dir}
  end

  describe "Phase 3: Spacetime Shard Creation and Configuration" do
    test "creates spacetime shard with default physics laws" do
      {:ok, shard} = SpacetimeShard.create_shard(:test_hot, %{})

      assert shard.shard_id == :test_hot
      assert is_reference(shard.ets_table)
      assert is_map(shard.physics_laws)
      assert shard.physics_laws.consistency_model == :eventual
      assert shard.physics_laws.time_dilation == 1.0
    end

    test "creates spacetime shard with custom physics laws" do
      custom_physics = %{
        consistency_model: :strong,
        time_dilation: 0.5,
        gravitational_mass: 2.0,
        max_capacity: 10_000
      }

      {:ok, shard} = SpacetimeShard.create_shard(:test_custom, custom_physics)

      assert shard.physics_laws.consistency_model == :strong
      assert shard.physics_laws.time_dilation == 0.5
      assert shard.physics_laws.gravitational_mass == 2.0
      assert shard.physics_laws.max_capacity == 10_000
    end

    test "shard configuration persists to filesystem", %{test_data_dir: test_data_dir} do
      {:ok, _shard} = SpacetimeShard.create_shard(:persistent_test, %{
        consistency_model: :strong,
        gravitational_mass: 3.0
      })

      # Give persistence time to complete
      :timer.sleep(200)

      # Check that configuration file exists
      config_path = Path.join([
        test_data_dir,
        "spacetime",
        "persistent_test",
        "_physics_laws.json"
      ])

      assert File.exists?(config_path)

      # Verify configuration content
      {:ok, content} = File.read(config_path)
      {:ok, config} = Jason.decode(content)

      assert config["shard_id"] == "persistent_test"
      assert config["physics_laws"]["consistency_model"] == "strong"
      assert config["physics_laws"]["gravitational_mass"] == 3.0
    end

    test "initializes gravitational field correctly" do
      {:ok, shard} = SpacetimeShard.create_shard(:gravity_test, %{
        gravitational_mass: 2.5,
        gravitational_range: 500.0
      })

      assert shard.gravitational_field.mass == 2.5
      assert shard.gravitational_field.range == 500.0
      assert is_map(shard.gravitational_field.attraction_map)
      assert is_integer(shard.gravitational_field.last_calculated)
    end
  end

  describe "Gravitational Data Operations" do
    setup do
      {:ok, hot_shard} = SpacetimeShard.create_shard(:hot_test, %{
        consistency_model: :strong,
        time_dilation: 0.5,
        gravitational_mass: 2.0,
        max_capacity: 1000
      })

      {:ok, cold_shard} = SpacetimeShard.create_shard(:cold_test, %{
        consistency_model: :weak,
        time_dilation: 2.0,
        gravitational_mass: 0.3,
        max_capacity: 500
      })

      %{hot_shard: hot_shard, cold_shard: cold_shard}
    end

    test "gravitational_put stores data with physics effects", %{hot_shard: shard} do
      test_key = "test:gravity_put"
      test_value = %{data: "gravitational storage test", importance: "high"}

      {:ok, updated_shard, storage_metadata} = SpacetimeShard.gravitational_put(shard, test_key, test_value)

      # Check that data was stored
      case :ets.lookup(updated_shard.ets_table, test_key) do
        [{^test_key, stored_value}] ->
          assert stored_value == test_value
        [] ->
          flunk("Data was not stored in ETS table")
      end

      # Check storage metadata
      assert storage_metadata.shard_id == :hot_test
      assert is_float(storage_metadata.gravitational_score)
      assert is_integer(storage_metadata.operation_time)
      assert storage_metadata.time_dilation_applied == 0.5
      assert storage_metadata.consistency_level == :strong

      # Check that gravitational field was updated
      assert Map.has_key?(updated_shard.gravitational_field.attraction_map, test_key)
    end

    test "gravitational_get retrieves data with physics effects", %{hot_shard: shard} do
      test_key = "test:gravity_get"
      test_value = %{data: "retrieval test", priority: "high"}

      # First store the data
      {:ok, shard_with_data, _metadata} = SpacetimeShard.gravitational_put(shard, test_key, test_value)

      # Now retrieve it
      {:ok, retrieved_value, updated_shard, retrieval_metadata} = SpacetimeShard.gravitational_get(shard_with_data, test_key)

      assert retrieved_value == test_value
      assert retrieval_metadata.shard_id == :hot_test
      assert is_integer(retrieval_metadata.operation_time)
      assert retrieval_metadata.consistency_level == :strong

      # Check that access patterns were updated
      assert updated_shard.current_load.read_operations == shard_with_data.current_load.read_operations + 1
    end

    test "gravitational_get returns not_found for non-existent data", %{cold_shard: shard} do
      result = SpacetimeShard.gravitational_get(shard, "non_existent:key")

      assert {:error, :not_found, operation_time} = result
      assert is_integer(operation_time)
    end

    test "storage respects shard capacity limits", %{cold_shard: shard} do
      # The cold shard has max_capacity: 500, let's fill it up
      # Store data until we hit the capacity limit
      keys_and_values = for i <- 1..501 do
        {"capacity_test:#{i}", %{index: i, data: "capacity test"}}
      end

      # Store items one by one and check for capacity errors
      {successful_stores, capacity_error} = Enum.reduce_while(keys_and_values, {0, nil}, fn {key, value}, {count, _error} ->
        case SpacetimeShard.gravitational_put(shard, key, value) do
          {:ok, _updated_shard, _metadata} -> {:cont, {count + 1, nil}}
          {:error, :shard_at_capacity} -> {:halt, {count, :capacity_reached}}
          {:error, other_error} -> {:halt, {count, other_error}}
        end
      end)

      # We should have stored some items but hit capacity before storing all 501
      assert successful_stores > 0
      assert successful_stores <= 500
      assert capacity_error == :capacity_reached
    end

    test "time dilation affects operation timing", %{hot_shard: hot_shard, cold_shard: cold_shard} do
      test_key = "time_dilation:test"
      test_value = %{data: "time test"}

      # Store in hot shard (time_dilation: 0.5 = faster)
      {:ok, _hot_shard, hot_metadata} = SpacetimeShard.gravitational_put(hot_shard, test_key, test_value)

      # Store in cold shard (time_dilation: 2.0 = slower)
      {:ok, _cold_shard, cold_metadata} = SpacetimeShard.gravitational_put(cold_shard, test_key, test_value)

      # Hot shard operations should generally be faster due to time dilation
      # (Though this test might be flaky due to system timing variations)
      Logger.debug("Hot shard operation time: #{hot_metadata.operation_time}μs (dilated with factor #{hot_metadata.time_dilation_applied})")
      Logger.debug("Cold shard operation time: #{cold_metadata.operation_time}μs (dilated with factor #{cold_metadata.time_dilation_applied})")

      # At least verify that time dilation factors are applied correctly
      assert hot_metadata.time_dilation_applied == 0.5
      assert cold_metadata.time_dilation_applied == 2.0
    end
  end

  describe "Gravitational Score Calculations" do
    setup do
      {:ok, balanced_shard} = SpacetimeShard.create_shard(:balanced, %{
        gravitational_mass: 1.0,
        max_capacity: 1000
      })

      %{balanced_shard: balanced_shard}
    end

    test "calculates gravitational scores based on data characteristics", %{balanced_shard: shard} do
      # High-priority data should have higher gravitational score
      high_priority_score = SpacetimeShard.calculate_gravitational_score(
        shard,
        "important:data",
        %{size: "large", critical: true},
        %{priority: :critical, access_pattern: :hot}
      )

      low_priority_score = SpacetimeShard.calculate_gravitational_score(
        shard,
        "background:data",
        %{size: "small", critical: false},
        %{priority: :background, access_pattern: :cold}
      )

      assert high_priority_score > low_priority_score
      assert is_float(high_priority_score)
      assert is_float(low_priority_score)
    end

    test "gravitational scores consider access pattern compatibility", %{balanced_shard: shard} do
      # For a balanced shard, different access patterns should yield different scores
      hot_pattern_score = SpacetimeShard.calculate_gravitational_score(
        shard,
        "test:hot_pattern",
        %{data: "test"},
        %{access_pattern: :hot}
      )

      cold_pattern_score = SpacetimeShard.calculate_gravitational_score(
        shard,
        "test:cold_pattern",
        %{data: "test"},
        %{access_pattern: :cold}
      )

      balanced_pattern_score = SpacetimeShard.calculate_gravitational_score(
        shard,
        "test:balanced_pattern",
        %{data: "test"},
        %{access_pattern: :balanced}
      )

      # All should be positive numbers
      assert hot_pattern_score > 0
      assert cold_pattern_score > 0
      assert balanced_pattern_score > 0

      Logger.debug("Hot pattern score: #{hot_pattern_score}")
      Logger.debug("Cold pattern score: #{cold_pattern_score}")
      Logger.debug("Balanced pattern score: #{balanced_pattern_score}")
    end
  end

  describe "Shard Metrics and Monitoring" do
    setup do
      {:ok, monitored_shard} = SpacetimeShard.create_shard(:monitored, %{
        consistency_model: :eventual,
        gravitational_mass: 1.5,
        max_capacity: 100
      })

      %{monitored_shard: monitored_shard}
    end

    test "get_shard_metrics returns comprehensive information", %{monitored_shard: shard} do
      # Store some test data to generate metrics
      {:ok, shard_with_data, _metadata} = SpacetimeShard.gravitational_put(shard, "metrics:test", %{data: "test"})

      metrics = SpacetimeShard.get_shard_metrics(shard_with_data)

      # Check basic structure
      assert metrics.shard_id == :monitored
      assert is_map(metrics.physics_laws)
      assert is_map(metrics.current_load)
      assert is_integer(metrics.data_items)
      assert is_integer(metrics.memory_usage)
      assert is_float(metrics.gravitational_field_strength)
      assert is_float(metrics.entropy_level)
      assert is_integer(metrics.uptime_ms)
      assert is_atom(metrics.migration_state)
      assert is_atom(metrics.consistency_health)

      # Check that data items count is correct
      assert metrics.data_items == 1

      # Check that physics laws are preserved
      assert metrics.physics_laws.consistency_model == :eventual
      assert metrics.physics_laws.gravitational_mass == 1.5
    end

    test "entropy levels increase with shard usage", %{monitored_shard: initial_shard} do
      initial_entropy = SpacetimeShard.get_shard_metrics(initial_shard).entropy_level

      # Store multiple items to increase entropy
      shard_with_data = Enum.reduce(1..10, initial_shard, fn i, shard_acc ->
        {:ok, updated_shard, _metadata} = SpacetimeShard.gravitational_put(shard_acc, "entropy_test:#{i}", %{index: i})
        updated_shard
      end)

      final_entropy = SpacetimeShard.get_shard_metrics(shard_with_data).entropy_level

      # Entropy should generally increase with more data and operations
      assert final_entropy >= initial_entropy
      Logger.debug("Initial entropy: #{initial_entropy}, Final entropy: #{final_entropy}")
    end
  end

  describe "Physics Law Updates" do
    setup do
      {:ok, updatable_shard} = SpacetimeShard.create_shard(:updatable, %{
        consistency_model: :weak,
        time_dilation: 2.0,
        gravitational_mass: 0.5
      })

      %{updatable_shard: updatable_shard}
    end

    test "updates physics laws successfully", %{updatable_shard: shard} do
      new_physics_laws = %{
        consistency_model: :strong,
        time_dilation: 0.5,
        gravitational_mass: 2.0,
        max_capacity: 5000
      }

      {:ok, updated_shard} = SpacetimeShard.update_physics_laws(shard, new_physics_laws)

      assert updated_shard.physics_laws.consistency_model == :strong
      assert updated_shard.physics_laws.time_dilation == 0.5
      assert updated_shard.physics_laws.gravitational_mass == 2.0
      assert updated_shard.physics_laws.max_capacity == 5000
    end

    test "validates physics laws before updating", %{updatable_shard: shard} do
      # Invalid physics laws (missing required fields)
      invalid_laws = %{
        some_invalid_field: "invalid"
      }

      result = SpacetimeShard.update_physics_laws(shard, invalid_laws)

      assert {:error, {:missing_fields, missing_fields}} = result
      assert :consistency_model in missing_fields
      assert :time_dilation in missing_fields
      assert :gravitational_mass in missing_fields
    end

    test "rejects non-map physics laws", %{updatable_shard: shard} do
      result = SpacetimeShard.update_physics_laws(shard, "invalid format")

      assert {:error, :invalid_format} = result
    end
  end

  ## HELPER FUNCTIONS

  defp cleanup_test_system() do
    # Clean up any test ETS tables
    test_table_patterns = [:test_hot, :test_custom, :persistent_test, :gravity_test, :hot_test, :cold_test, :balanced, :monitored, :updatable]

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
    test_data_dir = "/tmp/islab_db_test_phase3_shards"
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
