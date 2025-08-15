import Config

# Production configuration for IsLab Database
# Configure with appropriate production data directory

# In production, you might want to use a more persistent location
# config :islab_db,
#   data_root: "/opt/islab_db/data"

# For now, use relative path - adjust for your production environment
config :islab_db,
  data_root: Path.expand("../data", __DIR__)

# Configure logging for production
config :logger,
  level: :warning
