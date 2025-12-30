---
name: terraform-module
description: Crear módulo de Terraform siguiendo best practices
---

# Workflow: Crear Módulo Terraform

Crear un módulo de Terraform reutilizable y bien documentado.

## 1. Analizar Contexto

```bash
# Verificar estructura existente
ls -la modules/

# Revisar patrones de naming
grep -h 'resource "' modules/*/*.tf | head -20

# Ver providers configurados
cat versions.tf
```

## 2. Crear Estructura

```
modules/<nombre>/
├── main.tf           # Recursos principales
├── variables.tf      # Variables de entrada
├── outputs.tf        # Valores de salida
├── versions.tf       # Provider requirements
├── locals.tf         # Variables locales (opcional)
├── data.tf           # Data sources (opcional)
└── README.md         # Documentación
```

## 3. Implementar Archivos

### versions.tf
```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

### variables.tf
```hcl
variable "name" {
  type        = string
  description = "Name prefix for resources"
  
  validation {
    condition     = length(var.name) <= 32
    error_message = "Name must be 32 characters or less."
  }
}

variable "environment" {
  type        = string
  description = "Environment (dev, staging, prod)"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be: dev, staging, or prod."
  }
}

variable "tags" {
  type        = map(string)
  description = "Additional tags for resources"
  default     = {}
}
```

### outputs.tf
```hcl
output "id" {
  description = "Resource ID"
  value       = aws_resource.main.id
}

output "arn" {
  description = "Resource ARN"
  value       = aws_resource.main.arn
}
```

### locals.tf
```hcl
locals {
  name_prefix = "${var.name}-${var.environment}"
  
  common_tags = merge(var.tags, {
    Module      = "<nombre>"
    Environment = var.environment
  })
}
```

## 4. Validar

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

## 5. Documentar

```bash
# Generar docs automáticamente
terraform-docs markdown table --output-file README.md modules/<nombre>
```

## 6. Ejemplo de Uso

Agregar en README.md:
```hcl
module "example" {
  source = "./modules/<nombre>"

  name        = "my-resource"
  environment = "dev"
  
  tags = {
    Project = "my-project"
  }
}
```

## Checklist

- [ ] Todas las variables tienen `type` y `description`
- [ ] Variables sensibles tienen `sensitive = true`
- [ ] Todos los outputs tienen `description`
- [ ] Naming sigue convención del proyecto
- [ ] `terraform validate` pasa
- [ ] README.md actualizado
