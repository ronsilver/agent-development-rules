# OWASP Top 10:2021 - Detailed Checklist

## A01:2021 - Broken Access Control

- Enforce deny-by-default for all resources
- Implement proper RBAC or ABAC
- Disable directory listing on web servers
- Rate limit API access to minimize automated attacks
- Invalidate JWT tokens on the server after logout
- Verify ownership on every CRUD operation

## A02:2021 - Cryptographic Failures

- Use TLS 1.2+ for all data in transit
- Encrypt sensitive data at rest (AES-256)
- Never use deprecated algorithms (MD5, SHA1, DES)
- Use proper key management (never hardcode keys)
- Hash passwords with bcrypt/argon2 (cost factor >= 12)

## A03:2021 - Injection

- Use parameterized queries for all database access
- Validate and sanitize all user input
- Use ORM frameworks with built-in escaping
- Apply context-specific output encoding
- Use allowlists for permitted characters/patterns

## A04:2021 - Insecure Design

- Perform threat modeling during design phase
- Apply secure design patterns (defense in depth)
- Implement proper error handling without information leakage
- Use unit and integration tests for security controls

## A05:2021 - Security Misconfiguration

- Remove default credentials and accounts
- Disable unnecessary features, ports, and services
- Configure proper security headers (CSP, HSTS, X-Frame-Options)
- Keep all software and dependencies up to date
- Review cloud IAM permissions (least privilege)

## A06:2021 - Vulnerable and Outdated Components

- Maintain an inventory of all dependencies
- Monitor CVE databases (NVD, GitHub Security Advisories)
- Automate dependency updates with Dependabot/Renovate
- Remove unused dependencies
- Pin dependency versions in lock files

## A07:2021 - Identification and Authentication Failures

- Implement multi-factor authentication
- Enforce strong password policies
- Implement account lockout after failed attempts
- Use secure session management
- Never expose session IDs in URLs

## A08:2021 - Software and Data Integrity Failures

- Verify digital signatures on updates and deployments
- Use integrity checks (SRI) for external resources
- Secure CI/CD pipelines against tampering
- Avoid insecure deserialization of untrusted data

## A09:2021 - Security Logging and Monitoring Failures

- Log all authentication events (success and failure)
- Log all access control failures
- Ensure logs cannot be tampered with
- Never log sensitive data (passwords, tokens, PII)
- Set up alerts for suspicious activity patterns

## A10:2021 - Server-Side Request Forgery (SSRF)

- Validate and sanitize all URLs provided by users
- Use allowlists for permitted external services
- Disable unnecessary URL schemas (file://, gopher://)
- Block access to cloud metadata endpoints (169.254.169.254)
- Implement network segmentation
