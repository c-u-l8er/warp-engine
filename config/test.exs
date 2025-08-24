import Config

# Test configuration for WarpEngine Database
# Uses temporary test data directory

config :warp_engine,
  # Use a test-specific data directory (matches test_helper.exs)
  data_root: "/tmp/warp_engine_test_data"

# Configure logging for testing
config :logger,
  level: :warning
