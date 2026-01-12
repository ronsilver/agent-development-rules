# Agent Rules

Centralized development rules for AI agents (Windsurf, GitHub Copilot, Cursor, etc.).

## Structure

```
agent-rules/
├── manifest.yaml          # Central configuration
│
├── rules/                 # Development rules (centralized)
│   ├── global.md          # Agent behavior
│   ├── git.md             # Git/GitHub + Conventional Commits
│   ├── security.md        # OWASP Top 10:2025
│   ├── testing.md         # Testing Best Practices
│   ├── performance.md     # Performance
│   ├── scalability.md     # Scalability
│   ├── solid.md           # SOLID Principles
│   ├── operational-excellence.md  # SRE/Observability
│   ├── documentation.md   # Documentation
│   ├── terraform.md       # Terraform
│   ├── aws.md             # AWS
│   ├── go.md              # Go
│   ├── python.md          # Python
│   ├── nodejs.md          # Node.js/TypeScript
│   ├── bash.md            # Bash
│   ├── docker.md          # Docker
│   └── kubernetes.md      # Kubernetes
│
├── workflows/             # Workflows (slash commands)
│   ├── validate.md        # /validate
│   ├── test.md            # /test
│   ├── lint.md            # /lint
│   ├── pre-push.md        # /pre-push
│   ├── pr-review.md       # /pr-review
│   └── ...
│
├── prompts/               # Reusable Prompts
│   ├── review.prompt.md
│   ├── security.prompt.md
│   ├── test.prompt.md
│   └── ...
│
└── scripts/
    └── sync.sh            # Synchronization script
```

## Usage

### Sync Rules

```bash
# Sync to all enabled agents
./scripts/sync.sh

# Sync only one agent
./scripts/sync.sh --agent windsurf
./scripts/sync.sh --agent github-copilot

# Dry run (see what would happen)
./scripts/sync.sh --dry-run

# List available agents
./scripts/sync.sh --list
```

### Requirements

```bash
# Install yq (YAML parser)
brew install yq
```

## Configuration

### manifest.yaml

The `manifest.yaml` file defines:
- **Source Files**: List of rules, workflows, and prompts.
- **Agents**: Destination configuration per agent.

```yaml
# Agent configuration example
agents:
  windsurf:
    enabled: true
    targets:
      rules:
        path: "${HOME}/.codeium/memories/global_rules.md"
        format: merged
```

### Adding a New Agent

1. Add a section in `manifest.yaml` under `agents:`.
2. Configure `targets` with destination paths.
3. Run `./scripts/sync.sh --agent <name>`.

### Adding a New Rule

1. Create a file in `rules/<name>.md`.
2. Add it to the list in `manifest.yaml` under `rules.files`.
3. Run `./scripts/sync.sh`.

## Rule Content

### Operational Excellence
- **security.md** - OWASP Top 10:2025
- **testing.md** - Test Pyramid, coverage, naming
- **performance.md** - Big O, caching, queries
- **scalability.md** - Stateless, rate limiting, circuit breakers
- **operational-excellence.md** - Logs, metrics, alerts, SRE
- **solid.md** - SOLID Principles

### Technologies
- **terraform.md** - IaC best practices
- **aws.md** - AWS security, IAM, S3
- **go.md** - Go idioms
- **python.md** - Type hints, Pydantic
- **nodejs.md** - TypeScript, ESM
- **bash.md** - Shell scripting
- **docker.md** - Dockerfile best practices
- **kubernetes.md** - K8s/Helm patterns

### Process
- **git.md** - Conventional Commits (strict)
- **documentation.md** - ADRs, READMEs
- **global.md** - Agent behavior

## Quality Gates

### Linting & Formatting

All code **MUST** pass linting before commit/PR:

| Language | Tools | Configuration |
|----------|-------|---------------|
| **Go** | `golangci-lint v2`, `go fmt`, `go vet` | `.golangci.yml` |
| **Python** | `ruff` (format + lint), `mypy`, `bandit` | `pyproject.toml` |
| **TypeScript** | `prettier`, `eslint` (flat config), `tsc` | `eslint.config.js`, `tsconfig.json` |
| **Terraform** | `terraform fmt`, `tflint`, `checkov`, `tfsec` | `.tflint.hcl` |
| **Bash** | `shfmt`, `shellcheck` | `.shellcheckrc` |
| **Docker** | `hadolint`, `docker scout` | `.hadolint.yaml` |
| **Kubernetes** | `kubeval`, `helm lint`, `datree` | - |

See `rules/linting.md` for detailed configuration.

### Testing & Coverage

Minimum coverage requirements:

| Code Type | Coverage Target |
|-----------|----------------|
| **Critical Logic** | 90% |
| **Public API** | 80% |
| **Overall** | 70% |

**Commands**:
- Go: `go test -race -cover ./...`
- Python: `pytest --cov=src --cov-fail-under=70`
- Node/TS: `vitest run --coverage`

See `workflows/test.md` for detailed testing guidelines.

### Pre-commit Hooks

Use `.pre-commit-config.yaml.example` to catch issues before commit:

```bash
pip install pre-commit
cp .pre-commit-config.yaml.example .pre-commit-config.yaml
pre-commit install
```

## Supported Agents

| Agent | Status | Description |
|-------|--------|-------------|
| **windsurf** | ✅ Enabled | Windsurf IDE / Codeium Cascade |
| **github-copilot** | ✅ Enabled | VS Code / IntelliJ |
| **cursor** | ⬜ Disabled | Cursor IDE |
| **local-project** | ⬜ Disabled | Copy rules to local project |

## Development

### Rule Structure

```markdown
---
trigger: glob
globs: ["*.py", "*.go"]
---

# Rule Title

## Section 1

Content...

## Section 2

Content...
```

### Workflow Structure

```markdown
---
description: Workflow description
---

# /workflow-name

## Steps

1. Step 1
2. Step 2
```

## License

MIT
