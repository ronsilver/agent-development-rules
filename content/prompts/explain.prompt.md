---
name: Explain
description: Explain selected code in a clear, educational manner
version: "1.0"
trigger: manual
tags:
  - learning
  - analysis
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

## Example Explanation

**Code:** Python retry with exponential backoff

```python
def retry(fn, max_attempts=3, base_delay=1):
    for attempt in range(max_attempts):
        try:
            return fn()
        except Exception:
            if attempt == max_attempts - 1:
                raise
            time.sleep(base_delay * 2**attempt + random.random())
```

### Summary
Implements retry logic with exponential backoff + jitter for unreliable operations.

### Purpose
Handles transient failures (network timeouts, rate limits) by retrying with increasing delays, preventing thundering herd when services recover.

### How It Works
1. Attempts `fn()` → on success, returns immediately
2. On failure, checks if retries remain → if final attempt, re-raises
3. Calculates delay: `base_delay × 2^attempt + jitter` → waits, retries

### Key Concepts
- **Exponential backoff**: Delay doubles each attempt (1s → 2s → 4s)
- **Jitter**: Random 0-1s spread retry load across clients
- **Fail-fast**: Raises original exception after max attempts

### Gotchas
- Retries ALL exceptions (including non-retryable like `ValueError`)
- Blocks thread with `time.sleep()` — use async version for async code
- No circuit breaker — retries even if service is completely down

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
