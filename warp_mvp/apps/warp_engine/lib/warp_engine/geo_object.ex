defmodule WarpEngine.GeoObject do
  @moduledoc """
  Core spatial object data type for WarpEngine.

  Represents any geographic object with coordinates, geometry, and metadata.
  Includes physics-inspired optimization metadata for intelligent routing.
  """

  @type coordinates :: {lat :: float(), lon :: float()}
  @type geometry_type :: :point | :linestring | :polygon | :multipoint |
                         :multilinestring | :multipolygon | :geometrycollection

  @type t :: %__MODULE__{
    id: binary(),
    coordinates: coordinates(),
    geometry: geometry_type(),
    properties: map(),
    metadata: metadata(),
    shard_id: non_neg_integer() | nil,
    created_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  @type metadata :: %{
    access_frequency: float(),           # For gravitational mass calculations
    data_mass: float(),                 # Physics: gravitational mass
    energy_level: non_neg_integer(),    # Physics: quantum energy level
    entangled_objects: [binary()],      # Physics: quantum entanglement
    last_accessed: DateTime.t()
  }

  defstruct [
    :id,
    :coordinates,
    :geometry,
    :properties,
    :metadata,
    :shard_id,
    :created_at,
    :updated_at
  ]

  @doc """
  Creates a new GeoObject with default metadata.
  """
  @spec new(binary(), coordinates(), geometry_type(), map()) :: t()
  def new(id, coordinates, geometry, properties \\ %{}) do
    now = DateTime.utc_now()

    %__MODULE__{
      id: id,
      coordinates: coordinates,
      geometry: geometry,
      properties: properties,
      metadata: default_metadata(),
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Validates geographic coordinates.
  """
  @spec validate_coordinates(float(), float()) :: {:ok, coordinates()} | {:error, String.t()}
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
  Calculates the gravitational mass of an object based on its properties.
  Used by the physics-inspired optimization system.
  """
  @spec calculate_data_mass(t()) :: float()
  def calculate_data_mass(%__MODULE__{} = object) do
    base_mass = 1.0

    # Mass increases with access frequency
    frequency_mass = object.metadata.access_frequency * 0.5

    # Mass increases with property complexity
    property_mass = map_size(object.properties) * 0.1

    # Geometry complexity affects mass
    geometry_mass = case object.geometry do
      :point -> 0.1
      :linestring -> 0.3
      :polygon -> 0.7
      _ -> 0.5
    end

    base_mass + frequency_mass + property_mass + geometry_mass
  end

  @doc """
  Updates the access frequency and last accessed time.
  Used for physics calculations and optimization.
  """
  @spec record_access(t()) :: t()
  def record_access(%__MODULE__{} = object) do
    now = DateTime.utc_now()
    current_frequency = object.metadata.access_frequency

    # Exponential moving average for access frequency
    new_frequency = current_frequency * 0.9 + 0.1

    new_metadata = %{object.metadata |
      access_frequency: new_frequency,
      last_accessed: now
    }

    %{object | metadata: new_metadata, updated_at: now}
  end

  @doc """
  Converts GeoObject to GeoJSON format.
  """
  @spec to_geojson(t()) :: map()
  def to_geojson(%__MODULE__{} = object) do
    {lat, lon} = object.coordinates

    %{
      "type" => "Feature",
      "id" => object.id,
      "geometry" => %{
        "type" => geometry_type_to_string(object.geometry),
        "coordinates" => case object.geometry do
          :point -> [lon, lat]
          _ -> [lon, lat]  # Simplified for template
        end
      },
      "properties" => Map.merge(object.properties, %{
        "created_at" => DateTime.to_iso8601(object.created_at),
        "updated_at" => DateTime.to_iso8601(object.updated_at)
      })
    }
  end

  defp default_metadata do
    %{
      access_frequency: 0.0,
      data_mass: 1.0,
      energy_level: 0,
      entangled_objects: [],
      last_accessed: DateTime.utc_now()
    }
  end

  defp geometry_type_to_string(:point), do: "Point"
  defp geometry_type_to_string(:linestring), do: "LineString"
  defp geometry_type_to_string(:polygon), do: "Polygon"
  defp geometry_type_to_string(:multipoint), do: "MultiPoint"
  defp geometry_type_to_string(:multilinestring), do: "MultiLineString"
  defp geometry_type_to_string(:multipolygon), do: "MultiPolygon"
  defp geometry_type_to_string(:geometrycollection), do: "GeometryCollection"
end
