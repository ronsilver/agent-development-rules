---
name: test
description: Ejecutar tests del proyecto
---

# Workflow: Tests

Ejecutar tests del proyecto detectando automáticamente el tipo.

## Comandos por Tipo de Proyecto

| Proyecto | Comando | Con Coverage |
|----------|---------|---------------|
| Terraform | `terraform test` | N/A |
| Go | `go test ./...` | `go test ./... -cover` |
| Python | `pytest` | `pytest --cov=src` |
| Node/TS | `npm test` | `npm run test:coverage` |

## Pasos del Workflow

### 1. Detectar Tipo de Proyecto
- `*.tf` → Terraform
- `go.mod` → Go
- `package.json` → Node.js/TypeScript
- `pyproject.toml`, `requirements.txt` → Python

### 2. Ejecutar Tests

```bash
# Terraform
terraform test

# Go
go test ./... -v -race

# Python
pytest -v

# Node.js
npm test
```

### 3. Reportar Resultados

```markdown
## Resultados de Tests

- ✅ **Pasados:** X tests
- ❌ **Fallidos:** Y tests
- ⏭️ **Skipped:** Z tests

### Detalles de Fallos

#### test_nombre_del_test
**Archivo:** path/to/test.py:Línea
**Error:** Descripción del error
**Expected:** valor esperado
**Got:** valor obtenido
```

## Opciones Adicionales

```bash
# Solo tests específicos
go test ./... -run TestNombre
pytest tests/test_specific.py -k "test_name"
npm test -- --grep "test name"

# Verbose
go test ./... -v
pytest -v
npm test -- --verbose
```
