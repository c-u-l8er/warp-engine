import Config

# Development configuration for WarpEngine Database
# Uses local data directory for persistence

config :warp_engine,
  # Use the local data directory for development
  data_root: Path.expand("../data", __DIR__),
  # Enable high-performance topology sized to cores in development
  use_numbered_shards: true,
  num_numbered_shards: max(System.schedulers_online(), 24),  # Ensure at least 24 shards
  # Disable auto entanglement during development perf benches
  enable_auto_entanglement: false,
  # Enable bench mode to skip non-essential work when benchmarking
  bench_mode: true,
  # Force ultra-fast path for maximum performance
  force_ultra_fast_path: true,
  # Debug shard routing for troubleshooting (set to true if needed)
  debug_shard_routing: false

# Enable more verbose logging in development
config :logger,
  level: :info
