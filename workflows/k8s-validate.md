---
name: k8s-validate
description: Validar manifests Kubernetes
---

# Workflow: K8s Validate

## Pasos

1. **Detectar tipo**
   - Helm: `Chart.yaml`
   - Kustomize: `kustomization.yaml`
   - Plain YAML

2. **Validar**
   - Helm: `helm lint && helm template`
   - Kustomize: `kubectl kustomize`
   - YAML: `kubectl apply --dry-run=client -f`

3. **Verificar best practices**
   - Resources definidos
   - Probes configurados
   - Labels estándar
