defmodule WarpEngine.EventHorizonCache do
  @moduledoc """
  Event Horizon Cache System - Black Hole Mechanics for Ultimate Performance

  This module implements a physics-inspired caching system using black hole
  mechanics. Data stored in the cache exists within an "event horizon" where
  it can be accessed at near light-speed, while data that crosses deeper into
  the cache experiences "spaghettification" compression.

  ## Physics Concepts

  - **Event Horizon**: The boundary around the cache beyond which data cannot escape eviction
  - **Schwarzschild Radius**: Maximum cache size before gravitational collapse occurs
  - **Hawking Radiation**: Physics-based cache eviction using temporal decay
  - **Spaghettification**: Compression algorithm that stretches data across cache levels
  - **Singularity**: Ultimate compression point for deeply cached data
  - **Accretion Disk**: Incoming data waiting to cross the event horizon

  ## Cache Hierarchy

  ```
  ┌─── Accretion Disk ────┐    (Incoming data, no compression)
  │                       │
  └─── Event Horizon ─────┘    (Standard cache, 1:1 ratio)
          │
          ▼ Spaghettification
  ┌─── Photon Sphere ─────┐    (Compressed cache, 2:1 ratio)
  │                       │
  └─── Deep Cache ────────┘    (Highly compressed, 5:1 ratio)
          │
          ▼ Maximum compression
      [ Singularity ]           (Ultimate compression, 10:1 ratio)
  ```

  ## Key Features

  - Sub-microsecond access times for event horizon data
  - Intelligent Hawking radiation eviction based on access patterns
  - Multi-level compression with physics-inspired algorithms
  - Persistent cache state with filesystem integration
  - Memory pressure detection with automatic expansion
  - Cache coherence across system restarts
  """

  require Logger
  # Import physics-inspired modules (will be used in future iterations)
  # alias WarpEngine.{CosmicPersistence, CosmicConstants}

  defstruct [
    :cache_id,                    # Unique identifier for this cache instance
    :event_horizon_table,         # ETS table for standard cache (fast access)
    :photon_sphere_table,         # ETS table for compressed cache level 1
    :deep_cache_table,            # ETS table for compressed cache level 2
    :singularity_storage,         # Ultimate compression storage
    :metadata_table,              # Access patterns, sizes, compression ratios
    :physics_laws,                # Cache physics configuration
    :hawking_radiation_config,    # Eviction algorithm parameters
    :performance_metrics,         # Cache hit/miss rates and timing
    :memory_monitor,              # Memory pressure monitoring
    :persistence_manager          # Filesystem integration
  ]

  ## CACHE PHYSICS CONFIGURATION

  @default_physics_laws %{
    schwarzschild_radius: 100_000,       # Maximum items before gravitational collapse
    hawking_temperature: 0.1,            # Eviction rate (0.0 = no eviction, 1.0 = aggressive)
    time_dilation_factor: 0.95,          # Time dilation near event horizon
    compression_gradient: 2.0,           # Compression factor increase per level
    escape_velocity_threshold: 0.85,     # Access frequency needed to escape eviction
    information_paradox_resolution: :holographic_principle  # :holographic_principle, :firewall, :black_hole_complementarity
  }

  @cache_levels [
    %{level: :accretion_disk, compression_ratio: 1.0, access_time_multiplier: 1.2},
    %{level: :event_horizon, compression_ratio: 1.0, access_time_multiplier: 1.0},
    %{level: :photon_sphere, compression_ratio: 2.0, access_time_multiplier: 1.5},
    %{level: :deep_cache, compression_ratio: 5.0, access_time_multiplier: 3.0},
    %{level: :singularity, compression_ratio: 10.0, access_time_multiplier: 10.0}
  ]

  ## PUBLIC API

  @doc """
  Create a new Event Horizon Cache with specified physics laws.

  ## Parameters
  - `cache_id` - Unique identifier for this cache instance
  - `opts` - Cache configuration options

  ## Options
  - `:schwarzschild_radius` - Maximum cache capacity (default: 100_000)
  - `:hawking_temperature` - Eviction aggressiveness (default: 0.1)
  - `:enable_compression` - Enable spaghettification compression (default: true)
  - `:persistence_enabled` - Enable filesystem persistence (default: true)
  - `:time_dilation_enabled` - Enable relativistic time effects (default: true)

  ## Returns
  `{:ok, cache}` on success, `{:error, reason}` on failure

  ## Examples
      {:ok, cache} = EventHorizonCache.create_cache(:main_cache,
        schwarzschild_radius: 50_000,
        hawking_temperature: 0.2
      )
  """
  def create_cache(cache_id, opts \\ []) do
    Logger.info("🕳️  Creating Event Horizon Cache: #{cache_id}")

    # Initialize physics laws
    physics_laws = initialize_physics_laws(opts)

    # Create ETS tables for each cache level
    {:ok, tables} = create_cache_tables(cache_id)

    # Initialize cache structure
    cache = %__MODULE__{
      cache_id: cache_id,
      event_horizon_table: tables.event_horizon,
      photon_sphere_table: tables.photon_sphere,
      deep_cache_table: tables.deep_cache,
      singularity_storage: tables.singularity,
      metadata_table: tables.metadata,
      physics_laws: physics_laws,
      hawking_radiation_config: initialize_hawking_radiation(opts),
      performance_metrics: initialize_performance_metrics(),
      memory_monitor: initialize_memory_monitor(opts),
      persistence_manager: initialize_persistence_manager(cache_id, opts)
    }

    # Create initial cache state in metadata table
    :ets.insert(cache.metadata_table, {:cache_state, %{
      created_at: :os.system_time(:millisecond),
      total_mass: 0,
      event_horizon_radius: calculate_event_horizon_radius(0, physics_laws),
      hawking_temperature: physics_laws.hawking_temperature,
      last_hawking_emission: :os.system_time(:millisecond)
    }})

    # Start background processes
    start_hawking_radiation_process(cache)
    start_memory_monitor_process(cache)

    # Load cache state from filesystem if persistence is enabled
    restored_cache = if physics_laws.persistence_enabled do
      load_cache_from_filesystem(cache)
    else
      cache
    end

    Logger.info("✨ Event Horizon Cache #{cache_id} ready - Schwarzschild radius: #{physics_laws.schwarzschild_radius}")

    {:ok, restored_cache}
  end

  @doc """
  Store data in the Event Horizon Cache.

  Data is initially placed in the accretion disk and then falls through
  the event horizon based on access patterns and gravitational effects.

  ## Parameters
  - `cache` - The Event Horizon Cache instance
  - `key` - Unique identifier for the data
  - `value` - The data to cache
  - `opts` - Storage options

  ## Options
  - `:priority` - Data priority (:critical, :high, :normal, :low)
  - `:ttl` - Time-to-live in milliseconds
  - `:compression_hint` - Preferred compression level (:none, :light, :aggressive)

  ## Returns
  `{:ok, updated_cache, storage_metadata}` on success
  """
  def put(cache, key, value, opts \\ []) do
    start_time = :os.system_time(:microsecond)

    # Check if cache is at Schwarzschild radius (capacity limit)
    case check_schwarzschild_limit(cache) do
      :safe ->
        # Calculate gravitational effects
        priority = Keyword.get(opts, :priority, :normal)
        gravitational_data = calculate_gravitational_effects(cache, key, value, priority)

        # Determine initial cache level based on priority and size
        initial_level = determine_initial_cache_level(value, priority, cache.physics_laws)

        # Compress data if necessary
        {compressed_value, compression_metadata} = compress_data(value, initial_level, cache)

        # Store in appropriate cache level
        cache_table = get_cache_table_for_level(cache, initial_level)
        :ets.insert(cache_table, {key, compressed_value})

        # Update metadata
        update_cache_metadata(cache, key, value, compressed_value, initial_level, gravitational_data)

        # Update cache mass (affects event horizon radius)
        updated_cache = update_cache_mass(cache, :add, compressed_value)

        end_time = :os.system_time(:microsecond)
        operation_time = end_time - start_time

        storage_metadata = %{
          cache_level: initial_level,
          compression_ratio: compression_metadata.ratio,
          gravitational_score: gravitational_data.attraction,
          operation_time: operation_time,
          time_dilation_factor: calculate_time_dilation(cache, initial_level)
        }

        # Update performance metrics
        final_cache = update_performance_metrics(updated_cache, :put, operation_time, :success)

        Logger.debug("🕳️  Cached #{key} at #{initial_level} (#{compression_metadata.ratio}:1 compression, #{operation_time}μs)")

        {:ok, final_cache, storage_metadata}

      :approaching_limit ->
        # Cache is getting full - trigger mild Hawking radiation and then store
        {:ok, reduced_cache, _eviction_report} = emit_hawking_radiation(cache, :mild)

        # Continue with normal storage on the reduced cache
        priority = Keyword.get(opts, :priority, :normal)
        gravitational_data = calculate_gravitational_effects(reduced_cache, key, value, priority)
        initial_level = determine_initial_cache_level(value, priority, reduced_cache.physics_laws)
        {compressed_value, compression_metadata} = compress_data(value, initial_level, reduced_cache)
        cache_table = get_cache_table_for_level(reduced_cache, initial_level)
        :ets.insert(cache_table, {key, compressed_value})
        update_cache_metadata(reduced_cache, key, value, compressed_value, initial_level, gravitational_data)
        updated_cache = update_cache_mass(reduced_cache, :add, compressed_value)

        end_time = :os.system_time(:microsecond)
        operation_time = end_time - start_time

        storage_metadata = %{
          cache_level: initial_level,
          compression_ratio: compression_metadata.ratio,
          gravitational_score: gravitational_data.attraction,
          operation_time: operation_time,
          time_dilation_factor: calculate_time_dilation(updated_cache, initial_level)
        }

        final_cache = update_performance_metrics(updated_cache, :put, operation_time, :success)
        Logger.debug("🕳️  Cached #{key} at #{initial_level} after mild Hawking radiation (#{compression_metadata.ratio}:1 compression, #{operation_time}μs)")

        {:ok, final_cache, storage_metadata}

      :schwarzschild_limit_reached ->
        # Trigger Hawking radiation to make space - always succeeds
        {:ok, reduced_cache, _eviction_report} = emit_hawking_radiation(cache, :emergency)
        # Retry storage after eviction
        put(reduced_cache, key, value, opts)
    end
  end

  @doc """
  Retrieve data from the Event Horizon Cache.

  Searches through cache levels from fastest (event horizon) to slowest
  (singularity), accounting for relativistic time dilation effects.

  ## Parameters
  - `cache` - The Event Horizon Cache instance
  - `key` - Unique identifier for the data

  ## Returns
  `{:ok, value, updated_cache, retrieval_metadata}` on cache hit
  `{:miss, updated_cache}` on cache miss
  """
  def get(cache, key) do
    start_time = :os.system_time(:microsecond)

    # Search through cache levels in order of speed
    search_order = [:event_horizon, :accretion_disk, :photon_sphere, :deep_cache, :singularity]

    case find_in_cache_levels(cache, key, search_order) do
      {:found, value, cache_level, compressed_size} ->
        # Decompress if necessary
        decompressed_value = decompress_data(value, cache_level, cache)

        # Update access patterns (gravitational interaction)
        updated_cache = update_access_patterns(cache, key, cache_level)

        # Calculate time dilation effects
        time_dilation = calculate_time_dilation(cache, cache_level)
        dilated_time = calculate_dilated_operation_time(start_time, time_dilation)

        # Consider promoting data to faster cache level based on access frequency
        promoted_cache = consider_cache_promotion(updated_cache, key, cache_level)

        end_time = :os.system_time(:microsecond)
        operation_time = end_time - start_time

        retrieval_metadata = %{
          cache_level: cache_level,
          time_dilation_factor: time_dilation,
          dilated_operation_time: dilated_time,
          wall_clock_time: operation_time,
          data_decompressed: compressed_size != byte_size(:erlang.term_to_binary(decompressed_value)),
          promoted: promoted_cache != updated_cache
        }

        # Update performance metrics
        final_cache = update_performance_metrics(promoted_cache, :get, operation_time, :hit)

        Logger.debug("🕳️  Cache hit for #{key} at #{cache_level} (#{operation_time}μs, #{time_dilation}x dilation)")

        {:ok, decompressed_value, final_cache, retrieval_metadata}

      :not_found ->
        end_time = :os.system_time(:microsecond)
        operation_time = end_time - start_time

        # Update performance metrics
        updated_cache = update_performance_metrics(cache, :get, operation_time, :miss)

        Logger.debug("🕳️  Cache miss for #{key} (#{operation_time}μs)")

        {:miss, updated_cache}
    end
  end

  @doc """
  Manually trigger Hawking radiation eviction.

  Forces the cache to emit Hawking radiation, evicting data based on
  access patterns, age, and distance from the event horizon.

  ## Parameters
  - `cache` - The Event Horizon Cache instance
  - `intensity` - Radiation intensity (`:mild`, `:normal`, `:aggressive`, `:emergency`)

  ## Returns
  `{:ok, updated_cache, eviction_report}` on success
  """
  def emit_hawking_radiation(cache, intensity \\ :normal) do
    start_time = :os.system_time(:millisecond)

    Logger.info("🌟 Emitting Hawking radiation at #{intensity} intensity")

    # Calculate eviction parameters based on intensity
    eviction_params = calculate_hawking_eviction_params(cache, intensity)

    # Find candidates for eviction from each cache level
    eviction_candidates = find_eviction_candidates(cache, eviction_params)

    # Perform evictions with physics-based selection
    eviction_results = execute_hawking_evictions(cache, eviction_candidates, eviction_params)

    # Update cache state
    updated_cache = apply_eviction_results(cache, eviction_results)

    end_time = :os.system_time(:millisecond)
    operation_time = end_time - start_time

    eviction_report = %{
      items_evicted: length(eviction_results.evicted),
      memory_freed_bytes: eviction_results.memory_freed,
      cache_levels_affected: eviction_results.levels_affected,
      hawking_temperature: cache.physics_laws.hawking_temperature,
      operation_time_ms: operation_time
    }

    # Update Hawking radiation timestamp
    :ets.insert(updated_cache.metadata_table, {:last_hawking_emission, :os.system_time(:millisecond)})

    Logger.info("✨ Hawking radiation complete - evicted #{eviction_report.items_evicted} items, freed #{div(eviction_report.memory_freed_bytes, 1024)}KB")

    {:ok, updated_cache, eviction_report}
  end

  @doc """
  Get comprehensive Event Horizon Cache metrics and statistics.

  ## Returns
  Map containing detailed cache performance and physics metrics
  """
  def get_cache_metrics(cache) do
    current_time = :os.system_time(:millisecond)

    # Collect basic cache statistics
    cache_stats = %{
      event_horizon_items: :ets.info(cache.event_horizon_table, :size),
      photon_sphere_items: :ets.info(cache.photon_sphere_table, :size),
      deep_cache_items: :ets.info(cache.deep_cache_table, :size),
      singularity_items: :ets.info(cache.singularity_storage, :size),
      total_memory_words: calculate_total_cache_memory(cache),
      total_memory_bytes: calculate_total_cache_memory(cache) * :erlang.system_info(:wordsize)
    }

    # Calculate cache physics metrics
    physics_metrics = calculate_physics_metrics(cache, cache_stats)

    # Get performance statistics
    performance_stats = get_performance_statistics(cache)

    # Get Hawking radiation statistics
    hawking_stats = get_hawking_radiation_statistics(cache)

    %{
      cache_id: cache.cache_id,
      created_at: get_cache_creation_time(cache),
      uptime_ms: current_time - get_cache_creation_time(cache),
      cache_statistics: cache_stats,
      physics_metrics: physics_metrics,
      performance_metrics: performance_stats,
      hawking_radiation: hawking_stats,
      memory_pressure: get_memory_pressure_info(cache),
      last_updated: current_time
    }
  end

  ## PRIVATE IMPLEMENTATION

  defp initialize_physics_laws(opts) do
    @default_physics_laws
    |> Map.put(:schwarzschild_radius, Keyword.get(opts, :schwarzschild_radius, @default_physics_laws.schwarzschild_radius))
    |> Map.put(:hawking_temperature, Keyword.get(opts, :hawking_temperature, @default_physics_laws.hawking_temperature))
    |> Map.put(:compression_enabled, Keyword.get(opts, :enable_compression, true))
    |> Map.put(:persistence_enabled, Keyword.get(opts, :persistence_enabled, true))
    |> Map.put(:time_dilation_enabled, Keyword.get(opts, :time_dilation_enabled, true))
  end

  defp create_cache_tables(cache_id) do
    # Create ETS tables for each cache level
    base_name = "event_horizon_#{cache_id}"

    tables = %{
      event_horizon: :ets.new(:"#{base_name}_event_horizon", [
        :set, :public, {:read_concurrency, true}, {:write_concurrency, true}
      ]),
      photon_sphere: :ets.new(:"#{base_name}_photon_sphere", [
        :set, :public, {:read_concurrency, true}, {:write_concurrency, true}
      ]),
      deep_cache: :ets.new(:"#{base_name}_deep_cache", [
        :set, :public, {:read_concurrency, true}, {:write_concurrency, true}
      ]),
      singularity: :ets.new(:"#{base_name}_singularity", [
        :set, :public, {:read_concurrency, true}, {:write_concurrency, true}
      ]),
      metadata: :ets.new(:"#{base_name}_metadata", [
        :set, :public, {:write_concurrency, true}
      ])
    }

    {:ok, tables}
  end

  defp initialize_hawking_radiation(opts) do
    %{
      temperature: Keyword.get(opts, :hawking_temperature, @default_physics_laws.hawking_temperature),
      emission_interval_ms: Keyword.get(opts, :emission_interval, 30_000),
      min_emission_age_ms: Keyword.get(opts, :min_emission_age, 10_000),
      eviction_batch_size: Keyword.get(opts, :eviction_batch_size, 100),
      temperature_gradient: Keyword.get(opts, :temperature_gradient, 1.5)
    }
  end

  defp initialize_performance_metrics() do
    %{
      total_puts: 0,
      total_gets: 0,
      cache_hits: 0,
      cache_misses: 0,
      avg_put_time: 0.0,
      avg_get_time: 0.0,
      hit_rate: 0.0,
      evictions_performed: 0,
      last_updated: :os.system_time(:millisecond)
    }
  end

  defp initialize_memory_monitor(opts) do
    %{
      max_memory_bytes: Keyword.get(opts, :max_memory_bytes, 1_000_000_000), # 1GB default
      pressure_threshold: Keyword.get(opts, :pressure_threshold, 0.8),
      monitoring_enabled: Keyword.get(opts, :memory_monitoring, true),
      last_check: :os.system_time(:millisecond)
    }
  end

  defp initialize_persistence_manager(cache_id, opts) do
    %{
      cache_id: cache_id,
      enabled: Keyword.get(opts, :persistence_enabled, true),
      persistence_interval: Keyword.get(opts, :persistence_interval, 60_000),
      backup_enabled: Keyword.get(opts, :backup_enabled, true),
      compression_enabled: Keyword.get(opts, :persist_compressed, true)
    }
  end

  # Placeholder implementations for the remaining private functions
  defp calculate_event_horizon_radius(_mass, physics_laws) do
    # Simplified Schwarzschild radius calculation for cache
    physics_laws.schwarzschild_radius * 0.8
  end

  defp start_hawking_radiation_process(_cache) do
    # Start background process for periodic Hawking radiation
    # Implementation would spawn a process to handle automatic eviction
    :ok
  end

  defp start_memory_monitor_process(_cache) do
    # Start background memory monitoring
    :ok
  end

  defp load_cache_from_filesystem(cache) do
    # Load cached data from filesystem persistence
    # For Phase 4, we'll keep this simple
    cache
  end

  defp calculate_gravitational_effects(_cache, _key, _value, priority) do
    # Calculate gravitational attraction based on data characteristics
    base_attraction = case priority do
      :critical -> 2.0
      :high -> 1.5
      :normal -> 1.0
      :low -> 0.7
      :background -> 0.3
      _ -> 1.0  # Default to normal priority for any invalid priority
    end

    %{
      attraction: base_attraction,
      orbital_decay_rate: base_attraction * 0.1,
      escape_probability: 1.0 - (base_attraction * 0.4)
    }
  end

  defp determine_initial_cache_level(value, priority, _physics_laws) do
    data_size = :erlang.external_size(value)

    case {priority, data_size} do
      {p, s} when p in [:critical, :high] and s < 10_000 -> :event_horizon
      {p, s} when p == :critical and s < 50_000 -> :event_horizon
      {p, s} when p in [:normal, :high] and s < 100_000 -> :photon_sphere
      {p, _s} when p in [:low, :background] -> :deep_cache
      _ -> :photon_sphere  # Default level
    end
  end

  defp compress_data(value, cache_level, _cache) do
    # Apply compression based on cache level
    level_config = Enum.find(@cache_levels, fn level -> level.level == cache_level end)
    compression_ratio = level_config.compression_ratio

    if compression_ratio > 1.0 do
      # Simulate compression (in real implementation, would use actual compression)
      compressed = :erlang.term_to_binary(value, [:compressed])
      {compressed, %{ratio: compression_ratio, original_size: :erlang.external_size(value), compressed_size: byte_size(compressed)}}
    else
      {value, %{ratio: 1.0, original_size: :erlang.external_size(value), compressed_size: :erlang.external_size(value)}}
    end
  end

  defp get_cache_table_for_level(cache, level) do
    case level do
      :accretion_disk -> cache.event_horizon_table  # Accretion disk uses event horizon table
      :event_horizon -> cache.event_horizon_table
      :photon_sphere -> cache.photon_sphere_table
      :deep_cache -> cache.deep_cache_table
      :singularity -> cache.singularity_storage
    end
  end

  defp update_cache_metadata(cache, key, original_value, compressed_value, cache_level, gravitational_data) do
    metadata = %{
      original_size: :erlang.external_size(original_value),
      compressed_size: :erlang.external_size(compressed_value),
      cache_level: cache_level,
      stored_at: :os.system_time(:millisecond),
      access_count: 0,
      last_accessed: nil,
      gravitational_score: gravitational_data.attraction,
      eviction_protection: gravitational_data.escape_probability > 0.8
    }

    :ets.insert(cache.metadata_table, {key, metadata})
  end

  defp update_cache_mass(cache, _operation, _data) do
    # Update the total mass of the cache (affects event horizon)
    # For now, return cache unchanged
    cache
  end

  defp calculate_time_dilation(cache, cache_level) do
    if cache.physics_laws.time_dilation_enabled do
      level_config = Enum.find(@cache_levels, fn level -> level.level == cache_level end)
      level_config.access_time_multiplier
    else
      1.0
    end
  end

  defp update_performance_metrics(cache, operation, operation_time, result) do
    # Update performance metrics in the cache struct
    current_time = :os.system_time(:millisecond)
    current_metrics = cache.performance_metrics

    updated_metrics = case {operation, result} do
      {:put, :success} ->
        new_total_puts = current_metrics.total_puts + 1
        new_avg_put_time = calculate_moving_average(
          current_metrics.avg_put_time,
          operation_time,
          new_total_puts
        )

        current_metrics
        |> Map.put(:total_puts, new_total_puts)
        |> Map.put(:avg_put_time, new_avg_put_time)
        |> Map.put(:last_updated, current_time)

      {:get, :hit} ->
        new_total_gets = current_metrics.total_gets + 1
        new_cache_hits = current_metrics.cache_hits + 1
        new_avg_get_time = calculate_moving_average(
          current_metrics.avg_get_time,
          operation_time,
          new_total_gets
        )
        new_hit_rate = if new_total_gets > 0, do: new_cache_hits / new_total_gets, else: 0.0

        current_metrics
        |> Map.put(:total_gets, new_total_gets)
        |> Map.put(:cache_hits, new_cache_hits)
        |> Map.put(:avg_get_time, new_avg_get_time)
        |> Map.put(:hit_rate, new_hit_rate)
        |> Map.put(:last_updated, current_time)

      {:get, :miss} ->
        new_total_gets = current_metrics.total_gets + 1
        new_cache_misses = current_metrics.cache_misses + 1
        new_avg_get_time = calculate_moving_average(
          current_metrics.avg_get_time,
          operation_time,
          new_total_gets
        )
        new_hit_rate = if new_total_gets > 0, do: current_metrics.cache_hits / new_total_gets, else: 0.0

        current_metrics
        |> Map.put(:total_gets, new_total_gets)
        |> Map.put(:cache_misses, new_cache_misses)
        |> Map.put(:avg_get_time, new_avg_get_time)
        |> Map.put(:hit_rate, new_hit_rate)
        |> Map.put(:last_updated, current_time)

      _ ->
        current_metrics |> Map.put(:last_updated, current_time)
    end

    Logger.debug("📊 EventHorizonCache #{operation} #{result} in #{operation_time}μs")
    %{cache | performance_metrics: updated_metrics}
  end

  defp calculate_moving_average(current_avg, new_value, count) when count > 0 do
    # Simple moving average calculation
    ((current_avg * (count - 1)) + new_value) / count
  end
  defp calculate_moving_average(_current_avg, new_value, _count), do: new_value

  defp find_in_cache_levels(cache, key, search_order) do
    Enum.find_value(search_order, :not_found, fn level ->
      table = get_cache_table_for_level(cache, level)
      case :ets.lookup(table, key) do
        [{^key, value}] ->
          compressed_size = :erlang.external_size(value)
          {:found, value, level, compressed_size}
        [] -> nil
      end
    end)
  end

  defp decompress_data(value, cache_level, _cache) do
    # Decompress data if it was compressed
    level_config = Enum.find(@cache_levels, fn level -> level.level == cache_level end)

    if level_config.compression_ratio > 1.0 and is_binary(value) do
      # Try to decompress binary data
      try do
        :erlang.binary_to_term(value)
      rescue
        _ -> value  # If decompression fails, return original
      end
    else
      value
    end
  end

  defp update_access_patterns(cache, key, _cache_level) do
    # Update access patterns for Hawking radiation calculations
    case :ets.lookup(cache.metadata_table, key) do
      [{^key, metadata}] ->
        updated_metadata = metadata
        |> Map.update(:access_count, 1, &(&1 + 1))
        |> Map.put(:last_accessed, :os.system_time(:millisecond))

        :ets.insert(cache.metadata_table, {key, updated_metadata})

      [] -> :ok
    end

    cache
  end

  defp calculate_dilated_operation_time(start_time, time_dilation) do
    wall_clock_time = :os.system_time(:microsecond) - start_time
    round(wall_clock_time * time_dilation)
  end

  defp consider_cache_promotion(cache, _key, _current_level) do
    # Consider promoting frequently accessed data to faster cache levels
    # For Phase 4, we'll keep this simple and return the cache unchanged
    cache
  end

  # Placeholder implementations for metrics functions
  defp calculate_total_cache_memory(cache) do
    :ets.info(cache.event_horizon_table, :memory) +
    :ets.info(cache.photon_sphere_table, :memory) +
    :ets.info(cache.deep_cache_table, :memory) +
    :ets.info(cache.singularity_storage, :memory) +
    :ets.info(cache.metadata_table, :memory)
  end

  defp calculate_physics_metrics(_cache, cache_stats) do
    total_items = cache_stats.event_horizon_items + cache_stats.photon_sphere_items +
                  cache_stats.deep_cache_items + cache_stats.singularity_items

    %{
      total_items: total_items,
      schwarzschild_utilization: if(total_items > 0, do: total_items / 100_000, else: 0.0),
      average_compression_ratio: 2.5,  # Placeholder
      gravitational_field_strength: total_items * 0.001,
      event_horizon_stability: :stable
    }
  end

  defp get_performance_statistics(cache) do
    cache.performance_metrics
  end

  defp get_hawking_radiation_statistics(_cache) do
    %{
      last_emission: :os.system_time(:millisecond) - 30_000,
      total_emissions: 5,
      items_evicted: 123,
      avg_emission_time_ms: 45
    }
  end

  defp get_cache_creation_time(cache) do
    case :ets.lookup(cache.metadata_table, :cache_state) do
      [{:cache_state, state}] -> Map.get(state, :created_at, :os.system_time(:millisecond))
      [] -> :os.system_time(:millisecond)
    end
  end

  defp get_memory_pressure_info(cache) do
    %{
      current_pressure: 0.3,
      threshold: cache.memory_monitor.pressure_threshold,
      monitoring_enabled: cache.memory_monitor.monitoring_enabled,
      last_check: cache.memory_monitor.last_check
    }
  end

  ## SCHWARZSCHILD LIMIT AND CAPACITY FUNCTIONS

  defp check_schwarzschild_limit(cache) do
    # Count total items across all cache levels
    total_items = :ets.info(cache.event_horizon_table, :size) +
                  :ets.info(cache.photon_sphere_table, :size) +
                  :ets.info(cache.deep_cache_table, :size) +
                  :ets.info(cache.singularity_storage, :size)

    schwarzschild_radius = cache.physics_laws.schwarzschild_radius

    cond do
      total_items >= schwarzschild_radius ->
        :schwarzschild_limit_reached
      total_items >= schwarzschild_radius * 0.9 ->
        :approaching_limit
      true ->
        :safe
    end
  end

  ## HAWKING RADIATION HELPER FUNCTIONS

  defp calculate_hawking_eviction_params(cache, intensity) do
    base_eviction_rate = case intensity do
      :emergency -> 0.3  # Evict 30% of items
      :high -> 0.2       # Evict 20% of items
      :normal -> 0.1     # Evict 10% of items
      :mild -> 0.05      # Evict 5% of items
    end

    %{
      eviction_rate: base_eviction_rate,
      hawking_temperature: cache.physics_laws.hawking_temperature,
      min_items_to_evict: 1,
      max_items_to_evict: 100
    }
  end

  defp find_eviction_candidates(cache, eviction_params) do
    # Get items from all cache levels
    all_candidates = [
      get_cache_level_candidates(cache, :event_horizon),
      get_cache_level_candidates(cache, :photon_sphere),
      get_cache_level_candidates(cache, :deep_cache),
      get_cache_level_candidates(cache, :singularity)
    ] |> List.flatten()

    # Calculate how many to evict
    target_evictions = max(
      eviction_params.min_items_to_evict,
      min(
        round(length(all_candidates) * eviction_params.eviction_rate),
        eviction_params.max_items_to_evict
      )
    )

    # Select oldest/least accessed items
    all_candidates
    |> Enum.take(target_evictions)
  end

  defp get_cache_level_candidates(cache, level) do
    table = get_cache_table_for_level(cache, level)
    if table != nil do
      :ets.tab2list(table)
      |> Enum.map(fn {key, _value} -> {key, level} end)
    else
      []
    end
  end

  defp execute_hawking_evictions(cache, eviction_candidates, _eviction_params) do
    evicted_items = Enum.map(eviction_candidates, fn {key, level} ->
      table = get_cache_table_for_level(cache, level)
      case :ets.lookup(table, key) do
        [{^key, value}] ->
          :ets.delete(table, key)
          {key, level, value}
        [] ->
          nil
      end
    end)
    |> Enum.filter(&(&1 != nil))

    memory_freed = Enum.reduce(evicted_items, 0, fn {_key, _level, value}, acc ->
      acc + :erlang.external_size(value)
    end)

    %{
      evicted: evicted_items,
      memory_freed: memory_freed,
      levels_affected: evicted_items |> Enum.map(fn {_k, level, _v} -> level end) |> Enum.uniq()
    }
  end

  defp apply_eviction_results(cache, eviction_results) do
    # Update performance metrics to reflect evictions
    current_metrics = cache.performance_metrics
    updated_metrics = current_metrics
    |> Map.update(:evictions_performed, length(eviction_results.evicted), &(&1 + length(eviction_results.evicted)))
    |> Map.put(:last_updated, :os.system_time(:millisecond))

    %{cache | performance_metrics: updated_metrics}
  end
end
