---
trigger: glob
globs: ["*_test.go", "*_test.py", "*.test.ts", "*.test.js", "*.spec.ts", "*.spec.js", "test_*.py", "conftest.py", "pytest.ini", "jest.config.*", "vitest.config.*"]
---

# Testing Best Practices - Excelencia Operativa

## Principios Fundamentales

1. **Tests como documentación** - El test describe el comportamiento esperado
2. **Tests independientes** - Cada test puede ejecutarse en aislamiento
3. **Tests determinísticos** - Mismo input = Mismo resultado, siempre
4. **Tests rápidos** - Feedback loop corto para desarrollo ágil
5. **Tests mantenibles** - Código de test con la misma calidad que producción

## Pirámide de Testing

```
        /\
       /  \     E2E Tests (10%)
      /----\    - Flujos críticos de negocio
     /      \   - Lentos, frágiles
    /--------\  Integration Tests (20%)
   /          \ - APIs, DB, servicios externos
  /------------\Unit Tests (70%)
 /              \- Funciones, clases, módulos
/________________\- Rápidos, aislados
```

## Cobertura OBLIGATORIA

| Tipo de Código | Cobertura Mínima |
|----------------|------------------|
| Lógica de negocio crítica | 90% |
| APIs públicas | 80% |
| Utilidades/helpers | 70% |
| Código general | 60% |

### Qué Cubrir SIEMPRE
- Happy path (flujo exitoso)
- Edge cases (valores límite, vacíos, nulos)
- Error cases (inputs inválidos, excepciones)
- Boundary conditions (0, 1, N, N+1)

## Naming Convention - OBLIGATORIO

### Formato
```
test_<función>_<escenario>_<resultado_esperado>
```

### Ejemplos

```python
# ✅ Correcto - Descriptivo
def test_calculate_discount_with_valid_percentage_returns_discounted_price():
def test_create_user_with_duplicate_email_raises_conflict_error():
def test_process_payment_when_insufficient_funds_returns_failure():

# ❌ Incorrecto - Vago
def test_discount():
def test_user():
def test_payment_works():
```

```typescript
// ✅ Correcto
describe('UserService', () => {
  describe('createUser', () => {
    it('should create user with valid data', () => {});
    it('should throw ConflictError when email already exists', () => {});
    it('should hash password before storing', () => {});
  });
});

// ❌ Incorrecto
describe('tests', () => {
  it('works', () => {});
  it('test 1', () => {});
});
```

```go
// ✅ Correcto
func TestCalculateDiscount_WithValidPercentage_ReturnsDiscountedPrice(t *testing.T) {}
func TestCreateUser_WithDuplicateEmail_ReturnsConflictError(t *testing.T) {}

// ❌ Incorrecto
func TestDiscount(t *testing.T) {}
func Test1(t *testing.T) {}
```

## Estructura AAA - OBLIGATORIO

```python
def test_transfer_money_with_sufficient_balance_transfers_amount():
    # Arrange - Preparar datos y dependencias
    source_account = Account(balance=1000)
    target_account = Account(balance=500)
    transfer_service = TransferService()
    
    # Act - Ejecutar la acción a testear
    result = transfer_service.transfer(source_account, target_account, amount=200)
    
    # Assert - Verificar resultados
    assert result.success is True
    assert source_account.balance == 800
    assert target_account.balance == 700
```

## Unit Tests

### Principios
- Testear UNA cosa por test
- Sin I/O (DB, filesystem, network)
- Usar mocks/stubs para dependencias externas
- Ejecutar en < 100ms

```python
# ✅ Correcto - Aislado con mock
def test_send_notification_calls_email_service(mocker):
    mock_email = mocker.patch('services.email.send')
    notification_service = NotificationService(email_service=mock_email)
    
    notification_service.notify_user(user_id=123, message="Hello")
    
    mock_email.assert_called_once_with(
        to="user@example.com",
        subject="Notification",
        body="Hello"
    )

# ❌ Incorrecto - Dependencia real
def test_send_notification():
    service = NotificationService()  # Usa email real
    service.notify_user(123, "Hello")  # Envía email de verdad!
```

### Qué Mockear
- Bases de datos
- APIs externas
- Filesystem
- Tiempo (datetime.now)
- Generadores random

### Qué NO Mockear
- La unidad bajo test
- Value objects simples
- Funciones puras sin side effects

## Integration Tests

### Principios
- Testear interacción entre componentes
- Usar bases de datos de test (containers)
- Limpiar estado entre tests
- Ejecutar en < 5 segundos

```python
# ✅ Correcto - DB real en container
@pytest.fixture
def db_session():
    engine = create_engine("postgresql://test:test@localhost:5432/test")
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.rollback()
    session.close()

def test_create_user_persists_to_database(db_session):
    user_repo = UserRepository(db_session)
    
    user = user_repo.create(name="John", email="john@example.com")
    
    found = user_repo.find_by_id(user.id)
    assert found.name == "John"
    assert found.email == "john@example.com"
```

