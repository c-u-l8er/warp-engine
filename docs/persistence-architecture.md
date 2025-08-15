# 🌌 IsLab DB Filesystem Persistence Architecture

*Making data persistence as elegant as the cosmic microwave background.*

## 📖 Overview

IsLab DB employs a **physics-inspired filesystem persistence layer** that mirrors the structure of the universe itself. Data is organized into cosmic hierarchies, from quantum-scale individual records to galactic-scale shard clusters, with each level optimized for both performance and human readability.

## 🗂️ Cosmic Filesystem Structure

```
/data/
├── universe.manifest                    # Master universe configuration
├── spacetime/                          # Core spacetime shards
│   ├── hot_data/                       # High-energy, fast-access data
│   │   ├── shard.metadata             # Shard physics laws and metrics
│   │   ├── quantum_indices/           # Entangled key relationships
│   │   │   ├── entangled_keys.erl     # Erlang term format for speed
│   │   │   └── relationships.json     # Human-readable relationships
│   │   ├── particles/                 # Individual data records
│   │   │   ├── users/                 # Organized by data type
│   │   │   │   ├── alice.json        # Individual user records
│   │   │   │   ├── bob.json
│   │   │   │   └── _manifest.json    # Directory metadata
│   │   │   ├── products/
│   │   │   └── orders/
│   │   └── event_horizon/             # Cache persistence
│   │       ├── cache_state.erl       # ETS dump for fast recovery
│   │       └── cache_analytics.json  # Human-readable cache stats
│   ├── warm_data/                     # Balanced consistency/performance
│   │   └── [similar structure]
│   └── cold_data/                     # High-compression, slower access
│       └── [similar structure with compression]
├── temporal/                          # Time-series data organization  
│   ├── live/                         # Real-time data (last hour)
│   │   ├── 2024-01-15-14/           # Hour-based partitions
│   │   │   ├── events.jsonl         # Line-delimited JSON for streaming
│   │   │   ├── metrics.erl          # Binary metrics for speed
│   │   │   └── summary.json         # Human-readable hourly summary
│   │   └── current_streams.state    # Active stream state
│   ├── recent/                      # Recent data (last 24 hours)
│   │   ├── 2024-01-15/             # Day-based partitions
│   │   │   ├── aggregated.json     # Daily aggregations
│   │   │   ├── compressed.gz       # Compressed raw data
│   │   │   └── analytics.json      # Daily analytics
│   │   └── retention_policy.json
│   └── historical/                  # Long-term storage (30+ days)
│       ├── 2024-01/                # Month-based partitions
│       │   ├── compressed.lz4      # Highly compressed data
│       │   ├── indices.btree       # Optimized indices
│       │   └── summary.json        # Monthly summary
│       └── archive_policy.json
├── quantum_graph/                    # Graph database storage
│   ├── nodes/                       # Quantum nodes by type
│   │   ├── persons/                 
│   │   │   ├── alice.json          # Node data + quantum properties
│   │   │   └── bob.json
│   │   ├── organizations/
│   │   └── concepts/
│   ├── edges/                       # Quantum edges organized by relation
│   │   ├── works_for/              # Relationship type directories
│   │   │   ├── alice_to_acme.json  # Edge data + strength + temporal decay
│   │   │   └── bob_to_acme.json
│   │   ├── collaborates_with/
│   │   └── leads/
│   ├── dimensions/                  # Multi-dimensional indexing
│   │   ├── coordinate_index.btree   # Spatial index for similarity search
│   │   └── similarity_clusters.json # Pre-computed similarity clusters
│   └── entanglements/              # Quantum entanglement registry
│       ├── strong_correlations.erl  # Fast binary format
│       └── entanglement_map.json   # Human-readable entanglement visualization
├── wormholes/                       # Network topology and routing
│   ├── active_connections.json     # Current wormhole network state
│   ├── topology.graphml            # Graph visualization format
│   ├── routing_tables/             # Fast routing lookups
│   │   ├── hot_to_warm.routes     # Binary routing tables
│   │   └── warm_to_cold.routes
│   └── network_analytics.json     # Network performance metrics
├── entropy/                        # System monitoring and analytics
│   ├── current_state.json         # Real-time system entropy
│   ├── historical_entropy.csv     # Time-series entropy data
│   ├── rebalancing_log.jsonl      # Rebalancing event log
│   └── vacuum_stability.metrics   # Binary metrics for vacuum state
├── qql/                           # Query language persistence
│   ├── compiled_queries/          # Query compilation cache
│   │   ├── hash_1234.erl         # Compiled query bytecode
│   │   └── hash_1234.meta.json   # Query metadata
│   ├── query_analytics/           # Query performance data
│   │   ├── performance.csv       # Query execution statistics
│   │   └── optimization_log.json # Query optimization history
│   └── schema/                    # Data schema definitions
│       ├── universe_schema.json  # Master schema
│       └── validation_rules.erl  # Schema validation logic
├── backups/                       # Cosmic backup management
│   ├── snapshots/                 # Point-in-time universe snapshots
│   │   ├── 2024-01-15-snapshot/  # Complete universe state
│   │   │   ├── universe.tar.gz   # Compressed full backup
│   │   │   ├── manifest.json     # Backup metadata
│   │   │   └── verification.md5  # Integrity checksums
│   │   └── incremental/          # Incremental backups
│   └── cosmic_logs/               # Transaction and change logs
│       ├── 2024-01-15.wal        # Write-ahead log
│       ├── cosmic_events.jsonl   # Significant system events
│       └── audit_trail.log       # Human-readable audit log
├── observatory/                   # Monitoring and observability
│   ├── metrics/                   # Performance metrics
│   │   ├── real_time.json        # Current system state
│   │   ├── historical.csv        # Time-series metrics
│   │   └── alerts.json           # Active alerts and thresholds
│   ├── logs/                      # System logs
│   │   ├── quantum_db.log        # Main application log
│   │   ├── physics_engine.log    # Physics calculation logs
│   │   └── error_gravitational_waves.log # Critical error propagation
│   └── diagnostics/               # System diagnostic data
│       ├── health_check.json     # System health status
│       ├── performance_profile.erl # Performance profiling data
│       └── cosmic_debug.trace    # Detailed execution traces
└── configuration/                 # Universe configuration
    ├── physics_constants.json    # Fundamental constants
    ├── shard_topology.json       # Spacetime shard configuration
    ├── entanglement_rules.json   # Quantum entanglement patterns
    ├── temporal_policies.json    # Time-based data policies
    └── universe_parameters.json  # Master configuration file
```

