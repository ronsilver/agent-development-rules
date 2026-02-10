---
name: lint
description: Run linters with comprehensive checks
---

# Workflow: Lint

Executes linting and formatting checks for all supported project types.

> For full validation (lint + test), use the **validate** workflow. This workflow runs **detailed linting only**.

## By Project Type

### Terraform
```bash
# Format check
terraform fmt -check -recursive
# STOP if not formatted

# Syntax validation
terraform validate
# STOP if invalid

# Code quality (TFLint)
tflint --init
tflint --recursive
# STOP if linter finds issues

# Security scanning
checkov -d . --compact --quiet
tfsec .
# STOP if HIGH/CRITICAL issues found
```

**Expected tools**: `terraform`, `tflint`, `checkov`, `tfsec`

### Go
```bash
# Format check (gofmt -l returns unformatted files)
gofmt -l .
# STOP if output is non-empty (files need formatting)

# Vet check
go vet ./...
# STOP if issues found

# Comprehensive linting (golangci-lint v2)
golangci-lint run --config .golangci.yml
# STOP if linter finds issues

# Import formatting
goimports -l .
# STOP if not formatted
```

**Expected tools**: `go`, `golangci-lint`, `goimports`

**Configuration required**: `.golangci.yml`

### Python
```bash
# Format check (Ruff replaces Black)
ruff format . --check
# STOP if not formatted

# Linting (Ruff replaces flake8, isort)
ruff check .
# STOP if lint fails

# Type checking
mypy src/
# STOP if type errors found

# Security scanning
bandit -r src/ -f json
# STOP if HIGH/CRITICAL issues found
```

**Expected tools**: `ruff`, `mypy`, `bandit`

**Configuration required**: `pyproject.toml` with `[tool.ruff]` and `[tool.mypy]`

### Node.js / TypeScript
```bash
# Format check
npm run format:check
# or: npx prettier --check .
# STOP if not formatted

# Type checking
npm run typecheck
# or: tsc --noEmit
# STOP if type errors found

# ESLint (Flat Config)
npm run lint
# or: npx eslint .
# STOP if lint fails
```

**Expected tools**: `prettier`, `tsc`, `eslint`

**Configuration required**: `eslint.config.js` (flat config), `tsconfig.json` with `"strict": true`

### Bash
```bash
# Format check (recursive)
shfmt -d .
# STOP if not formatted

# Linting (recursive)
find . -name '*.sh' -exec shellcheck {} +
# STOP if issues found
```

**Expected tools**: `shfmt`, `shellcheck`

**Configuration optional**: `.shellcheckrc`, `.editorconfig`

### Docker
```bash
# Dockerfile linting
hadolint Dockerfile
# STOP if issues found

# Best practices check
docker scout quickview .
# STOP if CRITICAL vulnerabilities
```

**Expected tools**: `hadolint`, `docker scout` (or `trivy`)

### Kubernetes / Helm
```bash
# YAML validation (kubeconform replaces deprecated kubeval)
kubeconform -strict -summary *.yaml
# STOP if invalid

# Best practices
datree test ./k8s
# STOP if policy violations

# Helm linting (if using Helm)
helm lint ./chart
# STOP if errors found
```

**Expected tools**: `kubeconform`, `datree`, `helm` (if applicable)

## Execution Strategy

### 1. Detect Project Type
Scan for marker files:
- `*.tf` → Terraform
- `go.mod` → Go
- `package.json` + `tsconfig.json` → TypeScript/Node.js
- `pyproject.toml` or `requirements.txt` → Python
- `*.sh` → Bash
- `Dockerfile` → Docker
- `Chart.yaml` → Helm

### 2. Run Linters in Order
1. **Format Check** (fast, catches obvious issues)
2. **Syntax Validation** (ensures code compiles/parses)
3. **Linting** (code quality, best practices)
4. **Type Checking** (if applicable)
5. **Security Scanning** (optional, can be in separate workflow)

### 3. Stop on First Failure
**CRITICAL**: If any step fails, **STOP IMMEDIATELY**. Do not proceed to next steps.

### 4. Report Results
- ✅ **Passed**: All checks passed
- ❌ **Failed**: Show first failure with line numbers
- ⏭️ **Skipped**: No files of this type found

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Lint

on: [push, pull_request]

jobs:
  lint-go:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
      - uses: actions/setup-go@v5 # TODO: pin to SHA
        with:
          go-version: '1.23'
      - name: golangci-lint
        uses: golangci/golangci-lint-action@v4 # TODO: pin to SHA
        with:
          version: v2.1.2

  lint-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
      - uses: actions/setup-python@v5 # TODO: pin to SHA
        with:
          python-version: '3.11'
      - name: Install tools
        run: pip install ruff mypy
      - name: Ruff check
        run: ruff check .
      - name: Type check
        run: mypy src/
```

## Pre-commit Hooks

Recommended: Use pre-commit hooks to catch issues **before** commit.

See `.pre-commit-config.yaml` for configuration.

## Performance Tips

- **Cache dependencies**: Cache tool installations in CI/CD
- **Parallel execution**: Run linters for different languages in parallel
- **Incremental linting**: Only lint changed files (e.g., `git diff --name-only`)
- **Docker caching**: Use Docker layer caching for containerized linters
