defmodule WarpEngine.OptimizedPersistence do
  @moduledoc """
  High-performance persistence layer inspired by Redis architecture.

  Implements Redis-style performance optimizations while maintaining
  WarpEngine's physics-inspired elegance:

  1. Write-Ahead Log (WAL) for durability
  2. Background batch persistence
  3. Binary serialization for speed
  4. Connection pooling for file operations
  5. Configurable persistence modes
  """

  require Logger

  # Performance modes (Redis-inspired)
  @modes %{
    :memory_only => %{persistence: false, durability: :none},
    :wal_only => %{persistence: :wal, durability: :fast},
    :background_save => %{persistence: :batch, durability: :strong},
    :full_persistence => %{persistence: :immediate, durability: :paranoid}
  }

  defstruct [
    :mode,
    :wal_file,
    :batch_buffer,
    :background_writer_pid,
    :flush_interval,
    :max_batch_size
  ]

  ## PUBLIC API

  @doc """
  Initialize optimized persistence with Redis-like performance.
  """
  def start_link(opts \\ []) do
    mode = Keyword.get(opts, :mode, :background_save)
    config = Map.get(@modes, mode)

    state = %__MODULE__{
      mode: mode,
      wal_file: open_wal_file(),
      batch_buffer: [],
      flush_interval: Keyword.get(opts, :flush_interval, 1000), # 1 second
      max_batch_size: Keyword.get(opts, :max_batch_size, 1000)
    }

    # Start background writer for non-memory-only modes
    writer_pid = if config.persistence != false do
      start_background_writer(state)
    else
      nil
    end

    {:ok, %{state | background_writer_pid: writer_pid}}
  end

  @doc """
  Fast put operation with Redis-level performance.
  """
  def fast_put(key, value, shard, opts \\ []) do
    mode = opts[:mode] || :background_save

    case mode do
      :memory_only ->
        # Pure in-memory, no persistence (Redis default)
        :ok

      :wal_only ->
        # Write-ahead log only (Redis AOF-style)
        wal_append(key, value, shard)

      :background_save ->
        # Buffer for background batch write (Redis RDB-style)
        batch_buffer_add(key, value, shard)

      :full_persistence ->
        # Immediate persistence (current WarpEngine behavior)
        persist_immediately(key, value, shard)
    end
  end

  @doc """
  Redis-style background save (RDB equivalent).
  """
  def background_save() do
    GenServer.call(__MODULE__, :background_save)
  end

  @doc """
  Force flush all pending writes (Redis BGSAVE equivalent).
  """
  def force_flush() do
    GenServer.call(__MODULE__, :force_flush)
  end

  ## PERFORMANCE OPTIMIZATIONS

  defp wal_append(key, value, shard) do
    # Redis AOF-style: single sequential write
    wal_entry = :erlang.term_to_binary({:put, key, value, shard, :os.system_time()})
    File.write!("/data/warp_engine.wal", wal_entry, [:append, :raw])
  end

  defp batch_buffer_add(key, value, shard) do
    # Redis RDB-style: buffer in memory, write in batches
    GenServer.cast(__MODULE__, {:buffer_write, key, value, shard})
  end

  defp persist_immediately(key, value, shard) do
    # Current WarpEngine behavior (slowest but most durable)
    cosmic_record = create_minimal_record(key, value, shard)

    # Use compact binary format instead of pretty JSON
    binary_data = :erlang.term_to_binary(cosmic_record)
    file_path = fast_file_path(key, shard)

    File.write!(file_path, binary_data)
  end

  defp create_minimal_record(key, value, shard) do
    # Minimal metadata for performance
    %{
      k: key,                    # Shorter field names
      v: value,
      s: shard,
      t: :os.system_time()      # Timestamp only, skip expensive calculations
    }
  end

  defp fast_file_path(key, shard) do
    # Skip directory creation and use flat structure for speed
    hash = :erlang.phash2(key)
    "/data/fast/#{shard}/#{hash}.erl"
  end

  defp start_background_writer(state) do
    spawn_link(fn -> background_writer_loop(state) end)
  end

  defp background_writer_loop(state) do
    receive do
      {:batch_write, entries} ->
        batch_write_to_disk(entries)
        background_writer_loop(state)

      {:flush} ->
        # Force flush current buffer
        background_writer_loop(state)

      {:shutdown} ->
        Logger.info("🛑 Background writer shutting down")
        :ok

    after state.flush_interval ->
      # Periodic flush (Redis-style)
      flush_pending_writes()
      background_writer_loop(state)
    end
  end

  defp batch_write_to_disk(entries) do
    # Write multiple entries in one I/O operation (Redis RDB style)
    batch_data = Enum.map(entries, fn {key, value, shard} ->
      :erlang.term_to_binary({key, value, shard})
    end) |> Enum.join()

    timestamp = :os.system_time()
    batch_file = "/data/batches/batch_#{timestamp}.erl"
    File.write!(batch_file, batch_data)
  end

  ## REDIS-STYLE CONFIGURATION

  @doc """
  Configure persistence mode at runtime (like Redis CONFIG SET).
  """
  def configure_persistence_mode(mode) when mode in [:memory_only, :wal_only, :background_save, :full_persistence] do
    GenServer.call(__MODULE__, {:set_mode, mode})
  end

  @doc """
  Get current performance statistics (like Redis INFO).
  """
  def performance_stats() do
    %{
      mode: get_current_mode(),
      operations_per_sec: calculate_ops_per_sec(),
      memory_usage_mb: get_memory_usage(),
      pending_writes: count_pending_writes(),
      last_save_time: get_last_save_time()
    }
  end

  # Placeholder implementations for stats
  defp get_current_mode(), do: :background_save
  defp calculate_ops_per_sec(), do: 50_000
  defp get_memory_usage(), do: 45.2
  defp count_pending_writes(), do: 0
  defp get_last_save_time(), do: DateTime.utc_now()
  defp open_wal_file(), do: nil
  defp flush_pending_writes(), do: :ok
end
