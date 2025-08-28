defmodule WarpEngine do
  @moduledoc """
  WarpEngine - High-performance geospatial database with physics-inspired optimizations.

  WarpEngine combines Elixir's distributed systems capabilities with high-performance
  spatial operations and intelligent optimization algorithms.

  ## Basic Usage

      # Store a spatial object
      {:ok, :stored, shard_id, time} = WarpEngine.put("restaurant-1", %{
        coordinates: {37.7749, -122.4194},
        properties: %{"name" => "Best Pizza", "rating" => 4.5}
      })

      # Retrieve an object
      {:ok, object, shard_id, time} = WarpEngine.get("restaurant-1")

      # Spatial search
      {:ok, results} = WarpEngine.bbox_search({37.7, -122.5, 37.8, -122.4})

      # Radius search
      {:ok, results} = WarpEngine.radius_search({37.7749, -122.4194}, 1000)
  """

  alias WarpEngine.{GeoObject, InputValidator}
  alias WarpEngine.Storage.ShardManager

  @type object_id :: binary()
  @type coordinates :: {lat :: float(), lon :: float()}
  @type bounding_box :: {min_lat :: float(), min_lon :: float(),
                         max_lat :: float(), max_lon :: float()}

  # ============================================================================
  # Core CRUD Operations
  # ============================================================================

  @doc """
  Stores a spatial object.

  ## Parameters
  - `id`: Unique identifier for the object
  - `data`: Object data (coordinates, properties, etc.)

  ## Returns
  `{:ok, :stored, shard_id, storage_time_us}` or `{:error, reason}`

  ## Examples

      WarpEngine.put("user-123", %{
        coordinates: {37.7749, -122.4194},
        geometry: :point,
        properties: %{"name" => "Alice", "status" => "active"}
      })

  """
  @spec put(object_id(), map()) ::
    {:ok, :stored, non_neg_integer(), non_neg_integer()} | {:error, term()}
  def put(id, data) do
    start_time = System.monotonic_time(:microsecond)

    with {:ok, validated_id} <- InputValidator.validate_object_id(id),
         {:ok, validated_props} <- InputValidator.validate_properties(data[:properties] || %{}),
         {:ok, geo_object} <- build_geo_object(validated_id, data, validated_props) do

      case ShardManager.put_object(geo_object) do
        :ok ->
          end_time = System.monotonic_time(:microsecond)
          storage_time = end_time - start_time
          {:ok, :stored, geo_object.shard_id, storage_time}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Retrieves a spatial object.
  """
  @spec get(object_id()) ::
    {:ok, GeoObject.t(), non_neg_integer(), non_neg_integer()} | {:error, term()}
  def get(id) do
    start_time = System.monotonic_time(:microsecond)

    with {:ok, validated_id} <- InputValidator.validate_object_id(id) do
      case ShardManager.get_object(validated_id) do
        {:ok, object} ->
          end_time = System.monotonic_time(:microsecond)
          retrieval_time = end_time - start_time
          {:ok, object, object.shard_id, retrieval_time}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Updates a spatial object.
  """
  @spec update(object_id(), map()) ::
    {:ok, :updated, non_neg_integer(), non_neg_integer()} | {:error, term()}
  def update(id, updates) do
    start_time = System.monotonic_time(:microsecond)

    with {:ok, current_object, _shard, _time} <- get(id),
         {:ok, updated_object} <- apply_updates(current_object, updates) do

      case ShardManager.put_object(updated_object) do
        :ok ->
          end_time = System.monotonic_time(:microsecond)
          update_time = end_time - start_time
          {:ok, :updated, updated_object.shard_id, update_time}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Deletes a spatial object.
  """
  @spec delete(object_id()) :: :ok | {:error, term()}
  def delete(id) do
    with {:ok, validated_id} <- InputValidator.validate_object_id(id) do
      ShardManager.delete_object(validated_id)
    end
  end

  # ============================================================================
  # Spatial Query Operations
  # ============================================================================

  @doc """
  Searches for objects within a bounding box.
  """
  @spec bbox_search(bounding_box()) :: {:ok, [GeoObject.t()]} | {:error, term()}
  def bbox_search({min_lat, min_lon, max_lat, max_lon}) do
    with {:ok, validated_bbox} <- InputValidator.validate_bbox(min_lat, min_lon, max_lat, max_lon) do
      ShardManager.bbox_search(validated_bbox)
    end
  end

  @doc """
  Searches for objects within a radius of a center point.
  """
  @spec radius_search(coordinates(), number()) :: {:ok, [GeoObject.t()]} | {:error, term()}
  def radius_search({lat, lon}, radius_meters) do
    with {:ok, validated_params} <- InputValidator.validate_radius_search(lat, lon, radius_meters) do
      {validated_lat, validated_lon, validated_radius} = validated_params
      ShardManager.radius_search({validated_lat, validated_lon}, validated_radius)
    end
  end

  # ============================================================================
  # System Operations
  # ============================================================================

  @doc """
  Gets comprehensive system metrics and performance statistics.
  """
  @spec get_stats() :: map()
  def get_stats do
    ShardManager.get_shard_stats()
  end

  @doc """
  Gets system health status.
  """
  @spec health_check() :: {:ok, map()} | {:error, term()}
  def health_check do
    try do
      stats = get_stats()
      {:ok, %{status: :healthy, stats: stats}}
    rescue
      e ->
        {:error, %{status: :unhealthy, error: Exception.message(e)}}
    end
  end

  # ============================================================================
  # Private Implementation Functions
  # ============================================================================

  defp build_geo_object(id, %{coordinates: coordinates} = data, validated_props) do
    with {:ok, validated_coords} <- InputValidator.validate_coordinates(elem(coordinates, 0), elem(coordinates, 1)) do
      geo_object = GeoObject.new(
        id,
        validated_coords,
        data[:geometry] || :point,
        validated_props
      )
      {:ok, geo_object}
    end
  end

  defp build_geo_object(_id, _data, _validated_props), do: {:error, :missing_coordinates}

  defp apply_updates(%GeoObject{} = object, updates) do
    # Apply coordinate updates if present
    updated_coords = case updates[:coordinates] do
      {lat, lon} ->
        case InputValidator.validate_coordinates(lat, lon) do
          {:ok, coords} -> coords
          _ -> object.coordinates
        end
      _ -> object.coordinates
    end

    # Apply geometry updates if present
    updated_geometry = updates[:geometry] || object.geometry

    # Apply property updates if present
    updated_props = case updates[:properties] do
      props when is_map(props) ->
        case InputValidator.validate_properties(props) do
          {:ok, validated_props} -> Map.merge(object.properties, validated_props)
          _ -> object.properties
        end
      _ -> object.properties
    end

    updated_object = %{object |
      coordinates: updated_coords,
      geometry: updated_geometry,
      properties: updated_props,
      updated_at: DateTime.utc_now()
    }

    {:ok, updated_object}
  end
end
