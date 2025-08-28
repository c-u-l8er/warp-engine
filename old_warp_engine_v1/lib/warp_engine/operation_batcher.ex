defmodule WarpEngine.OperationBatcher do
  @moduledoc """
  Operation Batcher for Phase 9.3 High-Concurrency Optimization.

  Reduces per-operation overhead at high concurrency levels by intelligently
  batching operations within process boundaries and across shard boundaries.

  ## Key Optimizations

  - **Process-Local Batching**: Accumulate operations within each process
  - **Cross-Shard Coordination**: Batch operations going to the same shard
  - **Adaptive Batch Sizing**: Adjust batch size based on concurrency level
  - **Minimal Latency Impact**: Flush batches frequently to maintain responsiveness

  ## Target Performance

  - 16 processes: Recover 200K ops/sec peak performance
  - 20+ processes: Maintain 150K+ ops/sec with reduced overhead
  - High concurrency: Enable linear scaling beyond 24 processes
  """

  use GenServer
  require Logger

  defstruct [
    :batch_buffer,              # Process-local operation buffer
    :batch_size_target,         # Current target batch size
    :concurrency_level,         # Detected concurrency level
    :last_flush_time,           # Timestamp of last batch flush
    :performance_metrics,       # Real-time performance tracking
    :adaptive_sizing_enabled    # Whether adaptive batch sizing is active
  ]

  # Configuration constants
  @default_batch_size 10
  @max_batch_size 100
  @flush_interval_ms 5        # Maximum time before forced flush

  ## Public API

  @doc """
  Start the operation batcher.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Queue an operation for batched execution.

  Returns immediately for non-blocking behavior. Operations are automatically
  batched and flushed based on current system conditions.
  """
  def queue_operation(operation_type, key, value, opts \\ []) do
    # Check if batching should be used based on current concurrency
    if should_use_batching?() do
      GenServer.cast(__MODULE__, {:queue_operation, operation_type, key, value, opts})
    else
      # Execute immediately for low concurrency scenarios
      execute_operation_immediately(operation_type, key, value, opts)
    end
  end

  @doc """
  Force flush all pending batches immediately.
  """
  def force_flush() do
    GenServer.call(__MODULE__, :force_flush)
  end

  @doc """
  Get current batching statistics.
  """
  def get_batching_stats() do
    GenServer.call(__MODULE__, :get_batching_stats)
  end

  @doc """
  Update concurrency level for adaptive batch sizing.
  """
  def update_concurrency_level(level) do
    GenServer.cast(__MODULE__, {:update_concurrency_level, level})
  end

  ## GenServer Implementation

  @impl true
  def init(_opts) do
    initial_state = %__MODULE__{
      batch_buffer: %{},
      batch_size_target: @default_batch_size,
      concurrency_level: 1,
      last_flush_time: :os.system_time(:millisecond),
      performance_metrics: %{},
      adaptive_sizing_enabled: true
    }

    # Schedule periodic flushing
    schedule_batch_flush()

    Logger.info("⚡ Operation Batcher started - enabling high-concurrency optimization")
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:queue_operation, operation_type, key, value, opts}, state) do
    # Determine target shard for this operation
    shard_id = determine_operation_shard(key, opts)

    # Add operation to the appropriate shard batch
    updated_buffer = add_to_batch(state.batch_buffer, shard_id, {operation_type, key, value, opts})

    # Check if any shard batch should be flushed
    {final_buffer, flush_occurred} = maybe_flush_ready_batches(updated_buffer, state)

    updated_state = %{state | batch_buffer: final_buffer}

    # Update flush time if we flushed
    final_state = if flush_occurred do
      %{updated_state | last_flush_time: :os.system_time(:millisecond)}
    else
      updated_state
    end

    {:noreply, final_state}
  end

  @impl true
  def handle_cast({:update_concurrency_level, level}, state) do
    # Adapt batch size based on concurrency level
    new_batch_size = calculate_optimal_batch_size(level)

    updated_state = %{state |
      concurrency_level: level,
      batch_size_target: new_batch_size
    }

    Logger.info("📊 Updated concurrency level to #{level}, batch size to #{new_batch_size}")

    {:noreply, updated_state}
  end

  @impl true
  def handle_call(:force_flush, _from, state) do
    # Flush all pending batches immediately
    flush_count = flush_all_batches(state.batch_buffer)

    updated_state = %{state |
      batch_buffer: %{},
      last_flush_time: :os.system_time(:millisecond)
    }

    {:reply, {:ok, flush_count}, updated_state}
  end

  @impl true
  def handle_call(:get_batching_stats, _from, state) do
    stats = %{
      current_batch_size_target: state.batch_size_target,
      concurrency_level: state.concurrency_level,
      pending_operations: count_pending_operations(state.batch_buffer),
      pending_batches: map_size(state.batch_buffer),
      adaptive_sizing_enabled: state.adaptive_sizing_enabled,
      last_flush_time: state.last_flush_time
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_info(:flush_batches, state) do
    current_time = :os.system_time(:millisecond)
    time_since_flush = current_time - state.last_flush_time

    # Force flush if too much time has passed or if batches are large
    should_force_flush = time_since_flush >= @flush_interval_ms or
                        has_large_batches?(state.batch_buffer, state.batch_size_target)

    final_state = if should_force_flush and not Enum.empty?(state.batch_buffer) do
      flush_all_batches(state.batch_buffer)
      %{state | batch_buffer: %{}, last_flush_time: current_time}
    else
      state
    end

    # Schedule next flush cycle
    schedule_batch_flush()

    {:noreply, final_state}
  end

  ## Private Implementation

  defp should_use_batching?() do
    # Simple batching logic - avoid Process.list() overhead
    false  # Disable batching entirely for now to recover baseline performance
  end

  defp execute_operation_immediately(operation_type, key, value, opts) do
    # Execute single operation without batching overhead
    case operation_type do
      :put -> WarpEngine.cosmic_put(key, value, opts)
      :get -> WarpEngine.cosmic_get(key)
      :delete -> WarpEngine.cosmic_delete(key)
    end
  end

  defp determine_operation_shard(key, opts) do
    # Use the intelligent load balancer to determine optimal shard
    case Keyword.get(opts, :access_pattern) do
      pattern when pattern in [:hot, :warm, :cold] ->
        # Explicit pattern provided
        case pattern do
          :hot -> :hot_data
          :warm -> :warm_data
          :cold -> :cold_data
        end
      _ ->
        # Use intelligent load balancer
        WarpEngine.IntelligentLoadBalancer.get_optimal_shard(key, %{
          operation_type: :put,
          batched: true,
          priority: Keyword.get(opts, :priority, :normal)
        })
    end
  end

  defp add_to_batch(buffer, shard_id, operation) do
    current_batch = Map.get(buffer, shard_id, [])
    updated_batch = [operation | current_batch]
    Map.put(buffer, shard_id, updated_batch)
  end

  defp maybe_flush_ready_batches(buffer, state) do
    # Check each shard batch and flush if it's ready
    {updated_buffer, flushed_any} = Enum.reduce(buffer, {%{}, false}, fn {shard_id, batch}, {acc_buffer, flushed} ->
      if length(batch) >= state.batch_size_target do
        # Flush this batch
        flush_shard_batch(shard_id, batch)
        {acc_buffer, true}
      else
        # Keep this batch
        {Map.put(acc_buffer, shard_id, batch), flushed}
      end
    end)

    {updated_buffer, flushed_any}
  end

  defp flush_shard_batch(shard_id, operations) do
    # Execute all operations in the batch for this shard
    Logger.debug("🔄 Flushing batch for shard #{shard_id}: #{length(operations)} operations")

    # Group operations by type for optimal execution
    grouped_ops = Enum.group_by(operations, fn {op_type, _key, _value, _opts} -> op_type end)

    # Execute each operation type in batches
    Enum.each(grouped_ops, fn {op_type, ops} ->
      execute_operation_batch(op_type, ops, shard_id)
    end)
  end

  defp execute_operation_batch(:put, operations, _shard_id) do
    # Execute PUT operations efficiently
    Enum.each(operations, fn {_op_type, key, value, opts} ->
      WarpEngine.cosmic_put(key, value, opts)
    end)
  end

  defp execute_operation_batch(:get, operations, _shard_id) do
    # Execute GET operations efficiently
    Enum.each(operations, fn {_op_type, key, _value, opts} ->
      WarpEngine.cosmic_get(key)
    end)
  end

  defp execute_operation_batch(:delete, operations, _shard_id) do
    # Execute DELETE operations efficiently
    Enum.each(operations, fn {_op_type, key, _value, opts} ->
      WarpEngine.cosmic_delete(key)
    end)
  end

  defp flush_all_batches(buffer) do
    total_operations = Enum.reduce(buffer, 0, fn {shard_id, batch}, acc ->
      flush_shard_batch(shard_id, batch)
      acc + length(batch)
    end)

    Logger.debug("⚡ Flushed all batches: #{total_operations} operations across #{map_size(buffer)} shards")
    total_operations
  end

  defp calculate_optimal_batch_size(concurrency_level) do
    # Adaptive batch sizing based on concurrency level
    base_size = case concurrency_level do
      level when level <= 4 -> 5      # Small batches for low concurrency
      level when level <= 8 -> 10     # Medium batches
      level when level <= 16 -> 20    # Larger batches for high concurrency
      level when level <= 24 -> 30    # Very large batches
      _ -> 50                          # Maximum batching for extreme concurrency
    end

    min(@max_batch_size, base_size)
  end

  defp count_pending_operations(buffer) do
    Enum.reduce(buffer, 0, fn {_shard, batch}, acc ->
      acc + length(batch)
    end)
  end

  defp has_large_batches?(buffer, target_size) do
    Enum.any?(buffer, fn {_shard, batch} ->
      length(batch) >= target_size * 0.8  # 80% of target size
    end)
  end

  defp schedule_batch_flush() do
    Process.send_after(self(), :flush_batches, @flush_interval_ms)
  end
end
