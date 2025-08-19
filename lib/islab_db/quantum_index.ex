defmodule IsLabDB.QuantumIndex do
  @moduledoc """
  Quantum Index system for managing entangled data relationships.

  This module implements the quantum entanglement mechanics that allow for
  smart pre-fetching of related data. When a quantum-entangled data item
  is observed (accessed), its entangled partners are automatically retrieved
  in parallel, following the principles of quantum mechanics.

  ## Key Features

  - **Quantum Entanglement**: Data items can be entangled with related items
  - **Parallel Fetching**: Entangled data is retrieved using parallel processing
  - **Pattern Matching**: Automatic entanglement based on configurable patterns
  - **Persistence**: Quantum indices are persisted to filesystem for recovery
  - **Performance**: Sub-millisecond entangled data retrieval

  ## Physics Analogy

  In quantum mechanics, observing one particle in an entangled pair instantly
  affects its partner, regardless of distance. Similarly, accessing one data
  item automatically provides information about its entangled partners.
  """

  require Logger
  alias IsLabDB.CosmicPersistence

  # ETS table names for quantum indices
  @primary_index :quantum_primary_index
  @entanglement_map :quantum_entanglement_map
  @pattern_cache :quantum_pattern_cache

  ## PUBLIC API

  @doc """
  Initialize the quantum index system.

  Creates ETS tables and loads existing entanglements from filesystem.
  """
  def initialize_quantum_system() do
    Logger.info("⚛️  Initializing quantum entanglement system...")

    # Create ETS tables for quantum indices
    create_quantum_tables()

    # Load existing entanglements from filesystem
    load_quantum_indices_from_filesystem()

    # Initialize default entanglement patterns
    load_entanglement_patterns()

    Logger.info("✨ Quantum entanglement system ready for superposition")
    :ok
  end

  @doc """
  Create quantum entanglement between data items.

  Establishes bidirectional quantum relationships that enable automatic
  pre-fetching when any entangled item is observed.

  ## Parameters

  - `primary_key` - The primary data item key
  - `entangled_keys` - List of keys to entangle with the primary
  - `strength` - Entanglement strength (0.0 to 1.0, affects fetch probability)
  - `metadata` - Additional quantum metadata

  ## Returns

  `{:ok, entanglement_id}` on success, `{:error, reason}` on failure
  """
  def create_entanglement(primary_key, entangled_keys, strength \\ 1.0, metadata \\ %{}) do
    entanglement_id = generate_entanglement_id(primary_key, entangled_keys)

    entanglement_data = %{
      id: entanglement_id,
      primary_key: primary_key,
      entangled_keys: entangled_keys,
      strength: strength,
      created_at: :os.system_time(:millisecond),
      last_observed: nil,
      observation_count: 0,
      quantum_state: :superposition,
      metadata: metadata
    }

    # Validate inputs
    if primary_key == nil or not is_list(entangled_keys) do
      {:error, :invalid_parameters}
    else
      # Store in primary index
      :ets.insert(@primary_index, {primary_key, entanglement_data})

      # Create bidirectional relationships in entanglement map
      Enum.each(entangled_keys, fn entangled_key ->
        :ets.insert(@entanglement_map, {entangled_key, primary_key, strength})
        :ets.insert(@entanglement_map, {primary_key, entangled_key, strength})
      end)

      # Persist to filesystem
      persist_entanglement_to_filesystem(entanglement_data)

      Logger.debug("🔗 Created quantum entanglement: #{primary_key} <-> #{inspect(entangled_keys)} (strength: #{strength})")

      {:ok, entanglement_id}
    end
  end

  @doc """
  Observe quantum data and retrieve entangled partners.

  This is the core quantum operation that triggers entanglement collapse.
  When a data item is observed, all its quantum entangled partners are
  automatically retrieved in parallel.

  ## Parameters

  - `key` - The primary key being observed
  - `spacetime_tables` - ETS tables for spacetime shards
  - `opts` - Options for quantum observation

  ## Options

  - `:max_entangled` - Maximum number of entangled items to fetch (default: 10)
  - `:min_strength` - Minimum entanglement strength to consider (default: 0.1)
  - `:timeout` - Timeout for parallel fetching in milliseconds (default: 1000)

  ## Returns

  `{:ok, primary_value, entangled_data, quantum_metadata}` on success
  """
  def observe_quantum_data(key, spacetime_tables, opts \\ []) do
    start_time = :os.system_time(:microsecond)

    # Get the primary data
    primary_result = find_in_spacetime_shards(key, spacetime_tables)

    case primary_result do
      {:ok, primary_value, primary_shard} ->
        # Update observation count
        update_observation_count(key)

        # Get entangled keys
        entangled_keys = get_entangled_keys(key, opts)

        # Fetch entangled data in parallel
        entangled_data = if length(entangled_keys) > 0 do
          fetch_entangled_data_parallel(entangled_keys, spacetime_tables, opts)
        else
          %{}
        end

        end_time = :os.system_time(:microsecond)
        operation_time = end_time - start_time

        quantum_metadata = %{
          primary_shard: primary_shard,
          entangled_count: length(entangled_keys),
          quantum_operation_time: operation_time,
          quantum_state: :collapsed,
          entanglement_efficiency: calculate_entanglement_efficiency(entangled_data)
        }

        Logger.debug("⚛️  Quantum observation complete: #{key} + #{length(entangled_keys)} entangled items in #{operation_time}μs")

        {:ok, primary_value, entangled_data, quantum_metadata}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @doc """
  Remove quantum entanglement.

  Breaks the quantum relationship between data items.
  """
  def remove_entanglement(primary_key, entangled_keys \\ :all) do
    case entangled_keys do
      :all ->
        # Remove all entanglements for this key
        :ets.delete(@primary_index, primary_key)
        :ets.match_delete(@entanglement_map, {primary_key, :_, :_})
        :ets.match_delete(@entanglement_map, {:_, primary_key, :_})

      specific_keys when is_list(specific_keys) ->
        # Remove specific entanglements
        Enum.each(specific_keys, fn entangled_key ->
          :ets.match_delete(@entanglement_map, {primary_key, entangled_key, :_})
          :ets.match_delete(@entanglement_map, {entangled_key, primary_key, :_})
        end)
    end

    # Update filesystem
    remove_entanglement_from_filesystem(primary_key, entangled_keys)

    Logger.debug("🔓 Removed quantum entanglement for #{primary_key}")
    :ok
  end

  @doc """
  Get quantum index statistics and metrics.
  """
  def quantum_metrics() do
    # Ensure tables exist before querying for test compatibility
    ensure_tables_exist()

    total_entanglements = :ets.info(@primary_index, :size)
    total_relationships = :ets.info(@entanglement_map, :size)
    patterns_cached = :ets.info(@pattern_cache, :size)

    # Calculate entanglement distribution
    entanglement_strengths = :ets.tab2list(@entanglement_map)
    |> Enum.map(fn {_key1, _key2, strength} -> strength end)

    avg_strength = if length(entanglement_strengths) > 0 do
      Enum.sum(entanglement_strengths) / length(entanglement_strengths)
    else
      0.0
    end

    %{
      total_entanglements: total_entanglements,
      total_quantum_relationships: total_relationships,
      cached_patterns: patterns_cached,
      average_entanglement_strength: avg_strength,
      quantum_efficiency: calculate_quantum_efficiency(),
      superposition_count: count_superposition_states(),
      collapsed_count: count_collapsed_states()
    }
  end

  @doc """
  Apply entanglement patterns to automatically create relationships.

  Uses pattern matching to create quantum entanglements based on
  configurable rules (e.g., "user:*" entangles with "profile:*").
  """
  def apply_entanglement_patterns(key, value) do
    patterns = get_cached_patterns()

    matching_patterns = Enum.filter(patterns, fn {pattern, _targets} ->
      key_matches_pattern?(key, pattern)
    end)

    Enum.each(matching_patterns, fn {_pattern, target_patterns} ->
      entangled_keys = generate_entangled_keys(key, target_patterns, value)

      if length(entangled_keys) > 0 do
        create_entanglement(key, entangled_keys, 0.8, %{auto_generated: true, pattern_based: true})
      end
    end)

    :ok
  end

  ## PRIVATE FUNCTIONS

  defp create_quantum_tables() do
    # Primary index: key -> entanglement data
    :ets.new(@primary_index, [
      :set, :public, :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    # Entanglement map: bidirectional relationships
    :ets.new(@entanglement_map, [
      :bag, :public, :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    # Pattern cache: compiled entanglement patterns
    :ets.new(@pattern_cache, [
      :set, :public, :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])
  end

  defp load_quantum_indices_from_filesystem() do
    # Load existing quantum indices from all shards
    data_root = CosmicPersistence.data_root()

    ["hot_data", "warm_data", "cold_data"]
    |> Enum.each(fn shard ->
      indices_path = Path.join([data_root, "spacetime", shard, "quantum_indices"])

      if File.exists?(indices_path) do
        load_shard_quantum_indices(indices_path, shard)
      end
    end)
  end

  defp load_shard_quantum_indices(indices_path, shard) do
    entanglements_file = Path.join(indices_path, "entanglements.json")

    if File.exists?(entanglements_file) do
      case File.read(entanglements_file) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, entanglements} when is_list(entanglements) ->
              Enum.each(entanglements, fn entanglement ->
                restore_entanglement_from_data(entanglement)
              end)
              Logger.debug("🔄 Restored #{length(entanglements)} quantum entanglements from #{shard}")

            _ ->
              Logger.warning("⚠️  Invalid quantum entanglement data in #{shard}")
          end

        {:error, reason} ->
          Logger.warning("⚠️  Could not read quantum indices from #{shard}: #{reason}")
      end
    end
  end

  defp restore_entanglement_from_data(entanglement_data) do
    primary_key = entanglement_data["primary_key"]
    entangled_keys = entanglement_data["entangled_keys"] || []
    strength = entanglement_data["strength"] || 1.0

    if primary_key && is_list(entangled_keys) do
      # Restore to ETS tables
      :ets.insert(@primary_index, {primary_key, entanglement_data})

      Enum.each(entangled_keys, fn entangled_key ->
        :ets.insert(@entanglement_map, {entangled_key, primary_key, strength})
        :ets.insert(@entanglement_map, {primary_key, entangled_key, strength})
      end)
    end
  end

  defp load_entanglement_patterns() do
    # Load default patterns
    default_patterns = [
      {"user:*", ["profile:*", "settings:*", "sessions:*"]},
      {"order:*", ["customer:*", "products:*", "payment:*"]},
      {"post:*", ["author:*", "comments:*", "tags:*"]},
      {"product:*", ["reviews:*", "inventory:*", "pricing:*"]},
      {"project:*", ["team:*", "tasks:*", "milestones:*"]},
      {"article:*", ["author:*", "categories:*", "related:*"]}
    ]

    Enum.each(default_patterns, fn {pattern, targets} ->
      :ets.insert(@pattern_cache, {pattern, targets})
    end)

    # TODO: Load custom patterns from filesystem configuration
    Logger.debug("📋 Loaded #{length(default_patterns)} quantum entanglement patterns")
  end

  defp find_in_spacetime_shards(key, spacetime_tables) do
    search_order = [:hot_data, :warm_data, :cold_data]

    Enum.find_value(search_order, {:error, :not_found}, fn shard ->
      table = Map.get(spacetime_tables, shard)
      case :ets.lookup(table, key) do
        [{^key, value}] -> {:ok, value, shard}
        [] -> nil
      end
    end)
  end

  defp get_entangled_keys(key, opts) do
    max_entangled = Keyword.get(opts, :max_entangled, 10)
    min_strength = Keyword.get(opts, :min_strength, 0.1)

    :ets.lookup(@entanglement_map, key)
    |> Enum.filter(fn {_primary, _entangled, strength} ->
      strength >= min_strength
    end)
    |> Enum.sort_by(fn {_primary, _entangled, strength} -> -strength end)
    |> Enum.take(max_entangled)
    |> Enum.map(fn {_primary, entangled_key, _strength} -> entangled_key end)
  end

  defp fetch_entangled_data_parallel(entangled_keys, spacetime_tables, opts) do
    timeout = Keyword.get(opts, :timeout, 1000)

    # Use Task.async_stream for parallel fetching
    entangled_keys
    |> Task.async_stream(fn key ->
      case find_in_spacetime_shards(key, spacetime_tables) do
        {:ok, value, shard} -> {key, {:ok, value, shard}}
        {:error, :not_found} -> {key, {:error, :not_found}}
      end
    end, timeout: timeout, on_timeout: :kill_task)
    |> Enum.reduce(%{}, fn
      {:ok, {key, result}}, acc -> Map.put(acc, key, result)
      {:exit, :timeout}, acc -> acc
      _, acc -> acc
    end)
  end

  defp update_observation_count(key) do
    case :ets.lookup(@primary_index, key) do
      [{^key, entanglement_data}] ->
        updated_data = entanglement_data
        |> Map.update(:observation_count, 1, &(&1 + 1))
        |> Map.put(:last_observed, :os.system_time(:millisecond))
        |> Map.put(:quantum_state, :collapsed)

        :ets.insert(@primary_index, {key, updated_data})

      [] ->
        :ok
    end
  end

  defp calculate_entanglement_efficiency(entangled_data) do
    total_requested = map_size(entangled_data)

    if total_requested == 0 do
      1.0
    else
      successful_fetches = entangled_data
      |> Map.values()
      |> Enum.count(fn
        {:ok, _, _} -> true
        _ -> false
      end)

      successful_fetches / total_requested
    end
  end

  defp generate_entanglement_id(primary_key, entangled_keys) do
    combined = "#{primary_key}:#{Enum.join(entangled_keys, ",")}"
    :crypto.hash(:md5, combined) |> Base.encode16(case: :lower)
  end

  defp persist_entanglement_to_filesystem(entanglement_data) do
    # Persist to appropriate shard quantum indices
    Task.start(fn ->
      try do
        primary_key = entanglement_data.primary_key
        _data_type = CosmicPersistence.extract_data_type(primary_key)

        # Determine which shard this belongs to (simplified for now)
        shard = determine_quantum_shard(primary_key)

        indices_path = Path.join([
          CosmicPersistence.data_root(),
          "spacetime",
          Atom.to_string(shard),
          "quantum_indices"
        ])

        File.mkdir_p!(indices_path)

        # Load existing entanglements
        entanglements_file = Path.join(indices_path, "entanglements.json")
        existing = case File.read(entanglements_file) do
          {:ok, content} ->
            case Jason.decode(content) do
              {:ok, list} when is_list(list) -> list
              _ -> []
            end
          _ -> []
        end

        # Add new entanglement (or update existing)
        updated = [entanglement_data | existing]
        |> Enum.uniq_by(fn data ->
          case data do
            %{id: id} -> id
            map when is_map(map) -> map["id"]
            _ -> nil
          end
        end)

        File.write!(entanglements_file, safe_encode_json(updated))

      rescue
        error ->
          Logger.warning("Failed to persist quantum entanglement: #{inspect(error)}")
      end
    end)
  end

  defp remove_entanglement_from_filesystem(_primary_key, _entangled_keys) do
    # TODO: Implement filesystem removal
    # For now, just log the operation
    Logger.debug("🗑️  Quantum entanglement removal from filesystem (TODO)")
    :ok
  end

  defp get_cached_patterns() do
    :ets.tab2list(@pattern_cache)
  end

  # Safe JSON encoding without Jason dependency
  defp safe_encode_json(data) do
    try do
      Jason.encode!(data, pretty: true)
    rescue
      UndefinedFunctionError ->
        # Fallback to readable Elixir format
        inspect(data, pretty: true, limit: :infinity, printable_limit: :infinity)
    end
  end

  defp key_matches_pattern?(key, pattern) do
    # Convert key to string for pattern matching
    key_str = to_string(key)

    # Simple glob-style pattern matching
    case String.split(pattern, "*", parts: 2) do
      [prefix] -> key_str == prefix
      [prefix, suffix] ->
        String.starts_with?(key_str, prefix) and String.ends_with?(key_str, suffix)
      _ -> false
    end
  end

  defp generate_entangled_keys(key, target_patterns, _value) do
    # Extract the identifier from the key
    key_str = to_string(key)
    key_parts = String.split(key_str, ":", parts: 2)

    case key_parts do
      [_type, id] ->
        Enum.map(target_patterns, fn pattern ->
          String.replace(pattern, "*", id)
        end)
      _ ->
        []
    end
  end

  defp calculate_quantum_efficiency() do
    # Simplified quantum efficiency calculation
    total_relationships = :ets.info(@entanglement_map, :size)

    if total_relationships > 0 do
      # Calculate based on relationship density and strength distribution
      strengths = :ets.tab2list(@entanglement_map)
      |> Enum.map(fn {_, _, strength} -> strength end)

      avg_strength = Enum.sum(strengths) / length(strengths)
      min(avg_strength * 1.2, 1.0)
    else
      0.0
    end
  end

  defp count_superposition_states() do
    :ets.tab2list(@primary_index)
    |> Enum.count(fn {_key, data} ->
      Map.get(data, :quantum_state) == :superposition
    end)
  end

  defp count_collapsed_states() do
    :ets.tab2list(@primary_index)
    |> Enum.count(fn {_key, data} ->
      Map.get(data, :quantum_state) == :collapsed
    end)
  end

  defp determine_quantum_shard(key) do
    # Simple hashing to determine shard - could be more sophisticated
    shard_index = :erlang.phash2(key) |> rem(3)
    case shard_index do
      0 -> :hot_data
      1 -> :warm_data
      2 -> :cold_data
    end
  end

  # Ensure ETS tables exist for test compatibility
  defp ensure_tables_exist() do
    unless :ets.whereis(@primary_index) != :undefined do
      initialize_quantum_system()
    end
  end
end
