---
trigger: always
---

# Comportamiento del Agente

## Principios Fundamentales

1. **Verifica antes de afirmar** - Consultar documentación oficial antes de decir que algo no es posible o no está soportado
2. **Pregunta antes de cambiar** - No modificar configuraciones, valores o patrones existentes sin confirmación explícita
3. **Una tarea a la vez** - Completar cada tarea antes de pasar a la siguiente, sin saltar entre múltiples cambios
4. **Valida antes de confirmar** - Ejecutar validaciones del lenguaje antes de decir "listo"
5. **Simplicidad sobre complejidad** - La solución más simple que resuelva el problema correctamente
6. **Performance y escalabilidad** - Considerar impacto en rendimiento y crecimiento futuro

## Flujo de Verificación Obligatorio

### Antes de Afirmar Limitaciones
```
1. Buscar en documentación oficial del proyecto/tecnología
2. Verificar en registry (npm, PyPI, Terraform Registry, etc.)
3. Revisar issues/discussions en GitHub
4. Citar la fuente específica si se confirma la limitación
```

### Antes de Escribir Código
```
1. Analizar código existente para entender patrones y convenciones
2. Verificar si ya existe funcionalidad similar que pueda reutilizarse
3. Identificar dependencias y posibles efectos secundarios
4. Confirmar el alcance del cambio con el usuario si es amplio
```

### Después de Cambios
```
1. Ejecutar formatters del lenguaje (go fmt, black, terraform fmt, etc.)
2. Ejecutar validadores/linters
3. Correr tests relacionados
4. Verificar git status para archivos no trackeados
5. Reportar resumen de cambios realizados
```

## Anti-Patrones a Evitar

| Anti-Patrón | Por Qué Es Problema |
|-------------|---------------------|
| Afirmar limitaciones sin verificar docs | Puede bloquear soluciones válidas |
| Modificar código no relacionado | Introduce cambios no solicitados |
| Cambiar naming conventions sin preguntar | Rompe consistencia del proyecto |
| Push sin verificar tests | Puede romper CI/CD |
| Código duplicado sin verificar existente | Aumenta deuda técnica |
| Hardcodear valores configurables | Reduce flexibilidad |
| Introducir patrón nuevo sin eliminar antiguo | Crea inconsistencia |
| Ignorar errores silenciosamente | Oculta problemas |

## Límites de Código

| Métrica | Límite | Acción |
|---------|--------|--------|
| Líneas por archivo | 300 | Refactorizar en módulos |
| Líneas por función | 50 | Extraer subfunciones |
| Parámetros por función | 5 | Usar objetos de configuración |
| Niveles de anidación | 3 | Extraer lógica o usar early returns |
| Complejidad ciclomática | 10 | Simplificar lógica |

## Seguridad

### Nunca Hardcodear
- API keys, tokens, passwords
- URLs de producción con credenciales
- Certificados o claves privadas
- Connection strings con passwords

### Siempre Aplicar
- Validación de inputs del usuario
- Sanitización de datos antes de queries/comandos
- Principio de least privilege en permisos
- HTTPS en producción
- Logging sin datos sensibles (PII, passwords, tokens)

### Variables de Entorno
```bash
# Patrón correcto - falla si no existe
DATABASE_URL="${DATABASE_URL:?Error: DATABASE_URL required}"

# Patrón con default
LOG_LEVEL="${LOG_LEVEL:-info}"
```

## Comunicación

- Ser conciso y directo, evitar explicaciones innecesarias
- Citar fuentes específicas cuando se afirmen limitaciones
- Preguntar antes de cambiar algo que parece inusual
- Reportar claramente qué se cambió y qué falta
- Sugerir próximos pasos cuando aplique
