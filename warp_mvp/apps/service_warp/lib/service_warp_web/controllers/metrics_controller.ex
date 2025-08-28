defmodule ServiceWarpWeb.MetricsController do
  use ServiceWarpWeb, :controller

  def index(conn, _params) do
    # Get system metrics
    metrics = ServiceWarp.GlobalState.get_metrics()

    json(conn, %{
      system_metrics: metrics,
      timestamp: DateTime.utc_now()
    })
  end
end
