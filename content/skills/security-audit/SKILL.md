---
name: security-audit
description: Performs security audits on code, infrastructure, and dependencies. Use when the user asks for a security review, vulnerability scan, OWASP compliance check, or dependency audit.
license: MIT
---

# Security Audit Skill

## Goal

Identify security vulnerabilities, misconfigurations, and compliance issues in code and infrastructure. Produce actionable findings with remediation steps.

## Zero Trust & Redaction — CRITICAL

The agent **MUST NEVER** output real secrets:

| ❌ Never Output | ✅ Use Instead |
|----------------|---------------|
| `API_KEY="sk-12345abc"` | `API_KEY="<REDACTED>"` |
| `password: "myP@ssw0rd"` | `password: "********"` |
| `AKIA...` (AWS keys) | `AWS_ACCESS_KEY_ID="<REDACTED>"` |

## Workflow

### Phase 1: Reconnaissance

1. **Identify the stack**: Detect languages, frameworks, and package managers in the project.
2. **Map the attack surface**: List entry points (APIs, forms, file uploads, CLI args).
3. **Check for existing security tooling**: Look for `.bandit`, `.trivyignore`, `.gitleaksrc`, etc.

### Phase 2: Secrets Scan

Search for hardcoded secrets using pattern matching:

```bash
# Patterns to grep for (case-insensitive)
grep -rn -i "api[_-]key\|secret[_-]key\|password\s*=\|token\s*=\|private[_-]key" --include="*.{py,js,ts,go,java,rb,yaml,yml,json,env,toml}" .
```

Check for common secret file patterns:
- `.env` files committed to git (`git log --all -- '*.env'`)
- Private keys (`*.pem`, `*.key`)
- Credential files (`.aws/credentials`, `.netrc`, `kubeconfig`)

### Phase 3: Dependency Audit & SAST

Run the appropriate scanners for the detected stack:

| Stack | Dependency Audit | SAST |
|-------|-----------------|------|
| **Node.js** | `npm audit` / `yarn audit` | `eslint-plugin-security` |
| **Python** | `pip-audit` / `safety check` | `bandit -r src/` |
| **Go** | `govulncheck ./...` | `gosec ./...` |
| **Ruby** | `bundle audit check --update` | `brakeman` |
| **Rust** | `cargo audit` | `cargo clippy` |
| **Docker** | `trivy image <image>` | `hadolint Dockerfile` |
| **General** | `trivy fs .` / `grype .` | `semgrep --config=auto .` |

### Phase 4: OWASP Top 10:2021 Review

Evaluate the codebase against each category:

- [ ] **A01 - Broken Access Control**: Authorization checked on every endpoint? RBAC/ABAC enforced?
- [ ] **A02 - Cryptographic Failures**: TLS 1.2+? Secrets encrypted at rest? No deprecated algorithms?
- [ ] **A03 - Injection**: Parameterized queries? Input sanitized? No `eval()` with user data?
- [ ] **A04 - Insecure Design**: Threat model exists? Defense in depth? Rate limiting?
- [ ] **A05 - Security Misconfiguration**: No default creds? Unnecessary features disabled? Security headers set?
- [ ] **A06 - Vulnerable Components**: Dependencies audited? Lock files present? Auto-updates configured?
- [ ] **A07 - Authentication Failures**: MFA available? Account lockout? Secure session management?
- [ ] **A08 - Data Integrity Failures**: Signed deployments? SRI for external resources? Secure deserialization?
- [ ] **A09 - Logging Failures**: Auth events logged? No PII in logs? Tamper-proof logs?
- [ ] **A10 - SSRF**: User-provided URLs validated? Allowlists for external services? Metadata endpoint blocked?

### Phase 5: OWASP Remediation Patterns

#### A01 — Broken Access Control

```python
# ❌ Bad — implicit allow
def get_document(doc_id, user):
    return Document.query.get(doc_id)

# ✅ Good — explicit authorization
def get_document(doc_id, user):
    doc = Document.query.get(doc_id)
    if not doc:
        raise NotFoundError()
    if doc.owner_id != user.id and not user.has_role("admin"):
        raise ForbiddenError("Access denied")
    return doc
```

#### A02 — Cryptographic Failures

| Algorithm | Status | Parameters |
|-----------|--------|------------|
| Argon2id | ✅ Recommended | m=64MB, t=3, p=4 |
| bcrypt | ✅ Acceptable | cost ≥ 12 |
| scrypt | ✅ Acceptable | N ≥ 2^14 |
| PBKDF2-SHA256 | ⚠️ Legacy | iterations ≥ 600,000 |
| MD5, SHA1 | ❌ FORBIDDEN | Never use |

```python
# ✅ Argon2id
from argon2 import PasswordHasher
ph = PasswordHasher()
hash = ph.hash(password)
ph.verify(hash, password)

# ✅ bcrypt
import bcrypt
hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
```

#### A03 — Injection

```python
# SQL — ❌ VULNERABLE
query = f"SELECT * FROM users WHERE email = '{email}'"

# SQL — ✅ Parameterized
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))

# Command — ❌ VULNERABLE
os.system(f"convert {user_filename} output.png")

# Command — ✅ No shell
subprocess.run(["convert", user_filename, "output.png"], shell=False)
```

