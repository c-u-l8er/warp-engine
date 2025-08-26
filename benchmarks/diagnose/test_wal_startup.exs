#!/usr/bin/env elixir

# Simple test to debug WALCoordinator startup
require Logger
Logger.configure(level: :info)

# Set configuration
Application.put_env(:warp_engine, :bench_mode, false)
Application.put_env(:warp_engine, :use_numbered_shards, true)
Application.put_env(:warp_engine, :num_numbered_shards, 24)

IO.puts("🔧 Testing WALCoordinator startup...")
IO.puts("   bench_mode: #{Application.get_env(:warp_engine, :bench_mode)}")
IO.puts("   use_numbered_shards: #{Application.get_env(:warp_engine, :use_numbered_shards)}")
IO.puts("   num_numbered_shards: #{Application.get_env(:warp_engine, :num_numbered_shards)}")

# Start the application
{:ok, _} = Application.ensure_all_started(:warp_engine)

# Check if WALCoordinator is running
case Process.whereis(WarpEngine.WALCoordinator) do
  nil ->
    IO.puts("❌ WALCoordinator is not running!")

    # Check supervisor children
    case Process.whereis(WarpEngine.Supervisor) do
      nil ->
        IO.puts("❌ WarpEngine.Supervisor is not running!")
      pid ->
        children = Supervisor.which_children(pid)
        IO.puts("👥 Supervisor children: #{inspect(children)}")

        # Try to start WALCoordinator manually
        IO.puts("🔄 Attempting to start WALCoordinator manually...")
        case WarpEngine.WALCoordinator.start_link([]) do
          {:ok, coordinator_pid} ->
            IO.puts("✅ WALCoordinator started manually: #{inspect(coordinator_pid)}")

            # Check if shards are running
            Process.sleep(1000)  # Give it time to start shards

            case WarpEngine.WALCoordinator.shard_processes() do
              {:ok, shard_info} ->
                IO.puts("📊 Shard processes: #{inspect(shard_info)}")
              {:error, reason} ->
                IO.puts("❌ Failed to get shard info: #{inspect(reason)}")
            end

          {:error, reason} ->
            IO.puts("❌ Failed to start WALCoordinator manually: #{inspect(reason)}")
        end
    end

  pid when is_pid(pid) ->
    IO.puts("✅ WALCoordinator is running: #{inspect(pid)}")

    # Check shard processes
    case WarpEngine.WALCoordinator.shard_processes() do
      {:ok, shard_info} ->
        IO.puts("📊 Shard processes: #{inspect(shard_info)}")
      {:error, reason} ->
        IO.puts("❌ Failed to get shard info: #{inspect(reason)}")
    end
end

IO.puts("\n�� Test complete!")
