---
trigger: glob
globs: ["Dockerfile", "docker-compose*.yml", ".dockerignore"]
---

# Docker Best Practices

## Multi-stage Builds

```dockerfile
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o main .

FROM alpine:3.19
COPY --from=builder /app/main /usr/local/bin/
USER nobody
ENTRYPOINT ["main"]
```

## Orden de Capas

Ordenar de menos a más cambiante:
```dockerfile
# Dependencias primero
COPY package.json package-lock.json ./
RUN npm ci

# Código después
COPY . .
```

## No Root

```dockerfile
RUN adduser -D appuser
USER appuser
```

## .dockerignore

```
.git
node_modules
*.md
.env*
.terraform
```

## Docker Compose

```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
```

## Comandos

```bash
docker build -t app:latest .
docker run -d -p 8080:8080 app:latest
docker compose up -d
docker compose logs -f
docker system prune -af
```

## Seguridad

- Escanear imágenes: `docker scout`, `trivy`
- Base images específicas, no `latest`
- No secrets en imágenes
