---
name: lint
description: Ejecutar linters
---

# Workflow: Lint

## Por Tipo de Proyecto

### Terraform
```bash
terraform fmt -check -recursive
terraform validate
```

### Go
```bash
go fmt ./...
go vet ./...
golangci-lint run
```

### Python
```bash
black --check .
ruff check .
mypy src/
```

### Node.js
```bash
npm run lint
```

### Bash
```bash
shellcheck *.sh
```
