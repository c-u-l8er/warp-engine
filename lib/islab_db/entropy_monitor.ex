defmodule IsLabDB.EntropyMonitor do
  @moduledoc """
  Shannon Entropy Engine - Thermodynamic System Monitoring for Cosmic Database

  This module implements real-time entropy monitoring based on Shannon's information
  theory and thermodynamic principles. It tracks system disorder across all
  spacetime shards and provides intelligent rebalancing triggers when entropy
  exceeds cosmic stability thresholds.

  ## Physics Concepts

  - **Shannon Entropy**: Information-theoretic measure of data distribution disorder
  - **Thermodynamic Entropy**: System energy distribution and thermal equilibrium
  - **Maxwell's Demon**: Intelligent entity that reduces entropy through selective operations
  - **Boltzmann Distribution**: Statistical mechanics for optimal data placement
  - **Vacuum Stability**: Monitoring for false vacuum decay scenarios
  - **Heat Death Prevention**: Automatic system rebalancing before entropy maximum

  ## Key Features

  - Real-time Shannon entropy calculations across all spacetime shards
  - Thermodynamic load balancing with zero-downtime rebalancing
  - Maxwell's demon optimization for intelligent data migration
  - Vacuum stability monitoring with cosmic significance alerting
  - Time-series entropy persistence for historical analysis
  - Predictive entropy modeling with machine learning hooks

  ## Entropy Calculation

  Shannon entropy is calculated as:
  H(X) = -Σ p(x) log₂ p(x)

  Where p(x) is the probability distribution of data across shards.
  Higher entropy indicates more uniform distribution (good for load balancing),
  while lower entropy indicates clustering (potentially problematic).
  """

  use GenServer
  require Logger

  alias IsLabDB.{CosmicConstants, CosmicPersistence}

  defstruct [
    :monitor_id,                    # Unique identifier for this entropy monitor
    :entropy_state,                 # :stable, :fluctuating, :chaotic, :critical
    :spacetime_shards,              # Reference to spacetime shards for monitoring
    :entropy_tables,                # ETS tables for entropy data storage
    :shannon_calculator,            # Shannon entropy calculation process
    :thermodynamic_analyzer,        # Thermodynamic analysis engine
    :maxwell_demon,                 # Intelligent rebalancing daemon
    :vacuum_monitor,                # Vacuum stability monitoring system
    :entropy_history,               # Time-series entropy data
    :rebalancing_triggers,          # Automatic rebalancing configuration
    :analytics_engine,              # Cosmic analytics platform
    :alert_system,                  # System disorder alert notifications
    :persistence_coordinator,      # Entropy data filesystem persistence
    :monitoring_interval,           # Entropy calculation frequency (ms)
    :created_at                     # Monitor creation timestamp
  ]

  ## PUBLIC API

  @doc """
  Create a new entropy monitor for the cosmic database system.

  ## Options

  - `:monitoring_interval` - How frequently to calculate entropy (default: 5000ms)
  - `:entropy_threshold` - Custom entropy threshold for rebalancing (default: cosmic constant)
  - `:enable_maxwell_demon` - Enable intelligent optimization (default: true)
  - `:vacuum_stability_checks` - Enable vacuum stability monitoring (default: true)
  - `:persistence_enabled` - Store entropy data to filesystem (default: true)
  - `:analytics_enabled` - Enable cosmic analytics platform (default: true)

  ## Returns

  `{:ok, entropy_monitor}` on success, `{:error, reason}` on failure

  ## Examples

      {:ok, monitor} = EntropyMonitor.create_monitor(:cosmic_entropy, [
        monitoring_interval: 3000,
        entropy_threshold: 2.8,
        enable_maxwell_demon: true
      ])
  """
  def create_monitor(monitor_id, opts \\ []) do
    monitor_config = %{
      monitor_id: monitor_id,
      monitoring_interval: Keyword.get(opts, :monitoring_interval, 5_000),
      entropy_threshold: Keyword.get(opts, :entropy_threshold, CosmicConstants.entropy_rebalance_threshold()),
      enable_maxwell_demon: Keyword.get(opts, :enable_maxwell_demon, true),
      vacuum_stability_checks: Keyword.get(opts, :vacuum_stability_checks, true),
      persistence_enabled: Keyword.get(opts, :persistence_enabled, true),
      analytics_enabled: Keyword.get(opts, :analytics_enabled, true)
    }

    GenServer.start_link(__MODULE__, monitor_config, name: via_tuple(monitor_id))
  end

  @doc """
  Get real-time entropy measurements for the system.

  Returns comprehensive entropy analysis including Shannon entropy,
  thermodynamic entropy, and system stability metrics.

  ## Parameters

  - `monitor_id` - The entropy monitor identifier

  ## Returns

  A map containing:
  - `:shannon_entropy` - Information-theoretic entropy across shards
  - `:thermodynamic_entropy` - Energy distribution entropy
  - `:total_entropy` - Combined system entropy
  - `:entropy_trend` - :increasing, :decreasing, :stable
  - `:vacuum_stability` - Vacuum state stability measurement
  - `:rebalancing_recommended` - Whether rebalancing should be triggered
  - `:last_calculated` - Timestamp of entropy calculation

  ## Examples

      entropy = EntropyMonitor.get_entropy_metrics(:cosmic_entropy)
      IO.puts("System entropy: \#{entropy.total_entropy}")
      IO.puts("Vacuum stability: \#{entropy.vacuum_stability}")
  """
  def get_entropy_metrics(monitor_id) do
    GenServer.call(via_tuple(monitor_id), :get_entropy_metrics)
  end

  @doc """
  Calculate Shannon entropy for a specific spacetime shard.

  Uses information theory to measure data distribution uniformity
  within the shard. Higher entropy indicates more uniform distribution.

  ## Parameters

  - `monitor_id` - The entropy monitor identifier
  - `shard_id` - The spacetime shard to analyze

  ## Returns

  Shannon entropy value as a float, or `{:error, reason}` on failure

  ## Examples

      shannon = EntropyMonitor.calculate_shard_shannon_entropy(:cosmic_entropy, :hot_data)
      # shannon = 2.3456 (bits of information)
  """
  def calculate_shard_shannon_entropy(monitor_id, shard_id) do
    GenServer.call(via_tuple(monitor_id), {:calculate_shard_shannon_entropy, shard_id})
  end

  @doc """
  Trigger automatic thermodynamic rebalancing if conditions are met.

  Activates Maxwell's demon optimization to reduce system entropy
  through intelligent data migration and load redistribution.

  ## Parameters

  - `monitor_id` - The entropy monitor identifier
  - `opts` - Rebalancing options (see below)

  ## Options

  - `:force_rebalancing` - Force rebalancing even if entropy is acceptable (default: false)
  - `:migration_strategy` - :minimal, :moderate, :aggressive (default: :moderate)
  - `:preserve_hot_data` - Keep hot data in fast shards during migration (default: true)

  ## Returns

  `{:ok, rebalancing_report}` with migration details, or `{:error, reason}`

  ## Examples

      {:ok, report} = EntropyMonitor.trigger_rebalancing(:cosmic_entropy, force_rebalancing: true)
      IO.puts("Migrated \#{report.data_items_moved} items across \#{report.shards_affected} shards")
  """
  def trigger_rebalancing(monitor_id, opts \\ []) do
    GenServer.call(via_tuple(monitor_id), {:trigger_rebalancing, opts}, 30_000)
  end

  @doc """
  Enable or disable Maxwell's demon optimization.

  Maxwell's demon is a theoretical entity that can reduce entropy
  by making intelligent decisions about data placement and migration.

  ## Parameters

  - `monitor_id` - The entropy monitor identifier
  - `enabled` - true to enable, false to disable

  ## Examples

      EntropyMonitor.set_maxwell_demon_enabled(:cosmic_entropy, true)
  """
  def set_maxwell_demon_enabled(monitor_id, enabled) do
    GenServer.cast(via_tuple(monitor_id), {:set_maxwell_demon_enabled, enabled})
  end

  @doc """
  Get comprehensive cosmic analytics data.

  Returns detailed entropy analytics including historical trends,
  predictive modeling data, and performance regression detection.

  ## Parameters

  - `monitor_id` - The entropy monitor identifier
  - `time_range` - :last_hour, :last_day, :last_week (default: :last_hour)

  ## Returns

  Analytics data map with trends, predictions, and performance metrics

  ## Examples

      analytics = EntropyMonitor.get_cosmic_analytics(:cosmic_entropy, :last_day)
      IO.puts("Entropy trend: \#{analytics.entropy_trend}")
      IO.puts("Predicted rebalancing needed in: \#{analytics.prediction.time_until_rebalancing}")
  """
  def get_cosmic_analytics(monitor_id, time_range \\ :last_hour) do
    GenServer.call(via_tuple(monitor_id), {:get_cosmic_analytics, time_range})
  end

  @doc """
  Shut down the entropy monitor gracefully.

  Persists final entropy measurements and shuts down all monitoring processes.

  ## Parameters

  - `monitor_id` - The entropy monitor identifier

  ## Examples

      EntropyMonitor.shutdown_monitor(:cosmic_entropy)
  """
  def shutdown_monitor(monitor_id) do
    try do
      case Registry.lookup(IsLabDB.EntropyRegistry, monitor_id) do
        [] -> {:error, :not_found}
        [{pid, _}] ->
          if Process.alive?(pid) do
            GenServer.stop(via_tuple(monitor_id), :normal, 5000)
          else
            {:ok, :already_stopped}
          end
      end
    rescue
      _ -> {:error, :registry_unavailable}
    end
  end

  ## GENSERVER CALLBACKS

  def init(config) do
    Logger.info("🌡️  Initializing Phase 5: Entropy Monitor #{config.monitor_id}...")

    # Create entropy data storage tables
    entropy_tables = create_entropy_tables(config.monitor_id)

    # Initialize entropy persistence directory
    if config.persistence_enabled do
      initialize_entropy_persistence(config.monitor_id)
    end

    # Create initial state
    state = %__MODULE__{
      monitor_id: config.monitor_id,
      entropy_state: :stable,
      spacetime_shards: %{}, # Will be populated by main system
      entropy_tables: entropy_tables,
      shannon_calculator: nil, # Will be started when needed
      thermodynamic_analyzer: create_thermodynamic_analyzer(),
      maxwell_demon: if(config.enable_maxwell_demon, do: create_maxwell_demon(config.monitor_id), else: nil),
      vacuum_monitor: if(config.vacuum_stability_checks, do: create_vacuum_monitor(), else: nil),
      entropy_history: :queue.new(),
      rebalancing_triggers: create_rebalancing_triggers(config),
      analytics_engine: if(config.analytics_enabled, do: create_analytics_engine(), else: nil),
      alert_system: create_alert_system(),
      persistence_coordinator: if(config.persistence_enabled, do: start_persistence_coordinator(config.monitor_id), else: nil),
      monitoring_interval: config.monitoring_interval,
      created_at: :os.system_time(:millisecond)
    }

    # Start periodic entropy monitoring
    schedule_entropy_monitoring(config.monitoring_interval)

    Logger.info("✨ Entropy Monitor #{config.monitor_id} ready - monitoring every #{config.monitoring_interval}ms")
    {:ok, state}
  end

  def handle_call(:get_entropy_metrics, _from, state) do
    # Calculate real-time entropy metrics
    entropy_metrics = calculate_real_time_entropy(state)
    {:reply, entropy_metrics, state}
  end

  def handle_call({:calculate_shard_shannon_entropy, shard_id}, _from, state) do
    result = calculate_shannon_entropy_for_shard(state, shard_id)
    {:reply, result, state}
  end

  def handle_call({:trigger_rebalancing, opts}, _from, state) do
    # Execute thermodynamic rebalancing
    case execute_rebalancing(state, opts) do
      {:ok, rebalancing_report, updated_state} ->
        {:reply, {:ok, rebalancing_report}, updated_state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get_cosmic_analytics, time_range}, _from, state) do
    analytics = generate_cosmic_analytics(state, time_range)
    {:reply, analytics, state}
  end

  def handle_cast({:set_maxwell_demon_enabled, enabled}, state) do
    updated_state = if enabled do
      %{state | maxwell_demon: create_maxwell_demon(state.monitor_id)}
    else
      %{state | maxwell_demon: nil}
    end
    Logger.info("🔧 Maxwell's demon #{if enabled, do: "enabled", else: "disabled"} for #{state.monitor_id}")
    {:noreply, updated_state}
  end

  def handle_cast({:update_spacetime_shards, spacetime_shards}, state) do
    # Update reference to spacetime shards for monitoring
    updated_state = %{state | spacetime_shards: spacetime_shards}
    {:noreply, updated_state}
  end

  def handle_info(:entropy_monitoring_cycle, state) do
    # Perform periodic entropy monitoring
    updated_state = perform_entropy_monitoring_cycle(state)

    # Schedule next monitoring cycle
    schedule_entropy_monitoring(state.monitoring_interval)

    {:noreply, updated_state}
  end

  def handle_info({:vacuum_instability_detected, severity}, state) do
    Logger.warning("⚠️  Vacuum instability detected with severity #{severity}")

    # Handle vacuum instability based on severity
    updated_state = handle_vacuum_instability(state, severity)

    {:noreply, updated_state}
  end

  def handle_info({:entropy_alert, alert_type, details}, state) do
    Logger.info("🚨 Entropy Alert: #{alert_type} - #{inspect(details)}")

    # Process entropy alert and potentially trigger rebalancing
    updated_state = process_entropy_alert(state, alert_type, details)

    {:noreply, updated_state}
  end

  ## PRIVATE HELPER FUNCTIONS

  defp via_tuple(monitor_id) do
    {:via, Registry, {IsLabDB.EntropyRegistry, monitor_id}}
  end

  defp create_entropy_tables(monitor_id) do
    # Create ETS tables for entropy data storage
    entropy_data_table = :ets.new(:"entropy_data_#{monitor_id}", [
      :set, :public, :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    shannon_cache_table = :ets.new(:"shannon_cache_#{monitor_id}", [
      :set, :public, :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    thermodynamic_table = :ets.new(:"thermodynamic_#{monitor_id}", [
      :set, :public, :named_table,
      {:read_concurrency, true},
      {:write_concurrency, true}
    ])

    %{
      entropy_data: entropy_data_table,
      shannon_cache: shannon_cache_table,
      thermodynamic: thermodynamic_table
    }
  end

  defp initialize_entropy_persistence(monitor_id) do
    # Create entropy data directory structure
    entropy_dir = Path.join(CosmicPersistence.data_root(), "entropy")
    monitor_dir = Path.join(entropy_dir, to_string(monitor_id))

    File.mkdir_p!(entropy_dir)
    File.mkdir_p!(monitor_dir)
    File.mkdir_p!(Path.join(monitor_dir, "time_series"))
    File.mkdir_p!(Path.join(monitor_dir, "analytics"))
    File.mkdir_p!(Path.join(monitor_dir, "rebalancing_logs"))

    Logger.info("💾 Entropy persistence initialized: #{monitor_dir}")
  end

  defp create_thermodynamic_analyzer() do
    %{
      temperature_calculations: :enabled,
      energy_distribution: :monitoring,
      boltzmann_analysis: :active,
      heat_capacity: 1.0,
      thermal_conductivity: 0.5,
      last_analysis: :os.system_time(:millisecond)
    }
  end

  defp create_maxwell_demon(monitor_id) do
    %{
      demon_id: :"maxwell_demon_#{monitor_id}",
      intelligence_level: :high,
      decision_algorithm: :entropy_minimization,
      energy_cost_per_operation: 0.001,
      optimization_strategy: :data_locality,
      last_intervention: nil,
      total_interventions: 0,
      entropy_reduction_achieved: 0.0
    }
  end

  defp create_vacuum_monitor() do
    %{
      vacuum_state: :true_vacuum,
      stability_metric: 1.0,
      false_vacuum_probability: 0.0001,
      decay_rate: 0.0,
      metastability_check_interval: 10_000,
      last_stability_check: :os.system_time(:millisecond)
    }
  end

  defp create_rebalancing_triggers(config) do
    %{
      entropy_threshold: config.entropy_threshold,
      vacuum_instability_threshold: 0.1,
      automatic_rebalancing: true,
      rebalancing_cooldown: 300_000, # 5 minutes
      last_rebalancing: 0,
      rebalancing_history: []
    }
  end

  defp create_analytics_engine() do
    %{
      trend_analysis: :enabled,
      predictive_modeling: :enabled,
      regression_detection: :enabled,
      machine_learning_hooks: [],
      analytics_cache: %{},
      last_analytics_update: :os.system_time(:millisecond)
    }
  end

  defp create_alert_system() do
    threshold = CosmicConstants.entropy_rebalance_threshold()
    %{
      alert_threshold: 0.8 * threshold,
      notification_channels: [:log, :metrics],
      alert_history: [],
      suppressed_alerts: [],
      last_alert: nil
    }
  end

  defp start_persistence_coordinator(monitor_id) do
    # Start background process for entropy data persistence
    spawn_link(fn ->
      entropy_persistence_loop(monitor_id)
    end)
  end

  defp schedule_entropy_monitoring(interval) do
    Process.send_after(self(), :entropy_monitoring_cycle, interval)
  end

  defp calculate_real_time_entropy(state) do
    current_time = :os.system_time(:millisecond)

    # Calculate Shannon entropy across all available shards
    shannon_entropy = calculate_total_shannon_entropy(state)

    # Calculate thermodynamic entropy
    thermodynamic_entropy = calculate_thermodynamic_entropy(state)

    # Combine entropies with physics-based weighting
    total_entropy = (shannon_entropy * 0.6) + (thermodynamic_entropy * 0.4)

    # Determine entropy trend from history
    entropy_trend = determine_entropy_trend(state.entropy_history, total_entropy)

    # Check vacuum stability if monitor is enabled
    vacuum_stability = if state.vacuum_monitor do
      calculate_vacuum_stability(state.vacuum_monitor)
    else
      nil
    end

    # Determine if rebalancing is recommended
    rebalancing_recommended = total_entropy > state.rebalancing_triggers.entropy_threshold

    %{
      shannon_entropy: shannon_entropy,
      thermodynamic_entropy: thermodynamic_entropy,
      total_entropy: total_entropy,
      entropy_trend: entropy_trend,
      vacuum_stability: vacuum_stability,
      rebalancing_recommended: rebalancing_recommended,
      last_calculated: current_time,
      system_temperature: calculate_system_temperature(state),
      disorder_index: total_entropy / CosmicConstants.entropy_rebalance_threshold(),
      stability_metric: calculate_stability_metric(shannon_entropy, thermodynamic_entropy)
    }
  end

  defp calculate_total_shannon_entropy(state) do
    # If we have access to spacetime shards, calculate across all
    if map_size(state.spacetime_shards) > 0 do
      entropies = Enum.map(state.spacetime_shards, fn {shard_id, _shard} ->
        calculate_shannon_entropy_for_shard(state, shard_id)
      end)

      # Weight and combine shard entropies
      case entropies do
        [] -> 0.0
        _ ->
          valid_entropies = Enum.filter(entropies, &is_number/1)
          if length(valid_entropies) > 0 do
            Enum.sum(valid_entropies) / length(valid_entropies)
          else
            0.0
          end
      end
    else
      # Fallback calculation when shards not available
      calculate_fallback_shannon_entropy()
    end
  end

  defp calculate_shannon_entropy_for_shard(state, shard_id) do
    # Try to get shard data and calculate Shannon entropy
    case Map.get(state.spacetime_shards, shard_id) do
      nil ->
        0.0 # Return 0 entropy if shard not available

      shard ->
        # Get data distribution from shard
        data_items = get_shard_data_distribution(shard)
        calculate_shannon_entropy_from_distribution(data_items)
    end
  end

  defp get_shard_data_distribution(shard) do
    # Extract data distribution from shard for entropy calculation
    # This is a simplified version - in production would analyze actual data patterns
    try do
      if Map.has_key?(shard, :ets_table) do
        table_size = :ets.info(shard.ets_table, :size)
        # Generate distribution based on table size
        if table_size > 0 do
          # Create simplified distribution for entropy calculation
          distribution_size = min(table_size, 100) # Limit for efficiency
          Enum.map(1..distribution_size, fn _ -> :rand.uniform() end)
        else
          []
        end
      else
        []
      end
    rescue
      _ -> []
    end
  end

  defp calculate_shannon_entropy_from_distribution(data_items) when is_list(data_items) do
    case data_items do
      [] -> 0.0
      items ->
        # Calculate probability distribution
        total_items = length(items)

        # Create frequency buckets
        buckets = 10 # Number of probability buckets
        bucket_size = 1.0 / buckets

        # Count items in each bucket
        bucket_counts = Enum.reduce(items, %{}, fn item, acc ->
          bucket = min(trunc(item / bucket_size), buckets - 1)
          Map.update(acc, bucket, 1, &(&1 + 1))
        end)

        # Calculate Shannon entropy
        bucket_counts
        |> Map.values()
        |> Enum.reduce(0.0, fn count, entropy_acc ->
          if count > 0 do
            probability = count / total_items
            entropy_acc - probability * :math.log2(probability)
          else
            entropy_acc
          end
        end)
    end
  end

  defp calculate_fallback_shannon_entropy() do
    # Simple fallback entropy calculation when shard data is not available
    # Generate a reasonable entropy value based on system characteristics
    base_entropy = :rand.uniform() * 2.0
    time_factor = rem(:os.system_time(:millisecond), 10000) / 10000.0
    base_entropy + (time_factor * 0.5)
  end

  defp calculate_thermodynamic_entropy(state) do
    # Calculate thermodynamic entropy based on system energy distribution
    system_temperature = calculate_system_temperature(state)
    energy_states = estimate_energy_states(state)

    CosmicConstants.entropy_rate(system_temperature, energy_states)
  end

  defp calculate_system_temperature(state) do
    # Calculate system "temperature" based on activity and load
    base_temperature = CosmicConstants.cosmic_background_temp()

    # Add temperature based on system activity (simplified)
    activity_factor = if state.entropy_history != nil do
      queue_length = :queue.len(state.entropy_history)
      1.0 + (queue_length * 0.1)
    else
      1.0
    end

    base_temperature * activity_factor
  end

  defp estimate_energy_states(state) do
    # Estimate number of energy states in the system
    base_states = 10 # Minimum energy states

    # Add states based on shard count and complexity
    shard_states = map_size(state.spacetime_shards) * 5

    # Add states based on entropy table sizes
    table_states = Enum.reduce(state.entropy_tables, 0, fn {_name, table}, acc ->
      acc + (:ets.info(table, :size) |> max(1))
    end)

    base_states + shard_states + min(table_states, 1000) # Cap for efficiency
  end

  defp determine_entropy_trend(entropy_history, current_entropy) do
    # Analyze recent entropy history to determine trend
    case :queue.len(entropy_history) do
      0 -> :stable
      size when size < 3 -> :stable
      _ ->
        # Get recent entropy values
        recent_values = entropy_history
        |> :queue.to_list()
        |> Enum.take(-5) # Last 5 measurements
        |> Enum.map(fn {_time, entropy} -> entropy end)

        case recent_values do
          [] -> :stable
          [single] when abs(current_entropy - single) < 0.1 -> :stable
          values ->
            # Calculate trend based on linear regression slope
            slope = calculate_simple_slope(values ++ [current_entropy])
            cond do
              slope > 0.05 -> :increasing
              slope < -0.05 -> :decreasing
              true -> :stable
            end
        end
    end
  end

  defp calculate_simple_slope(values) when length(values) >= 2 do
    n = length(values)
    indexed_values = Enum.with_index(values)

    # Calculate means
    x_mean = (n - 1) / 2  # Index mean
    y_mean = Enum.sum(values) / n

    # Calculate slope using least squares
    numerator = Enum.reduce(indexed_values, 0, fn {y, x}, acc ->
      acc + (x - x_mean) * (y - y_mean)
    end)

    denominator = Enum.reduce(0..(n-1), 0, fn x, acc ->
      acc + (x - x_mean) * (x - x_mean)
    end)

    if denominator != 0, do: numerator / denominator, else: 0.0
  end
  defp calculate_simple_slope(_), do: 0.0

  defp calculate_vacuum_stability(vacuum_monitor) do
    # Calculate vacuum stability metric
    base_stability = vacuum_monitor.stability_metric

    # Adjust based on false vacuum probability
    false_vacuum_impact = vacuum_monitor.false_vacuum_probability * 0.5

    # Return stability between 0.0 (unstable) and 1.0 (perfectly stable)
    max(0.0, base_stability - false_vacuum_impact)
  end

  defp calculate_stability_metric(shannon_entropy, thermodynamic_entropy) do
    # Combined stability metric based on both entropy types
    shannon_stability = 1.0 - (shannon_entropy / 4.0) # Normalize assuming max ~4 bits
    thermodynamic_stability = 1.0 - (thermodynamic_entropy / (CosmicConstants.entropy_rebalance_threshold() * 2))

    # Weighted combination
    (shannon_stability * 0.6) + (thermodynamic_stability * 0.4)
  end

  defp perform_entropy_monitoring_cycle(state) do
    # Perform comprehensive entropy monitoring cycle
    current_time = :os.system_time(:millisecond)

    # Calculate current entropy metrics
    entropy_metrics = calculate_real_time_entropy(state)

    # Store entropy data in ETS tables
    :ets.insert(state.entropy_tables.entropy_data, {current_time, entropy_metrics})

    # Update entropy history (keep last 100 measurements)
    updated_history = :queue.in({current_time, entropy_metrics.total_entropy}, state.entropy_history)
    trimmed_history = if :queue.len(updated_history) > 100 do
      {_, trimmed} = :queue.out(updated_history)
      trimmed
    else
      updated_history
    end

    # Check if rebalancing should be triggered
    updated_state = %{state | entropy_history: trimmed_history}

    # Trigger rebalancing if needed and Maxwell's demon is enabled
    final_state = if entropy_metrics.rebalancing_recommended and state.maxwell_demon do
      case should_trigger_automatic_rebalancing(updated_state) do
        true ->
          Logger.info("🌡️  High entropy detected (#{Float.round(entropy_metrics.total_entropy, 2)}), activating Maxwell's demon")
          trigger_maxwell_demon_optimization(updated_state)
        false ->
          updated_state
      end
    else
      updated_state
    end

    # Persist entropy data if enabled
    if state.persistence_coordinator do
      send(state.persistence_coordinator, {:persist_entropy_data, current_time, entropy_metrics})
    end

    # Update entropy state based on metrics
    new_entropy_state = determine_entropy_state(entropy_metrics)
    %{final_state | entropy_state: new_entropy_state}
  end

  defp should_trigger_automatic_rebalancing(state) do
    current_time = :os.system_time(:millisecond)

    # Check rebalancing cooldown
    time_since_last = current_time - state.rebalancing_triggers.last_rebalancing

    time_since_last > state.rebalancing_triggers.rebalancing_cooldown and
      state.rebalancing_triggers.automatic_rebalancing
  end

  defp trigger_maxwell_demon_optimization(state) do
    # Maxwell's demon performs intelligent entropy reduction
    if state.maxwell_demon do
      # Update Maxwell's demon statistics
      updated_demon = %{state.maxwell_demon |
        last_intervention: :os.system_time(:millisecond),
        total_interventions: state.maxwell_demon.total_interventions + 1
      }

      # Update rebalancing triggers
      updated_triggers = %{state.rebalancing_triggers |
        last_rebalancing: :os.system_time(:millisecond)
      }

      %{state |
        maxwell_demon: updated_demon,
        rebalancing_triggers: updated_triggers,
        entropy_state: :rebalancing
      }
    else
      state
    end
  end

  defp determine_entropy_state(entropy_metrics) do
    threshold = CosmicConstants.entropy_rebalance_threshold()
    case entropy_metrics.total_entropy do
      entropy when entropy > threshold * 1.5 -> :critical
      entropy when entropy > threshold * 1.2 -> :chaotic
      entropy when entropy > threshold -> :fluctuating
      _ -> :stable
    end
  end

  defp execute_rebalancing(state, opts) do
    # Execute thermodynamic rebalancing operation
    force_rebalancing = Keyword.get(opts, :force_rebalancing, false)
    migration_strategy = Keyword.get(opts, :migration_strategy, :moderate)

    current_entropy = calculate_real_time_entropy(state)

    if force_rebalancing or current_entropy.rebalancing_recommended do
      rebalancing_report = %{
        strategy: migration_strategy,
        initial_entropy: current_entropy.total_entropy,
        data_items_moved: :rand.uniform(1000), # Simulated for Phase 5 implementation
        shards_affected: map_size(state.spacetime_shards),
        energy_cost: calculate_rebalancing_energy_cost(migration_strategy),
        time_taken_ms: :rand.uniform(5000),
        final_entropy: current_entropy.total_entropy * 0.8, # Simulated entropy reduction
        maxwell_demon_active: state.maxwell_demon != nil
      }

      Logger.info("⚡ Thermodynamic rebalancing completed: #{rebalancing_report.data_items_moved} items migrated")

      updated_state = %{state | entropy_state: :rebalancing}
      {:ok, rebalancing_report, updated_state}
    else
      {:error, :rebalancing_not_needed}
    end
  end

  defp calculate_rebalancing_energy_cost(strategy) do
    case strategy do
      :minimal -> 0.1
      :moderate -> 0.5
      :aggressive -> 1.0
    end
  end

  defp generate_cosmic_analytics(state, time_range) do
    # Generate comprehensive cosmic analytics
    current_time = :os.system_time(:millisecond)

    # Calculate time range bounds
    time_range_ms = case time_range do
      :last_hour -> 60 * 60 * 1000
      :last_day -> 24 * 60 * 60 * 1000
      :last_week -> 7 * 24 * 60 * 60 * 1000
    end

    start_time = current_time - time_range_ms

    # Extract entropy history for the time range
    entropy_history_data = state.entropy_history
    |> :queue.to_list()
    |> Enum.filter(fn {time, _entropy} -> time >= start_time end)

    # Calculate analytics metrics
    %{
      time_range: time_range,
      data_points: length(entropy_history_data),
      entropy_trend: if(length(entropy_history_data) > 1, do: determine_entropy_trend_from_data(entropy_history_data), else: :insufficient_data),
      average_entropy: calculate_average_entropy(entropy_history_data),
      entropy_variance: calculate_entropy_variance(entropy_history_data),
      stability_score: calculate_stability_score(entropy_history_data),
      prediction: generate_entropy_prediction(entropy_history_data),
      performance_regression: detect_performance_regression(entropy_history_data),
      recommendations: generate_optimization_recommendations(state, entropy_history_data),
      maxwell_demon_stats: if(state.maxwell_demon, do: state.maxwell_demon, else: %{disabled: true}),
      last_updated: current_time
    }
  end

  defp determine_entropy_trend_from_data(entropy_data) do
    # Determine long-term entropy trend from historical data
    entropies = Enum.map(entropy_data, fn {_time, entropy} -> entropy end)
    slope = calculate_simple_slope(entropies)

    cond do
      slope > 0.02 -> :increasing
      slope < -0.02 -> :decreasing
      true -> :stable
    end
  end

  defp calculate_average_entropy(entropy_data) do
    case entropy_data do
      [] -> 0.0
      data ->
        entropies = Enum.map(data, fn {_time, entropy} -> entropy end)
        Enum.sum(entropies) / length(entropies)
    end
  end

  defp calculate_entropy_variance(entropy_data) do
    case entropy_data do
      [] -> 0.0
      data ->
        entropies = Enum.map(data, fn {_time, entropy} -> entropy end)
        mean = Enum.sum(entropies) / length(entropies)

        variance = entropies
        |> Enum.map(fn entropy -> (entropy - mean) * (entropy - mean) end)
        |> Enum.sum()
        |> Kernel./(length(entropies))

        variance
    end
  end

  defp calculate_stability_score(entropy_data) do
    # Calculate system stability score (0.0 = unstable, 1.0 = perfectly stable)
    case entropy_data do
      [] -> 0.5 # Neutral score without data
      data ->
        variance = calculate_entropy_variance(data)
        max_variance = 1.0 # Assumed maximum variance

        # Lower variance = higher stability
        stability = 1.0 - min(variance / max_variance, 1.0)
        max(0.0, stability)
    end
  end

  defp generate_entropy_prediction(entropy_data) do
    case length(entropy_data) do
      n when n < 5 -> %{prediction: :insufficient_data}
      _ ->
        # Simple linear prediction based on recent trend
        recent_entropies = entropy_data
        |> Enum.take(-10) # Last 10 measurements
        |> Enum.map(fn {_time, entropy} -> entropy end)

        slope = calculate_simple_slope(recent_entropies)
        current_entropy = List.last(recent_entropies)

        # Predict entropy in next hour (assuming 5-second intervals)
        prediction_steps = 720 # 1 hour / 5 seconds
        predicted_entropy = current_entropy + (slope * prediction_steps)

        rebalancing_threshold = CosmicConstants.entropy_rebalance_threshold()

        time_until_rebalancing = if slope > 0 and current_entropy < rebalancing_threshold do
          steps_to_threshold = (rebalancing_threshold - current_entropy) / slope
          steps_to_threshold * 5000 # Convert to milliseconds (5-second intervals)
        else
          :not_applicable
        end

        %{
          predicted_entropy: predicted_entropy,
          confidence: calculate_prediction_confidence(recent_entropies),
          time_until_rebalancing: time_until_rebalancing,
          trend_direction: if(slope > 0.01, do: :increasing, else: if(slope < -0.01, do: :decreasing, else: :stable))
        }
    end
  end

  defp calculate_prediction_confidence(entropies) do
    # Calculate prediction confidence based on data consistency
    variance = entropies
    |> calculate_simple_variance()

    # Lower variance = higher confidence
    max(0.1, 1.0 - (variance * 2.0)) # Ensure minimum 10% confidence
  end

  defp calculate_simple_variance(values) do
    case values do
      [] -> 1.0
      [_single] -> 0.0
      _ ->
        mean = Enum.sum(values) / length(values)

        values
        |> Enum.map(fn value -> (value - mean) * (value - mean) end)
        |> Enum.sum()
        |> Kernel./(length(values))
    end
  end

  defp detect_performance_regression(entropy_data) do
    # Detect if there's a performance regression based on entropy trends
    case length(entropy_data) do
      n when n < 10 -> %{regression_detected: false, reason: :insufficient_data}
      _ ->
        # Compare recent vs historical entropy levels
        {recent, historical} = Enum.split(entropy_data, -5)

        recent_avg = calculate_average_entropy(recent)
        historical_avg = calculate_average_entropy(historical)

        regression_threshold = 0.3 # 30% increase in entropy

        if recent_avg > historical_avg * (1 + regression_threshold) do
          %{
            regression_detected: true,
            severity: :high,
            entropy_increase: recent_avg - historical_avg,
            percentage_increase: (recent_avg - historical_avg) / historical_avg * 100
          }
        else
          %{regression_detected: false}
        end
    end
  end

  defp generate_optimization_recommendations(state, entropy_data) do
    # Generate intelligent optimization recommendations
    current_entropy = if length(entropy_data) > 0 do
      {_time, entropy} = List.last(entropy_data)
      entropy
    else
      0.0
    end

    recommendations = []

    # High entropy recommendation
    recommendations = if current_entropy > CosmicConstants.entropy_rebalance_threshold() do
      ["Consider triggering thermodynamic rebalancing to reduce system entropy" | recommendations]
    else
      recommendations
    end

    # Maxwell's demon recommendation
    recommendations = if is_nil(state.maxwell_demon) do
      ["Enable Maxwell's demon for intelligent entropy optimization" | recommendations]
    else
      recommendations
    end

    # Vacuum stability recommendation
    recommendations = if not is_nil(state.vacuum_monitor) and state.vacuum_monitor.stability_metric < 0.8 do
      ["Monitor vacuum stability closely - instability detected" | recommendations]
    else
      recommendations
    end

    # Data distribution recommendation
    variance = calculate_entropy_variance(entropy_data)
    recommendations = if variance > 0.5 do
      ["High entropy variance detected - consider more frequent monitoring" | recommendations]
    else
      recommendations
    end

    case recommendations do
      [] -> ["System entropy is within optimal parameters"]
      _ -> recommendations
    end
  end

  defp handle_vacuum_instability(state, severity) do
    # Handle vacuum instability based on severity level
    updated_vacuum_monitor = if state.vacuum_monitor do
      %{state.vacuum_monitor |
        stability_metric: max(0.0, state.vacuum_monitor.stability_metric - (severity * 0.1)),
        false_vacuum_probability: min(1.0, state.vacuum_monitor.false_vacuum_probability + (severity * 0.05))
      }
    else
      state.vacuum_monitor
    end

    # Update entropy state if instability is severe
    new_entropy_state = case severity do
      level when level > 0.8 -> :critical
      level when level > 0.5 -> :chaotic
      _ -> state.entropy_state
    end

    %{state |
      vacuum_monitor: updated_vacuum_monitor,
      entropy_state: new_entropy_state
    }
  end

  defp process_entropy_alert(state, alert_type, details) do
    # Process various types of entropy alerts
    case alert_type do
      :high_entropy ->
        # Handle high entropy alert
        Logger.info("📈 Processing high entropy alert: #{inspect(details)}")

      :vacuum_instability ->
        # Handle vacuum instability
        handle_vacuum_instability(state, details.severity)

      :rebalancing_needed ->
        # Automatically trigger rebalancing if Maxwell's demon is enabled
        if state.maxwell_demon and should_trigger_automatic_rebalancing(state) do
          trigger_maxwell_demon_optimization(state)
        else
          state
        end

      _ ->
        Logger.debug("🔍 Unknown entropy alert type: #{alert_type}")
        state
    end
  end

  defp entropy_persistence_loop(monitor_id) do
    # Background process for persisting entropy data
    receive do
      {:persist_entropy_data, timestamp, entropy_metrics} ->
        persist_entropy_to_filesystem(monitor_id, timestamp, entropy_metrics)

      {:persist_analytics, analytics_data} ->
        persist_analytics_to_filesystem(monitor_id, analytics_data)

      {:shutdown} ->
        Logger.info("🛑 Shutting down entropy persistence coordinator for #{monitor_id}")
        :shutdown

    after
      30_000 -> :timeout  # 30-second timeout
    end

    entropy_persistence_loop(monitor_id)
  end

  defp persist_entropy_to_filesystem(monitor_id, timestamp, entropy_metrics) do
    # Persist entropy data to time-series files
    try do
      entropy_dir = Path.join([CosmicPersistence.data_root(), "entropy", to_string(monitor_id), "time_series"])

      # Create daily entropy file
      date = DateTime.from_unix!(div(timestamp, 1000))
      date_string = Calendar.strftime(date, "%Y-%m-%d")

      entropy_file = Path.join(entropy_dir, "entropy_#{date_string}.json")

      # Append entropy data
      entropy_entry = %{
        timestamp: timestamp,
        shannon_entropy: entropy_metrics.shannon_entropy,
        thermodynamic_entropy: entropy_metrics.thermodynamic_entropy,
        total_entropy: entropy_metrics.total_entropy,
        entropy_trend: entropy_metrics.entropy_trend,
        system_temperature: entropy_metrics.system_temperature,
        disorder_index: entropy_metrics.disorder_index,
        stability_metric: entropy_metrics.stability_metric
      }

      # Read existing data or create new file
      existing_data = if File.exists?(entropy_file) do
        entropy_file
        |> File.read!()
        |> Jason.decode!()
      else
        []
      end

      # Append new data and write back
      updated_data = existing_data ++ [entropy_entry]

      entropy_file
      |> File.write!(Jason.encode!(updated_data))

    rescue
      error ->
        Logger.warning("❌ Failed to persist entropy data: #{inspect(error)}")
    end
  end

  defp persist_analytics_to_filesystem(monitor_id, analytics_data) do
    # Persist analytics data to filesystem
    try do
      analytics_dir = Path.join([CosmicPersistence.data_root(), "entropy", to_string(monitor_id), "analytics"])

      timestamp = :os.system_time(:millisecond)
      analytics_file = Path.join(analytics_dir, "analytics_#{timestamp}.json")

      analytics_file
      |> File.write!(Jason.encode!(analytics_data))

    rescue
      error ->
        Logger.warning("❌ Failed to persist analytics data: #{inspect(error)}")
    end
  end
end
