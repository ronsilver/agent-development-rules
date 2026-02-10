---
name: terraform-expert
description: Write and validate Terraform infrastructure code with 3-layer security (tflint, checkov, trivy). Use when the user asks to create Terraform modules, review IaC, or set up infrastructure as code.
license: MIT
---

# Terraform Expert

## Workflow

### Step 1: Validate with 3-Layer Security

Before any commit or PR, run this layered validation:

**Layer 1 — Code Quality (Pre-commit):**
```bash
terraform fmt -recursive -check     # Format
terraform validate                   # Syntax
tflint --recursive                   # Best practices
```

**Layer 2 — Security Scanning (CI/CD):**
```bash
checkov -d .                        # Security & compliance
trivy config .                      # Misconfigurations + vulnerability scanning
```

**Layer 3 — Documentation:**
```bash
terraform-docs markdown table . > README.md
```

**Stop immediately if any layer fails.**

### Step 2: Module Structure

```
modules/<name>/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
└── README.md
```

### Step 3: Variables — MANDATORY Rules

- `type`: MUST be explicit.
- `description`: MUST be present.
- Use `validation` blocks for constraints.

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

- **for_each > count**: Use `for_each` for lists/sets of resources.
- **Tags**: Enforce strict tagging (Env, Project, Owner, ManagedBy).
- **Secrets**: NEVER in `.tfvars`. Use AWS Secrets Manager / Vault.

## TFLint — Code Quality Layer

TFLint analyzes Terraform code for errors, best practices, and provider-specific issues.

### Installation

```bash
# macOS
brew install tflint
# Linux
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
# Docker
docker run --rm -v $(pwd):/data -t ghcr.io/terraform-linters/tflint
```

### Configuration — `.tflint.hcl`

```hcl
config {
  module = true
  force = false
}

# AWS Plugin — check latest: github.com/terraform-linters/tflint-ruleset-aws/releases
plugin "aws" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Azure Plugin — check latest: github.com/terraform-linters/tflint-ruleset-azurerm/releases
plugin "azurerm" {
  enabled = false
  version = "0.25.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# GCP Plugin — check latest: github.com/terraform-linters/tflint-ruleset-google/releases
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

- **Syntax**: Invalid attributes, unused variables, typos in resource names.
- **Best Practices**: snake_case naming, required_version constraints, deprecated syntax.
- **Provider-Specific** (AWS): Invalid instance types, deprecated attributes, region validation.

### Usage

```bash
tflint --init                    # Download plugins
tflint --recursive               # All modules
tflint --format json             # JSON output for CI/CD
tflint --format sarif            # SARIF for GitHub
```

## Checkov — Security & Compliance Layer

Checkov enforces security best practices and compliance standards (CIS, SOC 2, PCI-DSS).

### Installation

```bash
pip install checkov
# Or Docker
docker run --rm -v $(pwd):/tf bridgecrew/checkov -d /tf
```

### Configuration — `.checkov.yaml`

```yaml
branch: main
download-external-modules: true
evaluate-variables: true

skip-check:
  - CKV_AWS_79  # Example: specific exclusion

framework:
  - terraform
  - terraform_plan

check:
  - LOW
  - MEDIUM
  - HIGH
  - CRITICAL

external-checks-dir:
  - ./custom-policies

output:
  - cli
  - json
  - sarif
```

### Checkov Best Practices

```bash
# Baseline for existing infrastructure
checkov -d . --create-baseline
checkov -d . --baseline checkov_baseline.json

# SOC 2 compliance
checkov -d . --check CKV_AWS_*

# CI/CD: fail on CRITICAL/HIGH only
checkov -d . --compact --quiet --skip-download
checkov -d . -o json > checkov-report.json
```

## tfsec — DEPRECATED (use Trivy instead)

> **Note:** tfsec has been archived by Aqua Security and its functionality merged into **Trivy**.
> Use `trivy config .` instead of `tfsec .` for new projects.
> Existing projects using tfsec should migrate to Trivy.

```bash
# Migration: replace tfsec with trivy config
trivy config .                        # Equivalent to tfsec .
trivy config . --format json          # JSON output
trivy config . --format sarif         # SARIF for GitHub
trivy config . --severity HIGH,CRITICAL
```

## Tool Comparison

| Tool | Purpose | When to Use | Example Issues |
|------|---------|-------------|----------------|
| **TFLint** | Code quality & best practices | Pre-commit hook | Unused variables, typos, naming |
| **Checkov** | Security & compliance | CI/CD pipeline | CIS benchmarks, SOC 2 |
| **tfsec** *(deprecated)* | Security misconfigurations | Migrate to Trivy | Open security groups, unencrypted storage |
| **Trivy** | Vulnerability scanning | CI/CD pipeline | CVEs in modules, outdated providers |

## Pre-commit Integration

```yaml
repos:
  # pre-commit uses tag-based pinning (not SHA) by convention
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
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4

      # Layer 1: Code Quality
      - name: TFLint
        uses: terraform-linters/setup-tflint@90f302c255ef959cbfb4bd10581afecdb7ece3e6 # v4
        with:
          tflint_version: latest
      - run: tflint --init
      - run: tflint --recursive

      # Layer 2: Security
      - name: Checkov
        uses: bridgecrewio/checkov-action@f34885219720066007f948b843e747bb136aa223 # v12
        with:
          directory: .
          framework: terraform

      - name: Trivy Config Scan
        run: trivy config . --severity HIGH,CRITICAL --exit-code 1
```

## Checklist

- [ ] `tflint` passes (code quality)
- [ ] `checkov` passes (security & compliance)
- [ ] `trivy config` passes (security misconfigurations)
- [ ] `terraform-docs` generated
- [ ] All variables have `type` and `description`
- [ ] No hardcoded secrets
- [ ] Remote state configured with locking
- [ ] Tags enforced on all resources

## Constraints

- **NEVER** hardcode secrets in `.tf` or `.tfvars` files.
- **ALWAYS** run the 3-layer validation before committing.
- **ALWAYS** use `for_each` over `count` for resource collections.
- **ALWAYS** pin provider and module versions.
