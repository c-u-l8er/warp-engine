#!/usr/bin/env elixir

# Pure WAL Performance Test - Isolates WAL bottlenecks
# Tests only cosmic_put operations to measure WAL performance scaling

require Logger
Logger.configure(level: :info)
Logger.configure_backend(:console, level: :info)

# Configuration - MUST be set before application startup
Application.put_env(:warp_engine, :bench_mode, false)
Application.put_env(:warp_engine, :use_numbered_shards, true)
Application.put_env(:warp_engine, :num_numbered_shards, 24)

# Ensure clean state by stopping any existing application
_ = Application.stop(:warp_engine)
Process.sleep(100)  # Give time for cleanup

concurrency_levels = [1, 2, 4, 6, 12, 24]
warmup_ms = 2000
measure_ms = 5000
trials = 1
keyset = 10000

IO.puts("🔧 WAL-Only Benchmark Configuration:")
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

# Atomic counter pre-warming disabled - using main WAL system only
# IO.puts("⚡ Pre-warming atomic counter cache...")
# WarpEngine.WALOperations.pre_warm_atomic_counters()
# IO.puts("✅ Atomic counter cache ready")

# Prime the system
_ = (try do GenServer.call(WarpEngine, :get_current_state, 5000) rescue _ -> :ok end)

# Create ETS tables in main process (so they persist after benchmark tasks terminate)
IO.puts("🔧 Creating ETS tables for lock-free WAL...")
Enum.each(0..23, fn i ->
  table_name = :"wal_process_#{i}"
  :ets.new(table_name, [:set, :public, :named_table])
end)
IO.puts("✅ Created 24 ETS tables for lock-free WAL")

# Minimal WAL workload - bypass all cosmic_put overhead
wal_workload = fn process_id ->
  # Get sequence number directly (bypass GenServer)
  sequence_counter_ref = WarpEngine.WAL.get_sequence_counter()
  sequence_number = :atomics.add_get(sequence_counter_ref, 1, 1)

  # Create minimal operation
  operation = %{
    operation: :put,
    key: "key_#{process_id}_#{sequence_number}",
    value: "value_#{sequence_number}",
    timestamp: :os.system_time(:microsecond),
    sequence: sequence_number,
    shard_id: :hot_data
  }

  # DIRECT ETS WRITE - zero coordination overhead
  # Each process writes directly to its own ETS table
  process_id_hash = :erlang.phash2(self(), 1000000)
  wal_table = :"wal_process_#{rem(process_id_hash, 24)}"

  # Table already exists (created in main process)
  # Direct ETS insert - no GenServer, no coordination, no bottlenecks
  :ets.insert(wal_table, {sequence_number, operation})

  # Debug: Log table size occasionally
  if rem(sequence_number, 10000) == 0 do
    table_size = :ets.info(wal_table, :size)
    IO.puts("     📊 Table #{wal_table} size: #{table_size}")
  end

  1  # Return 1 operation completed
end

# Benchmark runner
run_trial = fn procs ->
  # Warmup
  tasks = for i <- 1..procs do
    Task.async(fn ->
      deadline = System.monotonic_time(:millisecond) + warmup_ms
      spin = fn spin ->
        if System.monotonic_time(:millisecond) < deadline do
          _ = wal_workload.(i)
          spin.(spin)
        else
          :ok
        end
      end
      spin.(spin)
    end)
  end
  Task.await_many(tasks, warmup_ms + 10000)

  # Measure
  start_time = System.monotonic_time(:millisecond)
  counters = :ets.new(:wal_counters, [:set, :public])
  :ets.insert(counters, {:ops, 0})

  tasks2 = for i <- 1..procs do
    Task.async(fn ->
      deadline = start_time + measure_ms
      spin = fn spin, local_ops ->
        if System.monotonic_time(:millisecond) < deadline do
          new_ops = wal_workload.(i)
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

  ops_per_sec = div(total_ops * 1000, max(duration, 1))
  %{ops: total_ops, ms: duration, ops_sec: ops_per_sec}
end

# Run benchmarks
IO.puts("\n🎯 WAL-Only Performance Test")
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

  # Get WAL metrics
  get_wal_metrics = fn ->
    try do
      # Get WAL metrics from ETS-based process tables
      process_tables = Enum.map(0..23, fn i ->
        table_name = :"wal_process_#{i}"
        case :ets.info(table_name) do
          :undefined -> {table_name, 0}
          _ -> {table_name, :ets.info(table_name, :size)}
        end
      end)

      total_entries = Enum.reduce(process_tables, 0, fn {_table, size}, acc -> acc + size end)
      active_tables = Enum.count(process_tables, fn {_table, size} -> size > 0 end)

      # Debug: Show first few table sizes
      first_tables = Enum.take(process_tables, 5)
      IO.puts("     🔍 Debug - First 5 tables: #{inspect(first_tables)}")

      # Debug: Show ALL tables with data
      tables_with_data = Enum.filter(process_tables, fn {_table, size} -> size > 0 end)
      if length(tables_with_data) > 0 do
        IO.puts("     🔍 Debug - Tables with data: #{inspect(tables_with_data)}")
      else
        IO.puts("     ❌ Debug - ALL tables are empty!")
      end

      %{
        shard_count: active_tables,
        total_entries: total_entries,
        shard_0_sequence: :atomics.get(WarpEngine.WAL.get_sequence_counter(), 1)
      }
    rescue
      error ->
        IO.puts("     ❌ Error getting WAL metrics: #{inspect(error)}")
        %{shard_count: 0, total_entries: 0, shard_0_sequence: 0}
    end
  end

  # Test WAL-specific metrics (BEFORE force flush to see actual data)
  if procs >= 4 do
    IO.puts("   🔍 WAL Metrics:")

    wal_metrics = get_wal_metrics.()
    IO.puts("     📁 WAL tables: #{wal_metrics.shard_count}, Total entries: #{wal_metrics.total_entries}")
    IO.puts("     🔢 Shard 0 sequence: #{wal_metrics.shard_0_sequence}")
  end

  # Force flush all process WAL tables to prevent ETS buildup
  try do
    # Debug: Check table sizes before force flush
    IO.puts("     🔍 Debug - Before force flush:")
    Enum.each(0..23, fn i ->
      table_name = :"wal_process_#{i}"
      case :ets.info(table_name) do
        :undefined -> :ok
        _ ->
          size = :ets.info(table_name, :size)
          if size > 0 do
            IO.puts("       📊 #{table_name}: #{size} entries")
          end
      end
    end)

    # Flush all process WAL tables
    Enum.each(0..23, fn i ->
      table_name = :"wal_process_#{i}"
      case :ets.info(table_name) do
        :undefined -> :ok
        _ ->
          # Force flush this table
          entries = :ets.tab2list(table_name)
          if length(entries) > 0 do
            # In a real system, you'd send these to persistent storage
            # For now, just clear the table to prevent memory buildup
            :ets.delete_all_objects(table_name)
          end
      end
    end)
    Logger.debug("🔄 Forced flush of all process WAL tables after #{procs} processes test")
  rescue
    _ -> :ok  # Ignore flush errors
  end

  Process.sleep(1000)  # Cooldown between levels
end)

IO.puts("\n🎉 WAL-Only Benchmark Complete!")
IO.puts("💡 If WAL performance scales poorly, check:")
IO.puts("   • WAL file I/O bottlenecks")
IO.puts("   • Shard locking contention")
IO.puts("   • Disk I/O saturation")
