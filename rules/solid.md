---
trigger: glob
globs: ["*.py", "*.js", "*.ts", "*.go", "*.java", "*.cs", "*.rb"]
---

# SOLID Principles - Best Practices

Principios de diseño orientado a objetos para código mantenible, extensible y testeable.

## Resumen SOLID

| Principio | Descripción | Beneficio |
|-----------|-------------|-----------|
| **S** - Single Responsibility | Una clase = una razón para cambiar | Mantenibilidad |
| **O** - Open/Closed | Abierto a extensión, cerrado a modificación | Extensibilidad |
| **L** - Liskov Substitution | Subtipos sustituibles por su tipo base | Correctitud |
| **I** - Interface Segregation | Interfaces pequeñas y específicas | Flexibilidad |
| **D** - Dependency Inversion | Depender de abstracciones, no implementaciones | Testabilidad |

---

## S - Single Responsibility Principle (SRP)

> **"Una clase debe tener una, y solo una, razón para cambiar."**

### Señales de Violación
- Clase con múltiples responsabilidades no relacionadas
- Métodos que hacen cosas completamente diferentes
- Clase difícil de nombrar sin usar "And" o "Manager"
- Cambios en un área requieren modificar código no relacionado

### Ejemplo

```python
# ❌ Viola SRP - Múltiples responsabilidades
class UserService:
    def create_user(self, data: dict) -> User:
        # Validación
        if not data.get('email'):
            raise ValueError("Email required")
        
        # Persistencia
        user = User(**data)
        self.db.save(user)
        
        # Notificación
        self.send_welcome_email(user)
        
        # Logging
        self.log_user_creation(user)
        
        return user
    
    def send_welcome_email(self, user: User):
        # Lógica de email...
        pass
    
    def log_user_creation(self, user: User):
        # Lógica de logging...
        pass

# ✅ Cumple SRP - Responsabilidades separadas
class UserValidator:
    def validate(self, data: dict) -> None:
        if not data.get('email'):
            raise ValueError("Email required")
        if not self._is_valid_email(data['email']):
            raise ValueError("Invalid email format")

class UserRepository:
    def __init__(self, db: Database):
        self.db = db
    
    def save(self, user: User) -> User:
        return self.db.save(user)
    
    def find_by_id(self, user_id: int) -> User | None:
        return self.db.find(User, user_id)

class UserNotificationService:
    def __init__(self, email_client: EmailClient):
        self.email_client = email_client
    
    def send_welcome_email(self, user: User) -> None:
        self.email_client.send(
            to=user.email,
            template="welcome",
            context={"name": user.name}
        )

class UserService:
    def __init__(
        self,
        validator: UserValidator,
        repository: UserRepository,
        notification: UserNotificationService,
    ):
        self.validator = validator
        self.repository = repository
        self.notification = notification
    
    def create_user(self, data: dict) -> User:
        self.validator.validate(data)
        user = User(**data)
        saved_user = self.repository.save(user)
        self.notification.send_welcome_email(saved_user)
        return saved_user
```

```typescript
// ✅ TypeScript - SRP
class OrderValidator {
  validate(order: Order): ValidationResult {
    const errors: string[] = [];
    if (order.items.length === 0) {
      errors.push('Order must have at least one item');
    }
    if (order.total <= 0) {
      errors.push('Order total must be positive');
    }
    return { valid: errors.length === 0, errors };
  }
}

class OrderRepository {
  constructor(private db: Database) {}
  
  async save(order: Order): Promise<Order> {
    return this.db.orders.create(order);
  }
}

class OrderNotifier {
  constructor(private emailService: EmailService) {}
  
  async notifyOrderCreated(order: Order): Promise<void> {
    await this.emailService.send({
      to: order.customer.email,
      subject: 'Order Confirmation',
      body: `Your order #${order.id} has been placed.`,
    });
  }
}
```

### Checklist SRP
- [ ] ¿La clase tiene una única responsabilidad clara?
- [ ] ¿Puedo describir la clase sin usar "y"?
- [ ] ¿Cambios en un área no afectan otras áreas de la clase?
- [ ] ¿La clase tiene un nombre específico y descriptivo?

---

## O - Open/Closed Principle (OCP)

> **"Las entidades de software deben estar abiertas para extensión, pero cerradas para modificación."**

### Señales de Violación
- Agregar funcionalidad requiere modificar código existente
- Múltiples if/switch para manejar diferentes tipos
- Cambios frecuentes en clases estables

### Ejemplo

```python
# ❌ Viola OCP - Requiere modificar para cada nuevo tipo
class PaymentProcessor:
    def process(self, payment: Payment) -> Result:
        if payment.type == "credit_card":
            return self._process_credit_card(payment)
        elif payment.type == "paypal":
            return self._process_paypal(payment)
        elif payment.type == "crypto":  # Cada nuevo tipo requiere modificar
            return self._process_crypto(payment)
        else:
            raise ValueError(f"Unknown payment type: {payment.type}")

