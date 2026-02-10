---
trigger: glob
globs: ["*.js", "*.ts", "*.tsx", "package.json"]
---

# Node.js / TypeScript Best Practices

## Strict Mode - NON-NEGOTIABLE

`tsconfig.json` **MUST** have `"strict": true`. No exceptions.

## Mandatory Tooling

Before any commit or PR, you **MUST** run:
```bash
npm run format     # Prettier formatting
npm run typecheck  # TypeScript check
npm run lint       # ESLint
npm test           # Tests with coverage
```

## Type Safety
- **Interface**: Use for objects and extension.
- **Type**: Use for unions, intersections, utilities.
- **Avoid `any`**: Use `unknown` with type guards or Generics.

```typescript
// ❌ Bad
function process(data: any) { }

// ✅ Good
function process(data: unknown) {
  if (isData(data)) { ... }
}
```

## Async Patterns
- **Callback Hell**: Strictly FORBIDDEN.
- **Mix Async/Sync**: Avoid.
- Use `Promise.all` for parallel operations.
- **Top-level Await**: Allowed in ESM.

## Runtime Validation (Zod)

TypeScript checks types at compile time. You **MUST** use `zod` to validate external data (API request, Env vars, DB result) at runtime.

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
});

// Parse validates runtime data matches the schema
const user = UserSchema.parse(input);
```

## Project Structure
Standard `src/` layout:
```
src/
  index.ts
  services/
  routes/
  utils/
  types/
```

## ESLint Configuration - Flat Config (2025 Standard)

### Migration to Flat Config

ESLint v9+ uses **flat config** (`eslint.config.js`) instead of `.eslintrc.*`. This is the **new standard for 2025**.

**Legacy** (deprecated - do NOT use):
```json
// .eslintrc.json - DEPRECATED in ESLint v9+
{
  "extends": ["eslint:recommended"],
  "rules": {}
}
```

**Modern** (flat config - use this):
```javascript
// eslint.config.js - Using unified typescript-eslint package
import tseslint from 'typescript-eslint';

export default tseslint.config(
  ...tseslint.configs.recommended,
  {
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unused-vars': 'error',
      '@typescript-eslint/explicit-function-return-type': 'warn',
    },
  },
);
```

### TypeScript ESLint Configurations

Choose based on team proficiency:

| Config | Use Case | Performance Impact |
|--------|----------|-------------------|
| **recommended** | Most projects | Normal |
| **strict** | High code quality standards | Normal |
| **strict-type-checked** | Expert TypeScript teams | 30x slower (requires type info) |

**Recommended Setup**:
```javascript
// eslint.config.js
import tseslint from 'typescript-eslint';

export default tseslint.config(
  // Core recommended rules
  ...tseslint.configs.recommended,

  // Strict rules (no type checking)
  ...tseslint.configs.strict,

  // Custom overrides
  {
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unused-vars': ['error', {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
      }],
    },
  }
);
```

**Advanced Setup (Type-Checked)** - Use only if team is highly proficient:
```javascript
import tseslint from 'typescript-eslint';

export default tseslint.config(
  ...tseslint.configs.strictTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        project: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  }
);
```

**Warning**: Type-checked configs can increase ESLint execution time by 30x. Use only on small/medium codebases or expert teams.

### Essential ESLint Rules

```javascript
export default [
  {
    rules: {
      // TypeScript
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unused-vars': 'error',
      '@typescript-eslint/explicit-function-return-type': 'warn',
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',

      // Code quality
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'no-debugger': 'error',
      'prefer-const': 'error',
      'no-var': 'error',

      // Modern syntax
      'prefer-arrow-callback': 'error',
      'prefer-template': 'error',
      'object-shorthand': 'error',
    },
  },
];
```

## TypeScript Strict Mode Comparison

### `tsconfig.json` - Strict Configuration

```json
{
  "compilerOptions": {
    "strict": true,  // Enables all strict options below

    // Strict checks (enabled by "strict": true)
    "noImplicitAny": true,           // No implicit 'any' types
    "strictNullChecks": true,         // Null/undefined checking
    "strictFunctionTypes": true,      // Function type checking
    "strictBindCallApply": true,      // bind/call/apply checking
    "strictPropertyInitialization": true,  // Class property initialization
    "noImplicitThis": true,           // No implicit 'this'
    "alwaysStrict": true,             // Use 'use strict' mode

    // Additional strict options (not in "strict")
    "noUnusedLocals": true,           // Report unused local variables
    "noUnusedParameters": true,       // Report unused parameters
    "noImplicitReturns": true,        // All code paths return value
    "noFallthroughCasesInSwitch": true,  // No fallthrough in switch
    "noUncheckedIndexedAccess": true, // Index signatures return T | undefined
    "noImplicitOverride": true,       // Explicit 'override' keyword
    "allowUnusedLabels": false,       // Report unused labels
    "allowUnreachableCode": false,    // Report unreachable code

    // Module resolution
    "module": "ESNext",
    "moduleResolution": "bundler",
    "target": "ES2022",
    "lib": ["ES2022"],

    // Interop
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "resolveJsonModule": true,
    "isolatedModules": true,

    // Output
    "sourceMap": true,
    "declaration": true,
    "declarationMap": true,
    "outDir": "dist"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Testing with Vitest

Vitest is the **modern alternative** to Jest (faster, native ESM, better TypeScript support).

### Installation
```bash
npm install -D vitest @vitest/ui
```

### Configuration - `vitest.config.ts`
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',  // or 'jsdom' for browser
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.test.ts',
        '**/*.config.*',
      ],
      // Align with testing.md coverage requirements (70% overall)
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 70,
        statements: 70,
      },
    },
  },
});
```

### Test Examples

**Basic Test**:
```typescript
import { describe, it, expect } from 'vitest';

describe('Calculator', () => {
  it('should add two numbers', () => {
    expect(1 + 1).toBe(2);
  });

  it('should handle negative numbers', () => {
    expect(-1 + -1).toBe(-2);
  });
});
```

**Async Tests**:
```typescript
import { describe, it, expect } from 'vitest';

describe('API', () => {
  it('should fetch user data', async () => {
    const user = await fetchUser(123);
    expect(user.id).toBe(123);
    expect(user.name).toBeDefined();
  });
});
```

**Mocking**:
```typescript
import { describe, it, expect, vi } from 'vitest';

describe('Service', () => {
  it('should call repository', async () => {
    const mockRepo = {
      getUser: vi.fn().mockResolvedValue({ id: 123 }),
    };

    const service = new Service(mockRepo);
    const user = await service.getUser(123);

    expect(mockRepo.getUser).toHaveBeenCalledWith(123);
    expect(user.id).toBe(123);
  });
});
```

**Snapshot Testing**:
```typescript
import { describe, it, expect } from 'vitest';

describe('Component', () => {
  it('should render correctly', () => {
    const output = render({ name: 'John' });
    expect(output).toMatchSnapshot();
  });
});
```

### Package.json Scripts
```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:ui": "vitest --ui"
  }
}
```

## Coverage Requirements

> Thresholds (90%/80%/70%) defined in **testing.md § Coverage Requirements**.

```bash
# Run with coverage
npm run test:coverage

# CI/CD: Fail if coverage drops
vitest run --coverage --coverage.thresholds.lines=70
```

## Tooling Summary
- **Format**: `prettier`
- **Lint**: `eslint` (flat config)
- **Type Check**: `tsc --noEmit`
- **Test**: `vitest` (recommended) or `jest`
- **Build**: `tsc` or `tsup`
- **Bundle**: `vite`, `esbuild`, or `rollup`
