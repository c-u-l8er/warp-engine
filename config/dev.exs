import Config

# Development configuration for IsLab Database
# Uses local data directory for persistence

config :islab_db,
  # Use the local data directory for development
  data_root: Path.expand("../data", __DIR__)

# Enable more verbose logging in development
config :logger,
  level: :info
