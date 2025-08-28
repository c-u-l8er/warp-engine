defmodule ServiceWarp.Technicians.Supervisor do
  @moduledoc """
  Supervisor for technician management processes.

  This supervisor manages technician tracking, location updates, and status management.
  """

  use Supervisor

  @doc """
  Starts the technicians supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Technician Manager - handles technician CRUD operations
      {ServiceWarp.Technicians.Manager, []},

      # Location Tracker - manages real-time location updates
      {ServiceWarp.Technicians.LocationTracker, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
