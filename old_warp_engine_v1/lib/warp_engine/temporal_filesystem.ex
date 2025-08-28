defmodule WarpEngine.TemporalFilesystem do
  @moduledoc """
  Temporal Data Filesystem Management for WarpEngine Database Phase 7

  This module implements the enhanced filesystem structure for temporal data management,
  extending the existing cosmic filesystem with time-based hierarchical organization.

  ## Enhanced Filesystem Structure

  ```
  /data/
  ├── wal/                        # Phase 6.6 WAL system
  ├── spacetime/                  # Existing spacetime shards
  ├── temporal/                   # NEW: Temporal data management
  │   ├── live/                   # Real-time data (last hour)
  │   │   ├── streams/            # Active data streams
  │   │   │   ├── metrics.stream  # Live metrics stream
  │   │   │   └── events.stream   # Live events stream
  │   │   ├── indices/            # Real-time indices
  │   │   └── checkpoints/        # Live data checkpoints
  │   ├── recent/                 # Recent data (last 24-48 hours)
  │   │   ├── hourly/             # Hour-based partitions
  │   │   │   ├── 2025-01-20-14/  # Specific hour partition
  │   │   │   │   ├── data.wal    # Hour's WAL data
  │   │   │   │   ├── indices.idx # Hour's indices
  │   │   │   │   └── summary.json# Hour summary
  │   │   │   └── manifest.json   # Hourly manifest
  │   │   └── aggregations/       # Recent data aggregations
  │   ├── historical/             # Long-term storage (7+ days)
  │   │   ├── daily/              # Day-based partitions
  │   │   │   ├── 2025-01-15/     # Daily partition
  │   │   │   │   ├── compressed.lz4 # Compressed data
  │   │   │   │   ├── indices.btree  # Binary tree indices
  │   │   │   │   └── analytics.json # Daily analytics
  │   │   │   └── manifest.json   # Daily manifest
  │   │   ├── monthly/            # Month-based archives
  │   │   └── yearly/             # Long-term archives
  │   └── configuration/          # Temporal physics laws
  │       ├── lifecycle_rules.json # Data lifecycle configuration
  │       ├── compression_rules.json # Compression strategies
  │       └── retention_policies.json # Data retention policies
  ```

  ## Features

  - **Hierarchical Time Organization**: Live -> Recent -> Historical -> Deep Time
  - **Automatic Directory Management**: Creates and maintains temporal structure
  - **Compression Integration**: Manages compressed historical data
  - **Manifest System**: Tracks temporal data organization and metadata
  - **Physics Integration**: Applies temporal physics laws to filesystem organization
  """

  require Logger
  alias WarpEngine.CosmicPersistence

  ## FILESYSTEM STRUCTURE CONSTANTS

  @temporal_root "temporal"
  @time_periods [:live, :recent, :historical, :deep_time]

  @directory_structure %{
    live: [
      "streams",
      "indices",
      "checkpoints"
    ],
    recent: [
      "hourly",
      "aggregations"
    ],
    historical: [
      "daily",
      "monthly",
      "yearly"
    ],
    deep_time: [
      "yearly",
      "compressed",
      "archived"
    ],
    configuration: [
      "lifecycle_rules.json",
      "compression_rules.json",
      "retention_policies.json"
    ]
  }

  ## PUBLIC API

  @doc """
  Initialize the temporal filesystem structure.
  Creates all necessary directories and configuration files.
  """
  def initialize_temporal_filesystem() do
    Logger.info("🗂️  Initializing temporal filesystem structure...")

    try do
      data_root = CosmicPersistence.data_root()
      temporal_root_path = Path.join(data_root, @temporal_root)

      # Create temporal root directory
      File.mkdir_p!(temporal_root_path)

      # Create time period directories
      Enum.each(@time_periods, fn period ->
        create_time_period_structure(temporal_root_path, period)
      end)

      # Create configuration directory and files
      create_configuration_structure(temporal_root_path)

      # Create temporal manifest
      create_temporal_manifest(temporal_root_path)

      Logger.info("✅ Temporal filesystem initialized successfully")
      {:ok, temporal_root_path}

    rescue
      error ->
        Logger.error("❌ Failed to initialize temporal filesystem: #{inspect(error)}")
        {:error, {:initialization_failed, error}}
    end
  end

  @doc """
  Get the path for a specific temporal time period.
  """
  def get_time_period_path(time_period) when time_period in @time_periods do
    data_root = CosmicPersistence.data_root()
    Path.join([data_root, @temporal_root, Atom.to_string(time_period)])
  end

  @doc """
  Create a new temporal partition directory for time-based data organization.

  ## Examples
      {:ok, path} = TemporalFilesystem.create_temporal_partition(:recent, :hourly, "2025-01-20-14")
      {:ok, path} = TemporalFilesystem.create_temporal_partition(:historical, :daily, "2025-01-15")
  """
  def create_temporal_partition(time_period, partition_type, partition_id) do
    try do
      base_path = get_time_period_path(time_period)
      partition_path = Path.join([base_path, Atom.to_string(partition_type), partition_id])

      # Create partition directory
      File.mkdir_p!(partition_path)

      # Create partition-specific structure
      create_partition_structure(partition_path, time_period, partition_type)

      # Create partition manifest
      create_partition_manifest(partition_path, time_period, partition_type, partition_id)

      Logger.debug("📁 Created temporal partition: #{partition_path}")
      {:ok, partition_path}

    rescue
      error ->
        Logger.error("❌ Failed to create temporal partition: #{inspect(error)}")
        {:error, {:partition_creation_failed, error}}
    end
  end

  @doc """
  Get temporal data file path with automatic directory creation.
  """
  def get_temporal_data_path(time_period, partition_type, partition_id, filename) do
    try do
      # Ensure partition exists
      case create_temporal_partition(time_period, partition_type, partition_id) do
        {:ok, partition_path} ->
          file_path = Path.join(partition_path, filename)
          {:ok, file_path}

        {:error, reason} ->
          {:error, reason}
      end

    rescue
      error ->
        {:error, {:path_creation_failed, error}}
    end
  end

  @doc """
  Store temporal data to the filesystem with compression and indexing.
  """
  def store_temporal_data(time_period, partition_type, partition_id, filename, data, opts \\ []) do
    try do
      case get_temporal_data_path(time_period, partition_type, partition_id, filename) do
        {:ok, file_path} ->
          # Apply compression based on time period
          processed_data = maybe_compress_data(data, time_period, opts)

          # Write data to file
          File.write!(file_path, processed_data)

          # Update partition manifest
          update_partition_manifest(time_period, partition_type, partition_id, filename, data)

          # Create/update indices if needed
          if Keyword.get(opts, :create_index, false) do
            create_temporal_index(time_period, partition_type, partition_id, filename, data)
          end

          Logger.debug("💾 Stored temporal data: #{file_path}")
          {:ok, file_path, byte_size(processed_data)}

        {:error, reason} ->
          {:error, reason}
      end

    rescue
      error ->
        Logger.error("❌ Failed to store temporal data: #{inspect(error)}")
        {:error, {:storage_failed, error}}
    end
  end

  @doc """
  Load temporal data from the filesystem with automatic decompression.
  """
  def load_temporal_data(time_period, partition_type, partition_id, filename, opts \\ []) do
    try do
      case get_temporal_data_path(time_period, partition_type, partition_id, filename) do
        {:ok, file_path} ->
          case File.read(file_path) do
            {:ok, raw_data} ->
              # Apply decompression based on time period
              processed_data = maybe_decompress_data(raw_data, time_period, opts)

              Logger.debug("📖 Loaded temporal data: #{file_path}")
              {:ok, processed_data}

            {:error, reason} ->
              {:error, {:file_read_failed, reason}}
          end

        {:error, reason} ->
          {:error, reason}
      end

    rescue
      error ->
        Logger.error("❌ Failed to load temporal data: #{inspect(error)}")
        {:error, {:loading_failed, error}}
    end
  end

  @doc """
  Get comprehensive temporal filesystem metrics.
  """
  def get_temporal_filesystem_metrics() do
    try do
      data_root = CosmicPersistence.data_root()
      temporal_root_path = Path.join(data_root, @temporal_root)

      if File.exists?(temporal_root_path) do
        metrics = %{
          temporal_root_path: temporal_root_path,
          total_size_bytes: calculate_directory_size(temporal_root_path),
          time_periods: collect_time_period_metrics(temporal_root_path),
          partition_count: count_temporal_partitions(temporal_root_path),
          compression_ratios: calculate_compression_ratios(temporal_root_path),
          last_updated: get_last_modification_time(temporal_root_path)
        }

        {:ok, metrics}
      else
        {:error, :temporal_filesystem_not_initialized}
      end

    rescue
      error ->
        {:error, {:metrics_collection_failed, error}}
    end
  end

  ## PRIVATE FUNCTIONS

  defp create_time_period_structure(temporal_root_path, time_period) do
    period_path = Path.join(temporal_root_path, Atom.to_string(time_period))
    File.mkdir_p!(period_path)

    # Create subdirectories for this time period
    subdirectories = Map.get(@directory_structure, time_period, [])

    Enum.each(subdirectories, fn subdir ->
      subdir_path = Path.join(period_path, subdir)
      File.mkdir_p!(subdir_path)
    end)

    Logger.debug("📁 Created time period structure: #{time_period}")
  end

  defp create_configuration_structure(temporal_root_path) do
    config_path = Path.join(temporal_root_path, "configuration")
    File.mkdir_p!(config_path)

    # Create default configuration files
    default_configs = %{
      "lifecycle_rules.json" => create_default_lifecycle_rules(),
      "compression_rules.json" => create_default_compression_rules(),
      "retention_policies.json" => create_default_retention_policies()
    }

    Enum.each(default_configs, fn {filename, content} ->
      file_path = Path.join(config_path, filename)
      unless File.exists?(file_path) do
        File.write!(file_path, safe_encode_json(content))
      end
    end)

    Logger.debug("⚙️  Created configuration structure")
  end

  defp create_temporal_manifest(temporal_root_path) do
    manifest_path = Path.join(temporal_root_path, "temporal_manifest.json")

    manifest_data = %{
      version: "7.0.0",
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      temporal_structure: @directory_structure,
      time_periods: @time_periods,
      physics_integration: true,
      wal_integration: true,
      compression_enabled: true,
      last_updated: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    File.write!(manifest_path, safe_encode_json(manifest_data))
    Logger.debug("📄 Created temporal manifest")
  end

  defp create_partition_structure(partition_path, time_period, partition_type) do
    # Create partition-specific files and directories
    case {time_period, partition_type} do
      {:recent, :hourly} ->
        # Create hourly partition structure
        File.touch!(Path.join(partition_path, "data.wal"))
        File.touch!(Path.join(partition_path, "indices.idx"))

      {:historical, :daily} ->
        # Create daily partition structure
        File.mkdir_p!(Path.join(partition_path, "indices"))
        File.touch!(Path.join(partition_path, "analytics.json"))

      {:historical, :monthly} ->
        # Create monthly partition structure
        File.mkdir_p!(Path.join(partition_path, "compressed"))
        File.mkdir_p!(Path.join(partition_path, "summaries"))

      _ ->
        # Default structure
        :ok
    end
  end

  defp create_partition_manifest(partition_path, time_period, partition_type, partition_id) do
    manifest_path = Path.join(partition_path, "partition_manifest.json")

    manifest_data = %{
      partition_id: partition_id,
      time_period: time_period,
      partition_type: partition_type,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      data_files: [],
      indices: [],
      compression_applied: false,
      total_size_bytes: 0,
      record_count: 0,
      physics_metadata: %{
        temporal_entropy: 0.0,
        lifecycle_stage: determine_lifecycle_stage(time_period),
        compression_eligible: time_period in [:historical, :deep_time]
      }
    }

    File.write!(manifest_path, safe_encode_json(manifest_data))
  end

  defp update_partition_manifest(time_period, partition_type, partition_id, filename, data) do
    Task.start(fn ->
      try do
        partition_path = Path.join([
          CosmicPersistence.data_root(),
          @temporal_root,
          Atom.to_string(time_period),
          Atom.to_string(partition_type),
          partition_id
        ])

        manifest_path = Path.join(partition_path, "partition_manifest.json")

        if File.exists?(manifest_path) do
          case File.read(manifest_path) do
            {:ok, content} ->
              case safe_decode_json(content) do
                {:ok, manifest} ->
                  # Update manifest with new file information
                  updated_manifest = manifest
                  |> update_in(["data_files"], fn files ->
                    [filename | (files || [])] |> Enum.uniq()
                  end)
                  |> Map.put("last_updated", DateTime.utc_now() |> DateTime.to_iso8601())
                  |> Map.put("record_count", (manifest["record_count"] || 0) + 1)
                  |> Map.put("total_size_bytes",
                    (manifest["total_size_bytes"] || 0) + byte_size(:erlang.term_to_binary(data)))

                  File.write!(manifest_path, safe_encode_json(updated_manifest))

                {:error, _} ->
                  Logger.warning("Failed to parse partition manifest: #{manifest_path}")
              end

            {:error, _} ->
              Logger.warning("Failed to read partition manifest: #{manifest_path}")
          end
        end

      rescue
        error ->
          Logger.warning("Failed to update partition manifest: #{inspect(error)}")
      end
    end)
  end

  defp create_temporal_index(_time_period, _partition_type, _partition_id, _filename, _data) do
    # Placeholder for temporal index creation
    # This could be enhanced with B-tree or other index structures
    :ok
  end

  defp maybe_compress_data(data, time_period, opts) do
    should_compress = case time_period do
      :live -> false
      :recent -> Keyword.get(opts, :compress, false)
      :historical -> Keyword.get(opts, :compress, true)
      :deep_time -> Keyword.get(opts, :compress, true)
    end

    if should_compress do
      # Apply compression for speed (fallback to erlang term compression)
      try do
        # Use erlang term compression as fallback since :lz4 may not be available
        compressed = :erlang.term_to_binary(data, [:compressed])
        Logger.debug("📦 Applied compression: #{byte_size(:erlang.term_to_binary(data))} -> #{byte_size(compressed)} bytes")
        compressed
      rescue
        _ ->
          Logger.warning("Compression failed, storing uncompressed")
          data
      end
    else
      data
    end
  end

  defp maybe_decompress_data(data, time_period, opts) do
    should_decompress = case time_period do
      :live -> false
      :recent -> Keyword.get(opts, :compressed, false)
      :historical -> Keyword.get(opts, :compressed, true)
      :deep_time -> Keyword.get(opts, :compressed, true)
    end

    if should_decompress do
      try do
        # Use erlang term decompression as fallback since :lz4 may not be available
        :erlang.binary_to_term(data)
      rescue
        _ ->
          Logger.warning("Decompression failed, returning raw data")
          data
      end
    else
      data
    end
  end

  defp calculate_directory_size(directory_path) do
    try do
      {result, _} = System.cmd("du", ["-sb", directory_path])
      result
      |> String.split("\t")
      |> List.first()
      |> String.to_integer()
    rescue
      _ -> 0
    end
  end

  defp collect_time_period_metrics(temporal_root_path) do
    Enum.map(@time_periods, fn period ->
      period_path = Path.join(temporal_root_path, Atom.to_string(period))

      if File.exists?(period_path) do
        {period, %{
          path: period_path,
          size_bytes: calculate_directory_size(period_path),
          file_count: count_files_recursive(period_path),
          last_modified: get_last_modification_time(period_path)
        }}
      else
        {period, %{exists: false}}
      end
    end)
    |> Map.new()
  end

  defp count_temporal_partitions(temporal_root_path) do
    try do
      @time_periods
      |> Enum.map(fn period ->
        period_path = Path.join(temporal_root_path, Atom.to_string(period))
        if File.exists?(period_path) do
          count_partitions_in_period(period_path)
        else
          0
        end
      end)
      |> Enum.sum()
    rescue
      _ -> 0
    end
  end

  defp count_partitions_in_period(period_path) do
    try do
      case File.ls(period_path) do
        {:ok, entries} ->
          entries
          |> Enum.filter(fn entry ->
            full_path = Path.join(period_path, entry)
            File.dir?(full_path) and not String.starts_with?(entry, ".")
          end)
          |> length()

        {:error, _} -> 0
      end
    rescue
      _ -> 0
    end
  end

  defp calculate_compression_ratios(_temporal_root_path) do
    # Simplified compression ratio calculation
    # In a real implementation, this would analyze compressed vs uncompressed sizes
    %{
      recent: 0.8,
      historical: 0.5,
      deep_time: 0.2
    }
  end

  defp count_files_recursive(directory_path) do
    try do
      case File.ls(directory_path) do
        {:ok, entries} ->
          entries
          |> Enum.map(fn entry ->
            full_path = Path.join(directory_path, entry)
            if File.dir?(full_path) do
              count_files_recursive(full_path)
            else
              1
            end
          end)
          |> Enum.sum()

        {:error, _} -> 0
      end
    rescue
      _ -> 0
    end
  end

  defp get_last_modification_time(path) do
    try do
      case File.stat(path) do
        {:ok, %{mtime: mtime}} ->
          mtime
          |> NaiveDateTime.from_erl!()
          |> DateTime.from_naive!("Etc/UTC")
          |> DateTime.to_iso8601()

        {:error, _} -> nil
      end
    rescue
      _ -> nil
    end
  end

  defp determine_lifecycle_stage(time_period) do
    case time_period do
      :live -> "active"
      :recent -> "warm"
      :historical -> "cool"
      :deep_time -> "frozen"
    end
  end

  # Default configuration creators

  defp create_default_lifecycle_rules() do
    %{
      version: "7.0.0",
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      rules: %{
        live_to_recent_hours: 1,
        recent_to_historical_hours: 48,
        historical_to_deep_time_days: 30
      },
      transitions: %{
        automatic: true,
        check_interval_minutes: 15,
        batch_size: 1000
      },
      physics_integration: %{
        entropy_based_transitions: true,
        gravitational_decay: true,
        quantum_coherence_limits: true
      }
    }
  end

  defp create_default_compression_rules() do
    %{
      version: "7.0.0",
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      algorithms: %{
        recent: %{algorithm: "lz4", level: 3, threshold_bytes: 1024},
        historical: %{algorithm: "lz4", level: 6, threshold_bytes: 512},
        deep_time: %{algorithm: "lz4", level: 9, threshold_bytes: 256}
      },
      physics_optimization: %{
        entropy_based_compression: true,
        temporal_mass_consideration: true,
        adaptive_compression_ratio: true
      }
    }
  end

  defp create_default_retention_policies() do
    %{
      version: "7.0.0",
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      policies: %{
        live: %{retention_hours: 1, archive_policy: "transition"},
        recent: %{retention_hours: 48, archive_policy: "transition"},
        historical: %{retention_days: 365, archive_policy: "compress_and_keep"},
        deep_time: %{retention_years: 7, archive_policy: "long_term_storage"}
      },
      enforcement: %{
        automatic_cleanup: true,
        cleanup_interval_hours: 4,
        physics_based_prioritization: true
      }
    }
  end

  # Safe JSON encoding/decoding
  defp safe_encode_json(data) do
    try do
      Jason.encode!(data, pretty: true)
    rescue
      UndefinedFunctionError ->
        inspect(data, pretty: true, limit: :infinity, printable_limit: :infinity)
    end
  end

  defp safe_decode_json(content) when is_binary(content) do
    try do
      case Jason.decode(content) do
        {:ok, data} -> {:ok, data}
        {:error, reason} -> {:error, reason}
      end
    rescue
      UndefinedFunctionError ->
        try do
          {data, _} = Code.eval_string(content)
          {:ok, data}
        rescue
          _ -> {:error, "Unable to decode JSON"}
        end
    end
  end
end
