---
trigger: glob
globs: ["*.yaml", "*.yml", "**/k8s/**", "Chart.yaml", "values.yaml"]
---

# Kubernetes Best Practices

## Resources

Siempre definir requests y limits:
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

## Probes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 3
```

## Labels

```yaml
metadata:
  labels:
    app.kubernetes.io/name: app-name
    app.kubernetes.io/instance: app-instance
    app.kubernetes.io/version: "1.0.0"
```

## Seguridad

- No correr como root
- SecurityContext restrictivo
- NetworkPolicies
- ServiceAccounts con mínimos privilegios

## Helm

### Lint
```bash
helm lint ./chart
helm template release ./chart -f values.yaml
```

### Install
```bash
helm upgrade --install release ./chart -f values.yaml
```

## Comandos Útiles

```bash
kubectl get pods -n namespace
kubectl describe pod pod-name
kubectl logs pod-name -f
kubectl exec -it pod-name -- /bin/sh
kubectl port-forward pod-name 8080:8080
```
