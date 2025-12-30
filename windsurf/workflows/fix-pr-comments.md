---
name: fix-pr-comments
description: Corregir comentarios de revisión de PR
---

# Workflow: Corregir Comentarios de PR

Procesar y corregir comentarios de revisión de manera sistemática.

## 1. Obtener Comentarios

```bash
# Ver PR y comentarios
gh pr view --comments
gh pr view --json reviews -q '.reviews[].body'

# Ver diff del PR
gh pr diff
```

## 2. Clasificar Comentarios

| Tipo | Acción |
|------|--------|
| 🔴 Error de código/bug | Corregir inmediatamente |
| 🟠 Mejora de seguridad | Corregir |
| 🟡 Sugerencia de estilo | Evaluar y aplicar si mejora |
| 🟢 Mejora de docs | Aplicar si es relevante |
| ⚪ Falso positivo | Explicar por qué no aplica |

## 3. Procesar Cada Comentario

### Si es Válido
1. Aplicar la corrección sugerida
2. Ejecutar validaciones del proyecto
3. Hacer commit con referencia al comentario:
   ```bash
   git commit -m "fix: address review comment - descripción"
   ```

### Si es Inválido/Falso Positivo
1. Preparar explicación clara del por qué
2. Incluir referencias a documentación si aplica
3. Sugerir alternativas si existen

## 4. Validar Cambios

```bash
# Formateo
make fmt  # o comando específico del proyecto

# Tests
make test

# Lint
make lint
```

## 5. Resumen de Cambios

```markdown
## Comentarios Procesados

### ✅ Corregidos
- [Línea X] Descripción del fix
- [Línea Y] Descripción del fix

### ❌ No Aplica (con razón)
- [Línea Z] Razón: explicación

### 💬 Requiere Discusión
- [Línea W] Pregunta o alternativas
```

## 6. Push y Notificar

```bash
# Push cambios
git push origin <branch>

# Comentar en PR que se procesaron los comentarios
gh pr comment --body "Comentarios de revisión procesados. Ver commits recientes."
```
