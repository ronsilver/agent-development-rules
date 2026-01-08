# Test

Generar tests completos para el código seleccionado.

## Cobertura Requerida

### 1. Happy Path
- Flujo normal con inputs válidos
- Casos de uso principales
- Verificar outputs esperados

### 2. Edge Cases
- Valores límite (0, -1, MAX_INT)
- Strings vacíos, arrays vacíos
- Valores nulos/undefined
- Unicode y caracteres especiales
- Concurrencia (si aplica)

### 3. Error Cases
- Inputs inválidos (tipos incorrectos)
- Errores de validación
- Excepciones esperadas
- Timeouts y errores de red (si aplica)

## Frameworks por Lenguaje

| Lenguaje | Framework | Comando |
|----------|-----------|----------|
| Go | testing + testify | `go test ./... -v` |
| Python | pytest | `pytest -v` |
| TypeScript | vitest/jest | `npm test` |
| Terraform | terraform test | `terraform test` |

## Estructura de Test

### Naming Convention
```
test_<función>_<escenario>_<resultado_esperado>

Ejemplos:
test_create_user_valid_input_returns_user
test_create_user_empty_name_raises_validation_error
test_calculate_discount_zero_amount_returns_zero
```

### Patrón AAA (Arrange-Act-Assert)
```python
def test_calculate_discount_premium_user():
    # Arrange
    user = User(tier="premium")
    amount = 100.0

    # Act
    result = calculate_discount(user, amount)

    # Assert
    assert result == 90.0  # 10% descuento
```

## Instrucciones

1. Detectar framework de testing del proyecto
2. Generar tests siguiendo patrones existentes
3. Incluir setup/teardown si es necesario
4. Usar mocks solo cuando sea imprescindible
5. Cada test debe ser independiente y reproducible
