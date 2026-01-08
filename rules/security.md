---
trigger: glob
globs: ["*.py", "*.js", "*.ts", "*.go", "*.java", "*.php", "*.rb", "*.cs"]
---

# Seguridad OWASP Top 10:2025 - Best Practices

Reglas basadas en **OWASP Top 10 2025**, OWASP ASVS y OWASP Cheat Sheets.

## OWASP Top 10:2025 - Resumen

| # | Categoría | Cambio vs 2021 |
|---|-----------|----------------|
| A01 | Broken Access Control | = (incluye SSRF) |
| A02 | Security Misconfiguration | ↑ subió de #5 |
| A03 | Software Supply Chain Failures | **NUEVO** |
| A04 | Cryptographic Failures | ↓ bajó de #2 |
| A05 | Injection | ↓ bajó de #3 |
| A06 | Insecure Design | ↓ bajó de #4 |
| A07 | Authentication Failures | = |
| A08 | Software or Data Integrity Failures | = |
| A09 | Security Logging and Alerting Failures | = (renombrado) |
| A10 | Mishandling of Exceptional Conditions | **NUEVO** |

---

## A01:2025 - Broken Access Control

### Principios
- Denegar por defecto, excepto recursos públicos
- Implementar control de acceso una vez y reutilizar
- Validar permisos en cada request (server-side)
- Deshabilitar directory listing
- **SSRF ahora incluido en esta categoría**

### Patrones Seguros

```python
# ✅ Correcto - Verificar ownership
def get_document(user_id: int, document_id: int) -> Document:
    document = db.get_document(document_id)
    if document.owner_id != user_id:
        raise PermissionDeniedError("Access denied")
    return document

# ❌ Vulnerable - IDOR (Insecure Direct Object Reference)
def get_document(document_id: int) -> Document:
    return db.get_document(document_id)  # No verifica ownership
```

```typescript
// ✅ Middleware de autorización
async function requireOwnership(req: Request, res: Response, next: NextFunction) {
  const resource = await getResource(req.params.id);
  if (resource.ownerId !== req.user.id && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  req.resource = resource;
  next();
}

// ✅ RBAC (Role-Based Access Control)
const permissions = {
  admin: ['read', 'write', 'delete', 'manage_users'],
  editor: ['read', 'write'],
  viewer: ['read'],
};

function hasPermission(role: string, action: string): boolean {
  return permissions[role]?.includes(action) ?? false;
}
```

### SSRF Prevention (ahora parte de A01)

```python
import ipaddress
from urllib.parse import urlparse

BLOCKED_NETWORKS = [
    ipaddress.ip_network('10.0.0.0/8'),
    ipaddress.ip_network('172.16.0.0/12'),
    ipaddress.ip_network('192.168.0.0/16'),
    ipaddress.ip_network('127.0.0.0/8'),
    ipaddress.ip_network('169.254.169.254/32'),  # Cloud metadata
]

def is_safe_url(url: str) -> bool:
    try:
        parsed = urlparse(url)
        if parsed.scheme not in ('http', 'https'):
            return False
        
        import socket
        ip = socket.gethostbyname(parsed.hostname)
        ip_obj = ipaddress.ip_address(ip)
        
        return not any(ip_obj in network for network in BLOCKED_NETWORKS)
    except Exception:
        return False
```

### Anti-Patrones
- Confiar en IDs secuenciales para seguridad
- Validar permisos solo en frontend
- Exponer funciones admin sin autenticación
- URLs "secretas" como control de acceso

---

## A02:2025 - Security Misconfiguration

### Principios (subió a #2 en 2025)
- Debug mode deshabilitado en producción
- Stack traces no expuestos a usuarios
- Headers de seguridad configurados
- Credenciales por defecto cambiadas

### Configuración Segura

```python
# ✅ Flask - Configuración segura
app = Flask(__name__)
app.config.update(
    SECRET_KEY=os.environ['SECRET_KEY'],
    SESSION_COOKIE_SECURE=True,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE='Lax',
    PERMANENT_SESSION_LIFETIME=timedelta(hours=1),
)

if os.environ.get('ENVIRONMENT') == 'production':
    app.debug = False
```

```typescript
// ✅ Express - Headers de seguridad
import helmet from 'helmet';

app.use(helmet());
app.disable('x-powered-by');
```

