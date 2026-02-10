---
name: Document
description: Generate comprehensive documentation focusing on Why over What
version: "1.0"
trigger: manual
tags:
  - documentation
  - generation
  - readme
  - api-docs
---

# Document

Generate comprehensive documentation for the selected code or project. Focus on **"Why"** over **"What"**.

## Documentation Types

### 1. Code Comments (Docstrings)

**When to Document:**
| Scenario | Example |
|----------|---------|
| Non-obvious business logic | Tax calculation rules |
| Design decisions | Why we chose Strategy over Factory |
| Workarounds | Link to issue/ticket |
| Public APIs | Parameters, returns, exceptions |
| Complex algorithms | Time/space complexity |
| Security considerations | Why input is sanitized here |

**When NOT to Document:**
- Self-explanatory code
- Trivial getters/setters
- Comments that repeat the code
- Implementation details that may change

```python
# ❌ Bad - repeats code
# Increment counter by 1
counter += 1

# ❌ Bad - obvious
# Loop through users
for user in users:

# ✅ Good - explains WHY
# Skip first 2 rows: header + metadata per CSV spec v2.1
start_row = 2

# ✅ Good - documents edge case
# Handle legacy accounts created before 2020 migration
# which may have null email addresses (see JIRA-1234)
if user.email is None:
```

### 2. Docstring Formats by Language

#### Python (Google Style)
```python
def calculate_discount(user: User, amount: float) -> float:
    """Calculate discount based on user tier and purchase amount.

    Applies tiered discount rates based on user membership level.
    Premium users get 10%, standard users get 5%.

    Args:
        user: The user making the purchase.
        amount: The purchase amount before discount.

    Returns:
        The discounted amount.

    Raises:
        ValueError: If amount is negative.

    Example:
        >>> calculate_discount(premium_user, 100.0)
        90.0
    """
```

#### Go (GoDoc)
```go
// CalculateDiscount returns the discounted amount based on user tier.
//
// Premium users receive 10% discount, standard users receive 5%.
// Returns an error if amount is negative.
//
// Example:
//
//	discounted, err := CalculateDiscount(user, 100.0)
//	if err != nil {
//	    log.Fatal(err)
//	}
func CalculateDiscount(user *User, amount float64) (float64, error) {
```

#### TypeScript (TSDoc)
```typescript
/**
 * Calculates discount based on user tier and purchase amount.
 *
 * @param user - The user making the purchase
 * @param amount - The purchase amount before discount
 * @returns The discounted amount
 * @throws {Error} If amount is negative
 *
 * @example
 * ```typescript
 * const discounted = calculateDiscount(premiumUser, 100);
 * // Returns 90
 * ```
 */
function calculateDiscount(user: User, amount: number): number {
```

### 3. README Standard

~~~markdown
# Project Name

Brief description of what this project does and why it exists.

## Features

- Feature 1: Description
- Feature 2: Description

## Requirements

- Node.js >= 20
- PostgreSQL >= 15

## Installation

```bash
npm install
cp .env.example .env
npm run db:migrate
```

## Usage

```bash
# Development
npm run dev

# Production
npm run build && npm start
```

## Configuration

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Yes | - |
| `PORT` | Server port | No | `3000` |
| `LOG_LEVEL` | Logging verbosity | No | `info` |

## API Reference

See [API Documentation](./docs/api.md) for detailed endpoint documentation.

## Development

```bash
# Run tests
npm test

# Run linter
npm run lint

# Generate docs
npm run docs
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

MIT
~~~

### 4. ADR (Architecture Decision Record)

Structure: **Status → Context → Decision → Consequences (Positive/Negative) → Alternatives Considered**

Key rules:
- One decision per ADR, numbered sequentially (`ADR-001`, `ADR-002`)
- Include alternatives considered with pros/cons table
- Status: `Proposed`, `Accepted`, `Deprecated`, `Superseded`

### 5. API Documentation

Structure per endpoint: **Method + Path → Authentication → Request (Headers, Body, Constraints) → Responses (Success + Error codes with examples)**

Key rules:
- Include all response codes (2xx, 4xx, 5xx) with JSON examples
- Document required vs optional fields with constraints
- Include `X-Request-ID` for tracing correlation

### 6. CHANGELOG (Keep a Changelog)

Follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) + [Semantic Versioning](https://semver.org/):
- Sections: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`
- Keep `[Unreleased]` section at top
- Reference issue/PR numbers

## Documentation Tools

| Project Type | Tool | Command |
|-------------|------|---------|
| Terraform | terraform-docs | `terraform-docs markdown table .` |
| Go | godoc / pkgsite | `go doc -all` |
| Python | Sphinx / mkdocs | `mkdocs serve` |
| TypeScript | TypeDoc | `npx typedoc` |
| OpenAPI | Swagger / Redoc | `npx @redocly/cli build-docs` |

## When to Update Documentation

| Event | Action |
|-------|--------|
| New feature | Add to README, API docs, CHANGELOG |
| Breaking change | Update migration guide, bump major version |
| Bug fix | Add to CHANGELOG |
| Architectural change | Create/update ADR |
| Configuration change | Update README Configuration section |

## Instructions

1. **Analyze** existing documentation style in the project
2. **Match** the format and voice of existing docs
3. **Document** the "Why", not just the "What"
4. **Include** practical examples that can be copy-pasted
5. **Verify** accuracy of any code examples
6. **Update** related docs (README, CHANGELOG) if needed
