---
name: performance-optimization
description: Analyze and optimize code for performance by profiling, identifying bottlenecks, and applying targeted fixes. Use when the user asks to optimize, profile, or improve performance, latency, or throughput.
license: MIT
---

# Performance Optimization

## Core Principle

> "Premature optimization is the root of all evil." — Donald Knuth

**Measure first.** Never optimize without evidence of a bottleneck.

## Workflow

### Step 1: Profile and Identify Bottleneck

| Language | CPU Profiler | Memory Profiler |
|----------|-------------|-----------------|
| **Go** | `go tool pprof cpu.prof` | `go tool pprof -alloc_space mem.prof` |
| **Python** | `py-spy top --pid <PID>` | `tracemalloc`, `memory_profiler` |
| **Node.js** | `clinic doctor -- node app.js` | `--inspect` + Chrome DevTools |
| **SQL** | `EXPLAIN ANALYZE <query>` | — |

```bash
# Go: generate profiles
go test -cpuprofile=cpu.prof -memprofile=mem.prof -bench .
go tool pprof -http=:8080 cpu.prof
```

### Step 2: Analyze Complexity

#### Data Structure Operations

| Data Structure | Access | Search | Insert | Delete |
|---------------|--------|--------|--------|--------|
| Array/List | O(1) | O(n) | O(n) | O(n) |
| HashMap/Dict | O(1) | O(1) | O(1) | O(1) |
| Set | - | O(1) | O(1) | O(1) |
| Binary Search | - | O(log n) | - | - |
| Sorted Array | O(1) | O(log n) | O(n) | O(n) |

#### Common Optimizations

| Current | Target | Technique |
|---------|--------|-----------|
| O(n²) | O(n log n) | Sort + binary search |
| O(n²) | O(n) | Hash maps for lookups |
| O(n) | O(1) | Caching, precomputation |
| O(n) | O(log n) | Binary search, balanced trees |

#### Anti-Pattern: O(n²) Loops

```python
# ❌ Bad — O(n*m) = O(n²)
def find_common(list_a, list_b):
    result = []
    for item in list_a:           # O(n)
        if item in list_b:        # O(m) — list search!
            result.append(item)
    return result                  # Total: O(n*m)

# ✅ Good — O(n+m) ≈ O(n)
def find_common(list_a, list_b):
    set_b = set(list_b)           # O(m)
    return [item for item in list_a if item in set_b]  # O(n)
```

```python
# ❌ Bad — nested loops with repeated DB queries
for order in orders:
    for item in order.items:
        product = db.query(Product).get(item.product_id)  # N*M queries!

# ✅ Good — batch fetch
product_ids = {item.product_id for order in orders for item in order.items}
products = {p.id: p for p in db.query(Product).filter(Product.id.in_(product_ids))}
for order in orders:
    for item in order.items:
        product = products[item.product_id]  # O(1) lookup
```

### Step 3: Apply Targeted Fix

Choose the right strategy based on bottleneck type:

#### Database — N+1 Query Problem (FORBIDDEN)

```python
# ❌ N+1: 1 + n queries
users = User.query.all()
for user in users:
    print(user.profile.bio)  # One query per user!

# ✅ Eager loading: 1-2 queries
users = User.query.options(joinedload(User.profile)).all()
# Or: subqueryload for large datasets
users = User.query.options(subqueryload(User.profile)).all()
```

```go
// Go with GORM
// ❌ N+1
var users []User
db.Find(&users)
for _, user := range users {
    db.Model(&user).Association("Profile").Find(&user.Profile)  // N queries!
}

// ✅ Preload
var users []User
db.Preload("Profile").Find(&users)  // 2 queries total
```

#### Database — Indexing Strategy

| Query Pattern | Index Needed |
|--------------|--------------|
| `WHERE email = ?` | Index on `email` |
| `WHERE user_id = ? AND status = ?` | Composite index `(user_id, status)` |
| `WHERE created_at > ?` | Index on `created_at` |
| `ORDER BY created_at DESC` | Index on `created_at` |
| `JOIN users ON orders.user_id = users.id` | Index on `orders.user_id` |

