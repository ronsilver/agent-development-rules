---
trigger: glob
globs: ["*"]
---

# Linting Philosophy & Best Practices

## Why Linting is Critical

Linting catches bugs **before** they reach production:
- **Syntax errors**: Invalid code that won't compile
- **Logic bugs**: Unused variables, unreachable code
- **Security issues**: SQL injection, XSS vulnerabilities
- **Performance**: Inefficient patterns, memory leaks
- **Consistency**: Enforces team code style

**Impact**: Teams using linters catch 40-60% of bugs during development vs testing/production.

## The Golden Chain

Execute in this order for maximum effectiveness:

```
Format → Lint → Type Check → Test → Security Scan
```

1. **Format**: Catches obvious style issues (fast)
2. **Lint**: Code quality, best practices (medium)
3. **Type Check**: Type safety (medium-slow)
4. **Test**: Business logic correctness (slow)
5. **Security Scan**: Vulnerabilities, secrets (medium)

**Stop immediately if any step fails.**

## Linters by Language

### Go

| Tool | Purpose | Speed | Required |
|------|---------|-------|----------|
| `go fmt` | Formatting | ⚡ Fast | ✅ Yes |
| `go vet` | Suspicious constructs | ⚡ Fast | ✅ Yes |
| `golangci-lint` | Comprehensive linting | 🔥 Medium | ✅ Yes |
| `goimports` | Import organization | ⚡ Fast | ⚠️ Recommended |
| `gosec` | Security scanning | 🔥 Medium | ⚠️ Recommended |

**Config**: `.golangci.yml`

**Runs**: `golangci-lint run --config .golangci.yml`

### Python

| Tool | Purpose | Speed | Required |
|------|---------|-------|----------|
| `ruff format` | Formatting (replaces black) | ⚡ Fast | ✅ Yes |
| `ruff check` | Linting (replaces flake8, isort) | ⚡ Fast | ✅ Yes |
| `mypy` | Type checking | 🔥 Medium | ✅ Yes |
| `bandit` | Security scanning | 🔥 Medium | ⚠️ Recommended |

**Config**: `pyproject.toml`

**Runs**: `ruff format . && ruff check . && mypy src/`

### TypeScript / Node.js

| Tool | Purpose | Speed | Required |
|------|---------|-------|----------|
| `prettier` | Formatting | ⚡ Fast | ✅ Yes |
| `eslint` | Linting (flat config) | 🔥 Medium | ✅ Yes |
| `tsc` | Type checking | 🐌 Slow | ✅ Yes |

**Config**: `eslint.config.js` (flat config), `tsconfig.json`

**Runs**: `prettier --check . && eslint . && tsc --noEmit`

### Terraform

| Tool | Purpose | Speed | Required |
|------|---------|-------|----------|
| `terraform fmt` | Formatting | ⚡ Fast | ✅ Yes |
| `terraform validate` | Syntax validation | ⚡ Fast | ✅ Yes |
| `tflint` | Best practices | 🔥 Medium | ✅ Yes |
| `checkov` | Security & compliance | 🐌 Slow | ⚠️ CI/CD |
| `tfsec` | Security misconfigurations | 🔥 Medium | ⚠️ CI/CD |

**Config**: `.tflint.hcl`, `.checkov.yaml`

**Runs**: `terraform fmt -check && terraform validate && tflint`

### Bash

| Tool | Purpose | Speed | Required |
|------|---------|-------|----------|
| `shfmt` | Formatting | ⚡ Fast | ✅ Yes |
| `shellcheck` | Linting | ⚡ Fast | ✅ Yes |

**Config**: `.shellcheckrc`, `.editorconfig`

**Runs**: `shfmt -d . && find . -name '*.sh' -exec shellcheck {} +`

### Docker

| Tool | Purpose | Speed | Required |
|------|---------|-------|----------|
| `hadolint` | Dockerfile linting | ⚡ Fast | ✅ Yes |
| `docker scout` | Vulnerability scanning | 🔥 Medium | ⚠️ CI/CD |
| `trivy` | CVE scanning (alternative) | 🔥 Medium | ⚠️ CI/CD |

**Config**: `.hadolint.yaml`

**Runs**: `hadolint Dockerfile`

### Kubernetes / Helm

