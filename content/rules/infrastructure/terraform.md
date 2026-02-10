---
trigger: glob
globs: ["*.tf", "*.tfvars", "*.tftest.hcl"]
---

# Terraform Best Practices

## Mandatory Verification - Layered Security Approach

Before any commit or PR, you **MUST** run this **3-layer validation**:

### Layer 1: Code Quality (Pre-commit)
```bash
terraform fmt -recursive -check     # Format check
terraform validate                   # Syntax validation
tflint --recursive                   # Best practices linting
```

### Layer 2: Security Scanning (CI/CD)
```bash
checkov -d .                        # Security & compliance
tfsec .                             # Security misconfigurations
trivy config .                      # Vulnerability scanning
```

### Layer 3: Documentation (CI/CD)
```bash
terraform-docs markdown table . > README.md
```

**Stop immediately if any layer fails.**

## Module Structure

```
modules/name/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

## Variables

### Requirements
- **`type`**: MUST be explicit.
- **`description`**: MUST be present.

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Invalid environment."
  }
}
```

## Naming Convention
- `snake_case` for everything (resources, variables, outputs).
- Resource names should be descriptive: `aws_s3_bucket.app_logs`.

## State Management
- **Remote State**: Always use remote backend (S3+DynamoDB, Terraform Cloud).
- **Locking**: Ensure state locking is enabled.

## Best Practices
- **For Each** > **Count**: Use `for_each` for lists/sets of resources.
- **Tags**: Enforce strict tagging (Env, Project, Owner).
- **Secrets**: NEVER in `.tfvars`. Use AWS Secrets Manager.

## TFLint Configuration - Code Quality Layer

TFLint analyzes Terraform code for errors, best practices, and provider-specific issues **before** security scanning.

### Installation
```bash
# macOS
brew install tflint

# Linux
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Docker
docker run --rm -v $(pwd):/data -t ghcr.io/terraform-linters/tflint
```

### Configuration - `.tflint.hcl`

```hcl
# .tflint.hcl
config {
  module = true
  force = false
}

# AWS Plugin (for AWS resources)
plugin "aws" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Azure Plugin
plugin "azurerm" {
  enabled = false
  version = "0.25.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# GCP Plugin
plugin "google" {
  enabled = false
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

# Core rules
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}
```

### TFLint Rules Categories

**Syntax Issues**:
- Detects invalid resource attributes
- Finds unused variables
- Checks for typos in resource names

**Best Practices**:
- Enforces snake_case naming (not dashes)
- Validates required_version constraints
- Checks for deprecated syntax (e.g., `"${var.foo}"` → `var.foo`)

**Provider-Specific** (AWS example):
- Invalid instance types
- Deprecated resource attributes
- Region-specific validation

### Usage

```bash
# Initialize TFLint (downloads plugins)
tflint --init

# Run linting
tflint

# Recursive (all modules)
tflint --recursive

# Format: JSON/SARIF for CI/CD
tflint --format json
tflint --format sarif

# With specific config file
tflint --config .tflint.hcl
```

## Checkov Configuration - Security & Compliance Layer

Checkov enforces security best practices and compliance standards (CIS, SOC 2, PCI-DSS).

### Installation
```bash
pip install checkov

# Or use Docker
docker run --rm -v $(pwd):/tf bridgecrew/checkov -d /tf
```

### Configuration - `.checkov.yaml`

```yaml
# .checkov.yaml
branch: main
download-external-modules: true
evaluate-variables: true

# Skip specific checks
skip-check:
  - CKV_AWS_79  # Example: S3 bucket encryption with specific KMS key

# Frameworks to scan
framework:
  - terraform
  - terraform_plan

# Severity filters
check:
  - LOW
  - MEDIUM
  - HIGH
  - CRITICAL

# Custom policies directory
external-checks-dir:
  - ./custom-policies

# Output formats
output:
  - cli
  - json
  - sarif
```

### Checkov Best Practices

**Baseline Creation** (for existing infrastructure):
```bash
# Create baseline (ignore existing issues)
checkov -d . --create-baseline

# Run with baseline
checkov -d . --baseline checkov_baseline.json
```

**SOC 2 Compliance**:
```bash
checkov -d . --check CKV_AWS_*
```

**CI/CD Integration**:
```bash
# Fail on CRITICAL/HIGH only
checkov -d . --compact --quiet --skip-download

# Generate report
checkov -d . -o json > checkov-report.json
```

## tfsec Configuration - Security Misconfigurations

tfsec performs static analysis for security misconfigurations.

### Installation
```bash
# macOS
brew install tfsec

# Linux
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
```

### Configuration - `.tfsec.yaml`

```yaml
# .tfsec.yaml
severity_overrides:
  CKV_AWS_79: LOW

exclude:
  - aws-s3-enable-versioning  # Specific exclusion

minimum_severity: MEDIUM
```

### Usage

```bash
# Run tfsec
tfsec .

# With specific format
tfsec . --format json
tfsec . --format sarif

# Exclude specific checks
tfsec . --exclude aws-s3-enable-versioning

# Soft fail (exit 0 even with issues)
tfsec . --soft-fail
```

## Tool Comparison & When to Use Each

| Tool | Purpose | When to Use | Example Issues |
|------|---------|-------------|----------------|
| **TFLint** | Code quality & best practices | Pre-commit hook | Unused variables, typos, naming conventions |
| **Checkov** | Security & compliance | CI/CD pipeline | CIS benchmarks, SOC 2 compliance |
| **tfsec** | Security misconfigurations | CI/CD pipeline | Open security groups, unencrypted storage |
| **Trivy** | Vulnerability scanning | CI/CD pipeline | CVEs in modules, outdated providers |

## Pre-commit Integration

Create `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.88.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
        args:
          - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl
      - id: terraform_docs
        args:
          - --hook-config=--path-to-file=README.md
```

## CI/CD Pipeline Example

```yaml
# GitHub Actions
name: Terraform Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1

      # Layer 1: Code Quality
      - name: TFLint
        uses: terraform-linters/setup-tflint@v4
        with:
          tflint_version: latest
      - run: tflint --init
      - run: tflint --recursive

      # Layer 2: Security
      - name: Checkov
        uses: bridgecrewio/checkov-action@master # TODO: pin to SHA
        with:
          directory: .
          framework: terraform

      - name: tfsec
        uses: aquasecurity/tfsec-action@v1.0.0 # TODO: pin to SHA
        with:
          soft_fail: false
```

## Quality Checklist
- [ ] `tflint` passes (code quality).
- [ ] `checkov` passes (security & compliance).
- [ ] `tfsec` passes (security misconfigurations).
- [ ] `terraform-docs` generated.
- [ ] All variables have descriptions.
- [ ] No hardcoded secrets.
