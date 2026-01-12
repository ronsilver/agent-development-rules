# Review

Review the selected code or recent changes to identify issues.

## Review Categories

### 1. Bugs & Correctness
- Null/undefined references.
- Race conditions / Concurrency issues.
- Off-by-one errors.
- Resource leaks (connections, file handles).
- Incomplete error handling.

### 2. Security (OWASP)
- Hardcoded secrets or credentials.
- Unvalidated/Unsanitized inputs.
- SQL Injection, XSS, Path Traversal.
- Excessive permissions.
- Sensitive data in logs.

### 3. Performance
- N+1 queries.
- Unnecessary loops / O(n^2) or worse.
- Excessive allocations.
- Missing database indexes.
- Blocking synchronous calls.

### 4. Maintainability
- Long functions (>50 lines).
- Duplicated code (DRY violation).
- Confusing or inconsistent naming.
- High coupling.
- Lack of tests.

## Report Format

For each issue found:

```markdown
## [SEVERITY] Issue Title

**File:** path/to/file.ext:Line
**Category:** Security | Performance | Bug | Maintainability

**Problem:**
Description of the issue.

**Suggestion:**
How to fix it (provide code snippet if applicable).
```

## Severity Levels

- 🔴 **CRITICAL**: Must fix before merge (Security/Data Loss).
- 🟠 **WARNING**: Should fix (Tech Debt/Performance).
- 🟡 **INFO**: Suggestion / Nitpick.
