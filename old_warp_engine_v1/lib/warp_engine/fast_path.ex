defmodule WarpEngine.FastPath do
  @moduledoc """
  FastPath module for simple operations that bypass physics calculations.

  This module provides ultra-fast processing for operations that don't require
  complex physics calculations, achieving maximum performance by avoiding
  the GPU routing overhead.

  Target: 500K+ ops/sec for simple operations
  """

  require Logger
  alias WarpEngine.WALOperations

  @doc """
  Process simple operation using fast path (no physics).
  Bypasses all physics calculations for maximum performance.
  """
  def process(operation) do
    Logger.debug("⚡ FastPath processing: #{inspect(operation.key)}")

    # Extract basic operation data
    key = operation.key
    value = operation.value
    opts = Map.get(operation, :opts, [])

    # Try WAL operations first, fallback to simple ETS if WAL unavailable
    case try_wal_operation(key, value, opts) do
      {:ok, :stored, shard, time} ->
        {:ok, :stored, shard, time}

      {:error, reason} ->
        Logger.debug("⚠️  WAL operation failed, using ETS fallback: #{reason}")
        # Fallback to simple ETS operation
        fallback_ets_operation(key, value, opts)
    end
  end

  # Try WAL operation, return error if WAL unavailable
  defp try_wal_operation(key, value, opts) do
    try do
      case WALOperations.cosmic_put_v2(get_warp_engine_state(), key, value, opts) do
        {:ok, :stored, shard, time, _state} -> {:ok, :stored, shard, time}
        {:error, reason, _state} -> {:error, reason}
        other -> other
      end
    rescue
      _ -> {:error, :wal_unavailable}
    catch
      :exit, _ -> {:error, :wal_unavailable}
      :error, _ -> {:error, :wal_unavailable}
    end
  end

  # Simple ETS fallback operation
  defp fallback_ets_operation(key, value, _opts) do
    timestamp = :erlang.system_time(:microsecond)
    table = resolve_ets_table()

    ensure_table_exists(table)
    :ets.insert(table, {key, value, %{timestamp: timestamp}})

    {:ok, :stored, table, timestamp}
  end

  @doc """
  Process simple get operation using fast path.
  """
  def get(key, opts \\ []) do
    Logger.debug("⚡ FastPath GET: #{inspect(key)}")

    # Try WAL operations first, fallback to simple ETS if WAL unavailable
    case try_wal_get(key) do
      {:ok, value, shard, time} ->
        %{
          status: :found,
          key: key,
          value: value,
          shard: shard,
          timestamp: time,
          processing_path: :fast_path,
          physics_calculated: false
        }

      {:error, reason} ->
        Logger.debug("⚠️  WAL GET failed, using ETS fallback: #{reason}")
        # Fallback to simple ETS operation
        fallback_ets_get(key)
    end
  end

  # Try WAL GET operation, return error if WAL unavailable
  defp try_wal_get(key) do
    try do
      WALOperations.cosmic_get_v2(get_warp_engine_state(), key)
    rescue
      _ -> {:error, :wal_unavailable}
    catch
      :exit, _ -> {:error, :wal_unavailable}
      :error, _ -> {:error, :wal_unavailable}
    end
  end

  # Simple ETS fallback GET operation
  defp fallback_ets_get(key) do
    table = resolve_ets_table()
    timestamp = :erlang.system_time(:microsecond)

    ensure_table_exists(table)
    case :ets.lookup(table, key) do
      [{^key, value, metadata}] -> {:ok, value, table, metadata[:timestamp] || timestamp}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Process simple delete operation using fast path.
  """
  def delete(key, opts \\ []) do
    Logger.debug("⚡ FastPath DELETE: #{inspect(key)}")

    # Try WAL operations first, fallback to simple ETS if WAL unavailable
    case try_wal_delete(key) do
      {:ok, deleted_from, time} ->
        %{
          status: :deleted,
          key: key,
          deleted_from: deleted_from,
          timestamp: time,
          processing_path: :fast_path,
          physics_calculated: false
        }

      {:error, reason} ->
        Logger.debug("⚠️  WAL DELETE failed, using ETS fallback: #{reason}")
        # Fallback to simple ETS operation
        fallback_ets_delete(key)
    end
  end

  # Try WAL DELETE operation, return error if WAL unavailable
  defp try_wal_delete(key) do
    try do
      WALOperations.cosmic_delete_v2(get_warp_engine_state(), key)
    rescue
      _ -> {:error, :wal_unavailable}
    catch
      :exit, _ -> {:error, :wal_unavailable}
      :error, _ -> {:error, :wal_unavailable}
    end
  end

  # Simple ETS fallback DELETE operation
  defp fallback_ets_delete(key) do
    table = resolve_ets_table()
    timestamp = :erlang.system_time(:microsecond)

    ensure_table_exists(table)
    case :ets.lookup(table, key) do
      [{^key, _value, metadata}] ->
        :ets.delete(table, key)
        {:ok, table, metadata[:timestamp] || timestamp}
      [] -> {:error, :not_found}
    end
  end

  # Determine an available ETS table to use for fast path operations.
  # Prefer legacy :hot_data table when present, otherwise the first available table,
  # otherwise create a named fallback table.
  defp resolve_ets_table() do
    case get_warp_engine_state() do
      %{spacetime_tables: tables} when is_map(tables) and map_size(tables) > 0 ->
        cond do
          Map.has_key?(tables, :hot_data) -> Map.get(tables, :hot_data)
          true -> tables |> Map.values() |> List.first()
        end
      _ -> :fast_path_fallback
    end
  end

  defp ensure_table_exists(table) do
    try do
      case :ets.info(table) do
        :undefined ->
          :ets.new(table, [:set, :public, :named_table, {:read_concurrency, true}, {:write_concurrency, true}])
        _ -> :ok
      end
    rescue
      _ -> :ok
    end
  end

  @doc """
  Batch process multiple simple operations for maximum throughput.
  """
  def batch_process(operations) when is_list(operations) do
    Logger.debug("⚡ FastPath batch processing: #{length(operations)} operations")

    start_time = :erlang.system_time(:microsecond)

    results = Enum.map(operations, fn operation ->
      process(operation)
    end)

    end_time = :erlang.system_time(:microsecond)
    duration = end_time - start_time

    # Calculate throughput
    throughput = if duration > 0 do
      length(operations) / (duration / 1_000_000)
    else
      0
    end

    Logger.info("✅ FastPath batch completed:")
    Logger.info("   Operations: #{length(operations)}")
    Logger.info("   Duration: #{duration} μs")
    Logger.info("   Throughput: #{Float.round(throughput, 1)} ops/sec")

    %{
      results: results,
      batch_size: length(operations),
      duration_microseconds: duration,
      throughput_ops_per_sec: throughput,
      processing_path: :fast_path
    }
  end

  @doc """
  Check if operation qualifies for fast path processing.
  """
  def qualifies_for_fast_path?(operation) do
    # Simple operations that don't need physics
    not has_physics_requirements?(operation) and
    not has_complex_data_requirements?(operation) and
    not has_temporal_requirements?(operation)
  end

  @doc """
  Get fast path performance metrics.
  """
  def get_performance_metrics() do
    %{
      processing_path: :fast_path,
      target_throughput: "500K+ ops/sec",
      physics_calculations: false,
      gpu_acceleration: false,
      memory_overhead: "minimal",
      latency_target: "<10μs"
    }
  end

  # Private helper functions

  defp get_warp_engine_state() do
    # Get current WarpEngine state for WAL operations
    case Process.whereis(WarpEngine) do
      nil ->
        Logger.warning("⚠️  WarpEngine not running, using default state")
        %{
          spacetime_shards: %{
            :hot_data => %{ets_table: :spacetime_shard_hot_data},
            :warm_data => %{ets_table: :spacetime_shard_warm_data},
            :cold_data => %{ets_table: :spacetime_shard_cold_data}
          },
          wal_system: nil,
          wal_enabled: false
        }

      _pid ->
        # Get actual state from WarpEngine
        :sys.get_state(WarpEngine)
    end
  end

  defp has_physics_requirements?(operation) do
    # Check if operation requires physics calculations
    get_in(operation, [:physics]) != nil or
    get_in(operation, [:gravitational_routing]) != nil or
    get_in(operation, [:quantum_entanglement]) != nil or
    get_in(operation, [:entropy_monitoring]) != nil
  end

  defp has_complex_data_requirements?(operation) do
    # Check if operation has complex data requirements
    data_size = get_in(operation, [:data_size])
    is_integer(data_size) and data_size > 1000
  end

  defp has_temporal_requirements?(operation) do
    # Check if operation has temporal dependencies
    get_in(operation, [:temporal_weight]) != nil or
    get_in(operation, [:lifecycle]) != nil or
    get_in(operation, [:timestamp]) != nil
  end
end
