# Security Check

Analyze code for security vulnerabilities.

## Analysis Categories

### 1. Secrets & Credentials
**Search for:**
- Hardcoded API Keys/Tokens.
- Passwords in code.
- Connection strings with credentials.
- Private keys / Certificates.

**Regex Patterns:**
```regex
password\s*=\s*["'][^"']+["']
api[_-]?key\s*=\s*["'][^"']+["']
Authorization:\s*Bearer\s+[A-Za-z0-9-_]+
```

### 2. Input Validation
**Vulnerabilities:**
- SQL Injection.
- XSS (Cross-Site Scripting).
- Command Injection.
- Path Traversal.
- SSRF.

**Verify:**
- Sanitized user inputs.
- Parameterized queries (NO concatenation).
- Output encoding/escaping.
- URL/Path validation.

### 3. Authentication & Authorization
- Hashed passwords (bcrypt/argon2).
- Token expiration.
- Rate limiting on sensitive endpoints.
- Permission checks on EVERY request.

### 4. Sensitive Data
- NO sensitive data in logs (PII, tokens).
- Encryption at rest.
- HTTPS everywhere.
- Security Headers (HSTS, CSP).

### 5. Supply Chain
```bash
# Audit commands
npm audit              # Node
pip-audit              # Python
govulncheck ./...      # Go
trivy fs .             # General
```

## Report Format

```markdown
## [🔴 CRITICAL] Title

**File:** path/to/file:Line
**CWE:** CWE-XXX

**Vulnerability:**
Description.

**Impact:**
What happens if exploited?

**Remediation:**
How to fix (code example).
```
