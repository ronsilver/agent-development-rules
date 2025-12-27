# Kubernetes Instructions

## Resources

- Siempre definir requests y limits
- Requests = uso normal
- Limits = máximo permitido

## Probes

- livenessProbe para restart
- readinessProbe para traffic

## Labels

- Usar labels estándar de Kubernetes
- app.kubernetes.io/name, /instance, /version

## Seguridad

- No correr como root
- SecurityContext restrictivo
- ServiceAccount con mínimos privilegios
