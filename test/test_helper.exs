# Configure test environment BEFORE starting ExUnit and the application
# This ensures the data_root is set before IsLabDB tries to initialize

# Test environment configuration
Application.put_env(:islab_db, :test_mode, true)
Application.put_env(:islab_db, :data_root, "/tmp/islab_db_test_data")

# Ensure clean test environment before starting
test_data_dir = "/tmp/islab_db_test_data"
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

# Manually start the IsLabDB application with proper configuration
# (In test environment, the application doesn't auto-start to allow proper setup)
{:ok, _} = Application.ensure_all_started(:islab_db)

# Wait a moment for the application to fully initialize
Process.sleep(100)

# Verify the cosmic structure was created
if File.exists?(test_data_dir) do
  IO.puts("✅ Test data directory created at #{test_data_dir}")
else
  IO.puts("❌ Test data directory NOT created at #{test_data_dir}")
end

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
