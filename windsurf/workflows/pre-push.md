---
name: pre-push
description: Verificaciones completas antes de push
---

# Workflow: Pre-Push

Checklist completo antes de hacer push al repositorio remoto.

## Pasos

### 1. Verificar Estado del Repositorio
```bash
git status
git diff --stat  # Ver resumen de cambios
```

**Verificar:**
- No hay archivos sin trackear que deberían incluirse
- No hay archivos sensibles (`.env`, `*.tfvars`, secrets)

### 2. Validar Código

| Proyecto | Comandos |
|----------|----------|
| Terraform | `terraform fmt -check && terraform validate` |
| Go | `go fmt ./... && go vet ./... && go test ./...` |
| Python | `black --check . && ruff check . && pytest` |
| Node/TS | `npm run lint && npm test` |

### 3. Sincronizar con Remoto
```bash
git fetch origin
git log --oneline HEAD..origin/main  # Ver commits nuevos en main
```

**Si hay cambios:**
```bash
git pull --rebase origin main
```

### 4. Resolver Conflictos (si hay)
```bash
# Después de resolver cada archivo:
git add <archivo>
git rebase --continue
```

### 5. Revisar Commits a Enviar
```bash
git log --oneline origin/main..HEAD
```

**Verificar:**
- Mensajes de commit siguen convención
- No hay commits de debug o WIP
- Cambios son coherentes y atómicos

### 6. Push
```bash
git push origin <branch>
```

## Checklist Final

- [ ] Tests pasan
- [ ] Lint/format aplicado
- [ ] No hay archivos sensibles
- [ ] Sincronizado con main
- [ ] Commits tienen mensajes descriptivos
