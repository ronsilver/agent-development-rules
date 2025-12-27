---
name: test
description: Ejecutar tests
---

# Workflow: Tests

## Pasos

1. **Detectar tipo de proyecto**

2. **Ejecutar tests según tipo**
   - Terraform: `terraform test`
   - Go: `go test ./...`
   - Python: `pytest`
   - Node: `npm test`

3. **Reportar resultados**
   - Tests pasados/fallidos
   - Detalles de fallos
