---
name: terraform-module
description: Crear módulo de Terraform
---

# Workflow: Crear Módulo Terraform

## Pasos

1. **Analizar estructura existente**
   - Patrones de naming
   - Providers configurados

2. **Crear estructura**
   ```
   modules/nombre/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   ├── versions.tf
   └── README.md
   ```

3. **Implementar recursos**

4. **Agregar variables** con descripción y validación

5. **Agregar outputs** con descripción

6. **Validar**
   ```bash
   terraform fmt -recursive
   terraform validate
   ```

7. **Documentar** en README
