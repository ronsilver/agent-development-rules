---
trigger: glob
globs: [".github/**", ".gitignore", ".gitattributes", "CONTRIBUTING.md", "CHANGELOG.md"]
---

# Git Best Practices

## Commit Messages (Conventional Commits) - MANDATORY

**Strict Format:** `<type>(<scope>): <description>`

### Allowed Types
| Type | Use | Version | Example |
|------|-----|---------|----------|
| `feat` | **New feature** for the user | MINOR | `feat(auth): add OAuth2 login` |
| `fix` | **Bug fix** for the user | PATCH | `fix(api): resolve null pointer in handler` |
| `docs` | **Documentation only** | - | `docs(readme): add Docker setup guide` |
| `style` | **Formatting** (spaces, commas, no logic change) | - | `style(lint): fix indentation in utils` |
| `refactor` | **Code change** without fix or feature | - | `refactor(db): simplify query builder` |
| `perf` | **Performance improvement** | PATCH | `perf(api): add response caching` |
| `test` | **Tests** (add, correct, refactor) | - | `test(auth): add login validation tests` |
| `chore` | **Maintenance** (config, deps, scripts) | - | `chore(deps): upgrade axios to 1.6.0` |
| `ci` | **CI/CD** (GitHub Actions, pipelines) | - | `ci(actions): add caching for node_modules` |
| `build` | **Build system** (webpack, vite, etc.) | - | `build(vite): update output config` |
| `revert` | **Revert** previous commit | - | `revert: feat(auth): add OAuth2 login` |

### DIRECTIVES - STRICT ENFORCEMENT

The agent MUST always generate commits matching the Conventional Commits regex.
The agent MUST NEVER generate commits with the following generic messages:
- "update"
- "fix"
- "changes"
- "wip"
If the user asks for a quick save, the agent MUST still infer a proper message or ask for one.

#### Subject Line Rules
1.  **Imperative Mood**: Use `add`, `fix`, `update`, NOT `added`, `fixed`, `updates`.
2.  **Lowercase**: Start with lowercase. `add feature` NOT `Add feature`.
3.  **No Period**: No dot at the end.
4.  **Max Length**: 50 characters ideal, 72 hard limit.
5.  **Scope Required**: Always denote the area affected (`auth`, `api`, `ui`).

### Examples

#### ✅ Correct
```bash
feat(auth): add OAuth2 authentication
fix(api): resolve null pointer in login handler
docs(readme): add installation steps
chore(deps): upgrade axios to 1.6.0
feat(api)!: change response format (Breaking Change)
```

#### ❌ Incorrect (REJECT THESE)
```bash
feat: add authentication             # Missing scope
fixed(api): resolved the bug         # Past tense
feat(auth): Add new login            # Capitalized
feat(auth): add login.               # Trailing period
update(auth): add login              # Invalid type 'update'
```

## Branching Strategy

| Prefix | Use | Example |
|--------|-----|----------|
| `main` | Production | - |
| `develop` | Development | - |
| `feature/` | New Feature | `feature/user-auth` |
| `fix/` | Bug Fix | `fix/login-error` |
| `hotfix/` | Urgent Prod Fix | `hotfix/security-patch` |
| `release/` | Release Prep | `release/1.2.0` |

## Workflow

### Pre-Push Checklist
1.  **Lint**: Code must be linted.
2.  **Test**: Tests must pass.
3.  **Sync**: Rebase with `main` to ensure a clean history.

```bash
git fetch origin
git rebase origin/main
git push origin feature/my-feature
```

## .gitignore Best Practices
**NEVER COMMIT:**
- Secrets (`.env`, `*.pem`, `*.key`)
- Build artifacts (`dist/`, `build/`, `*.pyc`)
- OS files (`.DS_Store`)
- IDE config (`.idea/`, `.vscode/`) unless it's shared/sanitized.

## Pull Requests

### Description Template
```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
```
