---
name: verification-before-completion
description: Ensures all completion claims are backed by fresh verification evidence. Use before claiming any task is done, before committing, before creating PRs, or before moving to the next task.
license: MIT
---

# Verification Before Completion

## Core Principle

**No completion claims without fresh verification evidence.**

Claiming work is complete without verification is dishonesty, not efficiency. If you haven't run the verification command in this response, you cannot claim it passes.

## The Verification Gate

Before claiming ANY status or expressing satisfaction:

1. **IDENTIFY**: What command proves this claim?
2. **RUN**: Execute the full command (fresh, not cached from earlier).
3. **READ**: Check full output AND exit code.
4. **VERIFY**: Does the output actually confirm the claim?
   - If **NO**: State actual status with evidence.
   - If **YES**: State claim WITH the evidence.
5. **ONLY THEN**: Make the claim.

Skipping any step is guessing, not verifying.

## Red Flags — STOP Immediately

If you catch yourself about to use any of these, STOP and run verification first:

- Words like "should", "probably", "seems to", "looks correct"
- Expressions like "Great!", "Perfect!", "Done!", "All good!"
- About to commit, push, or create a PR
- Trusting output from a previous run without re-running
- Thinking "just this once, I'll skip the check"

## Verification Patterns

### Tests

```
✅ Run: pytest -v → See: "34 passed" → Claim: "All 34 tests pass"
❌ "Tests should pass now" (without running them)
❌ "Looks correct" (without evidence)
```

### Linting

```
✅ Run: eslint . → See: exit 0 → Claim: "Linting passes"
❌ "I fixed the lint error" (without re-running linter)
```

### Build

```
✅ Run: npm run build → See: exit 0, no errors → Claim: "Build succeeds"
❌ "Build should work now" (without running it)
❌ "Linter passed" (linter ≠ build)
```

### Regression Tests (TDD Red-Green)

```
✅ Write test → Run (PASS) → Revert fix → Run (MUST FAIL) → Restore → Run (PASS)
❌ "I've written a regression test" (without red-green verification)
```

### Requirements Checklist

```
✅ Re-read the plan → Create checklist → Verify each item → Report gaps or completion
❌ "Tests pass, so the phase is complete" (tests ≠ requirements)
```

## The Golden Chain

Run the full validation chain defined in the **linting** rule: **Format → Lint → Type Check → Test → Security Scan**.

If ANY step fails, the work is NOT complete. Fix and re-run the entire chain.

## When to Apply

**ALWAYS** before:

- Any claim of success, completion, or correctness
- Any positive statement about the state of the work
- Committing code (`git commit`)
- Creating or updating a PR
- Moving to the next task or phase
- Declaring a task "done"

## Constraints

- Never express satisfaction before verification.
- Never trust previous run results — always run fresh.
- Never claim partial verification is full verification.
- If a verification command is unavailable, explicitly state: "I cannot verify [X] because [reason]. Manual verification needed."
