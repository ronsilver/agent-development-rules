---
name: security-check
description: Verificar seguridad
---

# Workflow: Security Check

## Pasos

1. **Buscar secrets expuestos**
   ```bash
   grep -rE "(password|secret|api_key)\s*=" .
   git ls-files | grep -E "\.env$"
   ```

2. **Terraform**
   - Variables sensibles con `sensitive = true`
   - Security groups sin `0.0.0.0/0` innecesario

3. **Docker**
   - No root
   - Base images actualizadas

4. **Dependencias**
   - Node: `npm audit`
   - Python: `pip-audit`
   - Go: `govulncheck`

5. **Reportar findings**
