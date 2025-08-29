# Configure your database
config :service_warp, ServiceWarp.Repo,
  username: "travis",
  password: "furlong",
  hostname: "localhost",
  database: "service_warp_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your end user. For example, we can use an
# inotify-tools to monitor the file system and asynchronously
# pick up changes (without restarting Phoenix in development).
config :service_warp, ServiceWarpWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--watch)]},
    tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}
  ],
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/service_warp_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ],
  secret_key_base: "r+hS1V66qnO9UB9TFUEkfi2xgtX2WztC7XL3TgJuENMPzVMMbEguaIby84tV8tpJ",
  pubsub_server: ServiceWarp.PubSub,
  live_view: [signing_salt: "GGAKW9L0l3mqeQAJ"]
