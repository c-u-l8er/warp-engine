defmodule WarpEngine.Application do
  @moduledoc """
  WarpEngine Database Application Supervisor

  Supervises the main WarpEngine Database GenServer and any associated processes
  that make up the computational universe. The application uses a one-for-one
  supervision strategy, ensuring that if the main database process crashes,
  it will be restarted while maintaining system stability.

  ## Supervision Tree

  ```
  WarpEngine.Application (Supervisor)
  └── WarpEngine (GenServer) - Main database universe controller
      ├── Cosmic Persistence Layer
      ├── Spacetime Shard Management
      ├── Quantum Entanglement Engine
      ├── Entropy Monitoring System
      └── Wormhole Network Router
  ```

  ## Startup Process

  1. Initialize cosmic filesystem structure at `/data`
  2. Create ETS tables for spacetime shards (hot/warm/cold data)
  3. Establish quantum entanglement rules and patterns
  4. Start entropy monitoring for automatic load balancing
  5. Initialize wormhole network for fast data routing
  6. Begin periodic cosmic maintenance operations

  ## Error Recovery

  The supervisor ensures that if the main database process fails:
  - The universe is automatically restarted
  - Persistent data in `/data` filesystem is preserved
  - ETS tables are recreated and can be restored from filesystem
  - All cosmic constants and physics laws are reapplied
  - Client connections are gracefully handled

  ## Configuration

  Application configuration can be provided via:
  - `config/config.exs` - Static configuration
  - Environment variables - Runtime configuration
  - Application start options - Dynamic configuration

  Example configuration:

  ```elixir
  config :warp_engine,
    data_root: "/custom/data/path",
    enable_entropy_monitoring: true,
    cosmic_maintenance_interval: 30_000,
    entanglement_rules: [
      {"user:*", ["profile:*", "settings:*"]},
      {"order:*", ["customer:*", "products:*"]}
    ]
  ```
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("🚀 Starting WarpEngine Database Application...")

    # Get configuration from application environment
    config = Application.get_all_env(:warp_engine)

    # Log startup configuration
    log_startup_config(config)

    # Define supervised processes (Phase 9.3: High-Concurrency Optimized Architecture)
    bench_mode = Keyword.get(config, :bench_mode, false)
    disable_batcher = bench_mode or Application.get_env(:warp_engine, :disable_operation_batcher, false)
    disable_ilb = bench_mode or Application.get_env(:warp_engine, :disable_intelligent_load_balancer, false)

    children = [
      # Phase 9.3: Operation Batcher - reduces per-operation overhead at high concurrency
      (if disable_batcher, do: nil, else: {WarpEngine.OperationBatcher, []}),
      # Phase 9.2: Intelligent Load Balancer - optimizes performance at all concurrency levels
      (if disable_ilb, do: nil, else: {WarpEngine.IntelligentLoadBalancer, []}),
      # Phase 9.1: WAL Coordinator with per-shard processes - eliminates concurrency bottleneck
      (if bench_mode, do: nil, else: {WarpEngine.WALCoordinator, config}),
      # Legacy WAL (single process) for compatibility with TemporalShard and tests expecting :warp_engine.WAL
      (if bench_mode, do: nil, else: {WarpEngine.WAL, config}),
      # Main WarpEngine Database GenServer
      {WarpEngine, config}
    ]
    |> Enum.reject(&is_nil/1)

    Logger.info("🔧 Starting supervisor with #{length(children)} children")

    # Supervision options
    opts = [
      strategy: :one_for_one,
      name: WarpEngine.Supervisor,
      max_restarts: 10,
      max_seconds: 60
    ]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("✨ WarpEngine Database Application started successfully")
        Logger.info("🌌 Universe supervisor PID: #{inspect(pid)}")

        # Verify children started correctly
        Process.sleep(100)
        children_status = Supervisor.which_children(pid)
        Logger.info("👥 Supervisor children: #{inspect(children_status)}")

        {:ok, pid}

      {:error, reason} ->
        Logger.error("❌ Failed to start WarpEngine Database Application: #{inspect(reason)}")
        Logger.error("❌ Children that were supposed to start: #{inspect(children)}")
        {:error, reason}
    end
  end

  @impl true
  def stop(_state) do
    Logger.info("🛑 Stopping WarpEngine Database Application...")

    # Perform graceful shutdown operations
    try do
      # Get final metrics before shutdown
      if Process.whereis(WarpEngine) do
        final_metrics = WarpEngine.cosmic_metrics()
        log_shutdown_metrics(final_metrics)
      end
    rescue
      error ->
        Logger.warning("⚠️  Error collecting final metrics: #{inspect(error)}")
    end

    Logger.info("🌌 WarpEngine Database universe has been gracefully shut down")
    :ok
  end

  @doc """
  Get the current application configuration.
  """
  def config do
    Application.get_all_env(:warp_engine)
  end

  @doc """
  Get a specific configuration value with an optional default.
  """
  def config(key, default \\ nil) do
    Application.get_env(:warp_engine, key, default)
  end

  @doc """
  Update application configuration at runtime.

  Note: This only affects the application environment.
  The running WarpEngine GenServer will need to be restarted
  or explicitly reconfigured to pick up the changes.
  """
  def put_config(key, value) do
    Application.put_env(:warp_engine, key, value)
  end

  @doc """
  Get information about the current supervision tree.
  """
  def supervisor_info do
    case Process.whereis(WarpEngine.Supervisor) do
      nil -> {:error, :not_running}
      pid ->
        children = Supervisor.which_children(pid)
        count_by_status = Enum.group_by(children, fn {_id, _pid, _type, status} -> status end)

        %{
          supervisor_pid: pid,
          total_children: length(children),
          running_children: length(Map.get(count_by_status, :running, [])),
          failed_children: length(Map.get(count_by_status, :failed, [])),
          children_details: children
        }
    end
  end

  @doc """
  Restart the main WarpEngine GenServer.

  This will trigger a controlled restart of the database universe
  while preserving all persistent data in the filesystem.
  """
  def restart_universe do
    case Process.whereis(WarpEngine.Supervisor) do
      nil ->
        {:error, :supervisor_not_running}
      supervisor_pid ->
        Logger.info("🔄 Restarting WarpEngine Database universe...")

        # Terminate the current WarpEngine process
        case Supervisor.terminate_child(supervisor_pid, WarpEngine) do
          :ok ->
            # Restart the WarpEngine process
            case Supervisor.restart_child(supervisor_pid, WarpEngine) do
              {:ok, _pid} ->
                Logger.info("✨ WarpEngine Database universe restarted successfully")
                {:ok, :restarted}
              {:error, reason} ->
                Logger.error("❌ Failed to restart universe: #{inspect(reason)}")
                {:error, {:restart_failed, reason}}
            end
          {:error, reason} ->
            Logger.error("❌ Failed to terminate universe for restart: #{inspect(reason)}")
            {:error, {:terminate_failed, reason}}
        end
    end
  end

  @doc """
  Check if the WarpEngine Database is currently running and healthy.
  """
  def health_check do
    case Process.whereis(WarpEngine) do
      nil ->
        %{
          status: :not_running,
          universe_state: :unknown,
          uptime_ms: 0,
          last_check: DateTime.utc_now()
        }

      _pid ->
        try do
          metrics = WarpEngine.cosmic_metrics()
          %{
            status: :running,
            universe_state: metrics.universe_state,
            uptime_ms: metrics.uptime_ms,
            spacetime_shards: length(metrics.spacetime_regions),
            entropy: metrics.entropy.total_entropy,
            last_check: DateTime.utc_now(),
            healthy: metrics.universe_state == :stable and metrics.entropy.total_entropy < 3.0
          }
        rescue
          error ->
            %{
              status: :error,
              universe_state: :unknown,
              uptime_ms: 0,
              error: inspect(error),
              last_check: DateTime.utc_now(),
              healthy: false
            }
        end
    end
  end

  ## PRIVATE FUNCTIONS

  defp log_startup_config(config) do
    Logger.info("⚙️  Application Configuration:")

    # Log key configuration values (but not sensitive data)
    config_to_log = config
    |> Keyword.take([:data_root, :enable_entropy_monitoring, :cosmic_maintenance_interval])
    |> Enum.map(fn {key, value} -> "  #{key}: #{inspect(value)}" end)
    |> Enum.join("\n")

    if config_to_log != "" do
      Logger.info(config_to_log)
    else
      Logger.info("  Using default configuration")
    end

    # Log entanglement rules count if configured
    case Keyword.get(config, :entanglement_rules) do
      nil -> Logger.info("  Entanglement rules: using defaults")
      rules when is_list(rules) -> Logger.info("  Entanglement rules: #{length(rules)} patterns configured")
    end
  end

  defp log_shutdown_metrics(metrics) do
    Logger.info("📊 Final Universe Statistics:")
    Logger.info("  Uptime: #{metrics.uptime_ms}ms")
    Logger.info("  Universe state: #{metrics.universe_state}")
    Logger.info("  Total operations: #{metrics.performance.total_operations}")

    # Log shard statistics
    total_items = metrics.spacetime_regions
    |> Enum.map(& &1.data_items)
    |> Enum.sum()

    Logger.info("  Total data items: #{total_items}")

    # Log entropy
    if is_number(metrics.entropy.total_entropy) do
      Logger.info("  Final entropy: #{Float.round(metrics.entropy.total_entropy, 3)}")
    end

    # Log persistence statistics
    if metrics.persistence.exists do
      Logger.info("  Data persisted to: #{metrics.persistence.data_root}")
      Logger.info("  Persistent data size: ~#{Float.round(metrics.persistence.estimated_size_mb, 1)}MB")
    end
  end
end
