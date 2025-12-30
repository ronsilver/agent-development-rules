---
trigger: glob
globs: ["*.tf", "*.tfvars", "*.tftest.hcl"]
---

# Terraform Best Practices

## Validación Obligatoria

Después de cada cambio ejecutar:
```bash
terraform fmt -recursive -check  # Verificar formato
terraform validate               # Validar sintaxis
terraform test                   # Si hay tests configurados
```

## Estructura de Módulo

```
modules/nombre/
├── main.tf           # Recursos principales
├── variables.tf      # Variables de entrada
├── outputs.tf        # Valores de salida
├── versions.tf       # Provider requirements
├── locals.tf         # Variables locales computadas
├── data.tf           # Data sources (opcional)
└── README.md         # Documentación (terraform-docs)
```

## Variables - Requisitos

### Obligatorio
- `type` - Tipo de dato explícito
- `description` - Descripción clara del propósito

### Cuando Aplique
- `validation` - Validar valores permitidos
- `default` - Solo si tiene sentido un valor por defecto
- `sensitive = true` - Para secrets, passwords, tokens
- `nullable = false` - Cuando null no es válido

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be: dev, staging, or prod."
  }
}

variable "instance_count" {
  type        = number
  description = "Number of instances to create"
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "database_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
}
```

## Outputs

```hcl
output "instance_id" {
  description = "EC2 instance ID for the web server"
  value       = aws_instance.web.id
}

output "database_endpoint" {
  description = "RDS endpoint for database connections"
  value       = aws_db_instance.main.endpoint
  sensitive   = true  # Si contiene info sensible
}

# Output condicional
output "load_balancer_dns" {
  description = "ALB DNS name (only if ALB is created)"
  value       = var.create_alb ? aws_lb.main[0].dns_name : null
}
```

## Naming Convention

```hcl
# Patrón: {resource_type}_{purpose}
resource "aws_iam_role" "ecs_task_execution" { }
resource "aws_security_group" "alb_ingress" { }
resource "aws_s3_bucket" "application_logs" { }

# Para múltiples recursos similares
resource "aws_subnet" "private" {
  for_each = var.private_subnets
  # ...
}
```

## Provider Versions

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"  # Permitir minor updates
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"  # Permitir patch updates
    }
  }
}
```

## Tags Obligatorios

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Repository  = var.repository_url
  }
}

# En el provider para aplicar a todos los recursos
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
```

## State Management

```hcl
# Backend remoto con locking
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "project/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Patrones Comunes

### Recursos Condicionales
```hcl
# Usando count
resource "aws_cloudwatch_log_group" "app" {
  count = var.enable_logging ? 1 : 0
  name  = "/app/${var.environment}"
}

# Referencia condicional
log_group_arn = var.enable_logging ? aws_cloudwatch_log_group.app[0].arn : null
```

### For Each (preferido sobre count)
```hcl
resource "aws_iam_user" "developers" {
  for_each = toset(var.developer_names)
  name     = each.value
}

# Con mapa
resource "aws_s3_bucket" "buckets" {
  for_each = var.buckets
  bucket   = each.value.name
  # ...
}
```

### Dynamic Blocks
```hcl
resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

### Locals para Lógica Compleja
```hcl
locals {
  # Computar valores derivados
  is_production = var.environment == "prod"
  instance_type = local.is_production ? "t3.large" : "t3.micro"
  
  # Merge de configuraciones
  final_tags = merge(local.common_tags, var.extra_tags)
}
```

## Anti-Patrones

| Anti-Patrón | Solución |
|-------------|----------|
| Variables sin `description` | Siempre documentar propósito |
| Hardcodear valores | Usar variables con defaults |
| `count` con listas | Usar `for_each` (más predecible) |
| Providers sin version constraint | Especificar rango de versiones |
| State local en equipos | Usar remote state con locking |
| Secrets en `.tfvars` | Usar AWS Secrets Manager/SSM |
| Módulos sin README | Documentar con terraform-docs |
