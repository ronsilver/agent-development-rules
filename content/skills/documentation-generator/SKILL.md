---
name: documentation-generator
description: Generate and maintain project documentation including READMEs, CHANGELOGs, ADRs, docstrings, and architecture diagrams. Use when the user asks to document code, write a README, create an ADR, or improve documentation.
license: MIT
---

# Documentation Generator

## Core Principle

**Document the "Why", not the "What"** — code shows what happens; docs explain why.

## Workflow

### Step 1: Detect Documentation Needs

| What exists? | Action |
|-------------|--------|
| No README | Create one with standard sections |
| No CHANGELOG | Create one following Keep a Changelog |
| No docstrings on public API | Add them |
| Complex design decision | Create an ADR |

### Step 2: Auto-Generate Where Possible

| Language/Tool | Documentation Tool | Command |
|--------------|-------------------|---------|
| Terraform | terraform-docs | `terraform-docs markdown table .` |
| Go | godoc / pkgsite | `go doc -all ./...` |
| Python | mkdocs / Sphinx | `mkdocs serve` |
| TypeScript | TypeDoc | `npx typedoc src/` |
| API | OpenAPI / Swagger | Generate from code annotations |

### Step 3: README Standard

Every project MUST have these sections:

~~~markdown
# Project Name

Brief description (1-2 sentences).

## Features
- Feature 1
- Feature 2

## Requirements
- Runtime: Node.js >= 20
- Database: PostgreSQL >= 15

## Quick Start

```bash
# Install
npm install

# Configure
cp .env.example .env

# Run
npm run dev
```

## Configuration

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `DATABASE_URL` | PostgreSQL connection | Yes | - |
| `PORT` | Server port | No | `3000` |

## Development

```bash
npm run lint    # Lint code
npm test        # Run tests
npm run build   # Build for production
```

## API Reference

See [API Documentation](./docs/api.md).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT
~~~

### Step 4: CHANGELOG (Keep a Changelog)

Follow [Keep a Changelog](https://keepachangelog.com/) + [Semantic Versioning](https://semver.org/):

```markdown
# Changelog

## [Unreleased]
### Added
- New feature in progress

## [2.1.0] - 2024-01-15
### Added
- User authentication via OAuth2 (#123)

### Changed
- Improved error messages for validation

### Fixed
- Memory leak in connection pool (#124)

### Security
- Updated dependencies to patch known vulnerability

## [2.0.0] - 2024-01-01
### Changed
- **BREAKING**: Renamed `userId` to `user_id` in API responses

### Removed
- Deprecated `v1` API endpoints
```

**Categories:** Added, Changed, Deprecated, Removed, Fixed, Security.

### Step 5: Architecture Decision Records (ADR)

For significant decisions, create `docs/adr/ADR-NNN-title.md`:

```markdown
# ADR-001: Use PostgreSQL for Primary Database

## Status
Accepted | Superseded by ADR-XXX | Deprecated

## Context
What is the issue or decision we need to make?

## Decision
What is our choice?

## Consequences
What are the positive and negative outcomes?

## Alternatives Considered
| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| PostgreSQL | ACID, JSON support | Scaling | ✅ Chosen |
| MongoDB | Flexible schema | No ACID | ❌ Rejected |
```

**Store in:** `docs/adr/` or `docs/decisions/`

## Docstring Standards

### Python (Google Style)
```python
def process_order(order: Order, user: User) -> OrderResult:
    """Process an order for the given user.

    Validates inventory, applies discounts, and creates payment intent.

    Args:
        order: The order to process.
        user: The user placing the order.

    Returns:
        OrderResult with status and payment details.

    Raises:
        InsufficientInventoryError: If items are out of stock.
        PaymentFailedError: If payment processing fails.

    Example:
        >>> result = process_order(order, user)
        >>> print(result.status)
        'completed'
    """
```

### Go (GoDoc)
```go
// ProcessOrder processes an order for the given user.
//
// It validates inventory, applies discounts, and creates a payment intent.
// Returns an error if inventory is insufficient or payment fails.
//
// Example:
//
//	result, err := ProcessOrder(ctx, order, user)
//	if err != nil {
//	    return fmt.Errorf("order processing failed: %w", err)
//	}
func ProcessOrder(ctx context.Context, order *Order, user *User) (*OrderResult, error) {
```

### TypeScript (TSDoc)
```typescript
/**
 * Processes an order for the given user.
 *
 * @param order - The order to process
 * @param user - The user placing the order
 * @returns Promise resolving to OrderResult with status and payment details
 * @throws {InsufficientInventoryError} If items are out of stock
 * @throws {PaymentFailedError} If payment processing fails
 *
 * @example
 * ```typescript
 * const result = await processOrder(order, user);
 * console.log(result.status); // 'completed'
 * ```
 */
```

## Code Comments — When to Document

| ✅ Document | ❌ Don't Document |
|------------|------------------|
| Non-obvious business logic | Self-explanatory code |
| Design decisions and trade-offs | Trivial getters/setters |
| Workarounds (link to ticket) | Implementation details that may change |
| Complex algorithms (Big-O) | Code that repeats itself |
| Security considerations | Obvious operations |

```python
# ❌ Bad — states the obvious
# Increment counter by 1
counter += 1

# ✅ Good — explains WHY
# Skip first 2 rows: header + metadata per CSV spec v2.1
start_row = 2
```

## Diagrams as Code (Mermaid)

```markdown
graph LR
    A[Client] --> B[API Gateway]
    B --> C[Auth Service]
    B --> D[Order Service]
    D --> E[(PostgreSQL)]
```

## Checklist

- [ ] README exists with all standard sections
- [ ] CHANGELOG maintained for versioned projects
- [ ] Public APIs have docstrings
- [ ] Complex logic has explanatory comments
- [ ] Architecture decisions documented (ADR)
- [ ] Configuration options documented
- [ ] Examples provided for common use cases

## Constraints

- **NEVER** document the obvious — focus on the "why."
- **ALWAYS** auto-generate where tools exist (terraform-docs, typedoc, etc.).
- **ALWAYS** follow the language's standard docstring format.
- Keep docs close to the code they describe (co-located, not in a separate wiki).
