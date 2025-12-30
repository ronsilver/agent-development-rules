---
trigger: glob
globs: ["*.yaml", "*.yml", "**/k8s/**", "Chart.yaml", "values.yaml"]
---

# Kubernetes Best Practices

## Resources - Siempre Definir

```yaml
resources:
  requests:
    memory: "128Mi"   # Uso normal esperado
    cpu: "100m"       # 0.1 CPU cores
  limits:
    memory: "256Mi"   # Máximo permitido (OOMKilled si excede)
    cpu: "500m"       # Throttling si excede
```

### Guía de Sizing
| Tipo de Aplicación | Memory Request | CPU Request |
|--------------------|----------------|-------------|
| API ligera | 64-128Mi | 50-100m |
| API estándar | 256-512Mi | 100-250m |
| Worker/Jobs | 512Mi-1Gi | 250-500m |
| Base de datos | 1-4Gi | 500m-2000m |

## Probes

```yaml
# Liveness: ¿El container está vivo? (restart si falla)
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3

# Readiness: ¿Puede recibir tráfico? (remove from LB si falla)
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 2
  failureThreshold: 3

# Startup: Para apps lentas al iniciar (reemplaza liveness durante startup)
startupProbe:
  httpGet:
    path: /health
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

## Labels Estándar

```yaml
metadata:
  labels:
    # Recomendados por Kubernetes
    app.kubernetes.io/name: my-app
    app.kubernetes.io/instance: my-app-prod
    app.kubernetes.io/version: "1.2.3"
    app.kubernetes.io/component: api
    app.kubernetes.io/part-of: platform
    app.kubernetes.io/managed-by: helm
```

## Security Context

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault

  containers:
    - name: app
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

## Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    # Para IRSA en AWS EKS
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-app
    # Para Workload Identity en GKE
    iam.gke.io/gcp-service-account: my-app@project.iam.gserviceaccount.com
automountServiceAccountToken: false  # Solo si no necesita API access
```

## Deployment Completo

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app.kubernetes.io/name: my-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app.kubernetes.io/name: my-app
  template:
    metadata:
      labels:
        app.kubernetes.io/name: my-app
    spec:
      serviceAccountName: my-app
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      
      containers:
        - name: app
          image: my-app:1.2.3
          ports:
            - containerPort: 8080
              name: http
          
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "500m"
          
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 15
            periodSeconds: 10
          
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
          
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          
          env:
            - name: LOG_LEVEL
              value: "info"
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: my-app-secrets
                  key: db-password
```

## Helm

```bash
# Validar chart
helm lint ./chart
helm template release ./chart -f values.yaml
helm template release ./chart -f values.yaml | kubectl apply --dry-run=client -f -

# Dry run
helm upgrade --install release ./chart -f values.yaml --dry-run --debug

# Deploy
helm upgrade --install release ./chart -f values.yaml --wait

# Rollback
helm rollback release 1
```

## Comandos Útiles

```bash
# Pods y estado
kubectl get pods -n namespace -o wide
kubectl describe pod <pod-name> -n namespace
kubectl get events -n namespace --sort-by='.lastTimestamp'

# Logs
kubectl logs <pod-name> -f --tail=100
kubectl logs <pod-name> -c <container> --previous  # Container anterior

# Debug
kubectl exec -it <pod-name> -- /bin/sh
kubectl run debug --rm -it --image=alpine -- /bin/sh

# Recursos
kubectl top pods -n namespace
kubectl top nodes

# Port forward
kubectl port-forward svc/my-service 8080:80
kubectl port-forward pod/<pod-name> 8080:8080

# Secrets
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
```

## Anti-Patrones

| Anti-Patrón | Solución |
|-------------|----------|
| Sin resources definidos | Siempre definir requests y limits |
| Sin probes | Agregar liveness y readiness |
| Correr como root | SecurityContext restrictivo |
| Image tag `latest` | Usar tags específicos e inmutables |
| Secrets en ConfigMaps | Usar Secrets o external-secrets |
