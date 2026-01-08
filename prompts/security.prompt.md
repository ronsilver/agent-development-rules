# Security Check

Analizar el código para identificar vulnerabilidades de seguridad.

## Categorías de Análisis

### 1. Secrets y Credenciales

**Buscar:**
- API keys hardcodeadas
- Passwords en código
- Tokens de acceso
- Connection strings con credenciales
- Certificados o claves privadas

**Patrones sospechosos:**
```
password\s*=\s*["'][^"']+["']
api[_-]?key\s*=\s*["'][^"']+["']
secret\s*=\s*["'][^"']+["']
Authorization:\s*Bearer\s+[A-Za-z0-9-_]+
```

### 2. Input Validation

**Vulnerabilidades:**
- SQL Injection
- XSS (Cross-Site Scripting)
- Command Injection
- Path Traversal
- SSRF (Server-Side Request Forgery)

**Verificar:**
- Inputs de usuario sanitizados
- Queries parametrizadas (no concatenación)
- Escape de HTML en outputs
- Validación de URLs y paths

### 3. Autenticación y Autorización

- Passwords hasheados (bcrypt, argon2)
- Tokens con expiración
- Rate limiting en endpoints sensibles
- Verificación de permisos en cada request
- CORS configurado correctamente

### 4. Datos Sensibles

- No loggear datos sensibles (passwords, tokens, PII)
- Encryption at rest para datos sensibles
- HTTPS en producción
- Headers de seguridad (HSTS, CSP, etc.)

### 5. Dependencias

```bash
# Verificar vulnerabilidades
npm audit              # Node.js
pip-audit              # Python
go vuln check ./...    # Go
trivy fs .             # General
```

### 6. Infraestructura (IaC)

**Terraform/Kubernetes:**
- Security groups sin 0.0.0.0/0 innecesario
- Variables sensibles con `sensitive = true`
- Pods no corriendo como root
- Secrets en Secret Manager, no en código

## Formato de Reporte

```markdown
## [🔴 CRITICAL] Título

**Archivo:** path/to/file:Línea
**CWE:** CWE-XXX (si aplica)

**Vulnerabilidad:**
Descripción del problema.

**Impacto:**
Qué podría pasar si se explota.

**Remediación:**
Cómo corregirlo con ejemplo.
```

## Severidades

| Nivel | Criterio |
|-------|----------|
| 🔴 **CRITICAL** | Explotable remotamente, alto impacto |
| 🟠 **HIGH** | Explotable con ciertas condiciones |
| 🟡 **MEDIUM** | Requiere acceso interno o cadena de exploits |
| 🟢 **LOW** | Best practice, bajo riesgo |
