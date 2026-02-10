---
name: aws-cloud-expert
description: Design and implement secure AWS infrastructure following least privilege, encryption, and IaC principles. Use when the user asks about AWS services, IAM policies, S3, security groups, or cloud architecture.
license: MIT
---

# AWS Cloud Expert

## Core Principles — NON-NEGOTIABLE

1. **Least Privilege**: NEVER use `Action: "*"`. Always list specific actions.
2. **Infrastructure as Code**: All resources via Terraform/CDK. No ClickOps in production.
3. **Encryption Everywhere**: Data in transit (TLS) and at rest (KMS/AES256).

## IAM — Least Privilege

- Use **Roles** over Users (especially for services).
- Use **Conditions** to restrict access (IP, time, tags).
- Avoid `*` in actions and resources.

```hcl
# ✅ Correct — specific permissions
data "aws_iam_policy_document" "app_s3" {
  statement {
    sid     = "ReadAppBucket"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.app.arn,
      "${aws_s3_bucket.app.arn}/*",
    ]
  }
}

# ❌ Too permissive
data "aws_iam_policy_document" "bad" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}
```

## Security Groups

- Avoid `0.0.0.0/0` in ingress (except public ALB/NLB).
- Reference other Security Groups for internal traffic.
- Mandatory description for every rule.
- Restrictive egress where possible.

## S3 — Secure Configuration

- **Block Public Access**: Enable all block settings.
- **Versioning**: Enabled for recovery.
- **Encryption**: SSE-S3 or KMS.
- **Lifecycle**: Transition old objects to IA/Glacier.

## Secrets Management

- NEVER hardcode secrets in Terraform.
- Use `aws_secretsmanager_secret` or `aws_ssm_parameter` (SecureString).

## Mandatory Tags

All resources MUST have:

| Tag | Example |
|-----|---------|
| `Environment` | dev, staging, prod |
| `Project` | my-app |
| `ManagedBy` | terraform |
| `CostCenter` | engineering |

## Logging & Monitoring

- **Apps**: CloudWatch Logs with explicit retention (e.g., 90 days).
- **S3/ALB**: Access Logs enabled.
- **VPC**: Flow Logs enabled.
- Never use "Never Expire" retention.

## Cost Control

- **Lifecycle Policies**: Enforce on S3 and ECR.
- **Instance Types**: T3/T4g for variable loads. Spot for stateless workers.
- **Clean up**: Remove unused EIPs, EBS volumes, Snapshots.

## Constraints

- **NEVER** use `Action: "*"` or `Resource: "*"` in IAM policies.
- **NEVER** hardcode secrets — use Secrets Manager or SSM Parameter Store.
- **ALWAYS** enable encryption at rest and in transit.
- **ALWAYS** tag all resources with the mandatory tag set.
