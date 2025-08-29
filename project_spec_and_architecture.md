# WarpEngine: Hybrid Geospatial Database
## Project Specification & Complete Architecture Guide

> Note: See `docs/mvp_low_risk_design.md` for the current MVP (CPU-only, single-node) scope adopted to reduce execution risk. GPU/NIF, physics, clustering, and advanced real-time features are vNext behind feature flags.

### Executive Summary

WarpEngine is a next-generation geospatial database that combines Elixir's distributed systems capabilities with Zig+CUDA computational performance. It serves as a high-performance alternative to Tile38 and Hivekit, designed for global-scale spatial data processing with real-time capabilities.

**Key Innovation**: Physics-inspired optimization algorithms (gravitational routing, quantum entanglement prefetching, entropy-based load balancing) implemented as actual mathematical models running on GPU hardware.

**Performance Targets**:
- 10M+ spatial queries/second (vs Tile38's 100K/sec)  
- 100K+ concurrent geofence checks/second
- Global distribution with <50ms cross-region latency
- Support for 1M+ concurrent WebSocket connections

---

## Storage/Cache Adapter Strategy

WarpEngine focuses on spatial computation, indexing, and real-time GIS. Durability and caching are provided via pluggable adapters:

- Storage adapters (e.g., Postgres, ClickHouse) provide authoritative persistence and change data capture (CDC).
- Cache adapters (e.g., Redis) provide read-through/write-behind acceleration and pub/sub invalidation.
- In-memory shards and indices (ETS + GPU/CPU indices) are acceleration layers, not the source of truth.

This separation reduces scope risk and enables flexible deployments without reworking the spatial engine.

---

## Architecture Overview

### Hybrid Three-Layer Design

```
┌─────────────────────────────────────────────────────────────┐
│                    Elixir Orchestration Layer              │
│  • Global distribution & fault tolerance                   │
│  • WebSocket handling & real-time pub/sub                 │
│  • Cluster coordination & hot code updates                │
│  • Process supervision & recovery                         │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                    Zig Native Interface Layer              │
│  • High-performance data structures                       │
│  • Memory management & zero-copy operations               │
│  • CUDA kernel orchestration                             │
│  • Spatial indexing (R-trees, Quadtrees)                 │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                    CUDA Computation Layer                  │
│  • Parallel spatial queries                              │
│  • Physics-inspired optimization kernels                 │
│  • Real-time geofencing & analytics                     │
│  • Massive parallel data processing                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Elixir Application Structure

```
apps/
├── warp_engine/              # Core database engine
│   ├── lib/
│   │   ├── warp_engine/
│   │   │   ├── application.ex          # OTP application
│   │   │   ├── cluster/               # Global distribution
│   │   │   │   ├── coordinator.ex     # Cross-region coordination
│   │   │   │   ├── node_manager.ex    # Node discovery & health
│   │   │   │   └── partition_router.ex # Geographic partitioning
│   │   │   ├── spatial/               # Spatial operations
│   │   │   │   ├── engine.ex          # Main spatial query engine
│   │   │   │   ├── geofence_manager.ex # Geofence coordination
│   │   │   │   ├── index_manager.ex   # Spatial index management
│   │   │   │   └── physics/           # Physics-inspired optimizations
│   │   │   │       ├── gravitational_router.ex
│   │   │   │       ├── quantum_entanglement.ex
│   │   │   │       └── entropy_monitor.ex
│   │   │   ├── storage/               # Data persistence
│   │   │   │   ├── shard.ex           # In-memory shard/index management (acceleration)
│   │   │   │   ├── adapter/           # Pluggable storage/cache adapters
│   │   │   │   │   ├── behaviour.ex   # Storage/Cache behaviours
│   │   │   │   │   ├── postgres.ex    # Storage adapter: Postgres (authoritative)
│   │   │   │   │   └── redis.ex       # Cache adapter: Redis (read-through)
│   │   │   │   └── cdc.ex             # CDC subscriber to keep indices warm
│   │   │   └── nif/                   # Native interface
│   │   │       ├── spatial_nif.ex     # Zig NIF wrapper
│   │   │       └── gpu_coordinator.ex # CUDA operation coordinator
│   │   └── warp_engine.ex             # Public API
│   └── mix.exs
├── warp_web/                 # Web interface & real-time APIs  
│   ├── lib/
│   │   ├── warp_web/
│   │   │   ├── channels/              # Real-time WebSocket channels
│   │   │   │   ├── spatial_channel.ex # Real-time spatial updates
│   │   │   │   └── geofence_channel.ex # Geofence event streaming
│   │   │   ├── controllers/           # HTTP API endpoints
│   │   │   │   ├── spatial_controller.ex
│   │   │   │   └── admin_controller.ex
│   │   │   └── live/                  # LiveView admin interface
│   │   │       ├── dashboard_live.ex  # Real-time monitoring
│   │   │       └── spatial_map_live.ex # Interactive spatial viewer
│   │   └── warp_web.ex
│   └── mix.exs
└── warp_benchmark/           # Performance testing & validation
    ├── lib/
    │   ├── benchmark/
    │   │   ├── spatial_benchmarks.ex  # Spatial query performance
    │   │   ├── geofence_benchmarks.ex # Geofencing performance  
    │   │   ├── gpu_benchmarks.ex      # CUDA kernel performance
    │   │   └── global_benchmarks.ex   # Cross-region performance
    │   └── benchmark.ex
    └── mix.exs
```

### 2. Zig Native Components

```
native/
├── warp_spatial_nif/         # Main NIF library
│   ├── src/
│   │   ├── main.zig                   # NIF entry points
│   │   ├── spatial/                   # Spatial data structures
│   │   │   ├── rtree.zig              # GPU-optimized R-tree
│   │   │   ├── quadtree.zig           # Parallel quadtree  
│   │   │   ├── geohash.zig            # Geohash operations
│   │   │   └── geometry.zig           # Geometric calculations
│   │   ├── cuda/                      # CUDA integration
│   │   │   ├── kernels.zig            # CUDA kernel wrappers
│   │   │   ├── memory.zig             # GPU memory management
│   │   │   └── stream.zig             # CUDA stream coordination
│   │   ├── physics/                   # Physics algorithms
│   │   │   ├── gravitational.zig      # Gravitational routing
│   │   │   ├── quantum.zig            # Quantum entanglement
│   │   │   └── entropy.zig            # Entropy calculations
│   │   └── storage/                   # (optional) Low-level storage primitives
│   │       └── shard.zig              # Shard data structures used in-memory
│   ├── cuda_kernels/                  # CUDA kernel implementations
│   │   ├── spatial_query.cu           # Parallel spatial searches
│   │   ├── geofence_check.cu          # Massive geofence checking
│   │   ├── physics_simulation.cu      # Physics-inspired optimization
│   │   └── analytics.cu               # Real-time spatial analytics
│   ├── build.zig                      # Zig build configuration
│   └── zigler.exs                     # Zigler NIF configuration
└── benchmarks/               # Native performance tests
    ├── spatial_bench.zig              # Spatial operation benchmarks
    ├── cuda_bench.zig                 # CUDA kernel benchmarks  
    └── memory_bench.zig               # Memory performance tests
```

---

## Data Models & Core Types

### Elixir Data Types

```elixir
# Core spatial object
defmodule WarpEngine.GeoObject do
  @type t :: %__MODULE__{
    id: binary(),
    coordinates: {lat :: float(), lon :: float()},
    geometry: geometry_type(),
    properties: map(),
    metadata: metadata(),
    shard_id: non_neg_integer(),
    created_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  @type geometry_type :: 
    :point | :linestring | :polygon | :multipoint | 
    :multilinestring | :multipolygon | :geometrycollection

  @type metadata :: %{
    access_frequency: float(),      # For physics calculations
    data_mass: float(),            # Physics: gravitational mass
    energy_level: non_neg_integer(), # Physics: quantum energy level
    entangled_objects: [binary()],  # Physics: quantum entanglement
    last_accessed: DateTime.t()
  }
end

# Geofence definition
defmodule WarpEngine.Geofence do
  @type t :: %__MODULE__{
    id: binary(),
    name: String.t(),
    geometry: WarpEngine.Geometry.t(),
    rules: [geofence_rule()],
    active: boolean(),
    created_at: DateTime.t()
  }

  @type geofence_rule :: %{
    trigger: :enter | :exit | :inside | :outside,
    webhook_url: String.t() | nil,
    channel: String.t() | nil,
    metadata: map()
  }
end

# Physics-inspired optimization state
defmodule WarpEngine.Physics.State do
  @type t :: %__MODULE__{
    gravitational_constants: map(),    # Per-shard gravitational masses
    quantum_entanglements: %{binary() => [binary()]}, # Object relationships
    entropy_measurements: [float()],   # System entropy over time
    energy_levels: %{binary() => non_neg_integer()}, # Object energy states
    last_rebalancing: DateTime.t()
  }
end
```

### Zig Data Structures

```zig
// Core geometric types
const GeoPoint = struct {
    lat: f64,
    lon: f64,
    elevation: f32 = 0.0,
};

const BoundingBox = struct {
    min_lat: f64,
    min_lon: f64, 
    max_lat: f64,
    max_lon: f64,
};

// GPU-optimized spatial object
const GeoObjectGPU = struct {
    id: u64,                    // Hash of object ID
    point: GeoPoint,
    geometry_type: GeometryType,
    properties_offset: u32,     // Offset into properties buffer
    properties_length: u16,
    
    // Physics metadata
    access_frequency: f32,
    data_mass: f32,
    energy_level: u8,
    last_accessed: i64,
    
    // Padding for GPU memory alignment
    _padding: [4]u8 = undefined,
};

// Spatial index node (GPU-friendly)
const RTreeNodeGPU = struct {
    bbox: BoundingBox,
    children: [8]u32,          // Child node indices (0 = empty)
    object_count: u16,
    is_leaf: bool,
    level: u8,
    
    // Physics state for the node
    gravitational_mass: f32,
    center_of_mass: GeoPoint,
};

// Geofence for GPU processing
const GeofenceGPU = struct {
    id: u64,
    geometry_type: GeometryType,
    point_count: u16,
    points_offset: u32,        // Offset into points buffer
    
    // Rule configuration
    triggers: u8,              // Bitflags: enter|exit|inside|outside
    active: bool,
    
    _padding: [5]u8 = undefined,
};
```

---

## Physics-Inspired Optimization Algorithms

### 1. Gravitational Routing

**Concept**: Data placement based on gravitational attraction between objects and shards.

**Implementation**:
```elixir
defmodule WarpEngine.Physics.GravitationalRouter do
  @gravitational_constant 6.67430e-11  # Scaled for database use
  
  def calculate_optimal_shard(object, shards) do
    attractions = 
      Enum.map(shards, fn shard ->
        force = gravitational_force(object, shard)
        {shard.id, force}
      end)
    
    # Select shard with highest attraction
    {optimal_shard, _force} = Enum.max_by(attractions, &elem(&1, 1))
    optimal_shard
  end
  
  defp gravitational_force(object, shard) do
    data_mass = calculate_data_mass(object)
    shard_mass = shard.gravitational_mass
    distance = haversine_distance(object.coordinates, shard.center)
    
    # F = G * m1 * m2 / r²
    @gravitational_constant * data_mass * shard_mass / (distance * distance)
  end
end
```

**CUDA Kernel**:
```cuda
__global__ void calculate_gravitational_routing(
    const GeoObjectGPU* objects,
    const ShardInfo* shards,
    float* attraction_matrix,
    int n_objects, int n_shards
) {
    int obj_idx = blockIdx.x * blockDim.x + threadIdx.x;
    int shard_idx = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (obj_idx >= n_objects || shard_idx >= n_shards) return;
    
    const GeoObjectGPU& obj = objects[obj_idx];
    const ShardInfo& shard = shards[shard_idx];
    
    float distance = haversine_distance_gpu(obj.point, shard.center);
    float force = (GRAVITATIONAL_CONSTANT * obj.data_mass * shard.mass) / 
                  (distance * distance + 1.0f); // +1 to avoid division by zero
    
    attraction_matrix[obj_idx * n_shards + shard_idx] = force;
}
```

### 2. Quantum Entanglement (Predictive Prefetching)

**Concept**: Objects that are frequently accessed together become "entangled" and are prefetched together.

**Implementation**:
```elixir
defmodule WarpEngine.Physics.QuantumEntanglement do
  def create_entanglement(object_a, object_b, correlation_strength) do
    # Store bidirectional entanglement
    :ets.insert(:quantum_entanglements, {
      {object_a, object_b}, 
      correlation_strength, 
      System.system_time(:millisecond)
    })
    
    :ets.insert(:quantum_entanglements, {
      {object_b, object_a}, 
      correlation_strength, 
      System.system_time(:millisecond)
    })
  end
  
  def get_entangled_objects(object_id, min_correlation \\ 0.5) do
    :ets.select(:quantum_entanglements, [
      {{{object_id, :"$1"}, :"$2", :_}, 
       [{:>=, :"$2", min_correlation}], 
       [:"$1"]}
    ])
  end
  
  def quantum_prefetch(object_id) do
    entangled_ids = get_entangled_objects(object_id)
    
    # Parallel prefetch of entangled objects
    Task.async_stream(entangled_ids, fn id ->
      WarpEngine.SpatialNIF.prefetch_object(id)
    end, max_concurrency: 8)
    |> Enum.to_list()
  end
end
```

### 3. Entropy Monitoring (Load Balancing)

**Concept**: Use Shannon entropy to measure system balance and trigger rebalancing.

**Implementation**:
```elixir
defmodule WarpEngine.Physics.EntropyMonitor do
  def calculate_system_entropy(shards) do
    total_objects = Enum.sum(Enum.map(shards, & &1.object_count))
    
    if total_objects == 0 do
      0.0
    else
      entropy = 
        shards
        |> Enum.map(fn shard ->
          probability = shard.object_count / total_objects
          if probability > 0, do: -probability * :math.log2(probability), else: 0
        end)
        |> Enum.sum()
      
      # Normalize entropy (0 = perfectly unbalanced, 1 = perfectly balanced)  
      max_entropy = :math.log2(length(shards))
      entropy / max_entropy
    end
  end
  
  def should_rebalance?(current_entropy, threshold \\ 0.8) do
    current_entropy < threshold
  end
end
```

---

## API Design

### HTTP REST API

```elixir
# Spatial object operations
POST   /api/v1/objects                    # Create spatial object
GET    /api/v1/objects/:id               # Get object by ID  
PUT    /api/v1/objects/:id               # Update object
DELETE /api/v1/objects/:id               # Delete object

# Spatial queries
GET    /api/v1/search/nearby             # ?lat=&lon=&radius=&limit=
GET    /api/v1/search/bbox               # ?min_lat=&min_lon=&max_lat=&max_lon=
POST   /api/v1/search/polygon            # Search within custom polygon
POST   /api/v1/search/complex            # Complex spatial queries

# Geofencing
POST   /api/v1/geofences                 # Create geofence
GET    /api/v1/geofences                 # List geofences
GET    /api/v1/geofences/:id             # Get geofence by ID
PUT    /api/v1/geofences/:id             # Update geofence
DELETE /api/v1/geofences/:id             # Delete geofence

# Real-time analytics
GET    /api/v1/analytics/heatmap         # Generate heatmap
GET    /api/v1/analytics/stats           # Spatial statistics
GET    /api/v1/analytics/predictions     # Movement predictions

# System administration
GET    /api/v1/admin/health              # System health
GET    /api/v1/admin/metrics             # Performance metrics
POST   /api/v1/admin/rebalance           # Trigger rebalancing
GET    /api/v1/admin/physics             # Physics state inspection
```

### WebSocket Real-Time API

```elixir
# Real-time spatial updates channel
"spatial:updates"
  - join: %{bbox: bounding_box, filters: [...]}
  - events: 
    - object_entered: %{object: geo_object, timestamp: datetime}
    - object_exited: %{object: geo_object, timestamp: datetime}  
    - object_updated: %{object: geo_object, changes: [...]}

# Geofence events channel  
"geofence:events"
  - join: %{geofence_ids: [...]}
  - events:
    - geofence_triggered: %{geofence: geofence, object: geo_object, trigger: atom}
    - geofence_updated: %{geofence: geofence, changes: [...]}

# System monitoring channel
"system:monitoring"  
  - join: %{admin_token: token}
  - events:
    - performance_update: %{metrics: performance_metrics}
    - physics_update: %{entropy: float, rebalancing: boolean}
    - cluster_update: %{nodes: [...], health: [...]}
```

---

## Configuration

### Elixir Configuration

```elixir
# config/config.exs
import Config

config :warp_engine,
  # Global cluster configuration
  cluster: [
    strategy: Cluster.Strategy.Gossip,
    config: [
      port: 45892,
      if_addr: "0.0.0.0",
      multicast_addr: "230.1.1.251",
      multicast_ttl: 1,
      secret: System.get_env("CLUSTER_SECRET")
    ]
  ],

  # Regional node configuration  
  region: System.get_env("WARP_REGION", "us-west"),
  datacenter: System.get_env("WARP_DATACENTER", "us-west-1"),
  
  # Storage configuration
  data_root: System.get_env("WARP_DATA_ROOT", "/opt/warp_engine/data"),
  wal_enabled: true,
  wal_sync_interval: 1000,  # milliseconds
  
  # Spatial indexing
  default_shard_count: System.schedulers_online() * 2,
  spatial_index: :rtree_gpu,  # :rtree_gpu | :quadtree | :geohash
  
  # Physics optimizations
  physics: [
    enable_gravitational_routing: true,
    enable_quantum_entanglement: true, 
    enable_entropy_monitoring: true,
    
    # Physics constants (tuned for database workloads)
    gravitational_constant: 6.67430e-8,
    quantum_correlation_threshold: 0.6,
    entropy_rebalance_threshold: 0.75,
    
    # Update intervals
    physics_update_interval: 10_000,      # 10 seconds
    entropy_check_interval: 30_000,       # 30 seconds  
    rebalancing_cooldown: 300_000         # 5 minutes
  ],
  
  # GPU configuration
  gpu: [
    enabled: System.get_env("CUDA_VISIBLE_DEVICES") != nil,
    device_id: 0,
    memory_pool_size: "1GB",
    stream_count: 4,
    
    # Kernel launch parameters
    block_size: 256,
    grid_size: :auto,  # Calculated based on problem size
    
    # Feature flags
    enable_gpu_spatial_queries: true,
    enable_gpu_geofencing: true,
    enable_gpu_physics: true,
    enable_gpu_analytics: true
  ],

  # Performance tuning
  performance: [
    # ETS table configuration  
    ets_compressed: true,
    ets_write_concurrency: true,
    ets_read_concurrency: true,
    
    # Memory management
    binary_gc_interval: 60_000,    # 1 minute
    process_gc_threshold: 10_000,   # objects per process
    
    # Caching
    object_cache_size: 100_000,
    query_cache_size: 10_000,
    cache_ttl: 300_000,            # 5 minutes
    
    # Benchmarking  
    benchmark_mode: false,          # Skip non-essential operations
    enable_metrics_collection: true,
    metrics_flush_interval: 5_000   # 5 seconds
  ]

# Web interface configuration  
config :warp_web,
  # Phoenix endpoint
  endpoint: [
    http: [port: 4000, protocol_options: [max_connections: 16_384]],
    websocket: [timeout: 45_000, max_frame_size: 8_388_608], # 8MB frames
    live_view: [signing_salt: System.get_env("PHOENIX_LIVE_VIEW_SALT")]
  ],
  
  # Real-time features
  pubsub: [
    adapter: Phoenix.PubSub.PG2,
    pool_size: System.schedulers_online()
  ],
  
  # API rate limiting
  api_rate_limits: [
    spatial_queries: {1000, :per_minute},    # 1000 queries per minute
    object_updates: {5000, :per_minute},     # 5000 updates per minute  
    websocket_connections: {100, :per_ip}    # 100 connections per IP
  ]
```

### Zig Build Configuration

```zig
// build.zig
const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    
    // Main NIF library
    const nif_lib = b.addSharedLibrary(.{
        .name = "warp_spatial_nif",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    
    // CUDA support
    if (b.option(bool, "cuda", "Enable CUDA support") orelse true) {
        nif_lib.defineCMacro("CUDA_ENABLED", "1");
        nif_lib.linkSystemLibrary("cuda");
        nif_lib.linkSystemLibrary("cudart");
        nif_lib.linkSystemLibrary("cublas");
        
        // Add CUDA kernel compilation step
        const cuda_kernels = b.addSystemCommand(&[_][]const u8{
            "nvcc",
            "-ptx",
            "-O3",
            "--gpu-architecture=compute_75", // Adjust for target GPU
            "cuda_kernels/spatial_query.cu",
            "cuda_kernels/geofence_check.cu", 
            "cuda_kernels/physics_simulation.cu",
            "cuda_kernels/analytics.cu"
        });
        nif_lib.step.dependOn(&cuda_kernels.step);
    }
    
    // Optimization flags
    nif_lib.setTarget(target);
    nif_lib.setBuildMode(optimize);
    nif_lib.strip = (optimize == .ReleaseFast);
    nif_lib.link_function_sections = true;
    
    // Install the library
    nif_lib.install();
    
    // Benchmarking executable
    const bench_exe = b.addExecutable(.{
        .name = "warp_bench",
        .root_source_file = .{ .path = "benchmarks/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    bench_exe.linkLibC();
    if (b.option(bool, "cuda", "Enable CUDA support") orelse true) {
        bench_exe.linkSystemLibrary("cuda");
        bench_exe.linkSystemLibrary("cudart");
    }
    bench_exe.install();
}
```

---

## Development Workflow

### Initial Setup Commands

```bash
# Create new Elixir umbrella project
mix new warp_engine --umbrella --sup

# Add individual applications
cd apps/
mix new warp_engine --sup
mix new warp_web --sup  
mix new warp_benchmark --sup

# Initialize Zig native components
mkdir native/
cd native/
zig init-lib

# Install dependencies
mix deps.get
mix deps.compile

# Compile native components
cd native/warp_spatial_nif/
zig build -Doptimize=ReleaseFast

# Set up database
mix ecto.create
mix ecto.migrate

# Run tests
mix test

# Start development server
iex -S mix phx.server
```

### Development Commands

```bash
# Development server with live reloading
mix phx.server

# Run full test suite  
mix test
mix test --cover

# Native component development
cd native/warp_spatial_nif/
zig test src/main.zig
zig build bench
./zig-out/bin/warp_bench

# Benchmarking
mix run benchmarks/spatial_benchmarks.ex
mix run benchmarks/gpu_benchmarks.ex  
mix run benchmarks/global_benchmarks.ex

# Performance profiling
mix profile.eprof --calls
mix profile.fprof --calls

# Production deployment
MIX_ENV=prod mix compile
MIX_ENV=prod mix release
MIX_ENV=prod mix phx.server
```

### Testing Strategy

```bash
# Unit tests (per component)
mix test apps/warp_engine/test/
mix test apps/warp_web/test/
mix test apps/warp_benchmark/test/

# Integration tests (cross-component)  
mix test test/integration/

# Performance tests
mix test test/performance/ --max-cases 1

# Chaos testing (fault tolerance)
mix test test/chaos/ --max-cases 1

# GPU kernel tests
cd native/warp_spatial_nif/
zig test cuda_kernels/test_kernels.zig

# Load testing
mix loadtest --concurrent 1000 --duration 60

# Multi-node testing  
MIX_ENV=test mix test.cluster
```

---

## Deployment Architecture

### Single Region Deployment

```yaml
# docker-compose.yml for single region
version: '3.8'
services:
  warp_engine_1:
    image: warp_engine:latest
    environment:
      - WARP_REGION=us-west
      - WARP_NODE_NAME=warp@node1
      - CUDA_VISIBLE_DEVICES=0
    ports:
      - "4000:4000"
    volumes:
      - ./data/node1:/opt/warp_engine/data
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

  warp_engine_2:
    image: warp_engine:latest  
    environment:
      - WARP_REGION=us-west
      - WARP_NODE_NAME=warp@node2
      - CUDA_VISIBLE_DEVICES=1
    ports:
      - "4001:4000"
    volumes:
      - ./data/node2:/opt/warp_engine/data
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

### Global Multi-Region Deployment

```yaml
# Global deployment with Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: warp-engine-us-west
  namespace: warp-engine
spec:
  replicas: 3
  selector:
    matchLabels:
      app: warp-engine
      region: us-west
  template:
    metadata:
      labels:
        app: warp-engine
        region: us-west
    spec:
      containers:
      - name: warp-engine
        image: warpengine/warp-engine:latest
        env:
        - name: WARP_REGION  
          value: "us-west"
        - name: WARP_CLUSTER_SECRET
          valueFrom:
            secretKeyRef:
              name: warp-cluster-secret
              key: secret
        resources:
          requests:
            nvidia.com/gpu: 1
            memory: "4Gi"
            cpu: "2"
          limits:
            nvidia.com/gpu: 1
            memory: "8Gi"  
            cpu: "4"
        ports:
        - containerPort: 4000
        - containerPort: 45892  # Cluster communication
```

---

## Performance Benchmarks & Validation

### Benchmark Suite Structure

```elixir
# benchmarks/spatial_benchmarks.ex
defmodule WarpEngine.SpatialBenchmarks do
  use Benchee
  
  def run_benchmarks do
    # Object insertion benchmark
    Benchee.run(%{
      "insert_objects_cpu" => fn -> insert_objects_cpu(10_000) end,
      "insert_objects_gpu" => fn -> insert_objects_gpu(10_000) end,
      "insert_objects_hybrid" => fn -> insert_objects_hybrid(10_000) end
    },
    time: 10,
    memory_time: 2,
    warmup: 2
    )
    
    # Spatial query benchmarks  
    Benchee.run(%{
      "bbox_query_small" => fn -> bbox_query({37.7, -122.5, 37.8, -122.4}, 1000) end,
      "bbox_query_large" => fn -> bbox_query({37.0, -123.0, 38.0, -122.0}, 10000) end,
      "radius_query" => fn -> radius_query({37.7749, -122.4194}, 1000, 100) end,
      "polygon_query" => fn -> polygon_query(complex_polygon(), 5000) end
    },
    time: 15,
    warmup: 3
    )
    
    # Geofencing benchmarks
    Benchee.run(%{
      "geofence_check_1k" => fn -> check_geofences(1_000_objects(), 100_fences()) end,
      "geofence_check_10k" => fn -> check_geofences(10_000_objects(), 1_000_fences()) end,
      "geofence_check_gpu" => fn -> gpu_geofence_check(100_000_objects(), 10_000_fences()) end
    },
    time: 20,
    warmup: 5
    )
    
    # Physics optimization benchmarks
    Benchee.run(%{
      "gravitational_routing" => fn -> calculate_gravitational_routing(shards(), objects()) end,
      "quantum_entanglement" => fn -> update_quantum_entanglements(access_patterns()) end,
      "entropy_calculation" => fn -> calculate_system_entropy(cluster_state()) end
    },
    time: 10,
    warmup: 2
    )
  end
end
```

### Expected Performance Targets

```elixir
# Performance validation thresholds
defmodule WarpEngine.PerformanceTargets do
  @targets %{
    # Spatial operations (ops/second)
    point_insertions: %{
      cpu: 100_000,
      gpu: 1_000_000,
      hybrid: 2_000_000
    },
    
    bbox_queries: %{
      small_area: 500_000,    # <1km² bounding box
      medium_area: 200_000,   # 1-100km² 
      large_area: 50_000      # >100km²
    },
    
    geofence_checks: %{
      simple_polygon: 100_000,  # Per second per geofence
      complex_polygon: 10_000,
      massive_parallel: 1_000_000  # GPU: all objects vs all fences
    },
    
    # Real-time capabilities
    websocket_connections: 100_000,    # Concurrent connections
    real_time_updates: 1_000_000,      # Updates/second across all connections
    cross_region_latency: 50,          # milliseconds
    
    # Physics optimizations
    gravitational_routing: 10_000,     # Routing decisions/second  
    quantum_entanglement_updates: 50_000,  # Entanglement calculations/second
    entropy_rebalancing: 1000          # Objects rebalanced/second
  }
  
  def validate_performance(benchmark_results) do
    Enum.all?(@targets, fn {category, thresholds} ->
      validate_category(benchmark_results[category], thresholds)
    end)
  end
end
```

---

## Monitoring & Observability

### Metrics Collection

```elixir
# lib/warp_engine/metrics.ex
defmodule WarpEngine.Metrics do
  use GenServer
  require Logger
  
  # Spatial operation metrics
  def record_spatial_query(type, latency_us, result_count) do
    :telemetry.execute([:warp_engine, :spatial_query], %{
      latency_us: latency_us,
      result_count: result_count
    }, %{query_type: type})
  end
  
  def record_geofence_event(geofence_id, object_id, trigger_type) do
    :telemetry.execute([:warp_engine, :geofence_triggered], %{count: 1}, %{
      geofence_id: geofence_id,
      trigger_type: trigger_type
    })
  end
  
  # Physics metrics  
  def record_physics_calculation(type, computation_time_us, objects_processed) do
    :telemetry.execute([:warp_engine, :physics_calculation], %{
      computation_time_us: computation_time_us,
      objects_processed: objects_processed
    }, %{calculation_type: type})
  end
  
  # GPU metrics
  def record_gpu_operation(kernel_name, execution_time_us, memory_usage) do
    :telemetry.execute([:warp_engine, :gpu_operation], %{
      execution_time_us: execution_time_us,
      memory_usage_bytes: memory_usage
    }, %{kernel: kernel_name})
  end
  
  # System health metrics
  def record_system_health do
    cluster_entropy = WarpEngine.Physics.EntropyMonitor.current_entropy()
    shard_distribution = WarpEngine.Cluster.shard_distribution()
    gpu_utilization = WarpEngine.GPU.utilization_stats()
    
    :telemetry.execute([:warp_engine, :system_health], %{
      entropy: cluster_entropy,
      gpu_utilization: gpu_utilization.percentage,
      active_shards: length(shard_distribution)
    }, %{})
  end
end
```

### Grafana Dashboard Metrics

```yaml
# Prometheus metrics configuration
warp_engine_metrics:
  spatial_operations_total:
    type: counter
    help: "Total number of spatial operations performed"
    labels: [operation_type, region, shard_id]
    
  spatial_query_duration_seconds:
    type: histogram
    help: "Duration of spatial queries in seconds"  
    labels: [query_type, index_type]
    buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0, 5.0]
    
  geofence_checks_total:
    type: counter
    help: "Total geofence trigger events"
    labels: [trigger_type, geofence_id]
    
  physics_calculations_total:
    type: counter
    help: "Physics-inspired optimization calculations"
    labels: [calculation_type, optimization_enabled]
    
  gpu_kernel_execution_seconds:
    type: histogram  
    help: "GPU kernel execution time"
    labels: [kernel_name, device_id]
    buckets: [0.0001, 0.001, 0.01, 0.1, 1.0]
    
  cluster_entropy_ratio:
    type: gauge
    help: "Current cluster entropy (0=unbalanced, 1=perfectly balanced)"
    labels: [region]
    
  websocket_connections_active:
    type: gauge
    help: "Active WebSocket connections"
    labels: [channel_type, region]
    
  cross_region_latency_seconds:
    type: histogram
    help: "Cross-region operation latency" 
    labels: [source_region, target_region]
    buckets: [0.01, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0]
```

---

## Error Handling & Fault Tolerance

### Erlang/OTP Supervision Strategy

```elixir
# lib/warp_engine/application.ex
defmodule WarpEngine.Application do
  use Application
  
  def start(_type, _args) do
    children = [
      # Core storage supervision tree
      {WarpEngine.StorageSupervisor, []},
      
      # Spatial operations supervision tree  
      {WarpEngine.SpatialSupervisor, []},
      
      # GPU operations supervision tree
      {WarpEngine.GPUSupervisor, []},
      
      # Physics optimization supervision tree
      {WarpEngine.PhysicsSupervisor, []},
      
      # Cluster coordination
      {WarpEngine.ClusterSupervisor, []},
      
      # Metrics and monitoring
      {WarpEngine.MetricsSupervisor, []}
    ]
    
    opts = [strategy: :one_for_one, name: WarpEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# Fault-tolerant GPU operations
defmodule WarpEngine.GPUSupervisor do
  use Supervisor
  
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  def init(_init_arg) do
    children = [
      # GPU device managers (one per GPU)
      {WarpEngine.GPU.DeviceManager, device_id: 0},
      {WarpEngine.GPU.DeviceManager, device_id: 1},
      
      # GPU memory pool manager
      {WarpEngine.GPU.MemoryManager, []},
      
      # Kernel execution coordinator
      {WarpEngine.GPU.KernelCoordinator, []},
      
      # Fallback CPU coordinator (for GPU failures)
      {WarpEngine.CPU.FallbackCoordinator, []}
    ]
    
    # If any GPU component fails, restart only that component
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 60)
  end
end
```

### GPU Failure Recovery

```elixir
defmodule WarpEngine.GPU.DeviceManager do
  use GenServer
  require Logger
  
  def handle_call({:execute_kernel, kernel, params}, _from, state) do
    case WarpEngine.SpatialNIF.execute_cuda_kernel(kernel, params) do
      {:ok, result} -> 
        {:reply, {:ok, result}, state}
        
      {:error, :gpu_memory_error} ->
        Logger.warn("GPU memory error, attempting recovery")
        case recover_gpu_memory(state) do
          :ok -> 
            # Retry operation after recovery
            case WarpEngine.SpatialNIF.execute_cuda_kernel(kernel, params) do
              {:ok, result} -> {:reply, {:ok, result}, state}
              {:error, reason} -> fallback_to_cpu(kernel, params, state)
            end
          {:error, _} -> 
            fallback_to_cpu(kernel, params, state)
        end
        
      {:error, :gpu_device_error} ->
        Logger.error("GPU device error, falling back to CPU")
        fallback_to_cpu(kernel, params, state)
        
      {:error, reason} ->
        Logger.error("Unexpected GPU error: #{inspect(reason)}")
        fallback_to_cpu(kernel, params, state)
    end
  end
  
  defp fallback_to_cpu(kernel, params, state) do
    Logger.info("Executing #{kernel} on CPU fallback")
    result = WarpEngine.CPU.FallbackCoordinator.execute_operation(kernel, params)
    {:reply, result, %{state | gpu_available: false}}
  end
end
```

### Network Partition Handling

```elixir
defmodule WarpEngine.Cluster.PartitionHandler do
  use GenServer
  require Logger
  
  def handle_info({:nodedown, node}, state) do
    Logger.warn("Node #{node} went down, initiating partition recovery")
    
    # Determine if we're in a minority partition
    active_nodes = [Node.self() | Node.list()]
    total_expected_nodes = Application.get_env(:warp_engine, :expected_cluster_size, 3)
    
    if length(active_nodes) >= div(total_expected_nodes, 2) + 1 do
      # We're in majority partition, continue operations
      handle_majority_partition(node, state)
    else
      # We're in minority partition, switch to read-only mode
      handle_minority_partition(node, state)
    end
  end
  
  defp handle_majority_partition(failed_node, state) do
    # Redistribute shards from failed node
    failed_shards = WarpEngine.Cluster.get_shards_for_node(failed_node)
    
    Enum.each(failed_shards, fn shard ->
      # Find optimal backup node using gravitational routing
      backup_node = WarpEngine.Physics.GravitationalRouter.find_optimal_node(
        shard, Node.list()
      )
      
      # Migrate shard data
      WarpEngine.Storage.migrate_shard(shard, backup_node)
    end)
    
    {:noreply, state}
  end
  
  defp handle_minority_partition(_failed_node, state) do
    # Switch to read-only mode to prevent split-brain
    Logger.warn("Switching to read-only mode due to network partition")
    WarpEngine.Cluster.set_mode(:read_only)
    {:noreply, %{state | mode: :read_only}}
  end
end
```

---

## Security Considerations

### API Authentication & Authorization

```elixir
defmodule WarpWebAuth.APIAuth do
  import Plug.Conn
  require Logger
  
  def init(opts), do: opts
  
  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> validate_token(conn, token)
      [] -> send_unauthorized(conn, "Missing authorization header")
      _ -> send_unauthorized(conn, "Invalid authorization format")
    end
  end
  
  defp validate_token(conn, token) do
    case WarpEngine.Auth.verify_jwt(token) do
      {:ok, claims} -> 
        conn
        |> assign(:current_user, claims["user_id"])
        |> assign(:api_scopes, claims["scopes"] || [])
        |> assign(:rate_limit_key, claims["user_id"])
        
      {:error, reason} -> 
        Logger.warn("JWT validation failed: #{reason}")
        send_unauthorized(conn, "Invalid token")
    end
  end
  
  # Scope-based authorization for different operations
  def require_scope(conn, required_scope) do
    user_scopes = conn.assigns[:api_scopes] || []
    
    if required_scope in user_scopes do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Insufficient permissions", required_scope: required_scope})
      |> halt()
    end
  end
end

# Usage in controllers
defmodule WarpWeb.SpatialController do
  use WarpWeb, :controller
  
  plug WarpWebAuth.APIAuth
  plug :require_scope, "spatial:read" when action in [:search, :get_object]
  plug :require_scope, "spatial:write" when action in [:create_object, :update_object]
  plug :require_scope, "spatial:admin" when action in [:bulk_import, :rebalance]
end
```

### Rate Limiting

```elixir
defmodule WarpWeb.RateLimiter do
  use GenServer
  
  # Different rate limits for different operation types
  @rate_limits %{
    "spatial:read" => {1000, :per_minute},      # 1000 reads per minute
    "spatial:write" => {100, :per_minute},      # 100 writes per minute  
    "geofence:create" => {10, :per_minute},     # 10 geofence creations per minute
    "admin:operations" => {5, :per_minute}      # 5 admin operations per minute
  }
  
  def check_rate_limit(user_id, operation_type) do
    {limit, period} = @rate_limits[operation_type]
    key = "#{user_id}:#{operation_type}"
    
    case :ets.lookup(:rate_limits, key) do
      [] -> 
        :ets.insert(:rate_limits, {key, 1, current_window(period)})
        :ok
        
      [{^key, count, window}] when window == current_window(period) ->
        if count < limit do
          :ets.update_counter(:rate_limits, key, {2, 1})
          :ok
        else
          {:error, :rate_limit_exceeded, limit, period}
        end
        
      [{^key, _count, _old_window}] ->
        # Reset counter for new time window
        :ets.insert(:rate_limits, {key, 1, current_window(period)})
        :ok
    end
  end
  
  defp current_window(:per_minute), do: div(System.system_time(:second), 60)
  defp current_window(:per_hour), do: div(System.system_time(:second), 3600)
end
```

### Input Validation & Sanitization

```elixir
defmodule WarpEngine.InputValidator do
  # Validate geographic coordinates
  def validate_coordinates(lat, lon) when is_number(lat) and is_number(lon) do
    cond do
      lat < -90.0 or lat > 90.0 ->
        {:error, "Latitude must be between -90 and 90 degrees"}
      lon < -180.0 or lon > 180.0 ->
        {:error, "Longitude must be between -180 and 180 degrees"}  
      true ->
        {:ok, {Float.round(lat, 8), Float.round(lon, 8)}}
    end
  end
  
  def validate_coordinates(_, _), do: {:error, "Coordinates must be numbers"}
  
  # Validate bounding box
  def validate_bbox(min_lat, min_lon, max_lat, max_lon) do
    with {:ok, {min_lat, min_lon}} <- validate_coordinates(min_lat, min_lon),
         {:ok, {max_lat, max_lon}} <- validate_coordinates(max_lat, max_lon) do
      cond do
        min_lat >= max_lat -> {:error, "min_lat must be less than max_lat"}
        min_lon >= max_lon -> {:error, "min_lon must be less than max_lon"}
        abs(max_lat - min_lat) > 10.0 -> {:error, "Bounding box too large (max 10 degrees)"}
        abs(max_lon - min_lon) > 10.0 -> {:error, "Bounding box too large (max 10 degrees)"}
        true -> {:ok, {min_lat, min_lon, max_lat, max_lon}}
      end
    end
  end
  
  # Validate and sanitize GeoJSON
  def validate_geojson(geojson) when is_map(geojson) do
    case geojson do
      %{"type" => "Point", "coordinates" => [lon, lat]} when is_number(lon) and is_number(lat) ->
        validate_coordinates(lat, lon)
        
      %{"type" => "Polygon", "coordinates" => [exterior_ring | _]} ->
        validate_polygon_ring(exterior_ring)
        
      %{"type" => type} when type in ["LineString", "MultiPoint", "MultiPolygon"] ->
        # Additional validation for other geometry types
        validate_complex_geometry(geojson)
        
      _ ->
        {:error, "Invalid or unsupported GeoJSON geometry"}
    end
  end
  
  def validate_geojson(_), do: {:error, "GeoJSON must be a map"}
  
  # Prevent geometry complexity attacks
  defp validate_polygon_ring(coordinates) when is_list(coordinates) do
    cond do
      length(coordinates) < 4 ->
        {:error, "Polygon ring must have at least 4 coordinates"}
      length(coordinates) > 10_000 ->
        {:error, "Polygon ring too complex (max 10,000 vertices)"}
      true ->
        # Validate each coordinate pair
        Enum.reduce_while(coordinates, {:ok, []}, fn [lon, lat], {:ok, acc} ->
          case validate_coordinates(lat, lon) do
            {:ok, coord} -> {:cont, {:ok, [coord | acc]}}
            error -> {:halt, error}
          end
        end)
    end
  end
end
```

---

## Deployment & Operations Guide

### Docker Configuration

```dockerfile
# Dockerfile for WarpEngine
FROM nvidia/cuda:12.0-devel-ubuntu22.04 as builder

# Install Elixir and Erlang
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    autoconf \
    m4 \
    libncurses5-dev \
    libwxgtk3.0-gtk3-dev \
    libwxgtk-webview3.0-gtk3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libpng-dev \
    libssh-dev \
    unixodbc-dev \
    xsltproc \
    fop \
    libxml2-utils \
    libncurses-dev \
    openjdk-11-jdk

# Install Zig
RUN curl -L https://ziglang.org/download/0.12.0/zig-linux-x86_64-0.12.0.tar.xz | tar -xJ && \
    mv zig-linux-x86_64-0.12.0 /opt/zig && \
    ln -s /opt/zig/zig /usr/local/bin/zig

# Install Erlang and Elixir via asdf
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
RUN echo '. ~/.asdf/asdf.sh' >> ~/.bashrc
RUN ~/.asdf/bin/asdf plugin add erlang
RUN ~/.asdf/bin/asdf plugin add elixir
RUN ~/.asdf/bin/asdf install erlang 26.2.2
RUN ~/.asdf/bin/asdf install elixir 1.16.1-otp-26
RUN ~/.asdf/bin/asdf global erlang 26.2.2
RUN ~/.asdf/bin/asdf global elixir 1.16.1-otp-26

WORKDIR /app
COPY . .

# Build native components
RUN cd native/warp_spatial_nif && \
    zig build -Doptimize=ReleaseFast -Dcuda=true

# Build Elixir application
RUN . ~/.asdf/asdf.sh && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    MIX_ENV=prod mix compile && \
    MIX_ENV=prod mix release

# Production image
FROM nvidia/cuda:12.0-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y \
    libssl3 \
    libncurses6 \
    locales \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

WORKDIR /app

# Copy built application
COPY --from=builder /app/_build/prod/rel/warp_engine ./

# Create non-root user
RUN useradd -ms /bin/bash warpengine
RUN chown -R warpengine:warpengine /app
USER warpengine

EXPOSE 4000
CMD ["./bin/warp_engine", "start"]
```

### Kubernetes Deployment

```yaml
# k8s/warp-engine-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: warp-engine
  namespace: warp-engine
  labels:
    app: warp-engine
spec:
  replicas: 3
  selector:
    matchLabels:
      app: warp-engine
  template:
    metadata:
      labels:
        app: warp-engine
    spec:
      affinity:
        # Ensure pods are distributed across nodes
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - warp-engine
              topologyKey: kubernetes.io/hostname
      containers:
      - name: warp-engine
        image: warpengine/warp-engine:latest
        ports:
        - containerPort: 4000
          name: http
        - containerPort: 45892
          name: cluster
        env:
        - name: WARP_REGION
          value: "us-west"
        - name: WARP_NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: WARP_CLUSTER_SECRET
          valueFrom:
            secretKeyRef:
              name: warp-cluster-secret
              key: secret
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: url
        - name: CUDA_VISIBLE_DEVICES
          value: "0"
        resources:
          requests:
            nvidia.com/gpu: 1
            memory: "4Gi"
            cpu: "2"
          limits:
            nvidia.com/gpu: 1
            memory: "8Gi"
            cpu: "4"
        livenessProbe:
          httpGet:
            path: /api/v1/admin/health
            port: 4000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/v1/admin/ready
            port: 4000
          initialDelaySeconds: 10
          periodSeconds: 5
        volumeMounts:
        - name: data-storage
          mountPath: /app/data
      volumes:
      - name: data-storage
        persistentVolumeClaim:
          claimName: warp-engine-data
---
apiVersion: v1
kind: Service
metadata:
  name: warp-engine-service
  namespace: warp-engine
spec:
  selector:
    app: warp-engine
  ports:
  - name: http
    port: 80
    targetPort: 4000
  - name: cluster
    port: 45892
    targetPort: 45892
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: warp-engine-ingress
  namespace: warp-engine
  annotations:
    nginx.ingress.kubernetes.io/websocket-services: "warp-engine-service"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.warpengine.example.com
    secretName: warp-engine-tls
  rules:
  - host: api.warpengine.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: warp-engine-service
            port:
              number: 80
```

### Terraform Infrastructure

```hcl
# terraform/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# EKS Cluster with GPU node groups
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = "warp-engine-${var.environment}"
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  # GPU-enabled node group for WarpEngine workloads
  eks_managed_node_groups = {
    gpu_nodes = {
      name = "warp-engine-gpu"
      
      instance_types = ["p3.2xlarge"]  # Tesla V100 GPUs
      
      min_size     = 3
      max_size     = 10
      desired_size = 3
      
      k8s_labels = {
        workload = "gpu-intensive"
        app      = "warp-engine"
      }
      
      taints = {
        nvidia_gpu = {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
    
    # CPU-only nodes for supporting services
    cpu_nodes = {
      name = "warp-engine-cpu"
      
      instance_types = ["m5.xlarge"]
      
      min_size     = 2
      max_size     = 5
      desired_size = 2
      
      k8s_labels = {
        workload = "general"
      }
    }
  }
}

# RDS for metadata storage
resource "aws_db_instance" "warp_engine_metadata" {
  identifier = "warp-engine-${var.environment}"
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.r6g.xlarge"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_encrypted     = true
  
  db_name  = "warpengine"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  performance_insights_enabled = true
  
  tags = {
    Name        = "WarpEngine-${var.environment}"
    Environment = var.environment
  }
}

# ElastiCache Redis for caching
resource "aws_elasticache_replication_group" "warp_engine_cache" {
  replication_group_id       = "warp-engine-${var.environment}"
  description                = "WarpEngine Redis Cache"
  
  node_type            = "cache.r6g.xlarge"
  port                 = 6379
  parameter_group_name = "default.redis7"
  
  num_cache_clusters = 3
  
  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  tags = {
    Name        = "WarpEngine-Cache-${var.environment}"
    Environment = var.environment
  }
}

# S3 bucket for WAL and backup storage
resource "aws_s3_bucket" "warp_engine_storage" {
  bucket = "warp-engine-${var.environment}-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "WarpEngine-Storage-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "warp_engine_storage" {
  bucket = aws_s3_bucket.warp_engine_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "warp_engine_storage" {
  bucket = aws_s3_bucket.warp_engine_storage.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "warp_engine_logs" {
  name              = "/aws/eks/warp-engine-${var.environment}"
  retention_in_days = 30
  
  tags = {
    Name        = "WarpEngine-Logs-${var.environment}"
    Environment = var.environment
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "warpengine"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}
```

---

## Initial Implementation Tasks

### Phase 1: Core Foundation (Weeks 1-4)

```bash
# Task 1: Project scaffolding
mix new warp_engine --umbrella --sup
cd apps/
mix new warp_engine --sup
mix new warp_web --sup
mix new warp_benchmark --sup

# Task 2: Basic Elixir data structures
# Implement in lib/warp_engine/geo_object.ex
# Implement in lib/warp_engine/geofence.ex
# Implement in lib/warp_engine/spatial/engine.ex

# Task 3: Basic Zig NIF setup
mkdir native/warp_spatial_nif/
cd native/warp_spatial_nif/
# Set up build.zig and basic NIF functions

# Task 4: Simple spatial operations (CPU-only)
# Implement basic R-tree in Zig
# Point-in-polygon algorithms
# Bounding box queries

# Task 5: Basic HTTP API
# Implement CRUD operations for spatial objects
# Basic spatial search endpoints
# Input validation and error handling
```

### Phase 2: GPU Integration (Weeks 5-8)

```bash
# Task 1: CUDA kernel development
# Implement spatial_query.cu
# Implement geofence_check.cu
# Basic GPU memory management in Zig

# Task 2: GPU-accelerated spatial queries
# Integrate CUDA kernels with Zig NIF
# Parallel bounding box searches
# Batch geofence checking

# Task 3: Performance benchmarking
# Implement comprehensive benchmark suite
# Compare CPU vs GPU performance
# Memory usage profiling

# Task 4: Error handling and fallback
# GPU failure detection and recovery
# CPU fallback implementation
# Graceful degradation strategies
```

### Phase 3: Physics Optimizations (Weeks 9-12)

```bash
# Task 1: Gravitational routing
# Implement physics calculations in Elixir
# CUDA kernel for parallel routing decisions
# Shard placement optimization

# Task 2: Quantum entanglement system
# Access pattern tracking
# Correlation analysis algorithms
# Predictive prefetching implementation

# Task 3: Entropy monitoring
# System balance measurements
# Automatic rebalancing triggers
# Load distribution optimization

# Task 4: Integration testing
# End-to-end physics optimization tests
# Performance validation
# System stability under load
```

### Phase 4: Distribution & Real-time (Weeks 13-16)

```bash
# Task 1: Multi-node clustering
# Implement cluster coordination
# Node discovery and health monitoring
# Cross-region communication

# Task 2: WebSocket real-time features
# Implement Phoenix channels
# Real-time spatial update streaming
# Geofence event broadcasting

# Task 3: Global deployment
# Docker containerization
# Kubernetes manifests
# Terraform infrastructure as code

# Task 4: Production readiness
# Monitoring and observability
# Security implementation
# Performance optimization
```

---

## Testing Strategy

### Unit Tests

```elixir
# test/warp_engine/spatial/engine_test.exs
defmodule WarpEngine.Spatial.EngineTest do
  use ExUnit.Case, async: true
  
  setup do
    {:ok, _pid} = WarpEngine.start_link()
    :ok
  end
  
  describe "object storage and retrieval" do
    test "stores and retrieves geo objects" do
      object = %WarpEngine.GeoObject{
        id: "test-point-1",
        coordinates: {37.7749, -122.4194},
        geometry: :point,
        properties: %{"name" => "San Francisco"}
      }
      
      assert {:ok, :stored, shard_id, _time} = WarpEngine.cosmic_put(object.id, object)
      assert {:ok, retrieved_object, ^shard_id, _time} = WarpEngine.cosmic_get(object.id)
      assert retrieved_object.coordinates == object.coordinates
    end
    
    test "handles invalid coordinates" do
      invalid_object = %WarpEngine.GeoObject{
        id: "invalid-point",
        coordinates: {91.0, -200.0},  # Invalid lat/lon
        geometry: :point,
        properties: %{}
      }
      
      assert {:error, :invalid_coordinates} = WarpEngine.cosmic_put(invalid_object.id, invalid_object)
    end
  end
  
  describe "spatial queries" do
    test "finds objects within bounding box" do
      # Insert test objects
      objects = [
        {"sf-point", {37.7749, -122.4194}},
        {"oakland-point", {37.8044, -122.2711}},
        {"la-point", {34.0522, -118.2437}}  # Outside bay area
      ]
      
      Enum.each(objects, fn {id, {lat, lon}} ->
        object = %WarpEngine.GeoObject{id: id, coordinates: {lat, lon}, geometry: :point}
        WarpEngine.cosmic_put(id, object)
      end)
      
      # Query bay area bounding box
      bbox = {37.0, -123.0, 38.0, -122.0}
      {:ok, results} = WarpEngine.bbox_search(bbox)
      
      result_ids = Enum.map(results, & &1.id)
      assert "sf-point" in result_ids
      assert "oakland-point" in result_ids
      refute "la-point" in result_ids
    end
  end
end
```

### Integration Tests

```elixir
# test/integration/multi_node_test.exs
defmodule WarpEngine.Integration.MultiNodeTest do
  use ExUnit.Case
  
  @moduletag :integration
  
  setup_all do
    # Start multiple nodes for testing
    nodes = [:node1@localhost, :node2@localhost, :node3@localhost]
    
    Enum.each(nodes, fn node ->
      {:ok, _} = :slave.start_link(:localhost, node)
      :ok = :rpc.call(node, Application, :ensure_all_started, [:warp_engine])
    end)
    
    on_exit(fn ->
      Enum.each(nodes, &:slave.stop/1)
    end)
    
    {:ok, nodes: nodes}
  end
  
  test "distributes objects across nodes", %{nodes: [node1, node2, node3]} do
    # Insert objects on different nodes
    objects = for i <- 1..100 do
      object = %WarpEngine.GeoObject{
        id: "object-#{i}",
        coordinates: {:rand.uniform() * 180 - 90, :rand.uniform() * 360 - 180},
        geometry: :point
      }
      
      # Insert on random node
      node = Enum.random([node1, node2, node3])
      :rpc.call(node, WarpEngine, :cosmic_put, [object.id, object])
      
      object
    end)
    
    # Verify objects can be retrieved from any node
    Enum.each(objects, fn object ->
      query_node = Enum.random([node1, node2, node3])
      {:ok, retrieved, _shard, _time} = :rpc.call(query_node, WarpEngine, :cosmic_get, [object.id])
      assert retrieved.id == object.id
    end)
  end
  
  test "handles node failures gracefully", %{nodes: [node1, node2, node3]} do
    # Insert objects
    for i <- 1..50 do
      object = %WarpEngine.GeoObject{id: "fail-test-#{i}", coordinates: {0, i}, geometry: :point}
      :rpc.call(node1, WarpEngine, :cosmic_put, [object.id, object])
    end
    
    # Simulate node1 failure
    :slave.stop(node1)
    Process.sleep(2000)  # Allow cluster to detect failure
    
    # Verify objects are still accessible from remaining nodes
    {:ok, result} = :rpc.call(node2, WarpEngine, :cosmic_get, ["fail-test-1"])
    assert result.id == "fail-test-1"
  end
end
```

### Performance Tests

```elixir
# test/performance/gpu_benchmark_test.exs
defmodule WarpEngine.Performance.GPUBenchmarkTest do
  use ExUnit.Case
  
  @moduletag :performance
  @moduletag timeout: 300_000  # 5 minutes
  
  test "GPU spatial queries outperform CPU" do
    # Generate large dataset
    objects = for i <- 1..100_000 do
      %WarpEngine.GeoObject{
        id: "perf-test-#{i}",
        coordinates: {:rand.uniform() * 180 - 90, :rand.uniform() * 360 - 180},
        geometry: :point,
        properties: %{"index" => i}
      }
    end
    
    # Insert all objects
    Enum.each(objects, fn object ->
      WarpEngine.cosmic_put(object.id, object)
    end)
    
    # Benchmark CPU vs GPU spatial queries
    bbox = {37.0, -122.0, 38.0, -121.0}
    
    # CPU benchmark
    {cpu_time, cpu_results} = :timer.tc(fn ->
      WarpEngine.bbox_search(bbox, backend: :cpu)
    end)
    
    # GPU benchmark  
    {gpu_time, gpu_results} = :timer.tc(fn ->
      WarpEngine.bbox_search(bbox, backend: :gpu)
    end)
    
    # Verify results are equivalent
    assert length(cpu_results) == length(gpu_results)
    
    # GPU should be significantly faster for large datasets
    speedup = cpu_time / gpu_time
    IO.puts("GPU speedup: #{Float.round(speedup, 2)}x")
    assert speedup > 2.0  # At least 2x faster
  end
  
  test "geofence checking scales with GPU" do
    # Create many geofences
    geofences = for i <- 1..1_000 do
      %WarpEngine.Geofence{
        id: "geofence-#{i}",
        geometry: generate_random_polygon(),
        rules: [%{trigger: :enter, webhook_url: "http://example.com/#{i}"}]
      }
    end
    
    # Create many objects
    objects = for i <- 1..10_000 do
      %WarpEngine.GeoObject{
        id: "mobile-#{i}",
        coordinates: {:rand.uniform() * 180 - 90, :rand.uniform() * 360 - 180},
        geometry: :point
      }
    end
    
    # Benchmark geofence checking
    {time_us, triggered_events} = :timer.tc(fn ->
      WarpEngine.batch_geofence_check(objects, geofences)
    end)
    
    ops_per_second = length(objects) * length(geofences) / (time_us / 1_000_000)
    IO.puts("Geofence checks per second: #{Float.round(ops_per_second, 0)}")
    
    # Should handle at least 100K geofence checks per second
    assert ops_per_second > 100_000
  end
  
  defp generate_random_polygon do
    # Generate simple square polygon
    center_lat = :rand.uniform() * 180 - 90
    center_lon = :rand.uniform() * 360 - 180
    size = :rand.uniform() * 0.1  # Small polygon
    
    %{
      "type" => "Polygon",
      "coordinates" => [[
        [center_lon - size, center_lat - size],
        [center_lon + size, center_lat - size],
        [center_lon + size, center_lat + size],
        [center_lon - size, center_lat + size],
        [center_lon - size, center_lat - size]  # Close the ring
      ]]
    }
  end
end
```

---

## API Examples & Usage Patterns

### Basic Operations

```bash
# Create spatial objects
curl -X POST http://localhost:4000/api/v1/objects \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{
    "id": "restaurant-123",
    "coordinates": [37.7749, -122.4194],
    "geometry": {"type": "Point", "coordinates": [-122.4194, 37.7749]},
    "properties": {
      "name": "Best Pizza",
      "category": "restaurant",
      "rating": 4.5
    }
  }'

# Spatial search - find nearby restaurants
curl "http://localhost:4000/api/v1/search/nearby?lat=37.7749&lon=-122.4194&radius=1000&limit=10&category=restaurant" \
  -H "Authorization: Bearer $API_TOKEN"

# Bounding box search
curl "http://localhost:4000/api/v1/search/bbox?min_lat=37.7&min_lon=-122.5&max_lat=37.8&max_lon=-122.4" \
  -H "Authorization: Bearer $API_TOKEN"

# Create geofence
curl -X POST http://localhost:4000/api/v1/geofences \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -d '{
    "name": "Downtown SF",
    "geometry": {
      "type": "Polygon",
      "coordinates": [[
        [-122.4194, 37.7749],
        [-122.4094, 37.7749], 
        [-122.4094, 37.7849],
        [-122.4194, 37.7849],
        [-122.4194, 37.7749]
      ]]
    },
    "rules": [
      {"trigger": "enter", "webhook_url": "https://app.com/geofence/enter"},
      {"trigger": "exit", "webhook_url": "https://app.com/geofence/exit"}
    ]
  }'
```

### WebSocket Real-time Updates

```javascript
// JavaScript client for real-time spatial updates
import {Socket} from "phoenix"

const socket = new Socket("ws://localhost:4000/socket", {
  params: {token: API_TOKEN}
})

socket.connect()

// Subscribe to spatial updates in a region
const spatialChannel = socket.channel("spatial:updates", {
  bbox: {
    min_lat: 37.7,
    min_lon: -122.5,
    max_lat: 37.8,
    max_lon: -122.4
  },
  filters: {
    categories: ["vehicle", "delivery"],
    min_update_interval: 5000  // Only updates every 5 seconds
  }
})

spatialChannel.join()
  .receive("ok", resp => console.log("Joined spatial channel", resp))
  .receive("error", resp => console.log("Unable to join", resp))

// Handle real-time object updates
spatialChannel.on("object_entered", payload => {
  console.log("Object entered region:", payload.object)
  updateMapMarker(payload.object)
})

spatialChannel.on("object_exited", payload => {
  console.log("Object exited region:", payload.object)  
  removeMapMarker(payload.object.id)
})

spatialChannel.on("object_updated", payload => {
  console.log("Object moved:", payload.object)
  moveMapMarker(payload.object.id, payload.object.coordinates)
})

// Subscribe to geofence events
const geofenceChannel = socket.channel("geofence:events", {
  geofence_ids: ["downtown-sf", "mission-district"]
})

geofenceChannel.join()
geofenceChannel.on("geofence_triggered", payload => {
  console.log("Geofence triggered:", payload)
  showNotification(`${payload.object.name} ${payload.trigger} ${payload.geofence.name}`)
})
```

### Advanced Analytics

```bash
# Generate real-time heatmap
curl "http://localhost:4000/api/v1/analytics/heatmap?min_lat=37.7&min_lon=-122.5&max_lat=37.8&max_lon=-122.4&resolution=100&time_window=3600" \
  -H "Authorization: Bearer $API_TOKEN"

# Movement prediction
curl "http://localhost:4000/api/v1/analytics/predictions?object_id=vehicle-123&time_horizon=1800" \
  -H "Authorization: Bearer $API_TOKEN"

# Spatial statistics
curl "http://localhost:4000/api/v1/analytics/stats?category=delivery&time_window=86400" \
  -H "Authorization: Bearer $API_TOKEN"
```

---

## Migration from Existing Systems

### From Tile38

```bash
# Export data from Tile38
tile38-cli -p 9851 -c "OUTPUT JSON" > tile38_export.json
tile38-cli -p 9851 -c "SCAN fleet" >> tile38_export.json

# Convert and import to WarpEngine
python3 tools/migrate_tile38.py tile38_export.json | \
  curl -X POST http://localhost:4000/api/v1/admin/bulk_import \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    --data-binary @-
```

### From PostGIS

```sql
-- Export spatial data from PostGIS
COPY (
  SELECT 
    id,
    ST_AsGeoJSON(geom) as geometry,
    properties::json,
    created_at,
    updated_at
  FROM spatial_objects 
  WHERE active = true
) TO '/tmp/postgis_export.csv' CSV HEADER;
```

```bash
# Import to WarpEngine
python3 tools/migrate_postgis.py /tmp/postgis_export.csv | \
  curl -X POST http://localhost:4000/api/v1/admin/bulk_import \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    --data-binary @-
```

### Performance Comparison

| Feature | Tile38 | PostGIS + Redis | WarpEngine |
|---------|---------|-----------------|------------|
| **Point Insertions/sec** | 100K | 50K | 2M+ (GPU) |
| **Spatial Queries/sec** | 100K | 10K | 10M+ (GPU) |
| **Geofence Checks/sec** | 10K | 1K | 100K+ (GPU) |
| **Real-time Connections** | 10K | 5K | 100K+ |
| **Multi-region Support** | Manual | Complex | Built-in |
| **Auto-optimization** | None | Manual | AI-powered |

---

This completes the comprehensive WarpEngine project specification. The document provides everything needed for Cursor AI to understand and implement this hybrid Elixir+Zig+CUDA geospatial database system, from architecture overview to deployment strategies and migration guides.