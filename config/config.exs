import Config

# Configure the data root directory to use the local data directory
# instead of the system /data directory
config :warp_engine,
  data_root: Path.expand("../data", __DIR__)

# Configure Nx to use Candlex for GPU acceleration
config :nx, default_backend: Candlex.Backend

# Enable Candlex CUDA variant (used at compile-time to pick CUDA NIF)
config :candlex, use_cuda: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
