#!/usr/bin/env elixir

# Process Coordination Overhead Test - Isolates coordination bottlenecks
# Tests how WALCoordinator and process coordination affects scaling

require Logger
Logger.configure(level: :info)
Logger.configure_backend(:console, level: :info)

# Configuration
Application.put_env(:warp_engine, :bench_mode, false)
Application.put_env(:warp_engine, :use_numbered_shards, true)
Application.put_env(:warp_engine, :num_numbered_shards, 24)

concurrency_levels = [1, 2, 4, 6, 12, 24]
warmup_ms = 2000
measure_ms = 5000
trials = 3
keyset = 10000

IO.puts("🔧 Coordination Overhead Test Configuration:")
IO.puts("   bench_mode: #{Application.get_env(:warp_engine, :bench_mode)}")
IO.puts("   use_numbered_shards: #{Application.get_env(:warp_engine, :use_numbered_shards)}")
IO.puts("   num_numbered_shards: #{Application.get_env(:warp_engine, :num_numbered_shards)}")
IO.puts("   Concurrency levels: #{Enum.join(concurrency_levels, ",")}")

# Start system
{:ok, _} = Application.ensure_all_started(:warp_engine)

# Wait for ETS tables
wait_for_ets_tables = fn shard_count ->
  max_wait = 10000
  start_time = System.monotonic_time(:millisecond)

  recur = fn recur ->
    ready = Enum.all?(0..(shard_count - 1), fn i ->
      :ets.whereis(:"spacetime_shard_#{i}") != :undefined
    end)

    if ready do
      elapsed = System.monotonic_time(:millisecond) - start_time
      IO.puts("✅ All #{shard_count} ETS tables ready in #{elapsed}ms")
      true
    else
      elapsed = System.monotonic_time(:millisecond) - start_time
      if elapsed > max_wait do
        IO.puts("❌ Timeout waiting for ETS tables after #{elapsed}ms")
        false
      else
        Process.sleep(100)
        recur.(recur)
      end
    end
  end

  recur.(recur)
end

IO.puts("⏳ Waiting for ETS tables...")
:ok = (wait_for_ets_tables.(24) && :ok) || :ok

# Prime the system
_ = (try do GenServer.call(WarpEngine, :get_current_state, 5000) rescue _ -> :ok end)

# Coordination-intensive workload that stresses WALCoordinator
coordination_workload = fn worker_id ->
  Enum.reduce(1..50, 0, fn _, acc ->
    # Mix of operations that require coordination
    operations = [
      # Simple put/get
      fn ->
        key = "coord_test:#{worker_id}:#{:rand.uniform(keyset)}"
        value = %{worker: worker_id, data: "test_#{:rand.uniform(1000)}"}
        WarpEngine.cosmic_put(key, value)
      end,

      # Batch operations
      fn ->
        batch = Enum.map(1..5, fn i ->
          {"batch:#{worker_id}:#{i}", %{batch_id: i, worker: worker_id}}
        end)
        Enum.each(batch, fn {k, v} -> WarpEngine.cosmic_put(k, v) end)
      end,

      # Read operations
      fn ->
        key = "coord_test:#{worker_id}:#{:rand.uniform(keyset)}"
        WarpEngine.cosmic_get(key)
      end,

      # Mixed operations
      fn ->
        # Write
        key = "mixed:#{worker_id}:#{:rand.uniform(keyset)}"
        value = %{mixed: true, worker: worker_id, timestamp: System.monotonic_time(:millisecond)}
        WarpEngine.cosmic_put(key, value)

        # Read back
        WarpEngine.cosmic_get(key)
      end
    ]

    # Execute random operation
    operation = Enum.random(operations)
    operation.()

    acc + 1
  end)
end

