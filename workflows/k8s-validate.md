---
name: k8s-validate
description: Validate Kubernetes manifests
---

# Workflow: K8s Validate

## Steps

1.  **Detect Type**
    - Helm: `Chart.yaml`
    - Kustomize: `kustomization.yaml`
    - Plain YAML: `*.yaml` (with kind/apiVersion)

2.  **Validate**

    **Helm**:
    ```bash
    helm lint ./chart
    helm template ./chart > /dev/null
    # STOP if lint fails
    ```

    **Kustomize**:
    ```bash
    kubectl kustomize . > /dev/null
    # STOP if build fails
    ```

    **Plain YAML**:
    ```bash
    kubeval *.yaml
    # OR
    kubectl apply --dry-run=client -f .
    ```

3.  **Best Practices Check**
    - [ ] Resources (requests/limits) defined?
    - [ ] Probes (liveness/readiness) configured?
    - [ ] SecurityContext (runAsNonRoot) set?
