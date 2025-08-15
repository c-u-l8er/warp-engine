#!/usr/bin/env elixir

# Phase 5: Entropy Monitoring & Thermodynamics - Clean Demo
#
# A clean, simple demonstration of Phase 5 entropy monitoring features

# Set up the application
Application.put_env(:islab_db, :data_root, Path.expand("data", __DIR__))
Application.ensure_all_started(:islab_db)

defmodule Phase5CleanDemo do
  @moduledoc """
  Clean demonstration of Phase 5: Entropy Monitoring & Thermodynamics features.
  """

  require Logger
  alias IsLabDB

  def run_demo() do
    print_header()
    cleanup_existing_system()

    demo_entropy_startup()
    demo_shannon_calculations()
    demo_thermodynamic_balancing()
    demo_maxwell_demon()
    demo_system_cleanup()

    print_conclusion()
  end

  defp print_header() do
    IO.puts("""

    🌡️  ═══════════════════════════════════════════════════════════════
    🌌  IsLab Database - Phase 5: Entropy Monitoring Demo (Clean)
    🌡️  ═══════════════════════════════════════════════════════════════

    Welcome to a clean demonstration of advanced entropy monitoring!

    Key Features:
    • Real-time Shannon entropy calculations
    • Thermodynamic load balancing
    • Maxwell's demon optimization
    • Cosmic analytics

    ═══════════════════════════════════════════════════════════════
    """)

    Process.sleep(1000)
  end

  defp cleanup_existing_system() do
    IO.puts("🧹 Cleaning up any existing IsLab Database instances...")

    # Try to stop main process
    case GenServer.whereis(IsLabDB) do
      pid when is_pid(pid) ->
        try do
          GenServer.stop(IsLabDB, :normal, 2000)
        catch
          :exit, _ -> :ok
        end
      nil -> :ok
    end

    # Try to stop entropy registry if it exists
    case GenServer.whereis(IsLabDB.EntropyRegistry) do
      pid when is_pid(pid) ->
        try do
          GenServer.stop(IsLabDB.EntropyRegistry, :normal, 1000)
        catch
          :exit, _ -> :ok
        end
      nil -> :ok
    end

    Process.sleep(500)
    IO.puts("   ✅ System cleanup complete")
  end

  defp demo_entropy_startup() do
    section_header("🌡️  Phase 5 Entropy System Status")

    IO.puts("IsLab Database is running with Phase 5 entropy monitoring!")
    IO.puts("🌡️  Phase 5: Entropy Monitoring - ACTIVE")
    IO.puts("")

    # Allow system to stabilize
    Process.sleep(2000)

    # Show initial metrics
    metrics = IsLabDB.cosmic_metrics()
    entropy_data = metrics.entropy_monitoring

    IO.puts("📊 Current System Status:")
    IO.puts("   • Monitor Active: #{entropy_data.monitor_active}")
    IO.puts("   • Current Phase: #{metrics.phase}")
    IO.puts("   • Total Entropy: #{Float.round(entropy_data.total_entropy, 3)}")
    IO.puts("   • Shannon Entropy: #{Float.round(entropy_data.shannon_entropy, 3)} bits")
    IO.puts("   • System Temperature: #{Float.round(entropy_data.system_temperature, 2)} K")
    IO.puts("   • Stability Metric: #{Float.round(entropy_data.stability_metric, 3)}")
    IO.puts("")

    wait_for_user()
  end

  defp demo_shannon_calculations() do
    section_header("🔢 Shannon Entropy Calculations")

    IO.puts("Creating diverse data to demonstrate entropy calculations...")
    IO.puts("Shannon entropy: H(X) = -Σ p(x) log₂ p(x)")
    IO.puts("")

    # Create test data with different entropy patterns
    IO.puts("📝 Storing test data across shards...")

    # Hot data (low entropy - clustered)
    _hot_keys = 1..15 |> Enum.map(fn i ->
      key = "hot:session:#{i}"
      value = %{
        user_id: "user_#{rem(i, 3)}", # Only 3 different users (clustered)
        session_id: "session_#{i}",
        timestamp: :os.system_time(:millisecond)
      }
      {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put(key, value, access_pattern: :hot)
      key
    end)

    # Warm data (medium entropy - more distributed)
    _warm_keys = 1..10 |> Enum.map(fn i ->
      key = "warm:product:#{i}"
      value = %{
        product_id: "prod_#{i}",
        category: Enum.random(["electronics", "books", "clothing", "home"]),
        price: :rand.uniform(1000) + 10.99
      }
      {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put(key, value, access_pattern: :warm)
      key
    end)

    # Cold data (high entropy - uniform distribution)
    _cold_keys = 1..8 |> Enum.map(fn i ->
      key = "cold:archive:#{i}"
      value = %{
        archive_id: "archive_#{i}",
        data: :crypto.strong_rand_bytes(50),
        created: :os.system_time(:millisecond) - (i * 86400 * 1000)
      }
      {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put(key, value, access_pattern: :cold)
      key
    end)

    IO.puts("   ✅ Stored 33 items:")
    IO.puts("      • 15 hot items (clustered users - low entropy)")
    IO.puts("      • 10 warm items (diverse categories - medium entropy)")
    IO.puts("      • 8 cold items (uniform distribution - high entropy)")
    IO.puts("")

    # Wait for entropy analysis
    Process.sleep(4000)

    # Get entropy results
    entropy_metrics = IsLabDB.entropy_metrics()

    IO.puts("📊 Shannon Entropy Analysis:")
    IO.puts("   • Total System Entropy: #{Float.round(entropy_metrics.total_entropy, 4)} bits")
    IO.puts("   • Shannon Component: #{Float.round(entropy_metrics.shannon_entropy, 4)} bits")
    IO.puts("   • Thermodynamic Component: #{Float.round(entropy_metrics.thermodynamic_entropy, 4)}")
    IO.puts("   • Entropy Trend: #{entropy_metrics.entropy_trend}")
    IO.puts("   • Information Efficiency: #{Float.round((4.0 - entropy_metrics.shannon_entropy) / 4.0 * 100, 1)}%")
    IO.puts("")

    wait_for_user()
  end

  defp demo_thermodynamic_balancing() do
    section_header("⚖️  Thermodynamic Load Balancing")

    IO.puts("Demonstrating automatic load balancing based on entropy thresholds...")
    IO.puts("")

    # Get current state
    before_metrics = IsLabDB.entropy_metrics()
    IO.puts("📊 Current State:")
    IO.puts("   • Total Entropy: #{Float.round(before_metrics.total_entropy, 3)}")
    IO.puts("   • Rebalancing Recommended: #{before_metrics.rebalancing_recommended}")
    IO.puts("   • System Temperature: #{Float.round(before_metrics.system_temperature, 2)} K")
    IO.puts("")

    # Create load imbalance
    IO.puts("🔧 Creating intentional load imbalance...")

    _heavy_keys = 1..20 |> Enum.map(fn i ->
      key = "overload:batch:#{i}"
      value = %{
        batch_id: i,
        data: :crypto.strong_rand_bytes(100),
        priority: :high,
        created_at: :os.system_time(:millisecond)
      }
      {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put(key, value, access_pattern: :hot, priority: :critical)
      key
    end)

    IO.puts("   ✅ Added 20 heavy items to create imbalance")
    Process.sleep(3000)

    # Check entropy increase
    overload_metrics = IsLabDB.entropy_metrics()
    IO.puts("")
    IO.puts("📊 After Creating Imbalance:")
    IO.puts("   • Total Entropy: #{Float.round(overload_metrics.total_entropy, 3)}")
    IO.puts("   • Entropy Change: #{Float.round(overload_metrics.total_entropy - before_metrics.total_entropy, 3)}")
    IO.puts("   • Rebalancing Recommended: #{overload_metrics.rebalancing_recommended}")
    IO.puts("")

    # Trigger rebalancing
    IO.puts("🌡️  Triggering thermodynamic rebalancing...")

    {:ok, rebalance_report} = IsLabDB.trigger_entropy_rebalancing(
      force_rebalancing: true,
      migration_strategy: :moderate
    )

    IO.puts("   ✅ Rebalancing completed!")
    IO.puts("")
    IO.puts("📈 Rebalancing Report:")
    IO.puts("   • Strategy: #{rebalance_report.strategy}")
    IO.puts("   • Items Moved: #{rebalance_report.data_items_moved}")
    IO.puts("   • Shards Affected: #{rebalance_report.shards_affected}")
    IO.puts("   • Entropy Reduction: #{Float.round(rebalance_report.initial_entropy - rebalance_report.final_entropy, 3)}")
    IO.puts("   • Energy Cost: #{rebalance_report.energy_cost}")
    IO.puts("   • Time Taken: #{rebalance_report.time_taken_ms} ms")
    IO.puts("")

    wait_for_user()
  end

  defp demo_maxwell_demon() do
    section_header("👹 Maxwell's Demon Optimization")

    IO.puts("Maxwell's demon makes intelligent decisions to reduce system entropy...")
    IO.puts("Testing different optimization strategies...")
    IO.puts("")

    # Show initial state
    initial_metrics = IsLabDB.entropy_metrics()
    IO.puts("📊 Initial Entropy State:")
    IO.puts("   • Total Entropy: #{Float.round(initial_metrics.total_entropy, 3)}")
    IO.puts("   • Disorder Index: #{Float.round(initial_metrics.disorder_index, 3)}")
    IO.puts("")

    # Create optimization scenarios
    IO.puts("🧠 Creating optimization scenarios for Maxwell's demon...")

    # Related data that should be co-located
    _user_data = ["alice", "bob", "charlie"] |> Enum.map(fn user ->
      IsLabDB.cosmic_put("user:#{user}", %{name: user, type: :user})
      IsLabDB.cosmic_put("profile:#{user}", %{user: user, details: "Profile"})
      IsLabDB.cosmic_put("settings:#{user}", %{user: user, preferences: %{}})
      user
    end)

    # Temporal data with aging patterns
    _temporal_data = 1..10 |> Enum.map(fn i ->
      age_days = i * 2
      timestamp = :os.system_time(:millisecond) - (age_days * 86400 * 1000)

      key = "temporal:event:#{i}"
      value = %{
        event_id: i,
        timestamp: timestamp,
        age_days: age_days,
        importance: if(age_days < 7, do: :high, else: :low)
      }
      {:ok, :stored, _shard, _time} = IsLabDB.cosmic_put(key, value)
      key
    end)

    IO.puts("   ✅ Created optimization scenarios:")
    IO.puts("      • 3 users with related profile/settings data")
    IO.puts("      • 10 temporal events with aging patterns")
    IO.puts("")

    Process.sleep(2000)

    # Test different strategies
    IO.puts("👹 Activating Maxwell's demon with different strategies...")

    strategies = [:minimal, :moderate]
    demon_results = Enum.map(strategies, fn strategy ->
      IO.puts("   Testing #{strategy} strategy...")

      {:ok, result} = IsLabDB.trigger_entropy_rebalancing(
        force_rebalancing: true,
        migration_strategy: strategy
      )

      IO.puts("      • #{strategy}: #{result.data_items_moved} items moved, energy: #{result.energy_cost}")
      {strategy, result}
    end)

    IO.puts("")
    IO.puts("🎯 Maxwell's Demon Results:")

    Enum.each(demon_results, fn {strategy, result} ->
      efficiency = result.data_items_moved / max(result.energy_cost, 1)
      entropy_reduction = result.initial_entropy - result.final_entropy

      IO.puts("   • #{String.capitalize(to_string(strategy))}:")
      IO.puts("     - Data Efficiency: #{Float.round(efficiency, 2)} items/energy")
      IO.puts("     - Entropy Reduction: #{Float.round(entropy_reduction, 3)}")
    end)

    IO.puts("")
    wait_for_user()
  end

  defp demo_system_cleanup() do
    IO.puts("🧹 Demonstrating graceful system shutdown...")

    # Stop main process
    case GenServer.whereis(IsLabDB) do
      pid when is_pid(pid) ->
        try do
          GenServer.stop(IsLabDB, :normal, 5000)
        catch
          :exit, _ -> :ok
        end
      nil -> :ok
    end

    # Stop entropy registry if it exists
    case GenServer.whereis(IsLabDB.EntropyRegistry) do
      pid when is_pid(pid) ->
        try do
          GenServer.stop(IsLabDB.EntropyRegistry, :normal, 2000)
        catch
          :exit, _ -> :ok
        end
      nil -> :ok
    end

    IO.puts("   ✅ IsLab Database universe safely shut down")
    IO.puts("")
  end

  defp print_conclusion() do
    IO.puts("""

    🌡️  ═══════════════════════════════════════════════════════════════
    🎉  Phase 5 Entropy Monitoring Demo Complete!
    🌡️  ═══════════════════════════════════════════════════════════════

    Successfully demonstrated:

    🔬 SHANNON ENTROPY ENGINE
    • Real-time entropy calculations across data shards
    • Information-theoretic analysis of data distribution

    ⚖️  THERMODYNAMIC LOAD BALANCING
    • Automatic rebalancing triggered by entropy thresholds
    • Zero-downtime migration with entropy reduction

    👹 MAXWELL'S DEMON OPTIMIZATION
    • Intelligent data placement decisions
    • Multiple optimization strategies tested

    📊 SYSTEM ANALYTICS
    • Real-time entropy monitoring and trend analysis
    • Performance metrics and efficiency calculations

    The computational universe thanks you for exploring Phase 5! 🌌✨

    ═══════════════════════════════════════════════════════════════
    """)
  end

  # Helper functions
  defp section_header(title) do
    IO.puts("""

    ═══════════════════════════════════════════════════════════════
    #{title}
    ═══════════════════════════════════════════════════════════════
    """)
  end

  defp wait_for_user() do
    IO.puts("Press Enter to continue...")
    IO.read(:line)
  end
end

# Run the clean Phase 5 demo
Phase5CleanDemo.run_demo()
