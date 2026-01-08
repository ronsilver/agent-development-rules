---
trigger: glob
globs: ["*.py", "*.go", "*.js", "*.ts", "*.tf", "*.yaml", "*.yml", "Dockerfile"]
---

# Operational Excellence - SRE Best Practices

## Principios Fundamentales

1. **Observabilidad completa** - Logs, métricas, traces correlacionados
2. **Automation first** - Automatizar operaciones repetitivas
3. **Fail fast, recover faster** - Detectar y recuperar rápidamente
4. **Blameless postmortems** - Aprender de incidentes sin culpar
5. **Toil reduction** - Minimizar trabajo manual repetitivo

## Los Tres Pilares de Observabilidad

### 1. Logging - OBLIGATORIO

#### Formato Estructurado (JSON)

```python
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "service": "api",
            "environment": os.getenv("ENVIRONMENT", "development"),
        }
        
        # Agregar contexto si existe
        if hasattr(record, 'request_id'):
            log_entry["request_id"] = record.request_id
        if hasattr(record, 'user_id'):
            log_entry["user_id"] = record.user_id
        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)
        
        return json.dumps(log_entry)

# Configuración
handler = logging.StreamHandler()
handler.setFormatter(JSONFormatter())
logger = logging.getLogger()
logger.addHandler(handler)
logger.setLevel(logging.INFO)
```

#### Log Levels - Uso Correcto

| Level | Uso | Ejemplo |
|-------|-----|---------|
| **ERROR** | Errores que requieren atención | Falló conexión a DB, API externa falló |
| **WARNING** | Situaciones anómalas no críticas | Rate limit cerca, retry exitoso |
| **INFO** | Eventos de negocio importantes | Usuario creado, orden procesada |
| **DEBUG** | Información para debugging | Query ejecutada, parámetros de función |

```python
# ✅ Correcto - Contexto útil
logger.info("Order created", extra={
    "order_id": order.id,
    "user_id": user.id,
    "total": order.total,
    "items_count": len(order.items),
})

logger.error("Payment failed", extra={
    "order_id": order.id,
    "error_code": response.error_code,
    "provider": "stripe",
}, exc_info=True)

# ❌ Incorrecto - Sin contexto
logger.info("Order created")
logger.error("Error occurred")
```

#### Request ID Tracing - OBLIGATORIO

```python
import uuid
from contextvars import ContextVar

request_id_var: ContextVar[str] = ContextVar('request_id', default='')

@app.middleware("http")
async def request_id_middleware(request: Request, call_next):
    request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
    request_id_var.set(request_id)
    
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    
    return response

# Logger con request_id automático
class RequestIdFilter(logging.Filter):
    def filter(self, record):
        record.request_id = request_id_var.get('')
        return True

logger.addFilter(RequestIdFilter())
```

### 2. Metrics - OBLIGATORIO

#### RED Method (Request-oriented)

```python
from prometheus_client import Counter, Histogram, Gauge

# Rate - Requests per second
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

# Errors - Error rate
http_errors_total = Counter(
    'http_errors_total',
    'Total HTTP errors',
    ['method', 'endpoint', 'error_type']
)

# Duration - Latency
http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint'],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]
)

# Middleware para métricas
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    endpoint = request.url.path
    method = request.method
    status = response.status_code
    
    http_requests_total.labels(method, endpoint, status).inc()
    http_request_duration_seconds.labels(method, endpoint).observe(duration)
    
    if status >= 400:
        error_type = "client_error" if status < 500 else "server_error"
        http_errors_total.labels(method, endpoint, error_type).inc()
    
    return response
```

#### USE Method (Resource-oriented)

```python
# Utilization
db_connections_active = Gauge(
    'db_connections_active',
    'Active database connections'
)

# Saturation
db_connection_pool_waiting = Gauge(
    'db_connection_pool_waiting',
    'Requests waiting for DB connection'
)

# Errors
db_connection_errors_total = Counter(
    'db_connection_errors_total',
    'Database connection errors'
)

# Memory/CPU
process_memory_bytes = Gauge(
    'process_memory_bytes',
    'Process memory usage'
)
```

#### Business Metrics

```python
# Métricas de negocio
orders_created_total = Counter(
    'orders_created_total',
    'Total orders created',
    ['status', 'payment_method']
)

order_value_dollars = Histogram(
    'order_value_dollars',
    'Order value in dollars',
    buckets=[10, 25, 50, 100, 250, 500, 1000]
)

active_users = Gauge(
    'active_users',
    'Currently active users'
)
```

### 3. Distributed Tracing

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

# Setup
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

