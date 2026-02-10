---
name: Review
description: Review code for bugs, security vulnerabilities, and performance issues
trigger: manual
tags: [code-review, analysis, quality]
skill: code-review
---

# Review

Review the selected code or recent changes to identify issues. Focus on **impact** and **actionability**. Apply the **code-review** skill for the full workflow, checklist, and feedback techniques.

## Review Limits

- **Maximum issues to report**: 10 (prioritize by severity)
- **Focus on**: Issues that affect correctness, security, or significant performance
- **Skip**: Pure style preferences already covered by linters

## Severity Levels

| Level | Icon | Criteria | Action |
|-------|------|----------|--------|
| CRITICAL | 🔴 | Security vuln, data loss, crash | **Block merge** |
| WARNING | 🟠 | Performance, tech debt, bugs | Should fix before merge |
| INFO | 🟡 | Style, suggestions, nitpicks | Optional improvement |

## Report Format

~~~markdown
## 🔴 [CRITICAL] SQL Injection Vulnerability

**File:** `src/db/users.py:45`
**Category:** Security
**CWE:** CWE-89

**Problem:**
User input is concatenated directly into SQL query.

**Current Code:**
```python
query = f"SELECT * FROM users WHERE email = '{email}'"
```

**Suggested Fix:**
```python
query = "SELECT * FROM users WHERE email = %s"
cursor.execute(query, (email,))
```

**Impact:** An attacker could extract or modify all database records.
~~~

## Instructions

1. **Determine scope** — selected code, git diff, full file, or PR
2. **Scan** for CRITICAL issues first (bugs, security)
3. **Analyze** performance and maintainability concerns
4. **Prioritize** by severity — report max 10 issues
5. **Provide** actionable fix for each CRITICAL/WARNING issue
6. **Skip** style issues already covered by linters
