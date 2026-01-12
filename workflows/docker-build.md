---
name: docker-build
description: Build Docker image with strict validation
---

# Workflow: Docker Build

## Steps

1.  **Verify Dockerfile**
    ```bash
    hadolint Dockerfile
    # STOP if hadolint fails
    ```

2.  **Build Image**
    ```bash
    docker build -t app:latest .
    ```

3.  **Verify Image Size**
    ```bash
    docker images app:latest
    ```

4.  **Scan for Vulnerabilities (CVEs)**
    ```bash
    docker scout cves app:latest
    # OR
    trivy image app:latest
    # STOP if CRITICAL vulnerabilities found
    ```

5.  **Smoke Test**
    ```bash
    docker run --rm app:latest --version
    # STOP if command fails
    ```
