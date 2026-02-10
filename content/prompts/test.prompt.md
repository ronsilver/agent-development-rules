---
name: Test
description: Generate comprehensive tests following Test Pyramid and AAA pattern
trigger: manual
tags: [testing, generation, unit-tests, tdd]
skill: test-driven-development
---

# Test

Generate comprehensive tests for the selected code. Apply the **test-driven-development** skill for AAA pattern, test doubles, naming conventions, and framework-specific guidance.

## Instructions

1. **Detect** existing test framework and patterns in the codebase
2. **Follow** existing naming conventions and file structure
3. **Generate** tests using AAA pattern (Arrange → Act → Assert)
4. **Include** happy path, edge cases, and error cases
5. **Use** table-driven tests for multiple scenarios
6. **Mock** only external dependencies (DB, APIs, filesystem)
7. **Verify** tests are independent (no shared state)