tracer = trace.get_tracer(__name__)

# Uso
@tracer.start_as_current_span("process_order")
def process_order(order_id: str):
    span = trace.get_current_span()
    span.set_attribute("order.id", order_id)
    
    with tracer.start_as_current_span("validate_order"):
        validate_order(order_id)
    
    with tracer.start_as_current_span("process_payment"):
        process_payment(order_id)
    
    with tracer.start_as_current_span("send_notification"):
        send_notification(order_id)
```

## Alerting - OBLIGATORIO

### SLIs, SLOs, SLAs

| Término | Definición | Ejemplo |
|---------|------------|---------|
| **SLI** | Métrica que mide el servicio | Latencia p99, error rate |
| **SLO** | Objetivo interno | p99 < 200ms, errors < 0.1% |
| **SLA** | Compromiso con cliente | 99.9% uptime |

### Alertas Efectivas

```yaml
# ✅ Correcto - Basada en SLO
groups:
  - name: slo-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_errors_total[5m])) 
          / sum(rate(http_requests_total[5m])) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error rate above 1% SLO"
          description: "Error rate is {{ $value | humanizePercentage }}"
          runbook: "https://wiki/runbooks/high-error-rate"
      
      - alert: HighLatency
        expr: |
          histogram_quantile(0.99, 
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
          ) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "p99 latency above 500ms SLO"
          runbook: "https://wiki/runbooks/high-latency"

# ❌ Incorrecto - Métricas sin contexto
      - alert: HighCPU
        expr: cpu_usage > 80  # No indica impacto en servicio
```

### Runbooks - OBLIGATORIO para cada alerta

```markdown
# Runbook: HighErrorRate

## Descripción
Error rate del API supera el 1% SLO.

## Impacto
- Usuarios experimentan errores
- Posible pérdida de transacciones

## Diagnóstico
1. Verificar logs de errores:
   ```bash
   kubectl logs -l app=api --tail=100 | grep ERROR
   ```

2. Verificar dependencias:
   - Database: `curl http://db:5432/health`
   - Redis: `redis-cli ping`
   - External API: `curl https://api.external.com/health`

3. Verificar métricas:
   - Grafana: https://grafana/d/api-dashboard

## Mitigación
1. Si es un deploy reciente → Rollback
   ```bash
   kubectl rollout undo deployment/api
   ```

2. Si es una dependencia → Activar circuit breaker
   ```bash
   curl -X POST http://api/admin/circuit-breaker/open
   ```

3. Si es sobrecarga → Escalar
   ```bash
   kubectl scale deployment/api --replicas=10
   ```

## Escalación
- Después de 15min sin resolver → Llamar a on-call secundario
- Después de 30min → Escalar a engineering manager
```

## Error Handling

### Clasificación de Errores

```python
from enum import Enum

class ErrorCategory(Enum):
    TRANSIENT = "transient"      # Reintentar
    CLIENT = "client"            # Error del cliente, no reintentar
    DEPENDENCY = "dependency"    # Servicio externo falló
    INTERNAL = "internal"        # Bug en nuestro código

class AppError(Exception):
    def __init__(
        self,
        message: str,
        category: ErrorCategory,
        status_code: int = 500,
        retryable: bool = False,
        details: dict = None,
    ):
        self.message = message
        self.category = category
        self.status_code = status_code
        self.retryable = retryable
        self.details = details or {}

# Errores específicos
class ValidationError(AppError):
    def __init__(self, message: str, details: dict = None):
        super().__init__(
            message=message,
            category=ErrorCategory.CLIENT,
            status_code=400,
            retryable=False,
            details=details,
        )

class ExternalServiceError(AppError):
    def __init__(self, service: str, message: str):
        super().__init__(
            message=message,
            category=ErrorCategory.DEPENDENCY,
            status_code=502,
            retryable=True,
            details={"service": service},
        )
```

### Retry con Exponential Backoff

```python
import time
from functools import wraps

def retry(
    max_attempts: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
    retryable_exceptions: tuple = (ExternalServiceError,),
):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except retryable_exceptions as e:
                    last_exception = e
                    
                    if attempt < max_attempts - 1:
                        delay = min(
                            base_delay * (exponential_base ** attempt),
                            max_delay
                        )
                        # Add jitter
                        delay *= (0.5 + random.random())
                        
                        logger.warning(f"Retry {attempt + 1}/{max_attempts}", extra={
                            "delay": delay,
                            "error": str(e),
                        })
                        time.sleep(delay)
            
            raise last_exception
        return wrapper
    return decorator

