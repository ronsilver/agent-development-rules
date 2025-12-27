# Go Instructions

## Error Handling

- Siempre manejar errores, no ignorar con `_`
- Retornar errores con contexto: `fmt.Errorf("action: %w", err)`
- No usar `panic` en producción

## Naming

- Packages: lowercase, sin guiones
- Exports: Capitalized
- Variables cortas en scope pequeño

## Context

- Siempre como primer parámetro
- Propagar en llamadas

## Testing

- Table-driven tests
- Archivos `_test.go` junto al código
