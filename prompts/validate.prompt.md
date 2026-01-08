# Validate

Validar el código del proyecto actual ejecutando las herramientas apropiadas.

## Por Tipo de Proyecto

| Proyecto | Comandos |
|----------|----------|
| **Terraform** | `terraform fmt -check -recursive && terraform validate && terraform test` |
| **Go** | `go fmt ./... && go vet ./... && go test ./... -race` |
| **Python** | `black --check . && ruff check . && mypy src/ && pytest` |
| **Node/TS** | `npm run typecheck && npm run lint && npm test` |
| **Bash** | `shellcheck *.sh` |
| **Docker** | `hadolint Dockerfile` |
| **Helm** | `helm lint ./chart && helm template release ./chart` |

## Instrucciones

1. Detectar el tipo de proyecto por archivos presentes
2. Ejecutar comandos de validación en orden
3. Reportar:
   - ✅ Validaciones pasadas
   - ❌ Errores encontrados con línea y archivo
   - ⚠️ Warnings relevantes
4. Sugerir fixes para errores comunes
