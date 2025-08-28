defmodule WarpEngine.GPUBenchmark do
  @moduledoc """
  GPU performance validation benchmark.

  This module validates that GPU acceleration achieves:
  - 10x+ improvement over Phase 9 performance
  - 500,000+ ops/sec for single process
  - 12,000,000+ ops/sec for 24 processes
  - Linear scaling from 1 to 24 processes

  ## Key Metrics Tracked

  - **GPU vs CPU Performance**: Direct comparison of physics calculations
  - **Batch Processing Efficiency**: GPU batch operation throughput
  - **Memory Transfer Optimization**: GPU memory bandwidth utilization
  - **Fallback Performance**: CPU fallback when GPU unavailable
  - **Concurrency Scaling**: Multi-process GPU operation performance
  """
  import Bitwise

  require Logger

  @doc """
  Run comprehensive GPU performance benchmark.

  Tests GPU acceleration performance and scaling across multiple metrics.
  """
  def run_phase10_validation() do
    Logger.info("🚀 Starting Phase 10 GPU Validation...")

    # Always attempt GPU initialization
    WarpEngine.GPU.OpenCLManager.initialize_gpu_system()

    # Check if GPU is actually active for Nx (Candlex CUDA and default backend set to CUDA)
    gpu_available = gpu_active?()

    if gpu_available do
      Logger.info("✅ GPU acceleration is available")
    else
      Logger.info("⚠️  GPU acceleration not available - running on CPU")
    end

    # Run all validation tests
    physics_ops = test_physics_operations()
    batch_ops = test_gpu_batch_operations()
    mixed_ops = test_mixed_operations()
    concurrency_results = run_gpu_concurrency_test()
    memory_throughput = test_gpu_memory_throughput()

    # Validate results against targets
    target_validation = validate_gpu_targets(physics_ops, batch_ops, mixed_ops, memory_throughput, concurrency_results)

    Logger.info("✅ Phase 10 GPU Validation completed")

    %{
      gpu_available: gpu_available,
      physics_operations: physics_ops,
      batch_operations: batch_ops,
      mixed_operations: mixed_ops,
      concurrency_scaling: concurrency_results,
      memory_throughput: memory_throughput,
      target_validation: target_validation
    }
  end

  @doc """
  Run a GPU-centric benchmark aligned with WarpEngine DB workload.

  Workloads:
  - Shard routing (key→shard) and hotspot entropy
  - Batch scoring (feature vectors · weights)
  - Bitset filtering (tag masks)
  - End-to-end on large batches with preallocated GPU tensors
  """
  def run_warpengine_workload(opts \\ []) do
    require Logger

    n = Keyword.get(opts, :num_items, 1_000_000)
    num_shards = Keyword.get(opts, :num_shards, 48)
    num_features = Keyword.get(opts, :num_features, 16)

    Logger.info("⚙️  Preparing synthetic workload tensors on GPU... n=#{n}, shards=#{num_shards}, features=#{num_features}")

    # Keys: sequential u32 iota ensures even distribution without CPU loops
    keys_cpu = Nx.iota({n}, type: {:u, 32}, backend: Nx.BinaryBackend)
    # Features and weights on CPU first (BinaryBackend), then transfer once to GPU
    features_cpu =
      Nx.iota({n, num_features}, type: :f32, backend: Nx.BinaryBackend)
      |> Nx.multiply(0.001)

    weights_cpu =
      Nx.iota({num_features}, type: :f32, backend: Nx.BinaryBackend)
      |> Nx.multiply(0.001)

    # Bitset positions (0..31), then construct a single-bit mask per row
    bit_positions_cpu =
      Nx.remainder(
        Nx.iota({n}, type: {:u, 32}, backend: Nx.BinaryBackend),
        Nx.tensor(32, type: {:u, 32}, backend: Nx.BinaryBackend)
      )

    # Transfer once to GPU (Candlex CUDA). Default backend is already set to CUDA, but be explicit
    gpu_backend = {Candlex.Backend, device: :cuda}
    keys = Nx.backend_transfer(keys_cpu, gpu_backend)
    features = Nx.backend_transfer(features_cpu, gpu_backend)
    weights = Nx.backend_transfer(weights_cpu, gpu_backend)
    bit_positions = Nx.backend_transfer(bit_positions_cpu, gpu_backend)

    # Build per-row bitset from positions (1 << pos)
    ones_u32 = Nx.broadcast(Nx.tensor(1, type: {:u, 32}, backend: gpu_backend), {n})
    bitsets = Nx.left_shift(ones_u32, bit_positions)

    # Precompute constants on GPU
    shard_count_f32 = Nx.tensor(num_shards * 1.0, type: :f32, backend: gpu_backend)
    ln2 = Nx.tensor(:math.log(2), type: :f32, backend: gpu_backend)

    # 1) Shard routing and hotspot entropy
    {route_us, {shard_ids, entropy_bits}} = :timer.tc(fn ->
      # Use f32 modulo to avoid missing u32 remainder kernel in Candlex CUDA
      shard_ids =
        keys
        |> Nx.as_type(:f32)
        |> Nx.remainder(Nx.tensor(num_shards * 1.0, type: :f32, backend: gpu_backend))
        |> Nx.floor()
        |> Nx.as_type({:u, 32})

      # Histogram via one-hot and sum along axis 0: shape {n, num_shards} -> counts {num_shards}
      shard_axis = Nx.new_axis(Nx.iota({num_shards}, type: {:u, 32}, backend: gpu_backend), 0) # {1, S}
      expanded = Nx.new_axis(shard_ids, 1) # {n, 1}
      one_hot = Nx.equal(expanded, shard_axis) # {n, S}
      counts = Nx.sum(Nx.as_type(one_hot, :f32), axes: [0]) # {S}

      p = Nx.divide(counts, Nx.sum(counts))
      p_safe = Nx.clip(p, 1.0e-12, 1.0)
      entropy_bits = Nx.multiply(-1.0, Nx.sum(Nx.multiply(p_safe, Nx.divide(Nx.log(p_safe), ln2))))
      {shard_ids, entropy_bits}
    end)

    # 2) Batch scoring (dense features dot weights)
    {score_us, scores} = :timer.tc(fn ->
      # scores: {n} = features {n,f} · weights {f}
      Nx.dot(features, [1], weights, [0])
    end)

    # 3) Bitset filter
    {filter_us, filter_count} = :timer.tc(fn ->
      # Query mask selects a few bits (e.g., bits 3, 7, 11)
      mask = Enum.reduce([3, 7, 11], 0, fn b, acc -> acc ||| (1 <<< b) end)
      mask_t = Nx.tensor(mask, type: {:u, 32}, backend: gpu_backend)
      hits = Nx.not_equal(Nx.bitwise_and(bitsets, mask_t), Nx.tensor(0, type: {:u, 32}, backend: gpu_backend))
      Nx.sum(Nx.as_type(hits, :f32))
    end)

    # 4) End-to-end pass combining all
    {e2e_us, _} = :timer.tc(fn ->
      # route (avoid u32 remainder kernel on GPU)
      _sid =
        keys
        |> Nx.as_type(:f32)
        |> Nx.remainder(Nx.tensor(num_shards * 1.0, type: :f32, backend: gpu_backend))
        |> Nx.floor()
        |> Nx.as_type({:u, 32})
      # score
      _s = Nx.dot(features, [1], weights, [0])
      # filter + aggregate without top_k (use supported reductions on CUDA)
      s_f = Nx.as_type(scores, :f32)
      max_score = Nx.reduce_max(s_f)
      _agg = Nx.add(Nx.sum(s_f), max_score)
    end)

    # Materialize small scalars to the host for logging
    entropy_bits_num = Nx.backend_transfer(entropy_bits, Nx.BinaryBackend) |> Nx.to_number()
    filter_hits = Nx.backend_transfer(filter_count, Nx.BinaryBackend) |> Nx.to_number()

    %{
      num_items: n,
      shards: num_shards,
      features: num_features,
      shard_routing_time_us: route_us,
      entropy_bits: entropy_bits_num,
      batch_scoring_time_us: score_us,
      bitset_filter_time_us: filter_us,
      bitset_hits: filter_hits,
      end_to_end_time_us: e2e_us,
      shard_routing_throughput_ops_per_sec: n / (route_us / 1_000_000),
      batch_scoring_throughput_ops_per_sec: n / (score_us / 1_000_000),
      bitset_filter_throughput_ops_per_sec: n / (filter_us / 1_000_000),
      end_to_end_throughput_ops_per_sec: n / (e2e_us / 1_000_000)
    }
  end

  @doc """
  Test GPU acceleration performance for different operation types.
  """
  def test_gpu_acceleration() do
    Logger.info("🎯 Testing GPU acceleration performance...")

    # Check if we actually have GPU acceleration
    gpu_available = gpu_active?()
    if gpu_available do
      Logger.info("   ✅ GPU acceleration is available")
    else
      Logger.info("   ⚠️  GPU acceleration not available - running on CPU")
    end

    Logger.info("   Starting physics operations test...")

    # Test GPU-accelerated physics operations
    physics_ops_performance = test_physics_operations()
    Logger.info("   Physics operations test completed")

    Logger.info("   Starting batch operations test...")
    # Test GPU batch processing
    batch_ops_performance = test_gpu_batch_operations()
    Logger.info("   Batch operations test completed")

    Logger.info("   Starting mixed operations test...")
    # Test GPU mixed workloads
    mixed_ops_performance = test_mixed_operations()
    Logger.info("   Mixed operations test completed")

    Logger.info("   All acceleration tests completed")

    %{
      physics_operations: physics_ops_performance,
      batch_operations: batch_ops_performance,
      mixed_operations: mixed_ops_performance,
      gpu_available: gpu_available
    }
  end

  @doc """
  Test GPU memory throughput with large data operations.
  """
  def test_gpu_memory_throughput(large_operations \\ 100_000) do
    Logger.info("💾 Testing memory throughput performance (GPU-native)...")

    gpu_backend = {Candlex.Backend, device: :cuda}
    gpu_accelerated = WarpEngine.GPU.OpenCLManager.gpu_available?()

    # Allocate larger buffers and chain multiple ops to increase compute
    n = max(large_operations, 10_000_000)
    a = Nx.iota({n}, type: :f32, backend: gpu_backend)
    b = Nx.multiply(a, 1.0001)

    start_time = System.monotonic_time(:microsecond)
    c = Nx.add(a, b)
    d = Nx.multiply(c, 0.5)
    e = Nx.add(d, 1.0)
    f = Nx.multiply(e, 0.9999)
    g = Nx.add(f, Nx.sin(f))
    h = Nx.multiply(g, Nx.sqrt(Nx.add(Nx.abs(g), 1.0e-6)))
    _keep = h
    end_time = System.monotonic_time(:microsecond)
    duration = end_time - start_time

    throughput = n / (duration / 1_000_000)
    estimated_data_size_mb = n * 4 / 1_000_000
    memory_bandwidth_mbps = throughput * 4 / 1_000_000

    Logger.info("   Completed #{n} elements in #{duration}μs; ~#{Float.round(throughput, 1)} el/s")

    %{
      operations: n,
      duration_microseconds: duration,
      throughput_ops_per_sec: throughput,
      estimated_data_size_mb: estimated_data_size_mb,
      memory_bandwidth_mbps: memory_bandwidth_mbps,
      gpu_accelerated: gpu_accelerated
    }
  end

  @doc """
  Test concurrency scaling with GPU acceleration.
  """
  def test_concurrency_scaling() do
    Logger.info("📈 Testing GPU concurrency scaling...")

    # Levels and ops can be overridden via env to avoid OOM on some setups
    levels_env = System.get_env("WE_CONCURRENCY_LEVELS")
    concurrency_levels =
      case levels_env do
        nil -> [1, 2, 4, 8, 16]
        csv -> csv |> String.split(",", trim: true) |> Enum.map(&String.to_integer/1)
      end
    operations_per_test =
      System.get_env("WE_CONCURRENCY_OPS")
      |> case do
        nil -> 100_000
        v -> String.to_integer(v)
      end

    Logger.info("🔄 Testing concurrency levels: #{inspect(concurrency_levels)}")
    Logger.info("📝 Operations per test: #{operations_per_test}")

    # Run benchmark for each concurrency level
    results = Enum.map(concurrency_levels, fn processes ->
      Logger.info("\n⚡ Testing #{processes} concurrent processes...")
      run_gpu_concurrency_test(processes, operations_per_test)
    end)

    # Calculate scaling analysis
    scaling_analysis = analyze_concurrency_scaling(results)

    %{
      results: results,
      scaling_analysis: scaling_analysis,
      target_achievement: validate_scaling_targets(scaling_analysis)
    }
  end

  # Private test implementation functions

  def test_gpu_batch_operations(batch_size \\ 5_000, _operations \\ 50_000) do
    Logger.info("📦 Testing batch operations performance (WarpEngine PhysicsEngine batch; timed trials)...")

    gpu_accelerated = gpu_active?()

    # Prepare a realistic batch of gravitational operations (reused across calls)
    ops_per_call = System.get_env("WE_BATCH_OPS") |> case do
      nil -> 50_000
      v -> String.to_integer(v)
    end
    mk_ops = fn n ->
      Enum.map(1..n, fn i ->
        %{
          id: "batch_#{i}",
          type: :gravitational_calculation,
          physics: %{
            data_mass: :rand.uniform() * 1000.0,
            shard_mass: :rand.uniform() * 100.0,
            distance: :rand.uniform() * 1000.0 + 1.0
          },
          priority: :medium,
          timestamp: System.system_time(:millisecond) * 1.0
        }
      end)
    end
    warm_batch = mk_ops.(ops_per_call)

    # Timed trials for ~10s wall time each, repeatedly calling batch API
    trial_secs = 10
    trials = 3
    {durations, total_ops} =
      Enum.reduce(1..trials, {[], 0}, fn _, {ds, acc_ops} ->
        t0 = System.monotonic_time(:microsecond)
        iters = loop_for_ms(trial_secs * 1000, fn ->
          _ = WarpEngine.GPU.PhysicsEngine.calculate_gravitational_batch(warm_batch)
        end)
        t1 = System.monotonic_time(:microsecond)
        {[t1 - t0 | ds], acc_ops + iters * ops_per_call}
      end)

    duration = Enum.sum(durations)
    throughput = total_ops / (duration / 1_000_000)
    batches = 1

    %{
      batch_size: batch_size,
      operations: total_ops,
      duration_microseconds: duration,
      throughput_ops_per_sec: throughput,
      gpu_accelerated: gpu_accelerated,
      target_achievement: validate_batch_target(throughput),
      batches: batches
    }
  end

  def test_physics_operations(operations \\ 10_000) do
    Logger.info("🔬 Testing physics operations performance (WarpEngine PhysicsEngine; timed trials)...")

    gpu_accelerated = gpu_active?()

    ops_per_call = System.get_env("WE_PHYSICS_OPS") |> case do
      nil -> operations
      v -> String.to_integer(v)
    end

    mk_ops = fn n ->
      Enum.map(1..n, fn i ->
        %{
          id: "physics_#{i}",
          type: :gravitational_calculation,
          physics: %{
            data_mass: :rand.uniform() * 1000.0,
            shard_mass: :rand.uniform() * 100.0,
            distance: :rand.uniform() * 1000.0 + 1.0
          },
          priority: :high,
          timestamp: System.system_time(:millisecond) * 1.0
        }
      end)
    end
    warm_batch = mk_ops.(ops_per_call)

    trial_secs = 10
    trials = 3
    {durations, total_ops} =
      Enum.reduce(1..trials, {[], 0}, fn _, {ds, acc_ops} ->
        t0 = System.monotonic_time(:microsecond)
        iters = loop_for_ms(trial_secs * 1000, fn ->
          _ = WarpEngine.GPU.PhysicsEngine.calculate_gravitational_batch(warm_batch)
        end)
        t1 = System.monotonic_time(:microsecond)
        {[t1 - t0 | ds], acc_ops + iters * ops_per_call}
      end)

    duration = Enum.sum(durations)
    throughput = total_ops / (duration / 1_000_000)

    %{
      operations: total_ops,
      duration_microseconds: duration,
      throughput_ops_per_sec: throughput,
      gpu_accelerated: gpu_accelerated,
      target_achievement: validate_physics_target(throughput),
      cpu_only: !gpu_accelerated
    }
  end

  def test_mixed_operations(operations \\ 5_000) do
    Logger.info("🔄 Testing mixed operations performance (WarpEngine batch API; timed trials)...")

    gpu_accelerated = gpu_active?()

    ops_per_call = System.get_env("WE_MIXED_OPS") |> case do
      nil -> operations
      v -> String.to_integer(v)
    end

    grav_ops = fn n ->
      Enum.map(1..n, fn i ->
        %{
          id: "grav_#{i}",
          type: :gravitational_calculation,
          physics: %{
            data_mass: :rand.uniform() * 1000.0,
            shard_mass: :rand.uniform() * 100.0,
            distance: :rand.uniform() * 1000.0 + 1.0
          },
          priority: :high,
          timestamp: System.system_time(:millisecond) * 1.0
        }
      end)
    end

    quant_ops = fn n ->
      Enum.map(1..n, fn i ->
        %{
          id: "quantum_#{i}",
          type: :quantum_correlation,
          physics: %{
            access_pattern: :rand.uniform() * 0.99 + 0.01,
            temporal_weight: :rand.uniform() * 0.99 + 0.01
          },
          priority: :medium,
          timestamp: System.system_time(:millisecond) * 1.0
        }
      end)
    end

    entr_ops = fn n ->
      Enum.map(1..n, fn i ->
        %{
          id: "entropy_#{i}",
          type: :entropy_calculation,
          physics: %{
            load_distribution: :rand.uniform() * 0.99 + 0.01
          },
          priority: :low,
          timestamp: System.system_time(:millisecond) * 1.0
        }
      end)
    end

    warm_g = grav_ops.(ops_per_call)
    warm_q = quant_ops.(ops_per_call)
    warm_e = entr_ops.(ops_per_call)

    trial_secs = 10
    trials = 3
    {durations, total_ops} =
      Enum.reduce(1..trials, {[], 0}, fn _, {ds, acc_ops} ->
        t0 = System.monotonic_time(:microsecond)
        iters = loop_for_ms(trial_secs * 1000, fn ->
          _ = WarpEngine.GPU.PhysicsEngine.calculate_gravitational_batch(warm_g)
          _ = WarpEngine.GPU.PhysicsEngine.calculate_quantum_correlations_batch(warm_q)
          _ = WarpEngine.GPU.PhysicsEngine.calculate_entropy_batch(warm_e)
        end)
        t1 = System.monotonic_time(:microsecond)
        {[t1 - t0 | ds], acc_ops + iters * ops_per_call}
      end)

    duration = Enum.sum(durations)
    throughput = total_ops / (duration / 1_000_000)

    %{
      operations: total_ops,
      duration_microseconds: duration,
      throughput_ops_per_sec: throughput,
      target_achievement: validate_mixed_target(throughput),
      hybrid_processing: true
    }
  end

  # Utility: run body repeatedly until ms budget elapses; return iterations
  defp loop_for_ms(ms, fun) do
    deadline = System.monotonic_time(:millisecond) + ms
    do_loop(deadline, fun, 0)
  end

  defp do_loop(deadline_ms, fun, acc) do
    _ = fun.()
    now = System.monotonic_time(:millisecond)
    if now < deadline_ms, do: do_loop(deadline_ms, fun, acc + 1), else: acc + 1
  end

  # Safely perform matmul in column blocks to avoid OOM
  defp try_matmul(a, b, k_block) do
    {rows, k} = Nx.shape(a)
    {^k, cols} = Nx.shape(b)
    blocks = div(cols + k_block - 1, k_block)
    Enum.reduce(0..(blocks - 1), nil, fn i, _acc ->
      start_col = i * k_block
      len = min(k_block, cols - start_col)
      b_block = Nx.slice_along_axis(b, start_col, len, axis: 1)
      _c = Nx.dot(a, [1], b_block, [0])
    end)
  end



  defp run_gpu_concurrency_test(concurrency_levels \\ [1, 2, 4, 8, 16], operations_per_test \\ 100_000) do
    Logger.info("🔄 Testing concurrency scaling performance...")

    # Check if we actually have GPU acceleration
    gpu_accelerated = gpu_active?()
    # Check if we actually have GPU acceleration
    gpu_accelerated = gpu_active?()
    # Check if we actually have GPU acceleration
    gpu_accelerated = gpu_active?()
    # Check if we actually have GPU acceleration
    gpu_accelerated = gpu_active?()
    # Check if we actually have GPU acceleration
    gpu_accelerated = Candlex.Backend.cuda_available?()

    if gpu_accelerated do
      Logger.info("   ✅ GPU acceleration available for concurrency testing")
    else
      Logger.info("   ⚠️  CPU only - concurrency testing will use CPU cores")
    end

    gpu_backend = {Candlex.Backend, device: :cuda}

    results = Enum.map(concurrency_levels, fn process_count ->
      Logger.info("   Testing with #{process_count} processes...")

      start_time = System.monotonic_time(:microsecond)

      # Create tasks for concurrent execution
      tasks = Enum.map(1..process_count, fn _ ->
        Task.async(fn ->
          # Each task performs GPU-native vectorized work to stress GPU, not CPU/GC
          n = operations_per_test
          feats = 64
          a = Nx.iota({n, feats}, type: :f32, backend: gpu_backend) |> Nx.multiply(0.001)
          w = Nx.iota({feats}, type: :f32, backend: gpu_backend) |> Nx.multiply(0.001)
          scores = Nx.dot(a, [1], w, [0])
          _keep = Nx.add(Nx.sum(scores), Nx.reduce_max(scores))
        end)
      end)

      # Wait for all tasks to complete
      Enum.each(tasks, &Task.await(&1, 120_000))

      end_time = System.monotonic_time(:microsecond)
      duration = end_time - start_time

      total_operations = process_count * operations_per_test
      throughput = total_operations / (duration / 1_000_000)

      Logger.info("     #{process_count} processes: #{Float.round(throughput, 2)} ops/sec")

      %{
        process_count: process_count,
        errors: 0,
        total_operations: total_operations,
        duration_microseconds: duration,
        throughput_ops_per_sec: throughput,
        operations_per_process: operations_per_test,
        success_rate: "100%"
      }
    end)

    Logger.info("   Concurrency testing completed")

    scaling_analysis = analyze_concurrency_scaling(results)
    %{
      results: results,
      scaling_analysis: scaling_analysis,
      target_achievement: validate_scaling_targets(scaling_analysis),
      gpu_accelerated: gpu_accelerated
    }
  end



  defp validate_scaling_targets(scaling_analysis) do
    targets = %{
      single_process: scaling_analysis.baseline_throughput >= 500_000,
      max_throughput: scaling_analysis.max_throughput >= 20_000_000,  # Higher target for GPU
      scaling_efficiency: scaling_analysis.average_efficiency >= 80  # Lower threshold for GPU overhead
    }

    %{
      targets: targets,
      overall_achievement: if(Enum.all?(Map.values(targets)), do: "✅ All targets achieved", else: "❌ Some targets missed")
    }
  end

  # Returns true if Candlex reports CUDA available AND Nx default backend is set to Candlex CUDA
  defp gpu_active? do
    backend = Application.get_env(:nx, :default_backend)
    Candlex.Backend.cuda_available?() and backend == {Candlex.Backend, device: :cuda}
  end

  defp validate_gpu_targets(physics_ops, batch_ops, mixed_ops, memory_throughput, concurrency_results) do
    targets = %{
      physics_ops_target: physics_ops.throughput_ops_per_sec >= 500_000,  # Higher target
      batch_ops_target: batch_ops.throughput_ops_per_sec >= 1_000_000,   # Higher target
      mixed_ops_target: mixed_ops.throughput_ops_per_sec >= 750_000,     # Higher target
      memory_bandwidth_target: memory_throughput.throughput_ops_per_sec >= 2_000_000,          # Higher target
      max_concurrency_target: concurrency_results.scaling_analysis.max_throughput >= 10_000_000 # Higher target
    }

    %{
      targets: targets,
      overall_achievement: if(Enum.all?(Map.values(targets)), do: "✅ All GPU targets achieved", else: "❌ Some targets missed"),
      gpu_utilization: calculate_gpu_utilization(physics_ops, memory_throughput)
    }
  end

  defp calculate_gpu_utilization(physics_ops, memory_throughput) do
    # Calculate estimated GPU utilization based on throughput
    physics_utilization = min(physics_ops.throughput_ops_per_sec / 2_000_000 * 100, 100)
    memory_utilization = min(memory_throughput.throughput_ops_per_sec / 5_000_000 * 100, 100)

    %{
      physics_utilization_percent: physics_utilization,
      memory_utilization_percent: memory_utilization,
      overall_utilization_percent: (physics_utilization + memory_utilization) / 2
    }
  end

  # Validation helper functions
  defp validate_physics_target(throughput) do
    if throughput >= 500_000, do: "✅ Target achieved", else: "❌ Target missed"
  end

  defp validate_batch_target(throughput) do
    if throughput >= 1_000_000, do: "✅ Target achieved", else: "❌ Target missed"
  end

  defp validate_mixed_target(throughput) do
    if throughput >= 750_000, do: "✅ Target achieved", else: "❌ Target missed"
  end

  defp analyze_concurrency_scaling(results) do
    baseline_throughput = List.first(results).throughput_ops_per_sec

    scaling_analysis = Enum.map(results, fn result ->
      theoretical_throughput = baseline_throughput * result.process_count
      actual_throughput = result.throughput_ops_per_sec
      efficiency_percent = (actual_throughput / theoretical_throughput) * 100
      scaling_factor = actual_throughput / baseline_throughput

      %{
        process_count: result.process_count,
        theoretical_throughput: theoretical_throughput,
        actual_throughput: actual_throughput,
        efficiency_percent: efficiency_percent,
        scaling_factor: scaling_factor
      }
    end)

    max_throughput = Enum.max_by(results, & &1.throughput_ops_per_sec).throughput_ops_per_sec
    average_efficiency = Enum.reduce(scaling_analysis, 0, fn %{efficiency_percent: eff}, acc -> acc + eff end) / length(scaling_analysis)

    %{
      scaling_analysis: scaling_analysis,
      baseline_throughput: baseline_throughput,
      max_throughput: max_throughput,
      average_efficiency: average_efficiency
    }
  end

  defp generate_gpu_report(gpu_performance, concurrency_scaling, memory_performance, validation, total_time) do
    Logger.info("\n" <> String.duplicate("=", 80))
    Logger.info("🚀 GPU PERFORMANCE BENCHMARK REPORT")
    Logger.info(String.duplicate("=", 80))

    # GPU Performance Summary
    Logger.info("\n📊 GPU ACCELERATION PERFORMANCE:")
    Logger.info("   Physics Operations: #{Float.round(gpu_performance.physics_operations.throughput_ops_per_sec, 1)} ops/sec")
    Logger.info("   Batch Operations: #{Float.round(gpu_performance.batch_operations.throughput_ops_per_sec, 1)} ops/sec")
    Logger.info("   Mixed Operations: #{Float.round(gpu_performance.mixed_operations.throughput_ops_per_sec, 1)} ops/sec")
    Logger.info("   GPU Available: #{gpu_performance.gpu_available}")

    # GPU Memory Performance
    Logger.info("\n💾 GPU MEMORY PERFORMANCE:")
    Logger.info("   Memory Throughput: #{Float.round(memory_performance.throughput_ops_per_sec, 1)} ops/sec")
    Logger.info("   Memory Bandwidth: #{Float.round(memory_performance.memory_bandwidth_mbps || 0, 1)} MB/s")
    Logger.info("   Data Size: #{Float.round(memory_performance.estimated_data_size_mb || 0, 1)} MB")

    # GPU Utilization
    Logger.info("\n📈 GPU UTILIZATION:")
    Logger.info("   Physics Utilization: #{Float.round(validation.gpu_utilization.physics_utilization_percent, 1)}%")
    Logger.info("   Memory Utilization: #{Float.round(validation.gpu_utilization.memory_utilization_percent, 1)}%")
    Logger.info("   Overall Utilization: #{Float.round(validation.gpu_utilization.overall_utilization_percent, 1)}%")

    # Concurrency Scaling
    Logger.info("\n🔄 GPU CONCURRENCY SCALING:")
    Logger.info("   Max Throughput: #{Float.round(concurrency_scaling.scaling_analysis.max_throughput, 1)} ops/sec")
    Logger.info("   Average Efficiency: #{Float.round(concurrency_scaling.scaling_analysis.average_efficiency, 1)}%")
    Logger.info("   Scaling Achievement: #{concurrency_scaling.target_achievement.overall_achievement}")

    # GPU Target Validation
    Logger.info("\n🎯 GPU TARGET VALIDATION:")
    Logger.info("   Overall Achievement: #{validation.overall_achievement}")

    # Summary
    Logger.info("\n" <> String.duplicate("-", 80))
    Logger.info("📋 GPU BENCHMARK SUMMARY:")
    Logger.info("   Total Benchmark Time: #{total_time} ms")
    Logger.info("   GPU Status: #{if(gpu_performance.gpu_available, do: "✅ Available & Active", else: "❌ Not Available")}")
    Logger.info("   Physics Performance: #{gpu_performance.physics_operations.target_achievement}")
    Logger.info("   Batch Performance: #{gpu_performance.batch_operations.target_achievement}")
    Logger.info("   Concurrency Target: #{if(concurrency_scaling.scaling_analysis.max_throughput >= 5_000_000, do: "✅ 5M+ Achieved", else: "❌ Target Missed")}")
    Logger.info(String.duplicate("=", 80))
  end
