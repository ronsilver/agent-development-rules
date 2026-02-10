# Agent Development Rules

Centralized development rules for AI coding agents (Windsurf, GitHub Copilot, Cursor, Claude Code, Codex CLI, Gemini CLI, Antigravity, OpenCode).

## Structure

```
agent-development-rules/
├── manifest.yaml              # Central configuration (v2.0)
│
├── content/                   # All source content
│   ├── rules/                 # Development rules (always in context)
│   │   ├── core/              # Agent behavior
│   │   │   └── agent-behavior.md  # 6 pillars (architecture, quality,
│   │   │                          # performance, security, docs, scalability)
│   │   ├── quality/           # Linting tools
│   │   │   └── linting.md     #   Golden chain, all linters
│   │   ├── process/           # Git workflow
│   │   │   └── git.md         #   Conventional Commits (strict)
│   │   └── agents/            # Agent-specific behavior
│   │       ├── windsurf.md    #   Windsurf/Cascade rules
│   │       └── copilot.md     #   GitHub Copilot rules
│   │
│   ├── workflows/             # Workflows (slash commands)
│   │   ├── validation/        #   validate, test, lint
│   │   ├── git/               #   pre-push, pr-review, fix-pr-comments
│   │   ├── infrastructure/    #   terraform-module, docker-build, k8s-validate
│   │   └── security/          #   security-check
│   │
│   ├── prompts/               # Reusable prompts
│   │   ├── review.prompt.md   #   Code review
│   │   ├── security.prompt.md #   Security audit
│   │   ├── test.prompt.md     #   Test generation
│   │   ├── refactor.prompt.md #   Refactoring
│   │   ├── document.prompt.md #   Documentation
│   │   ├── validate.prompt.md #   Project validation
│   │   ├── commit.prompt.md   #   Conventional Commits
│   │   ├── explain.prompt.md  #   Code explanation
│   │   └── debug.prompt.md    #   Debugging assistant
│   │
│   └── skills/                # Agent Skills (on-demand capabilities)
│       ├── code-review/       #   Code review with checklists
│       │   ├── SKILL.md
│       │   └── references/
│       ├── git-commit-formatter/ # Conventional Commits enforcer
│       │   └── SKILL.md
│       └── security-audit/    #   OWASP security audit
│           ├── SKILL.md
│           └── references/
│
├── templates/                 # Reusable document templates
│   ├── pull-request.md        #   PR description template
│   ├── trd.md                 #   Technical Requirements Document
│   ├── prd.md                 #   Product Requirements Document
│   ├── readme.md              #   Project README template
│   └── architecture/          #   Architecture decision templates
│       ├── ad.md              #     Architecture Decision
│       ├── adl.md             #     Architecture Decision Log
│       ├── adr.md             #     Architecture Decision Record
│       ├── akm.md             #     Architecture Knowledge Management
│       └── asr.md             #     Architecturally-Significant Requirement
│
├── config/                    # Configuration examples
│   └── .pre-commit-config.yaml.example
│
├── scripts/                   # Automation
│   ├── sync.sh                #   Sync rules to agents
│   ├── validate.sh            #   Validate configuration
│   └── lib/
│       ├── common.sh          #   Shared functions
│       └── sync.sh            #   Sync implementation
│
├── tests/                     # Script tests (bats)
│   ├── test_common.bats       #   Tests for common.sh
│   ├── test_sync.bats         #   Tests for sync.sh
│   └── test_validate.bats     #   Tests for validate.sh
│
└── Makefile                   # lint, fmt, test, validate, sync
```

## Usage

### Sync Rules

```bash
# Sync to all enabled agents
./scripts/sync.sh

# Sync only one agent
./scripts/sync.sh --agent windsurf
./scripts/sync.sh --agent copilot-vscode
./scripts/sync.sh --agent cursor

# Dry run (see what would happen)
./scripts/sync.sh --dry-run

# Create backups before overwriting
./scripts/sync.sh --backup

# Validate configuration before syncing
./scripts/sync.sh --validate

# List available agents and their status
./scripts/sync.sh --list

# Enable debug output
./scripts/sync.sh --debug
```

### Validate Configuration

```bash
# Check manifest, files, and frontmatter
./scripts/validate.sh
```

