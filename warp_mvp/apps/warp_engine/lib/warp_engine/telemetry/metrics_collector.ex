defmodule WarpEngine.Telemetry.MetricsCollector do
  @moduledoc """
  Collects and exports telemetry metrics for WarpEngine.

  Provides performance monitoring and observability for spatial operations,
  shard performance, and system health.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Attach telemetry event handlers
    :telemetry.attach_many(
      "warp-engine-metrics",
      [
        [:warp_engine, :spatial_operation, :start],
        [:warp_engine, :spatial_operation, :stop],
        [:warp_engine, :spatial_operation, :exception],
        [:warp_engine, :shard_operation, :start],
        [:warp_engine, :shard_operation, :stop],
        [:warp_engine, :shard_operation, :exception]
      ],
      &handle_telemetry_event/4,
      nil
    )

    Logger.info("WarpEngine metrics collector started")
    {:ok, %{metrics: %{}, start_time: DateTime.utc_now()}}
  end

  @impl true
  def handle_info({:record_metric, name, value, metadata}, state) do
    new_metrics = Map.update(state.metrics, name, [%{value: value, metadata: metadata, timestamp: DateTime.utc_now()}], fn existing ->
      [%{value: value, metadata: metadata, timestamp: DateTime.utc_now()} | existing]
    end)

    {:noreply, %{state | metrics: new_metrics}}
  end

  # Telemetry event handler
  defp handle_telemetry_event([:warp_engine, :spatial_operation, :start], measurements, metadata, _config) do
    Logger.debug("Spatial operation started", %{
      operation: metadata.operation,
      object_id: metadata.object_id,
      timestamp: measurements.system_time
    })
  end

  defp handle_telemetry_event([:warp_engine, :spatial_operation, :stop], measurements, metadata, _config) do
    duration = measurements.duration

    Logger.debug("Spatial operation completed", %{
      operation: metadata.operation,
      object_id: metadata.object_id,
      duration_us: duration,
      timestamp: measurements.system_time
    })

    # Record performance metrics
    GenServer.cast(__MODULE__, {:record_metric, "spatial_operation_duration", duration, metadata})
  end

  defp handle_telemetry_event([:warp_engine, :spatial_operation, :exception], measurements, metadata, _config) do
    Logger.warning("Spatial operation failed", %{
      operation: metadata.operation,
      object_id: metadata.object_id,
      error: metadata.error,
      timestamp: measurements.system_time
    })

    # Record error metrics
    GenServer.cast(__MODULE__, {:record_metric, "spatial_operation_errors", 1, metadata})
  end

  defp handle_telemetry_event([:warp_engine, :shard_operation, :start], measurements, metadata, _config) do
    Logger.debug("Shard operation started", %{
      operation: metadata.operation,
      shard_id: metadata.shard_id,
      timestamp: measurements.system_time
    })
  end

  defp handle_telemetry_event([:warp_engine, :shard_operation, :stop], measurements, metadata, _config) do
    duration = measurements.duration

    Logger.debug("Shard operation completed", %{
      operation: metadata.operation,
      shard_id: metadata.shard_id,
      duration_us: duration,
      timestamp: measurements.system_time
    })

    # Record performance metrics
    GenServer.cast(__MODULE__, {:record_metric, "shard_operation_duration", duration, metadata})
  end

  defp handle_telemetry_event([:warp_engine, :shard_operation, :exception], measurements, metadata, _config) do
    Logger.warning("Shard operation failed", %{
      operation: metadata.operation,
      shard_id: metadata.shard_id,
      error: metadata.error,
      timestamp: measurements.system_time
    })

    # Record error metrics
    GenServer.cast(__MODULE__, {:record_metric, "shard_operation_errors", 1, metadata})
  end

  # Client API for recording custom metrics

  @doc """
  Records a custom metric.
  """
  @spec record_metric(String.t(), number(), map()) :: :ok
  def record_metric(name, value, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:record_metric, name, value, metadata})
  end

  @doc """
  Gets current metrics.
  """
  @spec get_metrics() :: map()
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @doc """
  Gets metrics in Prometheus format.
  """
  @spec get_prometheus_metrics() :: String.t()
  def get_prometheus_metrics do
    metrics = get_metrics()

    # Convert to Prometheus format
    Enum.map_join(metrics, "\n", fn {name, values} ->
      case values do
        [] -> ""
        [latest | _] ->
          metadata_str = Enum.map_join(latest.metadata, ",", fn {k, v} -> "#{k}=\"#{v}\"" end)
          "#{name}{#{metadata_str}} #{latest.value}"
      end
    end)
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, state.metrics, state}
  end
end
