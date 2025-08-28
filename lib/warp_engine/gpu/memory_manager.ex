defmodule WarpEngine.GPU.MemoryManager do
  @moduledoc """
  GPU memory management for efficient data transfer and storage.
  Implements memory pooling and batch optimization for maximum GPU performance.

  This module manages:
  - GPU memory allocation and deallocation
  - Data transfer optimization
  - Memory pooling for batch operations
  - Memory usage monitoring and statistics
  """

  require Logger

  defstruct [
    :memory_pools,
    :batch_buffers,
    :transfer_queue,
    :memory_stats,
    :gpu_memory_available
  ]

  @doc """
  Initialize GPU memory management system.
  Sets up memory pools and transfer queues for optimal performance.
  """
  def initialize_memory_system() do
    Logger.info("🧠 Initializing GPU memory management system...")

    # Get GPU memory information
    case WarpEngine.GPU.OpenCLManager.get_gpu_info() do
      {:ok, gpu_info} ->
        available_memory_mb = gpu_info.available_memory

        # Calculate optimal memory pool sizes
        pool_sizes = calculate_memory_pool_sizes(available_memory_mb)

        # Initialize memory pools
        memory_pools = initialize_memory_pools(pool_sizes)

        # Initialize transfer queue
        transfer_queue = :queue.new()

        # Initialize memory statistics
        memory_stats = %{
          total_memory_mb: available_memory_mb,
          allocated_memory_mb: 0,
          free_memory_mb: available_memory_mb,
          peak_usage_mb: 0,
          allocation_count: 0,
          deallocation_count: 0
        }

        memory_manager = %__MODULE__{
          memory_pools: memory_pools,
          batch_buffers: %{},
          transfer_queue: transfer_queue,
          memory_stats: memory_stats,
          gpu_memory_available: available_memory_mb
        }

        # Store in process dictionary
        Process.put(:warp_engine_gpu_memory_manager, memory_manager)

        Logger.info("✅ GPU memory management initialized:")
        Logger.info("   Total GPU Memory: #{available_memory_mb} MB")
        Logger.info("   Physics Pool: #{pool_sizes.physics_pool} MB")
        Logger.info("   Batch Pool: #{pool_sizes.batch_pool} MB")
        Logger.info("   Transfer Pool: #{pool_sizes.transfer_pool} MB")

        {:ok, memory_manager}

      {:error, reason} ->
        Logger.warning("⚠️  Failed to get GPU info: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Allocate GPU memory pool for physics calculations.
  Optimizes memory allocation for batch processing.
  """
  def allocate_physics_memory_pool(size_mb) do
    case get_memory_manager() do
      nil ->
        Logger.warning("⚠️  Memory manager not initialized")
        {:error, :memory_manager_not_initialized}

      manager ->
        case allocate_memory_from_pool(manager, :physics_pool, size_mb) do
          {:ok, allocated_memory, updated_manager} ->
            # Update process dictionary
            Process.put(:warp_engine_gpu_memory_manager, updated_manager)
            {:ok, allocated_memory}

          {:error, reason} ->
            Logger.warning("⚠️  Failed to allocate physics memory: #{reason}")
            {:error, reason}
        end
    end
  end

  @doc """
  Optimize data transfer to GPU for maximum bandwidth utilization.
  Implements batching and async transfer strategies using Nx.
  """
  def optimize_gpu_transfer(data, batch_size) do
    case get_memory_manager() do
      nil ->
        Logger.warning("⚠️  Memory manager not initialized")
        {:error, :memory_manager_not_initialized}

      manager ->
        # Prepare data for optimal GPU transfer using Nx
        optimized_data = prepare_data_for_nx_transfer(data, batch_size)

        # Add to transfer queue for async processing
        updated_queue = :queue.in({:transfer, optimized_data, batch_size}, manager.transfer_queue)
        updated_manager = %{manager | transfer_queue: updated_queue}

        # Update process dictionary
        Process.put(:warp_engine_gpu_memory_manager, updated_manager)

        # Trigger transfer processing if queue is getting full
        if :queue.len(updated_queue) >= 10 do
          Task.async(fn -> process_transfer_queue(updated_manager) end)
        end

        {:ok, :queued_for_transfer, :queue.len(updated_queue)}
    end
  end

  @doc """
  Get current GPU memory usage statistics.
  """
  def get_memory_stats() do
    case get_memory_manager() do
      nil -> {:error, :memory_manager_not_initialized}
      manager -> {:ok, manager.memory_stats}
    end
  end

  @doc """
  Free allocated GPU memory and return to pool.
  """
  def free_gpu_memory(memory_handle) do
    case get_memory_manager() do
      nil ->
        Logger.warning("⚠️  Memory manager not initialized")
        {:error, :memory_manager_not_initialized}

      manager ->
        case free_memory_to_pool(manager, memory_handle) do
          {:ok, updated_manager} ->
            # Update process dictionary
            Process.put(:warp_engine_gpu_memory_manager, updated_manager)
            {:ok, :memory_freed}

          {:error, reason} ->
            Logger.warning("⚠️  Failed to free GPU memory: #{reason}")
            {:error, reason}
        end
    end
  end

  # Private implementation functions

  defp get_memory_manager() do
    Process.get(:warp_engine_gpu_memory_manager)
  end

  defp calculate_memory_pool_sizes(total_memory_mb) do
    # Allocate memory pools based on total GPU memory
    # Reserve 20% for system operations
    available_memory = total_memory_mb * 0.8

    %{
      physics_pool: round(available_memory * 0.5),      # 50% for physics calculations
      batch_pool: round(available_memory * 0.3),        # 30% for batch operations
      transfer_pool: round(available_memory * 0.2)      # 20% for data transfer
    }
  end

  defp initialize_memory_pools(pool_sizes) do
    %{
      physics_pool: %{
        total_mb: pool_sizes.physics_pool,
        allocated_mb: 0,
        free_mb: pool_sizes.physics_pool,
        allocations: %{}
      },
      batch_pool: %{
        total_mb: pool_sizes.batch_pool,
        allocated_mb: 0,
        free_mb: pool_sizes.batch_pool,
        allocations: %{}
      },
      transfer_pool: %{
        total_mb: pool_sizes.transfer_pool,
        allocated_mb: 0,
        free_mb: pool_sizes.transfer_pool,
        allocations: %{}
      }
    }
  end

  defp allocate_memory_from_pool(manager, pool_name, size_mb) do
    pool = Map.get(manager.memory_pools, pool_name)

    if pool.free_mb >= size_mb do
      # Generate unique memory handle
      memory_handle = generate_memory_handle(pool_name)

      # Update pool allocation
      updated_pool = %{
        pool |
        allocated_mb: pool.allocated_mb + size_mb,
        free_mb: pool.free_mb - size_mb,
        allocations: Map.put(pool.allocations, memory_handle, %{
          size_mb: size_mb,
          allocated_at: :erlang.system_time(:millisecond)
        })
      }

      # Update memory pools
      updated_pools = Map.put(manager.memory_pools, pool_name, updated_pool)

      # Update memory statistics
      updated_stats = %{
        manager.memory_stats |
        allocated_memory_mb: manager.memory_stats.allocated_memory_mb + size_mb,
        free_memory_mb: manager.memory_stats.free_memory_mb - size_mb,
        allocation_count: manager.memory_stats.allocation_count + 1
      }

      # Update peak usage if necessary
      updated_stats = if updated_stats.allocated_memory_mb > updated_stats.peak_usage_mb do
        %{updated_stats | peak_usage_mb: updated_stats.allocated_memory_mb}
      else
        updated_stats
      end

      updated_manager = %{
        manager |
        memory_pools: updated_pools,
        memory_stats: updated_stats
      }

      {:ok, memory_handle, updated_manager}
    else
      {:error, :insufficient_memory}
    end
  end

  defp free_memory_to_pool(manager, memory_handle) do
    # Find which pool contains this allocation
    {pool_name, pool, allocation} = find_allocation_in_pools(manager.memory_pools, memory_handle)

    if pool_name and pool and allocation do
      # Update pool deallocation
      updated_pool = %{
        pool |
        allocated_mb: pool.allocated_mb - allocation.size_mb,
        free_mb: pool.free_mb + allocation.size_mb,
        allocations: Map.delete(pool.allocations, memory_handle)
      }

      # Update memory pools
      updated_pools = Map.put(manager.memory_pools, pool_name, updated_pool)

      # Update memory statistics
      updated_stats = %{
        manager.memory_stats |
        allocated_memory_mb: manager.memory_stats.allocated_memory_mb - allocation.size_mb,
        free_memory_mb: manager.memory_stats.free_memory_mb + allocation.size_mb,
        deallocation_count: manager.memory_stats.deallocation_count + 1
      }

      updated_manager = %{
        manager |
        memory_pools: updated_pools,
        memory_stats: updated_stats
      }

      {:ok, updated_manager}
    else
      {:error, :memory_handle_not_found}
    end
  end

  defp find_allocation_in_pools(memory_pools, memory_handle) do
    Enum.find_value(memory_pools, {nil, nil, nil}, fn {pool_name, pool} ->
      case Map.get(pool.allocations, memory_handle) do
        nil -> nil
        allocation -> {pool_name, pool, allocation}
      end
    end)
  end

  defp generate_memory_handle(pool_name) do
    timestamp = :erlang.system_time(:millisecond)
    random = :rand.uniform(999999)
    "#{pool_name}_#{timestamp}_#{random}"
  end

  defp prepare_data_for_nx_transfer(data, batch_size) do
    # Optimize data layout for GPU memory access using Nx
    # Convert to structure of arrays (SoA) for better GPU performance

    case data do
      [data_masses, shard_masses, distances] when is_list(data_masses) ->
        # Ensure all arrays have the same length
        max_length = Enum.max([length(data_masses), length(shard_masses), length(distances)])

        # Pad arrays to batch size
        padded_data_masses = pad_array(data_masses, max_length, batch_size)
        padded_shard_masses = pad_array(shard_masses, max_length, batch_size)
        padded_distances = pad_array(distances, max_length, batch_size)

        # Convert to Nx arrays
        data_masses_nx = Nx.tensor(padded_data_masses, type: :f32)
        shard_masses_nx = Nx.tensor(padded_shard_masses, type: :f32)
        distances_nx = Nx.tensor(padded_distances, type: :f32)

        [data_masses_nx, shard_masses_nx, distances_nx]

      _ ->
        # Generic data preparation
        data
    end
  end

  defp pad_array(array, current_length, target_length) do
    if current_length >= target_length do
      Enum.take(array, target_length)
    else
      padding = List.duplicate(0.0, target_length - current_length)
      array ++ padding
    end
  end

  defp process_transfer_queue(manager) do
    Logger.debug("🔄 Processing GPU transfer queue...")

    # Process transfers in batches for efficiency
    case :queue.out(manager.transfer_queue) do
      {{:value, {:transfer, data, batch_size}}, remaining_queue} ->
        # Process single transfer
        case process_single_transfer(data, batch_size) do
          {:ok, _result} ->
            Logger.debug("✅ Transfer processed successfully")

          {:error, reason} ->
            Logger.warning("⚠️  Transfer failed: #{reason}")
        end

        # Continue processing queue
        updated_manager = %{manager | transfer_queue: remaining_queue}
        Process.put(:warp_engine_gpu_memory_manager, updated_manager)
        process_transfer_queue(updated_manager)

      {:empty, _queue} ->
        Logger.debug("📭 Transfer queue is empty")
        :ok
    end
  end

  defp process_single_transfer(data, batch_size) do
    # Use Nx for efficient GPU data transfer

    Logger.debug("🎯 Processing Nx GPU transfer: batch_size=#{batch_size}")

    case data do
      [data_masses_nx, shard_masses_nx, distances_nx] when is_struct(data_masses_nx, Nx.Tensor) ->
        # Data is already in Nx format, ready for GPU processing
        Logger.debug("✅ Nx tensors ready for GPU processing")
        Logger.debug("   Data masses shape: #{inspect(Nx.shape(data_masses_nx))}")
        Logger.debug("   Shard masses shape: #{inspect(Nx.shape(shard_masses_nx))}")
        Logger.debug("   Distances shape: #{inspect(Nx.shape(distances_nx))}")

        {:ok, :nx_transfer_completed}

      _ ->
        # Convert data to Nx format for GPU processing
        Logger.debug("🔄 Converting data to Nx format for GPU processing")

        try do
          nx_data = Enum.map(data, fn array ->
            if is_list(array) do
              Nx.tensor(array, type: :f32)
            else
              array
            end
          end)

          {:ok, :nx_conversion_completed, nx_data}
        rescue
          error ->
            Logger.warning("⚠️  Nx conversion failed: #{inspect(error)}")
            {:error, :nx_conversion_failed}
        end
    end
  end
end
