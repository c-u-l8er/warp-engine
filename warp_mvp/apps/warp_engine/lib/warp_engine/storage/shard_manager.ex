defmodule WarpEngine.Storage.ShardManager do
  @moduledoc """
  Manages multiple in-memory shards for distributed spatial object storage.

  Provides consistent hashing for object distribution across shards,
  load balancing, and shard health monitoring.
  """

  use GenServer
  require Logger

  alias WarpEngine.Storage.Shard

  @type t :: %__MODULE__{
    shards: %{non_neg_integer() => pid()},
    shard_count: non_neg_integer(),
    hash_ring: [non_neg_integer()],
    created_at: DateTime.t()
  }

  defstruct [:shards, :shard_count, :hash_ring, :created_at]

  # Client API

  @doc """
  Starts the shard manager with the specified number of shards.
  """
  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the optimal shard for an object using consistent hashing.
  """
  @spec get_shard_for_object(binary()) :: {:ok, non_neg_integer()}
  def get_shard_for_object(object_id) do
    GenServer.call(__MODULE__, {:get_shard_for_object, object_id})
  end

  @doc """
  Stores an object in the appropriate shard.
  """
  @spec put_object(WarpEngine.GeoObject.t()) :: :ok | {:error, term()}
  def put_object(%WarpEngine.GeoObject{} = object) do
    case get_shard_for_object(object.id) do
      {:ok, shard_id} ->
        Shard.put(shard_id, object)
      error ->
        error
    end
  end

  @doc """
  Retrieves an object from the appropriate shard.
  """
  @spec get_object(binary()) :: {:ok, WarpEngine.GeoObject.t()} | {:error, term()}
  def get_object(object_id) do
    case get_shard_for_object(object_id) do
      {:ok, shard_id} ->
        Shard.get(shard_id, object_id)
      error ->
        error
    end
  end

  @doc """
  Deletes an object from the appropriate shard.
  """
  @spec delete_object(binary()) :: :ok | {:error, term()}
  def delete_object(object_id) do
    case get_shard_for_object(object_id) do
      {:ok, shard_id} ->
        Shard.delete(shard_id, object_id)
      error ->
        error
    end
  end

  @doc """
  Searches for objects across all shards within a bounding box.
  """
  @spec bbox_search({float(), float(), float(), float()}) :: {:ok, [WarpEngine.GeoObject.t()]}
  def bbox_search(bbox) do
    GenServer.call(__MODULE__, {:bbox_search, bbox})
  end

  @doc """
  Searches for objects across all shards within a radius.
  """
  @spec radius_search({float(), float()}, number()) :: {:ok, [WarpEngine.GeoObject.t()]}
  def radius_search(center, radius) do
    GenServer.call(__MODULE__, {:radius_search, center, radius})
  end

  @doc """
  Gets statistics for all shards.
  """
  @spec get_shard_stats() :: map()
  def get_shard_stats do
    GenServer.call(__MODULE__, :get_shard_stats)
  end

  # Server callbacks

  @impl true
  def init(opts) do
    shard_count = Keyword.get(opts, :shard_count, System.schedulers_online() * 2)

    Logger.info("Starting ShardManager with #{shard_count} shards")

    # Create shards
    shards = create_shards(shard_count, opts)

    # Build hash ring for consistent hashing
    hash_ring = build_hash_ring(shard_count)

    {:ok, %__MODULE__{
      shards: shards,
      shard_count: shard_count,
      hash_ring: hash_ring,
      created_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:get_shard_for_object, object_id}, _from, state) do
    shard_id = consistent_hash(object_id, state.hash_ring)
    {:reply, {:ok, shard_id}, state}
  end

  @impl true
  def handle_call({:bbox_search, bbox}, _from, state) do
    # Search across all shards
    results = Enum.reduce(state.shards, [], fn {shard_id, _pid}, acc ->
      case Shard.bbox_search(shard_id, bbox) do
        {:ok, objects} -> acc ++ objects
        {:error, _} -> acc
      end
    end)

    {:reply, {:ok, results}, state}
  end

  @impl true
  def handle_call({:radius_search, center, radius}, _from, state) do
    # Search across all shards
    results = Enum.reduce(state.shards, [], fn {shard_id, _pid}, acc ->
      case Shard.radius_search(shard_id, center, radius) do
        {:ok, objects} -> acc ++ objects
        {:error, _} -> acc
      end
    end)

    {:reply, {:ok, results}, state}
  end

  @impl true
  def handle_call(:get_shard_stats, _from, state) do
    stats = Enum.map(state.shards, fn {shard_id, _pid} ->
      Shard.stats(shard_id)
    end)

    total_objects = Enum.reduce(stats, 0, fn stat, acc ->
      acc + stat.object_count
    end)

    total_memory = Enum.reduce(stats, 0, fn stat, acc ->
      acc + stat.memory_usage_bytes
    end)

    summary = %{
      shard_count: state.shard_count,
      total_objects: total_objects,
      total_memory_bytes: total_memory,
      shards: stats,
      created_at: state.created_at
    }

    {:reply, summary, state}
  end

  # Private functions

  defp create_shards(count, opts) do
    Enum.reduce(0..(count - 1), %{}, fn shard_id, acc ->
      shard_opts = [
        read_concurrency: Keyword.get(opts, :read_concurrency, true),
        write_concurrency: Keyword.get(opts, :write_concurrency, true)
      ]

      case Shard.start_link({shard_id, shard_opts}) do
        {:ok, pid} ->
          Map.put(acc, shard_id, pid)
        {:error, reason} ->
          Logger.error("Failed to start shard #{shard_id}: #{inspect(reason)}")
          acc
      end
    end)
  end

  defp build_hash_ring(shard_count) do
    # Create a hash ring with virtual nodes for better distribution
    virtual_nodes_per_shard = 3

    Enum.flat_map(0..(shard_count - 1), fn shard_id ->
      Enum.map(0..(virtual_nodes_per_shard - 1), fn virtual_id ->
        hash_key = "#{shard_id}-#{virtual_id}"
        hash_value = :erlang.phash2(hash_key, 1_000_000)
        {hash_value, shard_id}
      end)
    end)
    |> Enum.sort_by(fn {hash, _shard} -> hash end)
    |> Enum.map(fn {_hash, shard} -> shard end)
  end

  defp consistent_hash(object_id, hash_ring) do
    hash = :erlang.phash2(object_id, 1_000_000)

    # Find the first shard with hash >= object hash
    case Enum.find_index(hash_ring, fn shard_hash ->
      shard_hash >= hash
    end) do
      nil -> List.first(hash_ring)  # Wrap around to first shard
      index -> Enum.at(hash_ring, index)
    end
  end
end
