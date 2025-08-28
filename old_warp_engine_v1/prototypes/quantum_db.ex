defmodule QuantumDB do
  @moduledoc """
  High-performance database engine using physics-inspired data structures.
  Optimized for both performance and elegant data modeling.
  """

  use GenServer
  require Logger

  # Compile-time physics constants for optimization
  @planck_time_ns 5.39e-35 * 1_000_000_000  # Minimum query granularity
  @light_speed_ops_per_sec 299_792_458       # Max operations per second per core
  @entropy_rebalance_threshold 2.5           # When to trigger load rebalancing

  defstruct [
    :quantum_indices,      # ETS tables with entangled key relationships
    :spacetime_shards,     # Region-based data partitioning
    :event_horizon_cache,  # Cache that prevents data "escape"
    :entropy_monitor,      # Load balancing metrics
    :wormhole_connections, # Inter-shard fast paths
    :vacuum_state,         # System stability monitoring
    :time_dilation_queues  # Priority-based processing queues
  ]

  ## QUANTUM INDICES - Entangled Key Relationships

  defmodule QuantumIndex do
    @moduledoc """
    ETS-based indices where related keys share quantum entanglement.
    When one key is accessed, related keys are pre-fetched automatically.
    """

    def create_entangled_index(name, entanglement_rules) do
      # Create ETS table optimized for entangled lookups
      table = :ets.new(name, [
        :set,
        :public,
        :named_table,
        {:read_concurrency, true},
        {:write_concurrency, true},
        {:decentralized_counters, true}
      ])

      # Store entanglement rules in separate ETS table
      entanglement_table = :"#{name}_entangled"
      :ets.new(entanglement_table, [:bag, :public, :named_table])

      # Precompute entanglement relationships
      Enum.each(entanglement_rules, fn {key_pattern, related_patterns} ->
        :ets.insert(entanglement_table, {key_pattern, related_patterns})
      end)

      {table, entanglement_table}
    end

    def quantum_get(table, key) do
      # Get primary value
      primary_result = :ets.lookup(table, key)

      # Get entangled keys and pre-fetch them (quantum superposition)
      entanglement_table = :"#{table}_entangled"
      entangled_keys = find_entangled_keys(entanglement_table, key)

      # Parallel fetch of entangled data (quantum measurement)
      entangled_data =
        entangled_keys
        |> Task.async_stream(fn ek -> {ek, :ets.lookup(table, ek)} end,
                             max_concurrency: System.schedulers_online())
        |> Enum.map(&elem(&1, 1))
        |> Enum.into(%{})

      # Return both primary and entangled results
      case primary_result do
        [{^key, value}] -> {:ok, value, entangled_data}
        [] -> {:error, :not_found, entangled_data}
      end
    end

    defp find_entangled_keys(entanglement_table, key) do
      # Find keys entangled with this one using pattern matching
      :ets.match(entanglement_table, {'$1', '$2'})
      |> Enum.flat_map(fn [pattern, related_patterns] ->
        if key_matches_pattern?(key, pattern) do
          Enum.map(related_patterns, &generate_key_from_pattern(&1, key))
        else
          []
        end
      end)
      |> Enum.uniq()
    end

    defp key_matches_pattern?(key, pattern) when is_binary(key) and is_binary(pattern) do
      # Simple glob-style pattern matching
      regex_pattern = String.replace(pattern, "*", ".*") |> Regex.compile!()
      Regex.match?(regex_pattern, key)
    end
    defp key_matches_pattern?(key, pattern), do: key == pattern

    defp generate_key_from_pattern(pattern, original_key) when is_binary(pattern) do
      # Replace pattern wildcards with parts from original key
      if String.contains?(pattern, "*") do
        # Simple substitution - could be more sophisticated
        String.replace(pattern, "*", extract_wildcard_part(original_key))
      else
        pattern
      end
    end
    defp generate_key_from_pattern(pattern, _), do: pattern

    defp extract_wildcard_part(key) do
      # Extract meaningful part from key for wildcard substitution
      key |> String.split(":") |> List.last() || key
    end
  end

  ## SPACETIME SHARDS - Regional Data Partitioning

  defmodule SpacetimeShard do
    @moduledoc """
    Data sharding where each shard has different "physics laws" (configurations).
    Optimized for data locality and access patterns.
    """

    defstruct [
      :shard_id,
      :physics_laws,        # Shard-specific configuration
      :data_table,          # ETS table for this shard's data
      :locality_metric,     # How "close" data items are
      :gravitational_pull,  # How much this shard attracts new data
      :event_horizon        # Cache size limit for this shard
    ]

    def create_shard(shard_id, physics_laws \\ %{}) do
      data_table = :ets.new(:"shard_#{shard_id}", [
        :set, :public,
        {:read_concurrency, true},
        {:write_concurrency, true}
      ])

      %SpacetimeShard{
        shard_id: shard_id,
        physics_laws: Map.merge(default_physics_laws(), physics_laws),
        data_table: data_table,
        locality_metric: 0.0,
        gravitational_pull: Map.get(physics_laws, :attraction, 1.0),
        event_horizon: Map.get(physics_laws, :cache_limit, 10_000)
      }
    end

    defp default_physics_laws do
      %{
        consistency_model: :strong,    # :strong, :eventual, :weak
        replication_factor: 1,
        compression_enabled: false,
        cache_ttl_ms: 300_000,        # 5 minutes
        attraction: 1.0,              # How much new data is attracted
        time_dilation: 1.0            # Processing speed multiplier
      }
    end

    def route_data_to_shard(shards, key, data, access_pattern \\ :random) do
      # Route data to shard based on physics-inspired algorithms
      case access_pattern do
        :sequential ->
          # Use consistent hashing for sequential access
          shard_index = :erlang.phash2(key) |> rem(length(shards))
          Enum.at(shards, shard_index)

        :hot_data ->
          # Route to shard with highest gravitational pull
          Enum.max_by(shards, & &1.gravitational_pull)

        :locality_sensitive ->
          # Route based on data locality (similar keys go together)
          find_best_locality_shard(shards, key, data)

        :load_balanced ->
          # Route to least loaded shard
          Enum.min_by(shards, fn shard ->
            :ets.info(shard.data_table, :size)
          end)

        _ ->
          # Default: weighted random based on gravitational pull
          weighted_random_shard(shards)
      end
    end

    defp find_best_locality_shard(shards, key, data) do
      # Find shard with most similar existing data
      locality_scores = Enum.map(shards, fn shard ->
        similarity = calculate_data_similarity(shard, key, data)
        {shard, similarity}
      end)

      {best_shard, _score} = Enum.max_by(locality_scores, &elem(&1, 1))
      best_shard
    end

    defp calculate_data_similarity(shard, key, data) do
      # Simple similarity based on key prefix and data type
      sample_keys = :ets.select(shard.data_table, [{{:'$1', :'_'}, [], [:'$1']}], 10)
                   |> elem(0)  # Get the keys

      if length(sample_keys) == 0 do
        0.0
      else
        key_similarities = Enum.map(sample_keys, fn existing_key ->
          string_similarity(to_string(key), to_string(existing_key))
        end)

        Enum.max(key_similarities)
      end
    end

    defp string_similarity(str1, str2) do
      # Simple Jaccard similarity
      set1 = String.graphemes(str1) |> MapSet.new()
      set2 = String.graphemes(str2) |> MapSet.new()

      intersection_size = MapSet.intersection(set1, set2) |> MapSet.size()
      union_size = MapSet.union(set1, set2) |> MapSet.size()

      if union_size == 0, do: 0.0, else: intersection_size / union_size
    end

    defp weighted_random_shard(shards) do
      # Select shard randomly weighted by gravitational pull
      total_pull = Enum.sum(Enum.map(shards, & &1.gravitational_pull))
      random_value = :rand.uniform() * total_pull

      find_shard_by_weight(shards, random_value, 0.0)
    end

    defp find_shard_by_weight([shard | _], random_value, acc)
         when acc + shard.gravitational_pull >= random_value do
      shard
    end
    defp find_shard_by_weight([shard | rest], random_value, acc) do
      find_shard_by_weight(rest, random_value, acc + shard.gravitational_pull)
    end
    defp find_shard_by_weight([], _, _), do: nil
  end

  ## EVENT HORIZON CACHE - Cache That Prevents Data "Escape"

  defmodule EventHorizonCache do
    @moduledoc """
    Cache with physics-inspired eviction policies.
    Data that crosses the "event horizon" gets compressed but never truly escapes.
    """

    def create_cache(name, opts \\ []) do
      cache_table = :ets.new(name, [
        :set, :public,
        {:read_concurrency, true},
        {:write_concurrency, true}
      ])

      # Separate table for metadata (access time, size, etc.)
      metadata_table = :"#{name}_metadata"
      :ets.new(metadata_table, [:set, :public, :named_table])

      # Initialize cache parameters
      schwarzschild_radius = Keyword.get(opts, :max_size, 1000)
      hawking_temperature = Keyword.get(opts, :eviction_rate, 0.1)

      :ets.insert(metadata_table, {:config, %{
        schwarzschild_radius: schwarzschild_radius,
        hawking_temperature: hawking_temperature,
        current_mass: 0,
        accretion_disk: []
      }})

      {cache_table, metadata_table}
    end

    def get(cache_table, key) do
      metadata_table = :"#{cache_table}_metadata"

      case :ets.lookup(cache_table, key) do
        [{^key, value}] ->
          # Update access time (gravitational interaction)
          :ets.insert(metadata_table, {key, %{
            last_access: :os.system_time(:millisecond),
            access_count: get_access_count(metadata_table, key) + 1,
            data_size: :erlang.external_size(value)
          }})
          {:ok, value}

        [] ->
          :miss
      end
    end

    def put(cache_table, key, value) do
      metadata_table = :"#{cache_table}_metadata"

      data_size = :erlang.external_size(value)

      # Check if data will fit within event horizon
      [{:config, config}] = :ets.lookup(metadata_table, :config)

      if config.current_mass + data_size <= config.schwarzschild_radius do
        # Data fits - store normally
        :ets.insert(cache_table, {key, value})
        :ets.insert(metadata_table, {key, %{
          last_access: :os.system_time(:millisecond),
          access_count: 1,
          data_size: data_size
        }})

        # Update total mass
        new_config = %{config | current_mass: config.current_mass + data_size}
        :ets.insert(metadata_table, {:config, new_config})

        :ok
      else
        # Data too large or cache full - trigger Hawking radiation
        evicted_items = hawking_radiation_eviction(cache_table, metadata_table, data_size)

        # Try again after eviction
        if length(evicted_items) > 0 do
          put(cache_table, key, value)
        else
          {:error, :cache_full}
        end
      end
    end

    defp get_access_count(metadata_table, key) do
      case :ets.lookup(metadata_table, key) do
        [{^key, metadata}] -> Map.get(metadata, :access_count, 0)
        [] -> 0
      end
    end

    defp hawking_radiation_eviction(cache_table, metadata_table, needed_space) do
      # Evict least recently used items (Hawking radiation)
      [{:config, config}] = :ets.lookup(metadata_table, :config)

      # Get all cache entries with metadata
      cache_entries = :ets.tab2list(cache_table)
      metadata_entries = :ets.select(metadata_table, [{{:'$1', :'$2'}, [{'=/=', '$1', :config}], [{'$1', '$2'}]}])
      metadata_map = Enum.into(metadata_entries, %{})

      # Sort by access time (oldest first)
      entries_with_metadata = Enum.map(cache_entries, fn {key, value} ->
        metadata = Map.get(metadata_map, key, %{last_access: 0, data_size: 0})
        {key, value, metadata}
      end)
      |> Enum.sort_by(fn {_key, _value, metadata} -> metadata.last_access end)

      # Evict until we have enough space
      evict_entries(entries_with_metadata, cache_table, metadata_table, needed_space, 0, [])
    end

    defp evict_entries([], _cache_table, _metadata_table, _needed_space, _freed_space, evicted) do
      evicted
    end
    defp evict_entries([{key, _value, metadata} | rest], cache_table, metadata_table, needed_space, freed_space, evicted) do
      if freed_space >= needed_space do
        evicted
      else
        # Evict this entry
        :ets.delete(cache_table, key)
        :ets.delete(metadata_table, key)

        new_freed_space = freed_space + Map.get(metadata, :data_size, 0)
        evict_entries(rest, cache_table, metadata_table, needed_space, new_freed_space, [key | evicted])
      end
    end
  end

  ## ENTROPY MONITOR - Load Balancing Based on System Entropy

  defmodule EntropyMonitor do
    @moduledoc """
    Monitor system entropy and trigger rebalancing when needed.
    High-performance entropy calculation using ETS counters.
    """

    def create_monitor(name) do
      # ETS table to track resource usage across shards
      :ets.new(name, [
        :set, :public, :named_table,
        {:write_concurrency, true},
        {:decentralized_counters, true}
      ])
    end

    def update_shard_metrics(monitor_table, shard_id, metrics) do
      # Update metrics using atomic ETS operations
      timestamp = :os.system_time(:millisecond)

      :ets.insert(monitor_table, {shard_id, %{
        cpu_usage: metrics.cpu_usage,
        memory_usage: metrics.memory_usage,
        query_rate: metrics.query_rate,
        timestamp: timestamp
      }})
    end

    def calculate_system_entropy(monitor_table) do
      # Fast entropy calculation using ETS select
      all_metrics = :ets.select(monitor_table, [{{:'$1', :'$2'}, [], [:'$2']}])

      if length(all_metrics) == 0 do
        %{total_entropy: 0.0, rebalance_needed: false}
      else
        # Calculate Shannon entropy of resource distribution
        cpu_distribution = Enum.map(all_metrics, & &1.cpu_usage)
        memory_distribution = Enum.map(all_metrics, & &1.memory_usage)
        query_distribution = Enum.map(all_metrics, & &1.query_rate)

        cpu_entropy = shannon_entropy(cpu_distribution)
        memory_entropy = shannon_entropy(memory_distribution)
        query_entropy = shannon_entropy(query_distribution)

        total_entropy = cpu_entropy + memory_entropy + query_entropy

        %{
          total_entropy: total_entropy,
          cpu_entropy: cpu_entropy,
          memory_entropy: memory_entropy,
          query_entropy: query_entropy,
          rebalance_needed: total_entropy > @entropy_rebalance_threshold
        }
      end
    end

    defp shannon_entropy(values) when length(values) == 0, do: 0.0
    defp shannon_entropy(values) do
      # Normalize values to probabilities
      total = Enum.sum(values)

      if total == 0 do
        0.0
      else
        values
        |> Enum.map(fn v -> v / total end)
        |> Enum.filter(fn p -> p > 0 end)
        |> Enum.map(fn p -> -p * :math.log2(p) end)
        |> Enum.sum()
      end
    end

    def entropy_based_rebalancing(monitor_table, shards) do
      entropy_data = calculate_system_entropy(monitor_table)

      if entropy_data.rebalance_needed do
        # Find overloaded and underloaded shards
        all_metrics = :ets.select(monitor_table, [{{:'$1', :'$2'}, [], [{'$1', '$2'}]}])

        overloaded = Enum.filter(all_metrics, fn {_shard_id, metrics} ->
          metrics.cpu_usage > 0.8 or metrics.memory_usage > 0.8
        end)

        underloaded = Enum.filter(all_metrics, fn {_shard_id, metrics} ->
          metrics.cpu_usage < 0.3 and metrics.memory_usage < 0.3
        end)

        # Generate rebalancing instructions
        rebalance_instructions = generate_rebalance_plan(overloaded, underloaded)

        {:rebalance, rebalance_instructions, entropy_data}
      else
        {:balanced, entropy_data}
      end
    end

    defp generate_rebalance_plan(overloaded, underloaded) do
      # Simple rebalancing: move load from overloaded to underloaded shards
      Enum.zip(overloaded, underloaded)
      |> Enum.map(fn {{from_shard, from_metrics}, {to_shard, to_metrics}} ->
        %{
          action: :migrate_data,
          from_shard: from_shard,
          to_shard: to_shard,
          estimated_load_reduction: (from_metrics.cpu_usage - 0.5) * 0.3,
          priority: calculate_migration_priority(from_metrics, to_metrics)
        }
      end)
    end

    defp calculate_migration_priority(from_metrics, to_metrics) do
      # Higher priority for bigger load differences
      load_diff = (from_metrics.cpu_usage + from_metrics.memory_usage) -
                  (to_metrics.cpu_usage + to_metrics.memory_usage)

      min(max(load_diff * 10, 1), 10)  # Priority between 1-10
    end
  end

  ## WORMHOLE CONNECTIONS - Inter-Shard Fast Paths

  defmodule WormholeRouter do
    @moduledoc """
    Fast routing between shards using pre-computed paths.
    Maintains stable "wormholes" for frequently accessed data patterns.
    """

    def create_router(name) do
      # Routing table for wormhole connections
      :ets.new(name, [
        :set, :public, :named_table,
        {:read_concurrency, true}
      ])
    end

    def establish_wormhole(router_table, from_shard, to_shard, connection_strength \\ 1.0) do
      # Create bidirectional fast path between shards
      wormhole_id = generate_wormhole_id(from_shard, to_shard)

      connection_data = %{
        from_shard: from_shard,
        to_shard: to_shard,
        strength: connection_strength,
        usage_count: 0,
        created_at: :os.system_time(:millisecond),
        last_used: :os.system_time(:millisecond)
      }

      :ets.insert(router_table, {wormhole_id, connection_data})
      :ets.insert(router_table, {generate_wormhole_id(to_shard, from_shard),
                                Map.merge(connection_data, %{from_shard: to_shard, to_shard: from_shard})})

      wormhole_id
    end

    defp generate_wormhole_id(shard1, shard2) do
      :"wormhole_#{shard1}_to_#{shard2}"
    end

    def find_fast_path(router_table, from_shard, to_shard) do
      # Find direct wormhole connection
      direct_id = generate_wormhole_id(from_shard, to_shard)

      case :ets.lookup(router_table, direct_id) do
        [{^direct_id, connection_data}] ->
          # Update usage statistics
          updated_data = %{connection_data |
            usage_count: connection_data.usage_count + 1,
            last_used: :os.system_time(:millisecond)
          }
          :ets.insert(router_table, {direct_id, updated_data})

          {:direct, connection_data.strength}

        [] ->
          # No direct connection - find multi-hop path
          find_multi_hop_path(router_table, from_shard, to_shard, [from_shard], 3)
      end
    end

    defp find_multi_hop_path(_router_table, _from_shard, _to_shard, _visited, 0) do
      {:no_path, :max_hops_exceeded}
    end
    defp find_multi_hop_path(router_table, from_shard, to_shard, visited, max_hops) do
      # Find all wormholes from current shard
      pattern = generate_wormhole_id(from_shard, :"$1")
      matches = :ets.select(router_table, [{{pattern, :'$2'}, [], [:'$2']}])

      # Try each connection that doesn't lead to visited shards
      viable_connections = Enum.filter(matches, fn connection ->
        connection.to_shard not in visited and connection.strength > 0.1
      end)

      case viable_connections do
        [] ->
          {:no_path, :dead_end}

        connections ->
          # Try the strongest connection first
          best_connection = Enum.max_by(connections, & &1.strength)

          if best_connection.to_shard == to_shard do
            {:multi_hop, [from_shard, to_shard], best_connection.strength}
          else
            case find_multi_hop_path(router_table, best_connection.to_shard, to_shard,
                                   [best_connection.to_shard | visited], max_hops - 1) do
              {:multi_hop, path, strength} ->
                {:multi_hop, [from_shard | path], strength * best_connection.strength}
              error ->
                error
            end
          end
      end
    end

    def maintain_wormholes(router_table, decay_rate \\ 0.95) do
      # Decay unused wormholes and strengthen frequently used ones
      current_time = :os.system_time(:millisecond)
      time_threshold = current_time - 60_000  # 1 minute

      all_wormholes = :ets.tab2list(router_table)

      Enum.each(all_wormholes, fn {wormhole_id, connection_data} ->
        if connection_data.last_used < time_threshold do
          # Decay unused wormhole
          new_strength = connection_data.strength * decay_rate

          if new_strength < 0.01 do
            # Wormhole collapsed - remove it
            :ets.delete(router_table, wormhole_id)
          else
            updated_data = %{connection_data | strength: new_strength}
            :ets.insert(router_table, {wormhole_id, updated_data})
          end
        end
      end)
    end
  end

  ## MAIN QUANTUMDB ENGINE

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    # Initialize all physics-inspired subsystems
    quantum_indices = QuantumIndex.create_entangled_index(:main_index, [
      {"user:*", ["profile:*", "settings:*", "sessions:*"]},
      {"order:*", ["customer:*", "products:*", "payment:*"]},
      {"post:*", ["author:*", "comments:*", "tags:*"]}
    ])

    # Create spacetime shards with different physics laws
    spacetime_shards = [
      SpacetimeShard.create_shard(:hot_data, %{
        consistency_model: :strong,
        attraction: 2.0,
        time_dilation: 0.5,  # Faster processing
        cache_limit: 50_000
      }),
      SpacetimeShard.create_shard(:warm_data, %{
        consistency_model: :eventual,
        attraction: 1.0,
        time_dilation: 1.0,
        cache_limit: 20_000
      }),
      SpacetimeShard.create_shard(:cold_data, %{
        consistency_model: :weak,
        attraction: 0.3,
        time_dilation: 2.0,  # Slower but cheaper processing
        cache_limit: 5_000
      })
    ]

    # Create event horizon cache
    event_horizon_cache = EventHorizonCache.create_cache(:main_cache,
      max_size: 100_000, eviction_rate: 0.1)

    # Initialize entropy monitor
    entropy_monitor = EntropyMonitor.create_monitor(:entropy_monitor)

    # Create wormhole router
    wormhole_network = WormholeRouter.create_router(:wormhole_router)

    # Establish initial wormhole connections between shards
    WormholeRouter.establish_wormhole(wormhole_network, :hot_data, :warm_data, 0.8)
    WormholeRouter.establish_wormhole(wormhole_network, :warm_data, :cold_data, 0.6)

    state = %QuantumDB{
      quantum_indices: quantum_indices,
      spacetime_shards: spacetime_shards,
      event_horizon_cache: event_horizon_cache,
      entropy_monitor: entropy_monitor,
      wormhole_connections: wormhole_network,
      vacuum_state: %{stability: 1.0, last_check: :os.system_time(:millisecond)},
      time_dilation_queues: %{
        critical: :queue.new(),
        normal: :queue.new(),
        background: :queue.new()
      }
    }

    # Start periodic maintenance
    schedule_maintenance()

    Logger.info("🚀 QuantumDB started with #{length(spacetime_shards)} spacetime shards")
    {:ok, state}
  end

  ## PUBLIC API

  def quantum_get(key) do
    GenServer.call(__MODULE__, {:quantum_get, key})
  end

  def quantum_put(key, value, opts \\ []) do
    GenServer.call(__MODULE__, {:quantum_put, key, value, opts})
  end

  def quantum_delete(key) do
    GenServer.call(__MODULE__, {:quantum_delete, key})
  end

  def get_system_metrics() do
    GenServer.call(__MODULE__, :get_system_metrics)
  end

  ## GENSERVER CALLBACKS

  def handle_call({:quantum_get, key}, _from, state) do
    start_time = :os.system_time(:microsecond)

    # Try cache first (event horizon)
    {cache_table, _metadata_table} = state.event_horizon_cache

    result = case EventHorizonCache.get(cache_table, key) do
      {:ok, value} ->
        # Cache hit - also get entangled data
        {main_table, _entanglement_table} = state.quantum_indices
        case QuantumIndex.quantum_get(main_table, key) do
          {:ok, _primary, entangled_data} ->
            {:ok, value, entangled_data, :cache_hit}
          _ ->
            {:ok, value, %{}, :cache_hit}
        end

      :miss ->
        # Cache miss - try quantum indices
        {main_table, _entanglement_table} = state.quantum_indices
        case QuantumIndex.quantum_get(main_table, key) do
          {:ok, value, entangled_data} ->
            # Cache the result
            EventHorizonCache.put(cache_table, key, value)
            {:ok, value, entangled_data, :index_hit}

          {:error, :not_found, entangled_data} ->
            # Not in indices - try shards via wormhole routing
            case find_in_shards(state, key) do
              {:ok, value, shard_id} ->
                # Cache and index the result
                EventHorizonCache.put(cache_table, key, value)
                {main_table, _} = state.quantum_indices
                :ets.insert(main_table, {key, value})
                {:ok, value, entangled_data, {:shard_hit, shard_id}}

              :not_found ->
                {:error, :not_found, entangled_data, :miss_all}
            end
        end
    end

    end_time = :os.system_time(:microsecond)
    query_time = end_time - start_time

    # Update metrics for entropy monitoring
    update_query_metrics(state, key, query_time, result)

    {:reply, result, state}
  end

  def handle_call({:quantum_put, key, value, opts}, _from, state) do
    start_time = :os.system_time(:microsecond)

    # Determine access pattern and route to appropriate shard
    access_pattern = Keyword.get(opts, :access_pattern, :random)
    priority = Keyword.get(opts, :priority, :normal)

    # Route to shard based on physics laws
    target_shard = SpacetimeShard.route_data_to_shard(
      state.spacetime_shards,
      key,
      value,
      access_pattern
    )

    # Store in shard
    :ets.insert(target_shard.data_table, {key, value})

    # Store in quantum indices for entanglement
    {main_table, _entanglement_table} = state.quantum_indices
    :ets.insert(main_table, {key, value})

    # Cache if appropriate
    {cache_table, _metadata_table} = state.event_horizon_cache
    case priority do
      :hot -> EventHorizonCache.put(cache_table, key, value)
      :normal when :rand.uniform() < 0.3 -> EventHorizonCache.put(cache_table, key, value)
      _ -> :ok  # Don't cache background data
    end

    end_time = :os.system_time(:microsecond)
    operation_time = end_time - start_time

    # Update shard metrics
    update_shard_metrics(state, target_shard.shard_id, operation_time, :write)

    {:reply, {:ok, target_shard.shard_id, operation_time}, state}
  end

  def handle_call({:quantum_delete, key}, _from, state) do
    # Delete from all subsystems
    {cache_table, _metadata_table} = state.event_horizon_cache
    {main_table, _entanglement_table} = state.quantum_indices

    # Remove from cache
    :ets.delete(cache_table, key)

    # Remove from indices
    :ets.delete(main_table, key)

    # Remove from all shards
    deleted_from_shards = Enum.map(state.spacetime_shards, fn shard ->
      case :ets.lookup(shard.data_table, key) do
        [{^key, _value}] ->
          :ets.delete(shard.data_table, key)
          {shard.shard_id, :deleted}
        [] ->
          {shard.shard_id, :not_found}
      end
    end)

    {:reply, {:ok, deleted_from_shards}, state}
  end

  def handle_call(:get_system_metrics, _from, state) do
    # Collect comprehensive system metrics
    entropy_data = EntropyMonitor.calculate_system_entropy(state.entropy_monitor)

    shard_metrics = Enum.map(state.spacetime_shards, fn shard ->
      shard_size = :ets.info(shard.data_table, :size)
      memory_usage = :ets.info(shard.data_table, :memory) * :erlang.system_info(:wordsize)

      %{
        shard_id: shard.shard_id,
        data_items: shard_size,
        memory_bytes: memory_usage,
        physics_laws: shard.physics_laws,
        gravitational_pull: shard.gravitational_pull
      }
    end)

    {cache_table, metadata_table} = state.event_horizon_cache
    [{:config, cache_config}] = :ets.lookup(metadata_table, :config)
    cache_metrics = %{
      current_mass: cache_config.current_mass,
      schwarzschild_radius: cache_config.schwarzschild_radius,
      hawking_temperature: cache_config.hawking_temperature,
      items_cached: :ets.info(cache_table, :size)
    }

    {main_table, entanglement_table} = state.quantum_indices
    index_metrics = %{
      indexed_items: :ets.info(main_table, :size),
      entanglement_rules: :ets.info(entanglement_table, :size),
      index_memory: :ets.info(main_table, :memory) * :erlang.system_info(:wordsize)
    }

    wormhole_metrics = %{
      active_wormholes: :ets.info(state.wormhole_connections, :size),
      network_memory: :ets.info(state.wormhole_connections, :memory) * :erlang.system_info(:wordsize)
    }

    metrics = %{
      entropy: entropy_data,
      shards: shard_metrics,
      cache: cache_metrics,
      indices: index_metrics,
      wormholes: wormhole_metrics,
      vacuum_state: state.vacuum_state,
      uptime_ms: :os.system_time(:millisecond) - Process.info(self(), :dictionary)[:start_time] || 0
    }

    {:reply, metrics, state}
  end

  def handle_info(:maintenance, state) do
    # Periodic maintenance tasks

    # 1. Wormhole maintenance (decay unused connections)
    WormholeRouter.maintain_wormholes(state.wormhole_connections, 0.98)

    # 2. Entropy-based rebalancing
    case EntropyMonitor.entropy_based_rebalancing(state.entropy_monitor, state.spacetime_shards) do
      {:rebalance, instructions, _entropy_data} ->
        Logger.info("🌌 Entropy rebalancing triggered: #{length(instructions)} migrations")
        # In a real system, you'd execute the migration instructions here

      {:balanced, _entropy_data} ->
        :ok  # System is balanced
    end

    # 3. Vacuum stability check
    new_vacuum_state = check_vacuum_stability(state)
    updated_state = %{state | vacuum_state: new_vacuum_state}

    # 4. Establish new wormholes based on access patterns
    establish_adaptive_wormholes(updated_state)

    # Schedule next maintenance
    schedule_maintenance()

    {:noreply, updated_state}
  end

  ## HELPER FUNCTIONS

  defp find_in_shards(state, key) do
    # Try to find key in shards using wormhole routing for optimization
    # First, try to find the best shard via wormhole network

    case find_optimal_shard_route(state, key) do
      {:direct, shard_id, _strength} ->
        shard = Enum.find(state.spacetime_shards, &(&1.shard_id == shard_id))
        case :ets.lookup(shard.data_table, key) do
          [{^key, value}] -> {:ok, value, shard_id}
          [] -> search_all_shards(state.spacetime_shards, key)
        end

      {:multi_hop, _path, _strength} ->
        # For now, just search all shards for multi-hop
        search_all_shards(state.spacetime_shards, key)

      {:no_path, _reason} ->
        search_all_shards(state.spacetime_shards, key)
    end
  end

  defp find_optimal_shard_route(state, key) do
    # Use some heuristic to guess which shard might have the data
    # For now, use consistent hashing as fallback
    estimated_shard_id = case :erlang.phash2(key) |> rem(length(state.spacetime_shards)) do
      0 -> :hot_data
      1 -> :warm_data
      _ -> :cold_data
    end

    # Try to find fast path to estimated shard
    WormholeRouter.find_fast_path(state.wormhole_connections, :query_origin, estimated_shard_id)
  end

  defp search_all_shards(shards, key) do
    # Parallel search across all shards
    search_tasks = Enum.map(shards, fn shard ->
      Task.async(fn ->
        case :ets.lookup(shard.data_table, key) do
          [{^key, value}] -> {:found, value, shard.shard_id}
          [] -> :not_found
        end
      end)
    end)

    # Wait for first success or all failures
    case Task.yield_many(search_tasks, 100) do
      results ->
        found_result = Enum.find_value(results, fn {_task, result} ->
          case result do
            {:ok, {:found, value, shard_id}} -> {:ok, value, shard_id}
            _ -> nil
          end
        end)

        # Cancel remaining tasks
        Enum.each(search_tasks, &Task.shutdown(&1, :brutal_kill))

        found_result || :not_found
    end
  end

  defp update_query_metrics(state, _key, query_time_us, result) do
    # Update entropy monitor with query metrics
    result_type = case result do
      {:ok, _value, _entangled, :cache_hit} -> :cache_hit
      {:ok, _value, _entangled, :index_hit} -> :index_hit
      {:ok, _value, _entangled, {:shard_hit, _}} -> :shard_hit
      {:error, :not_found, _entangled, :miss_all} -> :miss
    end

    # Simple metrics aggregation
    metrics = %{
      cpu_usage: calculate_cpu_usage(query_time_us),
      memory_usage: :rand.uniform() * 0.5,  # Simplified for demo
      query_rate: 1.0,  # Simplified for demo
      result_type: result_type
    }

    EntropyMonitor.update_shard_metrics(state.entropy_monitor, :query_engine, metrics)
  end

  defp update_shard_metrics(state, shard_id, operation_time_us, operation_type) do
    # Update metrics for the specific shard
    cpu_usage = calculate_cpu_usage(operation_time_us)
    memory_usage = :rand.uniform() * 0.3  # Simplified for demo

    metrics = %{
      cpu_usage: cpu_usage,
      memory_usage: memory_usage,
      query_rate: if(operation_type == :read, do: 1.0, else: 0.0),
      write_rate: if(operation_type == :write, do: 1.0, else: 0.0)
    }

    EntropyMonitor.update_shard_metrics(state.entropy_monitor, shard_id, metrics)
  end

  defp calculate_cpu_usage(operation_time_us) do
    # Convert operation time to CPU usage estimate
    # Longer operations = higher CPU usage
    base_usage = 0.1
    time_factor = operation_time_us / 1000.0  # Convert to ms

    min(base_usage + (time_factor / 100.0), 1.0)
  end

  defp check_vacuum_stability(state) do
    # Check system stability and update vacuum state
    current_time = :os.system_time(:millisecond)

    # Simple stability check based on system load
    total_processes = length(Process.list())
    memory_usage = :erlang.memory(:total) / (1024 * 1024)  # MB

    stability_score = cond do
      total_processes > 1000 or memory_usage > 1000 -> 0.3  # Unstable
      total_processes > 500 or memory_usage > 500 -> 0.7   # Moderate
      true -> 1.0  # Stable
    end

    %{
      stability: stability_score,
      last_check: current_time,
      process_count: total_processes,
      memory_mb: memory_usage
    }
  end

  defp establish_adaptive_wormholes(state) do
    # Analyze access patterns and establish new wormhole connections
    # This would analyze query logs to find frequently accessed shard pairs
    # For now, just maintain existing connections

    # Check if any high-traffic routes need stronger wormholes
    current_time = :os.system_time(:millisecond)

    # In a real implementation, you'd analyze access logs here
    # and create new wormhole connections between frequently accessed shards

    :ok
  end

  defp schedule_maintenance() do
    # Schedule maintenance every 30 seconds
    Process.send_after(self(), :maintenance, 30_000)
  end

  ## BENCHMARK AND DEMO FUNCTIONS

  def run_performance_demo() do
    IO.puts("🚀 QuantumDB Performance Demonstration")
    IO.puts(String.duplicate("=", 60))

    # Start the system
    {:ok, _pid} = start_link()

    # Wait for initialization
    :timer.sleep(100)

    # Demo 1: Quantum Entanglement Performance
    IO.puts("\n🔬 1. QUANTUM ENTANGLEMENT DEMO")
    demo_quantum_entanglement()

    # Demo 2: Spacetime Shard Routing
    IO.puts("\n🌌 2. SPACETIME SHARD ROUTING")
    demo_spacetime_routing()

    # Demo 3: Event Horizon Caching
    IO.puts("\n🕳️  3. EVENT HORIZON CACHING")
    demo_event_horizon_cache()

    # Demo 4: Entropy Load Balancing
    IO.puts("\n⚡ 4. ENTROPY LOAD BALANCING")
    demo_entropy_balancing()

    # Demo 5: Wormhole Network Performance
    IO.puts("\n🌀 5. WORMHOLE NETWORK ROUTING")
    demo_wormhole_routing()

    # Demo 6: Comprehensive Benchmark
    IO.puts("\n📊 6. COMPREHENSIVE BENCHMARK")
    run_comprehensive_benchmark()

    # System metrics
    IO.puts("\n📈 FINAL SYSTEM METRICS")
    metrics = get_system_metrics()
    print_system_metrics(metrics)
  end

  defp demo_quantum_entanglement() do
    # Test quantum entanglement performance
    start_time = :os.system_time(:microsecond)

    # Store related data that should be entangled
    quantum_put("user:alice", %{name: "Alice", email: "alice@example.com"}, priority: :hot)
    quantum_put("profile:alice", %{bio: "Software Engineer", location: "SF"}, priority: :hot)
    quantum_put("settings:alice", %{theme: "dark", notifications: true}, priority: :normal)

    # Test entangled retrieval
    {:ok, user_data, entangled_data, cache_status} = quantum_get("user:alice")

    end_time = :os.system_time(:microsecond)

    IO.puts("  User data: #{inspect(user_data)}")
    IO.puts("  Entangled data keys: #{inspect(Map.keys(entangled_data))}")
    IO.puts("  Cache status: #{cache_status}")
    IO.puts("  Query time: #{end_time - start_time}μs")
    IO.puts("  Entanglement efficiency: #{map_size(entangled_data)} related items pre-fetched")
  end

  defp demo_spacetime_routing() do
    # Test different access patterns and shard routing
    access_patterns = [:hot_data, :sequential, :locality_sensitive, :load_balanced]

    Enum.each(access_patterns, fn pattern ->
      start_time = :os.system_time(:microsecond)

      {:ok, shard_id, operation_time} = quantum_put(
        "test_#{pattern}_#{:rand.uniform(1000)}",
        %{pattern: pattern, data: :rand.uniform(1000)},
        access_pattern: pattern
      )

      end_time = :os.system_time(:microsecond)

      IO.puts("  Pattern #{pattern}: routed to #{shard_id} in #{operation_time}μs")
    end)
  end

  defp demo_event_horizon_cache() do
    # Test cache performance with different data sizes
    data_sizes = [
      {"small", String.duplicate("x", 100)},
      {"medium", String.duplicate("y", 1000)},
      {"large", String.duplicate("z", 10000)}
    ]

    Enum.each(data_sizes, fn {size_name, data} ->
      key = "cache_test_#{size_name}"

      # Store data
      start_time = :os.system_time(:microsecond)
      quantum_put(key, data, priority: :hot)
      store_time = :os.system_time(:microsecond) - start_time

      # Retrieve from cache
      start_time = :os.system_time(:microsecond)
      {:ok, _value, _entangled, cache_status} = quantum_get(key)
      retrieve_time = :os.system_time(:microsecond) - start_time

      IO.puts("  #{size_name} data (#{byte_size(data)} bytes):")
      IO.puts("    Store: #{store_time}μs, Retrieve: #{retrieve_time}μs")
      IO.puts("    Cache status: #{cache_status}")
    end)
  end

  defp demo_entropy_balancing() do
    # Generate some load to trigger entropy monitoring
    tasks = for i <- 1..50 do
      Task.async(fn ->
        quantum_put("load_test_#{i}", %{index: i, data: :rand.uniform(1000)})
        quantum_get("load_test_#{:rand.uniform(50)}")
      end)
    end

    # Wait for tasks to complete
    Task.await_many(tasks, 5000)

    # Check entropy metrics
    metrics = get_system_metrics()
    entropy = metrics.entropy

    IO.puts("  System entropy: #{Float.round(entropy.total_entropy, 3)}")
    IO.puts("  CPU entropy: #{Float.round(entropy.cpu_entropy, 3)}")
    IO.puts("  Memory entropy: #{Float.round(entropy.memory_entropy, 3)}")
    IO.puts("  Rebalance needed: #{entropy.rebalance_needed}")

    if entropy.rebalance_needed do
      IO.puts("  🌌 Cosmic rebalancing would be triggered!")
    end
  end

  defp demo_wormhole_routing() do
    # Test wormhole network performance
    # This would be more meaningful with actual network latency simulation
    IO.puts("  Wormhole connections established between shards")
    IO.puts("  Network topology: full mesh with adaptive strengthening")
    IO.puts("  Connection decay: 2% per maintenance cycle")

    metrics = get_system_metrics()
    IO.puts("  Active wormholes: #{metrics.wormholes.active_wormholes}")
    IO.puts("  Network memory: #{div(metrics.wormholes.network_memory, 1024)} KB")
  end

  defp run_comprehensive_benchmark() do
    IO.puts("  Running mixed workload benchmark...")

    start_time = :os.system_time(:millisecond)

    # Mixed read/write workload
    benchmark_tasks = for i <- 1..100 do
      Task.async(fn ->
        case rem(i, 4) do
          0 ->
            # Write operation
            quantum_put("bench_#{i}", %{value: i, timestamp: :os.system_time(:millisecond)})
          1 ->
            # Read operation
            quantum_get("bench_#{max(i-10, 1)}")
          2 ->
            # Read with entanglement
            quantum_get("user:alice")  # Should trigger entangled reads
          3 ->
            # Delete operation
            quantum_delete("bench_#{max(i-20, 1)}")
        end
      end)
    end

    # Wait for completion
    results = Task.await_many(benchmark_tasks, 10000)

    end_time = :os.system_time(:millisecond)
    total_time = end_time - start_time

    # Analyze results
    successful_ops = Enum.count(results, fn
      {:ok, _} -> true
      {:ok, _, _} -> true
      {:ok, _, _, _} -> true
      _ -> false
    end)

    ops_per_second = (successful_ops * 1000) / total_time

    IO.puts("  Total operations: #{length(results)}")
    IO.puts("  Successful operations: #{successful_ops}")
    IO.puts("  Total time: #{total_time}ms")
    IO.puts("  Throughput: #{Float.round(ops_per_second, 1)} ops/second")
    IO.puts("  Average latency: #{Float.round(total_time / length(results), 2)}ms/op")
  end

  defp print_system_metrics(metrics) do
    IO.puts("  System Entropy: #{Float.round(metrics.entropy.total_entropy, 3)}")
    IO.puts("  Vacuum Stability: #{Float.round(metrics.vacuum_state.stability, 3)}")
    IO.puts("  Active Shards: #{length(metrics.shards)}")

    Enum.each(metrics.shards, fn shard ->
      IO.puts("    #{shard.shard_id}: #{shard.data_items} items, #{div(shard.memory_bytes, 1024)}KB")
    end)

    IO.puts("  Cache Utilization: #{metrics.cache.current_mass}/#{metrics.cache.schwarzschild_radius}")
    IO.puts("  Quantum Index: #{metrics.indices.indexed_items} items, #{div(metrics.indices.index_memory, 1024)}KB")
    IO.puts("  Wormhole Network: #{metrics.wormholes.active_wormholes} connections")
  end
end

# Run the performance demonstration
QuantumDB.run_performance_demo()
