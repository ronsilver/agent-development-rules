# Refactor

Refactorizar el código seleccionado manteniendo el comportamiento existente.

## Objetivos de Refactoring

### 1. Reducir Complejidad
- Extraer funciones de métodos largos (>50 líneas)
- Simplificar condicionales anidados (>3 niveles)
- Usar early returns para reducir indentación
- Eliminar código muerto

### 2. Mejorar Legibilidad
- Nombres descriptivos para variables y funciones
- Constantes con nombres en lugar de magic numbers
- Extraer expresiones complejas a variables con nombre
- Ordenar métodos por nivel de abstracción

### 3. Eliminar Duplicación
- Identificar patrones repetidos
- Extraer a funciones/métodos compartidos
- Usar composición sobre herencia cuando aplique

### 4. Principios SOLID
- **S**ingle Responsibility: Una razón para cambiar
- **O**pen/Closed: Abierto a extensión, cerrado a modificación
- **L**iskov Substitution: Subtipos intercambiables
- **I**nterface Segregation: Interfaces pequeñas y específicas
- **D**ependency Inversion: Depender de abstracciones

## Restricciones

- ✅ Mantener comportamiento existente (mismos inputs → mismos outputs)
- ✅ Tests existentes deben seguir pasando
- ✅ Mantener API pública sin cambios
- ❌ No agregar nuevas dependencias sin justificación
- ❌ No cambiar firmas de funciones públicas

## Proceso

1. Identificar code smells
2. Proponer cambios específicos
3. Aplicar cambios incrementales
4. Verificar que tests pasan después de cada cambio

## Code Smells Comunes

| Smell | Solución |
|-------|----------|
| Función larga | Extract Method |
| Clase grande | Extract Class |
| Parámetros excesivos | Parameter Object |
| Código duplicado | Extract Method/Class |
| Switch repetido | Polymorphism |
| Feature envy | Move Method |