### Requirements

```bash
# Install yq (YAML parser)
brew install yq
```

## Configuration

### manifest.yaml

The `manifest.yaml` file (v2.0) defines:
- **content_dir**: Base directory for all content (`content/`).
- **Source Files**: Lists of rules, workflows, and prompts with paths relative to `content/`.
- **Agents**: Destination configuration per agent with auto-detection.

```yaml
# Agent configuration example
agents:
  windsurf:
    enabled: true
    description: "Windsurf IDE / Codeium Cascade"
    detect:
      paths:
        - "${HOME}/.codeium"
    targets:
      rules:
        path: "${HOME}/.codeium/memories/global_rules.md"
        format: merged
        strip_frontmatter: true
```

### Adding a New Agent

1. Add a section in `manifest.yaml` under `agents:`.
2. Configure `detect` with paths/commands for auto-detection.
3. Configure `targets` with destination paths and format (`merged` or `individual`).
4. Run `./scripts/sync.sh --agent <name>`.

### Adding a New Rule

1. Create a file in `content/rules/<category>/<name>.md` with frontmatter.
2. Add it to `manifest.yaml` under `rules.files` (path relative to `content/rules/`).
3. Run `./scripts/sync.sh`.

## Rules (Always in Context)

Rules define **principles and personality** — loaded on every interaction.

### Core — 6 Pillars (`agent-behavior.md`)

| # | Pillar | What it Covers |
|---|--------|----------------|
| 1 | **Architecture & Solution Design** | Thinking process, CUPID, SOLID triggers, dependency inversion |
| 2 | **Code Quality & Best Practices** | DRY/KISS/YAGNI, code limits, smells, early returns, naming |
| 3 | **Performance & Optimization** | Measure first, Big O, N+1, caching, connection pooling |
| 4 | **Security & Error Handling** | Zero trust, input validation, error patterns, self-check loop |
| 5 | **Documentation & Maintainability** | Comments (why not what), validation chain (format→lint→test→security) |
| 6 | **Scalability & Resilience** | Stateless, circuit breaker, retry, rate limiting, graceful degradation |

### Quality & Process
- **linting.md** — Golden chain, linters by language, pre-commit, CI/CD
- **git.md** — Conventional Commits (strict), branching, PRs

### Agents
- **windsurf.md** — Windsurf/Cascade specific behavior
- **copilot.md** — GitHub Copilot specific behavior

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
| **Kubernetes** | `kubeconform`, `helm lint`, `kube-linter` | - |

See `content/rules/quality/linting.md` for detailed configuration.

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

See `content/workflows/validation/test.md` for detailed testing guidelines.

### Pre-commit Hooks

Use `config/.pre-commit-config.yaml.example` to catch issues before commit:

```bash
pip install pre-commit
cp config/.pre-commit-config.yaml.example .pre-commit-config.yaml
pre-commit install
```

## Supported Agents

| Agent | Status | Skills | Description |
|-------|--------|--------|-------------|
| **windsurf** | ✅ Enabled | ✅ | Windsurf IDE / Codeium Cascade |
| **copilot-cli** | ✅ Enabled | — | GitHub Copilot CLI (`gh copilot`) |
| **copilot-vscode** | ✅ Enabled | ✅ | GitHub Copilot (VS Code) |
| **copilot-intellij** | ✅ Enabled | — | GitHub Copilot (IntelliJ/JetBrains) |
| **cursor** | ✅ Enabled | — | Cursor IDE |
| **claude-code** | ✅ Enabled | ✅ | Claude Code (Anthropic) |
| **codex-cli** | ✅ Enabled | — | OpenAI Codex CLI |
| **gemini-cli** | ✅ Enabled | — | Google Gemini CLI |
| **antigravity** | ✅ Enabled | ✅ | Google Antigravity IDE |
| **opencode** | ✅ Enabled | — | OpenCode |
| **local-project** | ⬜ Disabled | — | Copy rules to local project |

## Agent Skills

