# WarpEngine Database

A high-performance Elixir key-value database with creative physics-inspired optimizations and intelligent caching.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![Elixir Version](https://img.shields.io/badge/elixir-1.15+-blue.svg)]()
[![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-175%20passing-brightgreen.svg)]()

**Performance**: 300K–650K ops/sec (median), 500K+ peak (short steady-state)
**Architecture**: Intelligent caching, adaptive sharding, predictive loading
**Zero-Tuning**: Self-optimizing system that adapts to workload patterns

## Overview

WarpEngine is an Elixir-based key-value database that combines solid engineering with creative optimization techniques inspired by physics concepts. It provides high-performance data storage with intelligent caching, adaptive sharding, and predictive data loading.

**Key Features:**
- **High Performance**: 300K–650K ops/sec median with 500K+ peak (laptop, short windows)
- **Intelligent Caching**: Predictive prefetching based on access pattern analysis  
- **Adaptive Sharding**: Locality-aware data placement that improves over time
- **Pattern Learning**: Automatically learns data relationships for optimization
- **Zero-Tuning**: Self-optimizing system that adapts to workload patterns
- **Production Ready**: Write-ahead logging, crash recovery, comprehensive test suite

## Performance Characteristics

**Latest Concurrency Scaling (Dell PX13 / WSL, warmup 2s, measure 1.5s, trials 5):**

| Processes | Median ops/sec | Best ops/sec |
|-----------|----------------|--------------|
| 1         | 194,533        | 204,600      |
| 2         | 357,000        | 376,000      |
| 3         | 508,600        | 517,866      |
| 4         | 637,400        | 647,266      |

Notes:
- Benchmarks reflect short steady-state windows to avoid OS memory interference under WSL.
- Longer sweeps are possible with tighter memory caps (bounded keysets, periodic WAL flushes, and sampling).

**Why the improvement?**
- Per-shard WAL (24 shards) eliminated the single-GenServer bottleneck.
- Ultra-minimal WAL format (binary, essential fields only) with iodata writes.
- Buffered raw I/O with jittered flushing, hard buffer caps, and shard pinning.

## Architecture

WarpEngine uses creative terminology for standard database optimization techniques:

### "Quantum Entanglement" (Intelligent Prefetching)
Automatically learns which data items are frequently accessed together and prefetches related data in parallel:

```elixir
# When you access a user, related profile and settings are automatically prefetched
{:ok, user, quantum_data} = WarpEngine.quantum_get("user:alice")
# quantum_data contains prefetched profile:alice, settings:alice, etc.
```

### "Gravitational Routing" (Locality-Aware Sharding)  
Data placement algorithm that considers access patterns and data relationships:

```elixir
# Hot, frequently-accessed data goes to high-performance shards
WarpEngine.cosmic_put("trending:post:123", post_data, access_pattern: :hot)

# Cold, archived data goes to compressed storage shards  
WarpEngine.cosmic_put("archive:2020:data", old_data, access_pattern: :cold)
```

### "Event Horizon Cache" (Multi-Level Caching)
Hierarchical caching system with intelligent eviction:
- **Hot Cache**: Frequently accessed data
- **Warm Cache**: Moderately accessed data  
- **Cold Cache**: Infrequently accessed data
- **Deep Cache**: Compressed long-term storage

### "Entropy Monitoring" (Statistical Load Balancing)
Uses Shannon entropy calculations to detect load imbalances and trigger automatic rebalancing.

## Quick Start

### Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:warp_engine, "~> 1.0"},
    {:jason, "~> 1.4"}
  ]
end
```

### Basic Usage

```elixir
# Start WarpEngine
{:ok, _pid} = WarpEngine.start_link()

# Store data with automatic optimization
{:ok, :stored, shard, time} = WarpEngine.cosmic_put("user:alice", %{
  name: "Alice Johnson", 
  email: "alice@example.com"
})

# Retrieve data with potential prefetching
{:ok, user_data, shard, time} = WarpEngine.cosmic_get("user:alice")

# Get performance metrics
metrics = WarpEngine.cosmic_metrics()
```

### Advanced Operations

```elixir
# Intelligent prefetching with quantum entanglement
{:ok, response} = WarpEngine.quantum_get("user:alice")
# Automatically prefetches related data based on learned patterns

# Create custom entanglement relationships  
WarpEngine.create_quantum_entanglement("user:alice", 
  ["profile:alice", "settings:alice"], 0.9)

# Monitor system performance and entropy
metrics = WarpEngine.cosmic_metrics()
entropy = WarpEngine.entropy_metrics()

# Manually trigger system optimization
WarpEngine.trigger_entropy_rebalancing(force_rebalancing: true)
```

## Configuration

```elixir
config :warp_engine,
  # Data storage location
  data_root: "/path/to/data",
  
  # Enable optimizations
  enable_quantum_entanglement: true,    # Intelligent prefetching
  enable_gravitational_routing: true,   # Locality-aware sharding
  enable_event_horizon_cache: true,     # Multi-level caching
  enable_entropy_monitoring: true,      # Load balancing
  
  # Dynamic shard topology (per-machine)
  # Enable numbered shards and size to cores for max throughput
  use_numbered_shards: true,
  num_numbered_shards: System.schedulers_online(),

  # Benchmark knobs
  bench_mode: false,                 # Set true to skip non-essential work
  enable_auto_entanglement: true,    # Disable for pure-write benches
  wal_sample_rate: 1                 # Increase (e.g., 4/8/16) to reduce WAL I/O during long runs

  # Prefetch patterns
  entanglement_rules: [
    {"user:*", ["profile:*", "settings:*"]},
    {"order:*", ["customer:*", "products:*"]},
    {"post:*", ["author:*", "comments:*"]}
  ]
