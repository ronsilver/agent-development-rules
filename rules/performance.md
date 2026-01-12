---
trigger: glob
globs: ["*.py", "*.go", "*.js", "*.ts", "*.java"]
---

# Performance Best Practices

## Core Principles
1.  **Measure First**: No optimization without profiling.
2.  **Algorithmic Complexity**: O(n) > O(n²).
3.  **Database First**: The database is usually the bottleneck.

## Algorithmic Complexity - MANDATORY

Understand Big O of common collections.
- **Array Lookup**: O(n)
- **Map/Dict Lookup**: O(1)
- **Set Lookup**: O(1)

**Avoid O(n²) loops**:
```python
# ❌ Bad - O(n*m)
for item in items:
    if item in other_list: ...

# ✅ Good - O(n)
other_set = set(other_list)
for item in items:
    if item in other_set: ...
```

## Database Performance

### N+1 Query Problem - FORBIDDEN
The agent **MUST** detect and reject N+1 queries. Use Eager Loading (`JOIN`).

```python
# ❌ N+1
users = User.query.all()
for user in users:
    print(user.profile.bio)  # Hits DB for every user

# ✅ Eager Load
users = User.query.options(joinedload(User.profile)).all()
```

### Indexes
- Index frequently queried columns (WHERE).
- Index foreign keys (JOIN).
- Index sort columns (ORDER BY).

## Caching
Use Redis for frequently accessed, rarely changed data.
- **Cache-Aside**: App reads cache, if miss, reads DB and updates cache.
- **TTL**: Always set a Time-To-Live.

## Frontend Performance (Core Web Vitals)
- **LCP** < 2.5s
- **CLS** < 0.1
- **INP** < 200ms

**Optimization Techniques**:
- Image optimization (WebP, lazy load).
- Bundle splitting / Tree shaking.
- CDN usage.
