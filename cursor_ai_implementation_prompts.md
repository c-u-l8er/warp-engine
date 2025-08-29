# WarpEngine: Cursor AI Implementation Guide
## Step-by-Step Prompts for Cursor

> MVP notice: Execute Phase 1 with GPU/NIF, physics, clustering, and complex WebSockets disabled. Follow `docs/mvp_low_risk_design.md`. Use feature flags to defer advanced components.

This document provides specific prompts to use with Cursor AI for implementing WarpEngine from scratch, positioning WarpEngine as a high-performance spatial compute/indexing engine. Durability and caching are provided via pluggable storage/cache adapters (e.g., Postgres + Redis), and indices/shards act as acceleration layers updated via CDC.

---

## Phase 1: Project Initialization

### Prompt 1: Create Project Structure

```
Create a new Elixir umbrella project called "warp_engine" with the following structure:

1. Main umbrella project with these child applications:
   - warp_engine: Core database engine
   - warp_web: Web interface and real-time APIs  
   - warp_benchmark: Performance testing

2. Native directory structure:
   - native/warp_spatial_nif/: Zig NIF library
   - native/cuda_kernels/: CUDA kernel implementations

3. Configuration files:
   - mix.exs for umbrella and each app
   - config/ directory with environment configs
   - docker-compose.yml for development
   - .gitignore with Elixir/Zig/CUDA entries

4. Initial dependencies in mix.exs:
   - Jason for JSON
   - Phoenix for web interface
   - Phoenix PubSub for real-time
   - Benchee for performance testing
   - Zigler for Zig NIFs

Please create all directory structures and basic configuration files.
```

### Prompt 2: Implement Core Data Types

```
Based on the WarpEngine specification, implement the core Elixir data types:

1. Create lib/warp_engine/geo_object.ex with:
   - GeoObject struct with all specified fields
   - Type specifications for geometry types
   - Validation functions for coordinates and geometry
   - Conversion functions to/from GeoJSON

2. Create lib/warp_engine/geofence.ex with:
   - Geofence struct with geometry and rules
   - GeofenceRule embedded schema
   - Validation for polygon complexity
   - Trigger type validations (:enter, :exit, :inside, :outside)

3. Create lib/warp_engine/physics/state.ex with:
   - Physics.State struct for optimization metadata
   - Functions for calculating data mass, energy levels
   - Gravitational constant definitions
   - Entropy calculation helpers

Include comprehensive @doc documentation and @spec type specifications for all functions.
```

### Prompt 3: Basic NIF Setup

```
Create the foundational Zig NIF structure for WarpEngine:

1. In native/warp_spatial_nif/, create:
   - build.zig with proper CUDA linking
   - src/main.zig as the NIF entry point
   - zigler.exs configuration file

2. Implement basic NIF functions in main.zig:
   - validate_coordinates/2: Validate lat/lon ranges
   - haversine_distance/4: Calculate distance between points
   - point_in_bbox/6: Check if point is in bounding box
   - calculate_geohash/3: Generate geohash for coordinates

3. Create the Elixir wrapper in lib/warp_engine/nif/spatial_nif.ex:
   - Load the NIF library
   - Provide Elixir function wrappers
   - Error handling for NIF failures
   - Fallback CPU implementations

4. Include basic error handling and graceful degradation if GPU is not available.

Make sure all functions have proper error handling and return {:ok, result} or {:error, reason} tuples.
```

---

## Phase 2: Core Storage Engine

### Prompt 4: Implement Shard & Adapter Management

