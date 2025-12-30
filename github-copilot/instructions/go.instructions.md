# Go Instructions

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
| Packages | lowercase, singular | `user`, `auth` |
| Interfaces | -er suffix cuando aplique | `Reader`, `Validator` |
| Exported | PascalCase | `CreateUser`, `MaxRetries` |
| Unexported | camelCase | `parseConfig`, `defaultTimeout` |
| Constantes | PascalCase | `MaxConnections`, `DefaultPort` |
| Acronyms | Todo mayúsculas o minúsculas | `HTTPServer`, `xmlParser` |
| Receivers | 1-2 letras consistentes | `func (u *User)`, `func (s *Service)` |

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
func ProcessOrder(ctx context.Context, orderID string) error {
    user, err := s.userRepo.GetByID(ctx, orderID)
    if err != nil {
        return fmt.Errorf("get user: %w", err)
    }
    return s.notify(ctx, user)
}
```

## Interfaces

```go
// Pequeñas: 1-3 métodos
// Definir donde se usan, no donde se implementan
type UserRepository interface {
    GetByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
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
        {"premium 10%", 100, "premium", 90, false},
        {"standard no discount", 100, "standard", 100, false},
        {"invalid tier", 100, "invalid", 0, true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CalculateDiscount(tt.amount, tt.tier)
            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
            }
            if got != tt.expected {
                t.Errorf("got %v, want %v", got, tt.expected)
            }
        })
    }
}
```

## Estructura de Proyecto

```
project/
├── cmd/
│   └── api/main.go       # Entrypoints
├── internal/             # Código privado
│   ├── handler/
│   ├── service/
│   └── repository/
├── pkg/                  # Código público reutilizable
├── go.mod
└── go.sum
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
```

## Anti-Patrones

| Anti-Patrón | Solución |
|-------------|----------|
| Ignorar errores con `_` | Siempre manejar o documentar por qué |
| `panic` en bibliotecas | Retornar error |
| Interfaces grandes | Dividir en interfaces pequeñas |
| Context en structs | Pasar como primer parámetro |
| Goroutines sin control | Usar errgroup o similar |
