---
name: security-check
description: Deep security analysis
---

# Workflow: Security Check

## 1. Secrets & Credentials

### Search Patterns
```bash
# Grep for secrets
grep -rE "(password|secret|api_key|token|credential)\s*[:=]\s*[\"'][^\"']+" .
```

### Specialized Tools
```bash
# Gitleaks (Scanning git history)
gitleaks detect --source .
# STOP if secrets found
```

## 2. Dependency Vulnerabilities

| Project | Command |
|---------|---------|
| Node.js | `npm audit` |
| Python | `pip-audit` |
| Go | `govulncheck ./...` |
| General | `trivy fs .` |

## 3. Infrastructure (IaC)

### Terraform
```bash
# Check for wide open security groups
grep -rE 'cidr_blocks.*0\.0\.0\.0/0' *.tf
# Scan with tfsec/trivy
trivy config .
```

### Kubernetes
```bash
# Check for root user
grep -rE 'runAsUser:\s*0|runAsNonRoot:\s*false' .
```

## 4. Docker
```bash
hadolint Dockerfile
trivy image my-app:latest
```

## 5. Report Findings

Report any **High** or **Critical** issues immediately.