```
Implement the in-memory shard/index acceleration layer and storage/cache adapters:

1. Create lib/warp_engine/storage/shard.ex with:
   - Shard GenServer that manages an ETS table
   - CRUD operations (put/get/delete) for geo objects
   - Physics metadata tracking (access frequency, data mass)
   - Shard statistics (object count, memory usage)

2. Create lib/warp_engine/storage/shard_manager.ex with:
   - ShardManager GenServer that coordinates multiple shards
   - Dynamic shard creation based on system cores
   - Load balancing across shards using consistent hashing
   - Shard health monitoring and recovery

3. Implement gravitational routing in lib/warp_engine/physics/gravitational_router.ex:
   - calculate_optimal_shard/2 function using physics formulas
   - Shard gravitational mass calculations
   - Distance-based routing decisions
   - Integration with shard selection logic

4. Define storage/cache behaviours and adapters:
   - lib/warp_engine/storage/adapter.ex: Storage behaviour (put/get/delete/batch, start_link)
   - lib/warp_engine/storage/cache.ex: Cache behaviour (get/set/invalidate)
   - lib/warp_engine/storage/adapters/postgres.ex: Authoritative storage via Ecto
   - lib/warp_engine/storage/adapters/redis_cache.ex: Read-through cache

5. Add CDC subscriber to keep indices warm:
   - lib/warp_engine/storage/cdc_subscriber.ex: Subscribe to Postgres logical replication or Kafka; update indices

6. Add configuration options for:
   - Number of shards (default: System.schedulers_online() * 2)
   - Physics optimization toggles
   - ETS table options (compressed, write_concurrency)
   - Storage adapter selection and credentials
   - Cache adapter selection and connection details

Include proper supervision tree structure and crash recovery mechanisms.
```

### Prompt 5: Spatial Indexing (CPU/GPU) with Cache-Aside

```
Implement spatial indexing for efficient queries with cache-aside reads and CDC-driven updates:

1. Create lib/warp_engine/spatial/index_manager.ex:
   - IndexManager GenServer for coordinating spatial indices
   - Support for multiple index types (R-tree, Quadtree, Geohash)
   - Index selection based on query type and data characteristics
   - Index maintenance and rebuilding

2. Implement R-tree in Zig (native/warp_spatial_nif/src/spatial/rtree.zig):
   - RTreeNode structure optimized for GPU memory layout
   - Insert/delete/query operations
   - Bounding box calculations and intersection tests
   - Memory-efficient node packing

3. Create spatial query functions in lib/warp_engine/spatial/engine.ex:
   - bbox_search/1: Find objects within bounding box
   - radius_search/3: Find objects within radius of point
   - polygon_search/1: Find objects within arbitrary polygon
   - nearest_neighbors/3: K-nearest neighbor search

4. Implement query optimization:
   - Index selection based on query type
   - Query result caching with TTL
   - Statistics collection for query performance
   - Automatic index rebuilding when performance degrades
   - Cache-aside reads; write-behind updates to storage adapter

Each function should support both CPU and GPU backends with automatic fallback.
```

---

## Phase 3: GPU Acceleration

### Prompt 6: CUDA Kernel Implementation

```
Implement CUDA kernels for parallel spatial operations:

1. Create native/cuda_kernels/spatial_query.cu:
   - bbox_search_kernel: Parallel bounding box intersection
   - radius_search_kernel: Parallel distance calculations
   - nearest_neighbors_kernel: Parallel k-NN search
   - Optimized for high thread occupancy and memory coalescing

2. Create native/cuda_kernels/geofence_check.cu:
   - point_in_polygon_kernel: Parallel point-in-polygon tests
   - batch_geofence_check_kernel: Check all objects vs all geofences
   - Use shared memory for frequently accessed geofence data
   - Atomic operations for thread-safe result writing

3. Create native/cuda_kernels/physics_simulation.cu:
   - gravitational_routing_kernel: Parallel shard attraction calculations
   - entropy_calculation_kernel: Parallel entropy measurements
   - quantum_entanglement_kernel: Correlation analysis
   - Use CUDA math libraries for physics calculations

4. Implement GPU memory management in native/warp_spatial_nif/src/cuda/memory.zig:
   - Memory pool allocation for frequently used data
   - Asynchronous memory transfers
   - Memory usage monitoring and garbage collection
   - Error handling for out-of-memory conditions

All kernels should be optimized for modern GPU architectures (compute capability 7.5+) and include proper error checking.
```

### Prompt 7: GPU Integration Layer

