# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-02-10

### Added
- **Agent Skills support** — new content type following the [agentskills.io](https://agentskills.io) open standard
- `content/skills/` directory with 16 built-in skills:
  - Development: `code-review`, `git-commit-formatter`, `refactoring`, `systematic-debugging`, `test-driven-development`, `performance-optimization`, `verification-before-completion`
  - Infrastructure: `docker-expert`, `terraform-expert`, `aws-cloud-expert`, `kubernetes-expert`
  - Quality & Process: `security-audit`, `accessibility-compliance`, `scalability-patterns`, `documentation-generator`, `operational-excellence`
- `directory` sync format in `lib/sync.sh` — copies entire skill directories preserving structure
- `validate_skills()` in `validate.sh` — validates SKILL.md existence, frontmatter, and naming conventions
- Skills targets for Windsurf, Claude Code, Copilot VS Code, and Antigravity in `manifest.yaml`
- `get_source_skill_dirs()` function in `lib/sync.sh` for reading skill directories from manifest
- `Makefile` with lint, fmt, test, validate, sync, and check targets
- `tests/test_common.bats` — unit tests for common.sh functions
- Content change detection in sync — skip writes when content is unchanged
- Agent name validation (alphanumeric, hyphens, underscores only)
- `--agent` argument validation (prevents crash when value is missing)
- `REPO_ROOT` variable support in `expand_path()`
- `show_diff()` integrated into dry-run output
- `CHANGELOG.md` and `CONTRIBUTING.md`
- A04 (Insecure Design) remediation pattern in `security-audit` skill — was the only OWASP category missing

### Changed
- **BREAKING**: Removed `scripts/lib/agents/` directory (windsurf.sh, copilot.sh, cursor.sh) — all sync logic now driven by manifest.yaml
- **BREAKING**: Consolidated `core/global.md`, `core/clean-code.md`, `core/solid.md` into single `core/agent-behavior.md` (6 pillars)
- **BREAKING**: Migrated infrastructure/quality/process rules to on-demand skills (docker, terraform, aws, kubernetes, testing, security, performance, scalability, accessibility, documentation, operational-excellence)
- Prompts refactored to lightweight wrappers delegating to skills
- Replaced `eval`-based path expansion with safe variable substitution (security fix)
- Replaced `echo -e` with `printf '%s\n'` for file writing (prevents content corruption)
- Replaced `((var++))` with `var=$((var + 1))` in validate.sh (prevents crash under `set -e`)
- Replaced pipe in `get_source_files()` with process substitution (prevents silent error loss)
- Refactored `sync_agent` to use generic `sync_target` dispatcher supporting `merged` and `individual` formats
- ANSI colors now conditional on terminal detection (`[[ -t 2 ]]`)
- Separated `antigravity` and `gemini-cli` instructions paths to prevent overwrite conflict
- `local-project` paths now use `${REPO_ROOT}` instead of relative paths
- `linting.md` reduced from 297 → 51 lines (principles only, details in `lint` workflow)
- `agent-behavior.md` §6 Scalability collapsed to 6 lines + skill reference
- `pre-push.md` reduced from 222 → 162 lines (references `validate` workflow and `git` rule instead of duplicating)
- `performance-optimization` skill: connection pooling/caching now references `scalability-patterns` (330 → 290 lines)
- `git.md` trigger changed from `glob` to `always` — commit rules apply in every interaction
- `.windsurfrules` example changed from hardcoded `npm test` to language-agnostic
- Validation Chain in `agent-behavior.md` §5 now references canonical Golden Chain from `linting` rule
- `verification-before-completion` Golden Chain references canonical definition in `linting` rule
- Copilot slash commands updated (added `/new`, noted IDE-specific `/doc`)
- Windsurf project rules path reference made generic
- WCAG version updated from 2.1 to 2.2 in `accessibility-compliance`
- `trivy image` preferred over `docker scout` as default scanner in `docker-expert`

### Fixed
- OWASP category numbering in `security-audit` Phase 5 (A02↔A05 were swapped)
- Duplicate A08 section in `security-audit` merged into single coherent section
- OWASP remediation patterns reordered numerically (A01→A10)
- Broken cross-references from `test.md` workflow to deleted `testing.md` → now points to `test-driven-development` skill
- `fix-pr-comments.md` incorrect REST API for resolving threads → noted GraphQL requirement
- Docker Python multi-stage example: `USER nobody` → proper `appuser`/`appgroup`
- `is_agent_installed()` no longer uses `eval` for command detection
- `get_target_paths()` guards against empty array output
- `review.prompt.md` section 5 (AI/LLM Code) moved to correct position

### Deprecated
- `tfsec` marked as deprecated in `terraform-expert` skill — replaced by `trivy config` throughout all skills, workflows, and rules

### Security
- Eliminated command injection vectors in `expand_path()` and `is_agent_installed()`
- Agent name input validated before interpolation into yq queries
- Replaced all `tfsec` references with `trivy config` (tfsec archived by Aqua Security)
- Replaced sunset `datree` with `kube-linter` for Kubernetes policy validation
- SHA-pinned GitHub Actions in all workflow examples
- `trivy config` added to `terraform-module` workflow prerequisites and checklist

## [2.0.0] - 2026-02-06

### Added
- manifest.yaml v2.0 with centralized agent configuration
- Support for 10 AI agents (Windsurf, Copilot, Cursor, Claude Code, Codex, Gemini, Antigravity, OpenCode)
- Auto-detection of installed agents
- `--dry-run`, `--backup`, `--validate`, `--list`, `--debug` flags
- Content categories: rules, workflows, prompts, templates
- Pre-commit configuration example

### Changed
- Migrated from per-agent scripts to manifest-driven sync
- Reorganized content into `content/` directory structure
