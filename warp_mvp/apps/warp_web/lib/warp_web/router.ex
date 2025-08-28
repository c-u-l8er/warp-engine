defmodule WarpWeb.Router do
  use WarpWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", WarpWeb do
    pipe_through :api

    # Spatial object CRUD operations
    post "/objects", SpatialController, :create
    get "/objects/:id", SpatialController, :show
    put "/objects/:id", SpatialController, :update
    delete "/objects/:id", SpatialController, :delete

    # Spatial search operations
    get "/search/bbox", SpatialController, :bbox_search
    get "/search/nearby", SpatialController, :radius_search

    # System administration
    get "/admin/health", AdminController, :health
    get "/admin/stats", AdminController, :stats
    get "/admin/metrics", AdminController, :metrics
  end

  # Health check endpoint (no authentication required)
  get "/health", WarpWeb.HealthController, :check

  # LiveDashboard for monitoring
  scope "/admin" do
    pipe_through [:fetch_session, :protect_from_forgery]

    live_dashboard "/dashboard", metrics: WarpWeb.Telemetry
  end
end
