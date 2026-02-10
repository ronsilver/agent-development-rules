---
name: Validate
description: Validate project using appropriate tools for quality and correctness
trigger: manual
tags: [validation, quality, linting]
workflow: validation/validate
---

# Validate

Validate the current project using appropriate tools for quality and correctness. Follow the **validation/validate** workflow for project detection, commands, and execution strategy.

## Report Format

### Success
```
✅ Validation passed

Summary:
- Terraform: fmt ✓, validate ✓
- Go: fmt ✓, vet ✓, lint ✓, test ✓ (coverage: 78%)
```

### Failure
```
❌ Validation failed

Error: golangci-lint found issues

File: internal/handler/user.go:45
Rule: errcheck
Issue: Error return value not checked

Suggested fix:
  result, err := db.Query(...)
  if err != nil {
      return fmt.Errorf("query failed: %w", err)
  }
```

## Instructions

1. **Detect** project type(s) based on marker files
2. **Verify** prerequisites — check required tools are installed
3. **Execute** validation commands in order
4. **Stop immediately** if any command fails (exit code != 0)
5. **Report** results with actionable details
