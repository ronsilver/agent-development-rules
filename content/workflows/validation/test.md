---
name: test
description: Run project tests with coverage requirements
---

# Workflow: Run Tests

Executes tests with coverage tracking for all supported project types.

## Commands by Project Type

| Project | Command | With Coverage | Coverage Target |
|---------|---------|---------------|-----------------|
| Terraform | `terraform test` | N/A | N/A |
| Go | `go test ./...` | `go test -race -cover ./...` | 70% |
| Python | `pytest` | `pytest --cov=src --cov-report=term-missing` | 70% |
| Node/TS | `npm test` | `npm run test:coverage` | 70% |

## Coverage Requirements

### Minimum Thresholds

> Thresholds (90%/80%/70%) defined in **testing.md § Coverage Requirements**.

**STOP if coverage drops below overall target (70%).**

## Workflow Steps

### 1. Detect Project Type
Check for marker files:
- `go.mod` → Go
- `package.json` → Node.js/TypeScript
- `pyproject.toml` or `requirements.txt` → Python
- `*.tf` + `*.tftest.hcl` → Terraform

### 2. Run Tests with Coverage
Execute appropriate commands based on project type.

**STOP** if tests fail or coverage drops.

### 3. Generate Coverage Reports
- **Terminal**: Text summary with uncovered lines
- **HTML**: Detailed coverage report
- **JSON/XML**: For CI/CD integration

### 4. Report Results
- ✅ **Passed**: All tests passed, coverage met
- ❌ **Failed**: Tests failed or coverage below threshold
- ⏭️ **Skipped**: No tests found

## By Project Type (Detailed)

### Go

```bash
# Run all tests
go test ./...

# With race detector (catches concurrency issues)
go test -race ./...

# With coverage
go test -race -cover ./...

# Detailed coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

# CI/CD: Fail if coverage < 70%
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out | \
  grep total | \
  awk '{if ($3+0 < 70) {print "Coverage below 70%"; exit 1}}'
```

**Configuration**: Tests in `*_test.go` files

**Recommended**: Use `testify/assert` for assertions

### Python

```bash
# Run all tests
pytest

# With coverage
pytest --cov=src --cov-report=term-missing

# HTML report
pytest --cov=src --cov-report=html

# XML report (for CI/CD)
pytest --cov=src --cov-report=xml

# CI/CD: Fail if coverage < 70%
pytest --cov=src --cov-fail-under=70
```

**Configuration**: `pyproject.toml`
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = [
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-fail-under=70",
]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "if TYPE_CHECKING:",
]
```

**Recommended**: Use `pytest-cov`, `pytest-xdist` for parallel tests

### Node.js / TypeScript

```bash
# Run tests
npm test

# With coverage
npm run test:coverage

# Vitest (recommended)
vitest run --coverage

# Jest
jest --coverage
```

**Configuration**: `vitest.config.ts`
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'json'],
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 70,
        statements: 70,
      },
    },
  },
});
```

**package.json scripts**:
```json
{
  "scripts": {
    "test": "vitest run",
    "test:coverage": "vitest run --coverage",
    "test:watch": "vitest"
  }
}
```

### Terraform

```bash
# Run Terraform tests (if .tftest.hcl files exist)
terraform test

# Validate modules
terraform init -backend=false
terraform validate
```

**Note**: Terraform testing is primarily for modules. Use integration tests for full infrastructure.

## Test Types & Parallel Testing

> For test pyramid (unit/integration/E2E), naming conventions, and parallel testing patterns, see **testing.md**.

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test

on: [push, pull_request]

jobs:
  test-go:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
      - uses: actions/setup-go@v5 # TODO: pin to SHA
        with:
          go-version: '1.23'

      - name: Run tests
        run: go test -race -coverprofile=coverage.out ./...

      - name: Check coverage
        run: |
          go tool cover -func=coverage.out | \
          grep total | \
          awk '{if ($3+0 < 70) exit 1}'

      - name: Upload coverage
        uses: codecov/codecov-action@v4 # TODO: pin to SHA
        with:
          files: ./coverage.out

  test-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
      - uses: actions/setup-python@v5 # TODO: pin to SHA
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -e .
          pip install pytest pytest-cov

      - name: Run tests
        run: pytest --cov=src --cov-fail-under=70

      - name: Upload coverage
        uses: codecov/codecov-action@v4 # TODO: pin to SHA
        with:
          files: ./coverage.xml

  test-node:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
      - uses: actions/setup-node@v4 # TODO: pin to SHA
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm run test:coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v4 # TODO: pin to SHA
```

## Performance Tips

- **Run unit tests first** (fast feedback)
- **Parallel execution** (use `-n auto`, `-race`, `--threads`)
- **Cache dependencies** in CI/CD
- **Skip slow tests locally**: `pytest -m "not slow"`
- **Watch mode** for development: `vitest`, `pytest --watch`