### HTTP Security Headers - OBLIGATORIO

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), camera=(), microphone=()
```

### Checklist
- [ ] Debug mode deshabilitado en producción
- [ ] Stack traces no expuestos a usuarios
- [ ] Headers de seguridad configurados
- [ ] Servicios innecesarios deshabilitados
- [ ] Credenciales por defecto cambiadas
- [ ] Software actualizado (patches de seguridad)

---

## A03:2025 - Software Supply Chain Failures (NUEVO)

### Principios
- **Nueva categoría en 2025** - Expandido de "Vulnerable Components"
- Gestión integral de dependencias
- Verificación de integridad de artefactos
- Seguridad en CI/CD pipelines

### Gestión de Dependencias

```bash
# Verificar vulnerabilidades
npm audit                    # Node.js
pip-audit                    # Python
go vuln check ./...          # Go
trivy fs .                   # General
grype .                      # Container/filesystem

# SBOM (Software Bill of Materials)
syft . -o spdx-json > sbom.json
```

### CI/CD Security - CRÍTICO

```yaml
# ✅ GitHub Actions - Pinear por SHA (no tags)
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
- uses: actions/setup-node@60edb5dd545a775178f52524783378180af0d1f8  # v4.0.2

# ❌ Vulnerable - Tags mutables
- uses: actions/checkout@v4       # Puede cambiar
- uses: actions/checkout@main     # Muy peligroso
```

### Verificación de Integridad

```python
# ✅ Verificar checksums de descargas
import hashlib

