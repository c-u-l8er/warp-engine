import Config

# Configure your database
config :warp_engine, WarpEngine.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "warp_engine_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :warp_web, WarpWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_for_testing_only_do_not_use_in_production",
  server: false

# In test we don't send emails.
config :warp_web, WarpWeb.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Disable physics optimizations in test for faster execution
config :warp_engine, :physics,
  enable_gravitational_routing: false,
  enable_quantum_entanglement: false,
  enable_entropy_monitoring: false

# Use fewer shards in test for faster startup
config :warp_engine, :shard_count, 2
