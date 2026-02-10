---
name: systematic-debugging
description: Systematically debug issues by finding root causes, not symptoms. Use when the user reports a bug, error, unexpected behavior, or asks to debug or troubleshoot code.
license: MIT
---

# Systematic Debugging

## Core Philosophy

> "Debugging is twice as hard as writing the code in the first place." — Brian Kernighan

1. **Understand** before fixing
2. **Reproduce** before investigating
3. **Isolate** before concluding
4. **Verify** before closing

## Workflow

### Step 1: Understand the Problem

| Question | Purpose |
|----------|---------|
| What is the **expected** behavior? | Define success criteria |
| What is the **actual** behavior? | Identify the gap |
| **When** did it start? | Correlate with changes |
| Is it **reproducible**? | Determine if intermittent |
| What's the **impact**? | Prioritize urgency |

### Step 2: Gather Evidence

```bash
# Recent changes (likely cause)
git log --oneline -20
git diff HEAD~5

# Error logs
tail -500 /var/log/app.log | grep -i -E "error|exception|fatal"

# System state
ps aux | grep <process>
lsof -i :<port>
df -h
```

### Step 3: Form Hypotheses

Rank possible causes by likelihood:

| Hypothesis | Evidence For | Evidence Against | Test |
|------------|-------------|------------------|------|
| [cause 1] | [what supports it] | [what contradicts] | [how to verify] |
| [cause 2] | ... | ... | ... |

### Step 4: Isolate the Cause

| Technique | When to Use |
|-----------|-------------|
| **Binary search** (`git bisect`) | Regression in large history |
| **Strategic logging** | Complex state flow |
| **Debugger** (breakpoints) | Complex state inspection |
| **Minimal reproduction** | Complex system interactions |
| **Comment-out / divide** | Narrowing scope |

#### Git Bisect for Regressions

```bash
git bisect start
git bisect bad                    # Current commit is broken
git bisect good v1.2.0            # Last known good version
# Git checks out middle commit — test and mark good/bad
# Repeat until culprit found
git bisect reset
```

### Step 5: Fix and Verify

1. **Make ONE change** at a time.
2. **Run tests** after each change.
3. **Verify** the fix resolves the original issue.
4. **Check for regressions** in related functionality.
5. **Add a regression test** to prevent recurrence.

## Common Bug Patterns

| Pattern | Detection | Fix |
|---------|-----------|-----|
| **Off-by-one** | Boundary failures | Check `<` vs `<=`, use `enumerate()` |
| **Null/undefined** | `TypeError`, `NullPointerException` | Guard clauses, optional chaining |
| **Race condition** | Intermittent failures | Mutex, atomic ops, `go test -race` |
| **Resource leak** | Memory/connections grow | `defer`, `finally`, context managers |
| **Error swallowing** | Silent failures, unexpected state | Handle specific exceptions, propagate unknown |
| **Type coercion** | Wrong calculations | Explicit conversion + validation |

## Debugging Tools

| Language | Debugger | Profiler | Logger |
|----------|----------|----------|--------|
| **Go** | `dlv debug` | `go tool pprof` | `log/slog` |
| **Python** | `pdb`, `ipdb` | `cProfile`, `py-spy` | `logging` |
| **Node.js** | `node --inspect` | `clinic`, `0x` | `pino`, `winston` |
| **Rust** | `rust-gdb`, `lldb` | `perf`, `flamegraph` | `tracing` |

## Strategic Logging

```python
def process_order(order_id: str) -> Result:
    logger.info(f"Processing order: {order_id}")           # Entry

    try:
        order = fetch_order(order_id)
        logger.debug(f"Fetched: items={len(order.items)}")  # State

        result = charge_payment(order)
        logger.info(f"Payment OK: {result.transaction_id}") # Success
        return result
    except PaymentError as e:
        logger.error(f"Payment failed for {order_id}: {e}") # Expected failure
        raise
    except Exception:
        logger.exception(f"Unexpected error: {order_id}")    # Unexpected
        raise
```

## Report Format

```markdown
## Bug Report

**Issue:** [one-line description]
**Severity:** [Critical/High/Medium/Low]

**Reproduction:**
1. [step 1]
2. [step 2]
3. [observed behavior]

**Root Cause:**
[Explain WHY the bug happened, not just what was broken]

**Evidence:**
- [log lines, stack traces, metrics]

**Fix:**
[What was changed and why]

**Verification:**
- [ ] Fix resolves the original issue
- [ ] Regression test added
- [ ] No regressions in related functionality
- [ ] Tests pass

**Prevention:**
[What systemic change prevents similar bugs]
```

## Anti-Patterns

| ❌ Don't | ✅ Do |
|----------|-------|
| Change multiple things at once | One change, then test |
| Assume you know the cause | Gather evidence first |
| Fix symptoms | Find and fix root cause |
| Remove "unnecessary" code | Understand why it exists (Chesterton's Fence) |
| Debug in production | Reproduce locally if possible |
| Ignore intermittent bugs | They're often the worst — add logging |

## Constraints

- **NEVER** guess at the root cause — gather evidence.
- **ALWAYS** add a regression test after fixing a bug.
- **ALWAYS** verify the fix with fresh test execution.
- Make ONE change at a time between test runs.
