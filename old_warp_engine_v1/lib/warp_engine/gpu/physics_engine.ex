defmodule WarpEngine.GPU.PhysicsEngine do
  @moduledoc """
  GPU-accelerated physics calculations engine.
  Processes physics operations in parallel using OpenCL through clex.

  This module provides batch processing of physics calculations including:
  - Gravitational routing calculations (G·m₁·m₂/r²)
  - Quantum correlation analysis
  - Entropy monitoring calculations
  - Multi-dimensional coordinate transformations
  """

  require Logger
  # alias WarpEngine.GPU.OpenCLManager

  @doc """
  Batch gravitational routing calculations on GPU using Nx/Candlex.
  """
  def calculate_gravitational_batch(operations) do
    {data_masses_list, shard_masses_list, distances_list} =
      prepare_gravitational_data(operations)

    # Vectorized compute on the configured Nx backend (Candlex CUDA if active)
    g = 6.67430e-11
    eps = 1.0e-6

    gpu_backend = {Candlex.Backend, device: :cuda}
    data_masses = Nx.tensor(data_masses_list, type: :f32) |> Nx.backend_transfer(gpu_backend)
    shard_masses = Nx.tensor(shard_masses_list, type: :f32) |> Nx.backend_transfer(gpu_backend)
    distances = Nx.tensor(distances_list, type: :f32) |> Nx.backend_transfer(gpu_backend)

    scores =
      Nx.divide(
        Nx.multiply(g, Nx.multiply(data_masses, shard_masses)),
        Nx.add(Nx.multiply(distances, distances), eps)
      )

    # Optional debug of backends
    if System.get_env("WE_DEBUG_GPU") in ["1", "true"] do
      Logger.info("data_masses backend: #{inspect(data_masses)}")
      Logger.info("scores backend: #{inspect(scores)}")
    end

    scores_list = Nx.to_flat_list(scores)

    results =
      operations
      |> Enum.zip(scores_list)
      |> Enum.map(fn {operation, score} ->
        Map.put(operation, :gravitational_score, score)
      end)

    {:ok, results}
  end

  @doc """
  Batch quantum correlation calculations on GPU.
  Analyzes access patterns and temporal relationships in parallel.
  """
  def calculate_quantum_correlations_batch(operations) do
    Logger.debug("🔮 Processing quantum correlation batch: #{length(operations)} operations")

    {access_patterns_list, temporal_weights_list} = prepare_quantum_data(operations)

    gpu_backend = {Candlex.Backend, device: :cuda}
    access_patterns = Nx.tensor(access_patterns_list, type: :f32) |> Nx.backend_transfer(gpu_backend)
    temporal_weights = Nx.tensor(temporal_weights_list, type: :f32) |> Nx.backend_transfer(gpu_backend)

    # Example vectorized correlation (keep consistent with CPU fallback scale)
    scores = Nx.multiply(Nx.multiply(access_patterns, temporal_weights), 0.5)
    scores_list = Nx.to_flat_list(scores)

    results =
      operations
      |> Enum.zip(scores_list)
      |> Enum.map(fn {operation, score} ->
        Map.put(operation, :quantum_correlation, score)
      end)

    {:ok, results}
  end

  @doc """
  Batch entropy calculations on GPU.
  Computes Shannon entropy for load distribution analysis.
  """
  def calculate_entropy_batch(operations) do
    Logger.debug("📊 Processing entropy batch: #{length(operations)} operations")

    load_distributions_list = prepare_entropy_data(operations)

    ln2 = :math.log(2)
    gpu_backend = {Candlex.Backend, device: :cuda}
    p = Nx.tensor(load_distributions_list, type: :f32) |> Nx.backend_transfer(gpu_backend)
    p_safe = Nx.clip(p, 1.0e-12, 1.0 - 1.0e-12)
    one_minus_p = Nx.subtract(1.0, p_safe)
    entropy =
      Nx.multiply(-1.0,
        Nx.add(
          Nx.multiply(p_safe, Nx.divide(Nx.log(p_safe), ln2)),
          Nx.multiply(one_minus_p, Nx.divide(Nx.log(one_minus_p), ln2))
        )
      )

    scores_list = Nx.to_flat_list(entropy)

    results =
      operations
      |> Enum.zip(scores_list)
      |> Enum.map(fn {operation, score} ->
        Map.put(operation, :entropy_score, score)
      end)

    {:ok, results}
  end

  @doc """
  Process complete physics calculation batch on GPU.
  Combines all physics calculations for maximum efficiency.
  """
  def process_physics_batch(operations) do
    # Reduce noise: only log batch processing when explicitly enabled
    if System.get_env("WE_LOG_PHYSICS_BATCHES") in ["1", "true"] do
      Logger.info("🚀 Processing complete physics batch: #{length(operations)} operations")
    end

    # Process all physics calculations in parallel
    with {:ok, gravitational_results} <- calculate_gravitational_batch(operations),
         {:ok, quantum_results} <- calculate_quantum_correlations_batch(operations),
         {:ok, entropy_results} <- calculate_entropy_batch(operations) do

      # Combine all physics results
      combined_results = Enum.zip([gravitational_results, quantum_results, entropy_results])
      |> Enum.map(fn {grav_op, quantum_op, entropy_op} ->
        # Each result is an operation with added score fields
        %{
          operation: grav_op,
          gravitational_score: grav_op.gravitational_score,
          quantum_correlation: quantum_op.quantum_correlation,
          entropy_score: entropy_op.entropy_score,
          physics_metadata: %{
            calculated_at: :erlang.system_time(:millisecond),
            gpu_accelerated: Candlex.Backend.cuda_available?()
          }
        }
      end)

      {:ok, combined_results}
    else
      {:error, reason} ->
        Logger.error("❌ Physics batch processing failed: #{reason}")
        {:error, reason}
    end
  end

  # Private helper functions

  # GPU-optimized data preparation with padding for better utilization
  defp prepare_gravitational_data_optimized(operations, optimized_batch_size) do
    # Extract gravitational parameters from operations
    data_masses = Enum.map(operations, fn op ->
      get_in(op, [:physics, :data_mass]) || 1.0
    end)

    shard_masses = Enum.map(operations, fn op ->
      get_in(op, [:physics, :shard_mass]) || 1.0
    end)

    distances = Enum.map(operations, fn op ->
      get_in(op, [:physics, :distance]) || 1.0
    end)

    # Pad arrays to optimized batch size for better GPU utilization
    current_size = length(operations)
    if current_size < optimized_batch_size do
      padding_size = optimized_batch_size - current_size
      padding_masses = List.duplicate(1.0, padding_size)
      padding_distances = List.duplicate(1.0, padding_size)

      padded_data_masses = data_masses ++ padding_masses
      padded_shard_masses = shard_masses ++ padding_masses
      padded_distances = distances ++ padding_distances

      {padded_data_masses, padded_shard_masses, padded_distances}
    else
      {data_masses, shard_masses, distances}
    end
  end

  defp prepare_gravitational_data(operations) do
    # Extract gravitational parameters from operations
    data_masses = Enum.map(operations, fn op ->
      get_in(op, [:physics, :data_mass]) || 1.0
    end)

    shard_masses = Enum.map(operations, fn op ->
      get_in(op, [:physics, :shard_mass]) || 1.0
    end)

    distances = Enum.map(operations, fn op ->
      get_in(op, [:physics, :distance]) || 1.0
    end)

    {data_masses, shard_masses, distances}
  end

  defp prepare_quantum_data(operations) do
    # Extract quantum parameters from operations
    access_patterns = Enum.map(operations, fn op ->
      get_in(op, [:physics, :access_pattern]) || 0.5
    end)

    temporal_weights = Enum.map(operations, fn op ->
      get_in(op, [:physics, :temporal_weight]) || 0.5
    end)

    {access_patterns, temporal_weights}
  end

  defp prepare_quantum_data_optimized(operations, optimized_batch_size) do
    # Extract quantum parameters from operations
    access_patterns = Enum.map(operations, fn op ->
      get_in(op, [:physics, :access_pattern]) || 0.5
    end)

    temporal_weights = Enum.map(operations, fn op ->
      get_in(op, [:physics, :temporal_weight]) || 0.5
    end)

    # Pad arrays to optimized batch size for better GPU utilization
    current_size = length(operations)
    if current_size < optimized_batch_size do
      padding_size = optimized_batch_size - current_size
      padding_patterns = List.duplicate(0.5, padding_size)
      padding_temporal = List.duplicate(0.5, padding_size)

      padded_patterns = access_patterns ++ padding_patterns
      padded_temporal = temporal_weights ++ padding_temporal

      {padded_patterns, padded_temporal}
    else
      {access_patterns, temporal_weights}
    end
  end

  defp prepare_entropy_data(operations) do
    # Extract entropy parameters from operations
    Enum.map(operations, fn op ->
      get_in(op, [:physics, :load_distribution]) || 0.5
    end)
  end

  defp prepare_entropy_data_optimized(operations, optimized_batch_size) do
    # Extract entropy parameters from operations
    load_distributions = Enum.map(operations, fn op ->
      get_in(op, [:physics, :load_distribution]) || 0.5
    end)

    # Pad arrays to optimized batch size for better GPU utilization
    current_size = length(operations)
    if current_size < optimized_batch_size do
      padding_size = optimized_batch_size - current_size
      padding_distributions = List.duplicate(0.5, padding_size)

      # Ensure all values are floats
      padded_distributions = load_distributions ++ padding_distributions
      Enum.map(padded_distributions, &(&1 * 1.0))  # Force float conversion
    else
      # Ensure all values are floats
      Enum.map(load_distributions, &(&1 * 1.0))  # Force float conversion
    end
  end

  # CPU fallback implementations

  defp calculate_gravitational_cpu_fallback(operations) do
    Logger.debug("🔄 Calculating gravitational scores on CPU")
    Logger.debug("   Operations count: #{length(operations)}")
    Logger.debug("   First operation: #{inspect(List.first(operations))}")

    results = Enum.map(operations, fn operation ->
      g = 6.67430e-11
      m1 = get_in(operation, [:physics, :data_mass]) || 1.0
      m2 = get_in(operation, [:physics, :shard_mass]) || 1.0
      r = get_in(operation, [:physics, :distance]) || 1.0

      score = g * m1 * m2 / (r * r)
      result = Map.put(operation, :gravitational_score, score)
      Logger.debug("   Operation key: #{operation.key || "unknown"}, score: #{score}")
      Logger.debug("   Result: #{inspect(result)}")
      result
    end)

    Logger.debug("   CPU fallback results count: #{length(results)}")
    Logger.debug("   First result: #{inspect(List.first(results))}")
    results
  end

  defp calculate_quantum_cpu_fallback(operations) do
    Logger.debug("🔄 Calculating quantum correlations on CPU")

    Enum.map(operations, fn operation ->
      pattern = get_in(operation, [:physics, :access_pattern]) || 0.5
      temporal = get_in(operation, [:physics, :temporal_weight]) || 0.5

      score = pattern * temporal * 0.5
      Map.put(operation, :quantum_correlation, score)
    end)
  end

  defp calculate_entropy_cpu_fallback(operations) do
    Logger.debug("🔄 Calculating entropy scores on CPU")

    Enum.map(operations, fn operation ->
      p = get_in(operation, [:physics, :load_distribution]) || 0.5

      score = if p > 0.0 and p < 1.0 do
        -p * :math.log2(p) - (1.0 - p) * :math.log2(1.0 - p)
      else
        0.0
      end

      Map.put(operation, :entropy_score, score)
    end)
  end
end