# Benchmark runner
run_trial = fn procs ->
  # Record coordination metrics before
  coordinator_pid = Process.whereis(WarpEngine.WALCoordinator)
  coordinator_info = if coordinator_pid do
    try do
      Process.info(coordinator_pid, [:message_queue_len, :memory, :reductions])
    rescue
      _ -> %{}
    end
  else
    %{}
  end

  # Warmup
  tasks = for i <- 1..procs do
    Task.async(fn ->
      deadline = System.monotonic_time(:millisecond) + warmup_ms
      spin = fn spin ->
        if System.monotonic_time(:millisecond) < deadline do
          _ = coordination_workload.(i)
          spin.(spin)
        else
          :ok
        end
      end
      spin.(spin)
    end)
  end
  Task.await_many(tasks, warmup_ms + 10000)

  # Check coordinator state after warmup
  coordinator_after_warmup = if coordinator_pid do
    try do
      Process.info(coordinator_pid, [:message_queue_len, :memory, :reductions])
    rescue
      _ -> %{}
    end
  else
    %{}
  end

  # Measure
  start_time = System.monotonic_time(:millisecond)
  counters = :ets.new(:coordination_counters, [:set, :public])
  :ets.insert(counters, {:ops, 0})

  tasks2 = for i <- 1..procs do
    Task.async(fn ->
      deadline = start_time + measure_ms
      spin = fn spin, local_ops ->
        if System.monotonic_time(:millisecond) < deadline do
          new_ops = coordination_workload.(i)
          spin.(spin, local_ops + new_ops)
        else
          :ets.update_counter(counters, :ops, {2, local_ops}, {:ops, 0})
          :ok
        end
      end
      spin.(spin, 0)
    end)
  end

  Task.await_many(tasks2, measure_ms + 30000)
  total_ops = :ets.lookup_element(counters, :ops, 2)
  duration = System.monotonic_time(:millisecond) - start_time
  :ets.delete(counters)

  # Check coordinator state after measurement
  coordinator_after_measure = if coordinator_pid do
    try do
      Process.info(coordinator_pid, [:message_queue_len, :memory, :reductions])
    rescue
      _ -> %{}
    end
  else
    %{}
  end

  ops_per_sec = div(total_ops * 1000, max(duration, 1))

  %{
    ops: total_ops,
    ms: duration,
    ops_sec: ops_per_sec,
    coordinator_before: coordinator_info,
    coordinator_after_warmup: coordinator_after_warmup,
    coordinator_after_measure: coordinator_after_measure
  }
end

# Run benchmarks
IO.puts("\n🎯 Process Coordination Overhead Test")
IO.puts("=" |> String.duplicate(60))

Enum.each(concurrency_levels, fn procs ->
  IO.puts("\n== Testing with #{procs} processes ==")

  results = for trial <- 1..trials do
    IO.puts("  Trial #{trial}/#{trials}...")
    result = run_trial.(procs)
    Process.sleep(500)  # Cooldown between trials
    result
  end

  # Calculate statistics
  rates = Enum.map(results, & &1.ops_sec)
  sorted_rates = Enum.sort(rates)
  n = length(sorted_rates)
  p50 = Enum.at(sorted_rates, div(n * 50, 100))
  p90 = Enum.at(sorted_rates, min(n - 1, div(n * 90, 100)))
  median = Enum.at(sorted_rates, div(n, 2))
  best = Enum.max_by(results, & &1.ops_sec)

  IO.puts("   • #{procs} processes: best #{best.ms}ms (#{best.ops_sec} ops/sec)")
  IO.puts("     median #{median} (p50 #{p50}, p90 #{p90})")

  # Coordination metrics
  IO.puts("   🔗 Coordination Metrics:")

  # WALCoordinator message queue
  if best.coordinator_before[:message_queue_len] do
    before_q = best.coordinator_before[:message_queue_len]
    after_warmup_q = best.coordinator_after_warmup[:message_queue_len]
    after_measure_q = best.coordinator_after_measure[:message_queue_len]

    IO.puts("     📨 Message queue: before=#{before_q}, after_warmup=#{after_warmup_q}, after_measure=#{after_measure_q}")

    if after_measure_q > before_q do
      IO.puts("     ⚠️  Message queue grew by #{after_measure_q - before_q} messages")
    end
  end

  # WALCoordinator memory
  if best.coordinator_before[:memory] do
    before_mem = best.coordinator_before[:memory]
    after_warmup_mem = best.coordinator_after_warmup[:memory]
    after_measure_mem = best.coordinator_after_measure[:memory]

    IO.puts("     💾 Coordinator memory: before=#{Float.round(before_mem / 1024, 1)}KB, after_warmup=#{Float.round(after_warmup_mem / 1024, 1)}KB, after_measure=#{Float.round(after_measure_mem / 1024, 1)}KB")
  end

  # Test coordination-specific metrics
  if procs >= 4 do
    IO.puts("   🔍 Coordination Analysis:")

    # Check shard process states
    try do
      shard_0_pid = Process.whereis(:"spacetime_shard_0")
      if shard_0_pid do
        shard_info = Process.info(shard_0_pid, [:message_queue_len, :memory])
        IO.puts("     📊 Shard 0: queue=#{shard_info[:message_queue_len] || "N/A"}, memory=#{Float.round((shard_info[:memory] || 0) / 1024, 1)}KB")
      end
    rescue
      _ -> IO.puts("     📊 Shard info unavailable")
    end

    # Check system process count
    process_count = :erlang.processes() |> length()
    IO.puts("     🔄 Total processes: #{process_count}")
  end

  Process.sleep(1000)  # Cooldown between levels
end)

IO.puts("\n🎉 Coordination Overhead Test Complete!")
IO.puts("💡 If coordination overhead causes poor scaling, check:")
IO.puts("   • Coordinator response times")
IO.puts("   • Process communication overhead")
IO.puts("   • Shard process bottlenecks")
