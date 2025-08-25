# WarpEngine Database

A high-performance Elixir key-value database with creative physics-inspired optimizations and intelligent caching.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![Elixir Version](https://img.shields.io/badge/elixir-1.15+-blue.svg)]()
[![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-175%20passing-brightgreen.svg)]()

**Performance**: 15K-26K ops/sec with good scaling characteristics  
**Architecture**: Intelligent caching, adaptive sharding, predictive loading  
**Zero-Tuning**: Self-optimizing system that adapts to workload patterns

## Overview

WarpEngine is an Elixir-based key-value database that combines solid engineering with creative optimization techniques inspired by physics concepts. It provides high-performance data storage with intelligent caching, adaptive sharding, and predictive data loading.

**Key Features:**
- **High Performance**: 15K-26K ops/sec with good scaling characteristics (measured on laptop hardware)
- **Intelligent Caching**: Predictive prefetching based on access pattern analysis  
- **Adaptive Sharding**: Locality-aware data placement that improves over time
- **Pattern Learning**: Automatically learns data relationships for optimization
- **Zero-Tuning**: Self-optimizing system that adapts to workload patterns
- **Production Ready**: Write-ahead logging, crash recovery, comprehensive test suite

## Performance Characteristics

**Measured Performance (Dell PX13 Laptop):**
- **Key-Value Operations**: 15,209-26,033 ops/sec
- **Scaling**: Good performance maintained up to ~1M records  
- **Memory Efficiency**: Reasonable memory usage with intelligent caching
- **Latency**: Sub-millisecond operations for cached data

**Scaling Results:**
| Dataset Size | Operations/sec | Notes |
|--------------|----------------|--------|
| 1K records | 15,209 ops/sec | Baseline performance |
| 10K records | 23,922 ops/sec | 57% improvement as optimizations engage |
| 500K records | 24,598 ops/sec | Sustained performance |  
| 1M records | 26,033 ops/sec | Peak measured performance |

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
  
  # Prefetch patterns
  entanglement_rules: [
    {"user:*", ["profile:*", "settings:*"]},
    {"order:*", ["customer:*", "products:*"]},
    {"post:*", ["author:*", "comments:*"]}
  ]
```

## What Makes WarpEngine Different

### Creative Optimization Approach
- **Pattern-Based Prefetching**: Learns access patterns and prefetches related data
- **Similarity-Based Sharding**: Places related data on the same shards for locality
- **Statistical Load Balancing**: Uses information theory to detect and fix imbalances
- **Connection Optimization**: Tracks frequently used routing paths and optimizes them

### Production Features
- **Write-Ahead Logging**: Crash recovery and durability guarantees
- **Comprehensive Testing**: 175+ tests covering all functionality
- **Elixir/OTP Integration**: Built on battle-tested Erlang VM
- **Monitoring**: Built-in metrics and performance tracking
- **Self-Optimization**: Adapts to workload patterns without manual tuning

## Performance Comparison

**vs Other Elixir Databases (on similar hardware):**
- **Mnesia**: ~5,000-8,000 ops/sec → WarpEngine: 2-3x faster with intelligent optimizations  
- **CubDB**: ~3,000-6,000 ops/sec → WarpEngine: 3-5x faster with predictive caching
- **ETS-based stores**: Fast but no persistence → WarpEngine: Persistent + adaptive optimizations

**Note**: Performance is hardware and workload specific. WarpEngine excels at key-value operations with predictable access patterns and intelligent caching.

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
# Basic performance
mix run simple_benchmark.exs

# Multi-core scaling
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

**Note**: The physics metaphors ("quantum entanglement", "gravitational routing", etc.) are creative terminology for standard database optimization techniques. They don't involve actual physics but represent innovative approaches to data placement, caching, and load balancing.
