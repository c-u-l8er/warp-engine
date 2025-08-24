import Config

# Development configuration for WarpEngine Database
# Uses local data directory for persistence

config :warp_engine,
  # Use the local data directory for development
  data_root: Path.expand("../data", __DIR__)

# Enable more verbose logging in development
config :logger,
  level: :info
