---
name: validate
description: Validate current project code
---

# Workflow: Validate

Execute validation tools based on project type.

## Detection

| File Marker | Project Type |
|-------------|--------------|
| `*.tf` | Terraform |
| `go.mod` | Go |
| `package.json` | Node.js/TypeScript |
| `pyproject.toml` | Python |
| `Dockerfile` | Docker |
| `Chart.yaml` | Helm |

## Commands

### Terraform
```bash
terraform fmt -recursive -check
terraform init -backend=false
terraform validate
```

### Go
```bash
go fmt ./...
golangci-lint run
go test ./... -race
```

### Python
```bash
ruff check .
black --check .
mypy src/
pytest
```

### Node.js
```bash
npm run typecheck
npm run lint
npm test
```

## Execution Steps

1.  **Detect**.
2.  **Execute** commands in order.
3.  **STOP** immediately if any command fails.
4.  **Report** success or failure (with line numbers).
