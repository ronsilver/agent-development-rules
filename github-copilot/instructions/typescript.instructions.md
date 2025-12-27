# TypeScript Instructions

## Types

- Preferir interfaces sobre types para objetos
- Evitar `any`, usar `unknown` si es necesario
- Usar `strict: true` en tsconfig

## Async

- Usar async/await sobre Promises raw
- Manejar errores con try/catch

## Imports

- ESM sobre CommonJS
- Imports ordenados: externos, internos, relativos

## Null Handling

- Usar optional chaining: `obj?.prop`
- Nullish coalescing: `value ?? default`
