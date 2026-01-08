# Agent Rules

Reglas centralizadas de desarrollo para agentes de AI (Windsurf, GitHub Copilot, Cursor, etc.).

## Estructura

```
agent-rules/
├── manifest.yaml          # Configuración central
│
├── rules/                 # Reglas de desarrollo (centralizadas)
│   ├── global.md          # Comportamiento del agente
│   ├── git.md             # Git/GitHub + Conventional Commits
│   ├── security.md        # OWASP Top 10:2025
│   ├── testing.md         # Testing Best Practices
│   ├── performance.md     # Performance
│   ├── scalability.md     # Escalabilidad
│   ├── solid.md           # Principios SOLID
│   ├── operational-excellence.md  # SRE/Observabilidad
│   ├── documentation.md   # Documentación
│   ├── terraform.md       # Terraform
│   ├── aws.md             # AWS
│   ├── go.md              # Go
│   ├── python.md          # Python
│   ├── nodejs.md          # Node.js/TypeScript
│   ├── bash.md            # Bash
│   ├── docker.md          # Docker
│   └── kubernetes.md      # Kubernetes
│
├── workflows/             # Workflows (slash commands)
│   ├── validate.md        # /validate
│   ├── test.md            # /test
│   ├── lint.md            # /lint
│   ├── pre-push.md        # /pre-push
│   ├── pr-review.md       # /pr-review
│   └── ...
│
├── prompts/               # Prompts reutilizables
│   ├── review.prompt.md
│   ├── security.prompt.md
│   ├── test.prompt.md
│   └── ...
│
└── scripts/
    └── sync.sh            # Script de sincronización
```

## Uso

### Sincronizar Reglas

```bash
# Sincronizar a todos los agentes habilitados
./scripts/sync.sh

# Sincronizar solo un agente
./scripts/sync.sh --agent windsurf
./scripts/sync.sh --agent github-copilot

# Ver qué haría sin ejecutar
./scripts/sync.sh --dry-run

# Listar agentes disponibles
./scripts/sync.sh --list
```

### Requisitos

```bash
# Instalar yq (parser de YAML)
brew install yq
```

## Configuración

### manifest.yaml

El archivo `manifest.yaml` define:
- **Archivos fuente**: Lista de reglas, workflows y prompts
- **Agentes**: Configuración de destinos por agente

```yaml
# Ejemplo de configuración de agente
agents:
  windsurf:
    enabled: true
    targets:
      rules:
        path: "${HOME}/.codeium/memories/global_rules.md"
        format: merged
```

### Agregar Nuevo Agente

1. Agregar sección en `manifest.yaml` bajo `agents:`
2. Configurar `targets` con paths de destino
3. Ejecutar `./scripts/sync.sh --agent <nombre>`

### Agregar Nueva Regla

1. Crear archivo en `rules/<nombre>.md`
2. Agregar a lista en `manifest.yaml` bajo `rules.files`
3. Ejecutar `./scripts/sync.sh`

## Contenido de Reglas

### Excelencia Operativa
- **security.md** - OWASP Top 10:2025
- **testing.md** - Pirámide de tests, cobertura, naming
- **performance.md** - Big O, caching, queries
- **scalability.md** - Stateless, rate limiting, circuit breakers
- **operational-excellence.md** - Logs, métricas, alertas, SRE
- **solid.md** - Principios SOLID

### Tecnologías
- **terraform.md** - IaC best practices
- **aws.md** - AWS security, IAM, S3
- **go.md** - Go idioms
- **python.md** - Type hints, Pydantic
- **nodejs.md** - TypeScript, ESM
- **bash.md** - Shell scripting
- **docker.md** - Dockerfile best practices
- **kubernetes.md** - K8s/Helm patterns

### Proceso
- **git.md** - Conventional Commits (estricto)
- **documentation.md** - ADRs, READMEs
- **global.md** - Comportamiento del agente

## Agentes Soportados

| Agente | Estado | Descripción |
|--------|--------|-------------|
| **windsurf** | ✅ Habilitado | Windsurf IDE / Codeium Cascade |
| **github-copilot** | ✅ Habilitado | VS Code / IntelliJ |
| **cursor** | ⬜ Deshabilitado | Cursor IDE |
| **local-project** | ⬜ Deshabilitado | Copiar a proyecto local |

## Desarrollo

### Estructura de una Regla

```markdown
---
trigger: glob
globs: ["*.py", "*.go"]
---

# Título de la Regla

## Sección 1

Contenido...

## Sección 2

Contenido...
```

### Estructura de un Workflow

```markdown
---
description: Descripción del workflow
---

# /nombre-workflow

## Pasos

1. Paso 1
2. Paso 2
```

## Licencia

MIT
