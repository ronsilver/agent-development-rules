# Refactor

Refactor the selected code while maintaining existing behavior.

## Refactoring Goals

### 1. Reduce Complexity
- Extract functions from long methods (>50 lines).
- Simplify nested conditionals (>3 levels).
- Use early returns to reduce indentation.
- Remove dead code.

### 2. Improve Readability
- Descriptive naming for variables and functions.
- Replace magic numbers with named constants.
- Extract complex expressions into named variables.
- Order methods by abstraction level.

### 3. Eliminate Duplication (DRY)
- Identify repeated patterns.
- Extract to shared functions/methods.
- Prefer composition over inheritance.

### 4. SOLID Principles
- **S**ingle Responsibility: One reason to change.
- **O**pen/Closed: Open for extension, closed for modification.
- **L**iskov Substitution: Subtypes must be substitutable.
- **I**nterface Segregation: Specific interfaces.
- **D**ependency Inversion: Depend on abstractions.

## Constraints

- ✅ **Maintain Behavior**: Same inputs → Same outputs.
- ✅ **Pass Tests**: All existing tests must pass.
- ✅ **Public API**: Do not break public interfaces.
- ❌ **No New Deps**: Do not add dependencies without justification.

## Process

1.  Identify Code Smells (God Class, Long Method, Feature Envy).
2.  Propose specific changes.
3.  Apply incremental refactors.
4.  Verify tests after EACH change.
