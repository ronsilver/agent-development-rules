# Document

Generar documentación para el código seleccionado o proyecto.

## Tipos de Documentación

### 1. Docstrings/Comentarios

**Cuándo documentar:**
- Lógica de negocio no obvia
- Decisiones de diseño y sus razones
- Workarounds con referencia a issues
- APIs públicas
- Algoritmos complejos

**Cuándo NO documentar:**
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
```

### 2. README

Estructura recomendada:

```markdown
# Nombre del Proyecto

Descripción breve (1-2 oraciones).

## Requisitos

- Dependencias necesarias
- Versiones soportadas

## Instalación

```bash
# Comandos de instalación
```

## Uso

```bash
# Ejemplo de uso básico
```

## Configuración

| Variable | Descripción | Default |
|----------|-------------|----------|
| `VAR` | Descripción | `value` |

## Desarrollo

```bash
# Setup para desarrollo
```

## Licencia

MIT
```

### 3. API Documentation

Para cada endpoint:

```markdown
## POST /api/users

Crear un nuevo usuario.

### Request

```json
{
  "name": "string (required)",
  "email": "string (required, email format)"
}
```

### Response

**201 Created**
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "created_at": "ISO 8601"
}
```

**400 Bad Request**
```json
{
  "error": "validation_error",
  "details": [...]
}
```
```

## Formato por Lenguaje

| Lenguaje | Formato |
|----------|----------|
| Python | Google style docstrings |
| Go | GoDoc comments |
| TypeScript | TSDoc/JSDoc |
| Terraform | terraform-docs |

## Instrucciones

1. Analizar código/proyecto
2. Generar documentación apropiada según contexto
3. Mantener formato consistente con existente
4. Incluir ejemplos prácticos