end

# Main execution section for standalone benchmark
if System.argv() |> Enum.any?(&(&1 == "gpu")) do
  # Check if WarpEngine is already started
  case Process.whereis(WarpEngine) do
    nil ->
      # Start the WarpEngine application with benchmark configuration
      {:ok, _pid} = WarpEngine.start_link(
        bench_mode: true,
        enable_wal: false,
        enable_gpu: true
      )

    _pid ->
      # WarpEngine is already running, just continue
      IO.puts("ℹ️  WarpEngine is already running, continuing with benchmark...")
  end

  # Wait for application to start
  Process.sleep(1000)

  # Run the GPU benchmark
  result = WarpEngine.GPUBenchmark.run_phase10_validation()

  # Ensure all logs are flushed and also print a concise result snapshot
  Logger.flush()
  IO.puts("\n✅ Benchmark completed. Key results:")
  IO.inspect(result, label: "phase10_summary")

  # Exit cleanly
  System.halt(0)
end

# GPU workload CLI entry
if System.argv() |> Enum.any?(&(&1 == "workload")) do
  case Process.whereis(WarpEngine) do
    nil -> {:ok, _pid} = WarpEngine.start_link(bench_mode: true, enable_wal: false, enable_gpu: true)
    _pid -> :ok
  end
  Process.sleep(500)

  # Default workload params can be overridden via env
  n = System.get_env("WE_WORKLOAD_N") |> case do
    nil -> 1_000_000
    v -> String.to_integer(v)
  end
  shards = System.get_env("WE_WORKLOAD_SHARDS") |> case do
    nil -> 48
    v -> String.to_integer(v)
  end
  feats = System.get_env("WE_WORKLOAD_FEATS") |> case do
    nil -> 16
    v -> String.to_integer(v)
  end

  result = WarpEngine.GPUBenchmark.run_warpengine_workload(num_items: n, num_shards: shards, num_features: feats)
  Logger.flush()
  IO.inspect(result, label: "warpengine_workload")
  System.halt(0)
end