```typescript
// ✅ API Integration test
describe('POST /api/users', () => {
  beforeEach(async () => {
    await db.clear();
  });

  it('should create user and return 201', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: 'John', email: 'john@test.com' })
      .expect(201);

    expect(response.body).toMatchObject({
      name: 'John',
      email: 'john@test.com',
    });
  });
});
```

## E2E Tests

### Principios
- Solo flujos críticos de negocio
- Ambiente lo más cercano a producción
- Tests estables (no flaky)
- Ejecutar en CI, no localmente siempre

```typescript
// ✅ Playwright E2E
test('user can complete checkout flow', async ({ page }) => {
  // Login
  await page.goto('/login');
  await page.fill('[data-testid="email"]', 'user@test.com');
  await page.fill('[data-testid="password"]', 'password123');
  await page.click('[data-testid="login-button"]');
  
  // Add to cart
  await page.goto('/products/1');
  await page.click('[data-testid="add-to-cart"]');
  
  // Checkout
  await page.goto('/checkout');
  await page.fill('[data-testid="card-number"]', '4242424242424242');
  await page.click('[data-testid="pay-button"]');
  
  // Verify
  await expect(page.locator('[data-testid="success-message"]')).toBeVisible();
});
```

## Test Data

### Factories/Builders
```python
# ✅ Usar factories para datos de test
@dataclass
class UserFactory:
    @staticmethod
    def create(
        name: str = "Test User",
        email: str = "test@example.com",
        role: str = "user",
        **overrides
    ) -> User:
        return User(
            id=uuid4(),
            name=name,
            email=email,
            role=role,
            created_at=datetime.utcnow(),
            **overrides
        )

# Uso
def test_admin_can_delete_users():
    admin = UserFactory.create(role="admin")
    user = UserFactory.create(role="user")
    # ...
```

### Fixtures Reutilizables
```python
# conftest.py
@pytest.fixture
def authenticated_user(db_session):
    user = UserFactory.create()
    db_session.add(user)
    db_session.commit()
    return user

@pytest.fixture
def api_client(authenticated_user):
    client = TestClient(app)
    client.headers["Authorization"] = f"Bearer {generate_token(authenticated_user)}"
    return client
```

## Anti-Patrones a EVITAR

| Anti-Patrón | Problema | Solución |
|-------------|----------|----------|
| Tests interdependientes | Orden de ejecución importa | Cada test independiente |
| Sleep/delays hardcodeados | Tests lentos y flaky | Usar polling/waitFor |
| Asserts múltiples sin relación | No sabes qué falló | Un concepto por test |
| Datos de test compartidos | Tests se afectan entre sí | Fixtures aisladas |
| Mockear todo | No testea integración real | Mock solo lo necesario |
| Tests sin assertions | Test siempre pasa | Mínimo 1 assert por test |
| Ignorar tests flaky | Pierden confianza | Arreglar o eliminar |
| Copy-paste de tests | Difícil mantener | Parametrizar |

## Tests Parametrizados

```python
# ✅ Parametrizar casos similares
@pytest.mark.parametrize("input_value,expected", [
    (0, 0),
    (1, 1),
    (5, 120),
    (10, 3628800),
])
def test_factorial_returns_correct_value(input_value, expected):
    assert factorial(input_value) == expected

@pytest.mark.parametrize("invalid_input", [-1, -5, -100])
def test_factorial_raises_error_for_negative_numbers(invalid_input):
    with pytest.raises(ValueError):
        factorial(invalid_input)
```

```typescript
// ✅ Jest parametrizado
describe.each([
  [0, 0],
  [1, 1],
  [5, 120],
  [10, 3628800],
])('factorial(%i)', (input, expected) => {
  it(`should return ${expected}`, () => {
    expect(factorial(input)).toBe(expected);
  });
});
```

## Comandos de Ejecución

```bash
# Python
pytest tests/ -v                           # Verbose
pytest tests/ -x                           # Stop on first failure
pytest tests/ -k "test_user"               # Filter by name
pytest tests/ --cov=src --cov-report=html  # Coverage

# Node.js (Jest/Vitest)
npm test                                   # Run all
npm test -- --watch                        # Watch mode
npm test -- --coverage                     # Coverage
npm test -- -t "user"                      # Filter by name

# Go
go test ./... -v                           # Verbose
go test ./... -cover                       # Coverage
go test ./... -race                        # Race detector
go test ./... -run TestUser                # Filter
```

## CI/CD Integration

```yaml
# GitHub Actions
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    
    - name: Run unit tests
      run: pytest tests/unit -v --cov=src
    
    - name: Run integration tests
      run: pytest tests/integration -v
      env:
        DATABASE_URL: postgresql://test:test@localhost:5432/test
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3

    - name: Fail if coverage below threshold
      run: |
        coverage=$(pytest --cov=src --cov-fail-under=70)
```

## Checklist Pre-Merge

- [ ] Tests pasan localmente
- [ ] Cobertura no disminuyó
- [ ] Tests nuevos para código nuevo
- [ ] Tests de regresión para bugs corregidos
- [ ] No hay tests ignorados/skipped sin justificación
- [ ] Tests ejecutan en < 5 minutos en CI
