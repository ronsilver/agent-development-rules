---
trigger: glob
globs: [".github/**", "*.yml", "*.yaml", ".gitignore"]
---

# Git Best Practices

## Commit Messages (Conventional Commits) - OBLIGATORIO

**Formato estricto:** `<type>(<scope>): <description>`

### Tipos de Commit - SOLO ESTOS PERMITIDOS

| Tipo | Uso | Versión | Ejemplo |
|------|-----|---------|----------|
| `feat` | **Nueva funcionalidad** para el usuario | MINOR | `feat(auth): add OAuth2 login` |
| `fix` | **Corrección de bug** que afecta al usuario | PATCH | `fix(api): resolve null pointer in handler` |
| `docs` | **Solo documentación** (README, comments, etc.) | - | `docs(readme): add Docker setup guide` |
| `style` | **Formateo** (espacios, comas, sin cambio de lógica) | - | `style(lint): fix indentation in utils` |
| `refactor` | **Cambio de código** sin fix ni feature | - | `refactor(db): simplify query builder` |
| `perf` | **Mejora de performance** | PATCH | `perf(api): add response caching` |
| `test` | **Tests** (agregar, corregir, refactorizar) | - | `test(auth): add login validation tests` |
| `chore` | **Mantenimiento** (config, deps, scripts) | - | `chore(deps): upgrade axios to 1.6.0` |
| `ci` | **CI/CD** (GitHub Actions, pipelines) | - | `ci(actions): add caching for node_modules` |
| `build` | **Build system** (webpack, vite, etc.) | - | `build(vite): update output config` |
| `revert` | **Revertir commit** anterior | - | `revert: feat(auth): add OAuth2 login` |

### Reglas OBLIGATORIAS

#### Subject Line (primera línea)
| Regla | Correcto | Incorrecto |
|-------|----------|------------|
| Imperativo presente | `add`, `fix`, `update` | `added`, `fixed`, `updates` |
| Minúscula inicial | `add feature` | `Add feature` |
| Sin punto final | `add feature` | `add feature.` |
| Máximo 50 chars | `add user auth` | `add user authentication system with OAuth2 and JWT support` |
| Scope obligatorio | `feat(auth): add login` | `feat: add login` |
| Scope en minúsculas | `feat(auth)` | `feat(Auth)` |
| Sin artículos | `add validation` | `add the validation` |
| Sin verbos auxiliares | `add feature` | `should add feature` |

#### Scope (OBLIGATORIO)
- **Siempre incluir scope** que indique el módulo/área afectada
- Usar nombres cortos y consistentes: `auth`, `api`, `db`, `ui`, `config`, `deps`
- Si afecta múltiples áreas, usar el área principal o `core`

#### Límites Estrictos
| Elemento | Límite | Acción si excede |
|----------|--------|------------------|
| Subject line | 50 chars | RECHAZAR - reformular más conciso |
| Subject line (hard limit) | 72 chars | RECHAZAR - dividir commit |
| Body line | 72 chars | Wrap automático |

### Validación OBLIGATORIA Antes de Commit

```bash
# Regex de validación (debe matchear)
^(feat|fix|docs|style|refactor|perf|test|chore|ci|build|revert)(\([a-z0-9-]+\))!?:\s[a-z].{1,48}[^.]$
```

### Ejemplos CORRECTOS ✅

```bash
# Feature con scope
feat(auth): add OAuth2 authentication

# Fix con scope específico
fix(api): resolve null pointer in login handler

# Docs
docs(readme): add installation steps for Docker

# Dependencias
chore(deps): upgrade axios to 1.6.0

# Breaking change (con ! después del scope)
feat(api)!: change response format for users endpoint

# Con body explicativo (separado por línea en blanco)
refactor(db): simplify connection pooling logic

Remove redundant connection validation that was causing
performance issues under high load.

Fixes #234
```

### Ejemplos INCORRECTOS ❌ - RECHAZAR

```bash
# ❌ Sin scope
feat: add authentication

# ❌ Pasado en lugar de imperativo
fixed(api): resolved the bug

# ❌ Mayúscula inicial
feat(auth): Add new login

# ❌ Con punto final
feat(auth): add login.

# ❌ Muy largo (>50 chars)
feat(auth): add complete user authentication system with OAuth2 support

# ❌ Scope en mayúsculas
feat(AUTH): add login

# ❌ Mensaje vago
fix(api): fix bug
chore: update stuff
feat(ui): changes

# ❌ Múltiples cambios en un commit
feat(auth): add login and registration and password reset

# ❌ Con artículos
feat(auth): add the new login feature

# ❌ Tipo incorrecto
update(auth): add login          # 'update' no es tipo válido
feature(auth): add login         # 'feature' no es tipo válido
```

### Commits Atómicos - OBLIGATORIO

- **Un cambio lógico = Un commit**
- Si necesitas "y" en la descripción → **DIVIDIR EN MÚLTIPLES COMMITS**
- Cada commit debe poder revertirse independientemente
- Usar `git add -p` para staging parcial

### Breaking Changes

```bash
# Opción 1: Con ! después del scope
feat(api)!: change response format

# Opción 2: Con footer BREAKING CHANGE
feat(api): change response format

BREAKING CHANGE: response now returns array instead of object.
Migration: update all clients to handle array response.
```

### Footer para Issues

```bash
# Cerrar issue
Fixes #123
Closes #456

# Relacionar sin cerrar
Ref #789
Relates-to #012
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
