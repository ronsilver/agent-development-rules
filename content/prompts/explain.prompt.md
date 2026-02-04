---
name: Explain
description: Explain selected code in a clear, educational manner
trigger: manual
tags:
  - learning
  - documentation
  - onboarding
---

# Explain

Explain the selected code in a clear, educational manner. Focus on **understanding**, not just describing.

## Explanation Levels

| Level | Audience | Focus | Depth |
|-------|----------|-------|-------|
| **Beginner** | Junior dev, new to codebase | Concepts, terminology, basics | High-level overview |
| **Intermediate** | Mid-level dev | Patterns, trade-offs, why | Implementation details |
| **Expert** | Senior dev | Edge cases, internals, performance | Deep dive |

Default to **Intermediate** unless specified.

## Output Structure

### 1. Summary (1-2 sentences)
What does this code do at a high level?

### 2. Purpose
- What problem does it solve?
- Why does this code exist?
- What would happen without it?

### 3. How It Works
Step-by-step breakdown:
1. First, it does X...
2. Then, it checks Y...
3. Finally, it returns Z...

### 4. Key Concepts
- Patterns used (Strategy, Factory, Observer, etc.)
- Algorithms (binary search, BFS, etc.)
- Language features (generics, closures, etc.)

### 5. Important Details
- Edge cases handled
- Error handling approach
- Performance characteristics (O notation)

### 6. Potential Gotchas
- Common mistakes when modifying
- Non-obvious behavior
- Dependencies or assumptions

## Example Explanations

### Example 1: Retry Logic

**Code:**
```python
def retry_with_backoff(fn, max_attempts=3, base_delay=1):
    for attempt in range(max_attempts):
        try:
            return fn()
        except Exception as e:
            if attempt == max_attempts - 1:
                raise
            delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
            time.sleep(delay)
```

**Explanation:**

## Summary
This function implements exponential backoff retry logic for unreliable operations.

## Purpose
Handles transient failures (network timeouts, rate limits) by automatically retrying with increasing delays, preventing thundering herd problems when services recover.

## How It Works
1. **Attempts the operation** by calling `fn()`
2. **On success**, returns the result immediately
3. **On failure**, checks if retries remain
4. **If final attempt**, re-raises the exception
5. **Otherwise**, calculates delay: `base_delay × 2^attempt + jitter`
6. **Waits** for the calculated delay, then retries

## Key Concepts
- **Exponential backoff**: Delay doubles each attempt (1s → 2s → 4s)
- **Jitter**: Random 0-1s added to spread retry load across clients
- **Fail-fast on exhaustion**: Raises original exception after max attempts

## Important Details
- Time complexity: O(1) per attempt
- Max total wait: ~7 seconds with defaults (1 + 2 + 4 + jitter)
- Thread-blocking: Uses `time.sleep()`, not async

## Potential Gotchas
- **No exception filtering**: Retries ALL exceptions, including non-retryable ones (e.g., `ValueError`)
- **Blocking**: Will block the thread; use `asyncio` version for async code
- **No circuit breaker**: Continues retrying even if service is completely down

---

### Example 2: Database Connection Pool

**Code:**
```go
type Pool struct {
    mu       sync.Mutex
    conns    chan *Conn
    factory  func() (*Conn, error)
    maxSize  int
}

func (p *Pool) Get(ctx context.Context) (*Conn, error) {
    select {
    case conn := <-p.conns:
        if conn.IsHealthy() {
            return conn, nil
        }
        conn.Close()
        return p.factory()
    case <-ctx.Done():
        return nil, ctx.Err()
    default:
        p.mu.Lock()
        defer p.mu.Unlock()
        if len(p.conns) < p.maxSize {
            return p.factory()
        }
        select {
        case conn := <-p.conns:
            return conn, nil
        case <-ctx.Done():
            return nil, ctx.Err()
        }
    }
}
```

**Explanation:**

## Summary
A thread-safe connection pool that reuses database connections and creates new ones on demand up to a maximum limit.

## Purpose
Avoids the overhead of creating new database connections for each request (connection creation is expensive: TCP handshake, TLS, authentication).

## How It Works
1. **Try to get existing connection** from buffered channel (non-blocking)
2. **Health check**: If connection is stale, close it and create new one
3. **Context cancellation**: Respect timeout/cancellation at any point
4. **If no connection available**:
   - Lock mutex to safely check pool size
   - If under max size, create new connection
   - Otherwise, block waiting for a connection to be returned

## Key Concepts
- **Buffered channel as pool**: `chan *Conn` acts as a thread-safe queue
- **Select with default**: Non-blocking receive attempt
- **Context propagation**: Allows caller to set timeouts
- **Lazy initialization**: Connections created on demand, not upfront

## Important Details
- **Thread-safe**: Mutex protects size check, channel is inherently safe
- **Bounded**: Never exceeds `maxSize` connections
- **Health checks**: Validates connections before returning (handles server restarts)

## Potential Gotchas
- **Connection leak**: Caller MUST return connection via `Put()` or `defer`
- **No idle timeout**: Connections stay open indefinitely
- **Blocking under load**: If all connections busy and at max, callers block

---

## Explanation Patterns by Code Type

| Code Type | Focus On |
|-----------|----------|
| **Algorithm** | Time/space complexity, invariants, edge cases |
| **API endpoint** | Request flow, validation, error responses |
| **Data structure** | Operations, complexity, thread safety |
| **Configuration** | What each option does, defaults, impacts |
| **Test** | What's being tested, why, edge cases covered |
| **Infrastructure** | Resources created, dependencies, permissions |

## When NOT to Over-Explain

- Trivial code that's self-documenting
- Standard library usage with good naming
- Well-known patterns (e.g., singleton, iterator)

Instead, focus on:
- **Why** this approach was chosen
- **Context** specific to this codebase
- **Non-obvious** behavior or gotchas

## Instructions

1. **Read** the selected code carefully
2. **Identify** the audience level (default: intermediate)
3. **Structure** explanation using the template above
4. **Include** code snippets to illustrate points
5. **Highlight** non-obvious behavior and gotchas
6. **Be concise** - avoid repeating what the code clearly shows
