defmodule WarpEngine.Storage.Cache do
  @moduledoc """
  Behaviour for cache backends used for read-through/write-behind acceleration.

  Cache adapters provide fast access to frequently accessed objects and
  integrate with storage adapters for consistency.
  """

  @type id :: binary()
  @type object :: WarpEngine.GeoObject.t()

  @callback get(id) :: {:hit, object} | :miss | {:error, term()}
  @callback set(object) :: :ok | {:error, term()}
  @callback invalidate(id) :: :ok | {:error, term()}
  @callback clear() :: :ok | {:error, term()}
  @callback stats() :: map()
end
