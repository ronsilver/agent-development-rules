---
name: Optimize
description: Analyze and optimize code for performance, efficiency, and scalability
version: "1.0"
trigger: manual
tags:
  - performance
  - analysis
  - optimization
  - scalability
---

# Optimize

Analyze and optimize code for performance. **Measure before optimizing** — never optimize without evidence of a bottleneck.

## Optimization Philosophy

> "Premature optimization is the root of all evil." — Donald Knuth

1. **Profile** before guessing
2. **Measure** before and after
3. **Optimize** the bottleneck, not everything
4. **Document** why the optimization was needed

## Optimization Process

### Step 1: Identify the Bottleneck

| Tool | Language | Command |
|------|----------|---------|
| `pprof` | Go | `go tool pprof cpu.prof` |
| `py-spy` | Python | `py-spy top --pid <PID>` |
| `clinic` | Node.js | `npx clinic doctor -- node app.js` |
| `perf` | Rust/C/C++ | `perf record ./binary && perf report` |
| `EXPLAIN ANALYZE` | SQL | Run before query optimization |

### Step 2: Analyze Complexity

| Current | Target | Technique |
|---------|--------|-----------|
| O(n²) | O(n log n) | Sort + binary search, divide & conquer |
| O(n²) | O(n) | Hash maps for lookups, two pointers |
| O(n) | O(1) | Caching, precomputation, amortization |
| O(n) | O(log n) | Binary search, balanced trees |

### Step 3: Apply Targeted Optimization

Select the appropriate strategy based on the bottleneck type:

#### 1. Database Queries

| Anti-Pattern | Impact | Solution |
|-------------|--------|----------|
| N+1 queries | O(n) round trips | Eager loading, JOINs, batch queries |
| Missing indexes | Full table scans | Add indexes on WHERE/JOIN/ORDER BY columns |
| SELECT * | Excess data transfer | Select only needed columns |
| No pagination | Memory explosion | Use LIMIT/OFFSET or cursor-based pagination |
| Unoptimized queries | Slow response | Use EXPLAIN ANALYZE, add CTEs |

```sql
-- ❌ N+1: One query per user for orders
SELECT * FROM users;
-- Then for EACH user: SELECT * FROM orders WHERE user_id = ?

-- ✅ Single JOIN
SELECT u.*, o.* FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.active = true;
```

#### 2. Caching Strategies

| Strategy | Use Case | TTL |
|----------|----------|-----|
| **In-memory** (local) | Config, constants, computed values | App lifetime |
| **Request-scoped** | Repeated lookups within one request | Request duration |
| **Distributed** (Redis) | Shared state, sessions, API responses | Minutes to hours |
| **CDN** | Static assets, public API responses | Hours to days |

```python
# ❌ Recomputes on every call
def get_user_permissions(user_id):
    return db.query("SELECT ... complex join ...")

# ✅ Cache with TTL
@cache(ttl=300)  # 5 minutes
def get_user_permissions(user_id):
    return db.query("SELECT ... complex join ...")
```

#### 3. Algorithm & Data Structure

| Problem | Slow | Fast |
|---------|------|------|
| Membership check | `list` O(n) | `set`/`dict` O(1) |
| Sorted insertion | Array O(n) | Balanced tree O(log n) |
| String building | Concatenation O(n²) | `StringBuilder`/`join` O(n) |
| Repeated search | Linear scan O(n) | Binary search O(log n) |

```python
# ❌ O(n) lookup per item → O(n²) total
for item in items:
    if item in large_list:  # O(n) scan
        process(item)

# ✅ O(1) lookup per item → O(n) total
large_set = set(large_list)  # One-time O(n) conversion
for item in items:
    if item in large_set:    # O(1) lookup
        process(item)
```

#### 4. Concurrency & I/O

| Pattern | When | Implementation |
|---------|------|----------------|
| **Async I/O** | Multiple I/O-bound tasks | `asyncio`, `goroutines`, `Promise.all` |
| **Worker pool** | CPU-bound parallelism | `multiprocessing`, goroutine pool |
| **Batch processing** | Many small operations | Group into batches of 100-1000 |
| **Streaming** | Large datasets | Generators, iterators, chunked reads |

```go
// ❌ Sequential API calls — O(n) latency
for _, url := range urls {
    resp, _ := http.Get(url)  // Blocks each time
}

// ✅ Concurrent — O(1) latency (bounded)
var wg sync.WaitGroup
sem := make(chan struct{}, 10)  // Max 10 concurrent
for _, url := range urls {
    wg.Add(1)
    sem <- struct{}{}
    go func(u string) {
        defer wg.Done()
        defer func() { <-sem }()
        http.Get(u)
    }(url)
}
wg.Wait()
```

#### 5. Memory Optimization

| Issue | Detection | Fix |
|-------|-----------|-----|
| Large allocations | Profiler shows heap growth | Pre-allocate, reuse buffers |
| Memory leaks | Steady RAM increase | Close resources, clear references |
| Excessive copies | Profiler shows alloc hotspots | Pass by pointer/reference |
| Unbounded collections | OOM crashes | Set max sizes, use LRU eviction |

## Constraints — NON-NEGOTIABLE

| Rule | Description |
|------|-------------|
| ✅ **Measure first** | Profile and benchmark before any change |
| ✅ **Correctness preserved** | Same inputs must produce same outputs |
| ✅ **Tests pass** | All existing tests must pass after optimization |
| ✅ **Document trade-offs** | Note what was sacrificed (readability, memory, etc.) |
| ❌ **No premature optimization** | Only optimize proven bottlenecks |
| ❌ **No micro-optimizations** | Unless in a proven hot path |

## Report Format

~~~markdown
## Optimization Summary

**Target:** `src/services/order_service.py::get_orders()`
**Bottleneck:** N+1 query pattern — 1 + n database calls per request

### Before
- Response time: ~800ms (p95) for 100 orders
- DB queries: 101 per request

### After
- Response time: ~45ms (p95) for 100 orders
- DB queries: 1 per request (JOIN)

### Trade-offs
- Slightly more complex query
- Higher memory per request (all data loaded at once)
~~~

## Instructions

1. **Profile** the code to identify the actual bottleneck
2. **Measure** current performance (latency, throughput, memory)
3. **Analyze** complexity (Big-O) of the hot path
4. **Propose** optimization with expected improvement
5. **Implement** one change at a time
6. **Verify** correctness (tests pass) and measure improvement
7. **Document** the optimization and trade-offs
