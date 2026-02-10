---
name: test-driven-development
description: Write and generate tests following TDD (Red-Green-Refactor), Test Pyramid, and AAA pattern. Use when the user asks to write tests, add test coverage, or implement TDD for a feature.
license: MIT
---

# Test-Driven Development

## Core Cycle: Red → Green → Refactor

1. **Red**: Write a failing test that defines expected behavior.
2. **Green**: Write the **minimal** code to make the test pass.
3. **Refactor**: Improve code quality while keeping tests green.
4. **Commit**: After each green-refactor cycle.

## Workflow

### Step 1: Detect Test Framework

Identify the project's existing test setup:

| Language | Framework | Run | Coverage |
|----------|-----------|-----|----------|
| Go | testing + testify | `go test ./... -v` | `go test -cover ./...` |
| Python | pytest | `pytest -v` | `pytest --cov=src` |
| TypeScript | vitest | `npm test` | `npm run test:coverage` |
| Bash | bats-core | `bats tests/` | N/A |

Follow existing naming conventions and file structure.

### Step 2: Plan Test Cases

For any function/feature, identify:

| Category | What to Cover |
|----------|---------------|
| **Happy path** | Normal flow, valid inputs, main use cases |
| **Edge cases** | Boundaries (0, -1, MAX), empty collections, null |
| **Error cases** | Invalid inputs, validation errors, expected exceptions |
| **Concurrency** | Race conditions, deadlocks (if applicable) |

### Step 3: Write Failing Test (Red)

Use the **AAA pattern** (Arrange-Act-Assert):

```python
def test_transfer_sufficient_balance_succeeds():
    # Arrange — set up test data and dependencies
    source = Account(balance=100)
    target = Account(balance=0)

    # Act — execute ONE action
    result = transfer(source, target, amount=50)

    # Assert — verify the outcome
    assert result.success
    assert source.balance == 50
    assert target.balance == 50
```

Run the test — it **MUST** fail. If it passes, the test is not testing anything new.

### Step 4: Write Minimal Implementation (Green)

Write the **least amount of code** to make the test pass. No extra features, no anticipatory design.

Run: `pytest tests/path/test.py::test_name -v` → Expected: PASS

### Step 5: Refactor (if needed)

Improve code while keeping all tests green. Then commit.

### Step 6: Repeat

Go back to Step 3 for the next test case.

## Naming Convention

**Format:** `test_<unit>_<scenario>_<expected_result>`

```
✅ test_calculate_discount_premium_user_returns_10_percent
✅ TestCalculateDiscount_PremiumUser_Returns10Percent
✅ it('returns 10% discount for premium user')

❌ test_discount
❌ TestDiscount
❌ it('works')
```

## Table-Driven Tests

Use for multiple scenarios:

```python
@pytest.mark.parametrize("email,valid", [
    ("user@example.com", True),
    ("userexample.com", False),
    ("user@", False),
    ("", False),
])
def test_validate_email(email, valid):
    assert validate_email(email) == valid
```

```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"missing @", "userexample.com", true},
        {"missing domain", "user@", true},
        {"empty", "", true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if (err != nil) != tt.wantErr {
                t.Errorf("ValidateEmail(%q) error = %v, wantErr %v", tt.email, err, tt.wantErr)
            }
        })
    }
}
```

## Test Doubles

| Type | Purpose | When to Use |
|------|---------|-------------|
| **Stub** | Returns canned data | External API responses |
| **Mock** | Verifies interactions | Check if method was called |
| **Spy** | Records calls, uses real impl | Partial mocking |
| **Fake** | Working implementation | In-memory database |

## Coverage Requirements

| Code Type | Target |
|-----------|--------|
| Critical business logic | 90% |
| Public API/interfaces | 80% |
| Overall project | 70% |
| Utilities/helpers | 60% |

## Unit Test Guidelines

| Requirement | Reason |
|-------------|--------|
| **Isolated** | No network, filesystem, or DB calls |
| **Fast** | < 100ms per test |
| **Deterministic** | Same result every run |
| **Independent** | No shared state between tests |

**Avoid Non-Determinism:**

```python
# ❌ Bad — non-deterministic
def test_random_selection():
    result = select_random_item(items)
    assert result in items

# ✅ Good — seeded random
def test_random_selection():
    random.seed(42)
    result = select_random_item(items)
    assert result == items[3]

# ❌ Bad — time-dependent
def test_token_expiry():
    token = create_token()
    assert not token.is_expired()

# ✅ Good — frozen time
@freeze_time("2024-01-15 12:00:00")
def test_token_expiry():
    token = create_token(expires_in=3600)
    assert not token.is_expired()
```

## Integration Tests

**Use testcontainers for real dependencies:**

```python
# Python with testcontainers
@pytest.fixture(scope="module")
def postgres():
    with PostgresContainer("postgres:16") as pg:
        yield pg.get_connection_url()

def test_user_repository(postgres):
    repo = UserRepository(postgres)
    user = repo.save(User(name="Test"))
    assert repo.find_by_id(user.id).name == "Test"
```

```go
// Go with testcontainers
func TestUserRepository(t *testing.T) {
    ctx := context.Background()
    postgres, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: testcontainers.ContainerRequest{
            Image:        "postgres:16",
            ExposedPorts: []string{"5432/tcp"},
            WaitingFor:   wait.ForListeningPort("5432/tcp"),
        },
        Started: true,
    })
    defer postgres.Terminate(ctx)
    // Test with real database
}
```

**Cleanup state after each test:**
- Truncate tables
- Use transactions and rollback
- Use unique test data per test

## Coverage Measurement

```bash
# Go
go test -coverprofile=coverage.out ./...

# Python
pytest --cov=src --cov-fail-under=70

# Node
vitest run --coverage
```

## CI/CD Integration

```yaml
# GitHub Actions
- name: Run tests
  run: |
    go test -race -coverprofile=coverage.out ./...

- name: Check coverage
  run: |
    coverage=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
    if (( $(echo "$coverage < 70" | bc -l) )); then
      echo "Coverage $coverage% is below 70%"
      exit 1
    fi
```

**Pipeline fails if:**
- Any test fails
- Coverage drops below threshold
- Flaky tests detected (run 3x)

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|-------------|---------|----------|
| Testing implementation details | Brittle tests | Test behavior and output |
| Shared mutable state | Flaky tests | Fresh setup per test |
| Sleep/time delays | Slow, unreliable | Use mocks, async waits |
| Testing private methods | Over-specification | Test through public API |
| Multiple unrelated assertions | Unclear failures | One logical concept per test |

## Constraints

- **ALWAYS** run the test and confirm it fails (Red) before writing implementation.
- **ALWAYS** run the test and confirm it passes (Green) after implementation.
- **NEVER** skip the refactor step — clean code after each cycle.
- **NEVER** write tests that depend on execution order or shared state.
- Commit after each green-refactor cycle.
