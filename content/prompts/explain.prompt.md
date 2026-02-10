---
name: Explain
description: Explain selected code in a clear, educational manner
trigger: manual
tags: [learning, analysis, onboarding]
---

# Explain

Explain the selected code in a clear, educational manner. Focus on **understanding**, not just describing. Default to **Intermediate** level unless specified.

## Output Structure

1. **Summary** (1-2 sentences) — What does this code do at a high level?
2. **Purpose** — What problem does it solve? Why does this code exist?
3. **How It Works** — Step-by-step breakdown
4. **Key Concepts** — Patterns, algorithms, language features used
5. **Important Details** — Edge cases, error handling, performance (O notation)
6. **Potential Gotchas** — Non-obvious behavior, common mistakes, assumptions

## Explanation Depth by Audience

| Level | Focus |
|-------|-------|
| **Beginner** | Concepts, terminology, high-level overview |
| **Intermediate** | Patterns, trade-offs, implementation details |
| **Expert** | Edge cases, internals, performance deep dive |

## Instructions

1. **Read** the selected code carefully
2. **Identify** the audience level (default: intermediate)
3. **Structure** explanation using the output structure above
4. **Include** code snippets to illustrate points
5. **Highlight** non-obvious behavior and gotchas
6. **Be concise** — avoid repeating what the code clearly shows