# ✅ Cumple OCP - Extensible sin modificar
from abc import ABC, abstractmethod

class PaymentMethod(ABC):
    @abstractmethod
    def process(self, amount: float) -> Result:
        pass

class CreditCardPayment(PaymentMethod):
    def __init__(self, card_number: str, cvv: str):
        self.card_number = card_number
        self.cvv = cvv
    
    def process(self, amount: float) -> Result:
        # Lógica específica de tarjeta de crédito
        return gateway.charge(self.card_number, amount)

class PayPalPayment(PaymentMethod):
    def __init__(self, email: str):
        self.email = email
    
    def process(self, amount: float) -> Result:
        # Lógica específica de PayPal
        return paypal.charge(self.email, amount)

# Agregar nuevo método NO requiere modificar código existente
class CryptoPayment(PaymentMethod):
    def __init__(self, wallet_address: str):
        self.wallet_address = wallet_address
    
    def process(self, amount: float) -> Result:
        return crypto_gateway.transfer(self.wallet_address, amount)

class PaymentProcessor:
    def process(self, payment_method: PaymentMethod, amount: float) -> Result:
        return payment_method.process(amount)
```

```typescript
// ✅ TypeScript - OCP con Strategy Pattern
interface DiscountStrategy {
  calculate(price: number): number;
}

class NoDiscount implements DiscountStrategy {
  calculate(price: number): number {
    return price;
  }
}

class PercentageDiscount implements DiscountStrategy {
  constructor(private percentage: number) {}
  
  calculate(price: number): number {
    return price * (1 - this.percentage / 100);
  }
}

class FixedDiscount implements DiscountStrategy {
  constructor(private amount: number) {}
  
  calculate(price: number): number {
    return Math.max(0, price - this.amount);
  }
}

// Agregar nuevo descuento NO modifica PriceCalculator
class BuyOneGetOneFree implements DiscountStrategy {
  calculate(price: number): number {
    return price / 2;
  }
}

class PriceCalculator {
  constructor(private discountStrategy: DiscountStrategy) {}
  
  calculateFinalPrice(basePrice: number): number {
    return this.discountStrategy.calculate(basePrice);
  }
}
```

```go
// ✅ Go - OCP con interfaces
type Notifier interface {
    Send(message string) error
}

type EmailNotifier struct {
    client EmailClient
}

func (n *EmailNotifier) Send(message string) error {
    return n.client.Send(message)
}

type SMSNotifier struct {
    client SMSClient
}

func (n *SMSNotifier) Send(message string) error {
    return n.client.Send(message)
}

// Agregar SlackNotifier NO requiere modificar NotificationService
type SlackNotifier struct {
    webhook string
}

func (n *SlackNotifier) Send(message string) error {
    // implementación
    return nil
}

type NotificationService struct {
    notifiers []Notifier
}

func (s *NotificationService) NotifyAll(message string) error {
    for _, n := range s.notifiers {
        if err := n.Send(message); err != nil {
            return err
        }
    }
    return nil
}
```

### Patrones para OCP
- **Strategy Pattern** - Algoritmos intercambiables
- **Template Method** - Estructura fija, pasos variables
- **Decorator Pattern** - Agregar comportamiento dinámicamente
- **Factory Pattern** - Creación extensible de objetos

---

## L - Liskov Substitution Principle (LSP)

> **"Los objetos de una superclase deben poder ser reemplazados por objetos de sus subclases sin alterar la correctitud del programa."**

### Señales de Violación
- Subclase lanza excepciones que la superclase no lanza
- Subclase ignora o sobreescribe comportamiento de forma incompatible
- Código cliente necesita verificar el tipo concreto
- Métodos vacíos o que lanzan `NotImplementedError`

### Ejemplo

```python
# ❌ Viola LSP - Rectangle/Square problem clásico
class Rectangle:
    def __init__(self, width: int, height: int):
        self._width = width
        self._height = height
    
    def set_width(self, width: int):
        self._width = width
    
    def set_height(self, height: int):
        self._height = height
    
    def area(self) -> int:
        return self._width * self._height

