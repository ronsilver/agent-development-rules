---
name: docker-expert
description: Build secure, optimized Docker images and compose setups. Use when the user asks to create a Dockerfile, optimize an image, fix Docker issues, or set up docker-compose.
license: MIT
---

# Docker Expert

## Workflow

### Step 1: Detect Stack

Identify the project's language and framework to choose the right base image and build strategy.

### Step 2: Create or Review Dockerfile

Every Dockerfile MUST follow these rules:

#### Base Image Selection

| Use Case | Recommended Base | Size |
|----------|-----------------|------|
| Go binaries | `gcr.io/distroless/static` | ~2MB |
| Go with libc | `gcr.io/distroless/base` | ~20MB |
| Python | `python:3.12-slim` | ~150MB |
| Node.js | `node:20-slim` | ~200MB |
| General minimal | `alpine:3.19` | ~7MB |

- ✅ Pin specific versions: `python:3.12.1-slim`
- ✅ Use SHA for production: `python@sha256:abc123...`
- ❌ **NEVER** use `latest` tag
- ❌ **NEVER** use full images in production (`python:3.12` = 1GB+)

#### Multi-Stage Builds (MANDATORY)

```dockerfile
# ======== Build Stage ========
FROM golang:1.23-alpine AS builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/server ./cmd/server

# ======== Runtime Stage ========
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

**Python Example:**
```dockerfile
# Build stage
FROM python:3.12-slim AS builder

WORKDIR /app
RUN pip install --no-cache-dir poetry
COPY pyproject.toml poetry.lock ./
RUN poetry export -f requirements.txt > requirements.txt

# Runtime stage
FROM python:3.12-slim

WORKDIR /app
COPY --from=builder /app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser
CMD ["python", "-m", "src.main"]
```

#### Minimal Attack Surface

```dockerfile
# ❌ Bad — full image with unnecessary tools
FROM python:3.12
RUN pip install flask

# ✅ Good — slim image, no cache
FROM python:3.12-slim
RUN pip install --no-cache-dir flask
```

#### Non-Root User (MANDATORY)

```dockerfile
# Alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Debian/Ubuntu
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser
```

#### Read-Only Filesystem

```dockerfile
# In Dockerfile
RUN chmod -R a-w /app

# Or at runtime
# docker run --read-only --tmpfs /tmp myapp
```

#### Layer Optimization

Order: **least → most frequently changed**

```dockerfile
FROM node:20-slim
# 1. System deps (rare changes)
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
# 2. App deps (occasional changes)
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production
# 3. App code (frequent changes)
COPY src/ ./src/
USER node
EXPOSE 3000
CMD ["node", "src/index.js"]
```

#### Combine RUN Commands

```dockerfile
# ❌ Bad — multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# ✅ Good — single layer, cleanup in same layer
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
```

### Step 3: Create .dockerignore

```dockerignore
# Git
.git
.gitignore

# Dependencies (rebuild in container)
node_modules
venv
__pycache__
*.pyc

# Secrets (NEVER include)
.env
.env.*
*.pem
*.key
secrets/

# Build artifacts
dist
build
*.egg-info

# IDE/Editor
.idea
.vscode
*.swp

# Docker files (not needed in context)
Dockerfile*
docker-compose*
.dockerignore
```

### Step 4: Add Health Check

```dockerfile
# HTTP health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# For distroless (no curl)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/healthcheck"]  # Include a static binary
```

### Step 5: Validate

```bash
# Lint
hadolint Dockerfile

# Scan for vulnerabilities
trivy image <image>
# Or: docker scout cves <image> (requires Docker Desktop)
```

## Security Checklist

- [ ] Base image pinned to specific version
- [ ] Multi-stage build used
- [ ] Running as non-root user
- [ ] No secrets in image (no `ENV API_KEY=...`, no `COPY .env`)
- [ ] `.dockerignore` exists and excludes secrets
- [ ] `HEALTHCHECK` defined
- [ ] `hadolint` passes
- [ ] Image scanned for vulnerabilities
- [ ] Resource limits configured in compose/runtime

## Secrets Management

```dockerfile
# ❌ NEVER — secrets baked into image
ENV API_KEY=sk-12345
COPY .env /app/.env

# ✅ Pass at runtime
# docker run -e API_KEY=$API_KEY myapp
```

```yaml
# docker-compose.yml with secrets
services:
  app:
    secrets:
      - db_password
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

## Resource Limits

```yaml
# docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
```

```bash
# docker run
docker run --memory=512m --cpus=1.0 myapp
```

## Common Hadolint Rules

| Rule | Issue | Fix |
|------|-------|-----|
| DL3006 | Missing image tag | Pin: `FROM alpine:3.19` |
| DL3007 | Using `latest` | Pin specific version |
| DL3008 | apt without version | `apt-get install pkg=1.2.3` |
| DL3009 | apt lists not deleted | Add `rm -rf /var/lib/apt/lists/*` |
| DL3018 | apk without version | `apk add pkg=1.2.3` |
| DL3025 | CMD not JSON | `CMD ["node", "app.js"]` |
| DL4006 | No pipefail | `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` |

## Constraints

- **NEVER** use `latest` tags — always pin versions.
- **NEVER** bake secrets into images.
- **ALWAYS** use multi-stage builds for compiled languages.
- **ALWAYS** run as non-root in production.
- **ALWAYS** validate with `hadolint` before committing.
