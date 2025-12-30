---
trigger: glob
globs: ["*.js", "*.ts", "*.tsx", "package.json"]
---

# Node.js / TypeScript Best Practices

## Configuración TypeScript Estricta

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Types vs Interfaces

```typescript
// ✅ Interface para objetos y extensión
interface User {
  id: string;
  name: string;
  email: string;
}

interface AdminUser extends User {
  permissions: string[];
}

// ✅ Type para unions, intersections, utilities
type Status = 'pending' | 'active' | 'inactive';
type CreateUserInput = Omit<User, 'id'>;
type UserOrAdmin = User | AdminUser;
```

## Evitar `any`

```typescript
// ❌ Incorrecto
function process(data: any) { }

// ✅ Usar unknown y validar
function process(data: unknown) {
  if (isValidData(data)) {
    // data ahora tiene tipo específico
  }
}

// ✅ Usar generics
function process<T extends BaseData>(data: T): ProcessedData<T> {
  // ...
}
```

## Async/Await

```typescript
// ✅ Correcto - async/await con manejo de errores
async function fetchUser(id: string): Promise<User> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return await response.json() as User;
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Failed to fetch user: ${error.message}`);
    }
    throw error;
  }
}

// ✅ Operaciones paralelas
const [user, orders] = await Promise.all([
  fetchUser(userId),
  fetchOrders(userId),
]);

// ✅ Promise.allSettled para tolerancia a fallos
const results = await Promise.allSettled(tasks);
const successful = results
  .filter((r): r is PromiseFulfilledResult<T> => r.status === 'fulfilled')
  .map(r => r.value);
```

## Imports (ESM)

```typescript
// 1. Externos (node_modules)
import { z } from 'zod';
import express from 'express';

// 2. Node.js built-ins
import { readFile } from 'node:fs/promises';
import path from 'node:path';

// 3. Internos (aliases)
import { UserService } from '@/services/user.js';
import { validateEmail } from '@/utils/validation.js';

// 4. Relativos
import { config } from './config.js';
import type { AppContext } from './types.js';
```

## Null Safety

```typescript
// Optional chaining
const userName = user?.profile?.name;
const firstItem = items?.[0];
const result = callback?.();

// Nullish coalescing
const port = config.port ?? 3000;
const name = user.name ?? 'Anonymous';

// Type guards
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'name' in value
  );
}
```

## Validación con Zod

```typescript
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().min(0).max(150).optional(),
});

type User = z.infer<typeof UserSchema>;

function createUser(input: unknown): User {
  return UserSchema.parse(input);
}

// Safe parse sin throw
const result = UserSchema.safeParse(input);
if (result.success) {
  const user = result.data;
} else {
  console.error(result.error.issues);
}
```

## Estructura de Proyecto

```
project/
├── src/
│   ├── index.ts          # Entry point
│   ├── config.ts         # Configuración
│   ├── types/            # Type definitions
│   ├── services/         # Business logic
│   ├── routes/           # HTTP routes
│   └── utils/            # Helpers
├── tests/
│   └── *.test.ts
├── package.json
├── tsconfig.json
└── .env.example
```

## package.json

```json
{
  "name": "my-app",
  "type": "module",
  "engines": {
    "node": ">=20.0.0"
  },
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "tsx watch src/index.ts",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint src/",
    "typecheck": "tsc --noEmit"
  }
}
```

## Comandos de Validación

```bash
# Type checking
npm run typecheck

# Linting
npm run lint

# Testing
npm test
npm run test:coverage

# Seguridad
npm audit
npm audit fix
```

## Anti-Patrones

| Anti-Patrón | Solución |
|-------------|----------|
| Usar `any` | `unknown` + type guards o generics |
| Callbacks anidados | async/await |
| `require()` | ESM imports |
| `.then().catch()` chains | async/await con try/catch |
| Ignorar errores async | Siempre manejar rechazos |
