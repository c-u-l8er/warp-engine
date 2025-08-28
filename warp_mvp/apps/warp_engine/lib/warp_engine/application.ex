defmodule WarpEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting WarpEngine application...")

    children = [
      # Registry for process naming
      {Registry, keys: :unique, name: WarpEngine.Registry},

      # In-memory shard/index acceleration layer
      {WarpEngine.Storage.ShardManager, [
        shard_count: Application.get_env(:warp_engine, :shard_count, System.schedulers_online() * 2),
        read_concurrency: true,
        write_concurrency: true
      ]},

      # Telemetry and metrics (placeholder for now)
      {WarpEngine.Telemetry.MetricsCollector, []}
    ]

    opts = [strategy: :one_for_one, name: WarpEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
