---
trigger: glob
globs: ["*.go", "go.mod", "go.sum"]
---

# Go Best Practices

## Error Handling

### Regla Principal
Siempre manejar errores explícitamente. Nunca ignorar con `_`.

```go
// ✅ Correcto - Error con contexto
if err != nil {
    return fmt.Errorf("failed to create user %s: %w", username, err)
}

// ✅ Correcto - Errores sentinel
if errors.Is(err, ErrNotFound) {
    return nil  // Handle gracefully
}

// ❌ Incorrecto - Error ignorado
result, _ := doSomething()

// ❌ Incorrecto - Error sin contexto
if err != nil {
    return err
}
```

### Error Wrapping
```go
// Wrap con contexto para debugging
if err != nil {
    return fmt.Errorf("process order %s: %w", orderID, err)
}

// Definir errores sentinel
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
)
```

### No Panic en Producción
```go
// ❌ Evitar
panic(err)
log.Fatal(err)  // Solo aceptable en main() para startup

// ✅ Preferir
return fmt.Errorf("critical error: %w", err)
```

## Naming Conventions

| Elemento | Convención | Ejemplo |
|----------|------------|----------|
| Packages | lowercase, singular, sin `_` | `user`, `auth`, `httputil` |
| Interfaces | -er suffix cuando aplique | `Reader`, `Validator`, `UserService` |
| Exported | PascalCase | `CreateUser`, `MaxRetries` |
| Unexported | camelCase | `parseConfig`, `defaultTimeout` |
| Constantes | PascalCase | `MaxConnections`, `DefaultPort` |
| Receivers | 1-2 letras consistentes | `func (u *User)`, `func (s *Service)` |
| Acronyms | Todo mayúsculas o minúsculas | `HTTPServer`, `xmlParser` |

### Variables por Scope
```go
// Scope pequeño: nombres cortos
for i, v := range items { }
if err := validate(); err != nil { }

// Scope grande: nombres descriptivos
var userSessionTimeout = 30 * time.Minute
var maxConcurrentRequests = 100
```

## Context

```go
// Siempre primer parámetro, propagar en llamadas
func (s *Service) ProcessOrder(ctx context.Context, orderID string) error {
    // Verificar cancelación
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
    }

    user, err := s.userRepo.GetByID(ctx, orderID)
    if err != nil {
        return fmt.Errorf("get user: %w", err)
    }
    
    return s.notifier.Send(ctx, user)
}

// Context con timeout
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
```

## Interfaces

```go
// Pequeñas: 1-3 métodos
// Definir donde se USAN, no donde se implementan
type UserRepository interface {
    GetByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

// Composición de interfaces
type ReadWriter interface {
    Reader
    Writer
}
```

## Testing

### Table-Driven Tests
```go
func TestCalculateDiscount(t *testing.T) {
    tests := []struct {
        name     string
        amount   float64
        tier     string
        expected float64
        wantErr  bool
    }{
        {"premium 10%", 100.0, "premium", 90.0, false},
        {"standard no discount", 100.0, "standard", 100.0, false},
        {"invalid tier", 100.0, "invalid", 0, true},
        {"zero amount", 0, "premium", 0, false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CalculateDiscount(tt.amount, tt.tier)
            
            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            
            if got != tt.expected {
                t.Errorf("got %v, want %v", got, tt.expected)
            }
        })
    }
}
```

### Testify para Assertions
```go
import "github.com/stretchr/testify/assert"

func TestUser(t *testing.T) {
    user, err := CreateUser("test")
    
    assert.NoError(t, err)
    assert.NotNil(t, user)
    assert.Equal(t, "test", user.Name)
}
```

## Estructura de Proyecto

```
project/
├── cmd/
│   └── api/
│       └── main.go           # Entrypoint
├── internal/                 # Código privado del proyecto
│   ├── config/
│   ├── handler/              # HTTP handlers
│   ├── service/              # Business logic
│   ├── repository/           # Data access
│   └── model/                # Domain models
├── pkg/                      # Código público reutilizable
├── go.mod
├── go.sum
└── Makefile
```

## Comandos de Validación

```bash
# Formateo y linting
go fmt ./...
go vet ./...
golangci-lint run

# Testing
go test ./... -v
go test ./... -race -cover
go test -bench=. ./...

# Dependencias
go mod tidy
go mod verify

# Vulnerabilidades
govulncheck ./...
```

## Performance

```go
// Pre-allocar slices cuando conoces el tamaño
results := make([]Result, 0, len(items))

// strings.Builder para concatenación
var sb strings.Builder
for _, s := range items {
    sb.WriteString(s)
}
result := sb.String()

// sync.Pool para objetos frecuentes
var bufferPool = sync.Pool{
    New: func() interface{} {
        return new(bytes.Buffer)
    },
}

// Evitar allocations en hot paths
func (s *Service) Process(data []byte) error {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer bufferPool.Put(buf)
    buf.Reset()
    // use buf...
}
```

## Anti-Patrones

| Anti-Patrón | Solución |
|-------------|----------|
| Ignorar errores con `_` | Siempre manejar o documentar por qué |
| `panic` en bibliotecas | Retornar error |
| Interfaces grandes | Dividir en interfaces pequeñas |
| Context en structs | Pasar como primer parámetro |
| Goroutines sin control | Usar errgroup o similar |
