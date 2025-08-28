defmodule WarpEngine.IntelligentRouter do
  @moduledoc """
  Intelligent operation router that directs operations to CPU or GPU
  based on complexity and physics requirements.

  This module implements smart routing decisions to maximize performance:
  - Simple operations → Fast CPU path (no physics)
  - Physics-heavy operations → GPU batch processing
  - Mixed operations → Hybrid CPU/GPU processing
  """

  require Logger
  alias WarpEngine.GPU.PhysicsEngine
  # alias WarpEngine.GPU.OpenCLManager

  @doc """
  Route operation to optimal processing path.
  Analyzes operation complexity and directs to best execution engine.
  """
  def route_operation(operation) do
    complexity = analyze_operation_complexity(operation)

    Logger.debug("🎯 Routing operation: #{inspect(operation.key)}")
    Logger.debug("   Complexity: #{complexity}")

    case complexity do
      :simple ->
        Logger.debug("⚡ Fast path: CPU only, no physics")
        # Fast path: CPU only, no physics
        WarpEngine.FastPath.process(operation)

      :physics_heavy ->
        Logger.debug("🚀 GPU path: Batch with other physics operations")
        # GPU path: Batch with other physics operations
        add_to_gpu_batch(operation)

      :mixed ->
        Logger.debug("🔄 Hybrid: CPU for data, GPU for physics")
        # Hybrid: CPU for data, GPU for physics
        process_hybrid_operation(operation)
    end
  end

  @doc """
  Analyze operation complexity for routing decisions.
  Returns :simple, :physics_heavy, or :mixed.
  """
  def analyze_operation_complexity(operation) do
    complexity_score = calculate_complexity_score(operation)

    cond do
      complexity_score < 0.3 -> :simple
      complexity_score > 0.7 -> :physics_heavy
      true -> :mixed
    end
  end

  @doc """
  Add operation to GPU batch for parallel processing.
  Queues operations for efficient batch processing.
  """
  def add_to_gpu_batch(operation) do
    # Add to GPU operation queue
    case get_gpu_batch_queue() do
      nil ->
        # Initialize GPU batch queue if not exists
        initialize_gpu_batch_queue()
        add_to_gpu_batch(operation)

      queue ->
        # Add operation to existing queue
        updated_queue = [operation | queue]
        Process.put(:warp_engine_gpu_batch_queue, updated_queue)

        # Check if batch is ready for processing
        if length(updated_queue) >= get_batch_size() do
          process_gpu_batch()
        else
          # Return immediately with async processing
          {:ok, :queued_for_gpu, length(updated_queue)}
        end
    end
  end

  @doc """
  Process hybrid operation using both CPU and GPU.
  CPU handles data operations, GPU handles physics calculations.
  """
  def process_hybrid_operation(operation) do
    Logger.debug("🔄 Processing hybrid operation: #{inspect(operation.key)}")

    # Extract data and physics components
    {data_operation, physics_operation} = split_hybrid_operation(operation)

    # Process data on CPU (fast path)
    data_result = WarpEngine.FastPath.process(data_operation)

    # Queue physics for GPU batch processing via global batcher
    _ = WarpEngine.GPU.PhysicsBatcher.enqueue(physics_operation)

    # Return immediately with data path result; physics runs asynchronously in batches
    case data_result do
      {:ok, :stored, shard, time} ->
        {:ok, :hybrid_processed, %{shard: shard, timestamp: time}}
      other ->
        {:ok, :hybrid_processed, %{result: other}}
    end
  end

  @doc """
  Get current GPU batch queue status.
  """
  def get_gpu_batch_status() do
    case get_gpu_batch_queue() do
      nil -> %{queue_size: 0, batch_size: get_batch_size()}
      queue -> %{queue_size: length(queue), batch_size: get_batch_size()}
    end
  end

  # Private implementation functions

  defp calculate_complexity_score(operation) do
    # Calculate complexity based on operation characteristics
    base_score = 0.0

    # Physics complexity factors
    physics_score = if has_physics_requirements?(operation), do: 0.4, else: 0.0

    # Data complexity factors
    data_score = case get_in(operation, [:data_size]) do
      size when is_integer(size) and size > 1000 -> 0.3
      size when is_integer(size) and size > 100 -> 0.2
      _ -> 0.0
    end

    # Access pattern complexity
    access_score = case get_in(operation, [:access_pattern]) do
      :complex -> 0.2
      :balanced -> 0.1
      _ -> 0.0
    end

    # Temporal complexity
    temporal_score = if has_temporal_requirements?(operation), do: 0.1, else: 0.0

    base_score + physics_score + data_score + access_score + temporal_score
  end

  defp has_physics_requirements?(operation) do
    # Check if operation requires physics calculations
    get_in(operation, [:physics]) != nil or
    get_in(operation, [:gravitational_routing]) != nil or
    get_in(operation, [:quantum_entanglement]) != nil or
    get_in(operation, [:entropy_monitoring]) != nil
  end

  defp has_temporal_requirements?(operation) do
    # Check if operation has temporal dependencies
    get_in(operation, [:temporal_weight]) != nil or
    get_in(operation, [:lifecycle]) != nil or
    get_in(operation, [:timestamp]) != nil
  end

  defp split_hybrid_operation(operation) do
    # Split operation into data and physics components
    data_operation = %{
      key: operation.key,
      value: operation.value,
      data_size: get_in(operation, [:data_size]),
      access_pattern: get_in(operation, [:access_pattern])
    }

    physics_operation = %{
      key: operation.key,
      physics: get_in(operation, [:physics]),
      gravitational_routing: get_in(operation, [:gravitational_routing]),
      quantum_entanglement: get_in(operation, [:quantum_entanglement]),
      entropy_monitoring: get_in(operation, [:entropy_monitoring])
    }

    {data_operation, physics_operation}
  end

  defp get_gpu_batch_queue() do
    Process.get(:warp_engine_gpu_batch_queue)
  end

  defp initialize_gpu_batch_queue() do
    Process.put(:warp_engine_gpu_batch_queue, [])
  end

  defp get_batch_size() do
    Application.get_env(:warp_engine, :gpu_batch_size, 1000)
  end

  defp process_gpu_batch() do
    case get_gpu_batch_queue() do
      nil ->
        Logger.warning("⚠️  No GPU batch queue to process")
        {:error, :no_batch_queue}

      [] ->
        Logger.debug("📭 GPU batch queue is empty")
        {:ok, :empty_queue}

      operations ->
        Logger.info("🚀 Processing GPU batch: #{length(operations)} operations")

        # Clear the queue
        Process.put(:warp_engine_gpu_batch_queue, [])

        # Process physics batch on GPU
        case process_physics_on_gpu(operations) do
          {:ok, results} ->
            Logger.info("✅ GPU batch processed successfully")
            {:ok, :gpu_batch_processed, results}

          {:error, _reason} ->
            Logger.warning("⚠️  GPU batch failed, using CPU fallback")
            # Fallback to CPU processing
            results = process_physics_on_cpu(operations)
            {:ok, :gpu_batch_cpu_fallback, results}
        end
    end
  end

  defp process_physics_on_gpu(operations) do
    # Use GPU Physics Engine for batch processing
    PhysicsEngine.process_physics_batch(operations)
  end

  defp process_physics_on_cpu(operations) do
    # Fallback to CPU physics processing
    Logger.debug("🔄 Processing physics on CPU: #{length(operations)} operations")

    Enum.map(operations, fn operation ->
      # Simple CPU physics calculations
      %{
        operation: operation,
        gravitational_score: calculate_cpu_gravitational(operation),
        quantum_correlation: calculate_cpu_quantum(operation),
        entropy_score: calculate_cpu_entropy(operation),
        physics_metadata: %{
          calculated_at: :erlang.system_time(:millisecond),
          gpu_accelerated: false
        }
      }
    end)
  end

  defp calculate_cpu_gravitational(operation) do
    g = 6.67430e-11
    m1 = get_in(operation, [:physics, :data_mass]) || 1.0
    m2 = get_in(operation, [:physics, :shard_mass]) || 1.0
    r = get_in(operation, [:physics, :distance]) || 1.0

    g * m1 * m2 / (r * r)
  end

  defp calculate_cpu_quantum(operation) do
    pattern = get_in(operation, [:physics, :access_pattern]) || 0.5
    temporal = get_in(operation, [:physics, :temporal_weight]) || 0.5

    pattern * temporal * 0.5
  end

  defp calculate_cpu_entropy(operation) do
    p = get_in(operation, [:physics, :load_distribution]) || 0.5

    if p > 0.0 and p < 1.0 do
      -p * :math.log2(p) - (1.0 - p) * :math.log2(1.0 - p)
    else
      0.0
    end
  end
end
