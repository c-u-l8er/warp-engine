defmodule ServiceWarpWeb.Router do
  use ServiceWarpWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ServiceWarpWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Dispatcher Dashboard (Main Interface)
  scope "/", ServiceWarpWeb do
    pipe_through :browser

    # Main dashboard
    live "/", DashboardLive, :index

    # Job management
    live "/jobs", JobsLive, :index
    live "/jobs/new", JobsLive, :new
    live "/jobs/:id", JobsLive, :show
    live "/jobs/:id/edit", JobsLive, :edit

    # Technician management
    live "/technicians", TechniciansLive, :index
    live "/technicians/new", TechniciansLive, :new
    live "/technicians/:id", TechniciansLive, :show
    live "/technicians/:id/edit", TechniciansLive, :edit

    # Company settings
    live "/company", CompanyLive, :index
    live "/company/settings", CompanyLive, :settings

    # Analytics and reports
    live "/analytics", AnalyticsLive, :index
    live "/reports", ReportsLive, :index
  end

  # Technician Mobile Interface
  scope "/tech", ServiceWarpWeb do
    pipe_through :browser

    # Technician dashboard
    live "/", TechDashboardLive, :index

    # Job management for technicians
    live "/jobs", TechJobsLive, :index
    live "/jobs/:id", TechJobsLive, :show

    # Profile and settings
    live "/profile", TechProfileLive, :index
    live "/settings", TechSettingsLive, :index
  end

  # Customer Portal
  scope "/customer", ServiceWarpWeb do
    pipe_through :browser

    # Customer dashboard
    live "/", CustomerDashboardLive, :index

    # Service requests
    live "/requests", CustomerRequestsLive, :index
    live "/requests/new", CustomerRequestsLive, :new
    live "/requests/:id", CustomerRequestsLive, :show

    # Tracking
    live "/tracking", CustomerTrackingLive, :index
  end

  # API Endpoints
  scope "/api/v1", ServiceWarpWeb do
    pipe_through :api

    # Jobs API
    get "/jobs", JobController, :index
    post "/jobs", JobController, :create
    get "/jobs/:id", JobController, :show
    put "/jobs/:id", JobController, :update
    delete "/jobs/:id", JobController, :delete

    # Technicians API
    get "/technicians", TechnicianController, :index
    post "/technicians", TechnicianController, :create
    get "/technicians/:id", TechnicianController, :show
    put "/technicians/:id", TechnicianController, :update
    delete "/technicians/:id", TechnicianController, :delete

    # Location updates
    post "/technicians/:id/location", TechnicianController, :update_location

    # Spatial queries
    get "/search/nearby", SpatialController, :nearby_search
    get "/search/bbox", SpatialController, :bbox_search

    # System metrics
    get "/metrics", MetricsController, :index
    get "/health", HealthController, :index
  end

  # LiveDashboard (Admin/Dev)
  scope "/dev" do
    pipe_through :browser

    import Phoenix.LiveDashboard.Router
    live_dashboard "/dashboard", metrics: ServiceWarpWeb.Telemetry
  end
end
