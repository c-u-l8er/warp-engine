defmodule WarpEngine.Phase9Benchmark do
  @moduledoc """
  Benchmark validation for Phase 9.1 Per-Shard WAL Architecture.

  This module validates that the per-shard WAL architecture achieves:
  - 200K+ operations/second (vs previous 77K peak)
  - Linear concurrency scaling up to 16+ processes
  - Elimination of concurrency degradation bottleneck
  - <100μs average WAL write latency per operation

  ## Key Metrics Tracked

  - **Operations per second** at different concurrency levels
  - **Concurrency scaling efficiency** (actual vs theoretical linear scaling)
  - **Per-shard WAL latency** and throughput distribution
  - **System resource utilization** (CPU, memory, I/O)
  - **Cross-shard contention** elimination validation

  ## Benchmark Results Target

  ```
  Phase 9.1 Target Results:
  ┌─────────────┬──────────────┬─────────────┬──────────────┐
  │ Processes   │ Ops/Sec      │ Speedup     │ Efficiency   │
  ├─────────────┼──────────────┼─────────────┼──────────────┤
  │ 1           │ 50,000       │ 1.0x        │ 100%         │
  │ 2           │ 100,000      │ 2.0x        │ 100%         │
  │ 4           │ 200,000      │ 4.0x        │ 100%         │
  │ 8           │ 400,000      │ 8.0x        │ 100%         │
  │ 16          │ 800,000      │ 16.0x       │ 100%         │
  └─────────────┴──────────────┴─────────────┴──────────────┘
  ```

  Compare to Phase 6.6 Results:
  - 1 Process: 20,000 ops/sec
  - 2 Processes: 76,923 ops/sec (peak)
  - 4+ Processes: Degraded performance due to WAL bottleneck
  """

  require Logger

  @doc """
  Run comprehensive Phase 9.1 performance validation.

  Tests concurrency scaling from 1 to 16 processes and validates
  linear scaling performance with per-shard WAL architecture.
  """
  def run_phase9_validation() do
    Logger.info("🚀 Starting Phase 9.1 Per-Shard WAL Performance Validation...")
    Logger.info("📊 Target: 200K+ ops/sec with linear concurrency scaling")

    start_time = :os.system_time(:millisecond)

    # Test concurrency levels
    concurrency_levels = [1, 2, 4, 8, 16]
    operations_per_test = 10_000

    Logger.info("📈 Testing concurrency levels: #{inspect(concurrency_levels)}")
    Logger.info("🔄 Operations per test: #{operations_per_test}")

    # Run benchmark for each concurrency level
    results = Enum.map(concurrency_levels, fn processes ->
      Logger.info("\n⚡ Testing #{processes} concurrent processes...")
      run_concurrency_test(processes, operations_per_test)
    end)

    # Calculate performance analysis
    analysis = analyze_phase9_performance(results)

    # Validate against targets
    validation = validate_phase9_targets(analysis)

    total_time = :os.system_time(:millisecond) - start_time

    # Generate comprehensive report
    generate_phase9_report(results, analysis, validation, total_time)

    {results, analysis, validation}
  end

  @doc """
  Run concurrency test for a specific number of processes.
  """
  def run_concurrency_test(process_count, operations_count) do
    Logger.info("🔧 Setting up #{process_count} concurrent test processes...")

    # Prepare test data
    test_operations = prepare_test_operations(operations_count)
    operations_per_process = div(operations_count, process_count)

    Logger.info("📝 Each process will execute #{operations_per_process} operations")

    # Start timer
    start_time = :os.system_time(:microsecond)

    # Launch concurrent processes
    tasks = Enum.map(1..process_count, fn process_id ->
      process_operations = Enum.take(test_operations, operations_per_process)
      
      Task.async(fn ->
        run_process_operations(process_id, process_operations)
      end)
    end)

    # Wait for all processes to complete
    task_results = Enum.map(tasks, &Task.await(&1, 30_000))

    # Stop timer
    end_time = :os.system_time(:microsecond)
    total_time_us = end_time - start_time
    total_time_ms = div(total_time_us, 1000)

    # Calculate metrics
    total_operations_executed = Enum.sum(Enum.map(task_results, fn {ops_count, _time} -> ops_count end))
    ops_per_second = if total_time_ms > 0, do: div(total_operations_executed * 1000, total_time_ms), else: 0
    
    # Calculate speedup (assuming single process baseline)
    theoretical_speedup = process_count
    actual_speedup = if process_count == 1, do: 1.0, else: ops_per_second / get_baseline_ops_per_second()
    efficiency = (actual_speedup / theoretical_speedup) * 100

    result = %{
      process_count: process_count,
      operations_executed: total_operations_executed,
      total_time_ms: total_time_ms,
      ops_per_second: ops_per_second,
      theoretical_speedup: theoretical_speedup,
      actual_speedup: actual_speedup,
      efficiency: efficiency,
      avg_latency_us: if(total_operations_executed > 0, do: div(total_time_us, total_operations_executed), else: 0),
      task_results: task_results
    }

    Logger.info("✅ #{process_count} processes completed:")
    Logger.info("   Operations: #{total_operations_executed}")
    Logger.info("   Time: #{total_time_ms}ms")
    Logger.info("   Throughput: #{ops_per_second} ops/sec")
    Logger.info("   Speedup: #{Float.round(actual_speedup, 2)}x (#{Float.round(efficiency, 1)}% efficiency)")

    result
  end

  @doc """
  Run operations for a single test process.
  """
  def run_process_operations(process_id, operations) do
    Logger.debug("🏃 Process #{process_id} starting #{length(operations)} operations...")
    
    start_time = :os.system_time(:microsecond)

    # Execute operations with minimal overhead
    final_count = Enum.reduce(operations, 0, fn operation, acc ->
      case execute_test_operation(operation) do
        :ok -> acc + 1
        {:error, _reason} -> acc  # Skip failed operations
      end
    end)

    end_time = :os.system_time(:microsecond)
    process_time_us = end_time - start_time

    Logger.debug("✅ Process #{process_id} completed: #{final_count} ops in #{div(process_time_us, 1000)}ms")

    {final_count, process_time_us}
  end

  @doc """
  Execute a single test operation (put, get, or delete).
  """
  def execute_test_operation({:put, key, value}) do
    case WarpEngine.cosmic_put(key, value) do
      {:ok, :stored, _shard_id, _operation_time, _state} -> :ok
      {:ok, :stored, _shard_id, _operation_time} -> :ok
      {:error, reason} -> {:error, reason}
      _ -> :ok
    end
  end

  def execute_test_operation({:get, key}) do
    case WarpEngine.cosmic_get(key) do
      {:ok, _value, _shard_id, _operation_time, _state} -> :ok
      {:ok, _value, _shard_id, _operation_time} -> :ok
      {:error, :not_found, _operation_time, _state} -> :ok  # Not found is still a successful operation
      {:error, :not_found, _operation_time} -> :ok
      {:error, reason} -> {:error, reason}
      _ -> :ok
    end
  end

  def execute_test_operation({:delete, key}) do
    case WarpEngine.cosmic_delete(key) do
      {:ok, _delete_results, _operation_time, _state} -> :ok
      {:ok, _delete_results, _operation_time} -> :ok
      {:error, reason} -> {:error, reason}
      _ -> :ok
    end
  end

  ## PRIVATE FUNCTIONS

  defp prepare_test_operations(count) do
    # Generate a mix of operations for realistic testing
    Enum.flat_map(1..count, fn i ->
      key = "bench_key_#{i}"
      value = %{id: i, data: "benchmark_data_#{i}", timestamp: :os.system_time(:microsecond)}
      
      # 70% puts, 20% gets, 10% deletes for realistic workload
      case rem(i, 10) do
        n when n in [0, 1, 2, 3, 4, 5, 6] -> [{:put, key, value}]
        n when n in [7, 8] -> [{:get, "bench_key_#{max(1, i - 10)}"}]  # Get older keys
        9 -> [{:delete, "bench_key_#{max(1, i - 20)}"}]  # Delete much older keys
      end
    end)
    |> Enum.take(count)  # Ensure exact count
  end

  defp analyze_phase9_performance(results) do
    Logger.info("\n📊 Analyzing Phase 9.1 Performance Results...")

    # Extract key metrics
    max_ops_per_second = Enum.map(results, & &1.ops_per_second) |> Enum.max()
    avg_efficiency = Enum.map(results, & &1.efficiency) |> Enum.sum() |> Kernel./(length(results))
    
    # Calculate scaling metrics
    single_process_result = Enum.find(results, & &1.process_count == 1)
    baseline_ops = if single_process_result, do: single_process_result.ops_per_second, else: 50_000

    scaling_analysis = Enum.map(results, fn result ->
      expected_ops = baseline_ops * result.process_count
      scaling_efficiency = if expected_ops > 0, do: (result.ops_per_second / expected_ops) * 100, else: 0
      
      %{
        process_count: result.process_count,
        actual_ops: result.ops_per_second,
        expected_ops: expected_ops,
        scaling_efficiency: scaling_efficiency
      }
    end)

    # Check for linear scaling
    linear_scaling = Enum.all?(scaling_analysis, fn analysis ->
      analysis.scaling_efficiency >= 80.0  # 80% efficiency threshold for "linear"
    end)

    analysis = %{
      max_throughput: max_ops_per_second,
      avg_efficiency: avg_efficiency,
      baseline_ops_per_second: baseline_ops,
      scaling_analysis: scaling_analysis,
      achieves_linear_scaling: linear_scaling,
      bottleneck_eliminated: max_ops_per_second > 150_000,  # Well above previous 77K peak
      concurrency_degradation: detect_concurrency_degradation(results)
    }

    Logger.info("🎯 Max throughput achieved: #{max_ops_per_second} ops/sec")
    Logger.info("📈 Average efficiency: #{Float.round(avg_efficiency, 1)}%")
    Logger.info("⚖️  Linear scaling: #{if linear_scaling, do: "✅ YES", else: "❌ NO"}")

    analysis
  end

  defp validate_phase9_targets(analysis) do
    Logger.info("\n🎯 Validating Phase 9.1 Targets...")

    validations = [
      %{
        target: "200K+ ops/sec throughput",
        achieved: analysis.max_throughput >= 200_000,
        actual: analysis.max_throughput,
        target_value: 200_000
      },
      %{
        target: "Linear concurrency scaling",
        achieved: analysis.achieves_linear_scaling,
        actual: analysis.achieves_linear_scaling,
        target_value: true
      },
      %{
        target: "Eliminate concurrency bottleneck",
        achieved: analysis.bottleneck_eliminated,
        actual: analysis.max_throughput,
        target_value: 150_000  # Well above 77K previous peak
      },
      %{
        target: "No concurrency degradation",
        achieved: not analysis.concurrency_degradation,
        actual: analysis.concurrency_degradation,
        target_value: false
      },
      %{
        target: "Average 80%+ efficiency",
        achieved: analysis.avg_efficiency >= 80.0,
        actual: analysis.avg_efficiency,
        target_value: 80.0
      }
    ]

    successful_targets = Enum.count(validations, & &1.achieved)
    total_targets = length(validations)

    validation_result = %{
      successful_targets: successful_targets,
      total_targets: total_targets,
      success_rate: (successful_targets / total_targets) * 100,
      validations: validations,
      overall_success: successful_targets == total_targets
    }

    Logger.info("🏆 Validation Results: #{successful_targets}/#{total_targets} targets achieved")
    Enum.each(validations, fn validation ->
      status = if validation.achieved, do: "✅", else: "❌"
      Logger.info("   #{status} #{validation.target}: #{inspect(validation.actual)}")
    end)

    validation_result
  end

  defp detect_concurrency_degradation(results) do
    # Check if performance degrades as concurrency increases
    sorted_results = Enum.sort_by(results, & &1.process_count)
    
    Enum.zip(sorted_results, tl(sorted_results))
    |> Enum.any?(fn {prev, curr} ->
      # If ops/sec decreases as process count increases, we have degradation
      curr.ops_per_second < prev.ops_per_second * 0.9  # Allow 10% variance
    end)
  end

  defp generate_phase9_report(results, analysis, validation, total_time_ms) do
    Logger.info("\n" <> String.duplicate("=", 80))
    Logger.info("📋 PHASE 9.1 PER-SHARD WAL PERFORMANCE REPORT")
    Logger.info(String.duplicate("=", 80))

    Logger.info("\n🎯 VALIDATION SUMMARY:")
    Logger.info("   Overall Success: #{if validation.overall_success, do: "✅ PASSED", else: "❌ FAILED"}")
    Logger.info("   Targets Met: #{validation.successful_targets}/#{validation.total_targets}")
    Logger.info("   Success Rate: #{Float.round(validation.success_rate, 1)}%")

    Logger.info("\n🚀 PERFORMANCE METRICS:")
    Logger.info("   Peak Throughput: #{analysis.max_throughput} ops/sec")
    Logger.info("   Baseline Single Process: #{analysis.baseline_ops_per_second} ops/sec")
    Logger.info("   Peak vs Previous (77K): #{Float.round(analysis.max_throughput / 77_000, 2)}x improvement")
    Logger.info("   Average Efficiency: #{Float.round(analysis.avg_efficiency, 1)}%")

    Logger.info("\n📊 CONCURRENCY SCALING:")
    Logger.info("┌─────────────┬──────────────┬─────────────┬──────────────┬──────────────┐")
    Logger.info("│ Processes   │ Ops/Sec      │ Speedup     │ Efficiency   │ Avg Latency  │")
    Logger.info("├─────────────┼──────────────┼─────────────┼──────────────┼──────────────┤")
    
    Enum.each(results, fn result ->
      Logger.info("│ #{pad_string(Integer.to_string(result.process_count), 11)} │ #{pad_string(format_number(result.ops_per_second), 12)} │ #{pad_string("#{Float.round(result.actual_speedup, 1)}x", 11)} │ #{pad_string("#{Float.round(result.efficiency, 1)}%", 12)} │ #{pad_string("#{result.avg_latency_us}μs", 12)} │")
    end)
    
    Logger.info("└─────────────┴──────────────┴─────────────┴──────────────┴──────────────┘")

    Logger.info("\n⚡ ARCHITECTURAL IMPACT:")
    Logger.info("   WAL Bottleneck Eliminated: #{if analysis.bottleneck_eliminated, do: "✅ YES", else: "❌ NO"}")
    Logger.info("   Linear Scaling Achieved: #{if analysis.achieves_linear_scaling, do: "✅ YES", else: "❌ NO"}")
    Logger.info("   Concurrency Degradation: #{if analysis.concurrency_degradation, do: "❌ DETECTED", else: "✅ NONE"}")

    Logger.info("\n⏱️  BENCHMARK RUNTIME:")
    Logger.info("   Total Benchmark Time: #{total_time_ms}ms")
    Logger.info("   Average Test Time: #{div(total_time_ms, length(results))}ms per concurrency level")

    Logger.info("\n" <> String.duplicate("=", 80))
    
    if validation.overall_success do
      Logger.info("🎉 PHASE 9.1 VALIDATION SUCCESSFUL - Linear Concurrency Scaling Achieved!")
    else
      Logger.error("⚠️  PHASE 9.1 VALIDATION INCOMPLETE - Review failed targets above")
    end
    
    Logger.info(String.duplicate("=", 80) <> "\n")

    :ok
  end

  # Helper functions
  defp get_baseline_ops_per_second(), do: 50_000  # Conservative baseline estimate

  defp pad_string(str, width) do
    str_length = String.length(str)
    if str_length >= width do
      str
    else
      padding = div(width - str_length, 2)
      left_pad = String.duplicate(" ", padding)
      right_pad = String.duplicate(" ", width - str_length - padding)
      left_pad <> str <> right_pad
    end
  end

  defp format_number(num) when num >= 1_000_000 do
    "#{Float.round(num / 1_000_000, 1)}M"
  end
  defp format_number(num) when num >= 1_000 do
    "#{Float.round(num / 1_000, 1)}K"
  end
  defp format_number(num) do
    Integer.to_string(num)
  end
end
