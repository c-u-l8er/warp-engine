# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# WarpEngine configuration
config :warp_engine,
  # Shard configuration
  shard_count: System.get_env("WARP_SHARD_COUNT") |>
    (fn count -> if count, do: String.to_integer(count), else: System.schedulers_online() * 2 end).(),

  # Performance settings
  read_concurrency: true,
  write_concurrency: true,

  # Physics optimizations (disabled in MVP)
  physics: [
    enable_gravitational_routing: false,
    enable_quantum_entanglement: false,
    enable_entropy_monitoring: false
  ]

# WarpWeb configuration
config :warp_web, WarpWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit,
  http: [port: String.to_integer(System.get_env("PORT") || "4000")],
  check_origin: false

# Logger configuration
config :logger, :console,
  level: :info,
  format: "$date $time [$level] $metadata$message\n",
  metadata: [:request_id, :shard_id]
