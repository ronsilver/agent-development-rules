---
name: validate
description: Validar código del proyecto actual
---

# Workflow: Validar

Validar el código del proyecto detectando automáticamente el tipo.

## Detección de Proyecto

| Archivos Presentes | Tipo de Proyecto |
|-------------------|------------------|
| `*.tf` | Terraform |
| `go.mod` | Go |
| `package.json` | Node.js/TypeScript |
| `requirements.txt`, `pyproject.toml` | Python |
| `Dockerfile` | Docker |
| `Chart.yaml` | Helm |

## Comandos por Tipo

### Terraform
```bash
terraform fmt -recursive -check
terraform init -backend=false
terraform validate
terraform test  # si existe tests/
```

### Go
```bash
go fmt ./...
go vet ./...
golangci-lint run  # si está instalado
go test ./... -race
```

### Python
```bash
black --check .
ruff check .
mypy src/  # si existe src/
pytest
```

### Node.js/TypeScript
```bash
npm run typecheck  # si existe script
npm run lint
npm test
```

### Docker
```bash
hadolint Dockerfile
```

### Helm
```bash
helm lint ./chart
helm template release ./chart -f values.yaml
```

## Pasos del Workflow

1. **Detectar tipo de proyecto** por archivos presentes
2. **Ejecutar validaciones** en orden
3. **Verificar git status** para archivos no trackeados
4. **Reportar resultados**:
   - ✅ Validaciones exitosas
   - ❌ Errores con archivo y línea
   - ⚠️ Warnings relevantes
5. **Sugerir fixes** para errores comunes
