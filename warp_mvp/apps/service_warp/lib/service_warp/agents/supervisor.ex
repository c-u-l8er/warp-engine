defmodule ServiceWarp.Agents.Supervisor do
  @moduledoc """
  Supervisor for all AI agents in the ServiceWarp system.

  This supervisor manages the lifecycle of various AI agents including
  job assignment, route optimization, and customer communication.
  """

  use Supervisor

  @doc """
  Starts the agents supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Job Assignment Agent - assigns jobs to technicians using spatial intelligence
      {ServiceWarp.Agents.JobAssignmentAgent, []},

      # Route Optimization Agent - optimizes technician routes (placeholder)
      # {ServiceWarp.Agents.RouteOptimizationAgent, []},

      # Customer Communication Agent - handles customer notifications (placeholder)
      # {ServiceWarp.Agents.CustomerCommunicationAgent, []},

      # Scheduling Agent - manages job scheduling and optimization (placeholder)
      # {ServiceWarp.Agents.SchedulingAgent, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
