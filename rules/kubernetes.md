---
trigger: glob
globs: ["*.yaml", "*.yml", "**/k8s/**", "Chart.yaml", "values.yaml"]
---

# Kubernetes Best Practices

## Validation - MANDATORY

Before applying manifests, run:
```bash
# Validate schema
kubeval my-deployment.yaml
# Validate policies
datree test ./k8s
```

## Security - NON-NEGOTIABLE

### Strictly Forbidden:
- `privileged: true`
- `allowPrivilegeEscalation: true`
- `runAsRoot: true` (implicit or explicit)

### Required SecurityContext
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 10001
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]
```

## Resources - Always Define

```yaml
resources:
  requests:
    memory: "128Mi"   # Expected normal usage
    cpu: "100m"       # 0.1 CPU cores
  limits:
    memory: "256Mi"   # Max allowed (OOMKilled if exceeded)
    cpu: "500m"       # Throttled if exceeded
```

## Probes

- **Liveness**: Is the container alive? (Restarts if fails)
- **Readiness**: Can it receive traffic? (Removes from LB if fails)
- **Startup**: For slow booting apps.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
```

## Labels Standard
Use [Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/):
```yaml
metadata:
  labels:
    app.kubernetes.io/name: my-app
    app.kubernetes.io/instance: prod
    app.kubernetes.io/version: "1.2.3"
    app.kubernetes.io/managed-by: helm
```

## Service Accounts
- `automountServiceAccountToken: false` unless API access is explicitly needed.
