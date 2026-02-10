---
trigger: glob
globs: ["*.go", "go.mod", "go.sum"]
---

# Go Best Practices

## Error Handling

### Core Rule - NO IGNORED ERRORS
Never use `_` to ignore errors. If an error truly doesn't matter, document **explicitly** why.

- **Forbidden**: `val, _ := fn()`
- **Allowed**: `val, err := fn(); if err != nil { ... }`

### Error Wrapping
Use `%w` for wrapping errors to preserve context.
```go
if err != nil {
    return fmt.Errorf("process order %s: %w", orderID, err)
}
```

### No Panics
Do not use `panic` in libraries or production code. Return errors instead.

## Project Structure - Standard Layout

Follow [golang-standards/project-layout](https://github.com/golang-standards/project-layout).

- `cmd/`: Main applications.
- `internal/`: Private application and library code.
- `pkg/`: Library code usable by external apps.
- `api/`: OpenAPI/Swagger specs.

## Mandatory Verification

Before any commit or PR, you **MUST** run:
```bash
go fmt ./...                          # Formatting
go vet ./...                          # Vetting
golangci-lint run                     # Linting
go test -race -cover ./...            # Testing with race detector
go test -coverprofile=coverage.out    # Coverage report
```

## Linter Configuration

### golangci-lint v2 (2025) - `.golangci.yml`

```yaml
# golangci-lint v2 configuration
run:
  timeout: 5m
  tests: true
  modules-download-mode: readonly

linters:
  # New v2 syntax (replaces enable-all/disable-all)
  default: standard
  enable:
    # Core linters
    - errcheck      # Check for unchecked errors
    - gosimple      # Simplify code suggestions
    - govet         # Vet examines Go source code
    - ineffassign   # Detect ineffectual assignments
    - staticcheck   # Staticcheck checks
    - unused        # Check for unused constants, variables, functions

    # Code quality
    - revive        # Fast, configurable, extensible linter
    - gocyclo       # Cyclomatic complexity
    - misspell      # Spell checker
    - unconvert     # Remove unnecessary conversions
    - unparam       # Reports unused function parameters
    - gofmt         # Check formatting
    - goimports     # Check imports

    # Security
    - gosec         # Security problems scanner

    # Best practices
    - bodyclose     # Check HTTP response body closed
    - noctx         # Finds HTTP requests without context
    - errname       # Check error naming conventions
    - errorlint     # Error wrapping issues
    - gocritic      # Opinionated Go linter

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true

  gocyclo:
    min-complexity: 15

  revive:
    rules:
      - name: var-naming
      - name: exported
      - name: error-return
      - name: error-strings
      - name: blank-imports

  gosec:
    excludes:
      - G104  # Audit errors (covered by errcheck)

issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
```

**Key Linters Explained:**
- **errcheck**: Prevents ignored errors (`_` usage)
- **gosec**: Security vulnerabilities (SQL injection, weak crypto)
- **revive**: Configurable rules for code quality
- **gocyclo**: Prevents overly complex functions (>15 complexity)
- **bodyclose**: Ensures HTTP response bodies are closed

## Security
- Avoid `unsafe`.
- Use `gosec` to scan code.
- Sanitize SQL inputs (use parameter substitution, NEVER string concatenation).
- Use `govulncheck ./...` to scan for known vulnerabilities.

## Testing

### Test Coverage Requirements

> Thresholds (90%/80%/70%) defined in **testing.md § Coverage Requirements**.

```bash
# Run tests with coverage
go test -cover ./...

# Generate detailed coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# CI/CD: Fail if coverage drops
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out | grep total | awk '{if ($3+0 < 70) exit 1}'
```

### Testing Frameworks

#### Testify - Assertions & Mocking
Install: `go get github.com/stretchr/testify`

**Assertions** (testify/assert):
```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestUserCreate(t *testing.T) {
    user, err := CreateUser("john@example.com")

    assert.NoError(t, err)
    assert.NotNil(t, user)
    assert.Equal(t, "john@example.com", user.Email)
    assert.True(t, user.ID > 0)
}
```

**Mocking** (testify/mock):
```go
import "github.com/stretchr/testify/mock"

type MockRepository struct {
    mock.Mock
}

func (m *MockRepository) GetUser(id int) (*User, error) {
    args := m.Called(id)
    return args.Get(0).(*User), args.Error(1)
}

func TestService(t *testing.T) {
    mockRepo := new(MockRepository)
    mockRepo.On("GetUser", 123).Return(&User{ID: 123}, nil)

    service := NewService(mockRepo)
    user, err := service.GetUser(123)

    assert.NoError(t, err)
    assert.Equal(t, 123, user.ID)
    mockRepo.AssertExpectations(t)
}
```

### Table-Driven Tests (Go Standard Pattern)

**Pattern**:
```go
func TestCalculate(t *testing.T) {
    tests := []struct {
        name     string
        input    int
        expected int
        wantErr  bool
    }{
        {
            name:     "positive number",
            input:    5,
            expected: 10,
            wantErr:  false,
        },
        {
            name:     "negative number",
            input:    -5,
            expected: -10,
            wantErr:  false,
        },
        {
            name:     "zero",
            input:    0,
            expected: 0,
            wantErr:  false,
        },
        {
            name:     "overflow",
            input:    math.MaxInt,
            expected: 0,
            wantErr:  true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := Calculate(tt.input)

            if tt.wantErr {
                assert.Error(t, err)
                return
            }

            assert.NoError(t, err)
            assert.Equal(t, tt.expected, result)
        })
    }
}
```

### Parallel Testing

```go
func TestParallel(t *testing.T) {
    tests := []struct {
        name string
        input int
    }{
        {"test1", 1},
        {"test2", 2},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel() // Run tests in parallel
            result := Process(tt.input)
            assert.NotNil(t, result)
        })
    }
}
```

### Race Detector

Always run tests with race detector to catch concurrency issues:

```bash
# Run with race detector
go test -race ./...

# Race detector catches:
# - Concurrent map access
# - Unsynchronized variable access
# - Data races in goroutines
```

**Performance Impact**: 2-20x slower, 5-10x more memory (testing only, not production).

### Test Fixtures & Helpers

```go
// Use testdata/ directory for test files
func TestLoadConfig(t *testing.T) {
    data, err := os.ReadFile("testdata/config.json")
    assert.NoError(t, err)
    // ...
}

// Test helpers
func newTestServer(t *testing.T) *Server {
    t.Helper()
    server := &Server{}
    t.Cleanup(func() {
        server.Close()
    })
    return server
}
```

### Integration Tests

```go
// Use build tags to separate unit and integration tests
//go:build integration

package mypackage_test

import (
    "testing"
    "github.com/testcontainers/testcontainers-go"
)

func TestDatabaseIntegration(t *testing.T) {
    if testing.Short() {
        t.Skip("Skipping integration test")
    }

    // Use testcontainers for real database
    // ...
}
```

Run integration tests:
```bash
go test -tags=integration ./...
```
