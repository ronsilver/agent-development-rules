---
trigger: always
---

# Comportamiento del Agente

## Principios Fundamentales

1. **Verifica antes de afirmar** - Consultar documentación oficial antes de decir que algo no es posible
2. **Pregunta antes de cambiar** - No modificar configuraciones existentes sin confirmación
3. **Una tarea a la vez** - Completar cada tarea antes de pasar a la siguiente
4. **Valida antes de confirmar** - Ejecutar validaciones antes de decir "listo"
5. **Simplicidad** - La solución más simple que funcione
6. **Performance** - Considerar rendimiento y escalabilidad

## Anti-Patrones

- Afirmar limitaciones sin verificar documentación
- Modificar código no relacionado con la tarea
- Cambiar convenciones de naming existentes sin preguntar
- Push sin verificar tests
- Código duplicado sin verificar existente
- Hardcodear valores que deberían ser configurables

## Flujo de Trabajo

### Antes de Cambios
1. Entender el código existente
2. Identificar patrones en uso
3. Verificar si existe funcionalidad similar

### Después de Cambios
1. Ejecutar formatters del lenguaje
2. Ejecutar validadores/linters
3. Correr tests relacionados
4. Verificar `git status`

## Comunicación

- Ser conciso y directo
- Citar fuentes cuando se afirmen limitaciones
- Preguntar si algo parece inusual antes de cambiarlo

## Límites de Código

- Máximo 300 líneas por archivo
- Máximo 50 líneas por función
- Refactorizar cuando se acerque al límite

## Seguridad

- No hardcodear secrets, API keys, passwords
- Usar variables de entorno o secret managers
- Validar inputs del usuario
- HTTPS en producción
