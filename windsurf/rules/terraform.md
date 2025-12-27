---
trigger: glob
globs: ["*.tf", "*.tfvars", "*.tftest.hcl"]
---

# Terraform Best Practices

## Validación Obligatoria

Después de cada cambio:
```bash
terraform fmt -recursive
terraform validate
terraform test  # si hay tests
```

## Estructura de Archivos

```
module/
├── main.tf           # Recursos principales
├── variables.tf      # Variables de entrada
├── outputs.tf        # Outputs
├── versions.tf       # Providers y versiones
├── locals.tf         # Variables locales
└── README.md
```

## Variables

### Siempre Incluir
- `type` - Tipo de dato
- `description` - Descripción clara

### Agregar Cuando Aplique
- `default` - Valor por defecto
- `validation` - Validación de valores
- `sensitive` - Para secrets

```hcl
variable "environment" {
  type        = string
  description = "Environment name"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be: dev, staging, or prod."
  }
}
```

## Outputs

Siempre con descripción:
```hcl
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}
```

## Naming Convention

```hcl
# Patrón: {tipo}_{propósito}
resource "aws_iam_role" "ecs_task_execution" { }
resource "aws_security_group" "web_ingress" { }
```

## Versiones

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}
```

## State

- Usar remote state (S3, Terraform Cloud, etc.)
- Habilitar state locking
- Nunca commitear `*.tfstate`

## Patrones Comunes

### Conditional Resources
```hcl
resource "aws_resource" "example" {
  count = var.create_resource ? 1 : 0
}
```

### For Each
```hcl
resource "aws_resource" "example" {
  for_each = var.resources
  name     = each.key
}
```

### Dynamic Blocks
```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    from_port = ingress.value.port
    to_port   = ingress.value.port
  }
}
```

## Anti-Patrones

- Hardcodear valores (usar variables)
- Variables sin descripción
- Outputs sin descripción
- No usar remote state
- Versiones de providers muy permisivas (`>= 4.0`)
