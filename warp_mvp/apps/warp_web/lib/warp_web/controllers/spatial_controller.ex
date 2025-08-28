defmodule WarpWeb.SpatialController do
  use WarpWeb, :controller

  alias WarpEngine
  alias WarpEngine.GeoObject

  @doc """
  Creates a new spatial object.
  """
  def create(conn, %{"id" => id, "coordinates" => coordinates, "properties" => properties}) do
    data = %{
      coordinates: coordinates,
      properties: properties
    }

    case WarpEngine.put(id, data) do
      {:ok, :stored, shard_id, time_us} ->
        conn
        |> put_status(:created)
        |> json(%{
          id: id,
          status: "stored",
          shard_id: shard_id,
          storage_time_us: time_us
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: id, coordinates, properties"})
  end

  @doc """
  Retrieves a spatial object by ID.
  """
  def show(conn, %{"id" => id}) do
    case WarpEngine.get(id) do
      {:ok, object, shard_id, time_us} ->
        conn
        |> json(%{
          object: GeoObject.to_geojson(object),
          shard_id: shard_id,
          retrieval_time_us: time_us
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Object not found"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  Updates a spatial object.
  """
  def update(conn, %{"id" => id} = params) do
    updates = Map.take(params, ["coordinates", "properties"])

    case WarpEngine.update(id, updates) do
      {:ok, :updated, shard_id, time_us} ->
        conn
        |> json(%{
          id: id,
          status: "updated",
          shard_id: shard_id,
          update_time_us: time_us
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Object not found"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  Deletes a spatial object.
  """
  def delete(conn, %{"id" => id}) do
    case WarpEngine.delete(id) do
      :ok ->
        conn
        |> json(%{
          id: id,
          status: "deleted"
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Object not found"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  Searches for objects within a bounding box.
  """
  def bbox_search(conn, %{"min_lat" => min_lat, "min_lon" => min_lon, "max_lat" => max_lat, "max_lon" => max_lon}) do
    case WarpEngine.bbox_search({min_lat, min_lon, max_lat, max_lon}) do
      {:ok, objects} ->
        geojson_objects = Enum.map(objects, &GeoObject.to_geojson/1)

        conn
        |> json(%{
          type: "FeatureCollection",
          features: geojson_objects,
          count: length(geojson_objects)
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def bbox_search(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: min_lat, min_lon, max_lat, max_lon"})
  end

  @doc """
  Searches for objects within a radius of a center point.
  """
  def radius_search(conn, %{"lat" => lat, "lon" => lon, "radius" => radius}) do
    case WarpEngine.radius_search({lat, lon}, radius) do
      {:ok, objects} ->
        geojson_objects = Enum.map(objects, &GeoObject.to_geojson/1)

        conn
        |> json(%{
          type: "FeatureCollection",
          features: geojson_objects,
          count: length(geojson_objects),
          center: %{lat: lat, lon: lon},
          radius_meters: radius
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def radius_search(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: lat, lon, radius"})
  end
end
