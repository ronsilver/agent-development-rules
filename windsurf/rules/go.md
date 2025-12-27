---
trigger: glob
globs: ["*.go", "go.mod", "go.sum"]
---

# Go Best Practices

## Error Handling

### Siempre Manejar Errores
```go
// ✅ Correcto
if err != nil {
    return fmt.Errorf("failed to process: %w", err)
}

// ❌ Incorrecto
result, _ := doSomething()
```

### No Panic en Producción
```go
// ❌ Evitar
panic(err)
log.Fatal(err)  // Solo en main() para startup

// ✅ Preferir
return err
```

## Naming

### Packages
- Lowercase, sin guiones bajos
- Nombres cortos y descriptivos

### Variables
- Cortas para scope pequeño: `i`, `n`, `err`
- Descriptivas para scope grande: `userCount`

### Exports
- Públicos: `Capitalized`
- Privados: `lowercase`

## Interfaces

- Definir donde se usan, no donde se implementan
- Pequeñas: 1-3 métodos máximo

```go
type Reader interface {
    Read(p []byte) (n int, err error)
}
```

## Context

- Siempre como primer parámetro
- Propagar en llamadas

```go
func Process(ctx context.Context, data []byte) error {
    return repo.Save(ctx, data)
}
```

## Testing

### Table-Driven Tests
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            if got := Add(tt.a, tt.b); got != tt.expected {
                t.Errorf("got %d, want %d", got, tt.expected)
            }
        })
    }
}
```

## Estructura de Proyecto

```
project/
├── cmd/
│   └── app/
│       └── main.go
├── internal/
│   ├── handler/
│   ├── service/
│   └── repository/
├── pkg/
├── go.mod
└── go.sum
```

## Comandos

```bash
go fmt ./...
go vet ./...
go test ./...
go mod tidy
```

## Performance

- Pre-allocar slices: `make([]T, 0, size)`
- Usar `strings.Builder` para concatenación
- `sync.Pool` para objetos frecuentes
