# Code Review Checklist - Extended Reference

## Security: Authentication & Authorization

- [ ] Authentication required where needed
- [ ] Authorization checks before every action
- [ ] JWT validation proper (signature, expiry, audience)
- [ ] API keys and secrets not hardcoded
- [ ] Session management is secure (HttpOnly, Secure, SameSite)

## Security: Input Validation

- [ ] All user inputs validated and sanitized
- [ ] SQL queries use parameterized statements
- [ ] File uploads restricted (size, type, path traversal)
- [ ] XSS protection (escape output, CSP headers)
- [ ] No `eval()` or dynamic code execution with user input

## Security: Data Protection

- [ ] Passwords hashed with bcrypt/argon2 (not MD5/SHA1)
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS/TLS enforced for all data in transit
- [ ] PII handled according to regulations (GDPR, CCPA)
- [ ] Error messages do not leak internal details

## Security: Common Vulnerabilities

- [ ] No hardcoded credentials or secrets
- [ ] CSRF protection for state-changing operations
- [ ] Rate limiting on public endpoints
- [ ] Dependencies audited for known CVEs
- [ ] No open redirects

## Performance

- [ ] No N+1 query patterns
- [ ] Database queries are indexed
- [ ] Large collections use pagination
- [ ] No unnecessary memory allocations in loops
- [ ] Caching considered for expensive operations
- [ ] No blocking I/O in hot paths

## Reliability

- [ ] All errors are handled explicitly
- [ ] Retry logic has backoff and limits
- [ ] Timeouts set for external calls
- [ ] Circuit breakers for downstream services
- [ ] Graceful degradation paths exist

## Testing Quality

- [ ] Tests describe behavior, not implementation details
- [ ] Happy path, edge cases, and error cases covered
- [ ] Test names are clear and descriptive
- [ ] Tests are deterministic (no shared mutable state)
- [ ] Tests can run in any order independently

## Maintainability

- [ ] Functions are < 50 lines
- [ ] Nesting depth < 3 levels
- [ ] No magic numbers or strings
- [ ] Clear naming (variables, functions, classes)
- [ ] No dead code or commented-out blocks

## Architecture

- [ ] Solution fits the problem (not over-engineered)
- [ ] Consistent with existing project patterns
- [ ] New files are in the right directory structure
- [ ] No duplicate functionality (check existing utils)
- [ ] Public APIs are documented
