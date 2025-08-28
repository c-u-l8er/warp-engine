defmodule ServiceWarp.Jobs.Supervisor do
  @moduledoc """
  Supervisor for job management processes.

  This supervisor manages job creation, updates, and lifecycle management.
  """

  use Supervisor

  @doc """
  Starts the jobs supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Job Manager - handles job CRUD operations
      {ServiceWarp.Jobs.Manager, []},

      # Job Queue - manages pending job queue
      {ServiceWarp.Jobs.Queue, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
