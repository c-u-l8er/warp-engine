## Phase 9 Performance Hardening Guide (Bench + Production)

### TL;DR
- Keep the request critical path to ETS + lock‑free WAL only. No per‑op calls, spawns, or lookups.
- Offload physics via cast to a coordinator (GPU pipeline), with sampling.
- Use deterministic numbered routing in benches so GET is single‑table; avoid shard scans.
- Reduce logging to warn in benches; increase schedulers and widen concurrency levels.

---

### Primary hotspots to remove from the hot path
- Per‑op GenServer.call/2
  - Intelligent Load Balancer uses `GenServer.call` today. In benches, prefer deterministic routing or make ILB a pure read from ETS.
  - Legacy WAL/WALShard calls must be avoided; use lock‑free WAL ETS path only.

- Per‑op Task.start/1 spawns
  - Cache backfill and physics updates must not spawn a process per request. Use a single coordinator process and `GenServer.cast` batched events.

- Chatty Logger in hot paths
  - Even debug logs add overhead. In benches, set console level to `:warn`.

- Process lookups at request time
  - Avoid `Process.whereis/1` in routing/paths. Choose routing mode once via config and use a precomputed function.

- Shard scans
  - GET must be a single-table lookup under numbered shards. Fallback shard scans should be rare.

---

### Changes implemented (in this branch)
- Deterministic numbered routing toggle (default true) so GET hits a single ETS table.
- Cache-aware GET path with sampled cache backfill.
- Write-through cache on PUT (sampled) to lift cache hit rates without heavy overhead.
- Physics sampling and offload control:
  - Enhanced ADT fields support `physics_offload: :cast | :call` next to `physics: ...`.
  - `cosmic_put_v2` reads ADT offload preference; default is `:cast` (fire‑and‑forget to GPU coordinator).
  - Entanglement/caching work is sampled to cap overhead.
- Bench script: WAL readiness wait/auto‑start and deterministic routing enabled.

---

### Next edits recommended (actionable)
1) Replace per‑op backfill Task.start with a coordinator cast
   - Create `WarpEngine.CacheCoordinator` (GenServer): accepts `{:backfill, key, value, shard}` via `GenServer.cast`, batches, and writes to Event Horizon Cache.
   - In `wal_operations` GET/PUT, replace `Task.start(fn -> cache_retrieved_value_async(...) end)` with a single `GenServer.cast(CacheCoordinator, {:backfill, key, value, shard})` (still sampled).

2) Intelligent routing without per‑op calls
   - Add an ETS‑backed reader (pure function) for ILB weights; avoid `GenServer.call` for per‑op routing.
   - Keep deterministic routing for benchmarks; allow ILB in prod by swapping the function (config flag).

3) Remove dynamic process lookups from the hot path
   - Don’t call `Process.whereis/1` at request time; route mode decided once from config on startup.

4) Quiet logs in the benchmark
   - At the start of `benchmarks/large_dataset_feature_validation.exs`:
     ```elixir
     Logger.configure(level: :warn)
     Logger.configure_backend(:console, level: :warn)
     :erlang.system_flag(:schedulers_online, System.schedulers_online())
     ```
   - Optionally widen concurrency levels to `[1,2,4,8,12,16,24,32]` to test scaling.

5) Keep GET single‑table and minimize fallbacks
   - Ensure `:deterministic_numbered_routing` is true in benches.
   - Keep legacy 3‑shard probe as a last‑chance fallback only.

---

### Physics/GPU pipeline expectations
- Request path:
  - PUT: route shard → `:ets.insert` → lock‑free WAL ETS append → return.
  - GET: cache check → hashed single‑table ETS lookup → return.
- Offloaded physics:
  - Request enqueues a tiny event (cast). A coordinator batches and calls `WarpEngine.GPU.PhysicsEngine`. Results are written to ETS/caches (e.g., `:quantum_pattern_cache`, router weights) and read by subsequent requests. No waiting.

---

### Validation plan
1) WAL‑only bench (already green): confirm 300k–650k+ ops/sec across 1–12 processes.
2) Large dataset bench:
   - Expect higher ops/sec and better scaling with logs quiet + no per‑op spawns + single‑table GET.
   - Cache hit metric should be non‑N/A after write‑through/backfill sampling.
3) Toggle tests:
   - Set `:physics_offload_default` to `:call` to verify sync path still works.
   - Disable deterministic routing to test ILB’s pure reader, ensure no `GenServer.call` on hot path.

---

### Feature flags and example configuration
```elixir
# routing
config :warp_engine,
  deterministic_numbered_routing: true,
  use_numbered_shards: true,
  num_numbered_shards: 24

# physics offload & sampling
config :warp_engine,
  physics_offload_default: :cast,        # :cast | :call
  physics_sample_rate_put_deafult: 16,           # 1/N puts perform physics
  cache_write_through_on_put_default: true,
  cache_sample_rate_put_default: 8,
  cache_sample_rate_get_default: 4

# logging (bench)
# set Logger.configure in the benchmark script to :warn
```

Example ADT field with offload preference:
```elixir
defproduct User do
  field :preferences :: UserPreferences.t(), physics: :quantum_entanglement_group, physics_offload: :cast, physics_sample_rate_put: 100, cache_write_through_on_put: true, cache_sample_rate_put: 16, cache_sample_rate_get: 8
  field :activity_score :: float(), physics: :gravitational_mass, physics_offload: :call
end
```

---

### Rollback
- All new behavior is behind flags; disabling deterministic routing, physics sampling, or offload simply reverts to prior behavior.


