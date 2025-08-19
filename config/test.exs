import Config

# Test configuration for IsLab Database
# Uses temporary test data directory

config :islab_db,
  # Use a test-specific data directory (matches test_helper.exs)
  data_root: "/tmp/islab_db_test_data"

# Configure logging for testing
config :logger,
  level: :warning
