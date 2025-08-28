import Config

# Test configuration for WarpEngine Database
# Uses temporary test data directory

config :warp_engine,
  # Use a test-specific data directory (matches test_helper.exs)
  data_root: "/tmp/warp_engine_test_data",
  # Keep legacy 3-shard layout for tests to match existing test expectations
  use_numbered_shards: false,
  num_numbered_shards: 3,
  # Ensure deterministic entanglement for tests that expect it
  enable_auto_entanglement: true,
  bench_mode: false,
  enable_gpu: true

# Ensure Nx uses Candlex CUDA in tests when available
config :nx,
  default_backend: {Candlex.Backend, device: :cuda}

# Configure logging for testing
config :logger,
  level: :warning