Agent Skills are an [open standard](https://agentskills.io) for on-demand agent capabilities. Unlike rules (always active) or workflows (slash-command triggered), skills are **automatically invoked** when the agent detects relevance to the user's request.

### How Skills Work (Progressive Disclosure)

| Level | Content | When Loaded | Tokens |
|-------|---------|-------------|--------|
| **L1: Metadata** | `name` + `description` | Always (startup) | ~100/skill |
| **L2: Instructions** | Full `SKILL.md` body | When agent detects relevance | <5000 recommended |
| **L3: Resources** | `scripts/`, `references/`, `assets/` | Only when referenced | Variable |

### Skill Structure

```
content/skills/my-skill/
├── SKILL.md           # Required — YAML frontmatter + instructions
├── scripts/           # Optional — executable scripts
├── references/        # Optional — documentation, templates
└── assets/            # Optional — images, data files
```

### SKILL.md Format

```markdown
---
name: my-skill
description: What this skill does and when to use it.
license: MIT
metadata:
  author: your-org
  version: "1.0"
---

# My Skill

## Instructions
1. Step one...
2. Step two...

## Examples
...
```

### Included Skills (16)

**Development:**
- **code-review** — Phased code review with severity labels, question technique, and PR/local detection
- **git-commit-formatter** — Conventional Commits with diff analysis, multi-commit strategy, and verification
- **refactoring** — Code smell detection with incremental refactoring patterns and behavior-preserving constraints
- **systematic-debugging** — Root-cause analysis with hypothesis-driven debugging, git bisect, and strategic logging
- **test-driven-development** — Red-Green-Refactor cycle with AAA pattern, table-driven tests, and coverage targets
- **performance-optimization** — Profile-first optimization with per-language profilers, Big-O analysis, and caching
- **verification-before-completion** — Ensures all completion claims are backed by fresh verification evidence

**Infrastructure:**
- **docker-expert** — Secure, optimized Docker images with multi-stage builds, hadolint, and vulnerability scanning
- **terraform-expert** — 3-layer validation (tflint, checkov, tfsec), module structure, and IaC best practices
- **aws-cloud-expert** — Least privilege IAM, S3 security, encryption, tagging, and cost control
- **kubernetes-expert** — Security contexts, resource limits, probes, network policies, and HPA

**Quality & Process:**
- **security-audit** — OWASP Top 10:2025 audit with dependency scanning, secrets detection, and structured reports
- **accessibility-compliance** — WCAG 2.1 Level AA with semantic HTML, ARIA, keyboard navigation, and contrast
- **scalability-patterns** — Stateless services, async processing, caching, circuit breakers, and rate limiting
- **documentation-generator** — READMEs, CHANGELOGs, ADRs, docstrings, and architecture diagrams
- **operational-excellence** — SRE observability (logs, metrics, tracing), alerting, SLOs, and incident management

### Adding a New Skill

1. Create a directory in `content/skills/<skill-name>/` with a `SKILL.md` file.
2. Add it to `manifest.yaml` under `skills.directories`.
3. Run `./scripts/sync.sh`.

### Skills Destination Paths

| Agent | Global Skills Path |
|-------|--------------------|
| **Windsurf** | `~/.codeium/windsurf/skills/<name>/` |
| **Claude Code** | `~/.claude/skills/<name>/` |
| **Copilot VS Code** | `~/.copilot/skills/<name>/` |
| **Antigravity** | `~/.gemini/antigravity/skills/<name>/` |

For the full specification, see [agentskills.io/specification](https://agentskills.io/specification).

## Development

### Rule Structure

Rules use YAML frontmatter for trigger configuration:

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

### Prompt Structure

```markdown
---
name: Prompt Name
description: What this prompt does
trigger: manual
tags:
  - category
---

# Prompt Name

Instructions...
```

## Scripts

### `sync.sh`

Reads `manifest.yaml` and syncs rules, workflows, and prompts to each agent's configured destination. Supports auto-detection of installed agents, dry-run mode, backups, and per-agent sync.

### `validate.sh`

Validates the entire configuration: manifest syntax, file references, content directory structure, and frontmatter consistency.

### `lib/common.sh`

Shared logging, file operations, frontmatter extraction, and safe path expansion.

### `Makefile`

Run the full validation chain for the project itself:

```bash
make check    # lint → fmt-check → validate → test
make sync     # Sync rules to all agents
make help     # Show all available targets
```

## License

MIT
