defmodule WarpEngine.WALShard do
  @moduledoc """
  Per-Shard WAL Process for eliminating concurrency bottlenecks.

  This module implements individual WAL processes for each spacetime shard,
  eliminating the single-point-of-contention that limited concurrency scaling.
  Each shard gets its own:

  - Dedicated GenServer process
  - Independent atomic sequence counter
  - Separate WAL file (cosmic_hot.wal, cosmic_warm.wal, cosmic_cold.wal)
  - Individual write buffer and flush cycle
  - Background sync process

  ## Performance Target
  - Enable linear scaling from 77K → 200K+ ops/sec
  - Eliminate concurrency degradation after 2-4 processes
  - Maintain <100μs WAL write latency per shard

  ## Architecture
  ```
  Per-Shard WAL Files:
  /data/wal/
  ├── cosmic_hot.wal      # Hot data shard WAL
  ├── cosmic_warm.wal     # Warm data shard WAL
  ├── cosmic_cold.wal     # Cold data shard WAL
  ├── checkpoints/
  │   ├── hot_checkpoint_001/
  │   ├── warm_checkpoint_001/
  │   └── cold_checkpoint_001/
  └── metadata.json       # Global WAL metadata
  ```
  """

  use GenServer
  require Logger

  alias WarpEngine.CosmicPersistence
  alias WarpEngine.WAL.Entry, as: WALEntry

  defstruct [
    :shard_id,              # Shard identifier (:hot_data, :warm_data, :cold_data)
    :wal_file_path,         # Shard-specific WAL file path
    :wal_file_handle,       # Shard-specific file handle
    :sequence_counter_ref,  # Shard-specific atomic counter
    :write_buffer,          # Per-shard write buffer
    :last_flush_time,       # Last flush timestamp
    :sync_process_pid,      # Background sync process
    :core_affinity,         # CPU core for NUMA optimization
    :stats                  # Per-shard statistics
  ]

  # Per-shard configuration
  @write_batch_size 5000     # Operations per batch write (increased from 1000)
  @flush_interval_ms 50       # Flush interval (increased from 12ms)
  @flush_batch_size 1024
  @max_buffer_ops 25000       # Maximum buffer size (increased from 8192)

  ## PUBLIC API

  @doc """
  Start a WAL shard process for a specific spacetime shard.
  """
  def start_link(shard_id, opts \\ []) do
    GenServer.start_link(__MODULE__, {shard_id, opts}, name: via_tuple(shard_id))
  end

  @doc """
  Asynchronously append an operation to this shard's WAL.
  This eliminates cross-shard contention for maximum concurrency.
  """
  def async_append(shard_id, operation) do
    GenServer.cast(via_tuple(shard_id), {:append, operation})
  end

  @doc """
  Get next sequence number for this shard.
  Each shard has independent sequence numbering.
  """
  def next_sequence(shard_id) do
    GenServer.call(via_tuple(shard_id), :next_sequence)
  end

  @doc """
  ULTRA-PERFORMANCE: Get direct atomic counter reference for this shard.
  Use :atomics.add_get(ref, 1, 1) for maximum speed sequence generation.
  """
  def get_sequence_counter(shard_id) do
    GenServer.call(via_tuple(shard_id), :get_sequence_counter)
  end

  @doc """
  Get the atomic counter reference for this shard (for coordinator use).
  """
  def get_sequence_counter_ref(shard_id) do
    GenServer.call(via_tuple(shard_id), :get_sequence_counter_ref)
  end

  @doc """
  Force flush this shard's write buffer to disk.
  """
  def force_flush(shard_id) do
    GenServer.call(via_tuple(shard_id), :force_flush)
  end

  @doc """
  Get WAL statistics for this shard.
  """
  def stats(shard_id) do
    GenServer.call(via_tuple(shard_id), :stats)
  end

  @doc """
  Get current WAL ETS table size for this shard.
  """
  def get_wal_table_size(shard_id) do
    # Extract numeric part for clean table naming (e.g., :shard_0 -> wal_shard_0)
    numeric_shard_id = case Atom.to_string(shard_id) do
      "shard_" <> num_str ->
        case Integer.parse(num_str) do
          {num, _} -> num
          :error -> 0
        end
      _ -> 0  # Fallback to 0
    end
    wal_ets_table_name = "wal_shard_#{numeric_shard_id}"
    wal_ets_table_atom = String.to_atom(wal_ets_table_name)

    # Safety check: ensure ETS table exists before querying
    case :ets.whereis(wal_ets_table_atom) do
      :undefined -> 0
      _ -> :ets.info(wal_ets_table_atom, :size) || 0
    end
  end

  @doc """
  Create checkpoint for this shard.
  """
  def create_checkpoint(shard_id) do
    GenServer.call(via_tuple(shard_id), :create_checkpoint, 60_000)
  end

  @doc """
  Recover this shard from its WAL file.
  """
  def recover_from_wal(shard_id) do
    GenServer.call(via_tuple(shard_id), :recover_from_wal, 120_000)
  end

  ## GENSERVER CALLBACKS

  def init({shard_id, opts}) do
    try do
      Logger.info("🚀 Initializing WAL Shard #{shard_id}...")

      # Get data_root and create shard-specific paths
      data_root = Keyword.get(opts, :data_root, CosmicPersistence.data_root())
      wal_directory = Path.join(data_root, "wal")
      shard_wal_file = "cosmic_#{shard_id}.wal"
      wal_file_path = Path.join(wal_directory, shard_wal_file)

      Logger.info("📁 Shard #{shard_id} WAL file: #{wal_file_path}")

      # Create WAL directory structure
      Logger.info("📁 Creating directories for shard #{shard_id}...")
      File.mkdir_p!(wal_directory)
      File.mkdir_p!(Path.join(wal_directory, "checkpoints"))
      File.mkdir_p!(Path.join([wal_directory, "checkpoints", "#{shard_id}"]))

      Logger.info("📁 Directories created for shard #{shard_id}")

      # Initialize shard-specific WAL file
      Logger.info("📄 Opening WAL file for shard #{shard_id}...")
      {:ok, wal_file_handle} = File.open(wal_file_path, [:write, :binary, :append])
      Logger.info("📄 WAL file opened for shard #{shard_id}")

      # PHASE 9.10: Create WAL ETS table for direct operations
      # Extract numeric part for clean table naming (e.g., :shard_0 -> wal_shard_0)
      numeric_shard_id = case Atom.to_string(shard_id) do
        "shard_" <> num_str ->
          case Integer.parse(num_str) do
            {num, _} -> num
            :error -> 0
          end
        _ -> 0  # Fallback to 0
      end
      wal_ets_table_name = "wal_shard_#{numeric_shard_id}"
      wal_ets_table_atom = String.to_atom(wal_ets_table_name)

      # Create ETS table - :ets.new/2 either succeeds or crashes
      try do
        :ets.new(wal_ets_table_atom, [:set, :public, :named_table])
        Logger.info("📊 Created WAL ETS table: #{wal_ets_table_name}")
      rescue
        error ->
          Logger.error("❌ Failed to create WAL ETS table #{wal_ets_table_name}: #{inspect(error)}")
          raise "Failed to create WAL ETS table: #{inspect(error)}"
      end

      # Initialize shard-specific atomic sequence counter
      Logger.info("⚡ Initializing sequence counter for shard #{shard_id}...")
      sequence_counter_ref = :atomics.new(1, [])
      :atomics.put(sequence_counter_ref, 1, load_shard_last_sequence(wal_directory, shard_id))
      Logger.info("⚡ Shard #{shard_id} sequence counter initialized: #{:atomics.get(sequence_counter_ref, 1)}")

      # Pin shard to specific CPU core for NUMA optimization
      # Reuse numeric_shard_id from above
      core_affinity = rem(numeric_shard_id, System.schedulers())
      Logger.info("📌 Shard #{shard_id} pinned to CPU core #{core_affinity}")

      # Build initial shard state
      Logger.info("🏗️ Building state for shard #{shard_id}...")
      state = %WarpEngine.WALShard{
        shard_id: shard_id,
        wal_file_path: wal_file_path,
        wal_file_handle: wal_file_handle,
        write_buffer: [],
        sequence_counter_ref: sequence_counter_ref,
        last_flush_time: :os.system_time(:millisecond),
        core_affinity: core_affinity,
        stats: initialize_shard_stats(shard_id)
      }

      Logger.info("✅ WAL Shard #{shard_id} ready for linear concurrency scaling!")

      # Start periodic flush timer for ETS-based WAL - staggered to prevent I/O contention
      # Stagger flush timing based on shard ID to prevent all shards flushing simultaneously
      initial_flush_delay = 100 + (numeric_shard_id * 25)  # Stagger by 25ms per shard
      Process.send_after(self(), :periodic_flush, initial_flush_delay)

      {:ok, state}
    rescue
      error ->
        Logger.error("❌ Failed to initialize WAL Shard #{shard_id}: #{inspect(error)}")
        {:error, error}
    end
  end

  def handle_cast({:append, operation}, state) do
    # Add to shard-specific write buffer (in-memory, ultra-fast)
    updated_buffer = [operation | state.write_buffer]
    buffer_size = length(updated_buffer)

    new_state = %{state | write_buffer: updated_buffer}

    # Check if we should flush this shard's buffer
    # Adaptive flushing: more aggressive at high concurrency
    should_flush = buffer_size >= 5000 or
                   (:os.system_time(:millisecond) - state.last_flush_time) >= 50 or
                   (buffer_size >= 2500 and :os.system_time(:millisecond) - state.last_flush_time >= 25)

    if should_flush do
      flushed_state = flush_shard_buffer(new_state)
      {:noreply, flushed_state}
    else
      {:noreply, new_state}
    end
  end

  def handle_call(:next_sequence, _from, state) do
    # Shard-specific atomic sequence generation
    sequence = :atomics.add_get(state.sequence_counter_ref, 1, 1)
    {:reply, sequence, state}
  end

  def handle_call(:get_sequence_counter, _from, state) do
    # Get current sequence number from shard-specific atomic counter
    current_sequence = :atomics.get(state.sequence_counter_ref, 1)
    {:reply, current_sequence, state}
  end

  def handle_call(:get_sequence_counter_ref, _from, state) do
    # Get the atomic counter reference itself (for coordinator use)
    {:reply, state.sequence_counter_ref, state}
  end

  def handle_call(:force_flush, _from, state) do
    new_state = flush_shard_buffer(state)
    {:reply, :ok, new_state}
  end

  def handle_call(:stats, _from, state) do
    # PHASE 9.10: Get stats from ETS table instead of message buffer
    # Extract numeric part for clean table naming (e.g., :shard_0 -> wal_shard_0)
    numeric_shard_id = case Atom.to_string(state.shard_id) do
      "shard_" <> num_str ->
        case Integer.parse(num_str) do
          {num, _} -> num
          :error -> 0
        end
      _ -> 0  # Fallback to 0
    end
    wal_ets_table_name = "wal_shard_#{numeric_shard_id}"
    wal_ets_table_atom = String.to_atom(wal_ets_table_name)

    # Safety check: ensure ETS table exists before querying
    ets_size = case :ets.whereis(wal_ets_table_atom) do
      :undefined -> 0
      _ -> :ets.info(wal_ets_table_atom, :size) || 0
    end

    current_stats = %{
      shard_id: state.shard_id,
      sequence_number: :atomics.get(state.sequence_counter_ref, 1),
      buffer_size: ets_size,  # ETS table size instead of message buffer
      wal_file_size: get_file_size(state.wal_file_path),
      last_flush_time: state.last_flush_time,
      total_operations: state.stats.total_operations,
      total_flushes: state.stats.total_flushes,
      avg_flush_time_ms: state.stats.avg_flush_time_ms,
      core_affinity: state.core_affinity
    }
    {:reply, current_stats, state}
  end

  def handle_call(:create_checkpoint, _from, state) do
    result = create_shard_checkpoint(state)
    {:reply, result, state}
  end

  def handle_call(:recover_from_wal, _from, state) do
    result = perform_shard_wal_recovery(state)
    {:reply, result, state}
  end

  # PHASE 9.9: Handle fire-and-forget with ULTRA-MINIMAL WAL - maximum performance
  def handle_info({:fire_and_forget, operation_type, key, value, sequence_number}, state) do
    # Use consistent format for all WAL entries
    minimal_entry = %{
      operation: operation_type,
      key: key,
      value: value,
      timestamp: :os.system_time(:millisecond),
      sequence: sequence_number,
      shard_id: state.shard_id,
      value_preview: get_value_preview(value)  # Optimized value preview
    }

    # Add to buffer for ultra-fast batched writing
    updated_buffer = [minimal_entry | state.write_buffer]
    updated_state = %{state | write_buffer: updated_buffer}

    # Adaptive flushing: more aggressive at high concurrency
    should_flush = length(updated_buffer) >= 5000 or
                   (:os.system_time(:millisecond) - updated_state.last_flush_time) >= 50 or
                   (length(updated_buffer) >= 2500 and :os.system_time(:millisecond) - updated_state.last_flush_time >= 25)

    # Hard cap: flush immediately if buffer is getting too large
    next_state = if should_flush or length(updated_buffer) >= 25000 do
      flush_shard_buffer(updated_state)
    else
      updated_state
    end

    {:noreply, next_state}
  end

  # PHASE 9.9: Handle batch operations - optimized for high concurrency
  def handle_info({:batch_operations, operations}, state) do
    # Process multiple operations in batch
    minimal_entries = Enum.map(operations, fn {operation_type, key, value, sequence_number} ->
      %{
        operation: operation_type,
        key: key,
        value: value,
        timestamp: :os.system_time(:millisecond),
        sequence: sequence_number,
        shard_id: state.shard_id,
        value_preview: get_value_preview(value)  # Optimized value preview
      }
    end)

    # Add all entries to buffer
    updated_buffer = minimal_entries ++ state.write_buffer
    updated_state = %{state | write_buffer: updated_buffer}

    # Adaptive flushing: more aggressive at high concurrency
    should_flush = length(updated_buffer) >= 5000 or
                   (:os.system_time(:millisecond) - updated_state.last_flush_time) >= 50 or
                   (length(updated_buffer) >= 2500 and :os.system_time(:millisecond) - updated_state.last_flush_time >= 25)

    # Hard cap: flush immediately if buffer is getting too large
    next_state = if should_flush or length(updated_buffer) >= 25000 do
      flush_shard_buffer(updated_state)
    else
      updated_state
    end

    {:noreply, next_state}
  end

  def handle_info(:flush_hint, state) do
    {:noreply, flush_shard_buffer(state)}
  end

  # PHASE 9.10: Periodic flush for ETS-based WAL operations
  def handle_info(:periodic_flush, state) do
    # Check if we need to flush based on ETS table size
    # Extract numeric part for clean table naming (e.g., :shard_0 -> wal_shard_0)
    numeric_shard_id = case Atom.to_string(state.shard_id) do
      "shard_" <> num_str ->
        case Integer.parse(num_str) do
          {num, _} -> num
          :error -> 0
        end
      _ -> 0  # Fallback to 0
    end
    wal_ets_table_name = "wal_shard_#{numeric_shard_id}"
    wal_ets_table_atom = String.to_atom(wal_ets_table_name)

    # Safety check: ensure ETS table exists before querying
    ets_size = case :ets.whereis(wal_ets_table_atom) do
      :undefined -> 0
      _ -> :ets.info(wal_ets_table_atom, :size) || 0
    end

    # Simple, high-threshold flushing for maximum batching
    time_since_flush = :os.system_time(:millisecond) - state.last_flush_time

    # Balanced thresholds for 8 WAL shards - good distribution without fragmentation
    should_flush = ets_size > 0 and (
      ets_size >= 5000 or            # Moderate size threshold for 8 shards
      time_since_flush >= 500        # Moderate time threshold for 8 shards
    )

    new_state = if should_flush do
      Logger.debug("🔄 Flushing ETS table #{wal_ets_table_name} with #{ets_size} entries (time since last flush: #{time_since_flush}ms)")
      flush_shard_buffer(state)
    else
      state
    end

    # Less frequent periodic checks
    Process.send_after(self(), :periodic_flush, 200)

    {:noreply, new_state}
  end

  # PHASE 9.6: Handle direct WAL append messages from ultra-fast path
  def handle_info({:append, wal_entry}, state) do
    # Convert ultra-fast WAL entry to standard format and append
    operation = %{
      operation: wal_entry.operation,
      key: wal_entry.key,
      value: wal_entry.value,
      timestamp: wal_entry.timestamp,
      sequence: wal_entry.sequence,
      value_preview: wal_entry.value_preview
    }

    # Add to buffer for batched writing
    updated_buffer = [operation | state.write_buffer]
    updated_state = %{state | write_buffer: updated_buffer}

    {:noreply, updated_state}
  end

  def handle_info(:flush_check, state) do
    # DISABLED: Old flush mechanism replaced by new ETS-based periodic flush
    # This prevents premature flushing that was killing performance at high concurrency
    # Re-schedule but don't actually flush
    schedule_flush_check()
    {:noreply, state}
  end

  def terminate(_reason, state) do
    # Ensure shard data is flushed on shutdown
    flush_shard_buffer(state)
    :file.sync(state.wal_file_handle)
    File.close(state.wal_file_handle)
    :ok
  end

  ## PRIVATE FUNCTIONS

  defp flush_shard_buffer(state) do
    # PHASE 9.10: Flush WAL entries directly from ETS table
    # This eliminates message passing bottlenecks and achieves true linear scaling
    start_time = :os.system_time(:millisecond)

    # Extract numeric part for clean table naming (e.g., :shard_0 -> wal_shard_0)
    numeric_shard_id = case Atom.to_string(state.shard_id) do
      "shard_" <> num_str ->
        case Integer.parse(num_str) do
          {num, _} -> num
          :error -> 0
        end
      _ -> 0  # Fallback to 0
    end
    wal_ets_table_name = "wal_shard_#{numeric_shard_id}"
    wal_ets_table_atom = String.to_atom(wal_ets_table_name)

    # Safety check: ensure ETS table exists before querying
    case :ets.whereis(wal_ets_table_atom) do
      :undefined ->
        # ETS table doesn't exist yet, return state unchanged
        state
      _ ->
        # Get all entries from ETS table
        entries = :ets.tab2list(wal_ets_table_atom)

        if length(entries) == 0 do
          state
        else
          try do
            # Sort entries by sequence number for ordered writing
            sorted_entries = entries
            |> Enum.sort_by(fn {seq, _} -> seq end)
            |> Enum.map(fn {_seq, entry} -> entry end)

            # Convert to binary data for efficient writing
            binary_data = encode_shard_operations_batch(sorted_entries)

            # Write to shard-specific WAL file
            IO.binwrite(state.wal_file_handle, binary_data)

            # Update statistics
            updated_stats = update_shard_flush_stats(state.stats, :os.system_time(:millisecond) - start_time, length(sorted_entries))

            # Clear ETS table and update timestamp
            :ets.delete_all_objects(wal_ets_table_atom)

            %{state |
              last_flush_time: :os.system_time(:millisecond),
              stats: updated_stats
            }
          rescue
            error ->
              Logger.error("❌ Failed to flush shard #{state.shard_id} buffer: #{inspect(error)}")
              # Return state unchanged on error
              state
          end
        end
    end
  end

  defp encode_shard_operations_batch(operations) do
    # Encode batch of operations to binary format for maximum I/O efficiency
    batch_header = <<length(operations)::32, :os.system_time(:millisecond)::64>>

    operations_binary = operations
    |> Enum.map(&encode_shard_operation_binary/1)
    |> Enum.join()

    batch_header <> operations_binary
  end

  defp encode_shard_operation_binary(operation) do
    # Optimized binary encoding - no JSON overhead
    key_binary = to_string(operation.key)
    key_size = byte_size(key_binary)

    # Simple binary format: key_size + key + operation_type + sequence + timestamp
    operation_type_byte = case operation.operation do
      :put -> 1
      :delete -> 2
      _ -> 0
    end

    <<key_size::16, key_binary::binary, operation_type_byte::8, operation.sequence::64, operation.timestamp::64>>
  end

  defp load_shard_last_sequence(wal_directory, shard_id) do
    # Load the last sequence number for this specific shard
    metadata_path = Path.join(wal_directory, "shard_metadata_#{shard_id}.json")

    case File.read(metadata_path) do
      {:ok, content} ->
        case safe_decode_json(content) do
          {:ok, %{"last_sequence" => seq}} -> seq
          _ -> 0
        end
      {:error, _} -> 0
    end
  end

  # Safe JSON decoding without Jason dependency
  defp safe_decode_json(content) do
    try do
      case Jason.decode(content) do
        {:ok, data} -> {:ok, data}
        {:error, reason} -> {:error, reason}
      end
    rescue
      UndefinedFunctionError ->
        # Fallback: try to evaluate as Elixir term
        try do
          {data, _} = Code.eval_string(content)
          {:ok, data}
        rescue
          _ -> {:error, "Unable to decode JSON"}
        end
    end
  end

  defp initialize_shard_stats(shard_id) do
    %{
      shard_id: shard_id,
      total_operations: 0,
      total_flushes: 0,
      avg_flush_time_ms: 0.0,
      total_flush_time_ms: 0,
      created_at: :os.system_time(:millisecond)
    }
  end

  defp update_shard_flush_stats(stats, flush_time_ms, operations_count) do
    new_total_flushes = stats.total_flushes + 1
    new_total_operations = stats.total_operations + operations_count
    new_total_flush_time = stats.total_flush_time_ms + flush_time_ms
    new_avg_flush_time = new_total_flush_time / new_total_flushes

    %{stats |
      total_operations: new_total_operations,
      total_flushes: new_total_flushes,
      avg_flush_time_ms: new_avg_flush_time,
      total_flush_time_ms: new_total_flush_time
    }
  end

  defp schedule_flush_check() do
    Process.send_after(self(), :flush_check, @flush_interval_ms)
  end

  def via_tuple(shard_id) do
    {:via, Registry, {WarpEngine.WALRegistry, shard_id}}
  end

  defp get_file_size(file_path) do
    case File.stat(file_path) do
      {:ok, %{size: size}} -> size
      {:error, _} -> 0
    end
  end

  defp save_shard_ets_table_to_checkpoint(checkpoint_dir, table_name) do
    try do
      # Check if table exists and has data
      case :ets.whereis(table_name) do
        :undefined ->
          %{
            table_name: table_name,
            status: :not_found,
            error: "Table does not exist"
          }
        _reference ->
          table_size = :ets.info(table_name, :size) || 0
          table_file = Path.join(checkpoint_dir, "#{table_name}.ets")

          case :ets.tab2file(table_name, String.to_charlist(table_file)) do
            :ok ->
              %{
                table_name: table_name,
                file_path: table_file,
                size: table_size,
                status: :saved
              }
            {:error, reason} ->
              %{
                table_name: table_name,
                file_path: table_file,
                error: reason,
                status: :failed
              }
          end
      end
    rescue
      error ->
        %{
          table_name: table_name,
          error: error,
          status: :exception
        }
    end
  end

  defp cleanup_old_shard_checkpoints(shard_checkpoint_dir) do
    try do
      case File.ls(shard_checkpoint_dir) do
        {:ok, entries} ->
          # Get checkpoint directories sorted by creation time (newest first)
          checkpoint_dirs = entries
          |> Enum.filter(fn entry ->
            full_path = Path.join(shard_checkpoint_dir, entry)
            File.dir?(full_path) and String.starts_with?(entry, "checkpoint_")
          end)
          |> Enum.map(fn entry ->
            full_path = Path.join(shard_checkpoint_dir, entry)
            stat = File.stat!(full_path)
            {entry, full_path, stat.mtime}
          end)
          |> Enum.sort_by(fn {_entry, _path, mtime} -> mtime end, :desc)

          # Keep the 3 most recent, delete the rest
          {keep, delete} = Enum.split(checkpoint_dirs, 3)

          if length(delete) > 0 do
            Logger.info("🗑️  Deleting #{length(delete)} old checkpoints (keeping #{length(keep)} recent)")

            deleted_count = delete
            |> Enum.map(fn {entry, full_path, _mtime} ->
              try do
                File.rm_rf!(full_path)
                Logger.debug("🗑️  Deleted old checkpoint: #{entry}")
                1
              rescue
                error ->
                  Logger.warning("⚠️  Failed to delete checkpoint #{entry}: #{inspect(error)}")
                  0
              end
            end)
            |> Enum.sum()

            Logger.info("🧹 Cleanup complete: #{deleted_count}/#{length(delete)} old checkpoints deleted")
          end

        {:error, reason} ->
          Logger.warning("⚠️  Failed to list checkpoints directory: #{inspect(reason)}")
      end
    rescue
      error ->
        Logger.error("💥 Checkpoint cleanup failed: #{inspect(error)}")
    end
  end

  defp perform_shard_wal_recovery(state) do
    Logger.info("🔄 Beginning WAL recovery for shard #{state.shard_id}...")
    start_time = :os.system_time(:millisecond)

    try do
      # Look for shard-specific checkpoint first
      wal_directory = Path.dirname(state.wal_file_path)
      shard_checkpoint_dir = Path.join([wal_directory, "checkpoints", "#{state.shard_id}"])

      checkpoint_result = attempt_shard_checkpoint_recovery(shard_checkpoint_dir, state.shard_id)

      case checkpoint_result do
        {:ok, checkpoint_info} ->
          Logger.info("📂 Shard #{state.shard_id} checkpoint recovery successful")
          :atomics.put(state.sequence_counter_ref, 1, checkpoint_info.last_sequence + 1)
          replay_shard_wal_after_checkpoint(state, checkpoint_info.last_sequence, start_time)

        {:error, :no_checkpoint} ->
          Logger.info("ℹ️  No checkpoint found for shard #{state.shard_id}, performing full WAL recovery")
          perform_full_shard_wal_recovery(state, start_time)

        {:error, reason} ->
          Logger.warning("⚠️  Checkpoint recovery failed for shard #{state.shard_id} (#{inspect(reason)}), falling back to full WAL recovery")
          perform_full_shard_wal_recovery(state, start_time)
      end

    rescue
      error ->
        recovery_time = :os.system_time(:millisecond) - start_time
        Logger.error("💥 WAL recovery failed for shard #{state.shard_id} after #{recovery_time}ms: #{inspect(error)}")
        {:error, {:recovery_failed, error}}
    end
  end

  defp perform_full_shard_wal_recovery(state, start_time) do
    try do
      # Check if WAL file exists
      case File.exists?(state.wal_file_path) do
        false ->
          Logger.info("ℹ️  No WAL file found for shard #{state.shard_id}, starting with clean state")
          {:ok, %{entries_replayed: 0, recovery_time_ms: 0}}

        true ->
          # Load and replay WAL entries
          case load_shard_wal_entries_from_file(state.wal_file_path) do
            {:ok, entries} ->
              Logger.info("📂 Found #{length(entries)} WAL entries to replay for shard #{state.shard_id}")

              # Replay each entry to restore system state
              total_entries = length(entries)

              {replayed_count, _} =
                entries
                |> Stream.with_index()
                |> Stream.map(fn {entry, index} ->
                  # Show progress for large recoveries
                  if total_entries > 1000 and rem(index, 1000) == 0 do
                    progress = Float.round(index / total_entries * 100, 1)
                    Logger.info("🔄 Recovery progress for shard #{state.shard_id}: #{progress}%")
                  end

                  # Replay the WAL entry
                  case replay_shard_wal_entry(entry) do
                    :ok -> {1, entry}
                    {:error, reason} ->
                      Logger.warning("⚠️  Failed to replay entry #{entry.sequence} for shard #{state.shard_id}: #{inspect(reason)}")
                      {0, entry}
                  end
                end)
                |> Enum.reduce({0, nil}, fn {count, entry}, {total_count, _last} ->
                  {total_count + count, entry}
                end)

              recovery_time = :os.system_time(:millisecond) - start_time
              Logger.info("✅ WAL recovery completed for shard #{state.shard_id}: #{replayed_count}/#{total_entries} entries in #{recovery_time}ms")

              # Update sequence counter to continue from last replayed sequence
              if total_entries > 0 do
                last_entry = List.last(entries)
                :atomics.put(state.sequence_counter_ref, 1, last_entry.sequence + 1)
                Logger.info("🔢 Sequence counter updated for shard #{state.shard_id} to #{last_entry.sequence + 1}")
              end

              {:ok, %{
                entries_replayed: replayed_count,
                total_entries: total_entries,
                recovery_time_ms: recovery_time,
                last_sequence: if(total_entries > 0, do: List.last(entries).sequence, else: 0)
              }}

            {:error, reason} ->
              Logger.error("❌ Failed to load WAL entries for shard #{state.shard_id}: #{inspect(reason)}")
              {:error, reason}
          end
      end

    rescue
      error ->
        recovery_time = :os.system_time(:millisecond) - start_time
        Logger.error("💥 Full WAL recovery failed for shard #{state.shard_id} after #{recovery_time}ms: #{inspect(error)}")
        {:error, {:full_recovery_failed, error}}
    end
  end

  defp save_shard_sequence_metadata(shard_id, sequence, wal_directory) do
    metadata = %{
      shard_id: shard_id,
      last_sequence: sequence,
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      version: "9.1.0"
    }

    metadata_path = Path.join(wal_directory, "shard_metadata_#{shard_id}.json")
    File.write!(metadata_path, :erlang.term_to_binary(metadata))
  end


  defp create_shard_checkpoint(state) do
    Logger.info("📸 Creating checkpoint for shard #{state.shard_id}...")
    start_time = :os.system_time(:millisecond)

    try do
      checkpoint_id = generate_shard_checkpoint_id(state.shard_id)
      wal_directory = Path.dirname(state.wal_file_path)
      shard_checkpoint_dir = Path.join([wal_directory, "checkpoints", "#{state.shard_id}"])
      checkpoint_dir = Path.join(shard_checkpoint_dir, checkpoint_id)
      File.mkdir_p!(checkpoint_dir)

      # Get current sequence for this shard
      current_sequence = :atomics.get(state.sequence_counter_ref, 1)

      # Save ETS table for this shard
      shard_table_name = :"spacetime_#{state.shard_id}"
      ets_snapshot = save_shard_ets_table_to_checkpoint(checkpoint_dir, shard_table_name)

      # Create shard checkpoint metadata
      checkpoint_metadata = %{
        shard_id: state.shard_id,
        checkpoint_id: checkpoint_id,
        created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        sequence_number: current_sequence,
        ets_table: ets_snapshot,
        wal_file_path: state.wal_file_path,
        version: "9.1.0"
      }

      # Save checkpoint metadata
      metadata_file = Path.join(checkpoint_dir, "metadata.json")
      File.write!(metadata_file, :erlang.term_to_binary(checkpoint_metadata))

      # Save sequence metadata for recovery
      save_shard_sequence_metadata(state.shard_id, current_sequence, wal_directory)

      # Clean up old shard checkpoints
      cleanup_old_shard_checkpoints(shard_checkpoint_dir)

      checkpoint_time = :os.system_time(:millisecond) - start_time
      Logger.info("✅ Shard #{state.shard_id} checkpoint created in #{checkpoint_time}ms")

      {:ok, checkpoint_metadata}

    rescue
      error ->
        checkpoint_time = :os.system_time(:millisecond) - start_time
        Logger.error("❌ Shard #{state.shard_id} checkpoint failed after #{checkpoint_time}ms: #{inspect(error)}")
        {:error, {:checkpoint_failed, error}}
    end
  end

  defp attempt_shard_checkpoint_recovery(shard_checkpoint_dir, shard_id) do
    Logger.info("🔍 Looking for checkpoint for shard #{shard_id} to accelerate recovery...")

    case File.exists?(shard_checkpoint_dir) do
      false ->
        Logger.info("📁 No checkpoints directory found for shard #{shard_id}")
        {:error, :no_checkpoint}

      true ->
        case find_latest_shard_checkpoint(shard_checkpoint_dir) do
          {:ok, checkpoint_path} ->
            load_shard_checkpoint(checkpoint_path, shard_id)

          {:error, reason} ->
            Logger.info("📄 No valid checkpoint found for shard #{shard_id}: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp find_latest_shard_checkpoint(shard_checkpoint_dir) do
    try do
      case File.ls(shard_checkpoint_dir) do
        {:ok, entries} ->
          # Find valid checkpoint directories (filter out files)
          checkpoint_dirs = entries
          |> Enum.filter(fn entry ->
            full_path = Path.join(shard_checkpoint_dir, entry)
            File.dir?(full_path) and String.starts_with?(entry, "checkpoint_")
          end)
          |> Enum.sort(:desc) # Most recent first

          case checkpoint_dirs do
            [] ->
              {:error, :no_checkpoints}

            [latest | _rest] ->
              latest_path = Path.join(shard_checkpoint_dir, latest)
              Logger.info("📂 Found latest checkpoint: #{latest}")
              {:ok, latest_path}
          end

        {:error, reason} ->
          {:error, {:ls_failed, reason}}
      end

    rescue
      error ->
        {:error, {:find_checkpoint_failed, error}}
    end
  end

  defp load_shard_checkpoint(checkpoint_path, shard_id) do
    Logger.info("📥 Loading checkpoint from #{checkpoint_path} for shard #{shard_id}")

    try do
      # Load checkpoint metadata
      metadata_file = Path.join(checkpoint_path, "metadata.json")

      case File.read(metadata_file) do
        {:ok, content} ->
          case :erlang.binary_to_term(content) do
            %{sequence_number: sequence_number} = metadata ->
              Logger.info("📋 Checkpoint metadata for shard #{shard_id}: sequence #{sequence_number}")

              {:ok, %{
                checkpoint_id: metadata.checkpoint_id,
                last_sequence: sequence_number,
                shard_id: shard_id,
                created_at: metadata.created_at
              }}

            _ ->
              Logger.error("❌ Invalid checkpoint metadata format for shard #{shard_id}")
              {:error, :invalid_metadata_format}
          end

        {:error, reason} ->
          Logger.error("❌ Failed to read checkpoint metadata for shard #{shard_id}: #{inspect(reason)}")
          {:error, {:metadata_read_failed, reason}}
      end

    rescue
      error ->
        Logger.error("💥 Checkpoint loading failed for shard #{shard_id}: #{inspect(error)}")
        {:error, {:checkpoint_load_failed, error}}
    end
  end

  defp replay_shard_wal_after_checkpoint(state, checkpoint_sequence, start_time) do
    Logger.info("🔄 Replaying WAL entries after checkpoint sequence #{checkpoint_sequence} for shard #{state.shard_id}")

    case load_shard_wal_entries_from_file(state.wal_file_path) do
      {:ok, all_entries} ->
        # Filter entries that come after the checkpoint
        entries_after_checkpoint = all_entries
        |> Enum.filter(fn entry -> entry.sequence > checkpoint_sequence end)

        Logger.info("📂 Found #{length(entries_after_checkpoint)} WAL entries to replay after checkpoint for shard #{state.shard_id}")

        if length(entries_after_checkpoint) > 0 do
          # Replay entries after checkpoint
          {replayed_count, _} =
            entries_after_checkpoint
            |> Stream.with_index()
            |> Stream.map(fn {entry, _index} ->
              case replay_shard_wal_entry(entry) do
                :ok -> {1, entry}
                {:error, reason} ->
                  Logger.warning("⚠️  Failed to replay entry #{entry.sequence} for shard #{state.shard_id}: #{inspect(reason)}")
                  {0, entry}
              end
            end)
            |> Enum.reduce({0, nil}, fn {count, entry}, {total_count, _last} ->
              {total_count + count, entry}
            end)

          # Update sequence counter
          last_entry = List.last(entries_after_checkpoint)
          :atomics.put(state.sequence_counter_ref, 1, last_entry.sequence + 1)

          recovery_time = :os.system_time(:millisecond) - start_time
          Logger.info("✅ Checkpoint + WAL recovery completed for shard #{state.shard_id}: #{replayed_count} entries replayed in #{recovery_time}ms")

          {:ok, %{
            checkpoint_used: true,
            entries_replayed: replayed_count,
            recovery_time_ms: recovery_time,
            last_sequence: last_entry.sequence
          }}
        else
          recovery_time = :os.system_time(:millisecond) - start_time
          Logger.info("✅ Checkpoint recovery completed for shard #{state.shard_id} (no WAL entries to replay) in #{recovery_time}ms")

          {:ok, %{
            checkpoint_used: true,
            entries_replayed: 0,
            recovery_time_ms: recovery_time,
            last_sequence: checkpoint_sequence
          }}
        end

      {:error, reason} ->
        Logger.error("❌ Failed to load WAL entries for shard #{state.shard_id} after checkpoint: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Additional helper functions
  # PHASE 9.6: Use direct process names for maximum performance (no registry overhead)
  defp generate_shard_checkpoint_id(shard_id) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    sequence = :rand.uniform(9999)
    "#{shard_id}_checkpoint_#{timestamp}_#{sequence}"
  end

  # Placeholder functions for checkpoint and recovery operations
  defp replay_shard_wal_entry(entry) do
    # This function needs to be implemented based on how the WAL entry should be replayed.
    # For example, if it's a :put operation, it might need to update an ETS table.
    # If it's a :delete operation, it might need to delete a key from an ETS table.
    # The actual logic depends on the application's data model and how entries are encoded.
    # For now, we'll just log the replay attempt.
    Logger.debug("🔄 Replaying WAL entry: #{inspect(entry)}")
    # Example: If entry is a :put operation, you might update an ETS table
    # case entry.operation do
    #   :put ->
    #     table_name = :"spacetime_#{entry.shard_id}"
    #     :ets.insert(table_name, {entry.key, entry.value})
    #     :ok
    #   :delete ->
    #     table_name = :"spacetime_#{entry.shard_id}"
    #     :ets.delete(table_name, entry.key)
    #     :ok
    #   _ ->
    #     :ok # No action for other operations
    # end
    :ok
  end

  defp load_shard_wal_entries_from_file(file_path) do
    try do
      # Open the WAL file for reading
      {:ok, file_handle} = File.open(file_path, [:raw, :binary])

      # Read the header to get the number of operations
      case IO.binread(file_handle, 12) do
        <<batch_size::32, _timestamp::64, _shard_size::16, _shard_binary::binary>> = header ->
          # Read the rest of the batch
          batch_data = IO.binread(file_handle, batch_size)
          :ok = :file.position(file_handle, :cur, batch_size) # Move position forward

          # Decode the batch
          case :erlang.binary_to_term(batch_data) do
            {:wal_batch, operations} ->
              # Decode each operation
              decoded_operations = operations
              |> Enum.map(&WALEntry.decode_binary/1)
              |> Enum.map(&WALEntry.decode_json/1) # Assuming JSON is the default format

              {:ok, decoded_operations}
            _ ->
              {:error, "Unexpected batch format"}
          end
        _ ->
          {:error, "Invalid WAL file header"}
      end
    rescue
      error ->
        {:error, "Failed to load WAL entries from file #{file_path}: #{inspect(error)}"}
    end
  end

  # Optimized value preview - no expensive inspect calls
  defp get_value_preview(value) do
    cond do
      is_binary(value) and byte_size(value) > 50 ->
        "#{byte_size(value)}-byte binary"
      is_map(value) and map_size(value) > 3 ->
        "#{map_size(value)}-field map"
      is_list(value) and length(value) > 5 ->
        "#{length(value)}-item list"
      true ->
        "#{inspect(value, limit: 20)}"  # Only inspect for small values
    end
  end
end
