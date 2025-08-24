import Config

# Production configuration for WarpEngine Database
# Configure with appropriate production data directory

# In production, you might want to use a more persistent location
# config :warp_engine,
#   data_root: "/opt/warp_engine/data"

# For now, use relative path - adjust for your production environment
config :warp_engine,
  data_root: Path.expand("../data", __DIR__)

# Configure logging for production
config :logger,
  level: :warning
