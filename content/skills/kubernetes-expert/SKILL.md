---
name: kubernetes-expert
description: Deploy secure, production-ready Kubernetes workloads with proper security contexts, resource limits, probes, and network policies. Use when the user asks to create K8s manifests, Helm charts, or review cluster configurations.
license: MIT
---

# Kubernetes Expert

## Workflow

### Step 1: Validate Manifests

```bash
kubeconform -strict manifests/       # Schema validation
kube-linter lint manifests/          # Policy validation
kubectl apply --dry-run=server -f manifests/  # Cluster dry run
```

### Step 2: Security — NON-NEGOTIABLE

#### Strictly Forbidden

| Setting | Why |
|---------|-----|
| `privileged: true` | Full host access |
| `allowPrivilegeEscalation: true` | Can gain root |
| `runAsUser: 0` | Running as root |
| `hostNetwork: true` | Bypasses network policies |
| `hostPID: true` | Can see all host processes |
| `hostIPC: true` | Can access host IPC |

#### Required SecurityContext

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    runAsGroup: 10001
    fsGroup: 10001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
```

#### Pod Security Standards

| Level | Description |
|-------|-------------|
| `privileged` | No restrictions (avoid) |
| `baseline` | Minimal restrictions |
| `restricted` | Hardened (recommended for prod) |

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Step 3: Resources — MANDATORY

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "500m"
```

| Workload | Memory Request | Memory Limit | CPU Request |
|----------|----------------|--------------|-------------|
| Small API | 64-128Mi | 256Mi | 50-100m |
| Standard API | 256-512Mi | 1Gi | 100-250m |
| Worker/Batch | 512Mi-1Gi | 2Gi | 250-500m |
| Memory-intensive | 1-4Gi | 8Gi | 500m |

**Best Practice:** Set memory limit = 2x memory request to handle spikes.

### Step 4: Probes — MANDATORY for Production

```yaml
containers:
- name: app
  livenessProbe:
    httpGet:
      path: /healthz
      port: 8080
    initialDelaySeconds: 15
    periodSeconds: 10
    failureThreshold: 3
  readinessProbe:
    httpGet:
      path: /ready
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 5
  startupProbe:
    httpGet:
      path: /healthz
      port: 8080
    failureThreshold: 30
    periodSeconds: 10
```

### Step 5: Labels

```yaml
metadata:
  labels:
    app.kubernetes.io/name: my-app
    app.kubernetes.io/instance: prod-us-east-1
    app.kubernetes.io/version: "1.2.3"
    app.kubernetes.io/component: api
    app.kubernetes.io/managed-by: helm
```

### Step 6: Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - port: 5432
```

### Step 7: Health Endpoint Implementation

```go
http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
    if err := db.Ping(); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
})

http.HandleFunc("/ready", func(w http.ResponseWriter, r *http.Request) {
    if !app.IsWarmedUp() {
        w.WriteHeader(http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
})
```

### Step 8: Annotations

```yaml
metadata:
  annotations:
    description: "User authentication service"
    owner: "platform-team@example.com"
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
```

### Step 9: Service Accounts

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-app-role
---
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      serviceAccountName: my-app
      automountServiceAccountToken: false  # Unless K8s API access needed
```

### Step 10: PodDisruptionBudget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2        # Or: maxUnavailable: 1
  selector:
    matchLabels:
      app: my-app
```

### Step 11: Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Step 12: ConfigMaps & Secrets

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-app-config
data:
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
```

**Best Practice:** Use external secrets (AWS Secrets Manager, Vault) via External Secrets Operator. Do not store sensitive data in K8s Secret manifests.

## Deployment Checklist

- [ ] SecurityContext configured (runAsNonRoot, drop ALL capabilities)
- [ ] Resources (requests/limits) defined
- [ ] Liveness and readiness probes configured
- [ ] Recommended labels applied
- [ ] ServiceAccount created (automountToken: false)
- [ ] NetworkPolicy restricting traffic
- [ ] PodDisruptionBudget for availability
- [ ] HPA for autoscaling
- [ ] Secrets managed externally
- [ ] Pod Security Standards enforced on namespace
- [ ] `kubeconform` and `kube-linter` pass

## Constraints

- **NEVER** use `privileged: true` or `runAsUser: 0`.
- **NEVER** store secrets in K8s Secret manifests — use External Secrets Operator.
- **ALWAYS** define resource requests and limits.
- **ALWAYS** configure liveness and readiness probes.
- **ALWAYS** validate with `kubeconform` before applying.
