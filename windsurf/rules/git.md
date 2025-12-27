---
trigger: glob
globs: [".github/**", "*.yml", "*.yaml", ".gitignore"]
---

# Git Best Practices

## Commit Messages

Formato: `<type>: <description>`

### Tipos
- `feat` - Nueva funcionalidad
- `fix` - Corrección de bug
- `docs` - Documentación
- `refactor` - Refactorización
- `test` - Tests
- `chore` - Mantenimiento

```bash
git commit -m "feat: add user authentication"
git commit -m "fix: resolve null pointer in login"
```

## Branches

### Naming
- `main` / `master` - Producción
- `develop` - Desarrollo
- `feature/<name>` - Features
- `fix/<name>` - Correcciones
- `hotfix/<name>` - Fixes urgentes

## Pre-Push

Antes de push, siempre:
```bash
git fetch origin
git pull --rebase origin <branch>
# Correr tests
git push origin <branch>
```

## .gitignore

### Terraform
```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!example.tfvars
```

### General
```gitignore
.env
*.log
.DS_Store
node_modules/
```

## Archivos Prohibidos

Nunca commitear:
- `.env` con secrets
- `*.tfvars` con valores reales
- `terraform.tfstate`
- Credentials, API keys, passwords

## GitHub Actions

### Versiones Específicas
```yaml
# ✅ Correcto
- uses: actions/checkout@v4

# ❌ Incorrecto
- uses: actions/checkout@main
```

### Template Básico
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: make test
```

## Pull Requests

### Antes de Crear
1. Ejecutar tests localmente
2. Verificar lint/format
3. Actualizar documentación si aplica

### Descripción
- Qué cambia
- Por qué
- Cómo probar
