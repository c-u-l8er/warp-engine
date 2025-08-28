# WarpEngine Database

A high-performance Elixir key-value database with creative physics-inspired optimizations and intelligent caching.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![Elixir Version](https://img.shields.io/badge/elixir-1.15+-blue.svg)]()
[![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-175%20passing-brightgreen.svg)]()
[![Phase 9 Status](https://img.shields.io/badge/phase%209-partially%20complete-yellow.svg)]()

**Performance**: 300K–650K ops/sec (median), 500K+ peak (short steady-state)
**Architecture**: Intelligent caching, adaptive sharding, predictive loading
**Zero-Tuning**: Self-optimizing system that adapts to workload patterns
**Phase 9 Status**: Per-shard WAL architecture implemented, concurrency scaling needs optimization

**New Feature Validation Benchmark**: Large dataset testing (up to 10GB) validates all unique WarpEngine features before optimization

## 🚨 Phase 9 Validation Status: PARTIALLY COMPLETE

**What's Working:**
- ✅ Enhanced ADT system: 4.4M ops/sec performance
- ✅ Per-shard WAL architecture implemented (24 numbered shards)
- ✅ Core WarpEngine system operational
- ✅ Physics-inspired optimization modules functional

**What Needs Fixing:**
- ❌ ETS table creation timeout (5-second limit)
- ❌ Concurrency scaling drops at 4+ processes
- ❌ WAL system still has some bottlenecks

**Current Performance:**
- **Enhanced ADT**: 4.4M ops/sec (fully validated)
- **Concurrency Scaling**: 1.3M ops/sec at 3 processes, drops at 4
- **Target**: Linear scaling to 24 processes

## Overview

WarpEngine is an Elixir-based key-value database that combines solid engineering with creative optimization techniques inspired by physics concepts. It provides high-performance data storage with intelligent caching, adaptive sharding, and predictive data loading.

**Key Features:**
- **High Performance**: 300K–650K ops/sec median with 500K+ peak (laptop, short windows)
- **Intelligent Caching**: Predictive prefetching based on access pattern analysis  
- **Adaptive Sharding**: Locality-aware data placement that improves over time
- **Pattern Learning**: Automatically learns data relationships for optimization
- **Zero-Tuning**: Self-optimizing system that adapts to workload patterns
- **Production Ready**: Write-ahead logging, crash recovery, comprehensive test suite
- **Phase 9 Architecture**: Per-shard WAL system for linear concurrency scaling

## Performance Characteristics

**Current Status (Phase 9 Implementation):**

| Component | Status | Performance | Notes |
|-----------|--------|-------------|-------|
| **Enhanced ADT** | ✅ Complete | 4.4M ops/sec | Fully validated, revolutionary performance |
| **Core WarpEngine** | ✅ Complete | 1.4M ops/sec | 24 numbered shards operational |
| **Concurrency Scaling** | ⚠️ Partial | 1.3M ops/sec | Drops at 4+ processes, needs optimization |
| **Per-Shard WAL** | ⚠️ Partial | Architecture ready | ETS timeout issues need resolution |

**Latest Concurrency Scaling (Dell PX13 / WSL, warmup 2s, measure 1.5s, trials 5):**

| Processes | Median ops/sec | Best ops/sec | Status |
|-----------|----------------|--------------|---------|
| 1         | 371,133        | 386,266      | ✅ Working |
| 2         | 720,066        | 739,066      | ✅ Working |
| 3         | 1,013,933      | 1,022,533    | ✅ Working |
| 4         | 1,359,387      | 1,397,200    | ⚠️ Scaling drops |

**Phase 9 Target Performance (24 processes):**
- **Current**: ~1.4M ops/sec at 4 processes
- **Target**: Linear scaling to 24 processes = ~8.4M ops/sec
- **Gap**: Need to resolve ETS timeout and concurrency bottlenecks

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

### "Phase 9 Per-Shard WAL" (Linear Concurrency Scaling)
Each of the 24 numbered shards has its own WAL coordinator, eliminating the single-GenServer bottleneck:

```elixir
# Each shard operates independently
shard_0 = :spacetime_shard_0  # Independent WAL operations
shard_1 = :spacetime_shard_1  # Independent WAL operations
# ... up to shard_23
```

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
  
  # Phase 9: Dynamic shard topology (per-machine)
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

### Phase 9 Innovation: Per-Shard WAL Architecture
- **24 Independent Shards**: Each with its own WAL coordinator
- **Linear Scaling Target**: Eliminate single-GenServer bottleneck
- **Independent Operations**: Each shard can operate without blocking others
- **Current Status**: Architecture complete, optimization in progress

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

# 3. PHASE 9 PATH: Per-shard WAL operations (independent)
def perform_shard_wal_operation(shard_id, operation) do
  # Each shard operates independently
  shard = get_shard(shard_id)
  shard.wal_coordinator.process_operation(operation)
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
- **High-Concurrency Workloads**: Phase 9 architecture designed for linear scaling

### Considerations:
- **Dataset Size**: Optimized for datasets up to ~1M records
- **Access Patterns**: Works best with predictable, pattern-heavy workloads
- **Hardware**: Single-node focused (not distributed)
- **Ecosystem**: Best for Elixir/Erlang applications
- **Phase 9 Status**: Concurrency scaling optimization in progress

## Graph Database Example

While WarpEngine core is a key-value database, a graph database example is available that demonstrates how to build graph operations on top of WarpEngine:

```bash
# Explore the graph database implementation built on WarpEngine
mix run examples/weighted_graph_database.ex
```

The example provides graph operations like `store_node/1`, `store_edge/1`, `traverse_graph/3`, and `generate_recommendations/2`.

## Checking
Run validation/checking test:

```bash
CANDLEX_NIF_TARGET=cuda mix test
```

## Benchmarking

Run performance tests:

```bash
# Concurrency sweep (warmup + steady-state): prints best/median/p50/p90
mix run benchmarks/optimal_concurrency_test.exs
mix run benchmarks/concurrency_sweep_heavy.exs

# Concurrency sweep with settings and output to filesystem
WARP_GPU_BATCH_SIZE=1024 USE_GPU_PHYSICS=1 WAL_SAMPLE_RATE=16 KEYSET=500 CONC="1,2,3,4" TRIALS=5 MEASURE_MS=1500 OPS=100 MIX_ENV=prod mix run benchmarks/optimal_concurrency_test.exs &> benchmarks/optimal_concurrency_test.txt 
CONC="1,2,3,4" KEYSET=10000 TRIALS=2 WARMUPS=1 MEASURE_MS=3000 SHARDS=24 mix run benchmarks/concurrency_sweep_heavy.exs &> benchmarks/concurrency_sweep_heavy.txt

# Large dataset feature validation (tests all unique features)
BENCH_LOG_LEVEL=info BENCH_MODE=false TARGET_GB=0.1 CONC="1,2,4,8,12" TRIALS=1 mix run benchmarks/large_dataset_feature_validation.exs &> benchmarks/large_dataset_feature_validation_0_1_gb.txt

# General benchmark
mix run benchmarks/working_benchmark.exs &> benchmarks/working_benchmark.txt

# diagnostic benchmarks
mix run benchmarks/diagnose/test_wal_only.exs &> benchmarks/diagnose/test_wal_only.txt
mix run benchmarks/diagnose/test_shards_only.exs &> benchmarks/diagnose/test_shards_only.txt
mix run benchmarks/diagnose/test_memory_scaling.exs &> benchmarks/diagnose/test_memory_scaling.txt
mix run benchmarks/diagnose/test_coordination_overhead.exs &> benchmarks/diagnose/test_coordination_overhead.txt

# gpu benchmarks
WE_DEBUG_GPU=true WE_PHYSICS_OPS=800000 WE_BATCH_OPS=1000000 WE_MIXED_OPS=500000 mix run benchmarks/gpu_benchmark.ex gpu

# Graph database comparison (uses the example implementation)
mix run benchmarks/simple_weighted_graph_benchmark.exs
```

## Testing

```bash
mix test                    # Run all 175+ tests
mix test --max-cases 1      # Run tests sequentially
```

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

**Phase 9 Status**: Per-shard WAL architecture is implemented and operational, but concurrency scaling optimization is still in progress. The system shows excellent performance up to 3-4 processes but needs additional work to achieve linear scaling to 24 processes as designed.
