defmodule ServiceWarpWeb.HealthController do
  use ServiceWarpWeb, :controller

  def index(conn, _params) do
    # Basic health check
    health_status = %{
      status: "healthy",
      timestamp: DateTime.utc_now(),
      services: %{
        service_warp: "running",
        warp_engine: "running",
        global_state: "running"
      }
    }

    json(conn, health_status)
  end
end
