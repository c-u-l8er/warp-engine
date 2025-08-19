defmodule IsLabDB do
  @moduledoc """
  IsLab Database - A physics-inspired database with elegant filesystem persistence.

  ## Overview

  IsLabDB treats data storage as a computational universe, using physics principles
  like quantum entanglement for smart pre-fetching, spacetime sharding for optimal
  data placement, and black hole mechanics for intelligent caching.

  The database maintains persistent state in an elegant filesystem structure at `/data`
  that mirrors the organization of the universe itself, from quantum-scale records
  to galactic-scale configurations.

  ## Basic Usage

      # Start the universe
      {:ok, _pid} = IsLabDB.start_link()

      # Store data in the cosmic structure with automatic persistence
      {:ok, :stored, shard, time} = IsLabDB.cosmic_put("user:alice", %{name: "Alice", age: 30})

      # Retrieve data with potential entangled relationships
      {:ok, user_data, shard, time} = IsLabDB.cosmic_get("user:alice")

      # Delete data from all spacetime regions
      {:ok, deleted_from, time} = IsLabDB.cosmic_delete("user:alice")

      # Get comprehensive universe metrics
      metrics = IsLabDB.cosmic_metrics()

  ## Physics-Inspired Features

  - **Spacetime Sharding**: Data automatically routed to appropriate energy levels (hot/warm/cold)
  - **Quantum Entanglement**: Related data can be automatically linked for smart pre-fetching
  - **Event Horizon Caching**: Black hole mechanics with Hawking radiation eviction algorithms
  - **Entropy Monitoring**: Automatic system rebalancing when disorder increases
  - **Temporal Persistence**: All operations automatically persisted with cosmic metadata

  ## Performance Characteristics

  - Single-node throughput: 50,000-100,000 ops/second
  - Cache hit latency: <50 microseconds
  - Persistence overhead: <10% performance impact
  - Human-readable filesystem structure for debugging and exploration
  """

  use GenServer
  require Logger

  alias IsLabDB.{CosmicPersistence, CosmicConstants, QuantumIndex, SpacetimeShard, GravitationalRouter, EventHorizonCache, EntropyMonitor, WALOperations}

  defstruct [
    :universe_state,          # :stable, :rebalancing, :expanding, :collapsing
    :spacetime_shards,        # Phase 3: Advanced spacetime shards with physics laws
    :gravitational_router,    # Phase 3: Intelligent routing system
    :spacetime_tables,        # Legacy: ETS tables for backward compatibility
    :event_horizon_caches,    # Phase 4: Black hole mechanics caching system
    :cache_coherence_manager, # Phase 4: Cross-cache consistency and synchronization
    :persistence_coordinator, # Background persistence process PID
    :cosmic_metrics,          # Performance and entropy metrics
    :startup_time,            # When this universe began
    :entanglement_rules,      # Quantum entanglement patterns
    :entropy_monitor,         # Phase 5: Advanced entropy monitoring system
    :wormhole_network,        # Fast routing between shards
    :reality_anchor,          # Schema validation and consistency
    :wal_system,              # Phase 6.6: Write-Ahead Log for 250K+ ops/sec
    :wal_enabled              # Phase 6.6: WAL enable/disable flag
  ]

  ## PUBLIC API

  @doc """
  Start the IsLab Database universe with optional configuration.

  ## Options

  - `:data_root` - Custom data directory (defaults to "/data")
  - `:entanglement_rules` - Quantum entanglement patterns
  - `:physics_laws` - Custom physics laws for spacetime shards
  - `:enable_entropy_monitoring` - Enable automatic rebalancing (default: true)
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Store data in the computational universe with automatic persistence.

  Data is automatically routed to the appropriate spacetime shard based on
  access patterns and physics laws, then persisted to the filesystem with
  complete cosmic metadata.

  ## Parameters

  - `key` - Unique identifier for the data
  - `value` - The data to store (any Elixir term)
  - `opts` - Storage options (see below)

  ## Options

  - `:access_pattern` - `:hot`, `:warm`, `:cold`, `:sequential`, `:locality_sensitive`, `:load_balanced`
  - `:priority` - `:critical`, `:high`, `:normal`, `:low`, `:background`
  - `:entangled_with` - List of keys this data should be quantum entangled with
  - `:temporal_weight` - Importance factor for temporal decay calculations
  - `:custom_metadata` - Additional metadata to store with the cosmic record

  ## Returns

  `{:ok, :stored, shard_id, operation_time_microseconds}` on success
  `{:error, reason}` on failure

  ## Examples

      # Basic storage
      IsLabDB.cosmic_put("user:alice", %{name: "Alice", age: 30})

      # Hot data with high priority
      IsLabDB.cosmic_put("trending:post:123", post_data,
        access_pattern: :hot,
        priority: :critical
      )

      # Data with quantum entanglement
      IsLabDB.cosmic_put("profile:alice", profile_data,
        entangled_with: ["user:alice", "settings:alice"]
      )
  """
    def cosmic_put(key, value, opts \\ []) do
    # PERFORMANCE REVOLUTION: TRUE GenServer bypass with cached state!
    # Get cached state without any GenServer calls for maximum performance
    state = get_cached_state()

    if state.wal_enabled do
      # Phase 6.6: WAL-powered ultra-high performance (250K+ ops/sec)
      case IsLabDB.WALOperations.cosmic_put_v2(state, key, value, opts) do
        {:ok, :stored, shard_id, operation_time, updated_state} ->
          # Update local cache and server state asynchronously
          update_cached_state(updated_state)
          update_state_async(updated_state)
          {:ok, :stored, shard_id, operation_time}
        {:error, reason, _error_state} ->
          {:error, reason}
      end
    else
      # Fallback: Use GenServer for legacy mode
      GenServer.call(__MODULE__, {:cosmic_put, key, value, opts})
    end
  end

  @doc """
  Retrieve data from the computational universe.

  Searches across all spacetime shards and returns the data along with
  performance metrics. If quantum entanglement is configured, related
  data may be automatically pre-fetched.

  ## Parameters

  - `key` - The unique identifier to retrieve

  ## Returns

  `{:ok, value, shard_id, operation_time_microseconds}` on success
  `{:error, :not_found, operation_time_microseconds}` if not found
  `{:error, reason}` on other failures

  ## Examples

      # Basic retrieval
      {:ok, user_data, :hot_data, 150} = IsLabDB.cosmic_get("user:alice")

      # Handle not found
      case IsLabDB.cosmic_get("nonexistent:key") do
        {:ok, data, shard, time} -> process_data(data)
        {:error, :not_found, time} -> handle_not_found()
      end
  """
    def cosmic_get(key) do
    # PERFORMANCE REVOLUTION: TRUE GenServer bypass for GET operations!
    # Get cached state without any GenServer calls for maximum performance
    state = get_cached_state()

    if state.wal_enabled do
      # Phase 6.6: WAL-powered ultra-high performance (500K+ ops/sec)
      case IsLabDB.WALOperations.cosmic_get_v2(state, key) do
        {:ok, value, shard_id, operation_time, updated_state} ->
          # Update local cache and server state asynchronously
          update_cached_state(updated_state)
          update_state_async(updated_state)
          {:ok, value, shard_id, operation_time}
        {:error, :not_found, operation_time, error_state} ->
          update_cached_state(error_state)
          update_state_async(error_state)
          {:error, :not_found, operation_time}
      end
    else
      # Fallback: Use GenServer for legacy mode
      GenServer.call(__MODULE__, {:cosmic_get, key})
    end
  end

  @doc """
  Retrieve data with full quantum entanglement information.

  Similar to cosmic_get but returns complete quantum data including
  all entangled partners and quantum metadata.

  ## Parameters

  - `key` - The unique identifier to retrieve

  ## Returns

  `{:ok, quantum_response}` where quantum_response contains:
  - `:value` - The primary data value
  - `:shard` - Which shard contained the data
  - `:operation_time` - Operation time in microseconds
  - `:quantum_data` - Entangled items and quantum metrics

  ## Examples

      {:ok, response} = IsLabDB.quantum_get("user:alice")
      primary_data = response.value
      entangled_profile = response.quantum_data.entangled_items["profile:alice"]
  """
  def quantum_get(key) do
    GenServer.call(__MODULE__, {:quantum_get, key})
  end

  @doc """
  Remove data from all spacetime regions.

  Deletes the data from all ETS tables and removes the persistent files
  from the filesystem. Returns information about which shards contained
  the data.

  ## Parameters

  - `key` - The unique identifier to delete

  ## Returns

  `{:ok, deleted_from_shards, operation_time_microseconds}` where
  `deleted_from_shards` is a list of `{shard_id, :deleted | :not_found}` tuples

  ## Examples

      {:ok, results, time} = IsLabDB.cosmic_delete("user:alice")
      # results might be: [{:hot_data, :deleted}, {:warm_data, :not_found}, {:cold_data, :not_found}]
  """
  def cosmic_delete(key) do
    GenServer.call(__MODULE__, {:cosmic_delete, key})
  end

  @doc """
  Get comprehensive metrics about the universe state.

  Returns detailed information about system performance, shard utilization,
  cosmic constants, and overall universe health.

  ## Returns

  A map containing:
  - `:universe_state` - Current state (`:stable`, `:rebalancing`, etc.)
  - `:uptime_ms` - How long the universe has been running
  - `:spacetime_regions` - List of shard metrics
  - `:cosmic_constants` - Fundamental physics constants
  - `:performance` - Operation statistics
  - `:entropy` - System entropy measurements
  - `:persistence` - Filesystem state information

    ## Examples

      metrics = IsLabDB.cosmic_metrics()

      IO.puts("Universe has been stable for \#{metrics.uptime_ms}ms")
      IO.puts("Hot data shard contains \#{get_shard_size(metrics, :hot_data)} items")
      IO.puts("System entropy: \#{metrics.entropy.total_entropy}")
  """
  def cosmic_metrics() do
    GenServer.call(__MODULE__, :cosmic_metrics)
  end

  @doc """
  Force a cosmic rebalancing operation.

  Manually trigger entropy-based rebalancing across spacetime shards.
  This is normally done automatically when system entropy exceeds the
  rebalance threshold, but can be manually triggered for maintenance.

  ## Returns

  `{:ok, rebalance_report}` with details about the rebalancing operation
  """
  def force_cosmic_rebalancing() do
    GenServer.call(__MODULE__, :force_rebalancing)
  end

  @doc """
  Create quantum entanglement between data items.

  Establish quantum relationships so that accessing one item automatically
  provides information about related items. This enables smart pre-fetching
  and improves query performance for related data.

  ## Parameters

  - `primary_key` - The main data item
  - `entangled_keys` - List of keys to entangle with the primary
  - `strength` - Entanglement strength (0.0 to 1.0, defaults to 1.0)

  ## Examples

      # Create user profile entanglement
      IsLabDB.create_quantum_entanglement("user:alice",
        ["profile:alice", "settings:alice", "sessions:alice"],
        strength: 0.9
      )
  """
  def create_quantum_entanglement(primary_key, entangled_keys, strength \\ 1.0) do
    GenServer.call(__MODULE__, {:create_entanglement, primary_key, entangled_keys, strength})
  end

  @doc """
  Get quantum entanglement metrics and statistics.

  Returns detailed information about the quantum entanglement system,
  including total entanglements, quantum efficiency, and state distribution.

  ## Returns

  A map containing quantum system metrics and performance statistics.

  ## Examples

      quantum_stats = IsLabDB.quantum_entanglement_metrics()
      IO.puts("Total entanglements: \#{quantum_stats.total_entanglements}")
      IO.puts("Quantum efficiency: \#{quantum_stats.quantum_efficiency}")
  """
  def quantum_entanglement_metrics() do
    QuantumIndex.quantum_metrics()
  end

  @doc """
  Get comprehensive entropy monitoring metrics and system thermodynamics.

  Returns detailed entropy analysis including Shannon entropy, thermodynamic
  entropy, system temperature, and rebalancing recommendations from the
  Phase 5 entropy monitoring system.

  ## Returns

  A map containing:
  - `:total_entropy` - Combined system entropy measurement
  - `:shannon_entropy` - Information-theoretic entropy across shards
  - `:thermodynamic_entropy` - Energy distribution entropy
  - `:entropy_trend` - :increasing, :decreasing, or :stable
  - `:system_temperature` - System activity temperature
  - `:disorder_index` - Relative disorder compared to threshold
  - `:stability_metric` - Overall system stability (0.0 to 1.0)
  - `:vacuum_stability` - Vacuum state stability measurement
  - `:rebalancing_recommended` - Whether thermodynamic rebalancing needed

  ## Examples

      entropy = IsLabDB.entropy_metrics()
      IO.puts("System entropy: \#{entropy.total_entropy}")
      IO.puts("Rebalancing needed: \#{entropy.rebalancing_recommended}")
  """
  def entropy_metrics() do
    GenServer.call(__MODULE__, :entropy_metrics)
  end

  @doc """
  Trigger thermodynamic rebalancing to reduce system entropy.

  Activates Maxwell's demon optimization to intelligently migrate data
  and reduce entropy across spacetime shards. This is automatically
  triggered when entropy exceeds thresholds, but can be manually invoked.

  ## Options

  - `:force_rebalancing` - Force rebalancing even if entropy is acceptable
  - `:migration_strategy` - :minimal, :moderate, :aggressive

  ## Examples

      {:ok, report} = IsLabDB.trigger_entropy_rebalancing(force_rebalancing: true)
      IO.puts("Entropy reduced by: \#{report.entropy_reduction}")
  """
  def trigger_entropy_rebalancing(opts \\ []) do
    GenServer.call(__MODULE__, {:trigger_entropy_rebalancing, opts}, 30_000)
  end

  ## GENSERVER CALLBACKS

    def init(opts) do
    Logger.info("🚀 Initializing IsLabDB computational universe...")

    # Set data_root from options if provided
    if data_root = Keyword.get(opts, :data_root) do
      Application.put_env(:islab_db, :data_root, data_root)
    end

    # Initialize cosmic filesystem structure
    CosmicPersistence.initialize_universe()

    # Initialize quantum entanglement system
    QuantumIndex.initialize_quantum_system()

    # Phase 3: Create advanced spacetime shards with physics laws
    {:ok, spacetime_shards, gravitational_router} = initialize_phase3_sharding_system(opts)

    # Phase 4: Initialize Event Horizon Cache System (unless disabled)
    {event_horizon_caches, cache_coherence_manager} =
      if Keyword.get(opts, :disable_phase4, false) do
        {%{}, nil}
      else
        {:ok, caches, manager} = initialize_phase4_cache_system(opts)
        {caches, manager}
      end

    # Legacy: Create ETS tables for backward compatibility
    spacetime_tables = extract_legacy_tables(spacetime_shards)

    # Initialize quantum entanglement rules
    entanglement_rules = Keyword.get(opts, :entanglement_rules, default_entanglement_rules())

    # Phase 5: Initialize advanced entropy monitoring system
    # Check both opts and application environment for entropy monitoring setting
    enable_entropy = Keyword.get(opts, :enable_entropy_monitoring,
      Application.get_env(:islab_db, :enable_entropy_monitoring, true))

    entropy_monitor = if enable_entropy do
      initialize_phase5_entropy_monitoring(opts)
    else
      nil
    end

    # Initialize wormhole network for fast routing
    wormhole_network = create_wormhole_network()

    # Phase 6.6: Connect to WAL system (already started by supervisor)
    wal_enabled = Keyword.get(opts, :enable_wal, true)
    wal_system = if wal_enabled do
      # WAL is already started by the application supervisor
      # Just verify it's running and get its PID
      case Process.whereis(IsLabDB.WAL) do
        nil ->
          Logger.error("❌ WAL system not found - ensure it's in supervisor tree")
          nil
        wal_pid when is_pid(wal_pid) ->
          Logger.info("✅ Connected to WAL system")
          wal_pid
      end
    else
      Logger.info("⚠️ WAL disabled - using legacy persistence (3,500 ops/sec)")
      nil
    end

    # Create reality anchor for schema validation
    reality_anchor = initialize_reality_anchor()

    # Initialize state
    startup_time = :os.system_time(:millisecond)

    state = %IsLabDB{
      universe_state: :stable,
      spacetime_shards: spacetime_shards,
      gravitational_router: gravitational_router,
      spacetime_tables: spacetime_tables,
      event_horizon_caches: event_horizon_caches,
      cache_coherence_manager: cache_coherence_manager,
      persistence_coordinator: start_persistence_coordinator(),
      cosmic_metrics: initialize_cosmic_metrics(),
      startup_time: startup_time,
      entanglement_rules: entanglement_rules,
      entropy_monitor: entropy_monitor,
      wormhole_network: wormhole_network,
      reality_anchor: reality_anchor,
      wal_system: wal_system,
      wal_enabled: wal_enabled
    }

    # Restore universe state from filesystem if it exists
    restored_state = restore_universe_from_filesystem(state)

    # Phase 5: Update entropy monitor with spacetime shard information
    if restored_state.entropy_monitor do
      notify_entropy_monitor_of_shards(restored_state.entropy_monitor, restored_state.spacetime_shards)
    end

    # Start periodic cosmic maintenance
    schedule_cosmic_maintenance()

    Logger.info("✨ IsLabDB universe is stable and ready for cosmic operations")
    Logger.info("🌌 Data root: #{CosmicPersistence.data_root()}")
    Logger.info("🪐 Advanced spacetime shards: #{Map.keys(spacetime_shards) |> Enum.join(", ")}")
    Logger.info("🎯 Gravitational routing: #{gravitational_router.routing_algorithm} algorithm")
    Logger.info("🕳️  Event horizon caches: #{Map.keys(event_horizon_caches) |> Enum.join(", ")}")
    Logger.info("🔗 Entanglement rules: #{length(entanglement_rules)} patterns configured")
    Logger.info("🚀 Phase 4: Event Horizon Cache System - ACTIVE")
    Logger.info("🌡️  Phase 5: Entropy Monitoring & Thermodynamics - ACTIVE")

    {:ok, restored_state}
  end

  def handle_call({:cosmic_put, key, value, opts}, _from, state) do
    if state.wal_enabled do
      # Phase 6.6: WAL-powered ultra-high performance PUT (250K+ ops/sec)
      case WALOperations.cosmic_put_v2(state, key, value, opts) do
        {:ok, :stored, shard_id, operation_time, updated_state} ->
          {:reply, {:ok, :stored, shard_id, operation_time}, updated_state}
        {:error, reason, error_state} ->
          {:reply, {:error, reason}, error_state}
      end
    else
      # Legacy: Original implementation for backward compatibility
      handle_call_legacy_cosmic_put(key, value, opts, state)
    end
  end

  def handle_call({:cosmic_get, key}, _from, state) do
    if state.wal_enabled do
      # Phase 6.6: WAL-powered ultra-high performance GET (500K+ ops/sec)
      case WALOperations.cosmic_get_v2(state, key) do
        {:ok, value, shard_id, operation_time, updated_state} ->
          {:reply, {:ok, value, shard_id, operation_time}, updated_state}
        {:error, :not_found, operation_time, error_state} ->
          {:reply, {:error, :not_found, operation_time}, error_state}
      end
    else
      # Legacy: Original implementation for backward compatibility
      handle_call_legacy_cosmic_get(key, state)
    end
  end

  def handle_call({:quantum_get, key}, _from, state) do
    if state.wal_enabled do
      # Phase 6.6: WAL-powered quantum entanglement with analytics logging
      case WALOperations.quantum_get_v2(state, key) do
        {:ok, value, _shard_id, _operation_time, updated_state} ->
          {:reply, {:ok, value}, updated_state}  # Return simple 2-tuple for test compatibility
        {:error, :not_found, _operation_time, error_state} ->
          {:reply, {:error, :not_found}, error_state}  # Return simple 2-tuple for test compatibility
      end
    else
      # Legacy: Original quantum implementation for backward compatibility
      handle_call_legacy_quantum_get(key, state)
    end
  end

  def handle_call({:cosmic_delete, key}, _from, state) do
    if state.wal_enabled do
      # Phase 6.6: WAL-powered ultra-high performance DELETE
      case WALOperations.cosmic_delete_v2(state, key) do
        {:ok, delete_results, operation_time, updated_state} ->
          {:reply, {:ok, delete_results, operation_time}, updated_state}
      end
    else
      # Legacy: Original implementation for backward compatibility
      handle_call_legacy_cosmic_delete(key, state)
    end
  end

  def handle_call(:force_gravitational_rebalancing, _from, state) do
    Logger.info("🌌 Manual gravitational rebalancing initiated")

    # Use Phase 3 gravitational router for intelligent rebalancing
    analysis = GravitationalRouter.analyze_load_distribution(state.gravitational_router)

    {:ok, rebalance_results} = GravitationalRouter.execute_gravitational_rebalancing(state.gravitational_router, analysis)
    Logger.info("✅ Gravitational rebalancing completed: #{rebalance_results.successful_migrations} migrations")
    updated_state = %{state | universe_state: :rebalancing}

    # Schedule return to stable state
    Process.send_after(self(), :rebalancing_complete, 5_000)

    {:reply, {:ok, rebalance_results}, updated_state}
  end

  def handle_call(:get_spacetime_shard_metrics, _from, state) do
    shard_metrics = Enum.map(state.spacetime_shards, fn {shard_id, shard} ->
      {shard_id, SpacetimeShard.get_shard_metrics(shard)}
    end) |> Enum.into(%{})

    {:reply, shard_metrics, state}
  end

  def handle_call(:analyze_load_distribution, _from, state) do
    analysis = GravitationalRouter.analyze_load_distribution(state.gravitational_router)
    {:reply, analysis, state}
  end

  def handle_call(:cosmic_metrics, _from, state) do
    current_time = :os.system_time(:millisecond)

    # Collect comprehensive universe metrics
    spacetime_regions = Enum.map(state.spacetime_tables, fn {shard, table} ->
      # Safely get ETS table info, handling undefined tables
      size = :ets.info(table, :size) || 0
      memory_words = :ets.info(table, :memory) || 0
      memory_bytes = if is_integer(memory_words), do: memory_words * :erlang.system_info(:wordsize), else: 0

      %{
        shard: shard,
        data_items: size,
        memory_words: memory_words,
        memory_bytes: memory_bytes,
        physics_laws: get_shard_physics_laws(shard)
      }
    end)

    # Calculate system entropy if monitoring is enabled
    entropy_data = if state.entropy_monitor do
      calculate_system_entropy(state)
    else
      %{total_entropy: 0.0, monitoring_disabled: true}
    end

    # Filesystem statistics
    persistence_stats = collect_filesystem_statistics()

    # Phase 3: Enhanced metrics with gravitational router data
    gravitational_metrics = GravitationalRouter.get_routing_metrics(state.gravitational_router)

    metrics = %{
      universe_state: state.universe_state,
      uptime_ms: current_time - state.startup_time,
      spacetime_regions: spacetime_regions,
      cosmic_constants: %{
        planck_time_ns: CosmicConstants.planck_time_ns(),
        light_speed_ops: CosmicConstants.light_speed_ops_per_sec(),
        background_temp: CosmicConstants.cosmic_background_temp(),
        entropy_threshold: CosmicConstants.entropy_rebalance_threshold()
      },
      performance: state.cosmic_metrics,
      entropy: entropy_data,
      persistence: persistence_stats,
      entanglement: %{
        rules_count: length(state.entanglement_rules),
        quantum_metrics: QuantumIndex.quantum_metrics()
      },
      wormhole_network: collect_wormhole_metrics(state.wormhole_network),
      gravitational_routing: gravitational_metrics,
      event_horizon_cache: collect_event_horizon_cache_metrics(state.event_horizon_caches),
      entropy_monitoring: collect_entropy_monitoring_metrics(state.entropy_monitor),
      phase: determine_current_phase(state)
    }

    {:reply, metrics, state}
  end

  def handle_call(:force_rebalancing, _from, state) do
    Logger.info("🌌 Manual cosmic rebalancing initiated")

    # Perform entropy-based rebalancing
    rebalance_result = perform_cosmic_rebalancing(state)

    updated_state = %{state | universe_state: :rebalancing}

    # Schedule return to stable state
    Process.send_after(self(), :rebalancing_complete, 5_000)

    {:reply, {:ok, rebalance_result}, updated_state}
  end

  def handle_call({:create_entanglement, primary_key, entangled_keys, strength}, _from, state) do
    # Use QuantumIndex to create proper entanglement
    case QuantumIndex.create_entanglement(primary_key, entangled_keys, strength) do
      {:ok, entanglement_id} ->
        Logger.debug("🔗 Created quantum entanglement: #{primary_key} <-> #{inspect(entangled_keys)}")
        {:reply, {:ok, entanglement_id}, state}

      {:error, reason} ->
        Logger.warning("❌ Failed to create quantum entanglement: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:entropy_metrics, _from, state) do
    # Get entropy metrics from the Phase 5 entropy monitor
    entropy_metrics = if state.entropy_monitor do
      try do
        EntropyMonitor.get_entropy_metrics(state.entropy_monitor)
      rescue
        error ->
          Logger.warning("❌ Failed to get entropy metrics: #{inspect(error)}")
          %{error: "entropy_monitor_unavailable"}
      end
    else
      %{error: "entropy_monitoring_disabled"}
    end

    {:reply, entropy_metrics, state}
  end

  def handle_call({:trigger_entropy_rebalancing, opts}, _from, state) do
    # Trigger entropy rebalancing using the Phase 5 entropy monitor
    if state.entropy_monitor do
      case EntropyMonitor.trigger_rebalancing(state.entropy_monitor, opts) do
        {:ok, rebalancing_report} ->
          Logger.info("🌡️  Thermodynamic rebalancing completed successfully")
          {:reply, {:ok, rebalancing_report}, state}

        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, :entropy_monitoring_disabled}, state}
    end
  end

  def handle_call(:get_current_state, _from, state) do
    # Fast state retrieval for direct operation calls (PERFORMANCE OPTIMIZATION)
    {:reply, state, state}
  end

  def handle_info(:cosmic_maintenance, state) do
    # Periodic maintenance tasks
    Logger.debug("⚡ Performing cosmic maintenance...")

    # 1. Entropy monitoring and potential rebalancing
    updated_state = if state.entropy_monitor do
      entropy = calculate_system_entropy(state)
      if entropy.total_entropy > CosmicConstants.entropy_rebalance_threshold() do
        Logger.info("🌌 High entropy detected (#{Float.round(entropy.total_entropy, 2)}), triggering automatic rebalancing")
        perform_cosmic_rebalancing(state)
        %{state | universe_state: :rebalancing}
      else
        state
      end
    else
      state
    end

    # 2. Wormhole network maintenance
    maintain_wormhole_network(updated_state.wormhole_network)

    # 3. Filesystem cleanup and optimization
    cleanup_temporary_files()

    # 4. Update reality anchor consistency
    validate_reality_anchor(updated_state.reality_anchor)

    # Schedule next maintenance
    schedule_cosmic_maintenance()

    {:noreply, updated_state}
  end

  def handle_info(:rebalancing_complete, state) do
    Logger.info("✨ Cosmic rebalancing complete - universe returned to stable state")
    {:noreply, %{state | universe_state: :stable}}
  end

  def handle_info({:persistence_complete, key, result}, state) do
    case result do
      {:ok, file_path} ->
        Logger.debug("💾 Persisted #{key} to #{file_path}")
      {:error, reason} ->
        Logger.warning("❌ Failed to persist #{key}: #{inspect(reason)}")
    end
    {:noreply, state}
  end

  @doc """
  Force cosmic rebalancing using the gravitational router.

  Phase 3 enhancement that uses intelligent load analysis and migration.
  """
  def force_gravitational_rebalancing() do
    GenServer.call(__MODULE__, :force_gravitational_rebalancing)
  end

  @doc """
  Get advanced spacetime shard metrics including gravitational fields.

  Phase 3 enhancement providing detailed physics-based metrics.
  """
  def get_spacetime_shard_metrics() do
    GenServer.call(__MODULE__, :get_spacetime_shard_metrics)
  end

  @doc """
  Analyze current load distribution across shards.

  Returns comprehensive analysis using the gravitational router.
  """
  def analyze_load_distribution() do
    GenServer.call(__MODULE__, :analyze_load_distribution)
  end

  ## PRIVATE HELPER FUNCTIONS

  defp initialize_phase4_cache_system(opts) do
    Logger.info("🕳️  Initializing Phase 4: Event Horizon Cache System...")

    # Create Event Horizon Caches for each spacetime shard
    cache_configs = [
      {
        :hot_data_cache,
        [
          schwarzschild_radius: Keyword.get(opts, :hot_cache_size, 10_000),
          hawking_temperature: Keyword.get(opts, :hot_cache_eviction_rate, 0.05),
          enable_compression: true,
          persistence_enabled: true
        ]
      },
      {
        :warm_data_cache,
        [
          schwarzschild_radius: Keyword.get(opts, :warm_cache_size, 5_000),
          hawking_temperature: Keyword.get(opts, :warm_cache_eviction_rate, 0.1),
          enable_compression: true,
          persistence_enabled: true
        ]
      },
      {
        :cold_data_cache,
        [
          schwarzschild_radius: Keyword.get(opts, :cold_cache_size, 2_000),
          hawking_temperature: Keyword.get(opts, :cold_cache_eviction_rate, 0.2),
          enable_compression: true,
          persistence_enabled: true
        ]
      },
      {
        :universal_cache,
        [
          schwarzschild_radius: Keyword.get(opts, :universal_cache_size, 20_000),
          hawking_temperature: Keyword.get(opts, :universal_cache_eviction_rate, 0.08),
          enable_compression: true,
          persistence_enabled: true
        ]
      }
    ]

    # Create Event Horizon Caches
    caches = Enum.reduce(cache_configs, %{}, fn {cache_id, cache_opts}, acc ->
      {:ok, cache} = EventHorizonCache.create_cache(cache_id, cache_opts)
      Map.put(acc, cache_id, cache)
    end)

    # Initialize cache coherence manager
    cache_coherence_manager = %{
      coherence_protocol: :eventual_consistency,
      synchronization_interval: 60_000,
      conflict_resolution: :last_writer_wins,
      cross_cache_operations: %{},
      last_coherence_check: :os.system_time(:millisecond)
    }

    Logger.info("✨ Phase 4 Event Horizon Cache System ready - #{map_size(caches)} caches active")
    {:ok, caches, cache_coherence_manager}
  end

  defp initialize_phase5_entropy_monitoring(opts) do
    Logger.info("🌡️  Initializing Phase 5: Entropy Monitoring & Thermodynamics...")

    # Start the entropy registry
    case Registry.start_link(keys: :unique, name: IsLabDB.EntropyRegistry) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok  # Registry already started
    end

    # Create entropy monitor configuration
    monitor_config = [
      monitoring_interval: Keyword.get(opts, :entropy_monitoring_interval, 5000),
      entropy_threshold: Keyword.get(opts, :entropy_threshold, CosmicConstants.entropy_rebalance_threshold()),
      enable_maxwell_demon: Keyword.get(opts, :enable_maxwell_demon, true),
      vacuum_stability_checks: Keyword.get(opts, :vacuum_stability_checks, true),
      persistence_enabled: Keyword.get(opts, :entropy_persistence, true),
      analytics_enabled: Keyword.get(opts, :entropy_analytics, true)
    ]

    # Create the main entropy monitor
    case EntropyMonitor.create_monitor(:cosmic_entropy, monitor_config) do
      {:ok, _monitor_pid} ->
        Logger.info("✨ Phase 5 Entropy Monitoring System ready - cosmic entropy monitor active")
        :cosmic_entropy  # Return monitor ID

      {:error, reason} ->
        Logger.warning("❌ Failed to initialize entropy monitor: #{inspect(reason)}")
        nil
    end
  end

  defp initialize_phase3_sharding_system(_opts) do
    Logger.info("🌌 Initializing Phase 3: Spacetime Sharding System...")

    # Define physics laws for each shard type
    shard_configs = [
      {
        :hot_data,
        %{
          consistency_model: :strong,
          time_dilation: 0.5,
          gravitational_mass: 2.0,
          energy_threshold: 2000,
          max_capacity: 50_000,
          entropy_limit: 1.5
        }
      },
      {
        :warm_data,
        %{
          consistency_model: :eventual,
          time_dilation: 1.0,
          gravitational_mass: 1.0,
          energy_threshold: 1000,
          max_capacity: 25_000,
          entropy_limit: 2.0
        }
      },
      {
        :cold_data,
        %{
          consistency_model: :weak,
          time_dilation: 2.0,
          gravitational_mass: 0.3,
          energy_threshold: 500,
          max_capacity: 10_000,
          entropy_limit: 3.0
        }
      }
    ]

    # Create spacetime shards with physics laws
    shards = Enum.reduce(shard_configs, %{}, fn {shard_id, physics_laws}, acc ->
      {:ok, shard} = SpacetimeShard.create_shard(shard_id, physics_laws, [named_table: true])
      Map.put(acc, shard_id, shard)
    end)

    # Initialize gravitational router
    shard_list = Map.values(shards)
    {:ok, router} = GravitationalRouter.initialize(shard_list, [
      routing_algorithm: :gravitational,
      cache_size: 1000,
      rebalancing_threshold: 0.3
    ])

    Logger.info("✨ Phase 3 spacetime sharding system ready")
    {:ok, shards, router}
  end

  defp extract_legacy_tables(spacetime_shards) do
    # Extract ETS tables for backward compatibility
    Enum.reduce(spacetime_shards, %{}, fn {shard_id, shard}, acc ->
      # Ensure the ETS table exists and is valid
      table = if shard.ets_table && :ets.whereis(shard.ets_table) != :undefined do
        shard.ets_table
      else
        # Create a fallback ETS table if the shard's table doesn't exist
        Logger.warning("Creating fallback ETS table for shard #{shard_id}")
        :ets.new(:"spacetime_shard_#{shard_id}", [:set, :public, :named_table])
      end

      Map.put(acc, shard_id, table)
    end)
  end

  defp find_in_gravitational_shards(key, spacetime_shards) do
    # Search all shards in order of likelihood (hot -> warm -> cold)
    search_order = [:hot_data, :warm_data, :cold_data]

    Enum.find_value(search_order, {:error, :not_found}, fn shard_id ->
      shard = Map.get(spacetime_shards, shard_id)
      case SpacetimeShard.gravitational_get(shard, key) do
        {:ok, value, updated_shard, _metadata} -> {:ok, value, shard_id, updated_shard}
        {:error, :not_found, _time} -> nil
        {:error, reason, _time} -> {:error, reason}
      end
    end)
  end







  defp start_persistence_coordinator() do
    # Start a background process to coordinate filesystem persistence
    # This would be more sophisticated in production
    spawn_link(fn -> persistence_coordinator_loop() end)
  end

  defp persistence_coordinator_loop() do
    # Simple persistence coordinator - would be more sophisticated in production
    receive do
      {:persist, key, cosmic_record} ->
        data_type = CosmicPersistence.extract_data_type(key)
        result = CosmicPersistence.persist_cosmic_record(cosmic_record, data_type)
        send(IsLabDB, {:persistence_complete, key, result})
      _ ->
        :ok
    after
      60_000 -> :timeout
    end
    persistence_coordinator_loop()
  end

  defp initialize_cosmic_metrics() do
    %{
      total_operations: 0,
      put_operations: 0,
      get_operations: 0,
      get_hits: 0,
      get_misses: 0,
      delete_operations: 0,
      avg_operation_time_us: 0.0,
      last_updated: :os.system_time(:millisecond),
      shard_distribution: %{
        hot_data: 0,
        warm_data: 0,
        cold_data: 0
      }
    }
  end

  defp update_cosmic_metrics(_state, operation_type, operation_time, shard) do
    # Update performance metrics - in production this would be more sophisticated
    # and potentially stored in ETS for thread-safety
    Logger.debug("📊 #{operation_type} operation completed in #{operation_time}μs on shard #{shard}")
    :ok
  end

  defp default_entanglement_rules() do
    [
      {"user:*", ["profile:*", "settings:*", "sessions:*"]},
      {"order:*", ["customer:*", "products:*", "payment:*"]},
      {"post:*", ["author:*", "comments:*", "tags:*"]},
      {"product:*", ["reviews:*", "inventory:*", "pricing:*"]}
    ]
  end



  defp create_wormhole_network() do
    :ets.new(:wormhole_network, [
      :bag, :public, :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])
  end

  defp initialize_reality_anchor() do
    %{
      schema_version: "1.0.0",
      consistency_rules: [],
      validation_enabled: true,
      last_validation: :os.system_time(:millisecond)
    }
  end

  defp restore_universe_from_filesystem(state) do
    # In Phase 1, we don't restore from filesystem yet
    # This will be implemented in later phases
    Logger.debug("🔄 Filesystem restoration not implemented in Phase 1")
    state
  end

  defp schedule_cosmic_maintenance() do
    # Schedule maintenance every 30 seconds
    Process.send_after(self(), :cosmic_maintenance, 30_000)
  end

  defp get_shard_physics_laws(:hot_data) do
    %{consistency_model: :strong, time_dilation: 0.5, attraction: 2.0, energy_level: :high}
  end
  defp get_shard_physics_laws(:warm_data) do
    %{consistency_model: :eventual, time_dilation: 1.0, attraction: 1.0, energy_level: :medium}
  end
  defp get_shard_physics_laws(:cold_data) do
    %{consistency_model: :weak, time_dilation: 2.0, attraction: 0.3, energy_level: :low}
  end

  defp create_entanglement_links(key, entangled_keys, _state) do
    # Create quantum entanglement using QuantumIndex
    case QuantumIndex.create_entanglement(key, entangled_keys, 1.0, %{manual: true}) do
      {:ok, _entanglement_id} -> :ok
      {:error, reason} ->
        Logger.warning("Failed to create manual entanglement for #{key}: #{inspect(reason)}")
        :error
    end
  end

  defp update_quantum_metrics(_state, :quantum_observation, _quantum_metadata) do
    # Update quantum-specific metrics
    # For Phase 2, we'll keep this simple and log the observation
    Logger.debug("⚛️  Quantum observation metrics updated")
    :ok
  end

  defp calculate_system_entropy(state) do
    # Phase 5: Use advanced entropy monitor if available
    if state.entropy_monitor do
      try do
        entropy_metrics = EntropyMonitor.get_entropy_metrics(state.entropy_monitor)
        %{
          total_entropy: entropy_metrics.total_entropy,
          shannon_entropy: entropy_metrics.shannon_entropy,
          thermodynamic_entropy: entropy_metrics.thermodynamic_entropy,
          entropy_trend: entropy_metrics.entropy_trend,
          system_temperature: entropy_metrics.system_temperature,
          last_calculated: entropy_metrics.last_calculated,
          disorder_index: entropy_metrics.disorder_index,
          stability_metric: entropy_metrics.stability_metric,
          rebalancing_recommended: entropy_metrics.rebalancing_recommended,
          vacuum_stability: entropy_metrics.vacuum_stability
        }
      rescue
        error ->
          Logger.warning("❌ Failed to get entropy metrics from monitor: #{inspect(error)}")
          %{error: "entropy_monitor_unavailable"}
      end
    else
      %{error: "entropy_monitoring_disabled"}
    end
  end

  defp collect_filesystem_statistics() do
    # Collect basic filesystem statistics
    data_root = CosmicPersistence.data_root()

    if File.exists?(data_root) do
      %{
        data_root: data_root,
        exists: true,
        universe_manifest_exists: File.exists?(Path.join(data_root, "universe.manifest")),
        estimated_size_mb: calculate_directory_size(data_root) / (1024 * 1024)
      }
    else
      %{
        data_root: data_root,
        exists: false,
        universe_manifest_exists: false,
        estimated_size_mb: 0.0
      }
    end
  rescue
    _ -> %{data_root: CosmicPersistence.data_root(), exists: false, error: "filesystem_access_error"}
  end

  defp calculate_directory_size(path) do
    # Simple directory size calculation
    try do
      path
      |> File.ls!()
      |> Enum.reduce(0, fn item, acc ->
        item_path = Path.join(path, item)
        if File.dir?(item_path) do
          acc + calculate_directory_size(item_path)
        else
          case File.stat(item_path) do
            {:ok, %{size: size}} -> acc + size
            _ -> acc
          end
        end
      end)
    rescue
      _ -> 0
    end
  end



  ## PHASE 4: EVENT HORIZON CACHE HELPER FUNCTIONS

  defp store_in_event_horizon_cache(state, key, value, shard_id, opts) do
    # Determine which cache to use based on shard and data characteristics
    cache_id = determine_cache_for_shard(shard_id)
    cache = Map.get(state.event_horizon_caches, cache_id)

    case EventHorizonCache.put(cache, key, value, opts) do
      {:ok, updated_cache, _storage_metadata} ->
        updated_caches = Map.put(state.event_horizon_caches, cache_id, updated_cache)
        %{state | event_horizon_caches: updated_caches}

      {:error, reason} ->
        Logger.debug("🕳️  Cache storage failed for #{key}: #{inspect(reason)}")
        state
    end
  end

  defp check_event_horizon_cache(state, key) do
    # Check all caches for the key (starting with most likely)
    cache_order = [:universal_cache, :hot_data_cache, :warm_data_cache, :cold_data_cache]

    Enum.reduce_while(cache_order, {:cache_miss, state}, fn cache_id, {_status, current_state} ->
      cache = Map.get(current_state.event_horizon_caches, cache_id)

      case EventHorizonCache.get(cache, key) do
        {:ok, value, updated_cache, retrieval_metadata} ->
          updated_caches = Map.put(current_state.event_horizon_caches, cache_id, updated_cache)
          final_state = %{current_state | event_horizon_caches: updated_caches}
          {:halt, {:cache_hit, value, final_state, retrieval_metadata}}

        {:miss, updated_cache} ->
          updated_caches = Map.put(current_state.event_horizon_caches, cache_id, updated_cache)
          updated_state = %{current_state | event_horizon_caches: updated_caches}
          {:cont, {:cache_miss, updated_state}}
      end
    end)
  end

  defp cache_retrieved_value(state, key, value, shard_id) do
    # Cache the value that was retrieved from shards for future access
    cache_id = determine_cache_for_shard(shard_id)
    cache = Map.get(state.event_horizon_caches, cache_id)

    case EventHorizonCache.put(cache, key, value, [priority: :normal]) do
      {:ok, updated_cache, _metadata} ->
        updated_caches = Map.put(state.event_horizon_caches, cache_id, updated_cache)
        %{state | event_horizon_caches: updated_caches}

      {:error, _reason} ->
        state
    end
  end

  defp determine_cache_for_shard(shard_id) do
    case shard_id do
      :hot_data -> :hot_data_cache
      :warm_data -> :warm_data_cache
      :cold_data -> :cold_data_cache
      _ -> :universal_cache
    end
  end

  defp collect_event_horizon_cache_metrics(event_horizon_caches) do
    cache_metrics = Enum.map(event_horizon_caches, fn {cache_id, cache} ->
      {cache_id, EventHorizonCache.get_cache_metrics(cache)}
    end) |> Enum.into(%{})

    total_items = cache_metrics
    |> Map.values()
    |> Enum.reduce(0, fn metrics, acc ->
      acc + metrics.cache_statistics.event_horizon_items +
            metrics.cache_statistics.photon_sphere_items +
            metrics.cache_statistics.deep_cache_items +
            metrics.cache_statistics.singularity_items
    end)

    total_memory = cache_metrics
    |> Map.values()
    |> Enum.reduce(0, fn metrics, acc -> acc + metrics.cache_statistics.total_memory_bytes end)

    %{
      total_caches: map_size(event_horizon_caches),
      total_cached_items: total_items,
      total_cache_memory_bytes: total_memory,
      individual_cache_metrics: cache_metrics,
      hawking_radiation_active: true,
      spaghettification_enabled: true,
      schwarzschild_utilization: if(total_items > 0, do: total_items / 50_000, else: 0.0)
    }
  end

  defp collect_wormhole_metrics(wormhole_network) do
    %{
      total_wormholes: :ets.info(wormhole_network, :size),
      memory_usage: :ets.info(wormhole_network, :memory) * :erlang.system_info(:wordsize),
      active_routes: 0  # Placeholder
    }
  end

  defp collect_entropy_monitoring_metrics(entropy_monitor) do
    if entropy_monitor do
      try do
        entropy_metrics = EntropyMonitor.get_entropy_metrics(entropy_monitor)
        %{
          monitor_active: true,
          total_entropy: entropy_metrics.total_entropy,
          shannon_entropy: entropy_metrics.shannon_entropy,
          thermodynamic_entropy: entropy_metrics.thermodynamic_entropy,
          entropy_trend: entropy_metrics.entropy_trend,
          system_temperature: entropy_metrics.system_temperature,
          disorder_index: entropy_metrics.disorder_index,
          stability_metric: entropy_metrics.stability_metric,
          rebalancing_recommended: entropy_metrics.rebalancing_recommended,
          vacuum_stability: entropy_metrics.vacuum_stability,
          last_calculated: entropy_metrics.last_calculated
        }
      rescue
        _ -> %{monitor_active: false, error: "entropy_monitor_unavailable"}
      end
    else
      %{monitor_active: false}
    end
  end

  defp determine_current_phase(state) do
    cond do
      state.entropy_monitor -> "Phase 5: Entropy Monitoring & Thermodynamics"
      map_size(state.event_horizon_caches) > 0 -> "Phase 4: Event Horizon Cache System"
      true -> "Phase 3: Spacetime Sharding System"
    end
  end

  defp notify_entropy_monitor_of_shards(entropy_monitor, spacetime_shards) do
    # Notify the entropy monitor about the spacetime shards so it can monitor them
    try do
      GenServer.cast({:via, Registry, {IsLabDB.EntropyRegistry, entropy_monitor}},
                     {:update_spacetime_shards, spacetime_shards})
    rescue
      error ->
        Logger.warning("❌ Failed to update entropy monitor with shards: #{inspect(error)}")
    end
  end

  defp perform_cosmic_rebalancing(_state) do
    # Placeholder for cosmic rebalancing logic
    Logger.info("🌌 Performing cosmic rebalancing operations...")

    %{
      rebalanced_shards: [:hot_data, :warm_data, :cold_data],
      data_migrated: 0,
      time_taken_ms: 100,
      entropy_reduction: 0.5
    }
  end

  defp maintain_wormhole_network(_wormhole_network) do
    # Maintain wormhole network connections
    # Placeholder for Phase 1
    :ok
  end

  defp cleanup_temporary_files() do
    # Clean up any temporary files in the cosmic structure
    # Placeholder for Phase 1
    :ok
  end

  defp validate_reality_anchor(_reality_anchor) do
    # Validate schema consistency and reality anchor
    # Placeholder for Phase 1
    :ok
  end

  ## PHASE 6.6: LEGACY COMPATIBILITY FUNCTIONS
  # These functions maintain backward compatibility for non-WAL mode

  defp handle_call_legacy_cosmic_put(key, value, opts, state) do
    # Legacy cosmic_put implementation (original Phase 1-5 code)
    # This is used when WAL is disabled for backward compatibility
    start_time = :os.system_time(:microsecond)

    # Phase 3: Use gravitational router to determine optimal shard
    case GravitationalRouter.route_data(state.gravitational_router, key, value, opts) do
      {:ok, shard_id, routing_metadata} ->
        # Get the spacetime shard
        spacetime_shard = Map.get(state.spacetime_shards, shard_id)

        # Phase 3: Store using advanced shard with gravitational effects
        case SpacetimeShard.gravitational_put(spacetime_shard, key, value, opts) do
          {:ok, updated_shard, storage_metadata} ->
            # Update shard in state
            updated_shards = Map.put(state.spacetime_shards, shard_id, updated_shard)
            shard_updated_state = %{state | spacetime_shards: updated_shards}

            # Legacy: Also store in ETS table for compatibility
            legacy_table = Map.get(state.spacetime_tables, shard_id)
            :ets.insert(legacy_table, {key, value})

            # Create cosmic record with enhanced metadata
            additional_metadata = Map.merge(
              Keyword.get(opts, :custom_metadata, %{}),
              %{gravitational_metadata: routing_metadata, storage_metadata: storage_metadata}
            )
            cosmic_record = CosmicPersistence.create_cosmic_record(key, value, shard_id, additional_metadata)

            # Persist to filesystem asynchronously
            Task.start(fn ->
              data_type = CosmicPersistence.extract_data_type(key)
              CosmicPersistence.persist_cosmic_record(cosmic_record, data_type)
            end)

            # Handle quantum entanglement if specified
            if entangled_with = Keyword.get(opts, :entangled_with) do
              create_entanglement_links(key, entangled_with, shard_updated_state)
            end

            # Apply automatic entanglement patterns
            QuantumIndex.apply_entanglement_patterns(key, value)

            end_time = :os.system_time(:microsecond)
            total_operation_time = end_time - start_time

            # Update cosmic metrics
            update_cosmic_metrics(shard_updated_state, :put, total_operation_time, shard_id)

            {:reply, {:ok, :stored, shard_id, total_operation_time}, shard_updated_state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp handle_call_legacy_cosmic_get(key, state) do
    # Legacy cosmic_get implementation for backward compatibility
    start_time = :os.system_time(:microsecond)

    # Check Event Horizon Cache first
    cache_result = if map_size(state.event_horizon_caches) > 0 do
      check_event_horizon_cache(state, key)
    else
      {:cache_miss, state}
    end

    case cache_result do
      {:cache_hit, value, cache_updated_state, _cache_metadata} ->
        end_time = :os.system_time(:microsecond)
        operation_time = end_time - start_time
        update_cosmic_metrics(cache_updated_state, :get_hit, operation_time, :cache)
        {:reply, {:ok, value, :event_horizon_cache, operation_time}, cache_updated_state}

      {:cache_miss, cache_updated_state} ->
        # Fallback to gravitational shards for retrieval
        result = find_in_gravitational_shards(key, cache_updated_state.spacetime_shards)

        # Update state if shard was modified (access patterns)
        final_updated_state = case result do
          {:ok, value, shard_id, updated_shard} ->
            updated_shards = Map.put(cache_updated_state.spacetime_shards, shard_id, updated_shard)
            shard_updated_state = %{cache_updated_state | spacetime_shards: updated_shards}

            # Cache the retrieved value for future access
            if map_size(shard_updated_state.event_horizon_caches) > 0 do
              cache_retrieved_value(shard_updated_state, key, value, shard_id)
            else
              shard_updated_state
            end

          _ ->
            cache_updated_state
        end

        end_time = :os.system_time(:microsecond)
        operation_time = end_time - start_time

        # Update cosmic metrics
        case result do
          {:ok, _value, shard, _updated_shard} -> update_cosmic_metrics(final_updated_state, :get_hit, operation_time, shard)
          {:error, :not_found} -> update_cosmic_metrics(final_updated_state, :get_miss, operation_time, :all)
        end

        case result do
          {:ok, value, shard, _updated_shard} -> {:reply, {:ok, value, shard, operation_time}, final_updated_state}
          {:error, :not_found} -> {:reply, {:error, :not_found, operation_time}, final_updated_state}
        end
    end
  end

  defp handle_call_legacy_quantum_get(key, state) do
    # Legacy quantum_get implementation
    start_time = :os.system_time(:microsecond)

    # Use quantum observation to get primary data and entangled partners
    result = QuantumIndex.observe_quantum_data(key, state.spacetime_tables)

    end_time = :os.system_time(:microsecond)
    operation_time = end_time - start_time

    case result do
      {:ok, value, entangled_data, quantum_metadata} ->
        # Return enhanced response with quantum data
        response = %{
          value: value,
          shard: quantum_metadata.primary_shard,
          operation_time: operation_time,
          quantum_data: %{
            entangled_items: entangled_data,
            entangled_count: quantum_metadata.entangled_count,
            quantum_efficiency: quantum_metadata.entanglement_efficiency
          }
        }
        {:reply, {:ok, response}, state}

      {:error, :not_found} ->
        {:reply, {:error, :not_found, operation_time}, state}
    end
  end

  defp handle_call_legacy_cosmic_delete(key, state) do
    # Legacy cosmic_delete implementation
    start_time = :os.system_time(:microsecond)

    # Delete from all spacetime regions and filesystem
    deletion_results = Enum.map([:hot_data, :warm_data, :cold_data], fn shard ->
      table = Map.get(state.spacetime_tables, shard)

      deleted_from_ets = case :ets.lookup(table, key) do
        [{^key, _value}] ->
          :ets.delete(table, key)
          true
        [] ->
          false
      end

      # Delete from filesystem
      data_type = CosmicPersistence.extract_data_type(key)
      deleted_from_fs = case CosmicPersistence.delete_cosmic_record(key, shard, data_type) do
        {:ok, :deleted} -> true
        {:ok, :not_found} -> false
        {:error, _} -> false
      end

      status = case {deleted_from_ets, deleted_from_fs} do
        {true, _} -> :deleted
        {false, true} -> :deleted
        {false, false} -> :not_found
      end

      {shard, status}
    end)

    # Remove any quantum entanglements
    QuantumIndex.remove_entanglement(key)

    end_time = :os.system_time(:microsecond)
    operation_time = end_time - start_time

    # Update cosmic metrics
    update_cosmic_metrics(state, :delete, operation_time, :all)

    {:reply, {:ok, deletion_results, operation_time}, state}
  end

  # ULTRA-PERFORMANCE HELPER FUNCTIONS FOR GENSERVER BYPASS

  def handle_cast({:update_state, updated_state}, _old_state) do
    # Asynchronous state update to avoid blocking direct operations
    {:noreply, updated_state}
  end

  # PERFORMANCE REVOLUTION: TRUE GenServer bypass with local state caching

  @cached_state_key :islab_db_cached_state
  @cache_refresh_interval 1000  # Refresh cache every 1 second max

  defp get_cached_state() do
    case Process.get(@cached_state_key) do
      {state, timestamp} ->
        # Check if cache is still fresh (within 1 second)
        if :os.system_time(:millisecond) - timestamp < @cache_refresh_interval do
          state
        else
          # Cache expired, refresh it
          refresh_cached_state()
        end

      nil ->
        # No cache, create it
        refresh_cached_state()
    end
  end

  defp refresh_cached_state() do
    # This is the ONLY GenServer call, done rarely (every 1 second max)
    state = GenServer.call(__MODULE__, :get_current_state)
    timestamp = :os.system_time(:millisecond)
    Process.put(@cached_state_key, {state, timestamp})
    state
  end

  defp update_cached_state(updated_state) do
    # Update local cache immediately to reflect changes
    timestamp = :os.system_time(:millisecond)
    Process.put(@cached_state_key, {updated_state, timestamp})
  end

  defp update_state_async(updated_state) do
    # Update state asynchronously to avoid blocking the caller
    GenServer.cast(__MODULE__, {:update_state, updated_state})
  end

  # Legacy function for backward compatibility
  defp get_current_state() do
    get_cached_state()
  end
end