```javascript
// XSS — ❌ VULNERABLE
element.innerHTML = userInput;

// XSS — ✅ SAFE
element.textContent = userInput;
// Or: DOMPurify.sanitize(userInput)
```

#### A04 — Insecure Design

- Perform **threat modeling** (STRIDE) during design phase.
- Apply **defense in depth**: never rely on a single security control.
- Implement **rate limiting** on sensitive endpoints (login, password reset).
- Use **security-focused user stories**: "As a user, I cannot access another user's data."

#### A05 — Security Misconfiguration

**Required HTTP Headers:**
```python
@app.after_request
def add_security_headers(response):
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    return response
```

#### A06 — Vulnerable and Outdated Components

- Pin dependency versions in lock files (`package-lock.json`, `poetry.lock`, `go.sum`).
- Enable automated dependency updates (Dependabot, Renovate).
- Remove unused dependencies: `npx depcheck`, `pip-extra-reqs`.
- Set a maximum age for unpatched HIGH/CRITICAL vulnerabilities (e.g., 7 days).

#### A07 — Authentication Failures

```python
response.set_cookie(
    "session_id", value=session_token,
    httponly=True, secure=True, samesite="Lax",
    max_age=3600, path="/", domain=".example.com"
)
```

#### A08 — Software and Data Integrity Failures

```yaml
# ❌ Vulnerable — unpinned action
uses: actions/checkout@v4

# ✅ Secure — pinned to commit SHA
uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4
```

```bash
npm ci                    # Uses package-lock.json
pip install -r requirements.txt --require-hashes
go mod verify
```

```python
# ❌ VULNERABLE — arbitrary code execution via deserialization
import pickle
data = pickle.loads(user_input)

# ✅ SAFE — structured format with schema validation
import json
data = json.loads(user_input)
validated = MySchema.parse_obj(data)
```

#### A09 — Logging & Monitoring

**Never log:** passwords, session tokens, API keys, credit cards, SSN.

```python
# ❌ Bad
logger.info(f"User login: {username}, password: {password}")

# ✅ Good
logger.info(f"User login: {username}")
```

#### A10 — SSRF

```python
# ✅ Allowlist approach (preferred over blocklist)
ALLOWED_DOMAINS = {"api.example.com", "cdn.example.com"}

def fetch_url(user_url: str) -> bytes:
    parsed = urlparse(user_url)
    if parsed.hostname not in ALLOWED_DOMAINS:
        raise SecurityError(f"Domain not allowed: {parsed.hostname}")
    return requests.get(user_url, allow_redirects=False, timeout=5).content
```

### Phase 6: Input Validation

```python
# Python with Pydantic
from pydantic import BaseModel, EmailStr, constr, Field

class UserCreate(BaseModel):
    email: EmailStr
    name: constr(min_length=1, max_length=100)
    age: int = Field(ge=0, le=150)
```

```typescript
// TypeScript with Zod
import { z } from 'zod';

const UserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150),
});
```

### Phase 7: Infrastructure Review (if applicable)

- **Terraform/IaC**: Run `tflint`, `checkov -d .`, `trivy config .`
- **Docker**: Run `hadolint Dockerfile`, check for `USER root`, exposed ports
- **Kubernetes**: Check `SecurityContext`, `NetworkPolicy`, no `privileged: true`
- **Cloud (AWS/GCP/Azure)**: Check IAM policies, S3/GCS bucket ACLs, security groups

### Phase 8: Generate Report

```markdown
# Security Audit Report

**Date**: YYYY-MM-DD
**Auditor**: AI Security Audit Skill
**Scope**: [files/modules/services audited]
**Stack**: [detected languages and frameworks]

## Executive Summary
[2-3 sentences: overall risk posture and most critical findings]

## 🔴 Critical (Exploit risk: immediate)
| # | Finding | Location | CWE | Remediation |
|---|---------|----------|-----|-------------|
| 1 | [issue] | [file:line] | CWE-XXX | [fix] |

## 🟠 High (Exploit risk: likely)
| # | Finding | Location | CWE | Remediation |
|---|---------|----------|-----|-------------|
| 1 | [issue] | [file:line] | CWE-XXX | [fix] |

## 🟡 Medium (Exploit risk: possible)
| # | Finding | Location | CWE | Remediation |
|---|---------|----------|-----|-------------|
| 1 | [issue] | [file:line] | CWE-XXX | [fix] |

## 🔵 Low / Informational
- [issue]: [description]

## Dependency Vulnerabilities
[Output from npm audit / pip-audit / govulncheck]

## Recommendations
1. **Immediate** (this sprint): [critical fixes]
2. **Short-term** (this quarter): [high-priority improvements]
3. **Long-term** (roadmap): [architectural security improvements]
```

## Constraints

- **NEVER** output real secrets found during audit — use `<REDACTED>`.
- **ALWAYS** provide remediation steps, not just findings.
- **ALWAYS** reference CWE identifiers when applicable.
- Prioritize findings by **actual exploitability**, not theoretical risk.
- Run verification commands when possible — do not guess at vulnerability presence.
