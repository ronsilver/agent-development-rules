---
trigger: glob
globs: ["*.py", "*.go", "*.js", "*.ts", "*.java"]
---

# Performance Best Practices - Excelencia Operativa

## Principios Fundamentales

1. **Medir antes de optimizar** - No optimizar sin datos de profiling
2. **Optimizar el cuello de botella** - El 80% del tiempo está en 20% del código
3. **Complejidad algorítmica primero** - O(n) a O(log n) > micro-optimizaciones
4. **Trade-offs conscientes** - CPU vs memoria vs legibilidad
5. **Performance budgets** - Definir límites aceptables

## Complejidad Algorítmica - OBLIGATORIO

### Conocer Big O de Operaciones Comunes

| Estructura | Acceso | Búsqueda | Inserción | Eliminación |
|------------|--------|----------|-----------|-------------|
| Array | O(1) | O(n) | O(n) | O(n) |
| HashMap | O(1)* | O(1)* | O(1)* | O(1)* |
| LinkedList | O(n) | O(n) | O(1) | O(1) |
| Binary Tree | O(log n) | O(log n) | O(log n) | O(log n) |
| Heap | O(1) | O(n) | O(log n) | O(log n) |

### Anti-Patrones de Complejidad

```python
# ❌ O(n²) - Loop anidado innecesario
def find_duplicates_bad(items: list[str]) -> list[str]:
    duplicates = []
    for i, item in enumerate(items):
        for j, other in enumerate(items):
            if i != j and item == other and item not in duplicates:
                duplicates.append(item)
    return duplicates

# ✅ O(n) - Usar set/dict
def find_duplicates_good(items: list[str]) -> list[str]:
    seen = set()
    duplicates = set()
    for item in items:
        if item in seen:
            duplicates.add(item)
        seen.add(item)
    return list(duplicates)
```

```python
# ❌ O(n) en cada búsqueda
def process_orders_bad(orders: list[Order], users: list[User]):
    for order in orders:
        for user in users:  # O(n) cada vez
            if user.id == order.user_id:
                process(order, user)

# ✅ O(1) en cada búsqueda con dict
def process_orders_good(orders: list[Order], users: list[User]):
    users_by_id = {u.id: u for u in users}  # O(n) una vez
    for order in orders:
        user = users_by_id.get(order.user_id)  # O(1)
        if user:
            process(order, user)
```

## Database Performance

### N+1 Query Problem - CRÍTICO

```python
# ❌ N+1 queries
def get_orders_bad():
    orders = Order.query.all()  # 1 query
    for order in orders:
        print(order.user.name)  # N queries adicionales

# ✅ Eager loading
def get_orders_good():
    orders = Order.query.options(
        joinedload(Order.user)
    ).all()  # 1 query con JOIN
    for order in orders:
        print(order.user.name)  # Sin queries adicionales
```

### Índices Obligatorios

```sql
-- Crear índices para:
-- 1. Columnas en WHERE frecuentes
CREATE INDEX idx_users_email ON users(email);

-- 2. Columnas en JOIN
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- 3. Columnas en ORDER BY
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- 4. Índices compuestos para queries comunes
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

### Query Optimization

```python
# ❌ SELECT * innecesario
users = db.query("SELECT * FROM users WHERE status = 'active'")

# ✅ Solo columnas necesarias
users = db.query("SELECT id, name, email FROM users WHERE status = 'active'")

# ❌ Sin paginación
all_records = db.query("SELECT * FROM logs")

# ✅ Con paginación
page = db.query("SELECT * FROM logs ORDER BY id LIMIT 100 OFFSET 0")

# ❌ LIKE con wildcard al inicio (no usa índice)
db.query("SELECT * FROM users WHERE email LIKE '%@gmail.com'")

