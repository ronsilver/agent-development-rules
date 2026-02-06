---
trigger: glob
globs: ["*.py", "*.go", "*.js", "*.ts", "*.tf", "docker-compose*.yml", "*.yaml"]
---

# Scalability Best Practices

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Stateless** | No local state between requests |
| **Horizontal** | Scale by adding instances, not bigger servers |
| **Async** | Offload heavy work to queues |
| **Cache** | Reduce database load |
| **Partition** | Distribute data across shards |

## Stateless Services - NON-NEGOTIABLE

Application services **MUST NOT** store state locally that persists between requests.

| State Type | ❌ Wrong | ✅ Correct |
|-----------|----------|-----------|
| Sessions | In-memory dict | Redis / Database |
| File uploads | Local disk | S3 / Blob Storage |
| Cache | Local memory | Redis / Memcached |
| Locks | File locks | Redis distributed locks |
| Scheduled jobs | In-process timers | External scheduler (cron, CloudWatch) |

```python
# ❌ Bad - State in memory (lost on restart/scale)
user_sessions = {}  # Global dict

@app.route("/login")
def login():
    user_sessions[user_id] = session_data
    return {"status": "ok"}

# ✅ Good - State in Redis
@app.route("/login")
def login():
    redis.setex(f"session:{user_id}", 3600, json.dumps(session_data))
    return {"status": "ok"}
```

## Database Scalability

### Connection Pooling - MANDATORY

Never create connections per request:

```python
# ❌ Bad - Connection per request
def get_user(user_id):
    conn = psycopg2.connect(DATABASE_URL)  # Expensive!
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    return cursor.fetchone()

# ✅ Good - Connection pool
from sqlalchemy import create_engine
engine = create_engine(DATABASE_URL, pool_size=10, max_overflow=20)

def get_user(user_id):
    with engine.connect() as conn:
        return conn.execute("SELECT * FROM users WHERE id = %s", (user_id,)).fetchone()
```

**Pool sizing:** `pool_size = (core_count * 2) + effective_spindle_count`

### Read Replicas

Split reads and writes for high-volume applications:

```python
# Configuration
PRIMARY_DB = "postgresql://primary:5432/db"
REPLICA_DB = "postgresql://replica:5432/db"

# Route queries
def get_user(user_id):
    # Read from replica
    with replica_engine.connect() as conn:
        return conn.execute(query, (user_id,))

def update_user(user_id, data):
    # Write to primary
    with primary_engine.connect() as conn:
        conn.execute(update_query, (data, user_id))
```

### Indexing Strategy

| Query Pattern | Index Type |
|--------------|------------|
| `WHERE column = ?` | B-tree (default) |
| `WHERE column IN (...)` | B-tree |
| `WHERE column LIKE 'prefix%'` | B-tree |
| `WHERE column @> '{...}'` (JSON) | GIN |
| Full-text search | GIN with tsvector |
| Geospatial | GiST / SP-GiST |

## Async Processing - MANDATORY for Heavy Tasks

Offload work that takes > 500ms:

```python
# ❌ Bad - Blocking request
@app.route("/orders", methods=["POST"])
def create_order():
    order = save_order(data)
    send_confirmation_email(order)      # 2s
    generate_invoice_pdf(order)         # 3s
    notify_warehouse(order)             # 1s
    return {"order_id": order.id}       # Total: 6s+ response time

# ✅ Good - Async processing
@app.route("/orders", methods=["POST"])
def create_order():
    order = save_order(data)

    # Queue background tasks
    send_confirmation_email.delay(order.id)
    generate_invoice_pdf.delay(order.id)
    notify_warehouse.delay(order.id)

    return {"order_id": order.id, "status": "processing"}  # ~100ms
```

**Queue Technologies:**
| Use Case | Technology |
|----------|------------|
| Simple tasks | Redis + Celery/RQ |
| High throughput | Kafka / AWS SQS |
| Workflows | Temporal / AWS Step Functions |

## Caching Strategy

> For cache-aside pattern, TTL guidelines, and cache key design, see **performance.md § Caching**.

### Multi-Level Caching

```
Request → L1 (In-Process) → L2 (Redis/Memcached) → L3 (Database)
```

| Level | Technology | Latency | Use Case |
|-------|-----------|---------|----------|
| **L1** | In-process (LRU) | ~1μs | Hot data, config |
| **L2** | Redis / Memcached | ~1ms | Shared across instances |
| **L3** | Database | ~10ms | Source of truth |

### Cache Invalidation Strategies

| Strategy | When to Use | Trade-off |
|----------|-------------|-----------|
| **TTL-based** | Eventual consistency OK | Simple, may serve stale data |
| **Event-driven** | Consistency required | Complex, needs pub/sub |
| **Write-through** | Read-heavy workloads | Higher write latency |
| **Write-behind** | Write-heavy workloads | Risk of data loss |

```python
# Event-driven invalidation with Redis pub/sub
def update_user(user_id, data):
    db.query(User).filter_by(id=user_id).update(data)
    redis.delete(f"user:{user_id}")
    redis.publish("cache:invalidate", json.dumps({"key": f"user:{user_id}"}))
```

## Resilience Patterns

### Rate Limiting - MANDATORY for APIs

```python
from flask_limiter import Limiter

limiter = Limiter(app, key_func=get_remote_address)

@app.route("/api/users")
@limiter.limit("100/minute")  # Per IP
def list_users():
    return users

# Return 429 Too Many Requests when exceeded
```

### Circuit Breaker

Fail fast when dependencies are unhealthy:

```python
import circuitbreaker

@circuitbreaker.circuit(failure_threshold=5, recovery_timeout=30)
def call_payment_service(order):
    return requests.post(PAYMENT_URL, json=order.to_dict())

# After 5 failures, circuit opens
# Calls fail immediately for 30s (no waiting for timeout)
# After 30s, circuit allows one test request
```

### Retry with Exponential Backoff

```python
import backoff

@backoff.on_exception(
    backoff.expo,           # Exponential backoff
    requests.RequestException,
    max_tries=5,
    max_time=60,
    jitter=backoff.full_jitter  # Add randomness
)
def fetch_data(url):
    response = requests.get(url, timeout=5)
    response.raise_for_status()
    return response.json()

# Retry delays: ~1s, ~2s, ~4s, ~8s, ~16s (with jitter)
```

### Bulkhead Pattern

Isolate failures to prevent cascade:

```python
from concurrent.futures import ThreadPoolExecutor

# Separate pools for different dependencies
payment_pool = ThreadPoolExecutor(max_workers=10)
inventory_pool = ThreadPoolExecutor(max_workers=10)

# Payment service issues won't exhaust inventory threads
def process_order(order):
    payment_future = payment_pool.submit(charge_card, order)
    inventory_future = inventory_pool.submit(reserve_items, order)

    return payment_future.result(), inventory_future.result()
```

## Horizontal Scaling Checklist

- [ ] Services are stateless
- [ ] Sessions stored externally (Redis)
- [ ] Files stored in object storage (S3)
- [ ] Database connections pooled
- [ ] Heavy tasks queued (async)
- [ ] Caching implemented with TTL
- [ ] Rate limiting configured
- [ ] Circuit breakers on external calls
- [ ] Health checks implemented (`/health`, `/ready`)
- [ ] Graceful shutdown handling
