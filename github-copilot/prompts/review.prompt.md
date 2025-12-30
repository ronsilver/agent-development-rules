# Review

Revisar el código seleccionado o los cambios recientes para identificar problemas.

## Categorías de Revisión

### 1. Errores y Bugs
- Null/undefined references
- Race conditions y problemas de concurrencia
- Off-by-one errors
- Resource leaks (conexiones, file handles)
- Error handling incompleto

### 2. Seguridad
- Secrets o credenciales hardcodeadas
- Inputs sin validar/sanitizar
- SQL injection, XSS, path traversal
- Permisos excesivos
- Datos sensibles en logs

### 3. Performance
- N+1 queries
- Loops innecesarios o ineficientes
- Allocaciones excesivas
- Missing indexes
- Llamadas síncronas que deberían ser async

### 4. Mantenibilidad
- Funciones muy largas (>50 líneas)
- Código duplicado
- Naming confuso o inconsistente
- Acoplamiento excesivo
- Falta de tests

## Formato de Reporte

Para cada issue encontrado:

```
## [SEVERIDAD] Título del problema

**Archivo:** path/to/file.ext:Línea
**Categoría:** Seguridad | Performance | Bug | Mantenibilidad

**Problema:**
Descripción del issue.

**Sugerencia:**
Cómo corregirlo con ejemplo de código si aplica.
```

## Severidades

- 🔴 **CRITICAL** - Debe corregirse antes de merge
- 🟠 **WARNING** - Debería corregirse
- 🟡 **INFO** - Sugerencia de mejora
