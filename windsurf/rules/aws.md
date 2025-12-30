---
trigger: glob
globs: ["*.tf", "*.tfvars"]
---

# AWS Best Practices

## IAM - Least Privilege

### Principios
- Permisos mínimos necesarios para la tarea
- Roles sobre users (para servicios y aplicaciones)
- Conditions para restringir acceso por IP, tiempo, tags
- Evitar `*` en actions y resources

```hcl
# ✅ Correcto - Permisos específicos
data "aws_iam_policy_document" "app_s3" {
  statement {
    sid    = "ReadAppBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.app.arn,
      "${aws_s3_bucket.app.arn}/*",
    ]
  }
}

# ❌ Evitar - Demasiado permisivo
data "aws_iam_policy_document" "bad" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}
```

### IAM Roles para Servicios
```hcl
# ECS Task Role
resource "aws_iam_role" "ecs_task" {
  name = "${var.project}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Lambda con IRSA
resource "aws_iam_role" "lambda" {
  name = "${var.project}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
```

## Security Groups

### Reglas
- Evitar `0.0.0.0/0` en ingress excepto para ALB/NLB públicos
- Usar referencias a otros security groups (no CIDRs)
- Descripción obligatoria en cada regla
- Egress restrictivo cuando sea posible

```hcl
resource "aws_security_group" "web" {
  name        = "${var.project}-web-sg"
  description = "Security group for web servers"
  vpc_id      = var.vpc_id

  # Ingress desde ALB solamente
  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Egress restrictivo
  egress {
    description = "HTTPS to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-web-sg"
  }
}
```

## S3 - Configuración Segura

```hcl
resource "aws_s3_bucket" "app" {
  bucket = "${var.project}-${var.environment}-app"
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versionado
resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # O usar KMS para más control
    }
  }
}

# Lifecycle para costos
resource "aws_s3_bucket_lifecycle_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    id     = "transition-old-objects"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}
```

## Secrets Management

### AWS Secrets Manager
```hcl
# Crear secret
resource "aws_secretsmanager_secret" "db" {
  name        = "${var.project}/${var.environment}/db"
  description = "Database credentials"
}

# Leer secret existente
data "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
}

# Usar en aplicación
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)
}
```

### SSM Parameter Store
```hcl
# Parámetro seguro
resource "aws_ssm_parameter" "api_key" {
  name        = "/${var.project}/${var.environment}/api-key"
  description = "External API key"
  type        = "SecureString"
  value       = var.api_key
}

# Leer parámetro
data "aws_ssm_parameter" "api_key" {
  name            = "/${var.project}/${var.environment}/api-key"
  with_decryption = true
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
    CostCenter  = var.cost_center
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
```

## Logging y Monitoreo

| Servicio | Logs |
|----------|------|
| Aplicaciones | CloudWatch Logs |
| S3 | Access Logs + CloudTrail |
| VPC | Flow Logs |
| ALB/NLB | Access Logs a S3 |
| API Gateway | CloudWatch Logs |
| Lambda | CloudWatch Logs (automático) |

## Networking - VPC

```hcl
# Estructura típica
locals {
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

# VPC Endpoints para tráfico privado
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id
}
```

## Comandos Útiles

```bash
# Verificar identidad
aws sts get-caller-identity

# EC2
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table

# S3
aws s3 ls s3://bucket-name/
aws s3 sync ./local s3://bucket/path

# Logs
aws logs tail /aws/lambda/function-name --follow --since 1h

# Secrets
aws secretsmanager get-secret-value --secret-id my-secret --query SecretString --output text

# SSM
aws ssm get-parameter --name /path/to/param --with-decryption --query Parameter.Value --output text
```
