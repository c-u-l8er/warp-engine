defmodule IsLabDB.CosmicPersistence do
  @moduledoc """
  Elegant filesystem persistence that mirrors the structure of the universe.

  Creates and manages the cosmic directory structure in `/data` that serves as
  the persistent foundation for the physics-inspired database. Each directory
  represents a different aspect of the computational universe:

  - `spacetime/` - Core data shards with different energy levels
  - `temporal/` - Time-series data across different time scales
  - `quantum_graph/` - Graph database structures with quantum properties
  - `wormholes/` - Network topology and routing optimization
  - `entropy/` - System monitoring and load balancing
  - `observatory/` - Metrics and observability data
  - `configuration/` - Universe configuration and physics parameters
  """

    require Logger

  @default_data_root "/data"

  @doc """
  Get the configured data root directory, with fallback to default.
  """
  def data_root do
    Application.get_env(:islab_db, :data_root, @default_data_root)
  end

  @doc """
  Initialize the complete cosmic filesystem structure.

  Creates all necessary directories and manifest files that define
  the computational universe's persistent state.
  """
  def initialize_universe() do
    Logger.info("🌌 Initializing cosmic filesystem structure...")

    create_cosmic_directories()
    create_universe_manifest()

        Logger.info("✨ Cosmic structure ready at #{data_root()}")
    :ok
  end

  @doc """
  Create a cosmic record with full metadata for persistence.
  """
  def create_cosmic_record(key, value, shard, additional_metadata \\ %{}) do
    %{
      key: key,
      value: value,
      cosmic_metadata: %{
        shard: shard,
        stored_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        access_count: 1,
        cosmic_coordinates: calculate_cosmic_coordinates(key, value),
        data_type: extract_data_type(key),
        energy_level: calculate_energy_level(key, value),
        quantum_state: :ground,
        entangled_keys: [],
        temporal_weight: 1.0
      }
    }
    |> Map.merge(additional_metadata)
  end

  @doc """
  Extract data type from a key for filesystem organization.
  """
  def extract_data_type(key) when is_binary(key) do
    case String.split(key, ":", parts: 2) do
      [type, _id] -> type
      _ -> "general"
    end
  end
  def extract_data_type(_key), do: "general"

  @doc """
  Persist a cosmic record to the appropriate filesystem location.
  """
  def persist_cosmic_record(cosmic_record, data_type \\ nil) do
    try do
      shard = cosmic_record.cosmic_metadata.shard
      data_type = data_type || cosmic_record.cosmic_metadata.data_type
      key = cosmic_record.key

            # Create file path in cosmic structure
      file_path = Path.join([
        data_root(),
        "spacetime",
        Atom.to_string(shard),
        "particles",
        data_type,
        "#{sanitize_filename(key)}.json"
      ])

      # Ensure directory exists
      File.mkdir_p!(Path.dirname(file_path))

      # Write cosmic record with pretty formatting for human readability
      File.write!(file_path, Jason.encode!(cosmic_record, pretty: true))

      # Update shard manifest
      update_shard_manifest(shard, key, file_path, cosmic_record)

      {:ok, file_path}
    rescue
      error ->
        Logger.warning("Failed to persist cosmic record for #{cosmic_record.key}: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Delete a cosmic record from the filesystem.
  """
  def delete_cosmic_record(key, shard, data_type) do
    try do
      file_path = Path.join([
        data_root(),
        "spacetime",
        Atom.to_string(shard),
        "particles",
        data_type,
        "#{sanitize_filename(key)}.json"
      ])

      if File.exists?(file_path) do
        File.rm!(file_path)
        update_shard_manifest_deletion(shard, key)
        {:ok, :deleted}
      else
        {:ok, :not_found}
      end
    rescue
      error ->
        Logger.warning("Failed to delete cosmic record for #{key}: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Load a cosmic record from the filesystem.
  """
  def load_cosmic_record(key, shard, data_type) do
    file_path = Path.join([
      data_root(),
      "spacetime",
      Atom.to_string(shard),
      "particles",
      data_type,
      "#{sanitize_filename(key)}.json"
    ])

    case File.read(file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, cosmic_record} -> {:ok, cosmic_record}
          {:error, reason} -> {:error, {:json_decode, reason}}
        end
      {:error, :enoent} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, {:file_read, reason}}
    end
  end

  ## PRIVATE FUNCTIONS

  defp create_cosmic_directories() do
    cosmic_structure = [
      # Spacetime shards for core data storage
      "spacetime/hot_data/particles/users",
      "spacetime/hot_data/particles/products",
      "spacetime/hot_data/particles/orders",
      "spacetime/hot_data/particles/sessions",
      "spacetime/hot_data/quantum_indices",
      "spacetime/hot_data/event_horizon",

      "spacetime/warm_data/particles/profiles",
      "spacetime/warm_data/particles/settings",
      "spacetime/warm_data/particles/analytics",
      "spacetime/warm_data/quantum_indices",
      "spacetime/warm_data/event_horizon",

      "spacetime/cold_data/particles/archives",
      "spacetime/cold_data/particles/backups",
      "spacetime/cold_data/particles/historical",
      "spacetime/cold_data/quantum_indices",
      "spacetime/cold_data/event_horizon",

      # Temporal shards for time-series data
      "temporal/live",
      "temporal/recent",
      "temporal/historical",

      # Quantum graph structures
      "quantum_graph/nodes/persons",
      "quantum_graph/nodes/organizations",
      "quantum_graph/nodes/concepts",
      "quantum_graph/edges/relationships",
      "quantum_graph/dimensions",
      "quantum_graph/entanglements",

      # Wormhole network for routing optimization
      "wormholes/routing_tables",
      "wormholes/active_connections",

      # Entropy monitoring for load balancing
      "entropy/current_state",
      "entropy/historical_data",
      "entropy/rebalancing_logs",

      # Query language compilation
      "qql/compiled_queries",
      "qql/query_analytics",
      "qql/schema_definitions",

      # Backup and recovery
      "backups/snapshots",
      "backups/incremental",
      "backups/cosmic_logs",

      # Observability and monitoring
      "observatory/metrics",
      "observatory/logs",
      "observatory/diagnostics",

      # Configuration management
      "configuration"
    ]

    Enum.each(cosmic_structure, fn path ->
      full_path = Path.join(data_root(), path)
      File.mkdir_p!(full_path)
      create_directory_manifest(full_path, path)
    end)
  end

  defp create_universe_manifest() do
    manifest = %{
      universe_version: "1.0.0",
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      physics_engine: "IsLabDB v1.0",
      cosmic_constants: IsLabDB.CosmicConstants.all_constants(),
      spacetime_shards: [
        %{
          name: "hot_data",
          physics_laws: %{
            consistency_model: :strong,
            time_dilation: 0.5,
            attraction: 2.0,
            cache_limit: 50_000
          }
        },
        %{
          name: "warm_data",
          physics_laws: %{
            consistency_model: :eventual,
            time_dilation: 1.0,
            attraction: 1.0,
            cache_limit: 20_000
          }
        },
        %{
          name: "cold_data",
          physics_laws: %{
            consistency_model: :weak,
            time_dilation: 2.0,
            attraction: 0.3,
            cache_limit: 5_000
          }
        }
      ],
      persistence_strategy: "multi_format_elegant",
      data_formats: %{
        json: "Human-readable structured data",
        erl: "Binary Erlang terms for speed",
        jsonl: "Line-delimited JSON for streaming",
        csv: "Time-series metrics data",
        compressed: "Historical data with compression"
      }
    }

    manifest_path = Path.join(data_root(), "universe.manifest")
    File.write!(manifest_path, Jason.encode!(manifest, pretty: true))
  end

      defp create_directory_manifest(full_path, cosmic_path) do
    manifest = %{
      cosmic_location: cosmic_path,
      physics_description: describe_cosmic_region(cosmic_path),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      data_format: determine_data_format(cosmic_path),
      purpose: describe_purpose(cosmic_path),
      access_patterns: determine_access_patterns(cosmic_path)
    }

    manifest_path = Path.join(full_path, "_manifest.json")
    File.write!(manifest_path, Jason.encode!(manifest, pretty: true))
  end

  defp describe_cosmic_region("spacetime/hot_data" <> _),
    do: "High-energy spacetime region for frequently accessed data with strong consistency"
  defp describe_cosmic_region("spacetime/warm_data" <> _),
    do: "Moderate-energy spacetime region for balanced access with eventual consistency"
  defp describe_cosmic_region("spacetime/cold_data" <> _),
    do: "Low-energy spacetime region for archived data with weak consistency and compression"
  defp describe_cosmic_region("temporal" <> _),
    do: "Time-based data streams and historical records with temporal physics"
  defp describe_cosmic_region("quantum_graph" <> _),
    do: "Graph database structures with quantum entanglement properties"
  defp describe_cosmic_region("wormholes" <> _),
    do: "Network topology and routing optimization with adaptive pathfinding"
  defp describe_cosmic_region("entropy" <> _),
    do: "System entropy monitoring and thermodynamic load balancing"
  defp describe_cosmic_region("observatory" <> _),
    do: "System monitoring, metrics collection and cosmic observability"
  defp describe_cosmic_region("configuration"),
    do: "Universe configuration and fundamental physics parameters"
  defp describe_cosmic_region(_),
    do: "General cosmic data storage region with standard physics"

  defp determine_data_format("spacetime" <> _), do: "JSON records with quantum properties and cosmic metadata"
  defp determine_data_format("temporal" <> _), do: "Time-series data in JSONL and compressed formats"
  defp determine_data_format("quantum_graph" <> _), do: "Graph structures with dimensional coordinates"
  defp determine_data_format("wormholes" <> _), do: "Network topology in binary and JSON formats"
  defp determine_data_format("entropy" <> _), do: "Real-time metrics and CSV time-series data"
  defp determine_data_format("qql" <> _), do: "Compiled query bytecode and analytics"
  defp determine_data_format(_), do: "Mixed format optimized for specific use case"

  defp describe_purpose("particles"), do: "Individual data records organized by type with cosmic metadata"
  defp describe_purpose("quantum_indices"), do: "Entangled key relationships and quantum indices"
  defp describe_purpose("event_horizon"), do: "Cache management with black hole mechanics and compression"
  defp describe_purpose("nodes"), do: "Quantum graph nodes with dimensional coordinates"
  defp describe_purpose("edges"), do: "Graph relationships with temporal decay and strength"
  defp describe_purpose("routing_tables"), do: "Wormhole network routing optimization tables"
  defp describe_purpose("metrics"), do: "Real-time system performance and cosmic health metrics"
  defp describe_purpose(_), do: "Specialized cosmic data storage with physics-inspired optimization"

  defp determine_access_patterns("hot_data" <> _), do: %{read_frequency: "very_high", write_frequency: "high", consistency: "strong"}
  defp determine_access_patterns("warm_data" <> _), do: %{read_frequency: "medium", write_frequency: "medium", consistency: "eventual"}
  defp determine_access_patterns("cold_data" <> _), do: %{read_frequency: "low", write_frequency: "very_low", consistency: "weak"}
  defp determine_access_patterns("temporal/live" <> _), do: %{read_frequency: "very_high", write_frequency: "continuous", consistency: "strong"}
  defp determine_access_patterns("temporal/recent" <> _), do: %{read_frequency: "high", write_frequency: "batch", consistency: "eventual"}
  defp determine_access_patterns("temporal/historical" <> _), do: %{read_frequency: "low", write_frequency: "rare", consistency: "weak"}
  defp determine_access_patterns(_), do: %{read_frequency: "medium", write_frequency: "medium", consistency: "eventual"}



  defp sanitize_filename(key) do
    key
    |> to_string()
    |> String.replace(~r/[^\w\-_.]/, "_")
    |> String.replace(~r/_+/, "_")
    |> String.trim("_")
  end

  defp calculate_cosmic_coordinates(key, value) do
    # Calculate multi-dimensional coordinates for the data in cosmic space
    key_hash = :erlang.phash2(key)
    value_hash = :erlang.phash2(value)
    combined_hash = key_hash + value_hash

    %{
      x: :math.sin(key_hash * 0.01),
      y: :math.cos(value_hash * 0.01),
      z: :math.sin(combined_hash * 0.005),
      w: :math.cos(combined_hash * 0.003),
      energy_level: rem(key_hash, 100) / 100.0,
      temporal_signature: rem(value_hash, 1000) / 1000.0,
      quantum_phase: :math.sin((key_hash + value_hash) * 0.001),
      dimensional_entropy: calculate_dimensional_entropy(key, value)
    }
  end

  defp calculate_energy_level(key, value) do
    # Calculate quantum energy level based on data characteristics
    base_energy = IsLabDB.CosmicConstants.quantum_energy_level(1.0)

    # Factor in key complexity and value size
    key_complexity = byte_size(to_string(key)) / 100.0
    value_complexity = :erlang.external_size(value) / 1000.0

    base_energy * (1.0 + key_complexity + value_complexity)
  end

  defp calculate_dimensional_entropy(key, value) do
    # Calculate entropy of the data for dimensional positioning
    key_entropy = calculate_string_entropy(to_string(key))
    value_entropy = calculate_data_entropy(value)

    (key_entropy + value_entropy) / 2.0
  end

  defp calculate_string_entropy(string) do
    # Shannon entropy calculation for strings
    char_frequencies =
      string
      |> String.graphemes()
      |> Enum.frequencies()
      |> Map.values()

    total_chars = String.length(string)

    if total_chars == 0 do
      0.0
    else
      char_frequencies
      |> Enum.map(fn freq ->
        probability = freq / total_chars
        if probability > 0, do: -probability * :math.log2(probability), else: 0.0
      end)
      |> Enum.sum()
    end
  end

  defp calculate_data_entropy(data) do
    # Simplified entropy calculation for arbitrary data
    data_size = :erlang.external_size(data)
    data_hash = :erlang.phash2(data)

    # Use hash distribution as entropy approximation
    hash_entropy = rem(data_hash, 256) / 256.0
    size_factor = min(data_size / 1000.0, 1.0)

    hash_entropy * size_factor
  end

  defp update_shard_manifest(shard, key, file_path, cosmic_record) do
    shard_manifest_path = Path.join([
      data_root(),
      "spacetime",
      Atom.to_string(shard),
      "_shard_manifest.json"
    ])

    # Load existing manifest or create new one
    existing_manifest = case File.read(shard_manifest_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, manifest} -> manifest
          _ -> create_empty_shard_manifest(shard)
        end
      _ ->
        create_empty_shard_manifest(shard)
    end

    # Update with new record
    updated_manifest = existing_manifest
    |> Map.put("last_updated", DateTime.utc_now() |> DateTime.to_iso8601())
    |> Map.update("total_records", 1, &(&1 + 1))
    |> Map.update("data_types", %{}, fn types ->
      data_type = cosmic_record.cosmic_metadata.data_type
      Map.update(types, data_type, 1, &(&1 + 1))
    end)
    |> Map.update("recent_keys", [], fn keys ->
      # Keep last 100 keys for debugging
      [key | Enum.take(keys, 99)]
    end)
    |> Map.put("total_size_bytes", File.stat!(file_path).size)

    File.write!(shard_manifest_path, Jason.encode!(updated_manifest, pretty: true))
  end

  defp update_shard_manifest_deletion(shard, key) do
    shard_manifest_path = Path.join([
      data_root(),
      "spacetime",
      Atom.to_string(shard),
      "_shard_manifest.json"
    ])

    case File.read(shard_manifest_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, manifest} ->
            updated_manifest = manifest
            |> Map.put("last_updated", DateTime.utc_now() |> DateTime.to_iso8601())
            |> Map.update("total_records", 0, &max(0, &1 - 1))
            |> Map.update("recent_deletions", [], fn deletions ->
              [key | Enum.take(deletions, 99)]
            end)

            File.write!(shard_manifest_path, Jason.encode!(updated_manifest, pretty: true))
          _ ->
            :ok
        end
      _ ->
        :ok
    end
  end

  defp create_empty_shard_manifest(shard) do
    %{
      "shard_id" => shard,
      "created_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "last_updated" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "total_records" => 0,
      "data_types" => %{},
      "recent_keys" => [],
      "recent_deletions" => [],
      "total_size_bytes" => 0,
      "physics_laws" => get_shard_physics_laws(shard)
    }
  end

  defp get_shard_physics_laws(:hot_data) do
    %{
      consistency_model: "strong",
      time_dilation: 0.5,
      attraction: 2.0,
      cache_limit: 50_000,
      energy_level: "high"
    }
  end
  defp get_shard_physics_laws(:warm_data) do
    %{
      consistency_model: "eventual",
      time_dilation: 1.0,
      attraction: 1.0,
      cache_limit: 20_000,
      energy_level: "medium"
    }
  end
  defp get_shard_physics_laws(:cold_data) do
    %{
      consistency_model: "weak",
      time_dilation: 2.0,
      attraction: 0.3,
      cache_limit: 5_000,
      energy_level: "low"
    }
  end
  defp get_shard_physics_laws(_shard) do
    %{
      consistency_model: "eventual",
      time_dilation: 1.0,
      attraction: 1.0,
      cache_limit: 10_000,
      energy_level: "medium"
    }
  end
end
