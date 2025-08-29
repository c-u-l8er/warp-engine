# WarpEngine MVP (Low-Risk) Design
## CPU-only, Single-Node Vertical Slice

### Purpose
Reduce execution risk and deliver a reviewable, working MVP quickly by deferring GPU/NIF, clustering, and physics features. This document supersedes broader ambitions for the MVP milestone only.

### Goals
- Minimal HTTP API: object CRUD, bbox and radius searches (CPU-only)
- Deterministic correctness with centralized validation
- Durability via Postgres; optional Redis cache-aside reads
- Basic observability (Telemetry + Prometheus)
- Security baseline (JWT auth, sane TLS defaults)

### Non-goals (vNext behind feature flags)
- GPU/CUDA kernels and Zig NIF integration
- Physics-inspired features (gravitational routing, entanglement, entropy)
- Multi-node clustering and cross-region capabilities
- Complex WebSockets and LiveView dashboards

### Scope
- API endpoints
  - POST/GET/PUT/DELETE `/api/v1/objects/:id`
  - GET `/api/v1/search/bbox?min_lat=&min_lon=&max_lat=&max_lon=`
  - GET `/api/v1/search/nearby?lat=&lon=&radius=`
- In-memory shards (ETS)
  - N shards, consistent hashing, CRUD against ETS
  - Write-through to Postgres on success
  - Cache-aside read via Redis when available
- Storage adapter: Postgres (Ecto)
  - Minimal schema: `spatial_objects(id text pk, lat float, lon float, properties jsonb, inserted_at, updated_at)`
  - Optionally store GeoJSON in JSONB for future geometry types
- Cache adapter: Redis (optional)
  - Read-through with TTL; invalidate on write/delete
  - If Redis unavailable, proceed without cache
- Validation
  - Single `InputValidator`: coordinates, bbox, GeoJSON sanity
  - Consistent `{lat, lon}` tuples internally; GeoJSON `[lon, lat]` at the edge
- Security
  - JWT via Joken; scope check plugs for write endpoints
  - No `verify: :verify_none`; use system roots or pinned CAs in prod
- Observability
  - :telemetry events for API, storage, cache, shards
  - Prometheus exporter; minimal Grafana panels (RPS, P95 latency, DB timings)
- PubSub
  - Use `Phoenix.PubSub` with `:pg` adapter (no PG2)

### Acceptance Criteria
- Functional
  - CRUD works end-to-end with Postgres durability
  - `bbox_search` and `radius_search` return correct results on a seeded dataset
  - Redis cache improves read latency when enabled; falls back cleanly when down
- Performance (CPU-only, realistic)
  - ≥ 50K inserts/min sustained on a single node
  - ≥ 20K bbox queries/min on 1M points, small-to-medium bbox
  - P95 API latency < 150ms under nominal load (dev hardware)
- Quality
  - 100% tests pass in CI; Credo and Dialyzer pass; formatted
  - Prometheus metrics exposed; basic dashboard loads
  - JWT required for write routes; validation rejects bad inputs

### Feature Flags (default: off)
- `gpu_enabled` (GPU/NIF)
- `physics_enabled` (routing/entropy/entanglement)
- `clustering_enabled` (multi-node)
- `websockets_enabled` (channels)

### Risks Explicitly Deferred
- BEAM scheduler blocking by long NIFs (none used in MVP)
- CUDA build/link complexity and dev env drift (none used in MVP)
- Distributed rate limiting and consensus (single-node only)

### Implementation Order
1) Domain + Validation: `GeoObject` + `InputValidator`
2) ETS shards with consistent hashing (single node)
3) Postgres adapter (Ecto Repo + schema)
4) Minimal API (CRUD, bbox, radius)
5) Redis cache (optional) + invalidation
6) Telemetry + Prometheus + basic dashboard JSON
7) Security baseline (Joken JWT + scope plugs)
8) CI (format, Credo, Dialyzer, tests) and Docker Compose (app+PG+Redis)

### References
- Main architecture: `project_spec_and_architecture.md` (vNext vision)
- Templates: `code_templates_and_examples.md` (use CPU-only parts for MVP)
- Prompts guide: `cursor_ai_implementation_prompts.md` (follow with flags off)

### Decision Log (MVP)
- 2025-08-28: Adopt CPU-only, single-node MVP to reduce execution risk; GPU/physics/clustering moved behind flags for later milestones.



