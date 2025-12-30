# Terraform Instructions

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
  description = "Deployment environment"
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be: dev, staging, or prod."
  }
}

variable "database_password" {
  type        = string
  description = "Database master password"
  sensitive   = true
}
```

## Recursos

### Naming Convention
```hcl
# Patrón: {resource_type}_{purpose}
resource "aws_iam_role" "ecs_task_execution" { }
resource "aws_security_group" "alb_ingress" { }
resource "aws_s3_bucket" "application_logs" { }
```

### Preferencias
- `for_each` sobre `count` (más predecible en cambios)
- Bloques `dynamic` para configuración condicional
- `locals` para valores computados reutilizables

### Tags Obligatorios
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
    Repository  = var.repository_url
  }
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
```

## Estructura de Módulo

```
modules/nombre/
├── main.tf           # Recursos principales
├── variables.tf      # Variables de entrada
├── outputs.tf        # Valores de salida
├── versions.tf       # Provider requirements
├── locals.tf         # Variables locales
├── data.tf           # Data sources (opcional)
└── README.md         # Documentación
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
resource "aws_cloudwatch_log_group" "app" {
  count = var.enable_logging ? 1 : 0
  name  = "/app/${var.environment}"
}
```

### For Each (preferido sobre count)
```hcl
resource "aws_iam_user" "developers" {
  for_each = toset(var.developer_names)
  name     = each.value
}
```

### Dynamic Blocks
```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    from_port   = ingress.value.port
    to_port     = ingress.value.port
    protocol    = "tcp"
    cidr_blocks = ingress.value.cidr_blocks
  }
}
```

### Locals para Lógica Compleja
```hcl
locals {
  is_production = var.environment == "prod"
  instance_type = local.is_production ? "t3.large" : "t3.micro"
  final_tags    = merge(local.common_tags, var.extra_tags)
}
```

## Validación Obligatoria

```bash
terraform fmt -recursive -check
terraform validate
terraform test  # Si hay tests configurados
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