## 🎯 Design Principles

### 1. **Cosmic Hierarchy**
Data organization mirrors the universe's structure:
- **Quantum Scale** → Individual records and small data structures
- **Atomic Scale** → Related data clusters and cache units  
- **Molecular Scale** → Shard-level data organization
- **Galactic Scale** → Universe-wide configuration and metadata

### 2. **Multi-Format Storage**
Strategic use of different formats for optimal balance of performance and readability:

- **`.erl` files** → Erlang term format for maximum speed (ETS dumps, compiled queries)
- **`.json` files** → Human-readable structured data (configs, metadata, analytics)
- **`.jsonl` files** → Line-delimited JSON for streaming data (logs, events)
- **`.csv` files** → Time-series data and metrics
- **`.gz/.lz4` files** → Compressed historical data
- **`.btree` files** → Binary tree indices for fast lookups

### 3. **Physics-Inspired Organization**

#### **Energy Levels** → Access Patterns
```
hot_data/     → High energy, frequent access, strong consistency
warm_data/    → Medium energy, moderate access, eventual consistency  
cold_data/    → Low energy, rare access, weak consistency + compression
```

#### **Temporal Relativity** → Time-Based Partitioning
```
live/        → Present time (relativistic effects minimal)
recent/      → Recent past (slight time dilation)
historical/  → Distant past (significant time dilation, compression)
```

#### **Quantum States** → Data Relationships
```
entangled/      → Strongly correlated data (automatic co-location)
superposition/  → Uncertain states (multiple possible values)
collapsed/      → Measured/accessed data (definite state)
```

### 4. **Human Readability Features**

#### **Semantic Naming**
```bash
# Instead of: /data/shard_001/table_users/record_123
# We use:    /data/spacetime/hot_data/particles/users/alice.json

# Instead of: /data/cache/lru_001
# We use:    /data/spacetime/hot_data/event_horizon/cache_analytics.json
```

#### **Self-Documenting Structure**
Every directory includes a `_manifest.json` file explaining its purpose:

