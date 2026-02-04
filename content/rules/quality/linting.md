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

**Runs**: `shfmt -l -d *.sh && shellcheck *.sh`

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
| `kubeval` | YAML schema validation | ⚡ Fast | ✅ Yes |
| `helm lint` | Helm chart validation | ⚡ Fast | ✅ Yes (if Helm) |
| `datree` | Best practices | 🔥 Medium | ⚠️ Recommended |

**Runs**: `kubeval *.yaml && helm lint ./chart`

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
    paths:
      - '**.go'
      - '**.py'
      - '**.ts'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Go Lint
        if: contains(github.event.pull_request.files, '.go')
        uses: golangci/golangci-lint-action@v4
        with:
          version: v2.1.2

      - name: Python Lint
        if: contains(github.event.pull_request.files, '.py')
        run: |
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

### ❌ Anti-patterns

1. **Disabling too many rules**: Defeats the purpose
   ```yaml
   # Bad
   disable:
     - errcheck
     - gosec
     - staticcheck
   ```

2. **Ignoring all warnings**: Warnings often catch real bugs
   ```bash
   # Bad
   eslint . || true  # Ignores exit code
   ```

3. **No CI enforcement**: Pre-commit hooks can be skipped
   ```bash
   # Developers can bypass
   git commit --no-verify
   ```

4. **Running linters separately**: Wastes time
   ```bash
   # Bad
   go fmt ./...
   go vet ./...
   golangci-lint run

   # Good
   golangci-lint run  # Includes fmt, vet, and more
   ```

### ✅ Best Practices

1. **Start strict**: Easier to relax than tighten
2. **Automate everything**: Pre-commit + CI/CD
3. **Fast feedback**: Local linting before push
4. **Enforce in CI**: Make it mandatory, not optional
5. **Update regularly**: Tools improve constantly

## Tool Version Management

### Keep Tools Updated

```bash
# Go
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Python
pip install --upgrade ruff mypy

# Node.js
npm update -g eslint prettier
```

### Pin Versions in CI/CD

```yaml
# GitHub Actions
- uses: golangci/golangci-lint-action@v4
  with:
    version: v2.1.2  # Pin specific version

# Docker
FROM golangci/golangci-lint:v2.1.2  # Pin version
```

## Measuring Impact

Track these metrics to measure linting effectiveness:

- **Bugs caught in linting**: vs testing/production
- **Build time**: Linting should be < 5% of total CI time
- **False positives**: Should be < 5% of total issues
- **Developer satisfaction**: Survey team regularly

## Resources

### Documentation
- **golangci-lint**: https://golangci-lint.run
- **Ruff**: https://docs.astral.sh/ruff
- **ESLint**: https://eslint.org
- **TFLint**: https://github.com/terraform-linters/tflint
- **Hadolint**: https://hadolint.com

### Learning
- **golangci-lint best practices**: https://golangci-lint.run/docs/usage/best-practices
- **Ruff vs Black/Flake8**: https://docs.astral.sh/ruff/faq/
- **ESLint flat config migration**: https://eslint.org/docs/latest/use/configure/migration-guide

## Summary

**The key to effective linting**:
1. ⚡ **Fast feedback**: Pre-commit hooks
2. 🔒 **Enforce in CI**: Make it mandatory
3. 📊 **Measure impact**: Track bugs caught
4. 🔄 **Keep updated**: Tools improve constantly
5. 👥 **Team buy-in**: Explain the why, not just the what

Linting is **not optional**—it's a quality gate that prevents bugs, security issues, and technical debt.
