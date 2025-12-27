---
name: fix-pr-comments
description: Corregir comentarios de PR
---

# Workflow: Corregir Comentarios de PR

## Pasos

1. **Obtener comentarios**
   ```bash
   gh pr view --comments
   ```

2. **Clasificar**
   - Errores de código
   - Mejoras de documentación
   - Sugerencias de estilo
   - Falsos positivos

3. **Para cada comentario**
   - Verificar si es válido
   - Si es válido → Aplicar corrección
   - Si es inválido → Explicar por qué

4. **Validar cambios**
   - Ejecutar formatters
   - Ejecutar tests

5. **Mostrar resumen**
   - Comentarios corregidos
   - Comentarios ignorados (con razón)

6. **Esperar confirmación** antes de push
