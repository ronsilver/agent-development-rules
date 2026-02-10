---
trigger: always
---

# Linting — Principles & Quick Reference

## The Golden Chain — MANDATORY

```
Format → Lint → Type Check → Test → Security Scan
```

**Stop immediately if any step fails.** For detailed commands, use the **lint** workflow.

## Linters by Language

| Language | Format | Lint | Type Check | Security |
|----------|--------|------|------------|----------|
| **Go** | `go fmt` | `golangci-lint` | (built-in) | `gosec` |
| **Python** | `ruff format` | `ruff check` | `mypy` | `bandit` |
| **TypeScript** | `prettier` | `eslint` | `tsc --noEmit` | — |
| **Terraform** | `terraform fmt` | `tflint` | `terraform validate` | `checkov`, `trivy config` |
| **Bash** | `shfmt` | `shellcheck` | — | — |
| **Docker** | — | `hadolint` | — | `trivy image` |
| **K8s/Helm** | — | `kubeconform`, `kube-linter` | `helm lint` | — |

## When to Run

| Stage | Scope | Purpose |
|-------|-------|---------|
| **Pre-commit** | Format + Lint (fast) | Immediate feedback |
| **CI — PR** | Format + Lint + Type Check + Test | Gate before merge |
| **CI — Main** | All + Security Scan | Final validation |

## Common Pitfalls

| Anti-Pattern | Fix |
|-------------|-----|
| Disabling too many rules | Start strict, relax selectively |
| `eslint . \|\| true` | Never ignore exit codes in CI |
| No CI enforcement | Pre-commit can be skipped — enforce in CI |
| Linters not in CI | Make lint mandatory, not optional |

## Best Practices

1. **Start strict** — easier to relax than tighten
2. **Automate** — pre-commit hooks + CI/CD enforcement
3. **Fast feedback** — lint locally before push
4. **Unified tools** — prefer `golangci-lint`, `ruff` over multiple single-purpose tools
5. **Pin versions** — ensure reproducible CI builds
