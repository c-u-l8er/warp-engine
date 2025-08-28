defmodule WarpEngine.Storage.Shard do
  @moduledoc """
  In-memory shard for spatial object storage and acceleration.

  Each shard manages an ETS table with spatial objects and provides
  fast CRUD operations. Objects are stored with their coordinates
  for efficient spatial queries.
  """

  use GenServer
  require Logger

  alias WarpEngine.GeoObject

  @type t :: %__MODULE__{
    id: non_neg_integer(),
    table: :ets.tid(),
    object_count: non_neg_integer(),
    memory_usage: non_neg_integer(),
    created_at: DateTime.t()
  }

  defstruct [:id, :table, :object_count, :memory_usage, :created_at]

  # Client API

  @doc """
  Starts a new shard with the given ID.
  """
  @spec start_link({non_neg_integer(), keyword()}) :: {:ok, pid()}
  def start_link({id, opts}) do
    GenServer.start_link(__MODULE__, {id, opts}, name: via_name(id))
  end

  @doc """
  Stores a spatial object in the shard.
  """
  @spec put(non_neg_integer(), GeoObject.t()) :: :ok | {:error, term()}
  def put(shard_id, %GeoObject{} = object) do
    GenServer.call(via_name(shard_id), {:put, object})
  end

  @doc """
  Retrieves a spatial object from the shard.
  """
  @spec get(non_neg_integer(), binary()) :: {:ok, GeoObject.t()} | {:error, :not_found}
  def get(shard_id, object_id) do
    GenServer.call(via_name(shard_id), {:get, object_id})
  end

  @doc """
  Deletes a spatial object from the shard.
  """
  @spec delete(non_neg_integer(), binary()) :: :ok | {:error, :not_found}
  def delete(shard_id, object_id) do
    GenServer.call(via_name(shard_id), {:delete, object_id})
  end

  @doc """
  Searches for objects within a bounding box.
  """
  @spec bbox_search(non_neg_integer(), {float(), float(), float(), float()}) :: {:ok, [GeoObject.t()]}
  def bbox_search(shard_id, bbox) do
    GenServer.call(via_name(shard_id), {:bbox_search, bbox})
  end

  @doc """
  Searches for objects within a radius of a center point.
  """
  @spec radius_search(non_neg_integer(), {float(), float()}, number()) :: {:ok, [GeoObject.t()]}
  def radius_search(shard_id, center, radius) do
    GenServer.call(via_name(shard_id), {:radius_search, center, radius})
  end

  @doc """
  Gets shard statistics.
  """
  @spec stats(non_neg_integer()) :: map()
  def stats(shard_id) do
    GenServer.call(via_name(shard_id), :stats)
  end

  # Server callbacks

  @impl true
  def init({id, opts}) do
    table_name = :ets.new(shard_table_name(id), [
      :set, :public, :named_table,
      {:read_concurrency, Keyword.get(opts, :read_concurrency, true)},
      {:write_concurrency, Keyword.get(opts, :write_concurrency, true)}
    ])

    Logger.info("Started shard #{id} with table #{shard_table_name(id)}")

    {:ok, %__MODULE__{
      id: id,
      table: table_name,
      object_count: 0,
      memory_usage: 0,
      created_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:put, %GeoObject{} = object}, _from, state) do
    # Store object with coordinates as key for spatial queries
    {lat, lon} = object.coordinates
    spatial_key = {lat, lon, object.id}

    # Insert into ETS
    :ets.insert(state.table, {object.id, object})
    :ets.insert(state.table, {spatial_key, object.id})

    # Update statistics
    new_count = state.object_count + 1
    new_memory = estimate_memory_usage(object)

    new_state = %{state |
      object_count: new_count,
      memory_usage: state.memory_usage + new_memory
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get, object_id}, _from, state) do
    case :ets.lookup(state.table, object_id) do
      [{^object_id, object}] ->
        # Update access metadata
        updated_object = GeoObject.record_access(object)
        :ets.insert(state.table, {object_id, updated_object})
        {:reply, {:ok, updated_object}, state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:delete, object_id}, _from, state) do
    case :ets.lookup(state.table, object_id) do
      [{^object_id, object}] ->
        # Remove object and spatial key
        {lat, lon} = object.coordinates
        spatial_key = {lat, lon, object_id}

        :ets.delete(state.table, object_id)
        :ets.delete(state.table, spatial_key)

        # Update statistics
        new_count = state.object_count - 1
        new_memory = state.memory_usage - estimate_memory_usage(object)

        new_state = %{state |
          object_count: new_count,
          memory_usage: max(0, new_memory)
        }

        {:reply, :ok, new_state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:bbox_search, {min_lat, min_lon, max_lat, max_lon}}, _from, state) do
    # Get all objects and filter by bounding box
    objects = :ets.tab2list(state.table)
    |> Enum.filter(fn
      {_key, %GeoObject{}} -> true
      _ -> false
    end)
    |> Enum.map(fn {_key, object} -> object end)

    # Filter objects within bounding box
    filtered_objects = Enum.filter(objects, fn object ->
      {lat, lon} = object.coordinates
      lat >= min_lat and lat <= max_lat and lon >= min_lon and lon <= max_lon
    end)

    {:reply, {:ok, filtered_objects}, state}
  end

  @impl true
  def handle_call({:radius_search, {center_lat, center_lon}, radius_meters}, _from, state) do
    # Simple radius search using Haversine distance
    objects = :ets.tab2list(state.table)
    |> Enum.filter(fn
      {_key, %GeoObject{}} -> true
      _ -> false
    end)
    |> Enum.map(fn {_key, object} -> object end)

    # Filter objects within radius
    nearby_objects = Enum.filter(objects, fn object ->
      {lat, lon} = object.coordinates
      distance = haversine_distance(center_lat, center_lon, lat, lon)
      distance <= radius_meters
    end)

    {:reply, {:ok, nearby_objects}, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    stats = %{
      id: state.id,
      object_count: state.object_count,
      memory_usage_bytes: state.memory_usage,
      created_at: state.created_at,
      table_name: shard_table_name(state.id)
    }

    {:reply, stats, state}
  end

  # Private functions

  defp via_name(id) do
    {:via, Registry, {WarpEngine.Registry, {__MODULE__, id}}}
  end

  defp shard_table_name(id) do
    String.to_atom("warp_engine_shard_#{id}")
  end

  defp estimate_memory_usage(%GeoObject{} = object) do
    # Rough memory estimation
    base_size = 100  # Basic struct overhead

    # ID size
    id_size = byte_size(object.id)

    # Properties size (rough estimate)
    properties_size = map_size(object.properties) * 50

    # Metadata size
    metadata_size = 50

    base_size + id_size + properties_size + metadata_size
  end

  defp haversine_distance(lat1, lon1, lat2, lon2) do
    # Haversine formula for calculating distance between two points
    r = 6_371_000  # Earth's radius in meters

    lat1_rad = lat1 * :math.pi / 180
    lat2_rad = lat2 * :math.pi / 180
    delta_lat = (lat2 - lat1) * :math.pi / 180
    delta_lon = (lon2 - lon1) * :math.pi / 180

    a = :math.sin(delta_lat / 2) * :math.sin(delta_lat / 2) +
        :math.cos(lat1_rad) * :math.cos(lat2_rad) *
        :math.sin(delta_lon / 2) * :math.sin(delta_lon / 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    r * c
  end
end
