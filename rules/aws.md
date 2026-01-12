---
trigger: glob
globs: ["*.tf", "*.tfvars"]
---

# AWS Best Practices

## Core Principles - NON-NEGOTIABLE

1.  **Least Privilege**: NEVER use `Action: "*"`. Always list specific actions.
2.  **Infrastructure as Code**: All resources must be created via Terraform/CDK. ClickOps is forbidden for Prod.
3.  **Encryption Everywhere**: Data in transit (TLS) and at rest (KMS/AES256).

## IAM - Least Privilege

### Guidelines
- Minimal permissions required for the task.
- Use Roles over Users (especially for services).
- Use Conditions to restrict access (IP, time, tags).
- Avoid `*` in actions and resources.

```hcl
# ✅ Correct - Specific permissions
data "aws_iam_policy_document" "app_s3" {
  statement {
    sid     = "ReadAppBucket"
    effect  = "Allow"
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

# ❌ Avoid - Too permissive
data "aws_iam_policy_document" "bad" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}
```

## Security Groups

### Rules
- Avoid `0.0.0.0/0` in ingress (except public ALB/NLB).
- Reference other Security Groups, not CIDRs, for internal traffic.
- **Mandatory description** for every rule.
- Restrictive egress where possible.

## S3 - Secure Configuration

- **Block Public Access**: Enable `block_public_acls`, `block_public_policy`, etc.
- **Versioning**: Enabled for recovery.
- **Encryption**: Server-side encryption (SSE-S3 or KMS).
- **Lifecycle**: Transition old objects to IA/Glacier to save costs.

## Secrets Management

### AWS Secrets Manager / SSM Parameter Store
- NEVER hardcode secrets in Terraform.
- Use `aws_secretsmanager_secret` or `aws_ssm_parameter` (SecureString).

## Mandatory Tags

All resources must have standard tags:
- `Environment` (dev, prod)
- `Project`
- `ManagedBy` (terraform)
- `CostCenter`

## Logging & Monitoring
- **Apps**: CloudWatch Logs.
- **S3/ALB**: Access Logs enabled.
- **VPC**: Flow Logs enabled.
- **Retention**: Set explicit retention (e.g., 90 days), never "Never Expire".

## Cost Control
- **Lifecycle Policies**: Enforce on S3 and ECR.
- **Instance Types**: Use T3/T4g for variable loads. Spot instances for stateless workers.
- **Clean up**: Remove unused EIPs, EBS volumes, and Snapshots.
