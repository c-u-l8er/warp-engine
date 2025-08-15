import Config

# Test configuration for IsLab Database
# Uses temporary test data directory

config :islab_db,
  # Use a test-specific data directory
  data_root: Path.expand("../test_data", __DIR__)

# Configure logging for testing
config :logger,
  level: :warning
