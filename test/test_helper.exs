# Configure test environment BEFORE starting ExUnit and the application
# This ensures the data_root is set before WarpEngine tries to initialize

# --- Candlex/Nx CUDA setup for test runtime ---
try do
  System.put_env("CANDLEX_NIF_TARGET", System.get_env("CANDLEX_NIF_TARGET") || "cuda")
  # Prefer visible GPU 0 in CI/WSL
  System.put_env("CUDA_VISIBLE_DEVICES", System.get_env("CUDA_VISIBLE_DEVICES") || "0")

  # Ensure Nx uses Candlex CUDA by default in tests
  Application.put_env(:nx, :default_backend, {Candlex.Backend, device: :cuda})
rescue
  _ -> :ok
end
# ---------------------------------------------

# Test environment configuration
Application.put_env(:warp_engine, :test_mode, true)
Application.put_env(:warp_engine, :data_root, "/tmp/warp_engine_test_data")
# Ensure tests run in normal mode (not bench mode)
Application.put_env(:warp_engine, :bench_mode, false)
Application.put_env(:warp_engine, :force_ultra_fast_path, false)
# Enable GPU in tests to avoid Candlex warnings
Application.put_env(:warp_engine, :enable_gpu, true)

# Ensure clean test environment before starting
test_data_dir = "/tmp/warp_engine_test_data"
if File.exists?(test_data_dir) do
  try do
    File.rm_rf!(test_data_dir)
  rescue
    File.Error ->
      # Ignore cleanup errors - directory will be recreated anyway
      :ok
  end
end

# Start ExUnit for testing
ExUnit.start()

# Let the test framework handle application startup
# The application will be started automatically when tests run
# Configuration is already set above, so it will use the correct settings

IO.puts("🧪 Test environment configured with data_root: #{test_data_dir}")

# Add setup callback for individual tests
ExUnit.after_suite(fn _results ->
  # Final cleanup after all tests complete
  IO.puts("🧹 Cleaning up test data directory...")
  if File.exists?(test_data_dir) do
    try do
      File.rm_rf!(test_data_dir)
      IO.puts("✅ Test cleanup completed")
    rescue
      File.Error ->
        IO.puts("⚠️ Test cleanup had issues, but continuing...")
        :ok
    end
  end
end)

# Configure ExUnit for better test output
ExUnit.configure(
  exclude: [
    :integration,  # Exclude integration tests by default
    :performance,  # Exclude performance tests by default
    :physics       # Exclude physics simulation tests by default
  ],
  formatters: [ExUnit.CLIFormatter],
  max_failures: :infinity,
  timeout: 60_000,  # 60 second timeout for long-running physics tests
  capture_log: true
)