```
Create the integration layer between Elixir and CUDA kernels. Emphasize batching, pinned buffers, and streams to amortize PCIe and NIF overhead:

1. Implement native/warp_spatial_nif/src/cuda/kernels.zig:
   - Wrapper functions for all CUDA kernels
   - Parameter marshaling between Elixir and CUDA (use page-locked host memory for large batches)
   - Stream-based asynchronous execution
   - Result collection and error handling

2. Create lib/warp_engine/gpu/coordinator.ex:
   - GPUCoordinator GenServer for managing GPU resources
   - Batch operation queuing and execution
   - GPU device health monitoring
   - Automatic fallback to CPU when GPU unavailable

3. Implement lib/warp_engine/gpu/memory_manager.ex:
   - GPU memory pool management
   - Object caching in GPU memory
   - Memory usage monitoring and cleanup
   - Optimal memory transfer strategies

4. Add GPU-accelerated functions to spatial engine:
   - Modify spatial/engine.ex to use GPU when available
   - Implement batched operations for better GPU utilization
   - Add performance monitoring and metrics collection
   - Include GPU vs CPU performance comparisons

Include comprehensive error handling for GPU failures and graceful degradation to CPU-only operation.
```

---

## Phase 4: Real-time Features

### Prompt 8: WebSocket Real-time System

```
Implement the real-time WebSocket system for spatial updates:

1. Create lib/warp_web/channels/spatial_channel.ex:
   - Handle client subscriptions to spatial regions (bounding boxes)
   - Real-time streaming of object enter/exit/update events
   - Subscription filtering (object types, update frequency)
   - Connection scaling optimizations

2. Create lib/warp_web/channels/geofence_channel.ex:
   - Handle geofence event subscriptions
   - Real-time geofence trigger notifications
   - Support for multiple geofence subscriptions per client
   - Event batching to reduce message frequency

3. Implement lib/warp_engine/real_time/event_broadcaster.ex:
   - PubSub integration for cross-node event distribution
   - Event deduplication and ordering
   - Rate limiting and backpressure handling
   - Metrics collection for real-time performance

4. Create lib/warp_engine/real_time/subscription_manager.ex:
   - Manage spatial and geofence subscriptions
   - Efficient subscription lookups using spatial indexing
   - Subscription cleanup for disconnected clients
   - Load balancing across Phoenix channels

Include proper authentication, rate limiting, and connection management for production use.
```

### Prompt 9: Geofencing System

```
Implement comprehensive geofencing capabilities:

1. Create lib/warp_engine/geofence/manager.ex:
   - GeofenceManager GenServer for managing active geofences
   - Efficient geofence storage and retrieval using spatial indexing
   - Real-time geofence activation/deactivation
   - Geofence rule evaluation and webhook triggering

2. Implement lib/warp_engine/geofence/checker.ex:
   - Batch geofence checking for multiple objects
   - Integration with GPU kernels for parallel checking
   - Event generation for geofence triggers
   - Debouncing to prevent duplicate events

3. Create lib/warp_engine/geofence/event_handler.ex:
   - Process geofence trigger events
   - Webhook notifications with retry logic
   - Event logging and metrics collection
   - Integration with real-time broadcasting

4. Add geofence HTTP API endpoints in lib/warp_web/controllers/geofence_controller.ex:
   - CRUD operations for geofences
   - Bulk geofence operations
   - Geofence testing and validation
   - Performance statistics and monitoring

Include support for complex polygons, circular geofences, and custom trigger conditions.
```

---

## Phase 5: Physics Optimizations

### Prompt 10: Quantum Entanglement System

```
Implement the quantum entanglement system for predictive prefetching:

1. Create lib/warp_engine/physics/quantum_entanglement.ex:
   - Track object access patterns and correlations
   - Calculate quantum correlation coefficients using statistical methods
   - Maintain entanglement matrices for related objects
   - Automatic entanglement strength decay over time

2. Implement lib/warp_engine/physics/correlation_analyzer.ex:
   - Analyze historical access patterns to discover relationships
   - Use statistical correlation algorithms (Pearson, Spearman)
   - Identify spatial and temporal access correlations
   - Generate entanglement recommendations

3. Create lib/warp_engine/cache/predictive_cache.ex:
   - Implement predictive prefetching based on entanglements
   - Cache hit rate optimization using quantum predictions
   - Memory-efficient cache eviction strategies
   - Performance metrics for prefetching accuracy

4. Add quantum operations to the main API:
   - quantum_get/1: Get object with entangled prefetching
   - create_entanglement/3: Manually create object relationships
   - analyze_access_patterns/1: Generate correlation reports
   - optimize_entanglements/0: Trigger optimization process

Include GPU-accelerated correlation calculations for large datasets and comprehensive performance monitoring.
```

