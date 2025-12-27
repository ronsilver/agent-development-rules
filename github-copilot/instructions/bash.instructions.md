# Bash Instructions

## Header

```bash
#!/usr/bin/env bash
set -euo pipefail
```

## Variables

- Siempre con comillas: `"${variable}"`
- Locales: `lowercase_snake_case`
- Constantes: `UPPERCASE`

## Condicionales

- Usar `[[ ]]` en lugar de `[ ]`

## Funciones

- Usar `local` para variables internas
- Validar argumentos requeridos

## Error Handling

- Usar `trap` para cleanup
