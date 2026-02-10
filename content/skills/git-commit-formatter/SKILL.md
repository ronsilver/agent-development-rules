---
name: git-commit-formatter
description: Formats git commit messages according to the Conventional Commits specification. Use this when the user asks to commit changes, write a commit message, or review commit messages.
license: MIT
---

# Git Commit Formatter Skill

## Goal

Generate precise, meaningful commit messages that follow the Conventional Commits specification by analyzing the actual code changes.

## Workflow

### Step 1: Analyze Changes

Run `git diff --staged` (or `git diff` if nothing is staged) to understand what changed.

If nothing is staged, ask: "No staged changes found. Should I stage all changes (`git add -A`) or specific files?"

### Step 2: Detect Scope & Complexity

- Identify the **primary area** affected (component, module, file group).
- If changes span **multiple unrelated areas**, recommend splitting:
  - "These changes touch auth AND billing. I recommend two separate commits."
  - Suggest which files belong to each commit.

### Step 3: Determine Type

Analyze the diff to select the correct type:

| Type | When to use |
|------|-------------|
| **feat** | New feature or capability added |
| **fix** | Bug fix (something was broken, now it works) |
| **docs** | Documentation only (README, comments, docstrings) |
| **style** | Formatting, whitespace, semicolons (no logic change) |
| **refactor** | Code restructuring without behavior change |
| **perf** | Performance improvement (measurable) |
| **test** | Adding or correcting tests |
| **build** | Build system or external dependency changes |
| **ci** | CI/CD configuration changes |
| **chore** | Maintenance tasks (deps update, config tweaks) |
| **revert** | Reverting a previous commit |

### Step 4: Generate Message

```
<type>[optional scope]: <description>

[optional body — explain WHAT and WHY, not HOW]

[optional footer(s)]
```

### Step 5: Verify

Before committing, confirm the message with the user. Show:
1. The proposed message.
2. A summary of files included.
3. Ask: "Commit with this message?"

## Rules

- **Subject line**: imperative mood, <= 72 characters, no period at end.
- **Body**: wrap at 72 characters, explain motivation and contrast with previous behavior.
- **Footer**: `BREAKING CHANGE:` for breaking changes, `Closes #123` for issue references.
- **Scope**: lowercase, matches a component/module name (e.g., `auth`, `api`, `cli`).

## Good vs Bad Examples

```
❌ "update"
❌ "fix bug"
❌ "changes"
❌ "wip"
❌ "misc improvements"
❌ "fix: fix the thing"

✅ feat(auth): implement OAuth2 login with Google
✅ fix(api): handle null response from payment gateway
✅ docs(readme): add deployment instructions for AWS
✅ refactor(user-service): extract validation into shared helper
✅ test(cart): add edge cases for empty cart checkout

✅ feat!: redesign user API endpoints

   BREAKING CHANGE: /api/users now returns paginated results.
   Migration: update all clients to handle `{ data: [], meta: {} }` shape.

✅ fix(parser): prevent crash on malformed UTF-8 input

   The parser assumed valid UTF-8 on all inputs. Malformed sequences
   caused an unhandled exception in production (Sentry #4521).

   Closes #4521
```

## Multi-Commit Strategy

When changes are complex, suggest atomic commits:

```
git add src/auth/          && git commit -m "feat(auth): add OAuth2 provider"
git add tests/auth/        && git commit -m "test(auth): add OAuth2 integration tests"
git add docs/auth.md       && git commit -m "docs(auth): document OAuth2 setup flow"
```

## Constraints

- **NEVER** generate generic messages — always infer from the diff.
- **NEVER** commit without showing the proposed message to the user first.
- **ALWAYS** use imperative mood ("add" not "added", "fix" not "fixed").
- If unsure about the type, ask the user rather than guessing.