```sql
-- Check for missing indexes (PostgreSQL)
SELECT schemaname, tablename, attname, null_frac, n_distinct
FROM pg_stats WHERE tablename = 'orders';

-- Create index without locking
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- Composite index (order matters!)
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

#### Database — Query Optimization

```sql
-- ❌ Bad — SELECT *
SELECT * FROM users WHERE id = 1;

-- ✅ Good — only needed columns
SELECT id, name, email FROM users WHERE id = 1;

-- ❌ Bad — LIKE with leading wildcard (can't use index)
SELECT * FROM users WHERE email LIKE '%@gmail.com';

-- ✅ Good — trailing wildcard (can use index)
SELECT * FROM users WHERE email LIKE 'john%';

-- Always analyze
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 123;
```

#### Database — Connection Pooling & Caching

For connection pool configuration, cache-aside pattern, TTL guidelines, and cache invalidation strategies, see the **scalability-patterns** skill.

#### Concurrency & I/O

```go
// ❌ Sequential — O(n) latency
for _, url := range urls {
    resp, _ := http.Get(url)
}

// ✅ Concurrent with bounded parallelism
var wg sync.WaitGroup
sem := make(chan struct{}, 10)
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

#### Memory Management

| Issue | Fix |
|-------|-----|
| Unbounded cache | Use LRU with max size |
| Large file loading | Stream line-by-line |
| Excessive copies | Pass by pointer/reference |
| Frequent allocations | `sync.Pool` (Go), pre-allocate slices |

```python
# ❌ Bad — unbounded cache
cache = {}
def get_data(key):
    if key not in cache:
        cache[key] = expensive_computation(key)  # Grows forever!
    return cache[key]

# ✅ Good — LRU with max size
from functools import lru_cache

@lru_cache(maxsize=1000)
def get_data(key):
    return expensive_computation(key)
```

```go
// Go — sync.Pool for frequently allocated objects
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

func process() {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()
}
```

#### Streaming Large Data

```python
# ❌ Bad — load entire file into memory
def process_file(path):
    with open(path) as f:
        data = f.read()  # 10GB in memory!
    for line in data.split('\n'):
        process(line)

# ✅ Good — stream line by line
def process_file(path):
    with open(path) as f:
        for line in f:  # One line at a time
            process(line)
```

### Step 4: Frontend Performance (Core Web Vitals)

| Metric | Target | Measures |
|--------|--------|----------|
| **LCP** | < 2.5s | Largest Contentful Paint |
| **INP** | < 200ms | Interaction to Next Paint |
| **CLS** | < 0.1 | Cumulative Layout Shift |

- Image optimization: WebP/AVIF, lazy loading, responsive images
- Bundle splitting: Dynamic imports, tree shaking
- CDN: Static assets, edge caching
- Compression: Brotli > gzip
- Preloading: Critical resources, fonts

### Step 5: Measure Improvement

Run the same benchmark/profile before and after.

### Step 6: Document Trade-offs

## Report Format

```markdown
## Optimization Summary

**Target:** `src/services/order_service.py::get_orders()`
**Bottleneck:** [what was slow and why]

### Before
- Response time: ~800ms (p95)
- DB queries: 101 per request

### After
- Response time: ~45ms (p95)
- DB queries: 1 per request (JOIN)

### Trade-offs
- [what was sacrificed: readability, memory, complexity]
```

## Constraints

- ✅ **Measure first** — profile and benchmark before any change.
- ✅ **Correctness preserved** — same inputs must produce same outputs.
- ✅ **Tests pass** — all existing tests must pass after optimization.
- ✅ **Document trade-offs** — note what was sacrificed.
- ❌ **No premature optimization** — only optimize proven bottlenecks.
- ❌ **No micro-optimizations** — unless in a proven hot path.
