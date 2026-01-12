---
trigger: glob
globs: ["Dockerfile", "docker-compose*.yml", ".dockerignore"]
---

# Docker Best Practices

## Validation Tools - MANDATORY

Before building, run:
```bash
hadolint Dockerfile
docker scout quickview .
```

## Security - NON-NEGOTIABLE

### 1. Non-Root User
The container **MUST NOT** run as root.
```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

### 2. Base Images
- Use specific versions (SHA256 digest preferred for prod).
- **NEVER** use `latest`.
- Prefer minimal images (`alpine`, `slim`, `distroless`).

## Optimizations

### Multi-stage Builds
Use multi-stage builds to keep runtime images small.

```dockerfile
# Builder
FROM golang:1.23-alpine AS builder
# ... build commands ...

# Runtime
FROM alpine:3.19
COPY --from=builder /app/main /main
USER nonroot
```

### Layer Ordering
Order instructions from least to most frequently changed (dependencies first, source code last) to maximize caching.

## .dockerignore
Always include:
- `.git`
- `node_modules` / `venv`
- `secrets` / `.env`
- `Dockerfile` / `README.md`

## Health Checks
Definining `HEALTHCHECK` is mandatory for long-running services.
