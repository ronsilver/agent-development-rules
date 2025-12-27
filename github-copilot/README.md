# GitHub Copilot - Custom Instructions

Reglas y prompts para GitHub Copilot.

## Estructura

```
github-copilot/
├── copilot-instructions.md     # Copilot Instructions (Global)
├── git-commit-instructions.md  # Git Commit Instructions
├── instructions/               # Instruction Files por tipo
│   ├── terraform.instructions.md
│   ├── go.instructions.md
│   ├── python.instructions.md
│   ├── typescript.instructions.md
│   ├── bash.instructions.md
│   ├── docker.instructions.md
│   └── kubernetes.instructions.md
└── prompts/                    # Prompt Files reutilizables
    ├── validate.prompt.md
    ├── review.prompt.md
    ├── test.prompt.md
    ├── refactor.prompt.md
    ├── document.prompt.md
    └── security.prompt.md
```

## Instalación

### Copilot Instructions (Global)
1. VS Code: Settings → GitHub Copilot → Customizations → Global
2. Copiar contenido de `copilot-instructions.md`

### Git Commit Instructions
1. VS Code: Settings → GitHub Copilot → Git Commit Instructions → Global
2. Copiar contenido de `git-commit-instructions.md`

### Instruction Files (Workspace)
1. Copiar archivos `.instructions.md` a la raíz del proyecto o `.github/`
2. O configurar en settings.json:
```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    { "file": "terraform.instructions.md" }
  ]
}
```

### Prompt Files
1. VS Code: Settings → GitHub Copilot → Prompt Files → Global
2. Agregar archivos `.prompt.md`
