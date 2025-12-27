---
trigger: glob
globs: ["README.md", "CHANGELOG.md", "docs/**"]
---

# Documentation Best Practices

## README

### Estructura Mínima
- Título y descripción
- Requisitos
- Instalación
- Uso
- Configuración

## CHANGELOG

Formato Keep a Changelog:
```markdown
## [1.0.0] - 2024-01-15

### Added
- Nueva feature

### Changed
- Cambio en comportamiento

### Fixed
- Bug corregido
```

## terraform-docs

Usar modo inject:
```yaml
# .terraform-docs.yml
output:
  file: README.md
  mode: inject
  template: |-
    <!-- BEGIN_TF_DOCS -->
    {{ .Content }}
    <!-- END_TF_DOCS -->
```

## Comentarios en Código

- Solo cuando explican el "por qué"
- No comentarios obvios
- Mantener actualizados

```python
# ❌
# Incrementar contador
counter += 1

# ✅
# Skip header rows (first 2 lines)
counter += 2
```

## API Documentation

- OpenAPI/Swagger para REST
- Ejemplos de request/response
- Documentar errores posibles
