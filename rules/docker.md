---
trigger: glob
globs: ["Dockerfile", "docker-compose*.yml", ".dockerignore"]
---

# Docker Best Practices

## Multi-stage Builds

```dockerfile
# Stage 1: Build
FROM golang:1.23-alpine AS builder
WORKDIR /app

# Dependencias primero (mejor caching)
COPY go.mod go.sum ./
RUN go mod download

# Código después
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o main .

# Stage 2: Runtime (imagen mínima)
FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata

COPY --from=builder /app/main /usr/local/bin/

# No root
USER nobody:nobody

ENTRYPOINT ["main"]
```

## Orden de Capas (Caching)

Ordenar de menos a más cambiante:

```dockerfile
# 1. Base image (casi nunca cambia)
FROM node:20-alpine

# 2. Configuración del sistema
WORKDIR /app
RUN apk --no-cache add curl

# 3. Dependencias (cambia con package.json)
COPY package.json package-lock.json ./
RUN npm ci --only=production

# 4. Código fuente (cambia frecuentemente)
COPY . .

# 5. Build
RUN npm run build
```

## Seguridad

### No Root
```dockerfile
# Crear usuario sin privilegios
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

USER appuser:appgroup
```

### Imágenes Base Específicas
```dockerfile
# ✅ Versión específica
FROM python:3.12-slim-bookworm
FROM node:20.10-alpine3.19
FROM golang:1.23-alpine3.19

# ❌ Evitar
FROM python:latest
FROM node:alpine
```

### Secrets - Nunca en Imagen
```dockerfile
# ❌ Nunca hardcodear
ENV API_KEY=secret123

# ✅ Usar build secrets (BuildKit)
RUN --mount=type=secret,id=api_key \
    cat /run/secrets/api_key > /app/.env

# ✅ O variables de entorno en runtime
# docker run -e API_KEY=xxx ...
```

## .dockerignore

```
# Control de versiones
.git
.gitignore

# Dependencias
node_modules
venv
.venv
__pycache__

# Build artifacts
dist
build
*.pyc

# Configuración local
.env*
*.local

# IDE
.idea
.vscode

# Terraform
.terraform
*.tfstate*

# Documentación
*.md
!README.md
LICENSE

# Tests
tests/
*_test.go
```

## Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
```

## Docker Compose

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - LOG_LEVEL=${LOG_LEVEL:-info}
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

## Comandos

```bash
# Build
docker build -t app:1.0.0 .
docker build --no-cache -t app:1.0.0 .  # Sin cache

# Run
docker run -d -p 8080:8080 --name app app:1.0.0
docker run --rm -it app:1.0.0 /bin/sh  # Debug

# Compose
docker compose up -d
docker compose logs -f app
docker compose down -v  # Con volúmenes

# Lint y Seguridad
hadolint Dockerfile
docker scout cves app:1.0.0
trivy image app:1.0.0

# Limpieza
docker system prune -af
docker volume prune -f
```

## Anti-Patrones

| Anti-Patrón | Solución |
|-------------|----------|
| `FROM imagen:latest` | Usar tags específicos |
| Correr como root | `USER nobody` o crear usuario |
| Secrets en ENV | Build secrets o runtime env |
| Un RUN por comando | Combinar comandos relacionados |
| COPY antes de dependencias | Copiar deps primero para cache |
