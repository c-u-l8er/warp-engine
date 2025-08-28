defmodule WarpEngine.GPU.OpenCLManager do
  @moduledoc """
  GPU acceleration manager for WarpEngine physics calculations using Candlex.
  Provides GPU device management, memory allocation, and kernel execution.

  This module uses Candlex (Nx backend) with CUDA support for maximum performance
  and compatibility with WarpEngine's physics-inspired architecture.
  """

  require Logger

  defstruct [
    :platform_id,
    :device_id,
    :context,
    :command_queue,
    :available_memory,
    :max_compute_units,
    :device_name,
    :initialized,
    :nx_backend,
    :has_gpu_backend
  ]

  @doc """
  Initialize GPU acceleration system using Nx.
  Detects available GPU devices and sets up Nx backend.
  """
  def initialize_gpu_system() do
    Logger.info("🚀 Initializing Nx GPU acceleration system...")

    case detect_gpu_devices() do
      {:ok, devices} ->
        case initialize_nx_gpu_context(devices) do
          {:ok, gpu_state} ->
            Logger.info("✅ Nx GPU system initialized successfully")
            Logger.info("   Device: #{gpu_state.device_name}")
            Logger.info("   Memory: #{gpu_state.available_memory} MB")
            Logger.info("   Compute Units: #{gpu_state.max_compute_units}")
            Logger.info("   Nx Backend: #{inspect(gpu_state.nx_backend)}")
            {:ok, gpu_state}

          {:error, reason} ->
            Logger.warning("⚠️  Failed to initialize Nx GPU context: #{reason}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.warning("⚠️  No GPU devices detected: #{reason}")
        Logger.info("   Falling back to CPU-only mode")
        {:error, :no_gpu_devices}
    end
  end

  @doc """
  Get GPU device information and capabilities.
  """
  def get_gpu_info() do
    case Process.get(:warp_engine_gpu_state) do
      nil ->
        {:error, :gpu_not_initialized}

      gpu_state ->
        {:ok, %{
          device_name: gpu_state.device_name,
          available_memory: gpu_state.available_memory,
          max_compute_units: gpu_state.max_compute_units,
          initialized: gpu_state.initialized,
          nx_backend: gpu_state.nx_backend,
          has_gpu_backend: gpu_state.has_gpu_backend
        }}
    end
  end

  @doc """
  Execute GPU kernel with data for physics calculations using Nx.
  """
  def execute_kernel(kernel_name, data_arrays, batch_size) do
    case Process.get(:warp_engine_gpu_state) do
      nil ->
        Logger.warning("⚠️  GPU not initialized, falling back to CPU")
        execute_kernel_cpu_fallback(kernel_name, data_arrays, batch_size)

      gpu_state ->
        case execute_kernel_gpu(gpu_state, kernel_name, data_arrays, batch_size) do
          {:ok, results} ->
            {:ok, results}

          {:error, reason} ->
            Logger.warning("⚠️  GPU kernel execution failed: #{reason}")
            Logger.info("   Falling back to CPU execution")
            execute_kernel_cpu_fallback(kernel_name, data_arrays, batch_size)
        end
    end
  end

  @doc """
  Check if GPU is available and properly initialized.
  Returns true only if we have actual GPU backends available.
  """
  def gpu_available?() do
    case Process.get(:warp_engine_gpu_state) do
      %__MODULE__{initialized: true, has_gpu_backend: true} ->
        Logger.debug("✅ GPU is available with GPU backend")
        true
      %__MODULE__{initialized: true, has_gpu_backend: false} ->
        Logger.debug("⚠️  GPU system initialized but only CPU backend available")
        false
      _ ->
        Logger.debug("❌ GPU system not initialized")
        false
    end
  end

  # Private implementation functions

  defp detect_gpu_devices() do
    Logger.debug("🔍 Detecting GPU devices using Candlex...")

    # Check if we can use Candlex with GPU backends
    try do
      backend = Application.get_env(:nx, :default_backend, Nx.default_backend())
      cond do
        is_candlex_cuda_backend?(backend) and Candlex.Backend.cuda_available?() ->
          Logger.info("   🚀 Candlex CUDA backend active")
          {:ok, [%{backend: :candlex_cuda, name: "Candlex CUDA Backend", memory_mb: 8192, compute_units: 24, type: :candlex_gpu}]}

        is_candlex_backend?(backend) ->
          Logger.info("   ℹ️  Candlex backend active (CPU mode)")
          {:ok, [%{backend: :candlex_cpu, name: "Candlex CPU Backend", memory_mb: 8192, compute_units: 24, type: :candlex_backend}]}

        true ->
          Logger.debug("   ℹ️  Using Nx backend: #{inspect(backend)}")
          {:ok, [%{backend: backend, name: "Nx Backend", memory_mb: 8192, compute_units: 24, type: :nx_backend}]}
      end
    rescue
      error ->
        Logger.warning("⚠️  Failed to detect GPU devices: #{inspect(error)}")
        {:error, "Candlex not available: #{inspect(error)}"}
    end
  end

  defp initialize_nx_gpu_context(devices) do
    [primary_device | _] = devices

    # Check if Candlex GPU backend is available
    has_gpu_backend = case System.get_env("CANDLEX_NIF_TARGET") do
      "cuda" ->
        # Double-check that CUDA is actually available
        if Candlex.Backend.cuda_available?() do
          Logger.info("   ✅ Candlex CUDA backend detected and available")
          ensure_batcher_started()
          true
        else
          Logger.warning("   ⚠️  CANDLEX_NIF_TARGET=cuda set but CUDA not available, falling back to CPU")
          false
        end
      _ ->
        # Check if we can detect Candlex backend at runtime
        try do
          current_backend = Application.get_env(:nx, :default_backend, Nx.default_backend())
          cond do
            is_candlex_cuda_backend?(current_backend) and Candlex.Backend.cuda_available?() ->
              Logger.info("   ✅ Candlex CUDA backend detected: #{inspect(current_backend)}")
              ensure_batcher_started()
              true
            is_candlex_backend?(current_backend) ->
              Logger.info("   ℹ️  Candlex CPU backend detected: #{inspect(current_backend)} (no CUDA hardware)")
              false
            true ->
              Logger.warning("   ⚠️  Candlex backend not configured")
              false
          end
        rescue
          _ ->
            Logger.warning("   ⚠️  Candlex backend not configured")
            false
        end
    end

    # Set Nx default backend
    if has_gpu_backend do
      Application.put_env(:nx, :default_backend, {Candlex.Backend, device: :cuda})
      Nx.default_backend({Candlex.Backend, device: :cuda})
      Logger.info("   Using Candlex GPU backend ({Candlex.Backend, device: :cuda})")
    else
      Application.put_env(:nx, :default_backend, Nx.BinaryBackend)
      Nx.default_backend(Nx.BinaryBackend)
      Logger.info("   Using Nx Binary backend (CPU)")
    end

    gpu_state = %__MODULE__{
      platform_id: :candlex_platform,
      device_id: :candlex_device,
      context: :candlex_context,
      command_queue: :candlex_queue,
      available_memory: primary_device.memory_mb,
      max_compute_units: primary_device.compute_units,
      device_name: primary_device.name,
      initialized: true,
      nx_backend: Nx.default_backend(),
      has_gpu_backend: has_gpu_backend
    }

    Process.put(:warp_engine_gpu_state, gpu_state)
    {:ok, gpu_state}
  end

  defp is_candlex_backend?(backend) do
    backend == Candlex.Backend or match?({Candlex.Backend, _kw}, backend)
  end

  defp is_candlex_cuda_backend?(backend) do
    match?({Candlex.Backend, device: :cuda}, backend) or
      (backend == Candlex.Backend and System.get_env("CANDLEX_NIF_TARGET") == "cuda")
  end

  defp ensure_batcher_started() do
    case Process.whereis(WarpEngine.GPU.PhysicsBatcher) do
      nil ->
        case WarpEngine.GPU.PhysicsBatcher.start_link([]) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _}} -> :ok
          _ -> :ok
        end
      _ -> :ok
    end
  end

  defp execute_kernel_gpu(gpu_state, kernel_name, data_arrays, batch_size) do
    # Use Nx for GPU kernel execution
    Logger.debug("🎯 Executing Nx GPU kernel: #{kernel_name}")
    Logger.debug("   Batch size: #{batch_size}")
    Logger.debug("   Nx Backend: #{inspect(gpu_state.nx_backend)}")

    case kernel_name do
      "gravitational_routing_batch" ->
        execute_gravitational_nx(data_arrays, batch_size)

      "quantum_correlation_batch" ->
        execute_quantum_nx(data_arrays, batch_size)

      "entropy_calculation_batch" ->
        execute_entropy_nx(data_arrays, batch_size)

      _ ->
        {:error, "Unknown kernel: #{kernel_name}"}
    end
  end

  defp execute_gravitational_nx([data_masses, shard_masses, distances], batch_size) do
    try do
      # Check if we actually have GPU backend
      gpu_state = Process.get(:warp_engine_gpu_state)
      if gpu_state && gpu_state.has_gpu_backend do
        Logger.info("🚀 Candlex GPU-optimized gravitational calculation (batch: #{batch_size})")
      else
        Logger.info("🔄 Candlex CPU-based gravitational calculation (batch: #{batch_size})")
      end

      # Get current backend
      current_backend = Nx.default_backend()
      Logger.debug("   Using Nx backend: #{inspect(current_backend)}")

      # Convert to Nx tensors with explicit type for efficiency
      masses1 = Nx.tensor(data_masses, type: :f32, backend: current_backend)
      masses2 = Nx.tensor(shard_masses, type: :f32, backend: current_backend)
      dist = Nx.tensor(distances, type: :f32, backend: current_backend)

      # Vectorized G·m₁·m₂/r² calculation - optimized for parallel processing
      g = Nx.tensor(6.67430e-11, type: :f32, backend: current_backend)

      # Use fused operations for better utilization
      mass_product = Nx.multiply(masses1, masses2)
      distance_squared = Nx.multiply(dist, dist)

      # Single fused operation: G * (m1 * m2) / (r * r)
      gravitational_scores = Nx.divide(Nx.multiply(mass_product, g), distance_squared)

      # Force computation to complete
      gravitational_scores = Nx.backend_transfer(gravitational_scores)

      # Convert back to list
      result = Nx.to_list(gravitational_scores)

      if gpu_state && gpu_state.has_gpu_backend do
        Logger.info("   Candlex GPU calculation completed: #{length(result)} results")
      else
        Logger.info("   Candlex CPU calculation completed: #{length(result)} results")
      end
      Logger.debug("   Backend used: #{inspect(current_backend)}")
      Logger.debug("   Performance: #{batch_size} operations completed")
      {:ok, result}
    rescue
      error ->
        Logger.error("   Candlex gravitational calculation failed: #{inspect(error)}")
        Logger.error("   Data masses: #{inspect(data_masses)}")
        Logger.error("   Shard masses: #{inspect(shard_masses)}")
        Logger.error("   Distances: #{inspect(distances)}")
        {:error, "Candlex calculation failed: #{inspect(error)}"}
    end
  end

  defp execute_quantum_nx([access_patterns, temporal_weights], batch_size) do
    try do
      Logger.debug("🔮 Candlex GPU-optimized quantum correlation calculation (batch: #{batch_size})")

      # Convert to Nx tensors with explicit type and backend
      backend = Nx.default_backend()
      patterns = Nx.tensor(access_patterns, type: :f32, backend: backend)
      temporal = Nx.tensor(temporal_weights, type: :f32, backend: backend)

      # Vectorized quantum correlation calculation: pattern * temporal * 0.5
      correlation_factor = Nx.tensor(0.5, type: :f32, backend: backend)

      # Single fused operation for better GPU utilization
      correlation_scores = Nx.multiply(Nx.multiply(patterns, temporal), correlation_factor)

      # Force computation to complete on GPU
      correlation_scores = Nx.backend_transfer(correlation_scores)

      # Convert back to list
      result = Nx.to_list(correlation_scores)
      Logger.debug("   Quantum Candlex calculation completed: #{length(result)} correlations")
      Logger.debug("   Backend used: #{inspect(backend)}")
      {:ok, result}
    rescue
      error ->
        Logger.error("   Quantum Candlex calculation failed: #{inspect(error)}")
        {:error, "Quantum Candlex calculation failed: #{inspect(error)}"}
    end
  end

  defp execute_entropy_nx([load_distributions], batch_size) do
    try do
      Logger.debug("📊 Candlex GPU-optimized entropy calculation (batch: #{batch_size})")

      # Convert to Nx tensors with explicit type and backend
      backend = Nx.default_backend()

      # Force all values to be floats before creating tensor
      float_distributions = Enum.map(load_distributions, &(&1 * 1.0))

      p = Nx.tensor(float_distributions, type: :f32, backend: backend)

      # Optimized Shannon entropy calculation using Nx
      # H(p) = -p * log2(p) - (1-p) * log2(1-p)
      one = Nx.tensor(1.0, type: :f32, backend: backend)
      epsilon = Nx.tensor(1.0e-10, type: :f32, backend: backend)
      one_minus_p = Nx.subtract(one, p)

      # Handle log(0) cases with GPU-friendly operations
      p_safe = Nx.add(p, epsilon)
      one_minus_p_safe = Nx.add(one_minus_p, epsilon)

      # Calculate entropy components using ln(x)/ln(2) instead of log2(x) for Candlex compatibility
      ln_2 = Nx.tensor(:math.log(2), type: :f32, backend: backend)
      entropy_p = Nx.multiply(p_safe, Nx.divide(Nx.log(p_safe), ln_2))
      entropy_one_minus_p = Nx.multiply(one_minus_p_safe, Nx.divide(Nx.log(one_minus_p_safe), ln_2))

      # Combine entropy components
      entropy = Nx.subtract(Nx.add(entropy_p, entropy_one_minus_p), Nx.tensor(0.0, type: :f32, backend: backend))

      # Force computation to complete on GPU
      entropy = Nx.backend_transfer(entropy)

      # Convert back to list
      result = Nx.to_list(entropy)
      Logger.debug("   Entropy Candlex calculation completed: #{length(result)} values")
      Logger.debug("   Backend used: #{inspect(backend)}")
      {:ok, result}
    rescue
      error ->
        Logger.error("   Entropy Candlex calculation failed: #{inspect(error)}")
        {:error, "Entropy Candlex calculation failed: #{inspect(error)}"}
    end
  end

  defp execute_kernel_cpu_fallback(kernel_name, data_arrays, batch_size) do
    Logger.debug("🔄 CPU fallback for kernel: #{kernel_name}")

    case kernel_name do
      "gravitational_routing_batch" ->
        execute_gravitational_cpu_fallback(data_arrays, batch_size)

      "quantum_correlation_batch" ->
        execute_quantum_cpu_fallback(data_arrays, batch_size)

      "entropy_calculation_batch" ->
        execute_entropy_cpu_fallback(data_arrays, batch_size)

      _ ->
        {:error, "Unknown kernel: #{kernel_name}"}
    end
  end

  defp execute_gravitational_cpu_fallback([data_masses, shard_masses, distances], _batch_size) do
    # CPU fallback for gravitational calculations
    results = Enum.zip([data_masses, shard_masses, distances])
    |> Enum.map(fn {m1, m2, d} ->
      g = 6.67430e-11
      if d > 0, do: g * m1 * m2 / (d * d), else: 0.0
    end)

    {:ok, results}
  end

  defp execute_quantum_cpu_fallback([access_patterns, temporal_weights], _batch_size) do
    # CPU fallback for quantum correlation calculations
    results = Enum.zip([access_patterns, temporal_weights])
    |> Enum.map(fn {pattern, temporal} ->
      pattern * temporal * 0.5
    end)

    {:ok, results}
  end

  defp execute_entropy_cpu_fallback([load_distributions], _batch_size) do
    # CPU fallback for entropy calculations
    results = Enum.map(load_distributions, fn p ->
      if p > 0 and p < 1 do
        -p * :math.log2(p) - (1 - p) * :math.log2(1 - p)
      else
        0.0
      end
    end)

    {:ok, results}
  end
end