```json
{
  "cosmic_location": "spacetime/hot_data/particles/users/",
  "physics_description": "Individual user entities in high-energy spacetime region",
  "data_format": "JSON records with quantum properties",
  "last_observation": "2024-01-15T14:30:00Z",
  "quantum_state": "frequently_observed",
  "entangled_with": ["profiles/", "settings/", "sessions/"],
  "access_patterns": {
    "read_frequency": "very_high",
    "write_frequency": "high", 
    "consistency_model": "strong"
  }
}
```

## 💾 Data Serialization Strategy

### **Performance-Critical Data** (Binary Formats)
```elixir
# ETS table dumps for instant recovery
:ets.tab2file(table, "/data/spacetime/hot_data/quantum_indices/entangled_keys.erl")

# Compiled query cache
compiled_query = %CompiledQuery{...}
File.write!("/data/qql/compiled_queries/hash_#{query_hash}.erl", 
           :erlang.term_to_binary(compiled_query))
```

### **Analytics and Monitoring** (JSON for Readability)
```elixir
# Human-readable system metrics
metrics = %{
  timestamp: DateTime.utc_now(),
  entropy: %{
    total: 1.85,
    cpu: 0.7,
    memory: 0.6,
    io: 0.55
  },
  vacuum_stability: 0.97,
  wormhole_efficiency: 0.83,
  cosmic_background_radiation: 2.7  # Always 2.7K :-)
}

File.write!("/data/observatory/metrics/real_time.json", 
           Jason.encode!(metrics, pretty: true))
```

### **Time-Series Data** (Hybrid Approach)
```elixir
# Live data: Line-delimited JSON for streaming
event = %{timestamp: now, type: "user_action", user_id: "alice"}
File.write!("/data/temporal/live/#{hour}/events.jsonl", 
           Jason.encode!(event) <> "\n", [:append])

# Historical data: Compressed binary for efficiency  
compressed_data = :lz4.compress(:erlang.term_to_binary(historical_events))
File.write!("/data/temporal/historical/#{month}/compressed.lz4", compressed_data)
```

## 🔄 Persistence Implementation

### **Universe Bootstrap Process**
```elixir
defmodule IsLabDB.CosmicPersistence do
  @data_root "/data"
  
  def initialize_universe() do
    create_cosmic_directories()
    load_universe_manifest()
    restore_spacetime_shards()
    rebuild_quantum_entanglements()
    establish_wormhole_network()
    start_entropy_monitoring()
  end
  
  defp create_cosmic_directories() do
    cosmic_structure = [
      "spacetime/hot_data/particles/users",
      "spacetime/hot_data/quantum_indices", 
      "spacetime/hot_data/event_horizon",
      "temporal/live", "temporal/recent", "temporal/historical",
      "quantum_graph/nodes", "quantum_graph/edges",
      "wormholes/routing_tables",
      "entropy", "qql/compiled_queries",
      "backups/snapshots", "observatory/metrics",
      "configuration"
    ]
    
    Enum.each(cosmic_structure, fn path ->
      full_path = Path.join(@data_root, path)
      File.mkdir_p!(full_path)
      create_manifest(full_path)
    end)
  end
end
```

### **Real-Time Persistence**
```elixir
defmodule IsLabDB.QuantumPersistence do
  # Asynchronous persistence to avoid blocking operations
  def persist_quantum_state(key, value, shard_id) do
    Task.start(fn ->
      shard_path = shard_directory(shard_id)
      data_type = extract_data_type(key)
      
      # Write to appropriate cosmic location
      file_path = Path.join([shard_path, "particles", data_type, "#{sanitize_key(key)}.json"])
      
      quantum_record = %{
        key: key,
        value: value,
        quantum_properties: %{
          observed_at: DateTime.utc_now(),
          observation_count: get_observation_count(key),
          quantum_state: determine_quantum_state(key),
          entangled_keys: get_entangled_keys(key),
          dimensional_coordinates: calculate_coordinates(value)
        },
        spacetime_metadata: %{
          shard_id: shard_id,
          gravitational_attraction: get_attraction_score(key),
          temporal_weight: get_temporal_weight(key)
        }
      }
      
      File.write!(file_path, Jason.encode!(quantum_record, pretty: true))
      update_shard_manifest(shard_id, key, file_path)
    end)
  end
end
```

