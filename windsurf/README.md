# Windsurf Rules - Best Practices

Reglas y workflows de best practices para el agente de Windsurf.

## Estructura

```
windsurf/
├── rules/                # Best practices por tecnología
│   ├── global.md        # Comportamiento del agente
│   ├── terraform.md     # Terraform
│   ├── aws.md           # AWS
│   ├── git.md           # Git/GitHub
│   ├── go.md            # Go
│   ├── python.md        # Python
│   ├── nodejs.md        # Node.js/TypeScript
│   ├── bash.md          # Bash
│   ├── kubernetes.md    # Kubernetes/Helm
│   ├── docker.md        # Docker
│   └── documentation.md # Documentación
│
└── workflows/            # Workflows invocables
    ├── validate.md      # /validate
    ├── test.md          # /test
    ├── lint.md          # /lint
    ├── pre-push.md      # /pre-push
    ├── pr-review.md     # /pr-review
    ├── fix-pr-comments.md
    ├── terraform-module.md
    ├── docker-build.md
    ├── k8s-validate.md
    └── security-check.md
```

## Uso

### Reglas Automáticas
Se aplican según extensión de archivo:
- `*.tf` → terraform.md, aws.md
- `*.go` → go.md
- `*.py` → python.md
- `Dockerfile` → docker.md

### Workflows
```
/validate         # Validar Terraform
/test             # Ejecutar tests
/lint             # Linting
/pre-push         # Verificar antes de push
/fix-pr-comments  # Corregir comentarios de PR
```

## Instalación

```bash
cp -r windsurf/ /path/to/project/.windsurf/
```

## Personalización

### Nueva Regla
```yaml
---
trigger: glob
globs: ["*.ext"]
---

# Contenido
```

### Nuevo Workflow
```yaml
---
name: mi-workflow
description: Descripción
---

# Pasos
```
