---
name: terraform-module
description: Create a Terraform module following best practices
---

# Workflow: Create Terraform Module

## 1. Structure
Create standard layout:
```
modules/<name>/
├── main.tf           # Resources
├── variables.tf      # Inputs
├── outputs.tf        # Outputs
├── versions.tf       # Providers
├── README.md         # Documentation
```

## 2. Implementation Rules

### `versions.tf`
Must define `required_version` and `required_providers`.

### `variables.tf`
- **MANDATORY**: `description` and `type` for ALL variables.
- **MANDATORY**: validation blocks for inputs where possible.

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment (dev, prod)"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Invalid environment."
  }
}
```

## 3. Validation
```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
# STOP if validation fails
```

## 4. Documentation
Generate `README.md` automatically:
```bash
terraform-docs markdown table --output-file README.md .
```
