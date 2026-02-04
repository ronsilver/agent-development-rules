---
name: Commit
description: Generate commit messages following Conventional Commits specification
trigger: manual
tags:
  - git
  - conventional-commits
---

# Commit

Generate a commit message following the **Conventional Commits** specification.

## Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

## Allowed Types

| Type | Emoji | Description | Example |
|------|-------|-------------|---------|
| `feat` | ✨ | New feature | `feat(auth): add OAuth2 login` |
| `fix` | 🐛 | Bug fix | `fix(api): handle null response` |
| `docs` | 📝 | Documentation only | `docs(readme): update install steps` |
| `style` | 💄 | Formatting, no code change | `style(lint): fix indentation` |
| `refactor` | ♻️ | Code change, no feature/fix | `refactor(user): extract validation` |
| `perf` | ⚡ | Performance improvement | `perf(query): add database index` |
| `test` | ✅ | Adding/correcting tests | `test(auth): add login unit tests` |
| `build` | 📦 | Build system, dependencies | `build(deps): upgrade lodash to 4.17.21` |
| `ci` | 🔧 | CI configuration | `ci(github): add test workflow` |
| `chore` | 🔨 | Other changes | `chore(deps): update lockfile` |
| `revert` | ⏪ | Revert previous commit | `revert: feat(auth): add OAuth2` |

## Rules - STRICT

### Subject Line
| Rule | ✅ Correct | ❌ Incorrect |
|------|-----------|-------------|
| Imperative mood | `add feature` | `added feature`, `adds feature` |
| Lowercase | `fix bug` | `Fix bug`, `FIX BUG` |
| No period | `add feature` | `add feature.` |
| Max 50 chars | Short and clear | Long rambling description |
| Scope required | `fix(auth): ...` | `fix: ...` |

### Body (Optional but Recommended)
- Explain **WHAT** and **WHY**, not **HOW**
- Wrap at 72 characters
- Separate from subject with blank line
- Use bullet points for multiple changes

### Footer (Optional)
- Reference issues: `Fixes #123`, `Closes #456`
- Breaking changes: `BREAKING CHANGE: description`
- Co-authors: `Co-authored-by: Name <email>`

## Breaking Changes

Two ways to indicate breaking changes:

```bash
# Option 1: Add ! after type
feat(api)!: change response format

# Option 2: Footer (more detail)
feat(api): change response format

BREAKING CHANGE: All endpoints now return JSON:API format.
See migration guide at docs/migration.md
```

## Examples

### Simple Feature
```
feat(user): add email verification endpoint
```

### Bug Fix with Context
```
fix(payment): prevent duplicate charges on timeout

When payment gateway times out, the retry logic was not checking
if the original transaction succeeded. Added idempotency key
to prevent duplicate charges.

Fixes #789
```

### Refactor with Scope
```
refactor(order): extract shipping calculation to service

- Move shipping logic from OrderController to ShippingService
- Add unit tests for all shipping methods
- No functional changes
```

### Multiple Changes (Use Separate Commits)
```bash
# ❌ Don't combine unrelated changes
feat(auth): add OAuth2 and fix password reset bug

# ✅ Split into separate commits
feat(auth): add OAuth2 login provider
fix(auth): handle expired reset tokens
```

### Dependency Update
```
build(deps): upgrade express from 4.18.0 to 4.19.0

Security fix for CVE-2024-XXXX (request smuggling).
No breaking changes in this minor version.
```

### Documentation
```
docs(api): add rate limiting section to API docs

- Document rate limits per endpoint
- Add examples of 429 responses
- Include retry-after header usage
```

## Analysis Process

1. **Examine changes**: Run `git diff --staged` or review diff
2. **Identify primary change**: What's the main purpose?
3. **Determine type**: feat, fix, refactor, etc.
4. **Find scope**: Which module/component is affected?
5. **Write subject**: Imperative, concise, lowercase
6. **Add body**: If change is non-trivial, explain why
7. **Add footer**: Reference issues, note breaking changes

## Anti-Patterns

| ❌ Bad | ✅ Good | Why |
|--------|---------|-----|
| `fix bug` | `fix(auth): handle expired tokens` | Missing scope, vague |
| `Update code` | `refactor(user): extract validation logic` | Non-descriptive |
| `WIP` | Don't commit WIP | Use `git stash` instead |
| `misc changes` | Split into meaningful commits | Atomic commits |
| `Fixed.` | `fix(api): return 404 for missing resource` | Period, past tense, vague |

## Git Hooks Integration

```bash
# .husky/commit-msg
npx --no -- commitlint --edit "$1"

# commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-empty': [2, 'never'],
    'subject-case': [2, 'always', 'lower-case'],
  },
};
```
