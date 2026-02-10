---
name: code-review
description: Reviews code changes for bugs, style issues, security vulnerabilities, and best practices. Use when reviewing PRs, checking code quality, or when the user asks for a code review.
license: MIT
---

# Code Review Skill

## Goal

Perform thorough, constructive code reviews that catch bugs, enforce standards, share knowledge, and improve code quality. Transform reviews from gatekeeping into collaborative learning.

## Anti-Goals

- Show off knowledge or nitpick formatting (use linters for that).
- Block progress unnecessarily or rewrite code to personal preference.
- Be judgmental — focus on the code, not the person.

## Workflow

### Phase 1: Determine Review Target

- **Remote PR**: If the user provides a PR number or URL, target that PR.
  - Run: `gh pr view <NUMBER> --json title,body,files` to get context.
  - Run: `gh pr diff <NUMBER>` to get the diff.
- **Local changes**: If no PR is mentioned, target the local working tree.
  - Run: `git status` to identify changed files.
  - Run: `git diff` (unstaged) and `git diff --staged` (staged).
- **Size check**: If diff exceeds ~400 lines, suggest splitting into smaller PRs.

### Phase 2: Context Gathering

1. Read the PR description or commit messages to understand the **intent**.
2. Identify the business requirement or linked issue.
3. Check CI/CD status if available (`gh pr checks <NUMBER>`).
4. Note relevant architectural decisions or project conventions.

### Phase 3: High-Level Review

1. **Architecture & Design** — Does the solution fit the problem? Is there a simpler approach?
2. **File Organization** — Are new files in the right places? Is code grouped logically?
3. **Testing Strategy** — Are there tests? Do they cover edge cases? Are they readable?

### Phase 4: Line-by-Line Analysis

For each file, evaluate these pillars:

- **Correctness**: Does the code achieve its stated purpose? Edge cases? Off-by-one errors? Race conditions?
- **Security**: Input validation? Injection risks? Secrets exposure? Auth checks?
- **Performance**: N+1 queries? Unnecessary loops? Memory leaks? Blocking I/O in hot paths?
- **Maintainability**: Clear naming? Functions doing one thing? Magic numbers extracted? Nesting depth < 3?
- **Error Handling**: Are errors handled explicitly? Do error messages leak sensitive info?
- **Testability**: Is the code testable? Are tests behavior-based (not implementation-detail)?

See [references/checklist.md](references/checklist.md) for the extended checklist.

### Phase 5: Summary & Verdict

1. Summarize key concerns.
2. Highlight what was done well (always include positives).
3. Make a clear decision: ✅ Approve, 💬 Comment, or 🔄 Request Changes.

## Severity Labels

Use these labels to indicate priority on every finding:

- 🔴 **[blocking]** — Must fix before merge (bugs, security, breaking changes).
- 🟡 **[important]** — Should fix; discuss if you disagree.
- 🟢 **[nit]** — Nice to have, not blocking.
- 💡 **[suggestion]** — Alternative approach to consider.
- 📚 **[learning]** — Educational comment, no action needed.
- 🎉 **[praise]** — Highlight good work.

## Feedback Technique

Use **questions** instead of commands to encourage thinking:

```
❌ "This will fail if the list is empty."
✅ "What happens if `items` is an empty array here?"

❌ "You need error handling here."
✅ "How should this behave if the API call fails?"

❌ "This is inefficient."
✅ "This loops through all users — have we considered the impact with 100k records?"

❌ "Extract this into a function."
✅ "This logic appears in 3 places. Would it make sense to extract a shared helper?"
```

## Report Template

```markdown
## Summary
[Brief overview of what was reviewed and overall impression]

## Strengths
- 🎉 [What was done well — always include positives]

## Required Changes
- 🔴 [blocking] [file:line] Issue description and why it matters

## Suggestions
- 🟡 [important] [file:line] Suggestion with recommended alternative
- 💡 [suggestion] [file:line] Alternative approach to consider

## Nits
- 🟢 [nit] [file:line] Minor style or readability improvements

## Questions
- ❓ [file:line] Clarification needed

## Verdict
✅ Approve / 💬 Comment / 🔄 Request Changes
```

## Constraints

- Be specific about what needs to change and **why**.
- Suggest alternatives, not just criticisms.
- Respect Chesterton's Fence: understand code before suggesting removal.
- Prioritize security and correctness over style nits.
- Do NOT manually review formatting — that is what linters are for.
