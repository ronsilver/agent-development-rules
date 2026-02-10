---
name: Debug
description: Analyze and debug issues systematically to find root causes
trigger: manual
tags: [debugging, analysis, troubleshooting]
skill: systematic-debugging
---

# Debug

Analyze and debug issues systematically. Focus on **root cause**, not symptoms. Apply the **systematic-debugging** skill for the full workflow, bug patterns, and tools reference.

## Report Format

~~~markdown
## Bug Report

**Issue:** [one-line description]
**Severity:** [Critical/High/Medium/Low]

**Reproduction:**
1. [step 1]
2. [step 2]
3. [observed behavior]

**Root Cause:**
[Explain WHY the bug happened, not just what was broken]

**Evidence:**
- [log lines, stack traces, metrics]

**Fix:**
[What was changed and why — include before/after code]

**Verification:**
- [ ] Fix resolves the original issue
- [ ] Regression test added
- [ ] No regressions in related functionality

**Prevention:**
[What systemic change prevents similar bugs]
~~~

## Instructions

1. **Reproduce** the issue — confirm expected vs actual behavior
2. **Gather** logs, metrics, and recent changes as evidence
3. **Hypothesize** possible causes ranked by likelihood
4. **Isolate** using binary search, minimal repro, or strategic logging
5. **Fix** one thing at a time, run tests after each change
6. **Verify** the fix resolves the issue without regressions
7. **Document** root cause, fix, and prevention in report format above