class Square(Rectangle):
    def set_width(self, width: int):
        self._width = width
        self._height = width  # Viola expectativa de Rectangle
    
    def set_height(self, height: int):
        self._width = height
        self._height = height

# Este código falla con Square pero funciona con Rectangle
def test_rectangle(rect: Rectangle):
    rect.set_width(5)
    rect.set_height(4)
    assert rect.area() == 20  # Falla con Square!

# ✅ Cumple LSP - Diseño correcto
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self) -> float:
        pass

class Rectangle(Shape):
    def __init__(self, width: float, height: float):
        self.width = width
        self.height = height
    
    def area(self) -> float:
        return self.width * self.height

class Square(Shape):
    def __init__(self, side: float):
        self.side = side
    
    def area(self) -> float:
        return self.side * self.side

# Cualquier Shape funciona correctamente
def print_area(shape: Shape):
    print(f"Area: {shape.area()}")
```

```python
# ❌ Viola LSP - Subclase con comportamiento incompatible
class Bird:
    def fly(self) -> str:
        return "Flying high!"

class Penguin(Bird):
    def fly(self) -> str:
        raise NotImplementedError("Penguins can't fly!")  # Viola LSP

# ✅ Cumple LSP - Jerarquía correcta
class Bird(ABC):
    @abstractmethod
    def move(self) -> str:
        pass

class FlyingBird(Bird):
    def move(self) -> str:
        return "Flying!"

class SwimmingBird(Bird):
    def move(self) -> str:
        return "Swimming!"

class Eagle(FlyingBird):
    pass

class Penguin(SwimmingBird):
    pass
```

### Reglas LSP
1. **Precondiciones** - Subclase no puede fortalecer precondiciones
2. **Postcondiciones** - Subclase no puede debilitar postcondiciones
3. **Invariantes** - Subclase debe mantener invariantes de la superclase
4. **Excepciones** - Subclase no puede lanzar excepciones nuevas no esperadas

---

## I - Interface Segregation Principle (ISP)

> **"Los clientes no deben verse forzados a depender de interfaces que no utilizan."**

### Señales de Violación
- Interfaces "gordas" con muchos métodos
- Clases que implementan métodos vacíos o lanzan excepciones
- Cambios en interfaz afectan a clientes que no usan esos métodos

### Ejemplo

```python
# ❌ Viola ISP - Interfaz "gorda"
from abc import ABC, abstractmethod

class Worker(ABC):
    @abstractmethod
    def work(self): pass
    
    @abstractmethod
    def eat(self): pass
    
    @abstractmethod
    def sleep(self): pass
    
    @abstractmethod
    def receive_payment(self): pass

class Robot(Worker):
    def work(self):
        return "Working..."
    
    def eat(self):
        pass  # Robots no comen - viola ISP
    
    def sleep(self):
        pass  # Robots no duermen - viola ISP
    
    def receive_payment(self):
        pass  # Robots no cobran - viola ISP

# ✅ Cumple ISP - Interfaces segregadas
class Workable(ABC):
    @abstractmethod
    def work(self) -> str: pass

class Eatable(ABC):
    @abstractmethod
    def eat(self) -> str: pass

class Sleepable(ABC):
    @abstractmethod
    def sleep(self) -> str: pass

class Payable(ABC):
    @abstractmethod
    def receive_payment(self, amount: float) -> None: pass

class Human(Workable, Eatable, Sleepable, Payable):
    def work(self) -> str:
        return "Working..."
    
    def eat(self) -> str:
        return "Eating lunch..."
    
    def sleep(self) -> str:
        return "Sleeping..."
    
    def receive_payment(self, amount: float) -> None:
        self.balance += amount

class Robot(Workable):
    def work(self) -> str:
        return "Working efficiently..."
```

```typescript
// ❌ Viola ISP
interface CRUDRepository<T> {
  create(entity: T): Promise<T>;
  read(id: string): Promise<T | null>;
  update(id: string, entity: T): Promise<T>;
  delete(id: string): Promise<void>;
  bulkCreate(entities: T[]): Promise<T[]>;
  bulkDelete(ids: string[]): Promise<void>;
  search(query: SearchQuery): Promise<T[]>;
  aggregate(pipeline: AggregationPipeline): Promise<AggregationResult>;
}

