---
name: Security
description: Analyze code for security vulnerabilities based on OWASP and CWE
trigger: manual
tags: [security, analysis, owasp, vulnerability]
skill: security-audit
---

# Security Check

Analyze code for security vulnerabilities based on **OWASP Top 10** and **CWE Top 25**. Apply the **security-audit** skill for the full workflow, OWASP remediation patterns, and tooling commands.

## Severity Classification

| Severity | CVSS | Examples | SLA |
|----------|------|----------|-----|
| 🔴 CRITICAL | 9.0-10.0 | RCE, Auth bypass, SQL injection | Fix immediately |
| 🟠 HIGH | 7.0-8.9 | XSS, SSRF, Sensitive data exposure | Fix within 7 days |
| 🟡 MEDIUM | 4.0-6.9 | CSRF, Information disclosure | Fix within 30 days |
| 🟢 LOW | 0.1-3.9 | Minor info leak, Clickjacking | Fix within 90 days |

## Report Format

~~~markdown
## 🔴 [CRITICAL] SQL Injection in User Authentication

**File:** `src/auth/login.py:47`
**CWE:** CWE-89 (SQL Injection)
**CVSS:** 9.8 (Critical)

**Vulnerability:**
[Description of the issue]

**Vulnerable Code:**
```python
query = f"SELECT * FROM users WHERE email = '{email}'"
```

**Proof of Concept:**
```
email: ' OR '1'='1' --
```

**Impact:**
- [List of impacts]

**Remediation:**
```python
query = "SELECT * FROM users WHERE email = %s"
cursor.execute(query, (email,))
```

**References:**
- https://owasp.org/Top10/A03_2021-Injection/
- https://cwe.mitre.org/data/definitions/89.html
~~~

## Instructions

1. **Scan** for hardcoded secrets and credentials first
2. **Check** all user input paths for injection vulnerabilities
3. **Verify** authentication and session security configuration
4. **Audit** logging for sensitive data exposure
5. **Review** security headers and CORS configuration
6. **Inspect** dependencies for known vulnerabilities
7. **Report** findings using severity classification and format above
