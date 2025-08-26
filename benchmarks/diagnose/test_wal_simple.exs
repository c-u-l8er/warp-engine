#!/usr/bin/env elixir

# Simple WAL test to debug shard issues
require Logger
Logger.configure(level: :info)

# Configuration - MUST be set before application startup
Application.put_env(:warp_engine, :bench_mode, false)
Application.put_env(:warp_engine, :use_numbered_shards, true)
Application.put_env(:warp_engine, :num_numbered_shards, 24)

# Ensure clean state by stopping any existing application
_ = Application.stop(:warp_engine)
Process.sleep(500)  # Give time for cleanup

# Start system
{:ok, _} = Application.ensure_all_started(:warp_engine)
Process.sleep(2000)

IO.puts("=== WAL System Status ===")
IO.puts("WALCoordinator alive: #{Process.alive?(Process.whereis(WarpEngine.WALCoordinator))}")

# Check a few WAL shards
for i <- 0..2 do
  shard_name = :"shard_#{i}"
  case Registry.lookup(WarpEngine.WALRegistry, shard_name) do
    [{pid, _}] ->
      alive = Process.alive?(pid)
      IO.puts("WAL shard #{i} (#{shard_name}): PID=#{inspect(pid)}, Alive=#{alive}")
    [] ->
      IO.puts("WAL shard #{i} (#{shard_name}): Not found in registry")
  end
end

# Try to get sequence counter from shard 0
IO.puts("\n=== Testing Sequence Counter ===")
try do
  seq = WarpEngine.WALShard.get_sequence_counter(:shard_0)
  IO.puts("Shard 0 sequence: #{seq}")
rescue
  error -> IO.puts("Error getting sequence: #{inspect(error)}")
end

# Try to force flush all shards
IO.puts("\n=== Testing Force Flush ===")
try do
  result = WarpEngine.WALCoordinator.force_flush_all()
  IO.puts("Force flush result: #{inspect(result)}")
rescue
  error -> IO.puts("Error force flushing: #{inspect(error)}")
end

IO.puts("\n=== Test Complete ===")
