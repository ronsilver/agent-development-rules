# Contributing

## Quick Start

```bash
# Install dependencies
brew install yq shellcheck shfmt bats-core

# Validate the project
make check
```

## Adding a New Agent

1. Add a section in `manifest.yaml` under `agents:`:

```yaml
agents:
  my-agent:
    enabled: true
    description: "My Agent Description"
    detect:
      paths:
        - "${HOME}/.my-agent"
      commands:
        - "my-agent --version"
    targets:
      rules:
        path: "${HOME}/.my-agent/rules"
        format: individual       # or: merged
        strip_frontmatter: false
```

2. Test with dry-run: `./scripts/sync.sh --agent my-agent --dry-run`
3. Sync: `./scripts/sync.sh --agent my-agent`

## Adding a New Rule

1. Create `content/rules/<category>/<name>.md` with frontmatter:

```markdown
---
trigger: always
---

# Rule Title

Content...
```

2. Add the path to `manifest.yaml` under `rules.files`:

```yaml
rules:
  files:
    - category/name.md
```

3. Validate: `./scripts/validate.sh`

## Adding a Workflow

1. Create `content/workflows/<category>/<name>.md`:

```markdown
---
name: workflow-name
description: What this workflow does
---

# Workflow: Name

Steps...
```

2. Add to `manifest.yaml` under `workflows.files`.

## Adding a Prompt

1. Create `content/prompts/<name>.prompt.md`:

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

2. Add to `manifest.yaml` under `prompts.files`.

## Validation

Before submitting changes, run:

```bash
make check    # lint → fmt-check → validate → test
```

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(rules): add rust best practices
fix(sync): handle empty glob paths
docs(readme): update agent table
```

## Code Style

- Shell scripts: 4-space indent, `set -euo pipefail`
- Format with `shfmt -i 4 -ci`
- Lint with `shellcheck`
