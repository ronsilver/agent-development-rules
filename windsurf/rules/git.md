---
trigger: glob
globs: [".github/**", "*.yml", "*.yaml", ".gitignore"]
---

# Git Best Practices

## Commit Messages (Conventional Commits)

Formato: `<type>(<scope>): <description>`

### Tipos de Commit
| Tipo | Descripción | Versión |
|------|-------------|----------|
| `feat` | Nueva funcionalidad | MINOR |
| `fix` | Corrección de bug | PATCH |
| `docs` | Solo documentación | - |
| `style` | Formateo, sin cambio de lógica | - |
| `refactor` | Cambio de código sin fix ni feature | - |
| `perf` | Mejora de performance | PATCH |
| `test` | Agregar o corregir tests | - |
| `chore` | Mantenimiento, configuración | - |
| `ci` | Cambios en CI/CD | - |

### Reglas
- Imperativo presente: "add" no "added"
- Primera letra en minúscula
- Sin punto al final
- Máximo 50 caracteres (límite: 72)

```bash
# Ejemplos
git commit -m "feat(auth): add OAuth2 authentication"
git commit -m "fix(api): resolve null pointer in login handler"
git commit -m "docs(readme): update installation steps"
git commit -m "chore(deps): upgrade axios to 1.6.0"

# Breaking change
git commit -m "feat(api)!: change response format for /users"
```

## Branches

### Naming Convention
| Prefijo | Uso | Ejemplo |
|---------|-----|----------|
| `main` | Producción | - |
| `develop` | Desarrollo | - |
| `feature/` | Nueva funcionalidad | `feature/user-auth` |
| `fix/` | Corrección | `fix/login-error` |
| `hotfix/` | Fix urgente en prod | `hotfix/security-patch` |
| `release/` | Preparar release | `release/1.2.0` |

## Flujo de Trabajo

### Antes de Empezar
```bash
git fetch origin
git checkout main
git pull --rebase origin main
git checkout -b feature/mi-feature
```

### Durante Desarrollo
```bash
# Commits pequeños y frecuentes
git add -p                    # Staging interactivo
git commit -m "feat: ..."     # Commits atómicos
```

### Pre-Push
```bash
# 1. Validar código
make lint
make test

# 2. Sincronizar con main
git fetch origin
git rebase origin/main

# 3. Resolver conflictos si hay
# ... resolver ...
git rebase --continue

# 4. Push
git push origin feature/mi-feature
```

## .gitignore

```gitignore
# Sistemas operativos
.DS_Store
Thumbs.db

# IDEs
.idea/
.vscode/
*.swp

# Dependencias
node_modules/
venv/
.venv/
vendor/

# Build
dist/
build/
*.pyc
__pycache__/

# Configuración local
.env
.env.*
!.env.example
*.local

# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!example.tfvars
.terraform.lock.hcl

# Logs
*.log
logs/

# Secrets (NUNCA commitear)
*.pem
*.key
secrets/
```

## Archivos Prohibidos

**Nunca commitear:**
- `.env` con secrets reales
- `*.tfvars` con valores de producción
- `terraform.tfstate` (usar remote state)
- Credentials, API keys, passwords
- Certificados y claves privadas

## GitHub Actions

### Versiones Específicas
```yaml
# ✅ Correcto - versión específica
- uses: actions/checkout@v4
- uses: actions/setup-node@v4

# ❌ Incorrecto - puede romper
- uses: actions/checkout@main
- uses: actions/setup-node@latest
```

### Template CI
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
    timeout-minutes: 15
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Lint
        run: npm run lint
      
      - name: Test
        run: npm test
      
      - name: Build
        run: npm run build
```

### Template Terraform
```yaml
name: Terraform

on:
  pull_request:
    paths:
      - '**.tf'
      - '.github/workflows/terraform.yml'

jobs:
  validate:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6'
      
      - name: Format
        run: terraform fmt -check -recursive
      
      - name: Init
        run: terraform init -backend=false
      
      - name: Validate
        run: terraform validate
```

## Pull Requests

### Antes de Crear
1. Tests pasan localmente
2. Lint/format aplicado
3. Documentación actualizada si aplica
4. Commits limpios (squash si necesario)

### Template de Descripción
```markdown
## Descripción
Breve descripción de los cambios.

## Tipo de Cambio
- [ ] Bug fix
- [ ] Nueva feature
- [ ] Breaking change
- [ ] Documentación

## Testing
- [ ] Tests unitarios agregados/actualizados
- [ ] Tests de integración pasan

## Checklist
- [ ] Código sigue el estilo del proyecto
- [ ] Self-review realizado
- [ ] Documentación actualizada
```

## Comandos Útiles

```bash
# Ver historial compacto
git log --oneline -20

# Ver cambios pendientes
git diff --stat

# Deshacer último commit (mantener cambios)
git reset --soft HEAD~1

# Limpiar branches mergeadas
git branch --merged | grep -v main | xargs git branch -d

# Buscar en historial
git log -S "texto" --oneline
```
