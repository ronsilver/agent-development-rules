---
name: Commit
description: Generate commit messages following Conventional Commits specification
trigger: manual
tags: [git, conventional-commits, generation]
skill: git-commit-formatter
---

# Commit

Generate a commit message following the **Conventional Commits** specification. Apply the **git-commit-formatter** skill for the full workflow, type detection, and multi-commit strategy.

## Instructions

1. **Examine changes**: Run `git diff --staged` or review diff
2. **Identify primary change**: What's the main purpose?
3. **Determine type**: feat, fix, refactor, etc.
4. **Find scope**: Which module/component is affected?
5. **Write subject**: Imperative, concise, lowercase
6. **Add body**: If change is non-trivial, explain why
7. **Add footer**: Reference issues, note breaking changes
