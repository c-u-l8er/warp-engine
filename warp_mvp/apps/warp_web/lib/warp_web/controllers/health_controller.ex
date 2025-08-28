defmodule WarpWeb.HealthController do
  use WarpWeb, :controller

  @doc """
  Basic health check endpoint.
  """
  def check(conn, _params) do
    conn
    |> json(%{
      status: "ok",
      timestamp: DateTime.utc_now(),
      service: "WarpEngine Web"
    })
  end
end
