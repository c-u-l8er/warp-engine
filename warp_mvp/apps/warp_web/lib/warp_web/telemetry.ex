defmodule WarpWeb.Telemetry do
  @moduledoc """
  Handles telemetry for WarpWeb.
  """
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {TelemetryMetricsPrometheus, [
        metrics: metrics()
      ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics do
    [
      # Phoenix Metrics
      counter("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      counter("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.error.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.start.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.exception.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.error.duration",
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("warp_engine.repo.query.total_time",
        unit: {:native, :millisecond}
      ),
      summary("warp_engine.repo.query.decode_time",
        unit: {:native, :millisecond}
      ),
      summary("warp_engine.repo.query.query_time",
        unit: {:native, :millisecond}
      ),
      summary("warp_engine.repo.query.queue_time",
        unit: {:native, :millisecond}
      ),
      summary("warp_engine.repo.query.idle_time",
        unit: {:native, :millisecond}
      ),

      # Custom WarpEngine Metrics
      counter("warp_engine.spatial_operations.total",
        description: "Total number of spatial operations"
      ),
      summary("warp_engine.spatial_operations.duration",
        unit: {:native, :microsecond},
        description: "Duration of spatial operations"
      ),
      counter("warp_engine.shard_operations.total",
        description: "Total number of shard operations"
      ),
      summary("warp_engine.shard_operations.duration",
        unit: {:native, :microsecond},
        description: "Duration of shard operations"
      )
    ]
  end
end