### **Periodic Cosmic Maintenance**
```elixir
defmodule IsLabDB.CosmicMaintenance do
  # Runs every 30 seconds like quantum maintenance
  def perform_cosmic_cleanup() do
    compress_historical_data()
    update_entropy_measurements()
    optimize_wormhole_topology()
    backup_critical_quantum_states()
    update_cosmic_analytics()
  end
  
  defp compress_historical_data() do
    # Move old data from recent/ to historical/ with compression
    yesterday = Date.add(Date.utc_today(), -1)
    recent_path = "/data/temporal/recent/#{yesterday}"
    historical_path = "/data/temporal/historical/#{Date.beginning_of_month(yesterday)}"
    
    if File.exists?(recent_path) do
      compress_and_move(recent_path, historical_path)
      update_retention_policies()
    end
  end
end
```

## 🔍 Data Recovery and Consistency

### **Cosmic Disaster Recovery**
```elixir
defmodule IsLabDB.CosmicRecovery do
  def restore_universe_from_backup(snapshot_path) do
    Logger.info("🌌 Beginning universe restoration from #{snapshot_path}")
    
    # 1. Stop all current operations
    stop_cosmic_processes()
    
    # 2. Clear current universe
    clear_spacetime()
    
    # 3. Restore from backup
    restore_spacetime_shards(snapshot_path)
    restore_quantum_entanglements(snapshot_path)
    restore_temporal_data(snapshot_path)
    
    # 4. Verify universe integrity
    verify_cosmic_consistency()
    
    # 5. Restart cosmic processes
    restart_universe()
    
    Logger.info("✨ Universe restoration complete")
  end
  
  def verify_cosmic_consistency() do
    # Check quantum entanglements are valid
    validate_entanglements()
    
    # Verify shard data integrity  
    validate_shard_checksums()
    
    # Check temporal causality
    validate_temporal_ordering()
    
    # Verify wormhole network connectivity
    validate_wormhole_topology()
  end
end
```

## 📊 Performance Optimizations

### **Intelligent Write Batching**
```elixir
defmodule IsLabDB.BatchWriter do
  # Batch writes by cosmic region for efficiency
  def batch_cosmic_writes(writes_queue) do
    writes_queue
    |> group_by_cosmic_region()
    |> Enum.map(&async_write_region/1)
    |> Task.await_many(5000)
  end
  
  defp group_by_cosmic_region(writes) do
    Enum.group_by(writes, fn {key, _value} ->
      determine_cosmic_region(key)
    end)
  end
end
```

### **Smart Compression Strategy**
```elixir
# Hot data: No compression (speed priority)
# Warm data: Light compression (balanced)
# Cold data: Heavy compression (space priority)

defp compress_by_temperature(data, :hot), do: data
defp compress_by_temperature(data, :warm), do: :zlib.compress(data)  
defp compress_by_temperature(data, :cold), do: :lz4.compress(data)
```

## 🔐 Security and Access Control

### **Cosmic Access Control**
```json
{
  "cosmic_security": {
    "spacetime_access": {
      "hot_data": ["admin", "physics_engine"],
      "warm_data": ["admin", "physics_engine", "observer"],
      "cold_data": ["admin", "archivist"]
    },
    "quantum_operations": {
      "entangle": ["admin", "quantum_engineer"],
      "observe": ["admin", "physics_engine", "observer"],
      "collapse": ["admin", "quantum_engineer"]
    },
    "temporal_access": {
      "live": ["admin", "real_time_processor"],
      "recent": ["admin", "analytics_engine"],
      "historical": ["admin", "data_scientist", "archivist"]
    }
  }
}
```

## 📈 Monitoring and Observability

### **Cosmic Health Dashboard**
The filesystem structure enables rich monitoring:

```elixir
def generate_cosmic_dashboard() do
  %{
    universe_health: read_universe_manifest(),
    spacetime_metrics: aggregate_shard_metrics(),
    quantum_entanglement_status: analyze_entanglement_health(),
    temporal_flow_rate: calculate_temporal_throughput(),
    entropy_levels: read_entropy_measurements(),
    wormhole_efficiency: analyze_network_performance(),
    vacuum_stability: read_vacuum_state(),
    cosmic_background_radiation: 2.7  # Always stable 😄
  }
end
```

This persistence architecture ensures that IsLab DB's cosmic data remains both performant and beautifully organized, making it as elegant to explore as the universe itself.

---

*"In the vast cosmic structure of data, organization brings order to chaos, and persistence brings permanence to the ephemeral dance of information."*
