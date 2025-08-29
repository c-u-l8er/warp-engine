import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

# Configure ServiceWarp database
config :service_warp, ServiceWarp.Repo,
  username: "travis",
  password: "furlong",
  hostname: "localhost",
  database: "service_warp_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :service_warp, ServiceWarpWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "r+hS1V66qnO9UB9TFUEkfi2xgtX2WztC7XL3TgJuENMPzVMMbEguaIby84tV8tpJ",
  pubsub_server: ServiceWarp.PubSub,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :service_warp, ServiceWarpWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"../priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"../priv/gettext/.*(po)$",
      ~r"../lib/service_warp_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :service_warp, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Enable the LiveDashboard
config :service_warp, ServiceWarpWeb.Endpoint,
  live_view: [
    signing_salt: "GGAKW9L0l3mqeQAJ"
  ]
