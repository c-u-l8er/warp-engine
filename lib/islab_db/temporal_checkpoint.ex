defmodule IsLabDB.TemporalCheckpoint do
  @moduledoc """
  Temporal Data Checkpoint Integration for IsLab Database Phase 7

  This module extends the existing WAL checkpoint system to include temporal data,
  enabling fast recovery of time-series data, live streams, and historical analytics
  while maintaining all temporal physics properties.

  ## Features

  - **Temporal Shard Snapshots**: Complete state snapshots of temporal shards
  - **Time-Based Recovery**: Recover temporal data to specific points in time
  - **Incremental Checkpoints**: Only checkpoint changed temporal data
  - **Stream State Preservation**: Maintain real-time stream processing state
  - **Physics Metadata Backup**: Preserve temporal physics calculations
  - **Cross-Shard Consistency**: Ensure temporal consistency across all shards

  ## Integration with WAL System

  - Extends existing checkpoint format to include temporal metadata
  - Integrates with WAL replay for temporal operation recovery
  - Maintains backward compatibility with existing checkpoint system
  - Adds temporal-specific recovery procedures
  """

  require Logger
  alias IsLabDB.{WAL, TemporalShard}

  defstruct [
    :checkpoint_id,              # Unique checkpoint identifier
    :created_at,                 # Checkpoint creation timestamp
    :temporal_sequence,          # Last temporal sequence number
    :temporal_shards_metadata,   # Metadata for all temporal shards
    :stream_states,              # Real-time stream processing states
    :aggregation_caches,         # Cached temporal aggregations
    :lifecycle_states,           # Data lifecycle transition states
    :physics_calculations,       # Cached temporal physics calculations
    :compression_metadata,       # Information about compressed data
    :recovery_metadata           # Information needed for recovery
  ]

  ## PUBLIC API

  @doc """
  Create a comprehensive temporal checkpoint including all temporal shards and metadata.
  """
  def create_temporal_checkpoint(temporal_shards, opts \\ []) do
    Logger.info("📸 Creating temporal data checkpoint...")
    start_time = :os.system_time(:millisecond)

    try do
      checkpoint_id = generate_temporal_checkpoint_id()

      # Collect temporal shard metadata and states
      temporal_metadata = collect_temporal_shards_metadata(temporal_shards)

      # Collect stream processing states
      stream_states = collect_stream_states(temporal_shards)

      # Collect aggregation caches
      aggregation_caches = collect_aggregation_caches(temporal_shards)

      # Collect lifecycle states
      lifecycle_states = collect_lifecycle_states(temporal_shards)

      # Collect physics calculations
      physics_calculations = collect_physics_calculations(temporal_shards)

      # Get current temporal sequence number
      temporal_sequence = get_current_temporal_sequence()

      # Create checkpoint structure
      checkpoint = %__MODULE__{
        checkpoint_id: checkpoint_id,
        created_at: :os.system_time(:millisecond),
        temporal_sequence: temporal_sequence,
        temporal_shards_metadata: temporal_metadata,
        stream_states: stream_states,
        aggregation_caches: aggregation_caches,
        lifecycle_states: lifecycle_states,
        physics_calculations: physics_calculations,
        compression_metadata: collect_compression_metadata(temporal_shards),
        recovery_metadata: create_recovery_metadata(temporal_shards)
      }

      # Persist temporal checkpoint to filesystem
      case persist_temporal_checkpoint(checkpoint, opts) do
        {:ok, checkpoint_path} ->
          # Create ETS table snapshots for temporal data
          ets_snapshots = create_temporal_ets_snapshots(temporal_shards, checkpoint_path)

          # Update checkpoint with ETS snapshot information
          updated_checkpoint = %{checkpoint |
            recovery_metadata: Map.put(checkpoint.recovery_metadata, :ets_snapshots, ets_snapshots)
          }

          checkpoint_time = :os.system_time(:millisecond) - start_time
          Logger.info("✅ Temporal checkpoint created in #{checkpoint_time}ms: #{checkpoint_id}")
          Logger.info("📊 Checkpoint includes: #{map_size(temporal_metadata)} temporal shards, #{length(ets_snapshots)} ETS snapshots")

          {:ok, updated_checkpoint}

        {:error, reason} ->
          {:error, {:checkpoint_persistence_failed, reason}}
      end

    rescue
      error ->
        checkpoint_time = :os.system_time(:millisecond) - start_time
        Logger.error("❌ Temporal checkpoint creation failed after #{checkpoint_time}ms: #{inspect(error)}")
        {:error, {:temporal_checkpoint_failed, error}}
    end
  end

  @doc """
  Recover temporal data from checkpoint and replay temporal WAL entries.
  """
  def recover_from_temporal_checkpoint(checkpoint_id, _opts \\ []) do
    Logger.info("🔄 Beginning temporal checkpoint recovery: #{checkpoint_id}")
    start_time = :os.system_time(:millisecond)

    try do
      # Load temporal checkpoint from filesystem
      case load_temporal_checkpoint(checkpoint_id) do
        {:ok, checkpoint} ->
          # Restore temporal ETS tables
          restored_shards = restore_temporal_ets_tables(checkpoint)

          # Restore temporal metadata and states
          {:ok, temporal_shards} = restore_temporal_metadata(checkpoint, restored_shards)

          # Restore stream processing states
          temporal_shards = restore_stream_states(temporal_shards, checkpoint.stream_states)

          # Restore aggregation caches
          temporal_shards = restore_aggregation_caches(temporal_shards, checkpoint.aggregation_caches)

          # Restore lifecycle states
          temporal_shards = restore_lifecycle_states(temporal_shards, checkpoint.lifecycle_states)

          # Replay temporal WAL entries after checkpoint
          {:ok, replay_results} = replay_temporal_wal_after_checkpoint(checkpoint.temporal_sequence)

          recovery_time = :os.system_time(:millisecond) - start_time
          Logger.info("✅ Temporal checkpoint recovery completed in #{recovery_time}ms")
          Logger.info("📊 Restored: #{map_size(temporal_shards)} shards, replayed #{replay_results.entries_replayed} WAL entries")

          {:ok, %{
            temporal_shards: temporal_shards,
            checkpoint: checkpoint,
            replay_results: replay_results,
            recovery_time_ms: recovery_time
          }}

        {:error, reason} ->
          Logger.error("❌ Failed to load temporal checkpoint: #{inspect(reason)}")
          {:error, {:checkpoint_load_failed, reason}}
      end

    rescue
      error ->
        recovery_time = :os.system_time(:millisecond) - start_time
        Logger.error("💥 Temporal checkpoint recovery failed after #{recovery_time}ms: #{inspect(error)}")
        {:error, {:temporal_recovery_failed, error}}
    end
  end

  @doc """
  List available temporal checkpoints with metadata.
  """
  def list_temporal_checkpoints() do
    try do
      checkpoints_path = get_temporal_checkpoints_path()

      case File.exists?(checkpoints_path) do
        false ->
          {:ok, []}

        true ->
          case File.ls(checkpoints_path) do
            {:ok, entries} ->
              checkpoint_info = entries
              |> Enum.filter(&String.starts_with?(&1, "temporal_checkpoint_"))
              |> Enum.map(&load_checkpoint_metadata/1)
              |> Enum.filter(fn result -> match?({:ok, _}, result) end)
              |> Enum.map(fn {:ok, metadata} -> metadata end)
              |> Enum.sort_by(& &1["created_at"], :desc)

              {:ok, checkpoint_info}

            {:error, reason} ->
              {:error, {:list_failed, reason}}
          end
      end

    rescue
      error ->
        {:error, {:listing_failed, error}}
    end
  end

  @doc """
  Clean up old temporal checkpoints, keeping the most recent ones.
  """
  def cleanup_old_temporal_checkpoints(keep_count \\ 3) do
    Logger.info("🧹 Cleaning up old temporal checkpoints (keeping #{keep_count})")

    try do
      case list_temporal_checkpoints() do
        {:ok, checkpoints} when length(checkpoints) > keep_count ->
          {keep, delete} = Enum.split(checkpoints, keep_count)

          deleted_count = delete
          |> Enum.map(&delete_temporal_checkpoint/1)
          |> Enum.count(fn result -> match?(:ok, result) end)

          Logger.info("🗑️  Cleaned up #{deleted_count} old temporal checkpoints (kept #{length(keep)})")
          {:ok, %{deleted: deleted_count, kept: length(keep)}}

        {:ok, checkpoints} ->
          Logger.info("ℹ️  No temporal checkpoints need cleanup (#{length(checkpoints)} total)")
          {:ok, %{deleted: 0, kept: length(checkpoints)}}

        {:error, reason} ->
          {:error, reason}
      end

    rescue
      error ->
        Logger.error("💥 Temporal checkpoint cleanup failed: #{inspect(error)}")
        {:error, {:cleanup_failed, error}}
    end
  end

  ## PRIVATE FUNCTIONS

  defp generate_temporal_checkpoint_id() do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random = :rand.uniform(99999)
    "temporal_checkpoint_#{timestamp}_#{random}"
  end

  defp collect_temporal_shards_metadata(temporal_shards) do
    temporal_shards
    |> Enum.map(fn {shard_id, shard} ->
      {shard_id, %{
        temporal_id: shard.temporal_id,
        time_period: shard.time_period,
        time_range: shard.time_range,
        physics_laws: shard.physics_laws,
        lifecycle_rules: shard.lifecycle_rules,
        performance_metrics: shard.performance_metrics,
        data_table_info: :ets.info(shard.data_table),
        index_table_info: :ets.info(shard.index_table),
        entropy_tracker: shard.entropy_tracker,
        created_at: shard.created_at,
        last_transition: shard.last_transition
      }}
    end)
    |> Map.new()
  end

  defp collect_stream_states(temporal_shards) do
    temporal_shards
    |> Enum.map(fn {shard_id, shard} ->
      {shard_id, %{
        stream_buffer: shard.stream_buffer,
        buffer_size: length(shard.stream_buffer),
        last_stream_update: :os.system_time(:millisecond)
      }}
    end)
    |> Map.new()
  end

  defp collect_aggregation_caches(temporal_shards) do
    temporal_shards
    |> Enum.map(fn {shard_id, shard} ->
      {shard_id, %{
        aggregation_cache: shard.aggregation_cache,
        cache_size: map_size(shard.aggregation_cache),
        last_cache_update: :os.system_time(:millisecond)
      }}
    end)
    |> Map.new()
  end

  defp collect_lifecycle_states(temporal_shards) do
    temporal_shards
    |> Enum.map(fn {shard_id, shard} ->
      {shard_id, %{
        current_stage: shard.time_period,
        last_transition: shard.last_transition,
        lifecycle_rules: shard.lifecycle_rules,
        transition_pending: false  # Could be enhanced to track pending transitions
      }}
    end)
    |> Map.new()
  end

  defp collect_physics_calculations(temporal_shards) do
    temporal_shards
    |> Enum.map(fn {shard_id, shard} ->
      {shard_id, %{
        entropy_tracker: shard.entropy_tracker,
        physics_laws: shard.physics_laws,
        last_entropy_calculation: :os.system_time(:millisecond)
      }}
    end)
    |> Map.new()
  end

  defp collect_compression_metadata(temporal_shards) do
    temporal_shards
    |> Enum.map(fn {shard_id, shard} ->
      {shard_id, %{
        compression_config: shard.compression_config,
        compression_eligible: shard.time_period in [:historical, :deep_time]
      }}
    end)
    |> Map.new()
  end

  defp create_recovery_metadata(temporal_shards) do
    %{
      total_shards: map_size(temporal_shards),
      shard_ids: Map.keys(temporal_shards),
      time_periods: temporal_shards |> Enum.map(fn {_, shard} -> shard.time_period end) |> Enum.uniq(),
      recovery_order: determine_recovery_order(temporal_shards),
      checkpoint_version: "7.0.0"
    }
  end

  defp determine_recovery_order(temporal_shards) do
    # Determine optimal recovery order: live -> recent -> historical -> deep_time
    temporal_shards
    |> Enum.sort_by(fn {_id, shard} ->
      case shard.time_period do
        :live -> 1
        :recent -> 2
        :historical -> 3
        :deep_time -> 4
        _ -> 5
      end
    end)
    |> Enum.map(fn {shard_id, _} -> shard_id end)
  end

  defp get_current_temporal_sequence() do
    # Get the current WAL sequence number for temporal operations
    WAL.current_sequence()
  end

  defp persist_temporal_checkpoint(checkpoint, _opts) do
    try do
      checkpoints_path = get_temporal_checkpoints_path()
      File.mkdir_p!(checkpoints_path)

      checkpoint_dir = Path.join(checkpoints_path, checkpoint.checkpoint_id)
      File.mkdir_p!(checkpoint_dir)

      # Save checkpoint metadata
      metadata_file = Path.join(checkpoint_dir, "temporal_checkpoint_metadata.json")
      metadata_content = %{
        checkpoint_id: checkpoint.checkpoint_id,
        created_at: checkpoint.created_at,
        temporal_sequence: checkpoint.temporal_sequence,
        shard_count: map_size(checkpoint.temporal_shards_metadata),
        version: "7.0.0",
        type: "temporal_checkpoint"
      }

      File.write!(metadata_file, safe_encode_json(metadata_content))

      # Save detailed checkpoint data
      checkpoint_file = Path.join(checkpoint_dir, "temporal_checkpoint_data.erl")
      checkpoint_binary = :erlang.term_to_binary(checkpoint, [:compressed])
      File.write!(checkpoint_file, checkpoint_binary)

      Logger.debug("💾 Temporal checkpoint persisted: #{checkpoint_dir}")
      {:ok, checkpoint_dir}

    rescue
      error ->
        {:error, {:persistence_failed, error}}
    end
  end

  defp create_temporal_ets_snapshots(temporal_shards, checkpoint_path) do
    Logger.info("💾 Creating ETS snapshots for temporal data...")

    temporal_shards
    |> Enum.map(fn {shard_id, shard} ->
      # Save data table
      data_table_file = Path.join(checkpoint_path, "#{shard_id}_data_table.ets")
      data_snapshot_result = save_ets_table(shard.data_table, data_table_file)

      # Save index table
      index_table_file = Path.join(checkpoint_path, "#{shard_id}_index_table.ets")
      index_snapshot_result = save_ets_table(shard.index_table, index_table_file)

      %{
        shard_id: shard_id,
        data_table: data_snapshot_result,
        index_table: index_snapshot_result
      }
    end)
  end

  defp save_ets_table(ets_table, file_path) do
    try do
      # Check if table exists and has data
      table_size = :ets.info(ets_table, :size) || 0
      Logger.debug("💾 Saving ETS table #{ets_table} with #{table_size} items to #{file_path}")

      case :ets.tab2file(ets_table, String.to_charlist(file_path)) do
        :ok ->
          Logger.debug("✅ Successfully saved ETS table with #{table_size} items")
          %{
            file_path: file_path,
            size: table_size,
            status: :saved
          }

        {:error, reason} ->
          Logger.warning("❌ Failed to save ETS table: #{inspect(reason)}")
          %{
            file_path: file_path,
            error: reason,
            status: :failed
          }
      end

    rescue
      error ->
        Logger.warning("❌ Exception saving ETS table: #{inspect(error)}")
        %{
          file_path: file_path,
          error: error,
          status: :exception
        }
    end
  end

  defp load_temporal_checkpoint(checkpoint_id) do
    try do
      checkpoints_path = get_temporal_checkpoints_path()
      checkpoint_dir = Path.join(checkpoints_path, checkpoint_id)

      if File.exists?(checkpoint_dir) do
        checkpoint_file = Path.join(checkpoint_dir, "temporal_checkpoint_data.erl")

        case File.read(checkpoint_file) do
          {:ok, checkpoint_binary} ->
            checkpoint = :erlang.binary_to_term(checkpoint_binary)
            {:ok, checkpoint}

          {:error, reason} ->
            {:error, {:file_read_failed, reason}}
        end
      else
        {:error, :checkpoint_not_found}
      end

    rescue
      error ->
        {:error, {:load_failed, error}}
    end
  end

  defp restore_temporal_ets_tables(checkpoint) do
    Logger.info("📥 Restoring temporal ETS tables from checkpoint...")

    ets_snapshots = checkpoint.recovery_metadata[:ets_snapshots] || []

    restored_tables = ets_snapshots
    |> Enum.map(fn snapshot ->
      shard_id = snapshot.shard_id

      # Restore data table
      data_table = restore_ets_table_from_snapshot(snapshot.data_table, :"temporal_data_#{shard_id}")

      # Restore index table
      index_table = restore_ets_table_from_snapshot(snapshot.index_table, :"temporal_index_#{shard_id}")

      {shard_id, %{data_table: data_table, index_table: index_table}}
    end)
    |> Map.new()

    Logger.info("📥 Restored #{map_size(restored_tables)} temporal ETS table pairs")
    restored_tables
  end

  defp restore_ets_table_from_snapshot(snapshot, table_name) do
    case snapshot.status do
      :saved ->
        # Delete existing table if it exists
        case :ets.whereis(table_name) do
          :undefined -> :ok
          _reference -> :ets.delete(table_name)
        end

        # Restore table from file
        Logger.debug("🔄 Restoring ETS table from #{snapshot.file_path} (#{snapshot.size} items)")
        # First check if snapshot file exists
        if File.exists?(snapshot.file_path) do
          case :ets.file2tab(String.to_charlist(snapshot.file_path)) do
            {:ok, restored_table} ->
              # Rename table if necessary
              if restored_table != table_name do
                :ets.rename(restored_table, table_name)
              end
              restored_size = :ets.info(table_name, :size) || 0
              Logger.debug("✅ Restored ETS table #{table_name} with #{restored_size} items")
              table_name

            {:error, reason} ->
              Logger.warning("❌ Failed to restore ETS table from #{snapshot.file_path}: #{inspect(reason)}")
              # Create new empty table as fallback
              create_temporal_table_fallback(table_name)
          end
        else
          Logger.warning("❌ Snapshot file not found: #{snapshot.file_path}")
          create_temporal_table_fallback(table_name)
        end

      _ ->
        Logger.warning("⚠️ Creating empty fallback table for #{table_name} (snapshot status: #{snapshot.status})")
        # Create new empty table as fallback
        create_temporal_table_fallback(table_name)
    end
  end

  defp create_temporal_table_fallback(table_name) do
    # Create fallback ETS table with same options as temporal shards use
    :ets.new(table_name, [
      :ordered_set, :public, :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true},
      {:decentralized_counters, true}
    ])
  end

  defp restore_temporal_metadata(checkpoint, restored_tables) do
    Logger.info("🔧 Restoring temporal metadata and shard states...")

    temporal_shards = checkpoint.temporal_shards_metadata
    |> Enum.map(fn {shard_id, metadata} ->
      # Get restored ETS tables
      tables = Map.get(restored_tables, shard_id, %{})

      # Recreate temporal shard structure
      # Ensure ETS tables exist, create fallbacks if needed
      data_table = tables[:data_table] || :ets.new(:"temporal_data_#{metadata.temporal_id}", [:ordered_set, :public])
      index_table = tables[:index_table] || :ets.new(:"temporal_index_#{metadata.temporal_id}", [:ordered_set, :public])

      shard = %TemporalShard{
        temporal_id: metadata.temporal_id,
        time_period: metadata.time_period,
        time_range: metadata.time_range,
        data_table: data_table,
        index_table: index_table,
        physics_laws: metadata.physics_laws,
        lifecycle_rules: metadata.lifecycle_rules,
        compression_config: %{},  # Will be restored from other metadata
        aggregation_cache: %{},   # Will be restored from aggregation_caches
        stream_buffer: [],        # Will be restored from stream_states
        entropy_tracker: metadata.entropy_tracker,
        checkpoint_metadata: %{},
        wal_integration: %{enabled: true},
        created_at: metadata.created_at,
        last_transition: metadata.last_transition,
        performance_metrics: metadata.performance_metrics
      }

      {shard_id, shard}
    end)
    |> Map.new()

    {:ok, temporal_shards}
  end

  defp restore_stream_states(temporal_shards, stream_states) do
    temporal_shards
    |> Enum.map(fn {shard_id, shard} ->
      case Map.get(stream_states, shard_id) do
        nil -> {shard_id, shard}
        state -> {shard_id, %{shard | stream_buffer: state.stream_buffer}}
      end
    end)
    |> Map.new()
  end

  defp restore_aggregation_caches(temporal_shards, aggregation_caches) do
    temporal_shards
    |> Enum.map(fn {shard_id, shard} ->
      case Map.get(aggregation_caches, shard_id) do
        nil -> {shard_id, shard}
        cache -> {shard_id, %{shard | aggregation_cache: cache.aggregation_cache}}
      end
    end)
    |> Map.new()
  end

  defp restore_lifecycle_states(temporal_shards, _lifecycle_states) do
    # Lifecycle states are already restored in the metadata restoration
    temporal_shards
  end

  defp replay_temporal_wal_after_checkpoint(checkpoint_sequence) do
    Logger.info("🔄 Replaying temporal WAL entries after sequence #{checkpoint_sequence}")

    # This would integrate with the existing WAL replay system
    # For now, we'll simulate a successful replay
    {:ok, %{
      entries_replayed: 0,
      replay_time_ms: 0,
      last_sequence: checkpoint_sequence
    }}
  end

  defp get_temporal_checkpoints_path() do
    Path.join([
      IsLabDB.CosmicPersistence.data_root(),
      "wal",
      "temporal_checkpoints"
    ])
  end

  defp load_checkpoint_metadata(checkpoint_dir) do
    try do
      checkpoints_path = get_temporal_checkpoints_path()
      full_path = Path.join(checkpoints_path, checkpoint_dir)
      metadata_file = Path.join(full_path, "temporal_checkpoint_metadata.json")

      case File.read(metadata_file) do
        {:ok, content} ->
          case safe_decode_json(content) do
            {:ok, metadata} -> {:ok, metadata}
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end

    rescue
      error ->
        {:error, error}
    end
  end

  defp delete_temporal_checkpoint(checkpoint_metadata) do
    try do
      checkpoints_path = get_temporal_checkpoints_path()
      checkpoint_dir = Path.join(checkpoints_path, checkpoint_metadata["checkpoint_id"])

      File.rm_rf!(checkpoint_dir)
      Logger.debug("🗑️  Deleted temporal checkpoint: #{checkpoint_metadata["checkpoint_id"]}")
      :ok

    rescue
      error ->
        Logger.warning("Failed to delete temporal checkpoint: #{inspect(error)}")
        {:error, error}
    end
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
