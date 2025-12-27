---
name: pre-push
description: Verificaciones antes de push
---

# Workflow: Pre-Push

## Pasos

1. **Verificar cambios pendientes**
   ```bash
   git status
   ```

2. **Validar código** (según tipo de proyecto)
   - Terraform: `terraform fmt && terraform validate`
   - Go: `go fmt && go vet && go test`
   - Python: `black --check && pytest`
   - Node: `npm run lint && npm test`

3. **Sincronizar con remoto**
   ```bash
   git fetch origin
   git pull --rebase origin <branch>
   ```

4. **Resolver conflictos** si hay

5. **Confirmar push**
   - Mostrar commits a enviar
   - Esperar confirmación del usuario
   ```bash
   git push origin <branch>
   ```
