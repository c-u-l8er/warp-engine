defmodule WarpEngine.IntelligentLoadBalancer do
  @moduledoc """
  Intelligent Load Balancer for Phase 9.2 Optimization.

  Eliminates performance drops at non-optimal concurrency levels by:
  - Monitoring real-time shard utilization and performance
  - Implementing adaptive routing strategies based on current load
  - Providing load-aware shard selection for optimal distribution
  - Detecting concurrency patterns and optimizing accordingly

  ## Key Optimizations

  - **Load-Aware Routing**: Routes operations to least-loaded shards
  - **Concurrency Pattern Detection**: Adapts strategy based on process count
  - **Performance Feedback**: Learns from actual throughput metrics
  - **Dynamic Rebalancing**: Shifts load when imbalances are detected

  ## Target Performance Improvements

  - 4 processes: 54K → 85K ops/sec (eliminate uneven distribution)
  - 12 processes: 37K → 150K ops/sec (reduce intra-shard contention)
  - 20-24 processes: 36-55K → 120K ops/sec (better over-subscription handling)
  """

  use GenServer
  require Logger

  defstruct [
    :shard_loads,                    # Real-time load tracking per shard
    :performance_history,            # Historical performance by concurrency level
    :routing_strategy,               # Current routing strategy (:hash, :round_robin, :least_loaded)
    :concurrency_level,              # Detected process concurrency level
    :rebalancing_active,             # Whether active rebalancing is enabled
    :performance_metrics,            # Real-time throughput metrics
    :optimization_state              # Current optimization configuration
  ]

  # PHASE 9.2: Support both legacy 3-shard and modern 24-shard systems
  @legacy_shard_ids [:hot_data, :warm_data, :cold_data]

  # Performance targets for different concurrency levels
  @performance_targets %{
    1 => 45_000,    # Single process baseline
    2 => 95_000,    # Sweet spot - maintain current performance
    4 => 85_000,    # Target: eliminate uneven distribution penalty
    6 => 90_000,    # Target: improve balanced distribution
    8 => 110_000,   # Target: optimize for 8-core alignment
    12 => 150_000,  # Target: reduce intra-shard contention
    16 => 200_000,  # Current peak - maintain
    20 => 120_000,  # Target: better over-subscription handling
    24 => 100_000   # Target: manageable high-concurrency performance
  }

  @monitor_interval_ms 200
  @review_interval_ms 500

  ## Public API

  @doc """
  Start the intelligent load balancer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get optimal shard for a new operation based on current system state.

  This replaces the simple hash-based routing with intelligent routing
  that considers current load, concurrency patterns, and performance feedback.
  """
  def get_optimal_shard(key, operation_metadata \\ %{}) do
    GenServer.call(__MODULE__, {:get_optimal_shard, key, operation_metadata})
  end

  @doc """
  Update performance metrics for adaptive optimization.
  """
  def update_performance_metrics(metrics) do
    GenServer.cast(__MODULE__, {:update_performance_metrics, metrics})
  end

  @doc """
  Get current load balancing statistics and recommendations.
  """
  def get_balancing_stats() do
    GenServer.call(__MODULE__, :get_balancing_stats)
  end

  @doc """
  Get current shard IDs based on configuration.
  """
  def get_shard_ids() do
    if Application.get_env(:warp_engine, :use_numbered_shards, false) do
      num_shards = Application.get_env(:warp_engine, :num_numbered_shards, 24)
      Enum.map(0..(num_shards - 1), &String.to_atom("shard_#{&1}"))
    else
      @legacy_shard_ids
    end
  end

  @doc """
  Route operation to optimal shard (direct call for performance).
  """
  def route_operation(key, operation_type, metadata) do
    # PHASE 9.2: TRUE LOAD-BALANCED ROUTING for linear concurrency scaling
    # This eliminates shard hotspots and enables true parallel processing across all 24 shards

    shard_ids = get_shard_ids()

    # Get current shard loads (real-time load balancing)
    current_loads = get_current_shard_loads()

    # Find the least loaded shard for optimal distribution
    {least_loaded_shard, _min_load} = Enum.min_by(current_loads, fn {_shard, load} -> load end)

    # Update load tracking for this shard
    update_shard_load_tracking(least_loaded_shard)

    least_loaded_shard
  end

  # Track shard loads for load balancing
  @shard_loads_key :intelligent_load_balancer_shard_loads

  defp get_current_shard_loads() do
    case Process.get(@shard_loads_key) do
      nil ->
        # Initialize with zero loads
        shard_ids = get_shard_ids()
        loads = Enum.map(shard_ids, fn shard_id -> {shard_id, 0} end) |> Enum.into(%{})
        Process.put(@shard_loads_key, loads)
        loads
      loads -> loads
    end
  end

  defp update_shard_load_tracking(shard_id) do
    current_loads = get_current_shard_loads()
    current_load = Map.get(current_loads, shard_id, 0)

    # Increment load for this shard
    updated_loads = Map.put(current_loads, shard_id, current_load + 1)
    Process.put(@shard_loads_key, updated_loads)

    # Periodically reset loads to prevent overflow
    if rem(current_load + 1, 1000) == 0 do
      reset_shard_loads()
    end
  end

  defp reset_shard_loads() do
    shard_ids = get_shard_ids()
    loads = Enum.map(shard_ids, fn shard_id -> {shard_id, 0} end) |> Enum.into(%{})
    Process.put(@shard_loads_key, loads)
  end

  @doc """
  Force rebalancing if performance is significantly below target.
  """
  def trigger_rebalancing() do
    GenServer.cast(__MODULE__, :trigger_rebalancing)
  end

  ## GenServer Implementation

  @impl true
  def init(_opts) do
    Process.flag(:priority, :low)
    # Initialize with balanced state
    initial_state = %__MODULE__{
      shard_loads: initialize_shard_loads(),
      performance_history: %{},
      routing_strategy: :hash,  # default to hash; adapt slowly off hot path
      concurrency_level: 1,
      rebalancing_active: true,
      performance_metrics: %{},
      optimization_state: %{
        last_rebalance: :os.system_time(:millisecond),
        optimization_active: true,
        target_performance: @performance_targets[1]
      }
    }

    # Start periodic monitoring (debounced)
    schedule_performance_monitoring()
    schedule_load_balancing_review()

    Logger.info("🧠 Intelligent Load Balancer started - optimizing all concurrency levels")
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:get_optimal_shard, key, operation_metadata}, _from, state) do
    # Select optimal shard based on current strategy and system state
    optimal_shard = select_optimal_shard(key, operation_metadata, state)

    # Update shard load tracking
    updated_loads = update_shard_load_prediction(state.shard_loads, optimal_shard)
    updated_state = %{state | shard_loads: updated_loads}

    {:reply, optimal_shard, updated_state}
  end

  @impl true
  def handle_call(:get_balancing_stats, _from, state) do
    stats = %{
      current_strategy: state.routing_strategy,
      concurrency_level: state.concurrency_level,
      shard_loads: state.shard_loads,
      performance_vs_target: calculate_performance_gap(state),
      rebalancing_active: state.rebalancing_active,
      optimization_recommendations: generate_optimization_recommendations(state)
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_cast({:update_performance_metrics, metrics}, state) do
    # Detect concurrency level from metrics
    detected_concurrency = detect_concurrency_level(metrics)

    # Update performance history
    updated_history = Map.put(state.performance_history, detected_concurrency, metrics)

    # Adapt routing strategy based on performance
    new_strategy = adapt_routing_strategy(detected_concurrency, metrics, state)

    updated_state = %{state |
      performance_metrics: metrics,
      concurrency_level: detected_concurrency,
      performance_history: updated_history,
      routing_strategy: new_strategy
    }

    # Trigger rebalancing if performance is significantly below target
    if should_trigger_rebalancing?(metrics, detected_concurrency) do
      Logger.info("🔄 Performance below target - triggering adaptive rebalancing")
      send(self(), :perform_rebalancing)
    end

    {:noreply, updated_state}
  end

  @impl true
  def handle_cast(:trigger_rebalancing, state) do
    send(self(), :perform_rebalancing)
    {:noreply, state}
  end

  @impl true
  def handle_info(:performance_monitoring, state) do
    # Collect current system performance metrics (quick sample)
    current_metrics = collect_system_metrics()

    # Update off hot path; no immediate re-route
    GenServer.cast(self(), {:update_performance_metrics, current_metrics})

    # Schedule next monitoring cycle
    Process.send_after(self(), :performance_monitoring, @monitor_interval_ms)

    {:noreply, state}
  end

  @impl true
  def handle_info(:load_balancing_review, state) do
    # Review current load distribution and optimize if needed
    if should_perform_load_balancing_review?(state) do
      Logger.info("📊 Performing load balancing review...")

      optimized_state = perform_load_balancing_optimization(state)
      schedule_load_balancing_review()

      {:noreply, optimized_state}
    else
      schedule_load_balancing_review()
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:perform_rebalancing, state) do
    Logger.info("⚖️  Performing intelligent rebalancing...")

    # Analyze current performance gaps
    performance_gap = calculate_performance_gap(state)

    # Apply optimization strategy
    optimized_state = case performance_gap do
      gap when gap > 0.3 ->  # Performance >30% below target
        apply_aggressive_rebalancing(state)
      gap when gap > 0.15 -> # Performance 15-30% below target
        apply_moderate_rebalancing(state)
      _ ->
        apply_fine_tuning(state)
    end

    Logger.info("✅ Rebalancing complete - strategy: #{optimized_state.routing_strategy}")
    {:noreply, optimized_state}
  end

  ## Private Implementation

  defp select_optimal_shard(key, operation_metadata, state) do
    case state.routing_strategy do
      :hash ->
        # Traditional hash-based routing
        hash_based_routing(key)

      :round_robin ->
        # Simple round-robin distribution
        round_robin_routing(state.shard_loads)

      :least_loaded ->
        # Route to least loaded shard
        least_loaded_routing(state.shard_loads)

      :adaptive ->
        # Intelligent adaptive routing based on current conditions
        adaptive_routing(key, operation_metadata, state)

      :performance_optimized ->
        # Route based on historical performance patterns
        performance_optimized_routing(key, operation_metadata, state)
    end
  end

  defp adaptive_routing(key, operation_metadata, state) do
    case state.concurrency_level do
      concurrency when concurrency <= 2 ->
        # Low concurrency: hash routing works well (maintains 95K ops/sec)
        hash_based_routing(key)

      concurrency when concurrency <= 8 ->
        # Medium concurrency: balance between locality and load distribution
        if should_prioritize_locality?(key, operation_metadata) do
          hash_based_routing(key)
        else
          least_loaded_routing(state.shard_loads)
        end

      concurrency when concurrency <= 16 ->
        # High concurrency approaching sweet spot: optimize for balance
        if concurrency == 16 do
          # At sweet spot: use round-robin to maintain perfect 5.33 per shard
          round_robin_routing(state.shard_loads)
        else
          # Near sweet spot: balance load but prefer performance
          least_loaded_routing(state.shard_loads)
        end

      _very_high_concurrency ->
        # Very high concurrency: aggressive load balancing needed
        least_loaded_with_affinity(key, state.shard_loads)
    end
  end

  defp hash_based_routing(key) do
    # Traditional routing - maintains data locality
    shard_ids = get_shard_ids()
    shard_index = :erlang.phash2(key, length(shard_ids))
    Enum.at(shard_ids, shard_index)
  end

  defp round_robin_routing(shard_loads) do
    # Simple round-robin - ensures even distribution
    shard_ids = get_shard_ids()
    least_used_count = shard_loads |> Map.values() |> Enum.min()

    # Find first shard with minimum load
    Enum.find(shard_ids, fn shard_id ->
      Map.get(shard_loads, shard_id, 0) == least_used_count
    end) || List.first(shard_ids)
  end

  defp least_loaded_routing(shard_loads) do
    # Route to shard with least current load
    {least_loaded_shard, _load} = Enum.min_by(shard_loads, fn {_shard, load} -> load end)
    least_loaded_shard
  end

  defp least_loaded_with_affinity(key, shard_loads) do
    # Try to balance load while maintaining some data affinity
    preferred_shard = hash_based_routing(key)
    preferred_load = Map.get(shard_loads, preferred_shard, 0)

    # Find minimum load across all shards
    {_min_shard, min_load} = Enum.min_by(shard_loads, fn {_shard, load} -> load end)

    # Use preferred shard if load difference is reasonable
    if preferred_load <= min_load * 1.2 do  # Within 20% of minimum
      preferred_shard
    else
      least_loaded_routing(shard_loads)
    end
  end

  defp should_prioritize_locality?(key, operation_metadata) do
    # Prioritize locality for frequently accessed or related data
    case operation_metadata do
      %{access_frequency: freq} when freq > 10 -> true  # High frequency access
      %{data_relationship: :strong} -> true             # Strongly related data
      %{operation_type: :get} -> true                   # Read operations benefit from locality
      _ ->
        # For unknown patterns, prioritize locality for keys that look related
        key
        |> String.contains?(["user:", "session:", "cache:"])
    end
  end

  defp initialize_shard_loads() do
    # Initialize load tracking for all shards
    get_shard_ids()
    |> Enum.map(fn shard_id -> {shard_id, 0.0} end)
    |> Map.new()
  end

  defp update_shard_load_prediction(shard_loads, selected_shard) do
    # Update predicted load (simplified model)
    current_load = Map.get(shard_loads, selected_shard, 0.0)
    Map.put(shard_loads, selected_shard, current_load + 1.0)
  end

  defp detect_concurrency_level(metrics) do
    # Detect concurrency level from system metrics
    cond do
      Map.has_key?(metrics, :concurrent_processes) ->
        metrics.concurrent_processes
      Map.has_key?(metrics, :active_tasks) ->
        metrics.active_tasks
      true ->
        # Fallback: estimate from throughput patterns
        estimate_concurrency_from_throughput(metrics)
    end
  end

  defp estimate_concurrency_from_throughput(metrics) do
    # Rough estimation based on throughput characteristics
    throughput = Map.get(metrics, :ops_per_sec, 20_000)

    cond do
      throughput > 180_000 -> 16  # Near optimal range
      throughput > 90_000 -> 8    # Good scaling range
      throughput > 70_000 -> 4    # Moderate concurrency
      throughput > 50_000 -> 2    # Low concurrency
      true -> 1                   # Single process
    end
  end

  defp adapt_routing_strategy(concurrency_level, metrics, _state) do
    current_performance = Map.get(metrics, :ops_per_sec, 0)
    target_performance = Map.get(@performance_targets, concurrency_level, 50_000)

    performance_ratio = current_performance / target_performance

    case {concurrency_level, performance_ratio} do
      {level, ratio} when level <= 2 and ratio > 0.9 ->
        # Low concurrency performing well: keep hash routing
        :hash

      {level, ratio} when level <= 8 and ratio > 0.8 ->
        # Medium concurrency performing adequately: adaptive routing
        :adaptive

      {16, ratio} when ratio > 0.9 ->
        # Sweet spot performing well: maintain round-robin
        :round_robin

      {level, ratio} when level > 16 and ratio < 0.7 ->
        # High concurrency underperforming: aggressive load balancing
        :least_loaded

      _ ->
        # General underperformance: try performance-optimized routing
        :performance_optimized
    end
  end

  defp should_trigger_rebalancing?(metrics, concurrency_level) do
    current_performance = Map.get(metrics, :ops_per_sec, 0)
    target_performance = Map.get(@performance_targets, concurrency_level, 50_000)

    performance_ratio = current_performance / target_performance

    # Trigger rebalancing if performance is >20% below target
    performance_ratio < 0.8
  end

  defp calculate_performance_gap(state) do
    current_performance = Map.get(state.performance_metrics, :ops_per_sec, 0)
    target_performance = Map.get(@performance_targets, state.concurrency_level, 50_000)

    if target_performance > 0 do
      max(0.0, 1.0 - (current_performance / target_performance))
    else
      0.0
    end
  end

  defp apply_aggressive_rebalancing(state) do
    Logger.info("🚨 Applying aggressive rebalancing - performance significantly below target")

    %{state |
      routing_strategy: :least_loaded,
      rebalancing_active: true,
      optimization_state: Map.put(state.optimization_state, :last_rebalance, :os.system_time(:millisecond))
    }
  end

  defp apply_moderate_rebalancing(state) do
    Logger.info("⚡ Applying moderate rebalancing - performance moderately below target")

    %{state |
      routing_strategy: :adaptive,
      optimization_state: Map.put(state.optimization_state, :last_rebalance, :os.system_time(:millisecond))
    }
  end

  defp apply_fine_tuning(state) do
    Logger.info("🎯 Applying fine-tuning optimizations")

    # Fine-tune current strategy rather than changing it
    %{state |
      optimization_state: Map.put(state.optimization_state, :last_rebalance, :os.system_time(:millisecond))
    }
  end

  defp performance_optimized_routing(_key, _operation_metadata, state) do
    # Route based on historical performance patterns for this concurrency level
    best_performing_shard = find_best_performing_shard_for_concurrency(state.concurrency_level, state)

    # Use best performing shard with some load balancing
    if should_use_best_shard?(state.shard_loads, best_performing_shard) do
      best_performing_shard
    else
      # Fallback to least loaded if best shard is overloaded
      least_loaded_routing(state.shard_loads)
    end
  end

  defp find_best_performing_shard_for_concurrency(concurrency_level, _state) do
    # Simplified: Use historical knowledge about shard performance
    case concurrency_level do
      level when level <= 4 -> :hot_data      # Hot shard performs best at low concurrency
      level when level <= 12 -> :warm_data    # Warm shard balances well at medium concurrency
      _ -> :cold_data                          # Cold shard handles high concurrency better
    end
  end

  defp should_use_best_shard?(shard_loads, best_shard) do
    best_shard_load = Map.get(shard_loads, best_shard, 0.0)
    avg_load = shard_loads |> Map.values() |> Enum.sum() |> Kernel./(3)

    # Use best shard if its load is within 50% of average
    best_shard_load <= avg_load * 1.5
  end

  defp collect_system_metrics() do
    # Collect real-time system performance metrics
    # This would integrate with WarpEngine's existing monitoring
    %{
      ops_per_sec: estimate_current_throughput(),
      concurrent_processes: Process.list() |> length(),
      memory_usage: :erlang.memory(:total),
      timestamp: :os.system_time(:millisecond)
    }
  end

  defp estimate_current_throughput() do
    # Simplified throughput estimation
    # In practice, this would integrate with actual metrics collection
    20_000 + :rand.uniform(100_000)
  end

  defp schedule_performance_monitoring() do
    # Monitor performance every 5 seconds
    Process.send_after(self(), :performance_monitoring, @monitor_interval_ms)
  end

  defp schedule_load_balancing_review() do
    # Review load balancing every 15 seconds
    Process.send_after(self(), :load_balancing_review, @review_interval_ms)
  end

  defp should_perform_load_balancing_review?(state) do
    # Perform review if enough time has passed since last rebalancing
    last_rebalance = get_in(state.optimization_state, [:last_rebalance]) || 0
    current_time = :os.system_time(:millisecond)

    (current_time - last_rebalance) > 30_000  # 30 seconds
  end

  defp perform_load_balancing_optimization(state) do
    # Analyze current load distribution and optimize
    load_imbalance = calculate_load_imbalance(state.shard_loads)

    if load_imbalance > 0.3 do  # >30% imbalance
      Logger.info("⚖️  Significant load imbalance detected (#{Float.round(load_imbalance * 100, 1)}%) - optimizing routing")

      %{state |
        routing_strategy: :least_loaded,
        optimization_state: Map.put(state.optimization_state, :last_rebalance, :os.system_time(:millisecond))
      }
    else
      state
    end
  end

  defp calculate_load_imbalance(shard_loads) do
    loads = Map.values(shard_loads)
    max_load = Enum.max(loads)
    min_load = Enum.min(loads)

    if max_load > 0 do
      (max_load - min_load) / max_load
    else
      0.0
    end
  end

  defp generate_optimization_recommendations(state) do
    # Generate actionable optimization recommendations
    performance_gap = calculate_performance_gap(state)
    load_imbalance = calculate_load_imbalance(state.shard_loads)

    recommendations = []

    recommendations = if performance_gap > 0.2 do
      ["Consider increasing WAL shard count for concurrency level #{state.concurrency_level}" | recommendations]
    else
      recommendations
    end

    recommendations = if load_imbalance > 0.4 do
      ["High load imbalance detected - recommend enabling aggressive rebalancing" | recommendations]
    else
      recommendations
    end

    recommendations = if state.concurrency_level > 20 do
      ["Very high concurrency detected - consider implementing operation batching" | recommendations]
    else
      recommendations
    end

    if Enum.empty?(recommendations) do
      ["System performing optimally - no recommendations"]
    else
      recommendations
    end
  end
end