// Clase que solo necesita leer debe implementar todo

// ✅ Cumple ISP - Interfaces específicas
interface Readable<T> {
  read(id: string): Promise<T | null>;
}

interface Writable<T> {
  create(entity: T): Promise<T>;
  update(id: string, entity: T): Promise<T>;
}

interface Deletable {
  delete(id: string): Promise<void>;
}

interface Searchable<T> {
  search(query: SearchQuery): Promise<T[]>;
}

interface BulkOperations<T> {
  bulkCreate(entities: T[]): Promise<T[]>;
  bulkDelete(ids: string[]): Promise<void>;
}

// Implementar solo lo necesario
class ReadOnlyUserRepository implements Readable<User>, Searchable<User> {
  async read(id: string): Promise<User | null> { /* ... */ }
  async search(query: SearchQuery): Promise<User[]> { /* ... */ }
}

class FullUserRepository 
  implements Readable<User>, Writable<User>, Deletable, Searchable<User> {
  // Implementa solo las interfaces que necesita
}
```

```go
// ✅ Go - ISP natural con interfaces pequeñas
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

type Closer interface {
    Close() error
}

// Composición de interfaces
type ReadWriter interface {
    Reader
    Writer
}

type ReadWriteCloser interface {
    Reader
    Writer
    Closer
}

// Funciones aceptan la interfaz mínima necesaria
func ProcessData(r Reader) error {
    // Solo necesita leer
    data, err := io.ReadAll(r)
    // ...
}

func SaveData(w Writer, data []byte) error {
    // Solo necesita escribir
    _, err := w.Write(data)
    return err
}
```

---

## D - Dependency Inversion Principle (DIP)

> **"Los módulos de alto nivel no deben depender de módulos de bajo nivel. Ambos deben depender de abstracciones."**

### Señales de Violación
- Instanciación directa de dependencias con `new` o constructores
- Imports de implementaciones concretas en módulos de alto nivel
- Difícil de testear por dependencias hardcodeadas
- Cambiar una implementación requiere modificar muchas clases

### Ejemplo

```python
# ❌ Viola DIP - Dependencia de implementación concreta
class MySQLDatabase:
    def query(self, sql: str) -> list:
        # Implementación MySQL específica
        pass

class UserService:
    def __init__(self):
        self.db = MySQLDatabase()  # Dependencia directa
    
    def get_users(self) -> list[User]:
        return self.db.query("SELECT * FROM users")

# ✅ Cumple DIP - Depende de abstracción
from abc import ABC, abstractmethod

class Database(ABC):
    @abstractmethod
    def query(self, sql: str) -> list:
        pass
    
    @abstractmethod
    def execute(self, sql: str, params: tuple) -> None:
        pass

class MySQLDatabase(Database):
    def query(self, sql: str) -> list:
        # Implementación MySQL
        pass
    
    def execute(self, sql: str, params: tuple) -> None:
        # Implementación MySQL
        pass

class PostgreSQLDatabase(Database):
    def query(self, sql: str) -> list:
        # Implementación PostgreSQL
        pass
    
    def execute(self, sql: str, params: tuple) -> None:
        # Implementación PostgreSQL
        pass

class UserService:
    def __init__(self, db: Database):  # Depende de abstracción
        self.db = db
    
    def get_users(self) -> list[User]:
        return self.db.query("SELECT * FROM users")

# Inyección de dependencia
mysql_db = MySQLDatabase()
user_service = UserService(mysql_db)

# Fácil de testear con mock
class MockDatabase(Database):
    def query(self, sql: str) -> list:
        return [{"id": 1, "name": "Test User"}]
    
    def execute(self, sql: str, params: tuple) -> None:
        pass

def test_get_users():
    mock_db = MockDatabase()
    service = UserService(mock_db)
    users = service.get_users()
    assert len(users) == 1
```

```typescript
// ✅ TypeScript - DIP con Dependency Injection
interface Logger {
  log(message: string): void;
  error(message: string, error?: Error): void;
}

interface HttpClient {
  get<T>(url: string): Promise<T>;
  post<T>(url: string, data: unknown): Promise<T>;
}

