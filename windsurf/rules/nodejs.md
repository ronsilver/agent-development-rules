---
trigger: glob
globs: ["*.js", "*.ts", "*.tsx", "package.json"]
---

# Node.js / TypeScript Best Practices

## TypeScript Preferido

- Usar TypeScript sobre JavaScript
- `strict: true` en tsconfig.json

## Imports

ESM sobre CommonJS:
```typescript
import { readFile } from 'fs/promises';
import path from 'path';
```

## Async/Await

```typescript
async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  if (!response.ok) {
    throw new Error(`Failed: ${response.status}`);
  }
  return response.json();
}
```

## Types

```typescript
interface User {
  id: string;
  name: string;
  email: string;
}

type CreateUserInput = Omit<User, 'id'>;
```

## Estructura

```
project/
├── src/
│   ├── index.ts
│   ├── types/
│   └── services/
├── tests/
├── package.json
└── tsconfig.json
```

## package.json

```json
{
  "type": "module",
  "engines": {
    "node": ">=20.0.0"
  },
  "scripts": {
    "build": "tsc",
    "test": "vitest",
    "lint": "eslint src/"
  }
}
```

## Testing

```bash
npm test
npm run lint
```

## Dependencias

- `package-lock.json` en git
- `npm audit` regular
- Actualizar dependencias periódicamente
