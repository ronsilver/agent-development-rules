---
name: security-check
description: Análisis de seguridad del proyecto
---

# Workflow: Security Check

Análisis completo de seguridad del código y configuración.

## 1. Secrets y Credenciales

### Buscar Patrones Sospechosos
```bash
# Buscar hardcoded secrets
grep -rE "(password|secret|api_key|token|credential)\s*[:=]\s*[\"'][^\"']+" . --include="*.{py,go,js,ts,tf,yaml,yml}"

# Verificar archivos .env
git ls-files | grep -E "(\.env|\.env\..*)$"

# Buscar claves privadas
find . -name "*.pem" -o -name "*.key" -o -name "id_rsa"
```

### Herramientas Especializadas
```bash
# Trufflehog - buscar secrets en historial git
trufflehog git file://. --only-verified

# Gitleaks
gitleaks detect --source .
```

## 2. Vulnerabilidades en Dependencias

| Lenguaje | Comando |
|----------|----------|
| Node.js | `npm audit` |
| Python | `pip-audit` |
| Go | `govulncheck ./...` |
| General | `trivy fs .` |

## 3. Infraestructura (Terraform/K8s)

### Terraform
```bash
# Verificar security groups abiertos
grep -rE 'cidr_blocks.*0\.0\.0\.0/0' *.tf

# Variables sensibles sin sensitive = true
grep -A5 'variable.*password\|secret\|key' variables.tf | grep -v sensitive

# Escanear con tfsec
tfsec .
```

### Kubernetes
```bash
# Pods como root
grep -rE 'runAsUser:\s*0|runAsNonRoot:\s*false' .

# Escanear con kubesec
kubesec scan deployment.yaml
```

## 4. Docker

```bash
# Lint Dockerfile
hadolint Dockerfile

# Escanear imagen
trivy image my-app:latest
docker scout cves my-app:latest
```

## 5. Formato de Reporte

```markdown
## [🔴 CRITICAL] Descripción
**Archivo:** path/to/file:Línea
**Problema:** Qué se encontró
**Impacto:** Qué podría pasar
**Remediación:** Cómo corregirlo
```

## Severidades

| Nivel | Criterio |
|-------|----------|
| 🔴 CRITICAL | Explotable remotamente, alto impacto |
| 🟠 HIGH | Explotable con condiciones |
| 🟡 MEDIUM | Requiere acceso interno |
| 🟢 LOW | Best practice, bajo riesgo |