def verify_integrity(filepath: str, expected_hash: str) -> bool:
    sha256 = hashlib.sha256()
    with open(filepath, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    return sha256.hexdigest() == expected_hash
```

### Dependabot/Renovate - OBLIGATORIO

```yaml
# dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Políticas
- Eliminar dependencias no utilizadas
- Usar versiones específicas (no rangos amplios)
- Revisar changelogs antes de actualizar majors
- Mantener inventario de dependencias (SBOM)
- Firmar commits y releases

---

## A04:2025 - Cryptographic Failures

### Algoritmos Recomendados

| Propósito | Algoritmo | Evitar |
|-----------|-----------|--------|
| Passwords | Argon2id, bcrypt, scrypt | MD5, SHA1, SHA256 sin salt |
| Cifrado simétrico | AES-256-GCM | DES, 3DES, RC4, ECB mode |
| Cifrado asimétrico | RSA-2048+, Ed25519 | RSA-1024 |
| Hashing | SHA-256, SHA-3, BLAKE3 | MD5, SHA1 |
| TLS | TLS 1.3, TLS 1.2 | TLS 1.0, TLS 1.1, SSL |

### Patrones Seguros

```python
# ✅ Password hashing con bcrypt
import bcrypt

def hash_password(password: str) -> bytes:
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password.encode('utf-8'), salt)

def verify_password(password: str, hashed: bytes) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed)
```

```go
// ✅ Password hashing en Go
import "golang.org/x/crypto/bcrypt"

func HashPassword(password string) (string, error) {
    bytes, err := bcrypt.GenerateFromPassword([]byte(password), 12)
    return string(bytes), err
}
```

### Nunca Hacer
- Implementar algoritmos criptográficos propios
- Hardcodear claves de cifrado
- Usar MD5/SHA1 para passwords
- Deshabilitar validación de certificados

---

## A05:2025 - Injection

### SQL Injection - Prevención

```python
# ✅ Queries parametrizadas
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# ✅ ORM
user = session.query(User).filter(User.id == user_id).first()

# ❌ Vulnerable
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

### Command Injection - Prevención

```python
# ✅ Lista de argumentos, shell=False
subprocess.run(['ls', '-la', filename], shell=False)

# ❌ Vulnerable
subprocess.run(f"ls -la {filename}", shell=True)
```

### XSS Prevention

```python
# ✅ Escapar output
from markupsafe import escape
return escape(user_input)

# ✅ Content Security Policy
CSP_HEADER = "default-src 'self'; script-src 'self'"
```

### Validación de Input

```python
from pydantic import BaseModel, Field, field_validator
import re

class UserInput(BaseModel):
    username: str = Field(..., min_length=3, max_length=30)
    email: str = Field(..., pattern=r'^[\w.-]+@[\w.-]+\.\w+$')
    
    @field_validator('username')
    @classmethod
    def validate_username(cls, v: str) -> str:
        if not re.match(r'^[a-zA-Z0-9_]+$', v):
            raise ValueError('Username must be alphanumeric')
        return v
```

---

## A06:2025 - Insecure Design

### Principios de Diseño Seguro
- Threat modeling desde el inicio
- Principio de menor privilegio
- Defense in depth (múltiples capas)
- Fail securely (fallar de forma segura)

### Patrones Seguros

```python
# ✅ Rate limiting
from functools import wraps

def rate_limit(max_requests: int, window_seconds: int):
    def decorator(func):
        @wraps(func)
        def wrapper(user_id: str, *args, **kwargs):
            if is_rate_limited(user_id, max_requests, window_seconds):
                raise RateLimitExceeded("Too many requests")
            return func(user_id, *args, **kwargs)
        return wrapper
    return decorator

# ✅ Límites de negocio
class TransferService:
    MAX_DAILY_TRANSFER = 10000
    MAX_SINGLE_TRANSFER = 5000
    
    def transfer(self, amount: float):
        if amount > self.MAX_SINGLE_TRANSFER:
            raise ValueError("Exceeds single transfer limit")
```

### Checklist de Diseño Seguro
- [ ] ¿Qué datos sensibles maneja el sistema?
- [ ] ¿Quién debe tener acceso a qué?
- [ ] ¿Qué pasa si un componente falla?
- [ ] ¿Hay rate limiting en endpoints críticos?

---

## A07:2025 - Authentication Failures

### Autenticación Segura

```python
# ✅ Validación de password robusta
import re

def validate_password(password: str) -> list[str]:
    errors = []
    if len(password) < 12:
        errors.append("Password must be at least 12 characters")
    if not re.search(r'[A-Z]', password):
        errors.append("Must contain uppercase letter")
    if not re.search(r'[a-z]', password):
        errors.append("Must contain lowercase letter")
    if not re.search(r'\d', password):
        errors.append("Must contain digit")
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        errors.append("Must contain special character")
    return errors
```

### Session Management

```python
SESSION_CONFIG = {
    'cookie_name': '__Host-session',
    'secure': True,
    'httponly': True,
    'samesite': 'Lax',
    'max_age': 3600,
}

# Regenerar session ID después de login
def login(user: User, session: Session):
    session.regenerate_id()
    session['user_id'] = user.id
```

### JWT Best Practices

```typescript
// ✅ Validación segura
jwt.verify(token, PUBLIC_KEY, {
  algorithms: ['RS256'],  // Especificar explícitamente
  issuer: 'myapp',
  audience: 'myapp-api',
});

// ❌ Vulnerable
jwt.verify(token, secret);  // Vulnerable a alg:none
```

### MFA

```python
import pyotp

def verify_totp(secret: str, code: str) -> bool:
    totp = pyotp.TOTP(secret)
    return totp.verify(code, valid_window=1)
```

---

## A08:2025 - Software or Data Integrity Failures

### Integridad de Datos

```python
import hmac
import hashlib

def sign_data(data: bytes, key: bytes) -> str:
    return hmac.new(key, data, hashlib.sha256).hexdigest()

def verify_signature(data: bytes, signature: str, key: bytes) -> bool:
    expected = hmac.new(key, data, hashlib.sha256).hexdigest()
    return hmac.compare_digest(signature, expected)
```

### Deserialization Segura

```python
# ✅ JSON para datos no confiables
import json
data = json.loads(user_input)

# ❌ NUNCA pickle con datos no confiables
import pickle
data = pickle.loads(user_input)  # RCE vulnerability!
```

---

## A09:2025 - Security Logging and Alerting Failures

### Logging Seguro

```python
import logging
import json
from datetime import datetime

class SecurityLogger:
    SENSITIVE_KEYS = {'password', 'token', 'secret', 'api_key', 'credit_card'}
    
    def log_event(self, event_type: str, details: dict, user_id: str = None):
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': event_type,
            'user_id': user_id,
            'details': self._sanitize(details),
        }
        logging.info(json.dumps(log_entry))
    
    def _sanitize(self, data: dict) -> dict:
        return {
            k: '[REDACTED]' if k.lower() in self.SENSITIVE_KEYS else v
            for k, v in data.items()
        }

