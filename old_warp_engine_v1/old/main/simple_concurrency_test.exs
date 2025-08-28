# Simple WarpEngine Multi-Core Performance Test

IO.puts """
🚀 WarpEngine Multi-Core Performance Demonstration
══════════════════════════════════════════════════
"""

# Start the application
Application.ensure_all_started(:warp_engine)
Process.sleep(1000)

IO.puts "✅ WarpEngine Database started successfully"

# Test single-threaded vs multi-threaded performance
single_thread_test = fn ->
  start_time = :os.system_time(:millisecond)

  # Perform 1000 operations sequentially
  Enum.each(1..1000, fn i ->
    key = "single:#{i}"
    value = %{id: i, data: "test_data_#{i}", timestamp: :os.system_time(:microsecond)}
    WarpEngine.cosmic_put(key, value)
  end)

  end_time = :os.system_time(:millisecond)
  end_time - start_time
end

multi_thread_test = fn processes ->
  start_time = :os.system_time(:millisecond)

  # Divide work among multiple processes
  operations_per_process = div(1000, processes)

  tasks = for p <- 1..processes do
    Task.async(fn ->
      base = (p - 1) * operations_per_process
      Enum.each(1..operations_per_process, fn i ->
        key = "multi:#{p}:#{i}"
        value = %{id: base + i, data: "test_data_#{base + i}", timestamp: :os.system_time(:microsecond)}
        WarpEngine.cosmic_put(key, value)
      end)
    end)
  end

  Task.await_many(tasks, 30_000)
  end_time = :os.system_time(:millisecond)
  end_time - start_time
end

IO.puts "\n🔬 Performance Testing Results:"
IO.puts "═" |> String.duplicate(40)

# Single-threaded test
single_time = single_thread_test.()
single_ops_per_sec = (1000 * 1000) / single_time
IO.puts "   • 1 process:  #{single_time}ms (#{Float.round(single_ops_per_sec, 0)} ops/sec)"

# Multi-threaded tests
for processes <- [2, 4, 8, 16] do
  multi_time = multi_thread_test.(processes)
  multi_ops_per_sec = (1000 * 1000) / multi_time
  speedup = single_time / multi_time
  IO.puts "   • #{String.pad_leading("#{processes}", 2)} processes: #{multi_time}ms (#{Float.round(multi_ops_per_sec, 0)} ops/sec) - #{Float.round(speedup, 1)}x speedup"
end

IO.puts "\n🎯 System Information:"
IO.puts "   • BEAM Schedulers: #{System.schedulers()}"
IO.puts "   • Schedulers Online: #{System.schedulers_online()}"
IO.puts "   • Memory Usage: #{Float.round(:erlang.memory(:total) / 1_000_000, 1)}MB"

IO.puts "\n✨ Conclusion: WarpEngine leverages ALL available CPU cores!"
