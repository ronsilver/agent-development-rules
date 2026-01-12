# Document

Generate comprehensive documentation for the selected code or project.

## Documentation Types

### 1. Code Comments (Docstrings)

**When to Document:**
- Non-obvious business logic.
- Design decisions and "Why" (not just "What").
- Workarounds for specific issues (link to tickets).
- Public APIs.
- Complex algorithms.

**When NOT to Document:**
- Self-explanatory code.
- Trivial getters/setters.
- Comments that merely repeat the code.

```python
# ❌ Bad - repeats code
# Increment counter
counter += 1

# ✅ Good - explains why
# Skip header rows per CSV spec v2.1
counter += 2
```

### 2. README Standard

Recommended structure:

```markdown
# Project Name

One-liner description.

## Requirements
- Dependencies
- Supported versions

## Installation
```bash
# Install commands
```

## Usage
```bash
# Basic usage example
```

## Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `VAR`    | Description | `value` |
```

### 3. API Documentation

For each endpoint:

```markdown
## POST /api/users

Create a new user.

### Request Body
```json
{
  "name": "string (required)",
  "email": "string (required, email format)"
}
```

### Responses
- **201 Created**: User created successfully.
- **400 Bad Request**: Validation error.
```

## Language Specifics

| Language | Format |
|----------|----------|
| Python | Google Style Docstrings |
| Go | GoDoc comments |
| TypeScript | TSDoc/JSDoc |
| Terraform | terraform-docs |

## Instructions

1.  Analyze the code context.
2.  Generate appropriate documentation.
3.  Ensure consistency with existing docs.
4.  Include practical examples.
