---
name: docker-build
description: Build imagen Docker
---

# Workflow: Docker Build

## Pasos

1. **Verificar Dockerfile**
   ```bash
   hadolint Dockerfile
   ```

2. **Build**
   ```bash
   docker build -t app:latest .
   ```

3. **Verificar tamaño**
   ```bash
   docker images app:latest
   ```

4. **Escanear vulnerabilidades**
   ```bash
   docker scout cves app:latest
   ```

5. **Test básico**
   ```bash
   docker run --rm app:latest --version
   ```