# ✅ LIKE con wildcard al final (usa índice)
db.query("SELECT * FROM users WHERE email LIKE 'john%'")
```

## Caching

### Estrategias

| Estrategia | Uso | Invalidación |
|------------|-----|--------------|
| Cache-Aside | Lectura frecuente, escritura ocasional | Manual en escritura |
| Write-Through | Consistencia importante | Automática |
| Write-Behind | Alto throughput escritura | Eventual |
| TTL | Datos que pueden estar stale | Por tiempo |

### Implementación

```python
import redis
from functools import wraps

redis_client = redis.Redis()

def cache(ttl_seconds: int = 300):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generar key única
            cache_key = f"{func.__name__}:{hash(args)}:{hash(frozenset(kwargs.items()))}"
            
            # Intentar obtener de cache
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
            
            # Ejecutar función y cachear
            result = func(*args, **kwargs)
            redis_client.setex(cache_key, ttl_seconds, json.dumps(result))
            return result
        return wrapper
    return decorator

# Uso
@cache(ttl_seconds=60)
def get_user_profile(user_id: int) -> dict:
    return db.query("SELECT * FROM users WHERE id = %s", user_id)
```

### Cache Invalidation

```python
# Invalidar al actualizar
def update_user(user_id: int, data: dict):
    db.execute("UPDATE users SET ... WHERE id = %s", user_id)
    
    # Invalidar cache relacionado
    redis_client.delete(f"get_user_profile:{user_id}")
    redis_client.delete(f"get_user_orders:{user_id}")
```

## Async/Concurrency

### Operaciones I/O-Bound

```python
import asyncio
import httpx

# ❌ Secuencial - Lento
def fetch_all_sync(urls: list[str]) -> list[dict]:
    results = []
    for url in urls:
        response = requests.get(url)
        results.append(response.json())
    return results  # N * latencia

# ✅ Concurrente - Rápido
async def fetch_all_async(urls: list[str]) -> list[dict]:
    async with httpx.AsyncClient() as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks)
        return [r.json() for r in responses]  # max(latencias)
```

### Connection Pooling

```python
# ✅ Pool de conexiones DB
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    pool_size=10,           # Conexiones permanentes
    max_overflow=20,        # Conexiones adicionales bajo demanda
    pool_recycle=3600,      # Reciclar conexiones cada hora
    pool_pre_ping=True,     # Verificar conexión antes de usar
)

# ✅ Pool de conexiones HTTP
import httpx

client = httpx.Client(
    limits=httpx.Limits(
        max_connections=100,
        max_keepalive_connections=20,
    ),
    timeout=httpx.Timeout(10.0),
)
```

## Memory Management

### Evitar Memory Leaks

```python
# ❌ Acumulación en memoria
def process_large_file_bad(filepath: str):
    lines = []
    with open(filepath) as f:
        for line in f:
            lines.append(process(line))  # Crece indefinidamente
    return lines

# ✅ Generator/streaming
def process_large_file_good(filepath: str):
    with open(filepath) as f:
        for line in f:
            yield process(line)  # Procesa uno a la vez

# ✅ Chunks para archivos grandes
def process_in_chunks(filepath: str, chunk_size: int = 1000):
    with open(filepath) as f:
        chunk = []
        for line in f:
            chunk.append(process(line))
            if len(chunk) >= chunk_size:
                yield chunk
                chunk = []
        if chunk:
            yield chunk
```

### Lazy Loading

```python
# ❌ Cargar todo al inicio
class UserService:
    def __init__(self):
        self.all_users = db.query("SELECT * FROM users")  # Miles de registros

# ✅ Cargar bajo demanda
class UserService:
    def __init__(self):
        self._users_cache = None
    
    @property
    def users(self):
        if self._users_cache is None:
            self._users_cache = db.query("SELECT * FROM users")
        return self._users_cache
