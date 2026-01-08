---
trigger: glob
globs: ["*.py", "*.go", "*.js", "*.ts", "*.tf", "docker-compose*.yml", "*.yaml"]
---

# Scalability Best Practices - Excelencia Operativa

## Principios Fundamentales

1. **Diseñar para escalar desde el inicio** - No como afterthought
2. **Stateless services** - Estado fuera de la aplicación
3. **Horizontal over vertical** - Agregar instancias > agregar recursos
4. **Loose coupling** - Servicios independientes
5. **Graceful degradation** - Funcionar con capacidad reducida

## Stateless Services - OBLIGATORIO

### Principios
- No guardar estado en memoria de la aplicación
- Sesiones en store externo (Redis, DB)
- Archivos en storage externo (S3, GCS)
- Cualquier instancia puede manejar cualquier request

```python
# ❌ Stateful - No escala
class OrderService:
    def __init__(self):
        self.pending_orders = {}  # Estado en memoria
    
    def add_order(self, order_id: str, order: Order):
        self.pending_orders[order_id] = order  # Perdido si reinicia

# ✅ Stateless - Escala horizontalmente
class OrderService:
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
    
    def add_order(self, order_id: str, order: Order):
        self.redis.setex(
            f"order:{order_id}",
            ttl=3600,
            value=order.json()
        )
```

### Session Management

```python
# ✅ Sesiones en Redis
from flask import Flask
from flask_session import Session

app = Flask(__name__)
app.config['SESSION_TYPE'] = 'redis'
app.config['SESSION_REDIS'] = redis.from_url('redis://localhost:6379')
Session(app)
```

## Database Scalability

### Connection Pooling - OBLIGATORIO

```python
# ✅ Pool configurado para escala
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    pool_size=10,              # Conexiones base
    max_overflow=20,           # Conexiones adicionales
    pool_recycle=3600,         # Reciclar cada hora
    pool_pre_ping=True,        # Health check
    pool_timeout=30,           # Timeout para obtener conexión
)
```

### Read Replicas

```python
# ✅ Separar lecturas y escrituras
class DatabaseRouter:
    def __init__(self, write_engine, read_engine):
        self.write = write_engine
        self.read = read_engine
    
    def get_session(self, readonly: bool = False):
        engine = self.read if readonly else self.write
        return Session(bind=engine)

# Uso
def get_user(user_id: int):
    with db.get_session(readonly=True) as session:
        return session.query(User).get(user_id)

def create_user(data: dict):
    with db.get_session(readonly=False) as session:
        user = User(**data)
        session.add(user)
        session.commit()
```

### Sharding Patterns

```python
# ✅ Sharding por tenant/user
def get_shard(tenant_id: str) -> str:
    shard_count = 4
    shard_index = hash(tenant_id) % shard_count
    return f"shard_{shard_index}"

def get_connection(tenant_id: str):
    shard = get_shard(tenant_id)
    return connection_pools[shard]
```

## Async Processing

### Message Queues - OBLIGATORIO para tareas pesadas

```python
# ✅ Celery para tareas async
from celery import Celery

celery = Celery('tasks', broker='redis://localhost:6379')

@celery.task
def process_order(order_id: str):
    """Tarea pesada ejecutada async."""
    order = get_order(order_id)
    generate_invoice(order)
    send_notification(order.user_id)
    update_inventory(order.items)

# API endpoint - responde inmediatamente
@app.post("/orders")
def create_order(order: OrderCreate):
    order_id = save_order(order)
    process_order.delay(order_id)  # Async, no bloquea
    return {"order_id": order_id, "status": "processing"}
```

### Event-Driven Architecture

```python
# ✅ Eventos para desacoplar servicios
class EventBus:
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
    
    def publish(self, event_type: str, data: dict):
        event = {
            "type": event_type,
            "data": data,
            "timestamp": datetime.utcnow().isoformat(),
        }
        self.redis.publish(event_type, json.dumps(event))
    
    def subscribe(self, event_type: str, handler: Callable):
        pubsub = self.redis.pubsub()
        pubsub.subscribe(event_type)
        for message in pubsub.listen():
            if message['type'] == 'message':
                event = json.loads(message['data'])
                handler(event)

# Servicio A: Publica evento
event_bus.publish("order.created", {"order_id": "123", "user_id": "456"})

# Servicio B: Reacciona al evento
@event_bus.subscribe("order.created")
def handle_order_created(event):
    send_email(event['data']['user_id'], "Order confirmed!")
```

## Rate Limiting - OBLIGATORIO

### Token Bucket Algorithm

```python
import redis
import time

class RateLimiter:
    def __init__(self, redis_client: Redis):
        self.redis = redis_client
    
    def is_allowed(
        self,
        key: str,
        max_requests: int,
        window_seconds: int
    ) -> bool:
        current = int(time.time())
        window_key = f"ratelimit:{key}:{current // window_seconds}"
        
        pipe = self.redis.pipeline()
        pipe.incr(window_key)
        pipe.expire(window_key, window_seconds)
        results = pipe.execute()
        
        current_count = results[0]
        return current_count <= max_requests

# Uso en middleware
@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    client_ip = request.client.host
    
    if not rate_limiter.is_allowed(client_ip, max_requests=100, window_seconds=60):
        return JSONResponse(
            status_code=429,
            content={"error": "Too many requests"},
            headers={"Retry-After": "60"}
        )
    
    return await call_next(request)
```

