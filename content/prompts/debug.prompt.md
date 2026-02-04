---
name: Debug
description: Systematic debugging assistant for analyzing and resolving issues
trigger: manual
tags:
  - debugging
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
journalctl -u myservice --since "1 hour ago"

# System state
ps aux | grep <process>
netstat -tlnp | grep <port>
df -h                           # Disk space
free -m                         # Memory

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

## Common Bug Patterns

### 1. Off-by-One Errors

```python
# ❌ Bug: Skips last element
for i in range(len(items) - 1):
    process(items[i])

# ✅ Fixed
for i in range(len(items)):
    process(items[i])

# ✅ Better: Avoid index entirely
for item in items:
    process(item)
```

**Detection**: Boundary failures, missing first/last item

### 2. Null/Undefined References

```javascript
// ❌ Bug: Crashes if user is null
const name = user.profile.name;

// ✅ Fixed: Optional chaining
const name = user?.profile?.name ?? 'Unknown';

// ✅ Fixed: Early return
if (!user?.profile) {
    return 'Unknown';
}
return user.profile.name;
```

**Detection**: `NullPointerException`, `TypeError: Cannot read property`

### 3. Race Conditions

```go
// ❌ Bug: Data race on counter
var counter int
for i := 0; i < 1000; i++ {
    go func() { counter++ }()
}

// ✅ Fixed: Atomic operation
var counter int64
for i := 0; i < 1000; i++ {
    go func() { atomic.AddInt64(&counter, 1) }()
}

// ✅ Fixed: Mutex
var mu sync.Mutex
var counter int
for i := 0; i < 1000; i++ {
    go func() {
        mu.Lock()
        counter++
        mu.Unlock()
    }()
}
```

**Detection**: Intermittent failures, `go test -race`, different results each run

### 4. Resource Leaks

```python
# ❌ Bug: File never closed
def read_config(path):
    f = open(path)
    return json.load(f)

# ✅ Fixed: Context manager
def read_config(path):
    with open(path) as f:
        return json.load(f)
```

**Detection**: Gradual memory/connection increase, "too many open files"

### 5. Error Swallowing

```python
# ❌ Bug: Silently ignores errors
try:
    result = risky_operation()
except Exception:
    pass  # Silent failure!

# ✅ Fixed: Handle or propagate
try:
    result = risky_operation()
except SpecificError as e:
    logger.warning(f"Operation failed: {e}")
    result = default_value
except Exception:
    logger.exception("Unexpected error")
    raise
```

**Detection**: Unexpected behavior without errors, missing data

### 6. Type Coercion Bugs

```javascript
// ❌ Bug: "2" + 2 = "22"
const total = userInput + 2;

// ✅ Fixed: Explicit conversion
const total = parseInt(userInput, 10) + 2;

// ✅ Better: Validate first
const num = parseInt(userInput, 10);
if (isNaN(num)) throw new Error('Invalid number');
const total = num + 2;
```

**Detection**: Wrong calculations, string concatenation instead of math

## Debugging Tools by Language

| Language | Debugger | Profiler | Logger |
|----------|----------|----------|--------|
| **Go** | `dlv debug` | `go tool pprof` | `log/slog` |
| **Python** | `pdb`, `ipdb` | `cProfile`, `py-spy` | `logging` |
| **Node.js** | `node --inspect` | `clinic`, `0x` | `pino`, `winston` |
| **Java** | IDE debugger | `async-profiler` | `slf4j` |
| **Rust** | `rust-gdb`, `lldb` | `perf`, `flamegraph` | `tracing` |

### Useful Debugging Commands

```bash
# Python - Interactive debugger
python -m pdb script.py
# In code: import pdb; pdb.set_trace()

# Node.js - Chrome DevTools
node --inspect-brk app.js
# Open chrome://inspect

# Go - Delve
dlv debug ./cmd/app
# (dlv) break main.go:42
# (dlv) continue
# (dlv) print variableName

# cURL - API debugging
curl -v -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

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

```markdown
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
```

## Anti-Patterns

| ❌ Don't | ✅ Do |
|----------|-------|
| Change multiple things at once | One change, then test |
| Assume you know the cause | Gather evidence first |
| Fix symptoms | Find and fix root cause |
| Remove "unnecessary" code | Understand why it exists first |
| Debug in production | Reproduce locally if possible |
| Ignore intermittent bugs | They're often the worst |
