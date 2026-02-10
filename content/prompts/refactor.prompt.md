---
name: Refactor
description: Refactor code while maintaining existing behavior
trigger: manual
tags: [refactoring, clean-code, maintainability]
skill: refactoring
---

# Refactor

Refactor the selected code while **maintaining existing behavior**. Apply the **refactoring** skill for code smells, solutions, and language-specific patterns.

## Report Format

~~~markdown
## Refactoring Summary

**Target:** `src/services/order_service.py`
**Smells Identified:** Long Method, Magic Numbers, Deep Nesting

### Changes Made

1. **Extract Function**: `process_order()` → `validate_order()` + `calculate_totals()` + `process_payment()`
   - Lines: 85 → 25 (main function)

2. **Named Constants**: Replaced 5 magic numbers with constants

3. **Early Returns**: Reduced nesting from 4 levels to 1

### Verification
- ✅ All tests pass
- ✅ Coverage maintained
- ✅ No public API changes
~~~

## Instructions

1. **Verify** tests exist and pass before starting
2. **Identify** code smells using the skill's thresholds
3. **Plan** incremental refactoring steps
4. **Execute** one refactoring at a time, run tests after each
5. **Measure** improvement (lines, complexity, nesting)
6. **Document** changes using the report format above
