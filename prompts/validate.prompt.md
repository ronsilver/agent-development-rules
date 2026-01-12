# Validate

Validate the current project using appropriate tools.

## By Project Type

| Project | Command |
|---------|---------|
| **Terraform** | `terraform fmt -check -recursive && terraform validate` |
| **Go** | `go fmt ./... && go vet ./... && golangci-lint run && go test -race ./...` |
| **Python** | `ruff check . && mypy src/ && pytest` |
| **Node/TS** | `npm run typecheck && npm run lint && npm test` |
| **Bash** | `shellcheck *.sh` |
| **Docker** | `hadolint Dockerfile` |
| **Helm** | `helm lint ./chart` |

## Instructions

1.  Detect project type based on files.
2.  Run validation commands in order.
3.  Report:
    - ✅ Checks passed.
    - ❌ Errors found (File + Line).
    - ⚠️ Relevant warnings.
4.  Suggest fixes for common errors.
