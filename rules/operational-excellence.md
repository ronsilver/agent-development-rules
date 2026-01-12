---
trigger: glob
globs: ["*.py", "*.go", "*.js", "*.ts", "*.tf", "*.yaml", "*.yml", "Dockerfile"]
---

# Operational Excellence - SRE Best Practices

## Core Principles

1.  **Observability by Default**: If it's not observable, it doesn't exist.
2.  **Automation First**: Toil should be eliminated.
3.  **Fail Fast, Recover Faster**: Design for failure.
4.  **Blameless Postmortems**: Focus on process improvement, not blame.

## 1. Observability - Three Pillars

### A. Logging - MANDATORY

**Format**: Structured JSON.

```python
# ✅ Correct: Structured JSON
import logging
import json

# Output: {"level": "INFO", "message": "Order processed", "order_id": "123", ...}
logger.info("Order processed", extra={"order_id": "123", "amount": 99.99})
```

**Levels**:
- `ERROR`: Attention required immediately (e.g., DB connection failed).
- `WARN`: Anomalous but handled (e.g., Retry success).
- `INFO`: Business events (e.g., Order created).
- `DEBUG`: Dev context (e.g., Query executed).

**Request ID**: MANDATORY for distributed tracing. Must be propagated across services.

### B. Metrics - MANDATORY

Use the **RED Method**:
- **Rate**: Requests per second.
- **Errors**: Failed requests per second.
- **Duration**: Latency (p50, p90, p99).

```python
# Prometheus Example
http_requests_total.labels(method="POST", endpoint="/orders", status="201").inc()
http_request_duration_seconds.labels(endpoint="/orders").observe(0.15)
```

### C. Distributed Tracing

Use OpenTelemetry. Every request should span the entire lifecycle across microservices.

## 2. Alerting

### SLI / SLO / SLA
- **SLI (Indicator)**: What we measure (e.g., Error Rate).
- **SLO (Objective)**: The goal (e.g., < 0.1% errors).
- **SLA (Agreement)**: The contract (e.g., 99.9% availability).

### Alert Rules
- Alert on **Symptoms** (High Error Rate), not causes (High CPU).
- Pages should be actionable. Information should be in dashboards.

### Runbooks
Every alert **MUST** have a linked Runbook in the annotation.
- **Description**: What is happening?
- **Impact**: user experience?
- **Diagnosis**: How to verify?
- **Mitigation**: How to fix immediately?

## 3. Reliability Patterns

### Circuit Breaker
Prevent cascading failures. If a dependency fails repeatedly, fail fast.

### Retry with Exponential Backoff
Never retry in a tight loop. Use Jitter.

```python
# ✅ Backoff with Jitter
wait = min(cap, base * 2 ** attempt)
wait += random.uniform(0, 1)
time.sleep(wait)
```

### Rate Limiting
Protect your service from overload. Reject excess traffic with `429 Too Many Requests`.

## 4. Deployment Safety

- **Feature Flags**: Decouple deployment from release.
- **Canary Deployments**: Roll out to small % of traffic first.
- **Automated Rollbacks**: If error rate spikes > SLO, revert automatically.

## 5. Incident Management

### Severity Levels
- **SEV1**: Critical Outage. Immediate response (15m).
- **SEV2**: Major degradation. Response (30m).
- **SEV3**: Minor issue. Response (4h).

### Post-Incident Review
- Root Cause Analysis (5 Whys).
- Action Items (prevent recurrence).
- Timeline of events.

## Checklist
- [ ] Logs are structured JSON.
- [ ] Correlation IDs (Request/Trace ID) enabled.
- [ ] RED metrics implemented.
- [ ] Health checks (Liveness/Readiness) configured.
- [ ] Graceful shutdown handled.
- [ ] Runbooks exist for critical alerts.
