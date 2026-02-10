---
name: refactoring
description: Refactor code while maintaining existing behavior. Use when the user asks to clean up code, reduce complexity, fix code smells, or improve readability and maintainability.
license: MIT
---

# Refactoring

## Core Principle

Improve code structure **without changing external behavior**. Same inputs → same outputs.

## Pre-Refactor Gate

Before touching any code:

1. **Tests exist and pass** — if not, write tests first.
2. **Understand current behavior** — read the code, don't assume.
3. **Identify specific smells** — don't refactor "everything."
4. **Plan incremental steps** — one refactor at a time.

## When to Refactor

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Long function | > 50 lines | Extract sub-functions |
| Deep nesting | > 3 levels | Early returns, extract logic |
| Duplicated code | > 10 lines, 3+ occurrences | Extract shared function |
| God class | > 300 lines | Split by responsibility |
| High cyclomatic complexity | > 10 | Simplify conditionals |
| Feature envy | Frequent external calls | Move method to owner |

## When NOT to Refactor

- Code under active development (wait for stability)
- No test coverage (add tests first!)
- Working legacy code with no changes planned
- Performance-critical sections (measure first)

## Workflow

### For each refactoring step:

1. Make **ONE** change.
2. Run tests.
3. If tests fail → **revert** and analyze.
4. If tests pass → commit and continue.

## Code Smells & Solutions

### 1. Long Method → Extract Function

```python
# ❌ 60+ lines doing multiple things
def process_order(order):
    # validate (15 lines)...
    # calculate totals (20 lines)...
    # process payment (25 lines)...

# ✅ Clear, focused functions
def process_order(order):
    validate_order(order)
    totals = calculate_totals(order)
    process_payment(order, totals)
```

### 2. Deep Nesting → Early Returns

```python
# ❌ Deep nesting
def process_user(user):
    if user:
        if user.is_active:
            if user.has_permission("admin"):
                return perform_action(user)
    return None

# ✅ Guard clauses
def process_user(user):
    if not user:
        return None
    if not user.is_active:
        return None
    if not user.has_permission("admin"):
        return None
    return perform_action(user)
```

### 3. Magic Numbers → Named Constants

```python
# ❌ Magic numbers
if response.status_code == 429:
    time.sleep(60)

# ✅ Named constants
HTTP_TOO_MANY_REQUESTS = 429
RATE_LIMIT_DELAY_SECONDS = 60

if response.status_code == HTTP_TOO_MANY_REQUESTS:
    time.sleep(RATE_LIMIT_DELAY_SECONDS)
```

### 4. Conditional Complexity → Strategy Pattern

```python
# ❌ Growing if/elif chain
def calculate_shipping(order):
    if order.type == "standard":
        return order.weight * 0.5
    elif order.type == "express":
        return order.weight * 1.5 + 10
    # ... more types

# ✅ Strategy pattern
SHIPPING_STRATEGIES = {
    "standard": lambda w: w * 0.5,
    "express": lambda w: w * 1.5 + 10,
}

def calculate_shipping(order):
    strategy = SHIPPING_STRATEGIES.get(order.type)
    if not strategy:
        raise ValueError(f"Unknown type: {order.type}")
    return strategy(order.weight)
```

### 5. Primitive Obsession → Value Objects

```python
# ❌ Raw strings everywhere
def create_user(email: str, phone: str): ...

# ✅ Value objects with built-in validation
@dataclass(frozen=True)
class Email:
    value: str
    def __post_init__(self):
        if "@" not in self.value:
            raise ValueError(f"Invalid email: {self.value}")

def create_user(email: Email, phone: Phone): ...
```

## Language-Specific Patterns

### Go
| Smell | Refactoring |
|-------|-------------|
| Error handling verbosity | `errors.Join()`, `fmt.Errorf("...: %w", err)` |
| Multiple returns | Use named result struct |
| Interface bloat | Split into smaller interfaces |

### Python
| Smell | Refactoring |
|-------|-------------|
| Dict access patterns | Use `dataclass` or `TypedDict` |
| Optional handling | `if x is not None` or `x or default` |
| Long comprehension | Extract to named function |

### TypeScript
| Smell | Refactoring |
|-------|-------------|
| Type assertions | Use type guards |
| Callback hell | Use async/await |
| Nested ifs | Optional chaining `?.` and `??` |

## Measure Improvement

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Lines per function | ? | ? | < 50 |
| Cyclomatic complexity | ? | ? | < 10 |
| Nesting depth | ? | ? | < 3 |
| Test coverage | ? | ? | Maintained or improved |

## Constraints

- ✅ **Same behavior** — same inputs must produce same outputs.
- ✅ **Tests pass** — all existing tests must pass after each step.
- ✅ **Public API stable** — do not break external interfaces.
- ✅ **Incremental** — one refactor at a time, verify after each.
- ❌ **No new dependencies** — unless absolutely necessary.
- ❌ **No premature optimization** — clarity over micro-optimization.