| Tool | Purpose | Speed | Required |
|------|---------|-------|----------|
| `kubeconform` | YAML schema validation | ⚡ Fast | ✅ Yes |
| `helm lint` | Helm chart validation | ⚡ Fast | ✅ Yes (if Helm) |
| `datree` | Best practices | 🔥 Medium | ⚠️ Recommended |

**Runs**: `kubeconform -strict *.yaml && helm lint ./chart`

## Pre-commit Hooks

**Purpose**: Catch issues **before** committing, preventing broken code from entering the repository.

### Installation

```bash
pip install pre-commit

# Install hooks (run once per repo)
pre-commit install
```

### Configuration

See `.pre-commit-config.yaml` for full configuration.

**Minimal example**:
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
```

### Usage

```bash
# Runs automatically on git commit
git commit -m "feat: add feature"

# Run manually on all files
pre-commit run --all-files

# Skip hooks (NOT recommended)
git commit --no-verify
```

## CI/CD Integration

### When to Run Linters

| Stage | Tools | Purpose |
|-------|-------|---------|
| **Pre-commit** | Format, Lint (fast) | Immediate feedback |
| **CI - PR** | Format, Lint, Type Check, Test | Gate before merge |
| **CI - Main** | All + Security Scan | Final validation |

### GitHub Actions Example

```yaml
name: Lint

on:
  pull_request:

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      go: ${{ steps.filter.outputs.go }}
      python: ${{ steps.filter.outputs.python }}
      typescript: ${{ steps.filter.outputs.typescript }}
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
      - uses: dorny/paths-filter@v3 # TODO: pin to SHA
        id: filter
        with:
          filters: |
            go:
              - '**/*.go'
            python:
              - '**/*.py'
            typescript:
              - '**/*.ts'
              - '**/*.tsx'

  go-lint:
    needs: detect-changes
    if: needs.detect-changes.outputs.go == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
      - uses: golangci/golangci-lint-action@v4 # TODO: pin to SHA
        with:
          version: v2.1.2

  python-lint:
    needs: detect-changes
    if: needs.detect-changes.outputs.python == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
      - run: |
          pip install ruff mypy
          ruff check .
          mypy src/
```

## Performance Optimization

### Local Development
- **Cache tool installations**: Use Docker or system package managers
- **Incremental linting**: Only lint changed files
  ```bash
  # Go
  golangci-lint run $(git diff --name-only HEAD | grep '\.go$')

  # Python
  ruff check $(git diff --name-only HEAD | grep '\.py$')
  ```
- **Watch mode**: Real-time linting
  ```bash
  # Ruff
  ruff check . --watch
  ```

### CI/CD
- **Parallel jobs**: Run linters for different languages in parallel
- **Cache dependencies**: Cache tool installations between runs
- **Fail fast**: Stop on first failure, don't run all checks

## Handling Legacy Code

### Baseline Creation

For existing codebases with many linting errors:

**Checkov** (Terraform):
```bash
# Create baseline
checkov -d . --create-baseline

# Run with baseline (ignores existing issues)
checkov -d . --baseline checkov_baseline.json
```

**ESLint** (TypeScript):
```bash
# Generate warnings-only config
eslint --init

# Gradually fix warnings
eslint . --fix
```

### Gradual Adoption

1. **Week 1**: Enable format checks only
2. **Week 2**: Enable basic linting rules
3. **Week 3**: Enable type checking
4. **Week 4**: Enable security scanning
5. **Week 5+**: Increase strictness gradually

## Common Pitfalls

| Anti-Pattern | Problem | Solution |
|-------------|---------|----------|
| Disabling too many rules | Defeats the purpose | Start strict, relax selectively |
| `eslint . \|\| true` | Ignores exit code | Fail CI on any lint error |
| No CI enforcement | Pre-commit can be skipped | Enforce in CI pipeline |
| Running linters separately | Wastes time | Use unified tools (`golangci-lint`, `ruff`) |

## Best Practices

1. **Start strict**: Easier to relax than tighten
2. **Automate everything**: Pre-commit + CI/CD
3. **Fast feedback**: Local linting before push
4. **Enforce in CI**: Make it mandatory, not optional
5. **Pin versions in CI**: Ensure reproducible builds
6. **Update regularly**: Tools improve constantly
