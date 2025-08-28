defmodule ServiceWarpWeb.SpatialController do
  use ServiceWarpWeb, :controller

  def nearby_search(conn, %{"lat" => lat, "lon" => lon, "radius" => radius}) do
    # Search for objects near the given coordinates
    coordinates = {String.to_float(lat), String.to_float(lon)}
    radius_meters = String.to_integer(radius)

    case WarpEngine.radius_search(coordinates, radius_meters) do
      {:ok, objects} ->
        json(conn, %{
          query: %{coordinates: coordinates, radius: radius_meters},
          results: objects,
          count: length(objects)
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def bbox_search(conn, %{"min_lat" => min_lat, "min_lon" => min_lon, "max_lat" => max_lat, "max_lon" => max_lon}) do
    # Search for objects within the bounding box
    bbox = {
      String.to_float(min_lat),
      String.to_float(min_lon),
      String.to_float(max_lat),
      String.to_float(max_lon)
    }

    case WarpEngine.bbox_search(bbox) do
      {:ok, objects} ->
        json(conn, %{
          query: %{bbox: bbox},
          results: objects,
          count: length(objects)
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end
end
