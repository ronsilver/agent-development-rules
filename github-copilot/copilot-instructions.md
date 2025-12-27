# GitHub Copilot - Global Instructions

## Principios

1. **Verifica antes de afirmar** - No decir que algo no es posible sin verificar documentación
2. **Simplicidad** - La solución más simple que funcione
3. **Performance** - Considerar rendimiento y escalabilidad
4. **Consistencia** - Seguir patrones existentes en el código

## Código

- Máximo 300 líneas por archivo
- Máximo 50 líneas por función
- Una responsabilidad por función/módulo
- Nombres descriptivos para variables y funciones

## Seguridad

- No hardcodear secrets, API keys, passwords
- Usar variables de entorno para configuración sensible
- Validar inputs del usuario

## Testing

- Escribir tests para funcionalidad nueva
- Mantener tests existentes funcionando

## Documentación

- Documentar el "por qué", no el "qué"
- Agregar comentarios solo cuando aporten valor
