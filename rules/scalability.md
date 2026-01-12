---
trigger: glob
globs: ["*.py", "*.go", "*.js", "*.ts", "*.tf", "docker-compose*.yml", "*.yaml"]
---

# Scalability Best Practices

## Stateless Services - NON-NEGOTIABLE

Application services **MUST NOT** store state locally (memory/disk) that persists between requests.
- **Sessions**: Store in Redis.
- **Uploads**: Store in S3/Blob Storage.
- **Global Vars**: Avoid.

## Database Scalability

### Connection Pooling
Mandatory. Use pools (e.g., SQLAlchemy Pool, PgBouncer) to manage connections efficiently.

### Read Replicas
Split reads and writes. Use replicas for high-volume read queries.

## Async Processing
Use Message Queues (Celery, SQS, Kafka) for heavy tasks.

```python
# API responds immediately
process_order.delay(order_id)
return {"status": "processing"}
```

## Resilience Patterns

### Rate Limiting
Protect your API. Return `429 Too Many Requests`.

### Circuit Breaker
Fail fast when dependencies are down.

```python
# Stop calling Payment Service if it fails 5 times in a row
payment_circuit.call(charge_card)
```
