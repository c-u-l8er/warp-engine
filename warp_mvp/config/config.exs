# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.0",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/service_warp/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind
config :tailwind,
  version: "3.4.6",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/service_warp/assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

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
