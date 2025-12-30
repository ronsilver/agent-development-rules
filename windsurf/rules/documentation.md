---
trigger: glob
globs: ["README.md", "CHANGELOG.md", "docs/**"]
---

# Documentation Best Practices

## README - Estructura

```markdown
# Nombre del Proyecto

Descripción breve (1-2 oraciones) de qué hace el proyecto.

## Requisitos

- Dependencia 1 >= versión
- Dependencia 2

## Instalación

```bash
# Comandos de instalación
```

## Uso

```bash
# Ejemplo básico
```

## Configuración

| Variable | Descripción | Default |
|----------|-------------|----------|
| `VAR_1` | Descripción | `value` |

## Desarrollo

```bash
# Setup para desarrollo local
```

## Testing

```bash
# Cómo correr tests
```

## Licencia

MIT
```

## CHANGELOG (Keep a Changelog)

```markdown
# Changelog

Todos los cambios notables de este proyecto serán documentados aquí.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Nueva feature en desarrollo

## [1.2.0] - 2024-01-15

### Added
- Soporte para OAuth2 authentication
- Endpoint para exportar datos

### Changed
- Mejorado rendimiento de queries

### Fixed
- Corregido error en validación de email

### Deprecated
- Método `oldMethod()` será removido en v2.0

### Removed
- Soporte para Node.js 16

### Security
- Actualizado axios por vulnerabilidad CVE-XXXX

## [1.1.0] - 2024-01-01
...
```

## terraform-docs

### Configuración (.terraform-docs.yml)
```yaml
formatter: markdown table

version: ">= 0.16.0"

header-from: main.tf
footer-from: ""

recursive:
  enabled: false

sections:
  hide: []
  show: []

content: ""

output:
  file: README.md
  mode: inject
  template: |-
    <!-- BEGIN_TF_DOCS -->
    {{ .Content }}
    <!-- END_TF_DOCS -->

output-values:
  enabled: false

sort:
  enabled: true
  by: required

settings:
  anchor: true
  color: true
  default: true
  description: true
  escape: true
  hide-empty: false
  html: true
  indent: 2
  lockfile: true
  read-comments: true
  required: true
  sensitive: true
  type: true
```

### Uso
```bash
# Generar docs
terraform-docs markdown table --output-file README.md .

# Verificar que está actualizado
terraform-docs markdown table --output-check .
```

## Comentarios en Código

### Cuándo Documentar
- Lógica de negocio no obvia
- Decisiones de diseño y sus razones
- Workarounds con referencia a issues
- Algoritmos complejos

### Cuándo NO Documentar
- Código auto-explicativo
- Getters/setters triviales
- Comentarios que repiten el código

```python
# ❌ Malo - repite el código
# Incrementar contador
counter += 1

# ✅ Bueno - explica el por qué
# Skip header rows per CSV spec v2.1
counter += 2

# ✅ Bueno - referencia a issue
# Workaround for issue #234: API returns wrong format on Mondays
data = fix_monday_bug(data)
```

## Docstrings por Lenguaje

### Python (Google Style)
```python
def calculate_discount(amount: float, rate: float = 0.1) -> float:
    """Calculate discounted amount.

    Args:
        amount: Original amount before discount.
        rate: Discount rate as decimal (default 10%).

    Returns:
        Final amount after applying discount.

    Raises:
        ValueError: If amount is negative.
    """
```

### Go (GoDoc)
```go
// CalculateDiscount returns the discounted amount.
// It applies the given rate to the original amount.
// Returns an error if amount is negative.
func CalculateDiscount(amount, rate float64) (float64, error) {
```

### TypeScript (TSDoc)
```typescript
/**
 * Calculates the discounted amount.
 * @param amount - Original amount before discount
 * @param rate - Discount rate as decimal (default 0.1)
 * @returns Final amount after applying discount
 * @throws {Error} If amount is negative
 */
function calculateDiscount(amount: number, rate = 0.1): number {
```

## API Documentation (OpenAPI)

```yaml
openapi: 3.0.0
info:
  title: Mi API
  version: 1.0.0

paths:
  /users:
    post:
      summary: Crear usuario
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UserCreate'
      responses:
        '201':
          description: Usuario creado
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          description: Datos inválidos
        '409':
          description: Email ya existe

components:
  schemas:
    UserCreate:
      type: object
      required: [name, email]
      properties:
        name:
          type: string
          minLength: 1
          maxLength: 100
        email:
          type: string
          format: email
    User:
      allOf:
        - $ref: '#/components/schemas/UserCreate'
        - type: object
          properties:
            id:
              type: string
              format: uuid
            created_at:
              type: string
              format: date-time
```

## Anti-Patrones

| Anti-Patrón | Solución |
|-------------|----------|
| README desactualizado | Actualizar con cada cambio relevante |
| Comentarios obsoletos | Actualizar o eliminar |
| TODOs sin owner ni issue | Crear issue o eliminar |
| Docs duplicados | Single source of truth |