```

## What Makes WarpEngine Different

WarpEngine combines traditional high-performance data structures (ETS tables) with **actual physics-inspired algorithms** for intelligent optimization:

### Real Physics-Based Optimization (Not Just Metaphors)
- **Gravitational Shard Routing**: Uses actual gravitational formulas (G·m₁·m₂/r²) to calculate optimal data placement based on "data mass" and access patterns
- **Entropy-Based Load Balancing**: Employs Shannon entropy calculations and Boltzmann equations to detect system imbalances and trigger rebalancing
- **Multi-Dimensional Data Coordinates**: Places data in calculated cosmic coordinates using trigonometric functions for spatial optimization
- **Quantum Energy Levels**: Uses Planck's equation (E=hf) to assign energy levels based on access frequency

### Hybrid Architecture Advantage  
- **Fast Path**: ETS table lookups for maximum performance (8M+ ops/sec capability)
- **Smart Path**: Physics calculations guide data placement, migration, and optimization decisions
- **Result**: Combines the speed of hash tables with the intelligence of physics-based optimization

### Production Features
- **Write-Ahead Logging**: Crash recovery and durability guarantees
- **Comprehensive Testing**: 175+ tests covering all functionality
- **Elixir/OTP Integration**: Built on battle-tested Erlang VM
- **Monitoring**: Built-in metrics and performance tracking
- **Self-Optimization**: Adapts to workload patterns without manual tuning

## Technical Architecture: Physics + Performance

**WarpEngine is NOT a replacement for hash tables** - it's an intelligent layer on top of them:

```elixir
# 1. FAST PATH: Standard ETS hash table lookup (microseconds)
case :ets.lookup(shard.ets_table, key) do
  [{^key, value}] -> {:ok, value}
end

# 2. SMART PATH: Physics calculations for optimization (background)
def calculate_gravitational_score(shard, key, value) do
  data_mass = calculate_data_mass(key, value)  
  shard_mass = shard.physics_laws.gravitational_mass
  # Real gravitational formula: 
  CosmicConstants.gravitational_attraction(data_mass, shard_mass, 1.0)
end
```

**The Innovation**: While other databases use simple hashing or round-robin for data placement, WarpEngine uses **actual physics equations** to make smarter decisions about where data should live, when it should migrate, and how the system should rebalance.

## Use Cases

### Well-Suited For:
- **Applications with Predictable Access Patterns**: Where related data is frequently accessed together
- **Caching-Heavy Workloads**: Intelligent prefetching improves performance significantly
- **Multi-tenant Systems**: Locality-aware sharding helps organize tenant data
- **Key-Value + Relationships**: When you need both fast lookups and data relationships
- **Self-Optimizing Systems**: Applications that benefit from automatic performance tuning

### Considerations:
- **Dataset Size**: Optimized for datasets up to ~1M records
- **Access Patterns**: Works best with predictable, pattern-heavy workloads
- **Hardware**: Single-node focused (not distributed)
- **Ecosystem**: Best for Elixir/Erlang applications

## Graph Database Example

While WarpEngine core is a key-value database, a graph database example is available that demonstrates how to build graph operations on top of WarpEngine:

```bash
# Explore the graph database implementation built on WarpEngine
mix run examples/weighted_graph_database.ex
```

The example provides graph operations like `store_node/1`, `store_edge/1`, `traverse_graph/3`, and `generate_recommendations/2`.

## Benchmarking

Run performance tests:

```bash
# Simple baseline
mix run simple_benchmark.exs

# Concurrency sweep (warmup + steady-state): prints best/median/p50/p90
mix run benchmarks/optimal_concurrency_test
mix run benchmarks/concurrency_sweep_heavy.exs

# Concurrency sweep with settings and output to filesystem
WAL_SAMPLE_RATE=16 KEYSET=500 CONC="1,2,3,4" TRIALS=5 MEASURE_MS=1500 OPS=100 MIX_ENV=prod mix run benchmarks/optimal_concurrency_test.exs &> benchmarks/optimal_concurrency_test.txt 
CONC="1,2,3,4" KEYSET=10000 TRIALS=2 WARMUPS=1 MEASURE_MS=3000 SHARDS=24 mix run benchmarks/concurrency_sweep_heavy.exs &> benchmarks/concurrency_sweep_heavy.txt

# general benchmark
mix run benchmarks/working_benchmark.exs &> benchmarks/working_benchmark.txt

# Multi-core scaling (additional scenarios)
mix run multi_core_benchmark.exs

# Graph database comparison (uses the example implementation)
mix run benchmarks/simple_weighted_graph_benchmark.exs
```

## Testing

```bash
mix test                    # Run all 175+ tests
mix test --max-cases 1      # Run tests sequentially
```

## Documentation

- [Architecture Overview](docs/complete-roadmap.md)
- [Performance Analysis](benchmarks/PERFORMANCE_REVIEW_vs_GRAPH_DATABASES.md) 
- [Configuration Guide](docs/phase1-quick-start.md)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `mix test`
5. Submit a pull request

## License

Apache License 2.0 - see [LICENSE](LICENSE) file.

## About

WarpEngine represents a creative approach to database optimization, using physics-inspired metaphors for well-known techniques like intelligent caching, locality-aware sharding, and statistical load balancing. While the terminology is unconventional, the underlying optimizations are sound and provide measurable performance benefits.

Built with Elixir/OTP for reliability and performance on the Erlang VM.

---

**Note**: While WarpEngine uses physics-inspired terminology, it implements **actual physics calculations** (gravitational formulas, entropy equations, energy levels) for intelligent data optimization. The "physics" are real mathematical formulas applied to database optimization, not just creative metaphors. The core storage still uses proven ETS hash tables for maximum performance.
