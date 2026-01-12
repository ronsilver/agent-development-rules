---
trigger: glob
globs: ["*_test.go", "*_test.py", "*.test.ts", "test_*.py", "conftest.py"]
---

# Testing Best Practices

## Philosophy

### 1. Test Driven Development (TDD)
For complex logic: **Red** (Write failing test) -> **Green** (Make it pass) -> **Refactor**.

### 2. Pyramid
- **Unit (70%)**: Fast, isolated, mocks i/o.
- **Integration (20%)**: Real DB/API interaction in containers.
- **E2E (10%)**: Critical user flows.

## Coverage - MANDATORY
- **Critical Logic**: 90%
- **Public API**: 80%
- **General**: 60%

## Naming Convention
Format: `test_<function>_<scenario>_<expected>`
- ✅ `test_calculate_total_with_discount_returns_correct_value`
- ❌ `test_total`

## AAA Pattern - MANDATORY

```python
def test_transfer():
    # Arrange
    source = Account(100)
    target = Account(0)

    # Act
    service.transfer(source, target, 50)

    # Assert
    assert source.balance == 50
    assert target.balance == 50
```

## Unit Tests guidelines
- **Isolated**: No network, no file access.
- **Fast**: < 100ms.
- **Deterministic**: No `random` without seed, no `time.now()` without freezing.

## Integration Tests
- Use Docker containers for DBs (`testcontainers`).
- Clean up state after each test.

## CI/CD
Tests **MUST** run in CI pipeline. Pipeline fails if tests fail or coverage drops.
