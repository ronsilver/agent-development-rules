---
name: Debug
description: Analyze and debug issues systematically to find root causes
version: "1.0"
trigger: manual
tags:
  - debugging
  - analysis
  - troubleshooting
  - problem-solving
---

# Debug

Analyze and debug issues systematically. Focus on **root cause**, not symptoms.

## Debugging Philosophy

> "Debugging is twice as hard as writing the code in the first place." — Brian Kernighan

1. **Understand** before fixing
2. **Reproduce** before investigating
3. **Isolate** before concluding
4. **Verify** before closing

## Debugging Process

### Step 1: Understand the Problem

| Question | Purpose |
|----------|---------|
| What is the **expected** behavior? | Define success criteria |
| What is the **actual** behavior? | Identify the gap |
| **When** did it start? | Correlate with changes |
| Is it **reproducible**? | Determine if intermittent |
| What's the **impact**? | Prioritize urgency |

### Step 2: Gather Information

```bash
# Recent changes (likely cause)
git log --oneline -20
git diff HEAD~5

# Error logs
tail -500 /var/log/app.log | grep -i -E "error|exception|fatal"
journalctl -u myservice --since "1 hour ago"  # Linux
log show --predicate 'process == "myservice"' --last 1h  # macOS

# System state
ps aux | grep <process>
lsof -i :<port>                 # macOS (or: ss -tlnp on Linux)
df -h                           # Disk space

# Application metrics
curl localhost:8080/metrics     # Prometheus endpoint
curl localhost:8080/health      # Health check
```

### Step 3: Form Hypotheses

Based on evidence, list possible causes:

| Hypothesis | Evidence For | Evidence Against | Test |
|------------|--------------|------------------|------|
| Database timeout | Slow query logs | Works locally | Check connection pool |
| Memory leak | RAM increasing | Recent deploy | Monitor over time |
| Race condition | Intermittent | Hard to reproduce | Add logging |

### Step 4: Isolate the Cause

| Technique | When to Use | How |
|-----------|-------------|-----|
| **Binary search** | Large codebase | `git bisect` |
| **Print debugging** | Quick, simple issues | Strategic `console.log` |
| **Debugger** | Complex state | Breakpoints, step through |
| **Minimal repro** | Complex systems | Strip to bare minimum |
| **Rubber duck** | Logic errors | Explain aloud |

#### Git Bisect for Regression

```bash
git bisect start
git bisect bad                    # Current commit is broken
git bisect good v1.2.0            # Last known good version
# Git checks out middle commit
# Test and mark: git bisect good/bad
# Repeat until culprit found
git bisect reset                  # Return to original state
```

### Step 5: Fix and Verify

1. **Make ONE change** at a time
2. **Run tests** after each change
3. **Verify** the fix actually resolves the issue
4. **Check for regressions** in related functionality
5. **Add test** to prevent recurrence

## Common Bug Patterns (Quick Reference)

| Pattern | Detection | Fix |
|---------|-----------|-----|
| **Off-by-one** | Boundary failures, missing first/last item | Check `<` vs `<=` bounds, use `enumerate()` for indexed access |
| **Null/undefined** | `NullPointerException`, `TypeError` | Optional chaining (`?.`), guard clauses |
| **Race condition** | Intermittent failures, `go test -race` | Mutex, atomic operations, channels |
| **Resource leak** | Memory/connection increase, "too many open files" | Context managers, `defer`, `finally` |
| **Error swallowing** | Unexpected behavior without errors | Handle specific exceptions, propagate unknown |
| **Type coercion** | Wrong calculations, string concatenation | Explicit conversion + validation |

## Debugging Tools (Quick Reference)

| Language | Debugger | Profiler | Logger |
|----------|----------|----------|--------|
| **Go** | `dlv debug` | `go tool pprof` | `log/slog` |
| **Python** | `pdb`, `ipdb` | `cProfile`, `py-spy` | `logging` |
| **Node.js** | `node --inspect` | `clinic`, `0x` | `pino`, `winston` |
| **Java** | IDE debugger | `async-profiler` | `slf4j` |
| **Rust** | `rust-gdb`, `lldb` | `perf`, `flamegraph` | `tracing` |

## Logging Best Practices

### Strategic Log Placement

```python
def process_order(order_id: str) -> Result:
    logger.info(f"Processing order: {order_id}")  # Entry point
    
    try:
        order = fetch_order(order_id)
        logger.debug(f"Fetched order: items={len(order.items)}")  # State
        
        result = charge_payment(order)
        logger.info(f"Payment processed: {result.transaction_id}")  # Success
        
        return result
    except PaymentError as e:
        logger.error(f"Payment failed for {order_id}: {e}")  # Failure
        raise
    except Exception:
        logger.exception(f"Unexpected error processing {order_id}")  # Unexpected
        raise
```

### Log Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| `DEBUG` | Development details | Variable values, loop iterations |
| `INFO` | Normal operations | Request received, job completed |
| `WARNING` | Recoverable issues | Retry attempt, fallback used |
| `ERROR` | Failures | Payment failed, validation error |
| `CRITICAL` | System failures | Database down, out of memory |

## Report Format

~~~markdown
## Bug Report

**Issue:** Users receiving duplicate emails on signup

**Severity:** High (user-facing, happening in production)

**Reproduction:**
1. Create new account with email
2. Submit form
3. Check inbox - 2-3 identical emails received

**Root Cause:**
The signup endpoint was not idempotent. Network retries from the 
frontend (on timeout) triggered multiple backend calls, each sending 
a welcome email.

**Evidence:**
- Logs show multiple `POST /signup` with same email within 100ms
- Frontend has `retry: 3` configured with no deduplication
- Backend processes each request independently

**Fix:**
```python
# Before
def signup(email):
    user = create_user(email)
    send_welcome_email(user)

# After - Idempotent with deduplication
def signup(email, idempotency_key):
    if is_duplicate_request(idempotency_key):
        return get_cached_response(idempotency_key)
    
    user = get_or_create_user(email)
    if user.welcome_email_sent:
        return user
    
    send_welcome_email(user)
    user.welcome_email_sent = True
    user.save()
    return user
```

**Verification:**
- [ ] Added unit test for duplicate submission
- [ ] Added integration test for retry scenario
- [ ] Monitored production for 24h - no duplicates

**Prevention:**
- Added idempotency middleware for all POST endpoints
- Updated frontend to include idempotency keys
~~~

## Anti-Patterns

| ❌ Don't | ✅ Do |
|----------|-------|
| Change multiple things at once | One change, then test |
| Assume you know the cause | Gather evidence first |
| Fix symptoms | Find and fix root cause |
| Remove "unnecessary" code | Understand why it exists first |
| Debug in production | Reproduce locally if possible |
| Ignore intermittent bugs | They're often the worst |

## Instructions

1. **Reproduce** the issue — confirm expected vs actual behavior
2. **Gather** logs, metrics, and recent changes as evidence
3. **Hypothesize** possible causes ranked by likelihood
4. **Isolate** using binary search, minimal repro, or strategic logging
5. **Fix** one thing at a time, run tests after each change
6. **Verify** the fix resolves the issue without regressions
7. **Document** root cause, fix, and prevention in report format above