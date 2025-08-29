defmodule ServiceWarpWeb.Telemetry do
  @moduledoc """
  Telemetry for ServiceWarp.
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    port =
      case System.get_env("PROMETHEUS_PORT") do
        nil -> 9568
        val ->
          case Integer.parse(val) do
            {num, _} -> num
            :error -> 9568
          end
      end

    children = [
      {TelemetryMetricsPrometheus, [
        metrics: metrics(),
        port: port,
        plug_cowboy_opts: [ref: :prometheus_metrics, transport_options: [num_acceptors: 5]]
      ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics do
    [
      # Phoenix Metrics
      counter("phoenix.endpoint.start.system"),
      counter("phoenix.endpoint.stop.duration"),
      summary("phoenix.router_dispatch.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.error.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_joined.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_handled_in.duration",
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("service_warp.repo.query.total_time",
        unit: {:native, :millisecond}
      ),
      summary("service_warp.repo.query.decode_time",
        unit: {:native, :millisecond}
      ),
      summary("service_warp.repo.query.query_time",
        unit: {:native, :millisecond}
      ),
      summary("service_warp.repo.query.queue_time",
        unit: {:native, :millisecond}
      ),
      summary("service_warp.repo.query.idle_time",
        unit: {:native, :millisecond}
      ),

      # Custom ServiceWarp Metrics
      counter("service_warp.jobs.created"),
      counter("service_warp.jobs.assigned"),
      counter("service_warp.jobs.completed"),
      counter("service_warp.technicians.added"),
      counter("service_warp.technicians.location_updated"),
      summary("service_warp.job_assignment.duration",
        unit: {:native, :millisecond}
      ),
      summary("service_warp.spatial_query.duration",
        unit: {:native, :millisecond}
      )
    ]
  end
end
