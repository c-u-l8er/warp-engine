import Config

# Configure the data root directory to use the local data directory
# instead of the system /data directory
config :islab_db,
  data_root: Path.expand("../data", __DIR__)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