### Rate Limiting por Tier

```python
RATE_LIMITS = {
    "free": {"requests": 100, "window": 3600},
    "pro": {"requests": 1000, "window": 3600},
    "enterprise": {"requests": 10000, "window": 3600},
}

def get_rate_limit(user: User) -> dict:
    return RATE_LIMITS.get(user.tier, RATE_LIMITS["free"])
```

## Circuit Breaker

```python
from enum import Enum
import time

class CircuitState(Enum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing if recovered

class CircuitBreaker:
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: int = 30,
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failures = 0
        self.state = CircuitState.CLOSED
        self.last_failure_time = None
    
    def call(self, func: Callable, *args, **kwargs):
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = CircuitState.HALF_OPEN
            else:
                raise CircuitOpenError("Service unavailable")
        
        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise
    
    def _on_success(self):
        self.failures = 0
        self.state = CircuitState.CLOSED
    
    def _on_failure(self):
        self.failures += 1
        self.last_failure_time = time.time()
        if self.failures >= self.failure_threshold:
            self.state = CircuitState.OPEN

# Uso
payment_circuit = CircuitBreaker(failure_threshold=3, recovery_timeout=60)

def process_payment(order_id: str):
    return payment_circuit.call(payment_gateway.charge, order_id)
```

## Load Balancing

### Health Checks - OBLIGATORIO

```python
# ✅ Health endpoint completo
@app.get("/health")
def health_check():
    checks = {
        "database": check_database(),
        "redis": check_redis(),
        "external_api": check_external_api(),
    }
    
    all_healthy = all(c["status"] == "healthy" for c in checks.values())
    
    return {
        "status": "healthy" if all_healthy else "unhealthy",
        "checks": checks,
        "timestamp": datetime.utcnow().isoformat(),
    }

def check_database() -> dict:
    try:
        db.execute("SELECT 1")
        return {"status": "healthy", "latency_ms": latency}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}

# ✅ Liveness vs Readiness
@app.get("/health/live")
def liveness():
    """App está corriendo."""
    return {"status": "ok"}

@app.get("/health/ready")
def readiness():
    """App puede recibir tráfico."""
    if not db.is_connected():
        return JSONResponse(status_code=503, content={"status": "not ready"})
    return {"status": "ready"}
```

### Graceful Shutdown

```python
import signal
import sys

class GracefulShutdown:
    def __init__(self):
        self.is_shutting_down = False
        signal.signal(signal.SIGTERM, self._handle_signal)
        signal.signal(signal.SIGINT, self._handle_signal)
    
    def _handle_signal(self, signum, frame):
        print("Received shutdown signal, finishing pending requests...")
        self.is_shutting_down = True
        
        # Dar tiempo para terminar requests en curso
        time.sleep(10)
        
        # Cerrar conexiones
        db.close()
        redis.close()
        
        sys.exit(0)

# Middleware para rechazar nuevos requests durante shutdown
@app.middleware("http")
async def shutdown_middleware(request: Request, call_next):
    if graceful_shutdown.is_shutting_down:
        return JSONResponse(
            status_code=503,
            content={"error": "Service shutting down"},
            headers={"Retry-After": "30"}
        )
    return await call_next(request)
```

## Caching Distribuido

### Multi-Layer Cache

```python
class MultiLayerCache:
    def __init__(self, local_cache: dict, redis_client: Redis):
        self.local = local_cache  # L1: In-memory, muy rápido
        self.redis = redis_client  # L2: Redis, compartido
    
    def get(self, key: str):
        # L1: Local
        if key in self.local:
            return self.local[key]
        
        # L2: Redis
        value = self.redis.get(key)
        if value:
            self.local[key] = json.loads(value)  # Populate L1
            return self.local[key]
        
        return None
    
    def set(self, key: str, value: any, ttl: int = 300):
        self.local[key] = value
        self.redis.setex(key, ttl, json.dumps(value))
    
    def invalidate(self, key: str):
        self.local.pop(key, None)
        self.redis.delete(key)
```

## Auto-Scaling Configuration

### Kubernetes HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
```

### AWS Auto Scaling

```hcl
resource "aws_autoscaling_group" "api" {
  name                = "api-asg"
  vpc_zone_identifier = var.private_subnet_ids
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 2
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  launch_template {
    id      = aws_launch_template.api.id
    version = "$Latest"
  }
  
  target_group_arns = [aws_lb_target_group.api.arn]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  autoscaling_group_name = aws_autoscaling_group.api.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 2
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
}
```

## Checklist Escalabilidad

### Diseño
- [ ] Servicios stateless
- [ ] Estado en stores externos (Redis, S3)
- [ ] Tareas pesadas en queues async
- [ ] Circuit breakers para dependencias externas

### Database
- [ ] Connection pooling configurado
- [ ] Read replicas para lecturas
- [ ] Índices optimizados
- [ ] Plan de sharding si necesario

### Infraestructura
- [ ] Health checks implementados (liveness + readiness)
- [ ] Graceful shutdown configurado
- [ ] Auto-scaling configurado
- [ ] Rate limiting implementado

### Monitoreo
- [ ] Métricas de requests/latencia/errores
- [ ] Alertas en thresholds críticos
- [ ] Dashboards de capacidad
