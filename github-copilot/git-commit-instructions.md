# Git Commit Instructions

Seguir Conventional Commits para mensajes consistentes y versionado semántico automático.

## Formato

```
<type>(<scope>): <description>

[body opcional]

[footer opcional]
```

## Tipos de Commit

| Tipo | Descripción | Versión |
|------|-------------|---------|
| `feat` | Nueva funcionalidad | MINOR |
| `fix` | Corrección de bug | PATCH |
| `docs` | Solo documentación | - |
| `style` | Formateo, sin cambio de lógica | - |
| `refactor` | Cambio de código sin fix ni feature | - |
| `perf` | Mejora de performance | PATCH |
| `test` | Agregar o corregir tests | - |
| `chore` | Mantenimiento, configuración | - |
| `ci` | Cambios en CI/CD | - |
| `build` | Sistema de build o dependencias | - |
| `revert` | Revertir commit anterior | - |

## Reglas

### Subject Line (primera línea)
- Imperativo presente: "add" no "added" ni "adding"
- Primera letra en minúscula
- Sin punto al final
- Máximo 50 caracteres (límite duro: 72)

### Body (opcional)
- Separado del subject por línea en blanco
- Explicar **qué** y **por qué**, no **cómo**
- Wrap a 72 caracteres

### Footer (opcional)
- `BREAKING CHANGE:` para cambios incompatibles (incrementa MAJOR)
- Referencias a issues: `Fixes #123`, `Closes #456`

## Ejemplos

```bash
# Feature simple
feat(auth): add OAuth2 authentication

# Fix con scope
fix(api): resolve null pointer in login handler

# Breaking change
feat(api)!: change response format for /users endpoint

BREAKING CHANGE: response now returns array instead of object

# Con body explicativo
refactor(db): simplify connection pooling logic

Remove redundant connection validation that was causing
performance issues under high load. The database driver
already handles connection validation internally.

Fixes #234

# Documentación
docs(readme): add installation steps for Docker

# Dependencias
chore(deps): upgrade axios to 1.6.0
```

## Commits Atómicos

- Un cambio lógico por commit
- Si el commit necesita "y" en la descripción, probablemente debería ser múltiples commits
- Usar `git add -p` para staging parcial

## Versionado Resultante (SemVer)

- **MAJOR** (X.0.0): `BREAKING CHANGE` o `!` después del tipo
- **MINOR** (0.X.0): `feat`
- **PATCH** (0.0.X): `fix`, `perf`