# Eventos a loggear
security_log.log_event('LOGIN_SUCCESS', {'ip': ip}, user.id)
security_log.log_event('LOGIN_FAILED', {'ip': ip, 'username': username})
security_log.log_event('PERMISSION_DENIED', {'resource': id}, user.id)
```

### Eventos a Monitorear

| Evento | Severidad | Acción |
|--------|-----------|--------|
| Login fallido repetido | HIGH | Alerta + bloqueo temporal |
| Acceso denegado repetido | MEDIUM | Investigar |
| Cambio de password/email | INFO | Notificar usuario |
| Escalación de privilegios | CRITICAL | Alerta inmediata |

### No Loggear
- Passwords (ni hasheados)
- Tokens de sesión/API
- Números de tarjeta de crédito
- PII sin enmascarar

---

## A10:2025 - Mishandling of Exceptional Conditions (NUEVO)

### Principios
- **Nueva categoría en 2025**
- Manejar todas las excepciones apropiadamente
- No exponer información sensible en errores
- Fail securely - estado seguro ante fallos

### Manejo Correcto de Excepciones

```python
# ✅ Correcto - Manejo específico y seguro
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    # Log interno con detalles
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    
    # Respuesta genérica al usuario
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "request_id": request.id}
    )

# ✅ Manejo específico por tipo
try:
    result = process_payment(order)
except PaymentDeclinedError as e:
    logger.warning(f"Payment declined: {e.reason}")
    return {"error": "Payment declined", "code": "PAYMENT_DECLINED"}
except ExternalServiceError as e:
    logger.error(f"External service failed: {e}")
    return {"error": "Service temporarily unavailable"}
except Exception as e:
    logger.critical(f"Unexpected error: {e}", exc_info=True)
    return {"error": "Internal error"}
```

```python
# ❌ Incorrecto - Expone información
@app.exception_handler(Exception)
async def bad_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={
            "error": str(exc),           # Expone detalles internos
            "traceback": traceback.format_exc(),  # MUY peligroso
            "query": request.query_params,  # Puede contener secrets
        }
    )
```

### Fail Secure Pattern

```python
# ✅ Fail secure - denegar en caso de error
def check_permission(user_id: str, resource_id: str) -> bool:
    try:
        return permission_service.check(user_id, resource_id)
    except Exception as e:
        logger.error(f"Permission check failed: {e}")
        return False  # Denegar por defecto

# ❌ Fail open - peligroso
def check_permission_bad(user_id: str, resource_id: str) -> bool:
    try:
        return permission_service.check(user_id, resource_id)
    except Exception:
        return True  # Permite acceso si falla!
```

### Resource Cleanup

```python
# ✅ Siempre limpiar recursos
def process_file(filepath: str):
    file = None
    try:
        file = open(filepath, 'r')
        return process(file.read())
    except FileNotFoundError:
        raise NotFoundError(f"File not found")
    except PermissionError:
        raise ForbiddenError("Access denied")
    finally:
        if file:
            file.close()

# ✅ Mejor - Context manager
def process_file(filepath: str):
    with open(filepath, 'r') as file:
        return process(file.read())
```

### Checklist
- [ ] Todas las excepciones manejadas
- [ ] Errores no exponen información interna
- [ ] Stack traces solo en logs, no en responses
- [ ] Fail secure (denegar por defecto)
- [ ] Recursos siempre liberados (finally/context managers)
- [ ] Errores loggeados con contexto suficiente

---

## CSRF (Cross-Site Request Forgery)

```python
# ✅ Token CSRF + SameSite cookies
from secrets import token_urlsafe

def generate_csrf_token() -> str:
    return token_urlsafe(32)

response.set_cookie(
    'session',
    value=session_id,
    httponly=True,
    secure=True,
    samesite='Lax',
)
```

---

## Herramientas de Análisis

```bash
# SAST (Static Analysis)
semgrep --config=auto .
bandit -r src/              # Python
gosec ./...                 # Go

# Secrets Detection
gitleaks detect
trufflehog git file://.

# Dependency Scanning
npm audit / pip-audit / go vuln check
trivy fs .
grype .

# Container Security
trivy image myapp:latest

# Infrastructure
checkov -d .
tfsec .
```

---

## Checklist de Seguridad

### Pre-Deployment
- [ ] Secrets en variables de entorno, no en código
- [ ] Dependencias escaneadas (A03)
- [ ] HTTPS con TLS 1.2+ (A04)
- [ ] Headers de seguridad (A02)
- [ ] Rate limiting (A06)
- [ ] Logging de eventos de seguridad (A09)

### Code Review
- [ ] Input validation en todos los endpoints (A05)
- [ ] Queries parametrizadas (A05)
- [ ] Control de acceso server-side (A01)
- [ ] Errores no exponen información (A10)
- [ ] Passwords hasheados con bcrypt/argon2 (A04)
- [ ] Excepciones manejadas correctamente (A10)
