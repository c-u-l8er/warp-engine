defmodule WarpEngine.CacheCoordinator do
  @moduledoc """
  Coordinates cache write-through and backfill operations off the hot path.

  Replaces per-operation Task.start spawns with a single GenServer that accepts
  cast messages and performs batched or immediate cache writes. This keeps GET/PUT
  critical paths free of process creation overhead.
  """

  use GenServer
  require Logger

  # Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Request a cache backfill for a retrieved value.
  """
  def backfill(key, value, shard_id) do
    GenServer.cast(__MODULE__, {:backfill, key, value, shard_id})
  end

  @doc """
  Request a write-through cache population for a newly written value.
  """
  def write_through(key, value, shard_id) do
    GenServer.cast(__MODULE__, {:write_through, key, value, shard_id})
  end

  # GenServer callbacks

  @impl true
  def init(_opts) do
    state = %{
      caches_refresh_ms: 5_000,
      last_caches_refresh_ms: monotonic_ms(),
      cached_caches: %{}
    }

    {:ok, refresh_caches(state)}
  end

  @impl true
  def handle_cast({:backfill, key, value, shard_id}, state) do
    caches = ensure_caches(state)

    do_cache_put(caches, key, value, shard_id, :read_through)

    {:noreply, maybe_refresh(state)}
  end

  @impl true
  def handle_cast({:write_through, key, value, shard_id}, state) do
    caches = ensure_caches(state)

    do_cache_put(caches, key, value, shard_id, :write_through)

    {:noreply, maybe_refresh(state)}
  end

  # Internal helpers

  defp do_cache_put(caches, key, value, shard_id, access_pattern) do
    cache_level = case shard_id do
      :hot_data -> :hot_data_cache
      :warm_data -> :warm_data_cache
      :cold_data -> :cold_data_cache
      _ -> :universal_cache
    end

    if cache = Map.get(caches, cache_level) do
      try do
        WarpEngine.EventHorizonCache.put(cache, key, value, [
          source_shard: shard_id,
          cached_at: DateTime.utc_now(),
          access_pattern: access_pattern
        ])
      rescue
        _ -> :ok
      end
    end
  end

  defp ensure_caches(state) do
    if map_size(state.cached_caches) > 0 do
      state.cached_caches
    else
      get_event_horizon_caches()
    end
  end

  defp maybe_refresh(%{last_caches_refresh_ms: last, caches_refresh_ms: interval} = state) do
    if monotonic_ms() - last > interval do
      refresh_caches(state)
    else
      state
    end
  end

  defp refresh_caches(state) do
    %{state | cached_caches: get_event_horizon_caches(), last_caches_refresh_ms: monotonic_ms()}
  end

  defp get_event_horizon_caches() do
    try do
      case Process.whereis(WarpEngine) do
        nil -> %{}
        _pid ->
          case :sys.get_state(WarpEngine) do
            %{event_horizon_caches: caches} when is_map(caches) -> caches
            _ -> %{}
          end
      end
    rescue
      _ -> %{}
    end
  end

  defp monotonic_ms() do
    System.monotonic_time(:millisecond)
  end
end
