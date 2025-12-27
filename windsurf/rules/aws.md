---
trigger: glob
globs: ["*.tf", "*.tfvars"]
---

# AWS Best Practices

## IAM

### Least Privilege
- Permisos mínimos necesarios
- Usar roles en lugar de users cuando sea posible
- Conditions para restringir acceso

```hcl
data "aws_iam_policy_document" "example" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]
  }
}
```

## Security Groups

### Reglas
- Evitar `0.0.0.0/0` en ingress cuando sea posible
- Usar referencias a otros security groups
- Descripción en cada regla

```hcl
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## S3

### Configuración Segura
- Bloquear acceso público por defecto
- Habilitar versionado
- Encryption at rest

```hcl
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## Secrets

### Nunca en Código
- Usar AWS Secrets Manager
- O SSM Parameter Store (SecureString)
- Variables `sensitive = true` en Terraform

```hcl
variable "db_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}
```

## Tags

### Obligatorios
```hcl
provider "aws" {
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "terraform"
    }
  }
}
```

## Logging

- CloudWatch Logs para aplicaciones
- S3 access logs
- VPC Flow Logs
- CloudTrail habilitado

## Networking

### VPC
- Subnets públicas y privadas
- NAT Gateway para salida de subnets privadas
- VPC endpoints para servicios AWS

## Comandos Útiles

```bash
# Verificar identidad
aws sts get-caller-identity

# Ver recursos
aws ec2 describe-instances
aws s3 ls

# Logs
aws logs tail /aws/lambda/function-name --follow
```
