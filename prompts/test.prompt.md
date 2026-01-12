# Test

Generate comprehensive tests for the selected code.

## Coverage Requirements

### 1. Happy Path
- Normal flow with valid inputs.
- Main use cases.
- Verify expected outputs.

### 2. Edge Cases
- Boundary values (0, -1, MAX_INT).
- Empty strings/arrays.
- Null/Undefined.
- Special characters.

### 3. Error Cases
- Invalid inputs (wrong types).
- Validation errors.
- Expected exceptions.
- Timeouts/Network errors.

## Frameworks

| Language | Framework | Command |
|----------|-----------|---------|
| Go | testing + testify | `go test ./... -v` |
| Python | pytest | `pytest -v` |
| TypeScript | vitest/jest | `npm test` |
| Terraform | terraform test | `terraform test` |

## Test Structure

### Naming Convention
`test_<function>_<scenario>_<expected_result>`

Example: `test_create_user_empty_email_raises_error`

### AAA Pattern (Arrange-Act-Assert)
```python
def test_calculate_discount():
    # Arrange
    user = User(tier="premium")
    amount = 100.0

    # Act
    result = calculate_discount(user, amount)

    # Assert
    assert result == 90.0
```

## Instructions
1.  Detect existing testing framework.
2.  Generate tests following existing patterns.
3.  Include Setup/Teardown if needed.
4.  Use Mocks ONLY when necessary (Unit tests).
5.  Ensure independence (no shared state).
