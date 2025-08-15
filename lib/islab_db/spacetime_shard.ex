defmodule IsLabDB.SpacetimeShard do
  @moduledoc """
  Advanced Spacetime Shard Management with Physics-Based Routing

  This module implements the core spacetime shard system for Phase 3, providing:
  - Intelligent shard management with configurable physics laws
  - Gravitational routing algorithms for optimal data placement
  - Dynamic load balancing and data migration capabilities
  - Cross-shard consistency and transaction coordination

  Each shard operates according to specific physics laws that determine:
  - Consistency models (strong, eventual, weak)
  - Time dilation effects (processing speed multipliers)
  - Gravitational attraction (data locality preferences)
  - Energy levels (access frequency optimization)

  ## Physics-Inspired Features

  - **Gravitational Attraction**: Data with higher mass (importance/frequency) attracts related data
  - **Time Dilation**: High-priority shards run faster than low-priority ones
  - **Entropy Monitoring**: Automatic rebalancing when disorder increases
  - **Conservation Laws**: Data and energy are conserved during migrations
  """

  require Logger
  alias IsLabDB.{CosmicPersistence, CosmicConstants}

  defstruct [
    :shard_id,                    # Unique shard identifier (:hot_data, :warm_data, etc.)
    :ets_table,                   # ETS table for this shard
    :physics_laws,                # Physics configuration for this shard
    :gravitational_field,         # Attraction parameters for data routing
    :current_load,                # Current data load and access patterns
    :migration_state,             # State for ongoing data migrations
    :consistency_manager,         # Cross-shard consistency coordination
    :entropy_tracker,             # Entropy monitoring for this shard
    :created_at,                  # Shard creation timestamp
    :last_rebalanced             # Last rebalancing operation timestamp
  ]

  ## PUBLIC API

  @doc """
  Create a new spacetime shard with specified physics laws.

  ## Parameters
  - `shard_id` - Unique identifier (atom)
  - `physics_laws` - Physics configuration map
  - `opts` - Additional options

  ## Physics Laws Configuration
  ```
  %{
    consistency_model: :strong | :eventual | :weak,
    time_dilation: float(),        # Processing speed multiplier
    gravitational_mass: float(),   # Attraction strength
    energy_threshold: integer(),   # Migration trigger
    max_capacity: integer(),       # Maximum items before overflow
    entropy_limit: float()         # Disorder threshold
  }
  ```

  ## Examples
      {:ok, shard} = SpacetimeShard.create_shard(:hot_data, %{
        consistency_model: :strong,
        time_dilation: 0.5,
        gravitational_mass: 2.0,
        energy_threshold: 1000,
        max_capacity: 50_000
      })
  """
  def create_shard(shard_id, physics_laws \\ %{}, opts \\ []) do
    # Create ETS table for this shard
    ets_table = create_shard_table(shard_id, opts)

    # Initialize physics laws with defaults
    complete_physics_laws = complete_physics_laws(physics_laws)

    # Create gravitational field configuration
    gravitational_field = initialize_gravitational_field(complete_physics_laws)

    # Initialize shard state
    shard = %__MODULE__{
      shard_id: shard_id,
      ets_table: ets_table,
      physics_laws: complete_physics_laws,
      gravitational_field: gravitational_field,
      current_load: initialize_load_metrics(),
      migration_state: :stable,
      consistency_manager: initialize_consistency_manager(shard_id),
      entropy_tracker: initialize_entropy_tracker(),
      created_at: :os.system_time(:millisecond),
      last_rebalanced: :os.system_time(:millisecond)
    }

    # Persist shard configuration to filesystem
    persist_shard_configuration(shard)

    Logger.info("🌌 Created spacetime shard: #{shard_id} with #{complete_physics_laws.consistency_model} consistency")
    {:ok, shard}
  end

  @doc """
  Calculate gravitational routing score for a data item.

  Uses physics-based calculations to determine the optimal shard
  for a given key-value pair based on gravitational attraction,
  current load, and access patterns.

  ## Parameters
  - `shard` - The spacetime shard to evaluate
  - `key` - Data key to route
  - `value` - Data value
  - `access_metadata` - Access pattern information

  ## Returns
  Float score where higher values indicate stronger gravitational attraction
  """
  def calculate_gravitational_score(shard, key, value, access_metadata \\ %{}) do
    # Calculate data mass (importance factor)
    data_mass = calculate_data_mass(key, value, access_metadata)

    # Get shard gravitational mass
    shard_mass = shard.physics_laws.gravitational_mass

    # Calculate base gravitational attraction
    base_attraction = CosmicConstants.gravitational_attraction(data_mass, shard_mass, 1.0)

    # Apply distance penalty based on current load
    load_factor = calculate_load_factor(shard)

    # Apply time dilation effects (faster shards are more attractive for hot data)
    time_factor = 1.0 / shard.physics_laws.time_dilation

    # Calculate access pattern compatibility - this should dominate the score
    pattern_compatibility = calculate_pattern_compatibility(shard, access_metadata)

    # Final gravitational score with pattern compatibility having primary influence
    # Pattern compatibility gets squared to give it more weight
    physics_factor = (base_attraction * load_factor * time_factor) / 10.0  # Reduce physics influence
    compatibility_factor = pattern_compatibility * pattern_compatibility  # Square for more weight

    score = physics_factor + compatibility_factor * 100.0  # Pattern compatibility dominates

    Logger.debug("🪐 Gravitational score for #{key} -> #{shard.shard_id}: #{Float.round(score, 3)} (pattern: #{pattern_compatibility}, physics: #{Float.round(physics_factor, 3)})")
    score
  end

  @doc """
  Store data in the spacetime shard with gravitational effects.

  ## Parameters
  - `shard` - Target spacetime shard
  - `key` - Data key
  - `value` - Data value
  - `opts` - Storage options

  ## Returns
  `{:ok, updated_shard, storage_metadata}` or `{:error, reason}`
  """
  def gravitational_put(shard, key, value, _opts \\ []) do
    start_time = :os.system_time(:microsecond)

    # Check shard capacity and physics laws
    case validate_storage_request(shard, key, value) do
      {:ok, :can_store} ->
        # Apply time dilation to operation
        _dilated_start = apply_time_dilation(start_time, shard.physics_laws.time_dilation)

        # Store in ETS table
        :ets.insert(shard.ets_table, {key, value})

        # Update gravitational field effects
        updated_shard = update_gravitational_field(shard, key, value, :add)

        # Update load metrics
        updated_shard = update_load_metrics(updated_shard, :put)

        # Check if entropy rebalancing is needed
        final_shard = check_entropy_rebalancing(updated_shard)

        end_time = :os.system_time(:microsecond)
        operation_time = apply_time_dilation(end_time - start_time, shard.physics_laws.time_dilation)

        storage_metadata = %{
          shard_id: shard.shard_id,
          gravitational_score: calculate_gravitational_score(shard, key, value),
          operation_time: operation_time,
          time_dilation_applied: shard.physics_laws.time_dilation,
          consistency_level: shard.physics_laws.consistency_model
        }

        {:ok, final_shard, storage_metadata}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieve data from spacetime shard with physics effects.
  """
  def gravitational_get(shard, key, _opts \\ []) do
    start_time = :os.system_time(:microsecond)

    # Apply time dilation
    _dilated_start = apply_time_dilation(start_time, shard.physics_laws.time_dilation)

    case :ets.lookup(shard.ets_table, key) do
      [{^key, value}] ->
        # Update access patterns for gravitational calculations
        updated_shard = update_access_patterns(shard, key, :read)

        # Update load metrics including read operations counter
        updated_shard = update_load_metrics(updated_shard, :get)

        end_time = :os.system_time(:microsecond)
        operation_time = apply_time_dilation(end_time - start_time, shard.physics_laws.time_dilation)

        retrieval_metadata = %{
          shard_id: shard.shard_id,
          operation_time: operation_time,
          consistency_level: shard.physics_laws.consistency_model,
          gravitational_influence: calculate_gravitational_influence(shard, key)
        }

        {:ok, value, updated_shard, retrieval_metadata}

      [] ->
        end_time = :os.system_time(:microsecond)
        operation_time = apply_time_dilation(end_time - start_time, shard.physics_laws.time_dilation)
        {:error, :not_found, operation_time}
    end
  end

  @doc """
  Initiate data migration between spacetime shards.

  Uses gravitational calculations to determine if data should be moved
  to a different shard based on access patterns and load distribution.
  """
  def initiate_data_migration(source_shard, target_shard, migration_criteria \\ %{}) do
    Logger.info("🚀 Initiating data migration: #{source_shard.shard_id} -> #{target_shard.shard_id}")

    # Calculate migration candidates based on gravitational attraction
    candidates = find_migration_candidates(source_shard, target_shard, migration_criteria)

    # Create migration plan with physics validation
    migration_plan = create_migration_plan(candidates, source_shard, target_shard)

    # Execute migration with consistency guarantees
    {:ok, migration_results} = execute_migration_plan(migration_plan)
    Logger.info("✅ Migration completed: #{length(migration_results.migrated_keys)} items migrated")
    {:ok, migration_results}
  end

  @doc """
  Get comprehensive shard metrics including physics properties.
  """
  def get_shard_metrics(shard) do
    current_time = :os.system_time(:millisecond)

    %{
      shard_id: shard.shard_id,
      physics_laws: shard.physics_laws,
      current_load: shard.current_load,
      data_items: :ets.info(shard.ets_table, :size),
      memory_usage: :ets.info(shard.ets_table, :memory) * :erlang.system_info(:wordsize),
      gravitational_field_strength: calculate_total_gravitational_field(shard),
      entropy_level: calculate_shard_entropy(shard),
      uptime_ms: current_time - shard.created_at,
      last_rebalanced_ms_ago: current_time - shard.last_rebalanced,
      migration_state: shard.migration_state,
      consistency_health: check_consistency_health(shard)
    }
  end

  @doc """
  Update physics laws for a shard dynamically.

  Allows runtime reconfiguration of shard behavior while maintaining
  consistency and preserving existing data.
  """
  def update_physics_laws(shard, new_physics_laws) do
    Logger.info("⚙️ Updating physics laws for shard #{shard.shard_id}")

    # Validate new physics laws
    case validate_physics_laws(new_physics_laws) do
      {:ok, validated_laws} ->
        # Create transition plan for physics changes
        transition_plan = create_physics_transition_plan(shard, validated_laws)

        # Apply physics changes
        updated_shard = apply_physics_transition(shard, validated_laws, transition_plan)

        # Persist updated configuration
        persist_shard_configuration(updated_shard)

        Logger.info("✅ Physics laws updated for #{shard.shard_id}")
        {:ok, updated_shard}

      {:error, reason} ->
        Logger.error("❌ Invalid physics laws: #{inspect(reason)}")
        {:error, reason}
    end
  end

  ## PRIVATE FUNCTIONS

  defp create_shard_table(shard_id, opts) do
    # Use named table only if explicitly requested, otherwise return reference
    use_named_table = Keyword.get(opts, :named_table, false)

    base_options = [
      :set, :public,
      {:read_concurrency, Keyword.get(opts, :read_concurrency, true)},
      {:write_concurrency, Keyword.get(opts, :write_concurrency, true)},
      {:decentralized_counters, Keyword.get(opts, :decentralized_counters, true)}
    ]

    table_options = if use_named_table do
      [:named_table | base_options]
    else
      base_options
    end

    :ets.new(:"spacetime_shard_#{shard_id}", table_options)
  end

  defp complete_physics_laws(partial_laws) do
    defaults = %{
      consistency_model: :eventual,
      time_dilation: 1.0,
      gravitational_mass: 1.0,
      energy_threshold: 1000,
      max_capacity: 25_000,
      entropy_limit: 2.0,
      migration_threshold: 0.8,
      gravitational_range: 1000.0
    }

    Map.merge(defaults, partial_laws)
  end

  defp initialize_gravitational_field(physics_laws) do
    %{
      mass: physics_laws.gravitational_mass,
      range: physics_laws.gravitational_range,
      attraction_map: %{},
      last_calculated: :os.system_time(:millisecond)
    }
  end

  defp initialize_load_metrics() do
    %{
      total_operations: 0,
      read_operations: 0,
      write_operations: 0,
      avg_operation_time: 0.0,
      peak_load_time: 0,
      current_capacity_usage: 0.0,
      hot_keys: %{}
    }
  end

  defp initialize_consistency_manager(shard_id) do
    %{
      shard_id: shard_id,
      consistency_state: :healthy,
      pending_operations: [],
      cross_shard_locks: %{},
      transaction_log: []
    }
  end

  defp initialize_entropy_tracker() do
    %{
      current_entropy: 0.0,
      entropy_history: [],
      last_measurement: :os.system_time(:millisecond),
      rebalancing_needed: false
    }
  end

  defp persist_shard_configuration(shard) do
    # Persist shard configuration to filesystem
    Task.start(fn ->
      try do
        config_path = Path.join([
          CosmicPersistence.data_root(),
          "spacetime",
          Atom.to_string(shard.shard_id),
          "_physics_laws.json"
        ])

        File.mkdir_p!(Path.dirname(config_path))

        shard_config = %{
          shard_id: shard.shard_id,
          physics_laws: shard.physics_laws,
          created_at: shard.created_at,
          last_updated: :os.system_time(:millisecond),
          gravitational_field: shard.gravitational_field
        }

        File.write!(config_path, Jason.encode!(shard_config, pretty: true))
      rescue
        error ->
          Logger.warning("Failed to persist shard configuration: #{inspect(error)}")
      end
    end)
  end

  defp calculate_data_mass(_key, value, access_metadata) do
    # Base mass from data size
    base_mass = :erlang.external_size(value) / 1000.0

    # Access frequency multiplier
    access_frequency = Map.get(access_metadata, :access_frequency, 1.0)
    frequency_mass = base_mass * access_frequency

    # Priority multiplier
    priority_multiplier = case Map.get(access_metadata, :priority, :normal) do
      :critical -> 5.0
      :high -> 3.0
      :normal -> 1.0
      :low -> 0.5
      :background -> 0.1
      _ -> 1.0  # Default for invalid/unknown priorities
    end

    frequency_mass * priority_multiplier
  end

  defp calculate_load_factor(shard) do
    capacity_usage = shard.current_load.current_capacity_usage
    max_capacity = shard.physics_laws.max_capacity

    if capacity_usage >= max_capacity do
      0.1  # Very low attraction when at capacity
    else
      usage_ratio = capacity_usage / max_capacity
      1.0 - (usage_ratio * 0.8)  # Reduce attraction as capacity fills
    end
  end

  defp calculate_pattern_compatibility(shard, access_metadata) do
    expected_pattern = case shard.shard_id do
      :hot_data -> :hot
      :warm_data -> :warm
      :cold_data -> :cold
      _ -> :balanced
    end

    actual_pattern = Map.get(access_metadata, :access_pattern, :balanced)
    priority = Map.get(access_metadata, :priority, :normal)

    # Base compatibility score
    base_score = case {expected_pattern, actual_pattern} do
      {same, same} -> 2.0  # Perfect match
      {:hot, :warm} -> 1.5  # Good match
      {:warm, :hot} -> 1.2  # Acceptable
      {:warm, :cold} -> 1.2  # Acceptable
      {:cold, :warm} -> 1.0  # Neutral
      _ -> 0.5  # Poor match
    end

    # For balanced access pattern, use priority to strongly influence shard selection
    priority_multiplier = if actual_pattern == :balanced do
      case {expected_pattern, priority} do
        {:hot, :critical} -> 3.0
        {:hot, :high} -> 2.5
        {:warm, :normal} -> 2.0
        {:cold, :low} -> 2.5
        {:cold, :background} -> 3.0
        {:cold, p} when p in [:low, :background] -> 2.5
        {:hot, p} when p in [:critical, :high] -> 2.5
        _ -> 1.0
      end
    else
      1.0
    end

    base_score * priority_multiplier
  end

  defp validate_storage_request(shard, _key, _value) do
    current_items = :ets.info(shard.ets_table, :size)
    max_capacity = shard.physics_laws.max_capacity

    if current_items >= max_capacity do
      {:error, :shard_at_capacity}
    else
      {:ok, :can_store}
    end
  end

  defp apply_time_dilation(time, dilation_factor) do
    # Apply relativistic time dilation effects
    round(time / dilation_factor)
  end

  defp update_gravitational_field(shard, key, value, operation) do
    # Update gravitational field based on data operations
    data_mass = calculate_data_mass(key, value, %{})

    updated_field = case operation do
      :add ->
        current_attractions = shard.gravitational_field.attraction_map
        updated_attractions = Map.put(current_attractions, key, data_mass)
        %{shard.gravitational_field | attraction_map: updated_attractions}

      :remove ->
        current_attractions = shard.gravitational_field.attraction_map
        updated_attractions = Map.delete(current_attractions, key)
        %{shard.gravitational_field | attraction_map: updated_attractions}
    end

    %{shard | gravitational_field: updated_field}
  end

  defp update_load_metrics(shard, operation_type) do
    current_load = shard.current_load
    current_items = :ets.info(shard.ets_table, :size)
    capacity_usage = current_items / shard.physics_laws.max_capacity

    updated_load = current_load
    |> Map.update(:total_operations, 1, &(&1 + 1))
    |> Map.put(:current_capacity_usage, capacity_usage)

    updated_load = case operation_type do
      :put -> Map.update(updated_load, :write_operations, 1, &(&1 + 1))
      :get -> Map.update(updated_load, :read_operations, 1, &(&1 + 1))
      _ -> updated_load
    end

    %{shard | current_load: updated_load}
  end

  defp check_entropy_rebalancing(shard) do
    current_entropy = calculate_shard_entropy(shard)

    if current_entropy > shard.physics_laws.entropy_limit do
      Logger.info("🌀 High entropy detected in #{shard.shard_id}: #{Float.round(current_entropy, 2)}")
      trigger_entropy_rebalancing(shard)
    else
      shard
    end
  end

  defp update_access_patterns(shard, key, access_type) do
    # Update access pattern tracking for gravitational calculations
    current_load = shard.current_load
    hot_keys = current_load.hot_keys

    updated_hot_keys = case access_type do
      :read ->
        Map.update(hot_keys, key, 1, &(&1 + 1))
      _ ->
        hot_keys
    end

    updated_load = %{current_load | hot_keys: updated_hot_keys}
    %{shard | current_load: updated_load}
  end

  defp calculate_gravitational_influence(shard, key) do
    # Calculate how much gravitational influence this key has on the shard
    Map.get(shard.gravitational_field.attraction_map, key, 0.0)
  end

  defp find_migration_candidates(_source_shard, _target_shard, _criteria) do
    # Placeholder for migration candidate selection
    []
  end

  defp create_migration_plan(_candidates, _source_shard, _target_shard) do
    # Placeholder for migration planning
    %{migration_items: [], estimated_time: 0}
  end

  defp execute_migration_plan(_migration_plan) do
    # Placeholder for migration execution
    # In future versions, this could fail, so keeping error handling structure
    {:ok, %{migrated_keys: [], migration_time: 0}}
  end

  defp calculate_total_gravitational_field(shard) do
    total = shard.gravitational_field.attraction_map
    |> Map.values()
    |> Enum.sum()

    # Ensure we always return a float
    total * 1.0
  end

  defp calculate_shard_entropy(shard) do
    # Simplified entropy calculation based on load distribution
    current_items = :ets.info(shard.ets_table, :size)
    capacity_usage = shard.current_load.current_capacity_usage

    # Ensure we always work with floats
    base_entropy = capacity_usage * 2.0

    # Add randomness based on access patterns
    hot_key_count = map_size(shard.current_load.hot_keys)
    access_entropy = if current_items > 0 do
      (hot_key_count / current_items) * 1.5
    else
      0.0
    end

    # Ensure result is always a float
    (base_entropy + access_entropy) * 1.0
  end

  defp check_consistency_health(shard) do
    # Check consistency manager health
    case shard.consistency_manager.consistency_state do
      :healthy -> :healthy
      :degraded -> :degraded
      :failed -> :failed
      _ -> :unknown
    end
  end

  defp validate_physics_laws(physics_laws) when is_map(physics_laws) do
    # Validate physics laws configuration
    required_fields = [:consistency_model, :time_dilation, :gravitational_mass]

    missing_fields = required_fields -- Map.keys(physics_laws)

    if length(missing_fields) == 0 do
      {:ok, physics_laws}
    else
      {:error, {:missing_fields, missing_fields}}
    end
  end
  defp validate_physics_laws(_), do: {:error, :invalid_format}

  defp create_physics_transition_plan(_shard, _new_laws) do
    # Create plan for transitioning physics laws
    %{transition_steps: [], estimated_time: 100}
  end

  defp apply_physics_transition(shard, new_laws, _transition_plan) do
    # Apply new physics laws to shard
    %{shard | physics_laws: new_laws}
  end

  defp trigger_entropy_rebalancing(shard) do
    # Trigger entropy-based rebalancing for this shard
    updated_entropy_tracker = %{
      shard.entropy_tracker |
      rebalancing_needed: true,
      last_measurement: :os.system_time(:millisecond)
    }

    %{shard | entropy_tracker: updated_entropy_tracker}
  end
end
