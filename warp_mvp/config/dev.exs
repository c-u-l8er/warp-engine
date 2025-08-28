import Config

# Configure your database
config :warp_engine, WarpEngine.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "warp_engine_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and external
# dependencies, making the API and database faster.
config :warp_engine, :cache_enabled, false

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Enable dev tools for Phoenix
config :warp_web, :dev_routes, true

# Disable physics optimizations in development for faster startup
config :warp_engine, :physics,
  enable_gravitational_routing: false,
  enable_quantum_entanglement: false,
  enable_entropy_monitoring: false
