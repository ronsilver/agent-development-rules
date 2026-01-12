---
name: pre-push
description: Comprehensive pre-push checks
---

# Workflow: Pre-Push

Run this checklist BEFORE pushing to remote.

## Steps

### 1. Check Repository Status
```bash
git status
git diff --stat
```
**Verify:**
- No untracked files that should be committed.
- NO SENSITIVE FILES (`.env`, secrets).

### 2. Validate Code (Run ALL Checks)

| Project | Commands |
|---------|----------|
| Terraform | `terraform fmt -check && terraform validate` |
| Go | `go fmt ./... && golangci-lint run && go test ./...` |
| Python | `black --check . && ruff check . && pytest` |
| Node/TS | `npm run lint && npm test` |

**STOP**: If any command fails, fix it. DO NOT PUSH.

### 3. Sync with Remote
```bash
git fetch origin
git rebase origin/main
```

### 4. Review Commits to Push
```bash
git log --oneline origin/main..HEAD
```
**Verify:**
- Messages follow Conventional Commits (`feat(scope): ...`).
- No "WIP" or "fix" generic messages.
- Commits are atomic.

### 5. Push
```bash
git push origin <branch>
```
