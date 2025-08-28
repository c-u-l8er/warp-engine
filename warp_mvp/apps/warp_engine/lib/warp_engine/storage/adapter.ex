defmodule WarpEngine.Storage.Adapter do
  @moduledoc """
  Behaviour for storage backends that provide authoritative persistence.

  Storage adapters handle the durable storage of spatial objects and provide
  change data capture (CDC) capabilities to keep in-memory indices warm.
  """

  @type id :: binary()
  @type object :: WarpEngine.GeoObject.t()
  @type bounding_box :: {min_lat :: float(), min_lon :: float(),
                         max_lat :: float(), max_lon :: float()}

  @callback put(object, keyword()) :: {:ok, term()} | {:error, term()}
  @callback get(id, keyword()) :: {:ok, object} | {:error, :not_found | term()}
  @callback delete(id, keyword()) :: :ok | {:error, term()}
  @callback batch_put([object], keyword()) :: {:ok, non_neg_integer()} | {:error, term()}
  @callback bbox_search(bounding_box(), keyword()) :: {:ok, [object]} | {:error, term()}
  @callback radius_search({float(), float()}, number(), keyword()) :: {:ok, [object]} | {:error, term()}
  @callback start_link(keyword()) :: {:ok, pid()} | {:error, term()}
end