### Prompt 11: Entropy Monitoring & Load Balancing

```
Implement entropy-based system monitoring and automatic load balancing:

1. Create lib/warp_engine/physics/entropy_monitor.ex:
   - Calculate Shannon entropy for shard load distribution
   - Monitor system balance in real-time
   - Detect load imbalances and trigger rebalancing
   - Historical entropy tracking and trend analysis

2. Implement lib/warp_engine/physics/rebalancer.ex:
   - Automatic data migration between shards
   - Minimize rebalancing overhead using physics calculations
   - Gradual rebalancing to avoid performance spikes
   - Integration with gravitational routing decisions

3. Create lib/warp_engine/monitoring/system_health.ex:
   - Comprehensive system health monitoring
   - Performance metrics collection and aggregation
   - Alert generation for system anomalies
   - Dashboard data preparation for real-time visualization

4. Add entropy visualization in lib/warp_web/live/entropy_dashboard_live.ex:
   - Real-time entropy monitoring dashboard
   - Historical entropy charts and trends
   - Shard load distribution visualization
   - Manual rebalancing controls for administrators

Include configurable entropy thresholds, rebalancing cooldown periods, and comprehensive logging of all rebalancing operations.
```

---

## Phase 6: Clustering & Distribution

### Prompt 12: Multi-Node Clustering

```
Implement multi-node clustering for global distribution:

1. Create lib/warp_engine/cluster/coordinator.ex:
   - Cluster formation and node discovery
   - Health monitoring and failure detection
   - Cross-node communication and coordination
   - Cluster membership management

2. Implement lib/warp_engine/cluster/partition_router.ex:
   - Geographic partitioning of data across regions
   - Routing decisions based on data locality
   - Cross-region query coordination
   - Network partition handling and split-brain prevention

3. Create lib/warp_engine/cluster/node_manager.ex:
   - Individual node management and configuration
   - Resource usage monitoring and reporting
   - Node-specific optimization and tuning
   - Graceful node shutdown and recovery

4. Add cluster management API in lib/warp_web/controllers/admin_controller.ex:
   - Cluster status and health endpoints
   - Node addition and removal operations
   - Performance monitoring across the cluster
   - Emergency cluster operations (maintenance mode, etc.)

Include proper consensus mechanisms for cluster decisions and comprehensive network partition recovery.
```

### Prompt 13: Cross-Region Operations

```
Implement cross-region data operations and consistency:

1. Create lib/warp_engine/cluster/cross_region_coordinator.ex:
   - Manage operations spanning multiple geographic regions
   - Optimize for network latency and data locality
   - Coordinate global queries and aggregations
   - Handle region failures and failover

2. Implement lib/warp_engine/replication/region_replicator.ex:
   - Asynchronous data replication between regions
   - Conflict resolution for concurrent updates
   - Replication lag monitoring and optimization
   - Selective replication based on data importance

3. Create lib/warp_engine/cluster/global_query_engine.ex:
   - Execute queries spanning multiple regions
   - Query result merging and deduplication
   - Performance optimization for global operations
   - Caching strategies for cross-region data

4. Add global monitoring in lib/warp_web/live/global_dashboard_live.ex:
   - World map showing all regions and their status
   - Cross-region latency monitoring
   - Global query performance metrics
   - Region-specific performance comparisons

Include support for data sovereignty requirements and configurable consistency levels.
```

---

## Phase 7: Performance & Production

### Prompt 14: Comprehensive Benchmarking

```
Implement a comprehensive benchmarking and performance testing system:

1. Create lib/warp_benchmark/spatial_benchmarks.ex:
   - Benchmark suite for all spatial operations
   - CPU vs GPU performance comparisons
   - Scalability testing with increasing data sizes
   - Memory usage profiling and optimization

2. Implement lib/warp_benchmark/concurrency_benchmarks.ex:
   - Multi-process and multi-node performance testing
   - WebSocket connection load testing
   - Real-time update throughput measurements
   - Geofencing performance under load

3. Create lib/warp_benchmark/physics_benchmarks.ex:
   - Benchmark physics optimization algorithms
   - Measure entropy calculation performance
   - Test gravitational routing efficiency
   - Validate quantum entanglement accuracy

4. Add automated performance regression testing:
   - Continuous benchmarking in CI/CD pipeline
   - Performance trend analysis and alerting
   - Automated performance report generation
   - Comparison with target performance metrics

Include detailed reporting, visualization of results, and integration with monitoring systems.
```

