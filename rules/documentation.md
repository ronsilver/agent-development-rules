---
trigger: glob
globs: ["README.md", "CHANGELOG.md", "docs/**"]
---

# Documentation Best Practices

## Documentation as Code - MANDATORY

Use tools to auto-generate docs:
- **Terraform**: `terraform-docs`
- **Go**: `swaggo` / `godoc`
- **Python**: `mkdocs` / `sphinx`
- **API**: OpenAPI (Swagger) generated from code.

## README Standard

1. **Title & Description**: What is this?
2. **Requirements**: Dependencies.
3. **Installation**: How to install.
4. **Usage**: Basic examples.
5. **Configuration**: Env vars, flags.
6. **Development**: How to build/test locally.

## CHANGELOG

Follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Format:
```markdown
## [1.0.0] - 2023-10-01
### Added
- Feature X
### Fixed
- Bug Y
```

## Code Comments

### When to Document
- Non-obvious business logic.
- "Why" a decision was made.
- Workarounds (link to issue).

### When NOT to Document
- Trivial getters/setters.
- Code that explains itself.
- Redundant comments (`i++ # increment i`).
