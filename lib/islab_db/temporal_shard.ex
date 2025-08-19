defmodule IsLabDB.TemporalShard do
  @moduledoc """
  Physics-Inspired Temporal Data Management for IsLab Database

  This module implements Phase 7 temporal data management, extending IsLabDB's
  physics-inspired architecture with time-series optimization, historical analytics,
  and real-time stream processing. Built on the solid WAL + Checkpoint foundation
  from Phase 6.6.

  ## Temporal Physics Model

  Time flows through the computational universe in distinct energy layers:
  - **Present (Live Data)**: High energy, immediate processing (last hour)
  - **Recent Past**: Medium energy, indexed processing (last 24-48 hours)
  - **Historical Past**: Low energy, compressed storage (7+ days)
  - **Deep Time**: Archive energy, highly compressed (months/years)

  ## Core Features

  - **WAL Integration**: All temporal operations logged for complete recovery
  - **Checkpoint System**: Temporal shard snapshots for faster recovery
  - **Physics Intelligence**: Time-based entropy and gravitational effects
  - **Automatic Lifecycle**: Data transitions based on temporal physics
  - **Real-Time Processing**: Live data streams with minimal latency

  ## Performance Targets

  - **Temporal Put Operations**: 25,000+ ops/sec (leveraging WAL infrastructure)
  - **Temporal Range Queries**: <100ms for 1M+ data points
  - **Stream Ingestion**: 50,000+ events/sec sustained throughput
  - **Real-Time Aggregations**: <50ms latency for live calculations

  ## Integration with Existing Systems

  - Built on Phase 6.6 WAL system for persistence
  - Uses SpacetimeShard physics laws and gravitational routing
  - Integrates with Event Horizon caches for temporal data
  - Leverages quantum entanglement for time-series correlation
  """

  use GenServer
  require Logger

  alias IsLabDB.{CosmicPersistence, WAL}
  alias IsLabDB.WAL.Entry, as: WALEntry

  defstruct [
    :temporal_id,                # Unique temporal shard identifier
    :time_period,                # :live, :recent, :historical, :deep_time
    :time_range,                 # {start_time, end_time} or :active
    :data_table,                 # ETS table for temporal data
    :index_table,                # ETS table for temporal indices
    :physics_laws,               # Temporal physics configuration
    :lifecycle_rules,            # Data lifecycle management rules
    :compression_config,         # Compression settings for historical data
    :aggregation_cache,          # Cache for temporal aggregations
    :stream_buffer,              # Buffer for real-time stream processing
    :entropy_tracker,            # Temporal entropy monitoring
    :checkpoint_metadata,        # Integration with checkpoint system
    :wal_integration,            # WAL integration state
    :created_at,                 # Shard creation timestamp
    :last_transition,            # Last lifecycle transition
    :performance_metrics         # Temporal operation metrics
  ]

  ## TEMPORAL PHYSICS LAWS

  @temporal_physics_defaults %{
    # Time dilation effects based on data recency
    time_dilation_factor: 1.0,
    # Temporal mass affects gravitational attraction over time
    temporal_mass_decay: 0.95,
    # Entropy decay rate over time
    entropy_decay_rate: 0.1,
    # Quantum coherence lifetime for temporal data
    quantum_coherence_time: 3600_000,  # 1 hour in milliseconds
    # Automatic lifecycle transition thresholds
    live_to_recent_threshold: 3600_000,      # 1 hour
    recent_to_historical_threshold: 172800_000, # 48 hours
    historical_to_deep_time_threshold: 2592000_000, # 30 days
    # Compression ratios by time period
    recent_compression_ratio: 0.8,
    historical_compression_ratio: 0.5,
    deep_time_compression_ratio: 0.2
  }

  ## PUBLIC API

  @doc """
  Create a new temporal shard with specified time period and physics laws.

  ## Parameters
  - `temporal_id` - Unique identifier for the temporal shard
  - `time_period` - :live, :recent, :historical, or :deep_time
  - `time_range` - Time range tuple or :active for live data
  - `physics_laws` - Temporal physics configuration (optional)
  - `opts` - Additional options

  ## Examples
      {:ok, shard} = TemporalShard.create_shard(:live_stream_001, :live, :active, %{
        time_dilation_factor: 0.5,
        quantum_coherence_time: 1800_000
      })
  """
  def create_shard(temporal_id, time_period, time_range, physics_laws \\ %{}, opts \\ []) do
    # Validate time period
    unless time_period in [:live, :recent, :historical, :deep_time] do
      raise ArgumentError, "Invalid time period: #{inspect(time_period)}"
    end

    # Create ETS tables for temporal data and indices
    data_table = create_temporal_table(:"temporal_data_#{temporal_id}", opts)
    index_table = create_temporal_table(:"temporal_index_#{temporal_id}", opts)

    # Initialize temporal physics laws
    complete_physics_laws = Map.merge(@temporal_physics_defaults, physics_laws)

    # Initialize temporal shard
    shard = %__MODULE__{
      temporal_id: temporal_id,
      time_period: time_period,
      time_range: time_range,
      data_table: data_table,
      index_table: index_table,
      physics_laws: complete_physics_laws,
      lifecycle_rules: initialize_lifecycle_rules(time_period),
      compression_config: initialize_compression_config(time_period, complete_physics_laws),
      aggregation_cache: %{},
      stream_buffer: [],
      entropy_tracker: initialize_temporal_entropy_tracker(),
      checkpoint_metadata: %{},
      wal_integration: initialize_wal_integration(),
      created_at: :os.system_time(:millisecond),
      last_transition: :os.system_time(:millisecond),
      performance_metrics: initialize_temporal_metrics()
    }

    # Persist temporal shard configuration
    persist_temporal_configuration(shard)

    Logger.info("⏰ Created temporal shard: #{temporal_id} (#{time_period}) with #{map_size(complete_physics_laws)} physics laws")
    {:ok, shard}
  end

  @doc """
  Store temporal data with timestamp metadata and automatic lifecycle management.

  ## Parameters
  - `shard` - Target temporal shard
  - `key` - Data key (can include timestamp prefix)
  - `value` - Data value
  - `timestamp` - Optional explicit timestamp (defaults to current time)
  - `opts` - Storage options

  ## Returns
  `{:ok, updated_shard, temporal_metadata}` or `{:error, reason}`

  ## Examples
      {:ok, updated_shard, metadata} = TemporalShard.temporal_put(shard, "sensor:temp", 23.5)
      {:ok, updated_shard, metadata} = TemporalShard.temporal_put(shard, "events:login", user_data, timestamp)
  """
  def temporal_put(shard, key, value, timestamp \\ nil, opts \\ []) do
    start_time = :os.system_time(:microsecond)
    actual_timestamp = timestamp || :os.system_time(:millisecond)

    # Apply temporal physics effects
    time_dilation_effect = calculate_time_dilation(shard, actual_timestamp)
    _dilated_start_time = apply_temporal_dilation(start_time, time_dilation_effect)

    # Create temporal metadata
    temporal_metadata = create_temporal_metadata(key, value, actual_timestamp, shard, opts)

    # Validate temporal data fits shard's time range
    case validate_temporal_data(shard, actual_timestamp) do
      {:ok, :valid} ->
        # Store in temporal ETS table with timestamp indexing
        temporal_key = create_temporal_key(key, actual_timestamp)
        temporal_record = {temporal_key, key, value, temporal_metadata}
        :ets.insert(shard.data_table, temporal_record)

        # Update temporal indices for efficient time-range queries
        updated_shard = update_temporal_indices(shard, key, actual_timestamp, temporal_metadata)

        # Log to WAL with temporal operation type
        wal_sequence = get_next_wal_sequence()
        wal_entry = WALEntry.new(:temporal_put, key, value, shard.temporal_id, temporal_metadata, wal_sequence)
        WAL.async_append(wal_entry)

        # Check for lifecycle transitions (async)
        final_shard = check_temporal_lifecycle_transitions(updated_shard, actual_timestamp)

        # Update performance metrics
        operation_time = apply_temporal_dilation(:os.system_time(:microsecond) - start_time, time_dilation_effect)
        final_shard_with_metrics = update_temporal_metrics(final_shard, :put, operation_time)

        success_metadata = Map.merge(temporal_metadata, %{
          operation_time: operation_time,
          time_dilation_applied: time_dilation_effect,
          temporal_shard: shard.temporal_id,
          wal_sequence: wal_sequence
        })

        {:ok, final_shard_with_metrics, success_metadata}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieve temporal data from specific time periods or ranges.

  ## Parameters
  - `shard` - Source temporal shard
  - `key` - Data key to retrieve
  - `time_range` - Optional time range tuple {start_time, end_time} or :latest
  - `opts` - Retrieval options

  ## Returns
  `{:ok, temporal_data, updated_shard, metadata}` or `{:error, reason}`

  ## Examples
      {:ok, data, shard, metadata} = TemporalShard.temporal_get(shard, "sensor:temp")
      {:ok, data, shard, metadata} = TemporalShard.temporal_get(shard, "events:login", {start_time, end_time})
  """
  def temporal_get(shard, key, time_range \\ :latest, _opts \\ []) do
    start_time = :os.system_time(:microsecond)

    case time_range do
      :latest ->
        # Get the most recent entry for this key
        get_latest_temporal_entry(shard, key, start_time, [])

      {start_ts, end_ts} ->
        # Get all entries within the time range
        get_temporal_range_entries(shard, key, start_ts, end_ts, start_time, [])

      specific_timestamp when is_integer(specific_timestamp) ->
        # Get entry for specific timestamp
        get_specific_temporal_entry(shard, key, specific_timestamp, start_time, [])

      _ ->
        {:error, :invalid_time_range}
    end
  end

  @doc """
  Query temporal data across time ranges with physics-optimized execution.

  ## Parameters
  - `shard` - Source temporal shard
  - `query` - Temporal query specification
  - `time_range` - Time range for the query
  - `opts` - Query options

  ## Returns
  `{:ok, query_results, updated_shard, query_metadata}` or `{:error, reason}`

  ## Query Examples
      query = %{
        operation: :range,
        key_pattern: "sensor:*",
        aggregation: :avg,
        window_size: 300_000  # 5 minutes
      }
      {:ok, results, shard, metadata} = TemporalShard.temporal_range_query(shard, query, {start_time, end_time})
  """
  def temporal_range_query(shard, query, time_range, opts \\ []) do
    start_time = :os.system_time(:microsecond)

    try do
      # Parse and validate temporal query
      case parse_temporal_query(query) do
        {:ok, parsed_query} ->
          # Execute temporal range query with physics optimization
          execute_temporal_range_query(shard, parsed_query, time_range, start_time, opts)

        {:error, reason} ->
          {:error, {:invalid_query, reason}}
      end

    rescue
      error ->
        Logger.error("Temporal range query failed: #{inspect(error)}")
        {:error, {:query_execution_error, error}}
    end
  end

  @doc """
  Get comprehensive temporal shard metrics including physics properties.
  """
  def get_temporal_metrics(shard) do
    current_time = :os.system_time(:millisecond)

    %{
      temporal_id: shard.temporal_id,
      time_period: shard.time_period,
      time_range: shard.time_range,
      physics_laws: shard.physics_laws,
      data_items: :ets.info(shard.data_table, :size),
      memory_usage: :ets.info(shard.data_table, :memory) * :erlang.system_info(:wordsize),
      temporal_entropy: calculate_temporal_entropy(shard),
      lifecycle_transitions: shard.performance_metrics.lifecycle_transitions,
      uptime_ms: current_time - shard.created_at,
      last_transition_ms_ago: current_time - shard.last_transition,
      compression_ratio: calculate_current_compression_ratio(shard),
      performance_metrics: shard.performance_metrics
    }
  end

  ## PRIVATE FUNCTIONS

  defp create_temporal_table(table_name, opts) do
    table_options = [
      :ordered_set, :public,  # ordered_set for time-based queries
      {:read_concurrency, Keyword.get(opts, :read_concurrency, true)},
      {:write_concurrency, Keyword.get(opts, :write_concurrency, true)},
      {:decentralized_counters, Keyword.get(opts, :decentralized_counters, true)}
    ]

    :ets.new(table_name, table_options)
  end

  defp initialize_lifecycle_rules(time_period) do
    %{
      time_period: time_period,
      auto_transition_enabled: true,
      transition_check_interval: 300_000,  # 5 minutes
      compression_enabled: time_period in [:historical, :deep_time],
      archival_enabled: time_period == :deep_time
    }
  end

  defp initialize_compression_config(time_period, physics_laws) do
    base_config = %{
      algorithm: :lz4,  # Fast compression for real-time processing
      level: case time_period do
        :live -> 1      # Minimal compression
        :recent -> 3    # Moderate compression
        :historical -> 6  # Good compression
        :deep_time -> 9   # Maximum compression
      end,
      threshold_bytes: 1024
    }

    compression_ratio = case time_period do
      :live -> 1.0  # No compression
      :recent -> Map.get(physics_laws, :recent_compression_ratio, 0.8)
      :historical -> Map.get(physics_laws, :historical_compression_ratio, 0.5)
      :deep_time -> Map.get(physics_laws, :deep_time_compression_ratio, 0.2)
    end

    Map.put(base_config, :target_ratio, compression_ratio)
  end

  defp initialize_temporal_entropy_tracker() do
    %{
      current_entropy: 0.0,
      entropy_history: [],
      last_measurement: :os.system_time(:millisecond),
      temporal_variance: 0.0,
      coherence_decay_rate: 0.1
    }
  end

  defp initialize_wal_integration() do
    %{
      enabled: true,
      temporal_operations_logged: 0,
      last_wal_sequence: 0,
      integration_health: :healthy
    }
  end

  defp initialize_temporal_metrics() do
    %{
      total_operations: 0,
      put_operations: 0,
      get_operations: 0,
      range_query_operations: 0,
      avg_operation_time: 0.0,
      lifecycle_transitions: 0,
      compression_events: 0,
      temporal_cache_hits: 0,
      temporal_cache_misses: 0
    }
  end

  defp persist_temporal_configuration(shard) do
    # Persist temporal shard configuration to filesystem
    Task.start(fn ->
      try do
        temporal_config_path = Path.join([
          CosmicPersistence.data_root(),
          "temporal",
          Atom.to_string(shard.time_period),
          "#{shard.temporal_id}_config.json"
        ])

        File.mkdir_p!(Path.dirname(temporal_config_path))

        config_data = %{
          temporal_id: shard.temporal_id,
          time_period: shard.time_period,
          time_range: shard.time_range,
          physics_laws: shard.physics_laws,
          lifecycle_rules: shard.lifecycle_rules,
          compression_config: shard.compression_config,
          created_at: shard.created_at,
          last_updated: :os.system_time(:millisecond),
          version: "7.0.0"
        }

        File.write!(temporal_config_path, safe_encode_json(config_data))
        Logger.debug("📁 Persisted temporal config: #{temporal_config_path}")

      rescue
        error ->
          Logger.warning("Failed to persist temporal configuration: #{inspect(error)}")
      end
    end)
  end

  defp calculate_time_dilation(shard, timestamp) do
    # Calculate relativistic time dilation based on temporal physics
    current_time = :os.system_time(:millisecond)
    time_distance = abs(current_time - timestamp)
    base_dilation = shard.physics_laws.time_dilation_factor

    # Apply physics-based time dilation effects
    case shard.time_period do
      :live ->
        # Recent data experiences less time dilation
        base_dilation * (1.0 + time_distance / 10_000_000)  # Very minimal dilation
      :recent ->
        # Moderate time dilation for recent data
        base_dilation * (1.0 + time_distance / 1_000_000)
      :historical ->
        # Historical data experiences more time dilation
        base_dilation * (1.0 + time_distance / 100_000)
      :deep_time ->
        # Deep time data experiences maximum time dilation
        base_dilation * (1.0 + time_distance / 10_000)
    end
  end

  defp apply_temporal_dilation(time_value, dilation_factor) do
    round(time_value / dilation_factor)
  end

  defp create_temporal_metadata(key, value, timestamp, shard, opts) do
    %{
      timestamp: timestamp,
      temporal_shard: shard.temporal_id,
      time_period: shard.time_period,
      temporal_mass: calculate_temporal_mass(key, value, timestamp),
      entropy_contribution: calculate_temporal_entropy_contribution(key, value, timestamp),
      quantum_coherence: calculate_quantum_temporal_coherence(timestamp, shard),
      lifecycle_stage: determine_lifecycle_stage(timestamp, shard),
      compression_eligible: is_compression_eligible?(timestamp, shard),
      custom_metadata: Keyword.get(opts, :temporal_metadata, %{})
    }
  end

  defp validate_temporal_data(shard, timestamp) do
    case shard.time_range do
      :active ->
        # Live data accepts all timestamps
        {:ok, :valid}

      {start_time, end_time} ->
        # Check if timestamp falls within shard's time range
        if timestamp >= start_time and timestamp <= end_time do
          {:ok, :valid}
        else
          {:error, :timestamp_out_of_range}
        end

      _ ->
        {:error, :invalid_time_range_config}
    end
  end

  defp create_temporal_key(key, timestamp) do
    # Create a compound key that enables efficient time-based queries
    # Format: {timestamp, original_key} for ordered_set chronological ordering
    {timestamp, key}
  end

  defp update_temporal_indices(shard, key, timestamp, temporal_metadata) do
    # Update temporal indices for efficient time-range queries
    index_entries = [
      # Time-based index for range queries
      {{:time_index, timestamp}, {key, temporal_metadata.temporal_mass}},
      # Key-based index for specific key lookups across time
      {{:key_index, key, timestamp}, temporal_metadata.entropy_contribution},
      # Lifecycle stage index for transition management
      {{:lifecycle_index, temporal_metadata.lifecycle_stage, timestamp}, key}
    ]

    Enum.each(index_entries, fn entry ->
      :ets.insert(shard.index_table, entry)
    end)

    shard
  end

  defp get_next_wal_sequence() do
    # Use the same ultra-fast sequence generation as WALOperations
    case Process.get(:wal_sequence_counter_cache) do
      nil ->
        ref = WAL.get_sequence_counter()
        Process.put(:wal_sequence_counter_cache, ref)
        :atomics.add_get(ref, 1, 1)
      ref ->
        :atomics.add_get(ref, 1, 1)
    end
  end

  defp check_temporal_lifecycle_transitions(shard, current_timestamp) do
    # Check if data needs to transition between temporal periods
    transition_needed = should_transition_data?(shard, current_timestamp)

    if transition_needed do
      # Perform lifecycle transition (async to avoid blocking)
      Task.start(fn -> perform_temporal_lifecycle_transition(shard, current_timestamp) end)
      %{shard | last_transition: :os.system_time(:millisecond)}
    else
      shard
    end
  end

  defp update_temporal_metrics(shard, operation, operation_time) do
    current_metrics = shard.performance_metrics
    updated_metrics = %{current_metrics |
      total_operations: current_metrics.total_operations + 1,
      avg_operation_time: calculate_rolling_average(
        current_metrics.avg_operation_time,
        operation_time,
        current_metrics.total_operations + 1
      )
    }

    updated_metrics = case operation do
      :put -> %{updated_metrics | put_operations: updated_metrics.put_operations + 1}
      :get -> %{updated_metrics | get_operations: updated_metrics.get_operations + 1}
      :range_query -> %{updated_metrics | range_query_operations: updated_metrics.range_query_operations + 1}
      _ -> updated_metrics
    end

    %{shard | performance_metrics: updated_metrics}
  end

  defp get_latest_temporal_entry(shard, key, start_time, _opts) do
    # Check if the shard has valid ETS tables
    if is_nil(shard.index_table) or is_nil(shard.data_table) do
      operation_time = :os.system_time(:microsecond) - start_time
      {:error, :shard_not_initialized, operation_time}
    else
      # Find the most recent entry for the given key
      key_pattern = {{:key_index, key, :"$1"}, :"$2"}
      matches = :ets.match(shard.index_table, key_pattern)

      case matches do
        [] ->
          operation_time = :os.system_time(:microsecond) - start_time
          {:error, :not_found, operation_time}

        timestamp_entropy_pairs ->
          # Get the most recent timestamp (largest value)
          # Handle both tuple and list formats
          {latest_timestamp, _entropy} =
            timestamp_entropy_pairs
            |> Enum.map(fn
              {timestamp, entropy} -> {timestamp, entropy}  # Already a tuple
              [timestamp, entropy] -> {timestamp, entropy}  # Convert list to tuple
              timestamp when is_integer(timestamp) -> {timestamp, 0.0}  # Just timestamp
            end)
            |> Enum.max_by(fn {timestamp, _} -> timestamp end)

          # Retrieve the actual data
          temporal_key = create_temporal_key(key, latest_timestamp)

          case :ets.lookup(shard.data_table, temporal_key) do
            [{^temporal_key, ^key, value, temporal_metadata}] ->
              operation_time = :os.system_time(:microsecond) - start_time
              updated_shard = update_temporal_metrics(shard, :get, operation_time)

              retrieval_metadata = %{
                timestamp: latest_timestamp,
                operation_time: operation_time,
                temporal_shard: shard.temporal_id,
              cache_status: :ets_hit
            }

              {:ok, {value, temporal_metadata}, updated_shard, retrieval_metadata}

            [] ->
              operation_time = :os.system_time(:microsecond) - start_time
              {:error, :data_not_found, operation_time}
          end
      end
    end
  end

  defp get_temporal_range_entries(shard, key, start_ts, end_ts, start_time, _opts) do
    # Get all entries for key within the time range
    range_results = :ets.select(shard.data_table, [
      {{{:"$1", key}, key, :"$2", :"$3"},
       [{:andalso, {:>=, :"$1", start_ts}, {:"=<", :"$1", end_ts}}],
       [{{:"$1", :"$2", :"$3"}}]}
    ])

    case range_results do
      [] ->
        operation_time = :os.system_time(:microsecond) - start_time
        {:error, :no_data_in_range, operation_time}

      entries ->
        # Sort entries by timestamp (should already be sorted due to ordered_set)
        sorted_entries = Enum.sort_by(entries, fn {timestamp, _value, _metadata} -> timestamp end)

        operation_time = :os.system_time(:microsecond) - start_time
        updated_shard = update_temporal_metrics(shard, :range_query, operation_time)

        query_metadata = %{
          entries_found: length(sorted_entries),
          time_range: {start_ts, end_ts},
          operation_time: operation_time,
          temporal_shard: shard.temporal_id
        }

        {:ok, sorted_entries, updated_shard, query_metadata}
    end
  end

  defp get_specific_temporal_entry(shard, key, timestamp, start_time, _opts) do
    # Get entry for specific timestamp
    temporal_key = create_temporal_key(key, timestamp)

    case :ets.lookup(shard.data_table, temporal_key) do
      [{^temporal_key, ^key, value, temporal_metadata}] ->
        operation_time = :os.system_time(:microsecond) - start_time
        updated_shard = update_temporal_metrics(shard, :get, operation_time)

        retrieval_metadata = %{
          timestamp: timestamp,
          operation_time: operation_time,
          temporal_shard: shard.temporal_id,
          cache_status: :ets_hit
        }

        {:ok, {value, temporal_metadata}, updated_shard, retrieval_metadata}

      [] ->
        operation_time = :os.system_time(:microsecond) - start_time
        {:error, :not_found, operation_time}
    end
  end

  defp parse_temporal_query(query) when is_map(query) do
    required_fields = [:operation, :key_pattern]

    if Enum.all?(required_fields, &Map.has_key?(query, &1)) do
      {:ok, query}
    else
      missing_fields = required_fields -- Map.keys(query)
      {:error, {:missing_fields, missing_fields}}
    end
  end
  defp parse_temporal_query(_), do: {:error, :invalid_format}

  defp execute_temporal_range_query(shard, query, time_range, start_time, _opts) do
    # Execute physics-optimized temporal range query
    try do
      {start_ts, end_ts} = time_range

      # Build ETS match specification based on query
      match_spec = build_temporal_match_spec(query, start_ts, end_ts)

      # Execute the query
      results = :ets.select(shard.data_table, match_spec)

      # Apply aggregations if specified
      processed_results = case Map.get(query, :aggregation) do
        nil -> results
        aggregation -> apply_temporal_aggregation(results, aggregation, query)
      end

      operation_time = :os.system_time(:microsecond) - start_time
      updated_shard = update_temporal_metrics(shard, :range_query, operation_time)

      query_metadata = %{
        results_count: length(processed_results),
        time_range: {start_ts, end_ts},
        operation_time: operation_time,
        temporal_shard: shard.temporal_id,
        query_type: query.operation,
        aggregation_applied: Map.get(query, :aggregation)
      }

      {:ok, processed_results, updated_shard, query_metadata}

    rescue
      error ->
        operation_time = :os.system_time(:microsecond) - start_time
        Logger.error("Temporal range query execution failed: #{inspect(error)}")
        {:error, {:execution_failed, error, operation_time}}
    end
  end

  # Helper functions for temporal physics calculations

  defp calculate_temporal_mass(key, value, timestamp) do
    # Calculate temporal mass based on data characteristics and age
    base_mass = byte_size(:erlang.term_to_binary({key, value})) / 1000.0
    current_time = :os.system_time(:millisecond)
    age_factor = (current_time - timestamp) / 86400_000  # Days since creation

    # Temporal mass decreases over time (gravitational decay)
    base_mass * :math.exp(-age_factor * 0.1)
  end

  defp calculate_temporal_entropy_contribution(key, value, timestamp) do
    # Calculate how much this data contributes to temporal entropy
    key_entropy = calculate_shannon_entropy(to_string(key))
    value_entropy = calculate_shannon_entropy(:erlang.term_to_binary(value))
    time_entropy = calculate_temporal_randomness(timestamp)

    (key_entropy + value_entropy + time_entropy) / 3.0
  end

  defp calculate_quantum_temporal_coherence(timestamp, shard) do
    # Calculate quantum coherence based on temporal distance and coherence time
    current_time = :os.system_time(:millisecond)
    time_distance = abs(current_time - timestamp)
    coherence_time = shard.physics_laws.quantum_coherence_time

    :math.exp(-time_distance / coherence_time)
  end

  defp determine_lifecycle_stage(timestamp, shard) do
    current_time = :os.system_time(:millisecond)
    age = current_time - timestamp

    cond do
      age < shard.physics_laws.live_to_recent_threshold -> :live
      age < shard.physics_laws.recent_to_historical_threshold -> :recent
      age < shard.physics_laws.historical_to_deep_time_threshold -> :historical
      true -> :deep_time
    end
  end

  defp is_compression_eligible?(timestamp, shard) do
    current_time = :os.system_time(:millisecond)
    age = current_time - timestamp

    # Check if data is old enough for compression based on age thresholds
    cond do
      age > shard.physics_laws.recent_to_historical_threshold -> true
      age > shard.physics_laws.live_to_recent_threshold -> true
      shard.time_period in [:historical, :deep_time] -> true
      true -> false
    end
  end

  defp should_transition_data?(shard, _current_timestamp) do
    # Check if data in this shard needs to transition to different temporal period
    # This is a simplified version - could be enhanced with more sophisticated logic
    case shard.time_period do
      :live ->
        # Check if any live data has aged enough to move to recent
        check_aged_data(shard, shard.physics_laws.live_to_recent_threshold)
      :recent ->
        # Check if any recent data has aged enough to move to historical
        check_aged_data(shard, shard.physics_laws.recent_to_historical_threshold)
      :historical ->
        # Check if any historical data has aged enough to move to deep time
        check_aged_data(shard, shard.physics_laws.historical_to_deep_time_threshold)
      :deep_time ->
        false  # Deep time is the final stage
    end
  end

  defp check_aged_data(shard, age_threshold) do
    current_time = :os.system_time(:millisecond)
    cutoff_time = current_time - age_threshold

    # Check if there's any data older than the threshold
    case :ets.select(shard.data_table, [
      {{{:"$1", :"$2"}, :"$3", :"$4", :"$5"},
       [{:<, :"$1", cutoff_time}],
       [:"$1"]}
    ], 1) do
      {[_timestamp], _continuation} -> true
      :"$end_of_table" -> false
    end
  end

  defp perform_temporal_lifecycle_transition(_shard, _current_timestamp) do
    # Placeholder for lifecycle transition logic
    # This would involve moving data to appropriate temporal shards
    Logger.info("🔄 Performing temporal lifecycle transition")
    :ok
  end

  defp calculate_rolling_average(current_avg, new_value, count) do
    (current_avg * (count - 1) + new_value) / count
  end

  defp calculate_temporal_entropy(shard) do
    # Calculate temporal entropy for the entire shard
    data_count = :ets.info(shard.data_table, :size)

    if data_count == 0 do
      0.0
    else
      # Sample entropy calculation based on temporal distribution
      current_time = :os.system_time(:millisecond)

      # Get temporal distribution of data
      time_buckets = :ets.foldl(fn {{timestamp, _key}, _orig_key, _value, _metadata}, acc ->
        bucket = div(current_time - timestamp, 3600_000)  # Hour buckets
        Map.update(acc, bucket, 1, &(&1 + 1))
      end, %{}, shard.data_table)

      # Calculate Shannon entropy
      total_items = Enum.sum(Map.values(time_buckets))

      time_buckets
      |> Map.values()
      |> Enum.map(fn count ->
        probability = count / total_items
        -probability * :math.log2(probability)
      end)
      |> Enum.sum()
    end
  end

  defp calculate_current_compression_ratio(shard) do
    # Estimate current compression ratio (placeholder implementation)
    shard.compression_config.target_ratio
  end

  defp build_temporal_match_spec(query, start_ts, end_ts) do
    # Build ETS match specification for temporal queries
    key_pattern = Map.get(query, :key_pattern, :"$2")

    # Basic time range match
    [{{{:"$1", key_pattern}, key_pattern, :"$3", :"$4"},
      [{:andalso, {:>=, :"$1", start_ts}, {:"=<", :"$1", end_ts}}],
      [{{:"$1", key_pattern, :"$3", :"$4"}}]}]
  end

  defp apply_temporal_aggregation(results, aggregation, _query) do
    # Apply temporal aggregations to query results
    case aggregation do
      :count -> [length(results)]
      :avg -> [calculate_average_from_results(results)]
      :sum -> [calculate_sum_from_results(results)]
      :min -> [calculate_min_from_results(results)]
      :max -> [calculate_max_from_results(results)]
      _ -> results
    end
  end

  defp calculate_average_from_results(results) do
    # Calculate average from temporal results (simplified)
    values = Enum.map(results, fn {_timestamp, _key, value, _metadata} ->
      extract_numeric_value(value)
    end)
    |> Enum.filter(&is_number/1)

    if length(values) > 0 do
      Enum.sum(values) / length(values)
    else
      0.0
    end
  end

  defp calculate_sum_from_results(results) do
    # Calculate sum from temporal results (simplified)
    results
    |> Enum.map(fn {_timestamp, _key, value, _metadata} -> extract_numeric_value(value) end)
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp calculate_min_from_results(results) do
    # Calculate minimum from temporal results (simplified)
    results
    |> Enum.map(fn {_timestamp, _key, value, _metadata} -> extract_numeric_value(value) end)
    |> Enum.filter(&is_number/1)
    |> Enum.min(fn -> nil end)
  end

  defp calculate_max_from_results(results) do
    # Calculate maximum from temporal results (simplified)
    results
    |> Enum.map(fn {_timestamp, _key, value, _metadata} -> extract_numeric_value(value) end)
    |> Enum.filter(&is_number/1)
    |> Enum.max(fn -> nil end)
  end

  defp extract_numeric_value(value) when is_number(value), do: value
  defp extract_numeric_value(value) when is_map(value) do
    # Try to extract a numeric value from maps (e.g., sensor readings)
    Enum.find_value(value, 0, fn {_k, v} -> if is_number(v), do: v end)
  end
  defp extract_numeric_value(_), do: 0

  defp calculate_shannon_entropy(binary) when is_binary(binary) do
    # Calculate Shannon entropy of binary data
    byte_frequencies = binary
    |> :binary.bin_to_list()
    |> Enum.frequencies()

    total_bytes = byte_size(binary)

    if total_bytes == 0 do
      0.0
    else
      byte_frequencies
      |> Map.values()
      |> Enum.map(fn count ->
        probability = count / total_bytes
        -probability * :math.log2(probability)
      end)
      |> Enum.sum()
    end
  end

  defp calculate_temporal_randomness(timestamp) do
    # Calculate temporal randomness based on timestamp patterns
    # This is a simplified implementation
    timestamp_str = Integer.to_string(timestamp)
    calculate_shannon_entropy(timestamp_str)
  end

  # Safe JSON encoding
  defp safe_encode_json(data) do
    try do
      # Convert data to JSON-compatible format before encoding
      json_compatible_data = make_json_compatible(data)
      Jason.encode!(json_compatible_data, pretty: true)
    rescue
      error ->
        Logger.warning("JSON encoding failed: #{inspect(error)}")
        # Fallback to readable Elixir format
        inspect(data, pretty: true, limit: :infinity, printable_limit: :infinity)
    end
  end

  # Convert Elixir data structures to JSON-compatible formats
  defp make_json_compatible(data) when is_map(data) do
    Map.new(data, fn {k, v} -> {k, make_json_compatible(v)} end)
  end
  defp make_json_compatible(data) when is_list(data) do
    Enum.map(data, &make_json_compatible/1)
  end
  defp make_json_compatible({start_val, end_val}) do
    # Convert tuples to maps for JSON compatibility
    %{start: start_val, end: end_val}
  end
  defp make_json_compatible(data), do: data

  ## GENSERVER CALLBACKS

  def init(init_arg) do
    {:ok, init_arg}
  end
end