# Uso
@retry(max_attempts=3, base_delay=1.0)
def call_external_api(endpoint: str):
    response = requests.get(endpoint, timeout=5)
    if response.status_code >= 500:
        raise ExternalServiceError("external-api", f"HTTP {response.status_code}")
    return response.json()
```

## Deployment Safety

### Feature Flags

```python
from typing import Any

class FeatureFlags:
    def __init__(self, config_source):
        self.config = config_source
    
    def is_enabled(
        self,
        flag_name: str,
        user_id: str = None,
        default: bool = False,
    ) -> bool:
        flag = self.config.get(flag_name)
        if flag is None:
            return default
        
        # Global toggle
        if not flag.get("enabled", False):
            return False
        
        # Percentage rollout
        if percentage := flag.get("percentage"):
            if user_id:
                # Deterministic based on user
                return hash(f"{flag_name}:{user_id}") % 100 < percentage
            return random.randint(0, 99) < percentage
        
        # User whitelist
        if whitelist := flag.get("users"):
            return user_id in whitelist
        
        return flag.get("enabled", default)

# Uso
flags = FeatureFlags(config)

def process_order(order: Order):
    if flags.is_enabled("new_payment_flow", user_id=order.user_id):
        return new_payment_flow(order)
    return legacy_payment_flow(order)
```

### Canary Deployments

```yaml
# Kubernetes canary con Istio
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api
spec:
  hosts:
    - api
  http:
    - match:
        - headers:
            x-canary:
              exact: "true"
      route:
        - destination:
            host: api
            subset: canary
    - route:
        - destination:
            host: api
            subset: stable
          weight: 95
        - destination:
            host: api
            subset: canary
          weight: 5
```

### Rollback Automático

```yaml
# ArgoCD Rollback
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: api
spec:
  strategy:
    canary:
      steps:
        - setWeight: 5
        - pause: {duration: 5m}
        - setWeight: 20
        - pause: {duration: 5m}
        - setWeight: 50
        - pause: {duration: 5m}
        - setWeight: 100
      analysis:
        templates:
          - templateName: success-rate
        startingStep: 1
        args:
          - name: service-name
            value: api
---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  metrics:
    - name: success-rate
      interval: 1m
      successCondition: result[0] >= 0.99
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            sum(rate(http_requests_total{status=~"2.."}[5m]))
            / sum(rate(http_requests_total[5m]))
```

## Incident Management

### Severidades

| Severity | Definición | Response Time | Ejemplo |
|----------|------------|---------------|---------|
| **SEV1** | Outage total, impacto crítico | 15 min | API completamente caído |
| **SEV2** | Degradación severa | 30 min | 50% de requests fallando |
| **SEV3** | Degradación menor | 4 horas | Feature específica no funciona |
| **SEV4** | Issue menor | 24 horas | Logs no llegando a sistema |

### Incident Timeline

```markdown
## Incident #123: API Outage

### Timeline
- **14:00 UTC** - Alert: HighErrorRate triggered
- **14:02 UTC** - On-call acknowledged
- **14:05 UTC** - Identified: DB connection pool exhausted
- **14:10 UTC** - Mitigation: Increased pool size, restarted pods
- **14:15 UTC** - Service recovered
- **14:20 UTC** - Monitoring confirmed stable

### Impact
- Duration: 15 minutes
- Users affected: ~5,000
- Requests failed: ~12,000
- Revenue impact: ~$2,000

### Root Cause
Connection leak in new feature deployed at 13:45 UTC.
Connections not being returned to pool on certain error paths.

### Action Items
- [ ] Fix connection leak (owner: @dev, due: EOD)
- [ ] Add connection pool metrics to dashboard (owner: @sre)
- [ ] Add integration test for connection handling (owner: @dev)
- [ ] Review deployment checklist (owner: @team)
```

## Checklist Operational Excellence

### Observabilidad
- [ ] Logs estructurados en JSON
- [ ] Request ID en todos los logs
- [ ] Métricas RED implementadas
- [ ] Dashboards para cada servicio
- [ ] Tracing distribuido configurado

### Alerting
- [ ] SLOs definidos para cada servicio
- [ ] Alertas basadas en SLOs
- [ ] Runbooks para cada alerta
- [ ] On-call rotation configurada
- [ ] Escalation paths definidos

### Reliability
- [ ] Health checks (liveness + readiness)
- [ ] Graceful shutdown
- [ ] Circuit breakers para dependencias
- [ ] Retry con backoff exponencial
- [ ] Rate limiting

### Deployment
- [ ] Feature flags para rollouts
- [ ] Canary/blue-green deployments
- [ ] Rollback automático configurado
- [ ] Smoke tests post-deploy
