import Config

# Production configuration for WarpEngine Database
# Configure with appropriate production data directory

# In production, you might want to use a more persistent location
# config :warp_engine,
#   data_root: "/opt/warp_engine/data"

# For now, use relative path - adjust for your production environment
config :warp_engine,
  data_root: Path.expand("../data", __DIR__)

# Dynamic shard topology sized to the machine
config :warp_engine,
  use_numbered_shards: true,
  num_numbered_shards: System.schedulers_online(),
  enable_auto_entanglement: true,
  bench_mode: false

# Nx configuration - enable GPU acceleration using Candlex for production
config :nx,
  default_backend: {Candlex.Backend, device: :cuda}

# Configure logging for production
config :logger,
  level: :warning
