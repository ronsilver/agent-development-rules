---
trigger: glob
globs: ["*.py", "*.js", "*.ts", "*.go", "*.java", "*.php", "*.rb", "*.cs"]
---

# Security OWASP Top 10:2025 - Best Practices

Rules based on **OWASP Top 10 2025** and OWASP ASVS.

## 0. Zero Trust & Redaction - CRITICAL

- **Self-Redaction**: The agent **MUST NEVER** output real secrets.
    - ❌ `API_KEY="sk-12345"`
    - ✅ `API_KEY="<REDACTED>"`
- **Pre-Check**: Verify output for leaks before sending.

## Security Tooling - MANDATORY

Run before PR:
```bash
gitleaks detect -v
trivy fs .
bandit -r .  # Python
govulncheck ./... # Go
npm audit # Node
```

## A01:2025 - Broken Access Control
- **Deny by default**.
- **Server-side validation** for every request.
- **SSRF Prevention**: Block internal networks (10.0.0.0/8, 169.254.169.254, etc.).

## A02:2025 - Security Misconfiguration
- Debug mode **DISABLED** in prod.
- HTTP Security Headers enabled (HSTS, CSP, X-Frame-Options).
- Change default credentials immediately.

## A03:2025 - Supply Chain Failures
- **Pin Actions by SHA**: `uses: actions/checkout@b4ff...`
- **Scan Dependencies**: Use `pip-audit`, `npm audit`, `trivy`.
- **SBOM**: Generate Software Bill of Materials.

## A04:2025 - Cryptographic Failures
- **Passwords**: Use Argon2id or bcrypt. NEVER MD5/SHA1.
- **Encryption**: AES-256-GCM / ChaCha20-Poly1305.
- **TLS**: version 1.2 or 1.3 only.

## A05:2025 - Injection
- **SQL**: Use Parameterized Queries (Prepared Statements) or ORM.
- **Command**: Avoid `shell=True`. Use list args.
- **Input**: Validate ALL input with strict schemas (e.g., Pydantic, Zod).

## A07:2025 - Authentication Failures
- Enforce MFA.
- Session Management: `HttpOnly`, `Secure`, `SameSite=Lax`.
- No weak passwords (enforce complexity).

## A09:2025 - Logging & Monitoring
- **Log Security Events**: Login success/fail, access denied.
- **Sanitize Logs**: No PII, no Secrets in logs.

## Code Review Checklist
- [ ] Input validation on all endpoints?
- [ ] Parameterized queries used?
- [ ] Access control checks server-side?
- [ ] Secrets removed/redacted?