// Implementaciones concretas
class ConsoleLogger implements Logger {
  log(message: string): void {
    console.log(`[INFO] ${message}`);
  }
  
  error(message: string, error?: Error): void {
    console.error(`[ERROR] ${message}`, error);
  }
}

class AxiosHttpClient implements HttpClient {
  async get<T>(url: string): Promise<T> {
    const response = await axios.get(url);
    return response.data;
  }
  
  async post<T>(url: string, data: unknown): Promise<T> {
    const response = await axios.post(url, data);
    return response.data;
  }
}

// Servicio de alto nivel depende de abstracciones
class UserApiService {
  constructor(
    private httpClient: HttpClient,
    private logger: Logger,
  ) {}
  
  async getUser(id: string): Promise<User> {
    this.logger.log(`Fetching user ${id}`);
    try {
      return await this.httpClient.get<User>(`/api/users/${id}`);
    } catch (error) {
      this.logger.error(`Failed to fetch user ${id}`, error as Error);
      throw error;
    }
  }
}

// Composición en el punto de entrada
const logger = new ConsoleLogger();
const httpClient = new AxiosHttpClient();
const userService = new UserApiService(httpClient, logger);

// Test con mocks
class MockHttpClient implements HttpClient {
  async get<T>(url: string): Promise<T> {
    return { id: '1', name: 'Test' } as T;
  }
  async post<T>(url: string, data: unknown): Promise<T> {
    return data as T;
  }
}

const testService = new UserApiService(new MockHttpClient(), new ConsoleLogger());
```

```go
// ✅ Go - DIP
type UserRepository interface {
    FindByID(id string) (*User, error)
    Save(user *User) error
}

type EmailSender interface {
    Send(to, subject, body string) error
}

// Implementación concreta
type PostgresUserRepository struct {
    db *sql.DB
}

func (r *PostgresUserRepository) FindByID(id string) (*User, error) {
    // Implementación
    return nil, nil
}

func (r *PostgresUserRepository) Save(user *User) error {
    // Implementación
    return nil
}

// Servicio depende de interfaces
type UserService struct {
    repo   UserRepository
    mailer EmailSender
}

func NewUserService(repo UserRepository, mailer EmailSender) *UserService {
    return &UserService{repo: repo, mailer: mailer}
}

func (s *UserService) CreateUser(data CreateUserInput) (*User, error) {
    user := &User{Name: data.Name, Email: data.Email}
    if err := s.repo.Save(user); err != nil {
        return nil, err
    }
    s.mailer.Send(user.Email, "Welcome!", "Welcome to our platform!")
    return user, nil
}
```

### Dependency Injection Containers

```python
# Python - usando dependency-injector
from dependency_injector import containers, providers

class Container(containers.DeclarativeContainer):
    config = providers.Configuration()
    
    database = providers.Singleton(
        PostgreSQLDatabase,
        host=config.db.host,
        port=config.db.port,
    )
    
    user_repository = providers.Factory(
        UserRepository,
        db=database,
    )
    
    user_service = providers.Factory(
        UserService,
        repository=user_repository,
    )
```

---

## Resumen de Patrones por Principio

| Principio | Patrones Relacionados |
|-----------|----------------------|
| SRP | Facade, Service Layer |
| OCP | Strategy, Decorator, Factory |
| LSP | Template Method, Null Object |
| ISP | Adapter, Facade |
| DIP | Factory, Dependency Injection, Service Locator |

## Checklist SOLID

### Single Responsibility
- [ ] Cada clase tiene una única responsabilidad
- [ ] Puedo describir la clase sin usar "y"
- [ ] Cambios están localizados

### Open/Closed
- [ ] Puedo agregar funcionalidad sin modificar código existente
- [ ] Uso polimorfismo en lugar de condicionales de tipo
- [ ] Nuevos comportamientos se agregan con nuevas clases

### Liskov Substitution
- [ ] Subclases son sustituibles por su clase base
- [ ] No hay métodos que lanzan NotImplementedError
- [ ] Contratos de la superclase se respetan

### Interface Segregation
- [ ] Interfaces son pequeñas y específicas
- [ ] No hay métodos vacíos o no implementados
- [ ] Clientes solo dependen de lo que usan

### Dependency Inversion
- [ ] Módulos de alto nivel dependen de abstracciones
- [ ] Dependencias se inyectan, no se instancian
- [ ] Fácil de testear con mocks