### Prompt 15: Production Monitoring & Observability

```
Implement comprehensive monitoring and observability for production deployment:

1. Create lib/warp_engine/telemetry/metrics_collector.ex:
   - Collect detailed performance metrics using :telemetry
   - Custom metrics for spatial operations and physics calculations
   - GPU utilization and performance monitoring
   - Real-time dashboard data aggregation

2. Implement lib/warp_engine/telemetry/distributed_tracing.ex:
   - Distributed tracing across multi-node operations
   - Cross-region operation tracking
   - Performance bottleneck identification
   - Request flow visualization

3. Create lib/warp_web/live/monitoring_dashboard_live.ex:
   - Real-time system monitoring dashboard
   - Performance metrics visualization
   - Alert management and notification system
   - Historical trend analysis and reporting

4. Add health check endpoints in lib/warp_web/controllers/health_controller.ex:
   - Comprehensive system health checks
   - Database connectivity and performance validation
   - GPU availability and performance testing
   - Cluster connectivity and cross-region latency

Include integration with Prometheus, Grafana, and popular APM tools, plus comprehensive alerting for production issues.
```

---

## Phase 8: Security & API

### Prompt 16: Authentication & Authorization

```
Implement comprehensive security for the WarpEngine API:

1. Create lib/warp_web/auth/jwt_auth.ex:
   - JWT token validation and verification
   - Scope-based authorization (spatial:read, spatial:write, admin)
   - Token refresh and expiration handling
   - Integration with external identity providers

2. Implement lib/warp_web/auth/rate_limiter.ex:
   - Operation-specific rate limiting
   - User-based and IP-based limits
   - Distributed rate limiting across cluster nodes
   - Graceful handling of rate limit violations

3. Create lib/warp_web/auth/api_key_manager.ex:
   - API key generation and management
   - Key-specific permissions and scopes
   - Usage tracking and analytics
   - Key rotation and security policies

4. Add security middleware in lib/warp_web/plugs/:
   - Input validation and sanitization plugs
   - SQL injection and XSS prevention
   - Request logging and audit trails
   - Security headers and CORS configuration

Include comprehensive security testing and vulnerability scanning integration.
```

### Prompt 17: Complete HTTP API

```
Implement the complete HTTP API for WarpEngine:

1. Create lib/warp_web/controllers/spatial_controller.ex:
   - All CRUD operations for spatial objects
   - Spatial search endpoints (bbox, radius, polygon)
   - Batch operations for bulk data management
   - Export/import functionality for data migration

2. Implement lib/warp_web/controllers/analytics_controller.ex:
   - Real-time spatial analytics endpoints
   - Heatmap generation with customizable parameters
   - Movement prediction and pattern analysis
   - Statistical reports and data insights

3. Create comprehensive API documentation:
   - OpenAPI/Swagger specification
   - Interactive API explorer
   - Code examples in multiple languages
   - Performance characteristics and rate limits

4. Add API versioning and backward compatibility:
   - Version negotiation through headers
   - Deprecation warnings and migration guides
   - Feature flagging for new capabilities
   - Comprehensive change logging

Include extensive integration tests, API response validation, and performance benchmarks for all endpoints.
```

---

## Deployment & DevOps Prompts

### Prompt 18: Container & Orchestration

```
Create production-ready containerization and orchestration:

1. Create optimized Dockerfile:
   - Multi-stage build for minimal production image
   - CUDA runtime integration
   - Security hardening and non-root user
   - Health check integration

2. Implement docker-compose.yml for development:
   - WarpEngine service with GPU support
   - PostgreSQL for metadata storage
   - Redis for caching and pub/sub
   - Monitoring stack (Prometheus, Grafana)

3. Create Kubernetes manifests in k8s/:
   - Deployment with GPU node affinity
   - Services and ingress configuration
   - ConfigMaps and Secrets management
   - HorizontalPodAutoscaler for scaling

4. Add Helm chart for easy deployment:
   - Parameterized configuration values
   - Multiple environment support (dev, staging, prod)
   - Resource limits and requests
   - Monitoring and observability integration

Include comprehensive deployment documentation and troubleshooting guides.
```

