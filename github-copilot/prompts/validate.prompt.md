# Validate

Validar el código según el tipo de proyecto:

- **Terraform**: `terraform fmt && terraform validate`
- **Go**: `go fmt && go vet && go test`
- **Python**: `black --check && pytest`
- **Node**: `npm run lint && npm test`

Reportar errores encontrados.
