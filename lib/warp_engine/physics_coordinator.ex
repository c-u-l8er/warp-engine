defmodule WarpEngine.PhysicsCoordinator do
  @moduledoc """
  Offloads physics-related work (e.g., entanglement pattern application) off the
  request critical path. Receives casts from WALOperations and applies
  QuantumIndex patterns asynchronously.
  """

  use GenServer
  require Logger

  # API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Callbacks

  @impl true
  def init(_opts) do
    {:ok, %{observations: 0}}
  end

  @impl true
  def handle_cast({:observe_put, key, value, _shard_id}, state) do
    try do
      # Ensure quantum ETS tables exist in case bench skipped init
      ensure_quantum_ready()
      # Apply entanglement patterns (pattern cache should be initialized by QuantumIndex)
      WarpEngine.QuantumIndex.apply_entanglement_patterns(key, value)
    rescue
      error ->
        Logger.debug("PhysicsCoordinator observe_put error: #{inspect(error)}")
    end

    {:noreply, %{state | observations: state.observations + 1}}
  end

  defp ensure_quantum_ready() do
    try do
      case :ets.whereis(:quantum_pattern_cache) do
        :undefined -> WarpEngine.QuantumIndex.initialize_quantum_system()
        _ -> :ok
      end
    rescue
      _ -> :ok
    end
  end
end
