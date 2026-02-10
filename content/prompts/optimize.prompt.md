---
name: Optimize
description: Analyze and optimize code for performance, efficiency, and scalability
trigger: manual
tags: [performance, analysis, optimization]
skill: performance-optimization
---

# Optimize

Analyze and optimize code for performance. **Measure before optimizing** — never optimize without evidence of a bottleneck. Apply the **performance-optimization** skill for profiling tools, complexity analysis, and optimization patterns.

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
