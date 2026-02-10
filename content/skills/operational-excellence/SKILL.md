---
name: operational-excellence
description: Implement SRE best practices including observability (logs, metrics, tracing), alerting, incident management, and deployment safety. Use when the user asks about monitoring, logging, SLOs, incident response, or production readiness.
license: MIT
---

# Operational Excellence — SRE Best Practices

## Core Principles

1. **Observability by Default**: If it's not observable, it doesn't exist.
2. **Automation First**: Toil should be eliminated.
3. **Fail Fast, Recover Faster**: Design for failure.
4. **Blameless Postmortems**: Focus on process improvement, not blame.

## Three Pillars of Observability

### Logging — Structured JSON

```python
# ✅ Structured JSON output
logger.info("Order processed", extra={"order_id": "123", "amount": 99.99})
# Output: {"level": "INFO", "message": "Order processed", "order_id": "123", ...}
```

| Level | When to Use |
|-------|-------------|
| `ERROR` | Attention required immediately |
| `WARN` | Anomalous but handled |
| `INFO` | Business events (order created, user logged in) |
| `DEBUG` | Development context |

**Request ID**: MANDATORY for distributed tracing. Propagate across all services.

### Metrics — RED Method

- **Rate**: Requests per second
- **Errors**: Failed requests per second
- **Duration**: Latency (p50, p90, p99)

```python
http_requests_total.labels(method="POST", endpoint="/orders", status="201").inc()
http_request_duration_seconds.labels(endpoint="/orders").observe(0.15)
```

### Distributed Tracing

Use OpenTelemetry. Every request should span the entire lifecycle across microservices.

## Alerting

### SLI / SLO / SLA

- **SLI** (Indicator): What we measure (e.g., error rate)
- **SLO** (Objective): The goal (e.g., < 0.1% errors)
- **SLA** (Agreement): The contract (e.g., 99.9% availability)

### Alert Rules

- Alert on **symptoms** (high error rate), not causes (high CPU).
- Pages should be actionable. Information goes in dashboards.
- Every alert MUST have a linked **runbook**.

### Runbook Template

```markdown
## Alert: [Alert Name]
### Description
What is happening?
### Impact
How does this affect users?
### Diagnosis
How to verify and investigate?
### Mitigation
How to fix immediately?
```

## Deployment Safety

- **Feature Flags**: Decouple deployment from release.
- **Canary Deployments**: Roll out to small % of traffic first.
- **Automated Rollbacks**: If error rate spikes > SLO, revert automatically.

## Incident Management

| Severity | Description | Response Time |
|----------|-------------|---------------|
| **SEV1** | Critical outage | 15 minutes |
| **SEV2** | Major degradation | 30 minutes |
| **SEV3** | Minor issue | 4 hours |

### Post-Incident Review

- Root Cause Analysis (5 Whys)
- Action Items (prevent recurrence)
- Timeline of events

## Checklist

- [ ] Logs are structured JSON
- [ ] Correlation IDs (Request/Trace ID) enabled
- [ ] RED metrics implemented
- [ ] Health checks (Liveness/Readiness) configured
- [ ] Graceful shutdown handled
- [ ] Runbooks exist for critical alerts
- [ ] SLOs defined for key services
- [ ] Alerting on symptoms, not causes

## Constraints

- **NEVER** log sensitive data (passwords, tokens, PII).
- **ALWAYS** use structured logging (JSON), not free-text.
- **ALWAYS** propagate request/trace IDs across services.
- **ALWAYS** link every alert to a runbook.
