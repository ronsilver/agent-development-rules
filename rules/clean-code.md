---
trigger: glob
globs: ["*.py", "*.js", "*.ts", "*.go", "*.java", "*.cs", "*.rb", "*.rs"]
---

# Clean Code & Modern Principles

## 1. Modern Design Principles (CUPID)

Instead of rigid adherence to SOLID, strive for **CUPID** properties to make code "joyful" to work with.

| Property | Description | Actionable Directive |
|----------|-------------|----------------------|
| **Composable** | Plays well with others | Write small functions with single purpose that pipe easily. |
| **Unix Philosophy** | Do one thing well | A function/class should typically fit on one screen. |
| **Predictable** | Does what you expect | Avoid side effects. Use descriptive naming. |
| **Idiomatic** | Feels natural | Follow standard language style guides (PEP8, Go fmt). |
| **Domain-based** | Models the problem | Use domain language (Ubiquitous Language) in code. |

## 2. Pragmatic Programmer Principles

### DRY (Don't Repeat Yourself)
- **Rule**: "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system."
- **Application**: Extract duplicated logic into helpers. Use constants for repeated strings/numbers.
- **Exception**: Rule of Three (duplicate twice, refactor on third). Do not DRY tests aggressively.

### KISS (Keep It Simple, Stupid)
- **Rule**: "Most systems work best if they are kept simple rather than made complicated."
- **Application**: Avoid over-engineering. Do not implement features "just in case" (YAGNI).
- **Check**: Can a junior engineer understand this code in 5 minutes?

### YAGNI (You Ain't Gonna Need It)
- **Rule**: "Always implement things when you actually need them, never when you just foresee that you need them."
- **Application**: No anticipatory interfaces, base classes, or configuration for future use cases.

## 3. The Boy Scout Rule

> **"Always leave the code better than you found it."**

- If you touch a file:
    - Fix broken indentation.
    - Rename unclear variables.
    - Add missing type hints.
    - Delete commented-out code.
    - **Do not** start a massive refactor, just small improvements.

## 4. Code Smells to Avoid

- **Long Methods**: >20 lines (soft limit), >50 lines (hard limit).
- **Deep Nesting**: >3 levels of indentation. Refactor with Early Returns.
- **Magic Numbers/Strings**: Use named constants.
- **God Classes**: Classes doing too much. Apply SRP/Unix Philosophy.
- **Commented Code**: Delete it. Git has history.
- **Dead Code**: Remove unused functions and imports.

## 5. Early Returns

Avoid nesting `if/else` hell.

```python
# ❌ Deep nesting
def process_user(user):
    if user:
        if user.is_active:
            if user.has_subscription:
                return "Access and subscribe"
            else:
                return "Access only"
        else:
            return "No access"
    else:
        return "Error"

# ✅ Early returns
def process_user(user):
    if not user:
        return "Error"
    if not user.is_active:
        return "No access"
    if not user.has_subscription:
        return "Access only"

    return "Access and subscribe"
```

## 6. Naming Matters

- **Intent-Revealing**: `days_since_creation` vs `d`.
- **Pronounceable**: `customer` vs `cstmr`.
- **Searchable**: `MAX_RETRIES` vs `5`.
- **Boolean**: `is_active`, `has_permission`, `can_edit`.

## 7. Comments

- **Good**: Explains **WHY** something is done (business logic, weird bug workaround).
- **Bad**: Explains **HOW** (code should be self-documenting) or **WHAT** (redundant).

```python
# ❌ Bad
# Increment i by 1
i += 1

# ✅ Good
# Retrying connection because legacy API drops the first packet
retry_connection()
```
