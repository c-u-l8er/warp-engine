defmodule WarpEngine.WALCoordinator do
  @moduledoc """
  WAL Coordinator managing per-shard WAL processes for linear concurrency scaling.

  This module replaces the single WAL GenServer bottleneck with a distributed
  architecture where each spacetime shard has its own dedicated WAL process.
  This eliminates the concurrency degradation and enables linear scaling from
  77K → 200K+ operations/second.

  ## Architecture Benefits

  - **Eliminates Bottleneck**: No single GenServer serialization point
  - **Linear Scaling**: Each shard processes operations independently
  - **Parallel I/O**: Multiple WAL files written in parallel
  - **NUMA Optimization**: WAL processes pinned to specific CPU cores
  - **Independent Recovery**: Each shard can recover independently

  ## Performance Target

  - 200K+ ops/sec (vs current 77K peak)
  - Linear concurrency scaling up to 16+ processes
  - <100μs per-shard WAL latency maintained
  - Zero concurrency degradation

  ## Shard Distribution

  ```
  ┌─────────────────┬─────────────────┬─────────────────┐
  │   Hot Shard     │   Warm Shard    │   Cold Shard    │
  │   (Core 0)      │   (Core 1)      │   (Core 2)      │
  ├─────────────────┼─────────────────┼─────────────────┤
  │ WALShard PID 1  │ WALShard PID 2  │ WALShard PID 3  │
  │ cosmic_hot.wal  │ cosmic_warm.wal │ cosmic_cold.wal │
  │ Hot ETS Table   │ Warm ETS Table  │ Cold ETS Table  │
  │ Atomic Counter  │ Atomic Counter  │ Atomic Counter  │
  └─────────────────┴─────────────────┴─────────────────┘
  ```
  """

  use GenServer
  require Logger

  defstruct [
    :shard_processes,      # Map of shard_id -> WALShard pid
    :data_root,            # Root directory for WAL files
    :registry_pid,         # Process registry for shard lookups
    :stats,                # Aggregate statistics across shards
    :opts,                 # Configuration options
    :shard_ids             # Configured shard identifiers
  ]

  # Standard spacetime shards
  # Phase 9.5: Use 12 numbered shards and include legacy hot/warm/cold for compatibility
  @spacetime_shards [
    :shard_0, :shard_1, :shard_2, :shard_3,
    :shard_4, :shard_5, :shard_6, :shard_7,
    :shard_8, :shard_9, :shard_10, :shard_11,
    :shard_12, :shard_13, :shard_14, :shard_15,
    :shard_16, :shard_17, :shard_18, :shard_19,
    :shard_20, :shard_21, :shard_22, :shard_23,
    # Legacy 3-shard system to support existing APIs/tests
    :hot_data, :warm_data, :cold_data
  ]

  ## PUBLIC API

  @doc """
  Start the WAL coordinator and all shard processes.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Asynchronously append an operation to the appropriate shard WAL.
  This routes to the correct shard process, eliminating cross-shard contention.
  """
  def async_append(shard_id, operation) do
    WarpEngine.WALShard.async_append(shard_id, operation)
  end

  @doc """
  PHASE 9.8: Fire-and-forget WAL append - absolute minimum overhead.
  Sends raw operation data without complex WAL entry creation.
  """
  def fire_and_forget_append(shard_id, operation_type, key, value, sequence_number) do
    # Send minimal data directly to WAL shard (no WALEntry object overhead)
    shard_name = WarpEngine.WALShard.via_tuple(shard_id)

    case Process.whereis(shard_name) do
      pid when is_pid(pid) ->
        # Direct send to existing process - fastest path
        send(pid, {:fire_and_forget, operation_type, key, value, sequence_number})
      nil ->
        # Process doesn't exist - skip WAL for this operation (fire-and-forget)
        # This prevents crashes but loses durability for operations during restarts
        :skipped
    end
  end

  @doc """
  Get next sequence number for a specific shard.
  Each shard maintains independent sequence numbering.
  """
  def next_sequence(shard_id) do
    WarpEngine.WALShard.next_sequence(shard_id)
  end

  @doc """
  ULTRA-PERFORMANCE: Get direct atomic counter reference for a shard.
  Use for maximum speed sequence generation without GenServer calls.
  """
  def get_sequence_counter(shard_id) do
    WarpEngine.WALShard.get_sequence_counter(shard_id)
  end

  @doc """
  Force flush write buffers for all shards.
  """
  def force_flush_all() do
    GenServer.call(__MODULE__, :force_flush_all)
  end

  @doc """
  Force flush write buffer for a specific shard.
  """
  def force_flush(shard_id) do
    WarpEngine.WALShard.force_flush(shard_id)
  end

  @doc """
  Create coordinated checkpoint across all shards.
  """
  def create_coordinated_checkpoint() do
    GenServer.call(__MODULE__, :create_coordinated_checkpoint, 180_000)
  end

  @doc """
  Recover all shards from their respective WAL files.
  """
  def recover_all_shards() do
    GenServer.call(__MODULE__, :recover_all_shards, 300_000)
  end

  @doc """
  Get aggregate statistics across all WAL shards.
  """
  def aggregate_stats() do
    GenServer.call(__MODULE__, :aggregate_stats)
  end

  @doc """
  Get statistics for a specific shard.
  """
  def shard_stats(shard_id) do
    WarpEngine.WALShard.stats(shard_id)
  end

  @doc """
  Get information about running shard processes.
  """
  def shard_processes() do
    GenServer.call(__MODULE__, :shard_processes)
  end

  @doc """
  Check health status of all WAL shards.
  """
  def health_check() do
    GenServer.call(__MODULE__, :health_check)
  end

  ## GENSERVER CALLBACKS

  def init(opts) do
    try do
      Logger.info("🚀 Starting WAL Coordinator for per-shard architecture...")

      # Start process registry for shard lookups
      {:ok, registry_pid} = Registry.start_link(keys: :unique, name: WarpEngine.WALRegistry)

      # Initialize coordinator state
      # Determine shard topology based on configuration
      shard_ids = compute_shard_ids(opts)

      state = %WarpEngine.WALCoordinator{
        shard_processes: %{},
        data_root: Keyword.get(opts, :data_root, "/tmp/warp_engine_data"),
        registry_pid: registry_pid,
        stats: initialize_coordinator_stats(),
        opts: opts,
        shard_ids: shard_ids
      }

      # Start WAL shard processes for each spacetime shard
      Logger.info("📡 Starting WAL shard processes (#{length(state.shard_ids)}) ...")
      shard_results = start_all_shard_processes(state.shard_ids, state.data_root, opts)

      # Verify all shards started successfully
      case verify_shard_startup(shard_results) do
        {:ok, shard_processes} ->
          final_state = %{state | shard_processes: shard_processes}

          # PHASE 9.7: Pre-cache atomic counter references for ultra-fast sequence generation
          cache_atomic_counters(shard_processes)

          Logger.info("✅ WAL Coordinator started successfully!")
          Logger.info("⚡ Per-shard WAL architecture ready for linear concurrency scaling!")
          Logger.info("📊 Active shards: #{map_size(shard_processes)} | Shards: #{Enum.join(Enum.map(state.shard_ids, &to_string/1), ", ")}")

          {:ok, final_state}

        {:error, failed_shards} ->
          Logger.error("❌ WAL Coordinator startup failed - shard failures: #{inspect(failed_shards)}")
          {:stop, {:shard_startup_failed, failed_shards}}
      end

    rescue
      error ->
        Logger.error("❌ WAL Coordinator initialization failed: #{inspect(error)}")
        {:stop, {:coordinator_init_failed, error}}
    end
  end

  def handle_call(:force_flush_all, _from, state) do
    Logger.info("🚿 Forcing flush on all WAL shards...")
    start_time = :os.system_time(:millisecond)

    # Force flush all shards in parallel
    flush_results = state.shard_ids
    |> Enum.map(fn shard_id ->
      Task.async(fn ->
        {shard_id, WarpEngine.WALShard.force_flush(shard_id)}
      end)
    end)
    |> Enum.map(&Task.await(&1, 5000))

    flush_time = :os.system_time(:millisecond) - start_time
    successful_flushes = Enum.count(flush_results, fn {_shard, result} -> result == :ok end)

    Logger.info("✅ Flush complete: #{successful_flushes}/#{length(state.shard_ids)} shards in #{flush_time}ms")

    {:reply, {:ok, flush_results}, state}
  end

  def handle_info(:flush_hint, state) do
    # Forward flush hint to all shard processes (non-blocking)
    Enum.each(state.shard_processes, fn {_shard_id, pid} -> send(pid, :flush_hint) end)
    {:noreply, state}
  end

  def handle_call(:create_coordinated_checkpoint, _from, state) do
    Logger.info("📸 Creating coordinated checkpoint across all shards...")
    start_time = :os.system_time(:millisecond)

    # Create checkpoints for all shards in parallel
    checkpoint_results = state.shard_ids
    |> Enum.map(fn shard_id ->
      Task.async(fn ->
        {shard_id, WarpEngine.WALShard.create_checkpoint(shard_id)}
      end)
    end)
    |> Enum.map(&Task.await(&1, 60_000))

    checkpoint_time = :os.system_time(:millisecond) - start_time
    successful_checkpoints = Enum.count(checkpoint_results, fn {_shard, result} ->
      match?({:ok, _}, result)
    end)

    # Create coordinated checkpoint metadata
    coordinated_metadata = %{
      coordinator_checkpoint_id: generate_coordinated_checkpoint_id(),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      shard_checkpoints: checkpoint_results,
      successful_count: successful_checkpoints,
      total_shards: length(state.shard_ids),
      checkpoint_time_ms: checkpoint_time,
      version: "9.1.0"
    }

    # Save coordinated checkpoint metadata
    save_coordinated_checkpoint_metadata(coordinated_metadata, state.data_root)

    Logger.info("✅ Coordinated checkpoint complete: #{successful_checkpoints}/#{length(state.shard_ids)} shards in #{checkpoint_time}ms")

    {:reply, {:ok, coordinated_metadata}, state}
  end

  def handle_call(:recover_all_shards, _from, state) do
    Logger.info("🔄 Starting coordinated recovery of all WAL shards...")
    start_time = :os.system_time(:millisecond)

    # Recover all shards in parallel
    recovery_results = state.shard_ids
    |> Enum.map(fn shard_id ->
      Task.async(fn ->
        {shard_id, WarpEngine.WALShard.recover_from_wal(shard_id)}
      end)
    end)
    |> Enum.map(&Task.await(&1, 120_000))

    recovery_time = :os.system_time(:millisecond) - start_time
    successful_recoveries = Enum.count(recovery_results, fn {_shard, result} ->
      match?({:ok, _}, result)
    end)

    Logger.info("✅ Coordinated recovery complete: #{successful_recoveries}/#{length(state.shard_ids)} shards in #{recovery_time}ms")

    recovery_summary = %{
      recovery_time_ms: recovery_time,
      successful_recoveries: successful_recoveries,
      total_shards: length(state.shard_ids),
      shard_results: recovery_results
    }

    {:reply, {:ok, recovery_summary}, state}
  end

  def handle_call(:aggregate_stats, _from, state) do
    # Collect statistics from all shards
    start_time = :os.system_time(:millisecond)

    shard_stats = state.shard_ids
    |> Enum.map(fn shard_id ->
      {shard_id, WarpEngine.WALShard.stats(shard_id)}
    end)
    |> Enum.into(%{})

    collection_time = :os.system_time(:millisecond) - start_time

    # Calculate aggregate statistics
    aggregate = calculate_aggregate_stats(shard_stats)

    final_stats = %{
      coordinator_stats: %{
        collection_time_ms: collection_time,
        active_shards: length(state.shard_ids),
        coordinator_uptime: :os.system_time(:millisecond) - state.stats.started_at
      },
      shard_stats: shard_stats,
      aggregate: aggregate
    }

    {:reply, final_stats, state}
  end

  def handle_call(:shard_processes, _from, state) do
    processes_info = state.shard_ids
    |> Enum.map(fn shard_id ->
      pid = get_shard_pid(shard_id)
      status = if Process.alive?(pid), do: :alive, else: :dead

      {shard_id, %{pid: pid, status: status}}
    end)
    |> Enum.into(%{})

    {:reply, processes_info, state}
  end

  def handle_call(:health_check, _from, state) do
    # Check health of all shard processes
    health_results = state.shard_ids
    |> Enum.map(fn shard_id ->
      try do
        pid = get_shard_pid(shard_id)
        status = if Process.alive?(pid) do
          # Try to get stats to verify shard is responding
          case WarpEngine.WALShard.stats(shard_id) do
            %{} -> :healthy
            _ -> :unhealthy
          end
        else
          :dead
        end

        {shard_id, status}
      rescue
        _ -> {shard_id, :error}
      end
    end)
    |> Enum.into(%{})

    healthy_count = Enum.count(health_results, fn {_shard, status} -> status == :healthy end)
    overall_health = if healthy_count == length(state.shard_ids), do: :healthy, else: :degraded

    health_report = %{
      overall_health: overall_health,
      healthy_shards: healthy_count,
      total_shards: length(state.shard_ids),
      shard_health: health_results,
      checked_at: DateTime.utc_now()
    }

    {:reply, health_report, state}
  end

  def terminate(_reason, state) do
    Logger.info("🛑 WAL Coordinator shutting down...")

    # Gracefully stop all shard processes
    state.shard_ids
    |> Enum.each(fn shard_id ->
      try do
        pid = get_shard_pid(shard_id)
        if Process.alive?(pid) do
          GenServer.stop(pid, :shutdown, 5000)
        end
      rescue
        error ->
          Logger.warning("⚠️  Error stopping shard #{shard_id}: #{inspect(error)}")
      end
    end)

    Logger.info("✅ WAL Coordinator shutdown complete")
    :ok
  end

  ## PRIVATE FUNCTIONS

  defp start_all_shard_processes(shard_ids, data_root, opts) do
    shard_ids
    |> Enum.map(fn shard_id ->
      Logger.info("🚀 Starting WAL shard: #{shard_id}")

      shard_opts = Keyword.merge(opts, [
        data_root: data_root,
        shard_id: shard_id
      ])

      case WarpEngine.WALShard.start_link(shard_id, shard_opts) do
        {:ok, pid} ->
          Logger.info("✅ WAL shard #{shard_id} started: #{inspect(pid)}")
          {shard_id, {:ok, pid}}

        {:error, reason} ->
          Logger.error("❌ WAL shard #{shard_id} failed to start: #{inspect(reason)}")
          {shard_id, {:error, reason}}
      end
    end)
  end

  defp compute_shard_ids(_opts) do
    use_numbered = Application.get_env(:warp_engine, :use_numbered_shards, false)
    if use_numbered do
      num =
        Application.get_env(:warp_engine, :num_numbered_shards,
          min(System.schedulers_online(), 24)
        )
        |> max(1)
        |> min(24)

      Enum.map(0..(num - 1), fn i -> String.to_atom("shard_" <> Integer.to_string(i)) end)
    else
      [:hot_data, :warm_data, :cold_data]
    end
  end

  defp verify_shard_startup(shard_results) do
    {successful, failed} = Enum.split_with(shard_results, fn {_shard, result} ->
      match?({:ok, _pid}, result)
    end)

    if length(failed) == 0 do
      shard_processes = successful
      |> Enum.map(fn {shard_id, {:ok, pid}} -> {shard_id, pid} end)
      |> Enum.into(%{})

      {:ok, shard_processes}
    else
      failed_shards = Enum.map(failed, fn {shard_id, {:error, reason}} ->
        {shard_id, reason}
      end)

      {:error, failed_shards}
    end
  end

  defp initialize_coordinator_stats() do
    %{
      started_at: :os.system_time(:millisecond),
      coordinated_checkpoints: 0,
      coordinated_recoveries: 0,
      total_flush_operations: 0
    }
  end

  defp calculate_aggregate_stats(shard_stats) do
    # Calculate totals across all shards
    total_operations = shard_stats
    |> Map.values()
    |> Enum.map(fn stats -> stats.total_operations end)
    |> Enum.sum()

    total_flushes = shard_stats
    |> Map.values()
    |> Enum.map(fn stats -> stats.total_flushes end)
    |> Enum.sum()

    avg_flush_times = shard_stats
    |> Map.values()
    |> Enum.map(fn stats -> stats.avg_flush_time_ms end)

    overall_avg_flush_time = if length(avg_flush_times) > 0 do
      Enum.sum(avg_flush_times) / length(avg_flush_times)
    else
      0.0
    end

    shard_count = map_size(shard_stats)

    %{
      total_operations: total_operations,
      total_flushes: total_flushes,
      overall_avg_flush_time_ms: overall_avg_flush_time,
      operations_per_shard: (if shard_count > 0, do: div(total_operations, shard_count), else: 0),
      active_shards: shard_count
    }
  end

  defp get_shard_pid(shard_id) do
    Process.whereis(WarpEngine.WALShard.via_tuple(shard_id))
  end

  defp generate_coordinated_checkpoint_id() do
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    sequence = :rand.uniform(9999)
    "coordinated_checkpoint_#{timestamp}_#{sequence}"
  end

  defp save_coordinated_checkpoint_metadata(metadata, data_root) do
    try do
      wal_directory = Path.join(data_root, "wal")
      File.mkdir_p!(wal_directory)

      metadata_file = Path.join(wal_directory, "coordinated_checkpoint_metadata.json")
      File.write!(metadata_file, :erlang.term_to_binary(metadata))

      Logger.debug("📝 Coordinated checkpoint metadata saved: #{metadata_file}")
    rescue
      error ->
        Logger.warning("⚠️  Failed to save coordinated checkpoint metadata: #{inspect(error)}")
    end
  end

  ## BACKWARD COMPATIBILITY FUNCTIONS
  ## These provide the same API as the original WAL module

  @doc """
  Backward compatibility: async_append without specifying shard.
  Routes based on operation key or falls back to balanced distribution.
  """
  def async_append(operation) do
    shard_id = determine_shard_from_operation(operation)
    async_append(shard_id, operation)
  end

  @doc """
  Backward compatibility: next_sequence without specifying shard.
  Uses hot_data shard by default for compatibility.
  """
  def next_sequence() do
    next_sequence(:hot_data)
  end

  @doc """
  Backward compatibility: get_sequence_counter without specifying shard.
  Uses hot_data shard by default for compatibility.
  """
  def get_sequence_counter() do
    get_sequence_counter(:hot_data)
  end

  # PHASE 9.7: Pre-cache atomic counter references for ultra-fast sequence generation
  # This eliminates ALL GenServer calls during high-frequency operations
  defp cache_atomic_counters(shard_processes) do
    Logger.info("⚡ PHASE 9.7: Caching atomic counter references for zero-overhead sequence generation...")

    cached_counters = Enum.reduce(shard_processes, %{}, fn {shard_id, _pid}, acc ->
      try do
        # Get the atomic counter reference directly (one-time GenServer call)
        counter_ref = WarpEngine.WALShard.get_sequence_counter(shard_id)
        Map.put(acc, shard_id, counter_ref)
      rescue
        error ->
          Logger.warning("⚠️  Failed to cache counter for shard #{shard_id}: #{inspect(error)}")
          acc
      end
    end)

    # Store in Application environment for global access (no process dictionary needed)
    Application.put_env(:warp_engine, :shard_counters, cached_counters)

    Logger.info("✅ Cached #{map_size(cached_counters)} atomic counter references - sequence generation is now zero-overhead!")
  end

  # Helper function to determine shard from operation for backward compatibility
  defp determine_shard_from_operation(%{shard_id: shard_id}) when shard_id != nil do
    shard_id
  end

  defp determine_shard_from_operation(%{key: key}) when is_binary(key) do
    # Simple hash-based routing for backward compatibility
    case :erlang.phash2(key, 3) do
      0 -> :hot_data
      1 -> :warm_data
      2 -> :cold_data
    end
  end

  defp determine_shard_from_operation(_operation) do
    # Default to warm_data for balanced load
    :warm_data
  end
end
