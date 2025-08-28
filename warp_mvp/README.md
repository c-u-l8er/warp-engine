# WarpEngine MVP

A high-performance geospatial database with in-memory acceleration and HTTP API.

## Current Implementation Status

This MVP implements the core WarpEngine functionality as specified in `docs/mvp_low_risk_design.md`:

### ✅ Implemented Features

- **Core Data Types**: `GeoObject` with physics-inspired metadata
- **Input Validation**: Comprehensive validation for coordinates, bounding boxes, and GeoJSON
- **In-Memory Storage**: ETS-based shards with consistent hashing
- **Spatial Operations**: Bounding box and radius searches
- **HTTP API**: RESTful endpoints for CRUD operations and spatial queries
- **Telemetry**: Performance monitoring and metrics collection
- **Health Checks**: System health monitoring and statistics

### 🚧 Architecture Components

- **WarpEngine Core**: Main spatial database engine with shard management
- **WarpWeb**: Phoenix-based HTTP API and monitoring interface
- **Storage Layer**: In-memory shards with ETS tables
- **Validation**: Input sanitization and coordinate validation
- **Metrics**: Telemetry collection and Prometheus export

### 🔄 API Endpoints

```
POST   /api/v1/objects                    # Create spatial object
GET    /api/v1/objects/:id               # Get object by ID  
PUT    /api/v1/objects/:id               # Update object
DELETE /api/v1/objects/:id               # Delete object

GET    /api/v1/search/bbox               # Bounding box search
GET    /api/v1/search/nearby             # Radius search

GET    /api/v1/admin/health              # System health
GET    /api/v1/admin/stats               # System statistics
GET    /api/v1/admin/metrics             # Prometheus metrics

GET    /health                           # Basic health check
```

## Getting Started

### Prerequisites

- Elixir 1.17+
- Erlang/OTP 26+
- PostgreSQL 15+ (for future persistence)
- Redis 7+ (for future caching)

### Development Setup

1. **Install dependencies**:
   ```bash
   mix deps.get
   ```

2. **Start development services**:
   ```bash
   docker-compose up -d
   ```

3. **Start WarpEngine**:
   ```bash
   # Start the core engine
   iex -S mix -app warp_engine
   
   # Start the web interface
   iex -S mix -app warp_web
   ```

4. **Run tests**:
   ```bash
   mix test
   ```

### Usage Examples

#### Store a spatial object:
```elixir
{:ok, :stored, shard_id, time} = WarpEngine.put("restaurant-1", %{
  coordinates: {37.7749, -122.4194},
  properties: %{"name" => "Best Pizza", "rating" => 4.5}
})
```

#### Retrieve an object:
```elixir
{:ok, object, shard_id, time} = WarpEngine.get("restaurant-1")
```

#### Spatial search:
```elixir
# Bounding box search
{:ok, results} = WarpEngine.bbox_search({37.7, -122.5, 37.8, -122.4})

# Radius search
{:ok, results} = WarpEngine.radius_search({37.7749, -122.4194}, 1000)
```

#### HTTP API:
```bash
# Create object
curl -X POST http://localhost:4000/api/v1/objects \
  -H "Content-Type: application/json" \
  -d '{
    "id": "restaurant-1",
    "coordinates": [37.7749, -122.4194],
    "properties": {"name": "Best Pizza", "rating": 4.5}
  }'

# Search nearby
curl "http://localhost:4000/api/v1/search/nearby?lat=37.7749&lon=-122.4194&radius=1000"
```

## Configuration

### Environment Variables

- `WARP_SHARD_COUNT`: Number of shards (default: CPU cores × 2)
- `PORT`: Web server port (default: 4000)

### Configuration Files

- `config/config.exs`: Main configuration
- `config/dev.exs`: Development settings
- `config/test.exs`: Test settings

## Performance Targets (MVP)

- **Insertions**: ≥ 50K inserts/min sustained
- **Queries**: ≥ 20K bbox queries/min on 1M points
- **Latency**: P95 API latency < 150ms under nominal load

## Monitoring

- **Health Check**: `/health` endpoint
- **Metrics**: `/api/v1/admin/metrics` (Prometheus format)
- **Dashboard**: `/admin/dashboard` (Phoenix LiveDashboard)
- **Statistics**: `/api/v1/admin/stats`

## Development

### Project Structure

```
warp_mvp/
├── apps/
│   ├── warp_engine/          # Core database engine
│   ├── warp_web/             # Web interface
│   └── warp_benchmark/       # Performance testing
├── config/                    # Configuration files
├── docker-compose.yml         # Development services
└── README.md
```

### Key Modules

- `WarpEngine.GeoObject`: Core spatial data type
- `WarpEngine.InputValidator`: Input validation and sanitization
- `WarpEngine.Storage.Shard`: In-memory shard management
- `WarpEngine.Storage.ShardManager`: Shard coordination and routing
- `WarpWeb.SpatialController`: HTTP API endpoints
- `WarpEngine.Telemetry.MetricsCollector`: Performance monitoring

## Testing

Run the test suite:

```bash
# All tests
mix test

# Specific app tests
mix test apps/warp_engine/test/
mix test apps/warp_web/test/

# With coverage
mix test --cover
```

## Next Steps

This MVP provides the foundation for:

1. **Storage Adapters**: PostgreSQL persistence and Redis caching
2. **GPU Acceleration**: CUDA kernels for spatial operations
3. **Physics Optimizations**: Gravitational routing and quantum entanglement
4. **Clustering**: Multi-node distribution and cross-region capabilities
5. **Real-time Features**: WebSocket channels and LiveView dashboards

## Contributing

1. Follow the MVP design specifications in `docs/mvp_low_risk_design.md`
2. Ensure all tests pass: `mix test`
3. Follow Elixir coding standards: `mix format`
4. Add comprehensive documentation for new features

## License

[License information to be added]

