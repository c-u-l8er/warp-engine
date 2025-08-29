defmodule ServiceWarp.Application do
  @moduledoc """
  The ServiceWarp Application.

  This is the main application module that supervises all the core processes
  including the web interface, AI agents, and spatial intelligence systems.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ServiceWarpWeb.Telemetry,

      # Start the PubSub system
      {Phoenix.PubSub, name: ServiceWarp.PubSub},

      # Start the Endpoint (web interface)
      ServiceWarpWeb.Endpoint,

      # Start the AI Agent Supervisor
      ServiceWarp.Agents.Supervisor,

      # Start the Job Management Supervisor
      ServiceWarp.Jobs.Supervisor,

      # Start the Technician Management Supervisor
      ServiceWarp.Technicians.Supervisor,

      # Start the Global State Manager
      ServiceWarp.GlobalState,

      # Start the Repo
      ServiceWarp.Repo
    ]

    opts = [strategy: :one_for_one, name: ServiceWarp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ServiceWarpWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
