defmodule WarpEngine.InputValidator do
  @moduledoc """
  Input validation for WarpEngine API endpoints.

  Provides validation for geographic coordinates, bounding boxes, and GeoJSON inputs.
  Ensures data integrity and prevents invalid spatial operations.
  """

  @doc """
  Validates geographic coordinates.
  """
  @spec validate_coordinates(float(), float()) :: {:ok, {float(), float()}} | {:error, String.t()}
  def validate_coordinates(lat, lon) when is_number(lat) and is_number(lon) do
    cond do
      lat < -90.0 or lat > 90.0 ->
        {:error, "Latitude must be between -90 and 90 degrees"}
      lon < -180.0 or lon > 180.0 ->
        {:error, "Longitude must be between -180 and 180 degrees"}
      true ->
        {:ok, {Float.round(lat, 8), Float.round(lon, 8)}}
    end
  end

  def validate_coordinates(_, _), do: {:error, "Coordinates must be numbers"}

  @doc """
  Validates bounding box parameters.
  """
  @spec validate_bbox(float(), float(), float(), float()) :: {:ok, {float(), float(), float(), float()}} | {:error, String.t()}
  def validate_bbox(min_lat, min_lon, max_lat, max_lon) do
    with {:ok, {min_lat, min_lon}} <- validate_coordinates(min_lat, min_lon),
         {:ok, {max_lat, max_lon}} <- validate_coordinates(max_lat, max_lon) do
      cond do
        min_lat >= max_lat ->
          {:error, "min_lat must be less than max_lat"}
        min_lon >= max_lon ->
          {:error, "min_lon must be less than max_lon"}
        abs(max_lat - min_lat) > 10.0 ->
          {:error, "Bounding box too large (max 10 degrees)"}
        abs(max_lon - min_lon) > 10.0 ->
          {:error, "Bounding box too large (max 10 degrees)"}
        true ->
          {:ok, {min_lat, min_lon, max_lat, max_lon}}
      end
    end
  end

  @doc """
  Validates radius search parameters.
  """
  @spec validate_radius_search(float(), float(), number()) :: {:ok, {float(), float(), number()}} | {:error, String.t()}
  def validate_radius_search(lat, lon, radius) when is_number(radius) and radius > 0 do
    with {:ok, {lat, lon}} <- validate_coordinates(lat, lon) do
      if radius <= 100_000 do  # Max 100km radius
        {:ok, {lat, lon, radius}}
      else
        {:error, "Radius too large (max 100km)"}
      end
    end
  end

  def validate_radius_search(_, _, radius) when not is_number(radius) or radius <= 0 do
    {:error, "Radius must be a positive number"}
  end

  @doc """
  Validates and sanitizes GeoJSON input.
  """
  @spec validate_geojson(map()) :: {:ok, map()} | {:error, String.t()}
  def validate_geojson(geojson) when is_map(geojson) do
    case geojson do
      %{"type" => "Point", "coordinates" => [lon, lat]} when is_number(lon) and is_number(lat) ->
        validate_coordinates(lat, lon)

      %{"type" => "Polygon", "coordinates" => [exterior_ring | _]} ->
        validate_polygon_ring(exterior_ring)

      %{"type" => type} when type in ["LineString", "MultiPoint", "MultiPolygon"] ->
        # Additional validation for other geometry types
        validate_complex_geometry(geojson)

      _ ->
        {:error, "Invalid or unsupported GeoJSON geometry"}
    end
  end

  def validate_geojson(_), do: {:error, "GeoJSON must be a map"}

  @doc """
  Validates polygon ring coordinates.
  """
  @spec validate_polygon_ring([[number()]]) :: {:ok, [[number()]]} | {:error, String.t()}
  def validate_polygon_ring(coordinates) when is_list(coordinates) do
    cond do
      length(coordinates) < 4 ->
        {:error, "Polygon ring must have at least 4 coordinates"}
      length(coordinates) > 10_000 ->
        {:error, "Polygon ring too complex (max 10,000 vertices)"}
      true ->
        # Validate each coordinate pair
        Enum.reduce_while(coordinates, {:ok, []}, fn [lon, lat], {:ok, acc} ->
          case validate_coordinates(lat, lon) do
            {:ok, coord} -> {:cont, {:ok, [coord | acc]}}
            error -> {:halt, error}
          end
        end)
    end
  end

  def validate_polygon_ring(_), do: {:error, "Polygon coordinates must be a list"}

  @doc """
  Validates complex geometry types.
  """
  @spec validate_complex_geometry(map()) :: {:ok, map()} | {:error, String.t()}
  def validate_complex_geometry(%{"type" => "LineString", "coordinates" => coordinates}) do
    if is_list(coordinates) and length(coordinates) >= 2 and length(coordinates) <= 10_000 do
      # Validate each coordinate pair
      Enum.reduce_while(coordinates, {:ok, []}, fn [lon, lat], {:ok, acc} ->
        case validate_coordinates(lat, lon) do
          {:ok, coord} -> {:cont, {:ok, [coord | acc]}}
          error -> {:halt, error}
        end
      end)
    else
      {:error, "LineString must have 2-10,000 coordinate pairs"}
    end
  end

  def validate_complex_geometry(%{"type" => "MultiPoint", "coordinates" => coordinates}) do
    if is_list(coordinates) and length(coordinates) <= 10_000 do
      # Validate each coordinate pair
      Enum.reduce_while(coordinates, {:ok, []}, fn [lon, lat], {:ok, acc} ->
        case validate_coordinates(lat, lon) do
          {:ok, coord} -> {:cont, {:ok, [coord | acc]}}
          error -> {:halt, error}
        end
      end)
    else
      {:error, "MultiPoint must have at most 10,000 coordinate pairs"}
    end
  end

  def validate_complex_geometry(%{"type" => "MultiPolygon", "coordinates" => coordinates}) do
    if is_list(coordinates) and length(coordinates) <= 100 do
      # Validate each polygon
      Enum.reduce_while(coordinates, {:ok, []}, fn polygon_coords, {:ok, acc} ->
        case validate_polygon_ring(polygon_coords) do
          {:ok, validated} -> {:cont, {:ok, [validated | acc]}}
          error -> {:halt, error}
        end
      end)
    else
      {:error, "MultiPolygon must have at most 100 polygons"}
    end
  end

  def validate_complex_geometry(_), do: {:error, "Unsupported geometry type"}

  @doc """
  Validates object ID format.
  """
  @spec validate_object_id(binary()) :: {:ok, binary()} | {:error, String.t()}
  def validate_object_id(id) when is_binary(id) do
    cond do
      byte_size(id) == 0 ->
        {:error, "Object ID cannot be empty"}
      byte_size(id) > 255 ->
        {:error, "Object ID too long (max 255 bytes)"}
      String.contains?(id, ["\0", "\r", "\n", "\t"]) ->
        {:error, "Object ID contains invalid characters"}
      true ->
        {:ok, String.trim(id)}
    end
  end

  def validate_object_id(_), do: {:error, "Object ID must be a string"}

  @doc """
  Validates properties map.
  """
  @spec validate_properties(map()) :: {:ok, map()} | {:error, String.t()}
  def validate_properties(properties) when is_map(properties) do
    # Check for reasonable property limits
    cond do
      map_size(properties) > 100 ->
        {:error, "Too many properties (max 100)"}
      map_size(properties) == 0 ->
        {:ok, %{}}
      true ->
        # Validate property values (basic checks)
        case validate_property_values(properties) do
          {:ok, _} -> {:ok, properties}
          error -> error
        end
    end
  end

  def validate_properties(_), do: {:error, "Properties must be a map"}

  defp validate_property_values(properties) do
    # Check for reasonable property value sizes
    Enum.reduce_while(properties, {:ok, nil}, fn {_key, value}, _acc ->
      case estimate_value_size(value) do
        {:ok, size} when size <= 1_000_000 -> {:cont, {:ok, nil}}  # Max 1MB per property
        {:ok, _size} -> {:halt, {:error, "Property value too large (max 1MB)"}}
        error -> {:halt, error}
      end
    end)
  end

  defp estimate_value_size(value) when is_binary(value) do
    {:ok, byte_size(value)}
  end

  defp estimate_value_size(value) when is_map(value) do
    # Estimate map size (rough approximation)
    {:ok, map_size(value) * 100}
  end

  defp estimate_value_size(value) when is_list(value) do
    # Estimate list size (rough approximation)
    {:ok, length(value) * 100}
  end

  defp estimate_value_size(value) when is_number(value) or is_boolean(value) do
    {:ok, 8}  # Small fixed size
  end

  defp estimate_value_size(_), do: {:error, "Unsupported property value type"}
end
