defmodule WarpWeb.AdminController do
  use WarpWeb, :controller

  alias WarpEngine

  @doc """
  Gets system health status.
  """
  def health(conn, _params) do
    case WarpEngine.health_check() do
      {:ok, health_data} ->
        conn
        |> json(%{
          status: "healthy",
          timestamp: DateTime.utc_now(),
          data: health_data
        })

      {:error, error_data} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{
          status: "unhealthy",
          timestamp: DateTime.utc_now(),
          error: error_data
        })
    end
  end

  @doc """
  Gets system statistics.
  """
  def stats(conn, _params) do
    stats = WarpEngine.get_stats()

    conn
    |> json(%{
      timestamp: DateTime.utc_now(),
      stats: stats
    })
  end

  @doc """
  Gets system metrics in Prometheus format.
  """
  def metrics(conn, _params) do
    metrics = WarpEngine.Telemetry.MetricsCollector.get_prometheus_metrics()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end
end