### Prompt 19: Infrastructure as Code

```
Create Terraform infrastructure for cloud deployment:

1. Create terraform/modules/warp-engine/:
   - EKS cluster with GPU node groups
   - RDS PostgreSQL for metadata
   - ElastiCache Redis for caching
   - S3 buckets for WAL and backups

2. Implement multi-region deployment:
   - VPC and networking configuration
   - Cross-region replication setup
   - Global load balancing
   - DNS and certificate management

3. Add monitoring infrastructure:
   - CloudWatch integration
   - Custom metrics and alarms
   - Log aggregation and analysis
   - Cost monitoring and optimization

4. Create deployment automation:
   - GitHub Actions or GitLab CI/CD pipelines
   - Automated testing and deployment
   - Blue-green deployment strategies
   - Rollback and disaster recovery procedures

Include comprehensive documentation for infrastructure management and scaling procedures.
```

---

## Testing Prompts

### Prompt 20: Comprehensive Test Suite

```
Create a comprehensive test suite covering all aspects of WarpEngine:

1. Unit tests for all modules:
   - Property-based testing for spatial operations
   - Physics algorithm validation
   - GPU kernel correctness testing
   - Error handling and edge cases

2. Integration tests:
   - Multi-node cluster testing
   - Cross-region operation validation
   - Real-time system end-to-end testing
   - Performance regression testing

3. Chaos engineering tests:
   - Network partition simulation
   - Node failure and recovery testing
   - GPU failure handling
   - Load testing under adverse conditions

4. Security testing:
   - Authentication and authorization testing
   - Input validation and injection testing
   - Rate limiting and DoS protection
   - Encryption and data protection validation

Include automated test execution, coverage reporting, and continuous testing in CI/CD pipelines.
```

---

## Final Integration Prompt

### Prompt 21: System Integration & Optimization

```
Perform final system integration and optimization:

1. End-to-end system testing:
   - Full workflow testing from data ingestion to real-time updates
   - Performance validation against target benchmarks
   - Stress testing with realistic workloads
   - Memory and resource usage optimization

2. Production readiness checklist:
   - Security audit and penetration testing
   - Performance tuning and optimization
   - Monitoring and alerting configuration
   - Documentation and operational runbooks

3. Migration tools and utilities:
   - Data import from Tile38 and PostGIS
   - Performance comparison tools
   - Migration validation and rollback procedures
   - Training materials and documentation

4. Launch preparation:
   - Load testing with production-scale data
   - Disaster recovery testing and procedures
   - Support and maintenance documentation
   - Performance monitoring and optimization guides

Include comprehensive deployment guides, troubleshooting documentation, and post-launch optimization recommendations.
```

---

## Usage Instructions for Cursor

### How to Use These Prompts:

1. **Sequential Implementation**: Use prompts in order, as later phases depend on earlier implementations.

2. **Iterative Development**: After each prompt, review the generated code and ask for refinements or optimizations.

3. **Testing Integration**: After every few prompts, ask Cursor to generate and run tests to validate the implementation.

4. **Performance Validation**: Regularly ask for benchmark implementations to verify performance targets are being met.

5. **Documentation Updates**: Request documentation updates as features are implemented.

### Example Follow-up Prompts:

```
"The spatial indexing implementation looks good, but can you optimize it for better GPU memory utilization?"

"Add comprehensive error handling and logging to the geofencing system we just implemented."

"Create unit tests for the quantum entanglement correlation calculations with property-based testing."

"Optimize the CUDA kernels for better occupancy on modern GPUs with compute capability 8.6."

"Add monitoring and metrics collection to the clustering system for production observability."
```

### Performance Validation Prompts:

```
"Generate a benchmark to validate that our GPU spatial queries achieve at least 10M ops/sec as specified."

"Create a load test to verify the system can handle 100K concurrent WebSocket connections."

"Implement a test to validate that gravitational routing provides better data locality than random distribution."

"Create a benchmark comparing our geofencing performance against Tile38 with identical workloads."
```

This systematic approach will guide Cursor through implementing the complete WarpEngine system while maintaining focus on the performance targets and architectural principles outlined in the specification.