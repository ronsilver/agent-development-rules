---
name: validate
description: Validar configuración de Terraform
---

# Workflow: Validar Terraform

## Pasos

1. **Formatear**
   ```bash
   terraform fmt -recursive
   ```

2. **Inicializar**
   ```bash
   terraform init -backend=false
   ```

3. **Validar**
   ```bash
   terraform validate
   ```

4. **Tests** (si existen)
   ```bash
   terraform test
   ```

5. **Verificar git status**
   - Reportar archivos sin trackear
   - Alertar si hay archivos sensibles
