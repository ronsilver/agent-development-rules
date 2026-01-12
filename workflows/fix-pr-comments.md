---
name: fix-pr-comments
description: Systematically address PR review comments
---

# Workflow: Fix PR Comments

Systematically process and resolve PR review comments.

## 1. Fetch Comments

```bash
# View PR and comments
gh pr view --comments
gh pr diff
```

## 2. Triage Comments

| Type | Action |
|------|--------|
| 🔴 **Bug/Error** | Fix immediately. |
| 🟠 **Security** | Fix immediately. |
| 🟡 **Style/Nit** | Apply if it improves clarity. |
| 🟢 **Docs** | Apply if relevant. |
| ⚪ **False Positive** | Explain why it does not apply. |

## 3. Process Each Comment

### If Valid
1.  Apply the fix.
2.  Run validations (`make lint`, `make test`).
3.  Commit with reference:
    ```bash
    git commit -m "fix: address review comment - description"
    ```

### If Invalid
1.  Prepare a clear explanation.
2.  Cite documentation/standards.
3.  Suggest alternatives.

## 4. Verify Changes

```bash
# Lint & Test
make lint && make test
# STOP if any checks fail
```

## 5. Push & Notify

```bash
git push origin <branch>
gh pr comment --body "Review comments addressed. See recent commits."
```