```

## API Performance

### Pagination OBLIGATORIA

```python
# ✅ Cursor-based pagination (recomendado para grandes datasets)
@app.get("/api/users")
def list_users(cursor: str | None = None, limit: int = 20):
    query = db.query(User).order_by(User.id)
    
    if cursor:
        query = query.filter(User.id > decode_cursor(cursor))
    
    users = query.limit(limit + 1).all()
    
    has_more = len(users) > limit
    users = users[:limit]
    
    return {
        "data": users,
        "next_cursor": encode_cursor(users[-1].id) if has_more else None,
    }

# ✅ Offset-based pagination (para datasets pequeños)
@app.get("/api/users")
def list_users(page: int = 1, per_page: int = 20):
    offset = (page - 1) * per_page
    users = db.query(User).offset(offset).limit(per_page).all()
    total = db.query(User).count()
    
    return {
        "data": users,
        "page": page,
        "per_page": per_page,
        "total": total,
    }
```

### Response Compression

```python
# FastAPI
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(GZipMiddleware, minimum_size=1000)
```

### Field Selection

```python
# ✅ Permitir selección de campos
@app.get("/api/users/{id}")
def get_user(id: int, fields: str | None = None):
    user = db.get(User, id)
    
    if fields:
        field_list = fields.split(",")
        return {f: getattr(user, f) for f in field_list if hasattr(user, f)}
    
    return user
```

## Frontend Performance

### Bundle Size

```typescript
// ❌ Importar librería completa
import _ from 'lodash';

// ✅ Importar solo lo necesario
import debounce from 'lodash/debounce';

// ❌ Importar todo de date-fns
import * as dateFns from 'date-fns';

// ✅ Tree-shakeable imports
import { format, parseISO } from 'date-fns';
```

### Lazy Loading Components

```typescript
// ✅ Code splitting con React
const Dashboard = lazy(() => import('./Dashboard'));
const Settings = lazy(() => import('./Settings'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

### Image Optimization

```html
<!-- ✅ Lazy loading nativo -->
<img src="image.jpg" loading="lazy" alt="..." />

<!-- ✅ Responsive images -->
<img
  srcset="image-400.jpg 400w, image-800.jpg 800w, image-1200.jpg 1200w"
  sizes="(max-width: 600px) 400px, (max-width: 1200px) 800px, 1200px"
  src="image-800.jpg"
  alt="..."
/>

<!-- ✅ Next.js Image -->
<Image src="/image.jpg" width={800} height={600} alt="..." />
```

## Performance Budgets

### Definir Límites

| Métrica | Target | Máximo |
|---------|--------|--------|
| API Response Time (p50) | < 100ms | < 200ms |
| API Response Time (p99) | < 500ms | < 1s |
| Page Load Time | < 2s | < 3s |
| Time to Interactive | < 3s | < 5s |
| Bundle Size (JS) | < 200KB | < 500KB |
| Memory Usage | < 256MB | < 512MB |

### Monitoreo

```python
# Logging de queries lentas
import logging
import time

class QueryLogger:
    SLOW_QUERY_THRESHOLD = 0.1  # 100ms
    
    def log_query(self, query: str, duration: float):
        if duration > self.SLOW_QUERY_THRESHOLD:
            logging.warning(f"Slow query ({duration:.3f}s): {query}")
```

## Profiling Tools

```bash
# Python
python -m cProfile -o output.prof script.py
py-spy top --pid <pid>
memory_profiler

# Go
go test -bench=. -benchmem
go tool pprof cpu.prof
go tool trace trace.out

# Node.js
node --prof app.js
node --inspect app.js  # Chrome DevTools

# Database
EXPLAIN ANALYZE SELECT ...
```

## Checklist Pre-Deploy

- [ ] Queries tienen índices apropiados
- [ ] No hay N+1 queries
- [ ] Paginación implementada en endpoints de listas
- [ ] Caching configurado para datos frecuentes
- [ ] Connection pooling configurado
- [ ] Assets comprimidos (gzip/brotli)
- [ ] Lazy loading para recursos pesados
- [ ] Performance budgets definidos y monitoreados
- [ ] Slow query logging habilitado
