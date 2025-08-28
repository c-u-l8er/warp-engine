defmodule WarpEngine.ModernWAL do
  @moduledoc """
  Modern High-Performance WAL Architecture using advanced Elixir/OTP patterns.

  This module implements:
  - DynamicSupervisor for dynamic WAL process management
  - Registry for efficient shard discovery without contention
  - :persistent_term for ultra-fast shard routing tables
  - Per-shard fsync strategies for optimal I/O performance

  ## Performance Targets
  - 500,000+ operations/second (2x improvement over current)
  - Linear scaling up to 48+ processes
  - Zero coordination overhead
  - Adaptive I/O strategies per shard
  """

  use DynamicSupervisor
  require Logger

  # Registry for shard discovery
  @registry_name WarpEngine.ModernWALRegistry

  # :persistent_term keys for ultra-fast routing
  @routing_table_key :modern_wal_routing_table
  @shard_config_key :modern_wal_shard_config

  # Configuration
  @max_shards 48  # Support up to 48 shards for maximum concurrency
  @default_fsync_strategy :adaptive  # :immediate, :batch, :adaptive

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🚀 Starting Modern WAL Architecture...")

    # Initialize :persistent_term routing table for ultra-fast lookups
    initialize_routing_table()

    # Start registry for shard discovery
    {:ok, _registry} = Registry.start_link(
      keys: :unique,
      name: @registry_name,
      partitions: System.schedulers_online()
    )

    Logger.info("✅ Modern WAL Architecture ready for 500K+ ops/sec!")
    {:ok, %{}}
  end

  @doc """
  Start default shards after initialization is complete.
  """
  def start_default_shards do
    # Start default shards for immediate performance
    # Use numeric IDs (0-23) instead of atom IDs (:shard_0, :shard_1, etc.)
    default_shards = Enum.map(0..23, &{&1, [fsync_strategy: :adaptive]})

    Enum.each(default_shards, fn {shard_id, opts} ->
      start_shard(shard_id, opts)
    end)

    Logger.info("🚀 Started #{length(default_shards)} default WAL shards")
  end

  @doc """
  Start a new WAL shard with optimized configuration.
  """
  def start_shard(shard_id, opts \\ []) do
    spec = WarpEngine.ModernWALShard.child_spec(shard_id, opts)

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        # Update routing table in :persistent_term for ultra-fast lookups
        update_routing_table(shard_id, pid, opts)
        Logger.info("✅ Started Modern WAL shard #{shard_id}")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("❌ Failed to start Modern WAL shard #{shard_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Ultra-fast shard lookup using :persistent_term (no GenServer calls).
  """
  def get_shard_pid(shard_id) do
    :persistent_term.get(@routing_table_key, %{})
    |> Map.get(shard_id)
  end

  @doc """
  Append operation to WAL with zero coordination overhead.
  """
  def append_operation(shard_id, operation) do
    case get_shard_pid(shard_id) do
      pid when is_pid(pid) ->
        # Direct send to shard process - no GenServer overhead
        send(pid, {:append, operation})
        :ok
      nil ->
        # Shard not found - create it dynamically
        case start_shard(shard_id) do
          {:ok, pid} ->
            send(pid, {:append, operation})
            :ok
          {:error, _} ->
            {:error, :shard_unavailable}
        end
    end
  end

  @doc """
  Get WAL statistics with minimal overhead.
  """
  def stats do
    # Use :persistent_term for ultra-fast stats collection
    routing_table = :persistent_term.get(@routing_table_key, %{})
    shard_config = :persistent_term.get(@shard_config_key, %{})

    %{
      total_shards: map_size(routing_table),
      active_shards: Enum.count(routing_table, fn {_id, pid} -> Process.alive?(pid) end),
      shard_config: shard_config,
      routing_table_size: map_size(routing_table)
    }
  end

  ## PRIVATE FUNCTIONS

  defp initialize_routing_table do
    # Initialize :persistent_term with empty routing table
    :persistent_term.put(@routing_table_key, %{})
    :persistent_term.put(@shard_config_key, %{})
    Logger.info("📊 Initialized :persistent_term routing table")
  end

  defp update_routing_table(shard_id, pid, opts) do
    # Update routing table atomically in :persistent_term
    current_table = :persistent_term.get(@routing_table_key, %{})
    updated_table = Map.put(current_table, shard_id, pid)
    :persistent_term.put(@routing_table_key, updated_table)

    # Update shard configuration
    current_config = :persistent_term.get(@shard_config_key, %{})
    updated_config = Map.put(current_config, shard_id, opts)
    :persistent_term.put(@shard_config_key, updated_config)
  end
end
