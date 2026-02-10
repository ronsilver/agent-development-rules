#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2016,SC2034
# =============================================================================
# Tests for scripts/sync.sh functions
# =============================================================================
# Run: bats tests/test_sync.bats

SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../scripts" && pwd)"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

bats_require_minimum_version 1.5.0

setup() {
    # Source real implementations (sync.sh sources common.sh internally)
    source "${SCRIPT_DIR}/sync.sh"

    TEST_FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
    mkdir -p "${TEST_FIXTURES}"

    # Override globals that sync.sh sets at source time
    MANIFEST_FILE="${TEST_FIXTURES}/test-manifest.yaml"
    CONTENT_DIR="${TEST_FIXTURES}/content"
    DRY_RUN=false
    CREATE_BACKUP=false
    TIMESTAMP="2026-01-01 00:00:00"

    # Create comprehensive test manifest
    cat > "${TEST_FIXTURES}/test-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
    - second-rule.md
workflows:
  source_dir: "workflows"
  files:
    - test-workflow.md
agents:
  enabled-agent:
    enabled: true
    description: "Enabled Test Agent"
    targets:
      rules:
        path: "${HOME}/.test-agent/rules.md"
        format: merged
        strip_frontmatter: true
        header: |
          # Rules - Generated {{timestamp}}
  disabled-agent:
    enabled: false
    description: "Disabled Test Agent"
    targets:
      rules:
        path: "${HOME}/.disabled-agent/rules.md"
        format: merged
  detected-agent:
    enabled: true
    description: "Detected Agent"
    detect:
      paths:
        - "/nonexistent/path/that/will/never/exist"
      commands:
        - "nonexistent_binary_xyz_12345"
    targets:
      rules:
        path: "${HOME}/.detected/rules.md"
        format: merged
  individual-agent:
    enabled: true
    description: "Individual Agent"
    detect:
      paths:
        - "/tmp"
      commands: []
    targets:
      rules:
        path: "${HOME}/.individual-agent/rules"
        format: individual
        strip_frontmatter: true
        output_extension: ".md"
  transform-agent:
    enabled: true
    description: "Transform Agent"
    detect:
      paths:
        - "/tmp"
      commands: []
    targets:
      rules:
        path: "${HOME}/.transform-agent/rules"
        format: individual
        strip_frontmatter: false
        transform_frontmatter: true
        output_extension: ".mdc"
        header: |
          ---
          name: {{name}}
          generated: {{timestamp}}
          ---
  multi-target-agent:
    enabled: true
    description: "Multi Target Agent"
    detect:
      paths:
        - "/tmp"
      commands: []
    targets:
      rules:
        path: "${HOME}/.multi/rules.md"
        format: merged
        strip_frontmatter: true
        source_type: "rules"
      workflows:
        path: "${HOME}/.multi/workflows.md"
        format: merged
        strip_frontmatter: true
        source_type: "workflows"
YAML

    # Create test content — rules
    mkdir -p "${TEST_FIXTURES}/content/rules"
    cat > "${TEST_FIXTURES}/content/rules/test-rule.md" <<'MD'
---
trigger: always
---

# Test Rule

This is a test rule.
MD

    cat > "${TEST_FIXTURES}/content/rules/second-rule.md" <<'MD'
---
trigger: manual
---

# Second Rule

This is the second rule.
MD

    # Create test content — workflows
    mkdir -p "${TEST_FIXTURES}/content/workflows"
    cat > "${TEST_FIXTURES}/content/workflows/test-workflow.md" <<'MD'
---
description: Test workflow
---

# Test Workflow

Workflow content.
MD
}

teardown() {
    rm -rf "${TEST_FIXTURES}"
}

# =============================================================================
# parse_args tests
# =============================================================================

@test "parse_args rejects --agent without value" {
    run parse_args --agent
    [[ "$status" -ne 0 ]]
}

@test "parse_args sets SPECIFIC_AGENT" {
    SPECIFIC_AGENT=""
    parse_args --agent windsurf
    [[ "${SPECIFIC_AGENT}" == "windsurf" ]]
}

@test "parse_args sets DRY_RUN" {
    DRY_RUN=false
    parse_args --dry-run
    [[ "${DRY_RUN}" == "true" ]]
}

@test "parse_args sets CREATE_BACKUP" {
    CREATE_BACKUP=false
    parse_args --backup
    [[ "${CREATE_BACKUP}" == "true" ]]
}

@test "parse_args sets VALIDATE_FIRST" {
    VALIDATE_FIRST=false
    parse_args --validate
    [[ "${VALIDATE_FIRST}" == "true" ]]
}

@test "parse_args sets DEBUG" {
    parse_args --debug
    [[ "${DEBUG}" == "true" ]]
}

@test "parse_args rejects unknown option" {
    run parse_args --unknown-flag
    [[ "$status" -ne 0 ]]
}

# =============================================================================
# Agent name validation
# =============================================================================

@test "valid agent names are accepted" {
    for name in "windsurf" "copilot-vscode" "claude_code" "test-123"; do
        [[ "${name}" =~ ^[a-zA-Z0-9_-]+$ ]]
    done
}

@test "invalid agent names are rejected" {
    for name in "agent;rm" 'agent$(cmd)' "agent name" "agent/path"; do
        ! [[ "${name}" =~ ^[a-zA-Z0-9_-]+$ ]]
    done
}

# =============================================================================
# check_dependencies tests
# =============================================================================

@test "check_dependencies succeeds when yq is installed" {
    run check_dependencies
    [[ "$status" -eq 0 ]]
}

# =============================================================================
# is_agent_enabled tests
# =============================================================================

@test "is_agent_enabled returns true for enabled agent" {
    is_agent_enabled "enabled-agent"
}

@test "is_agent_enabled returns false for disabled agent" {
    run ! is_agent_enabled "disabled-agent"
    [[ "$status" -ne 0 ]]
}

@test "is_agent_enabled returns false for nonexistent agent" {
    run ! is_agent_enabled "nonexistent-agent"
    [[ "$status" -ne 0 ]]
}

# =============================================================================
# is_agent_installed tests
# =============================================================================

@test "is_agent_installed returns true when no detect config" {
    # enabled-agent has no detect section → assumed installed
    is_agent_installed "enabled-agent"
}

@test "is_agent_installed returns false when nothing detected" {
    # detected-agent has nonexistent paths and commands
    run ! is_agent_installed "detected-agent"
    [[ "$status" -ne 0 ]]
}

@test "is_agent_installed returns true when path exists" {
    # individual-agent detects /tmp which always exists
    is_agent_installed "individual-agent"
}

# =============================================================================
# get_source_files tests
# =============================================================================

@test "get_source_files resolves rules files from manifest" {
    result=$(get_source_files "rules")
    [[ "$result" == *"test-rule.md"* ]]
    [[ "$result" == *"second-rule.md"* ]]
}

@test "get_source_files resolves workflow files from manifest" {
    result=$(get_source_files "workflows")
    [[ "$result" == *"test-workflow.md"* ]]
}

@test "get_source_files warns about missing files" {
    # Add a nonexistent file to manifest
    cat > "${TEST_FIXTURES}/bad-manifest.yaml" <<'YAML'
rules:
  source_dir: "rules"
  files:
    - nonexistent.md
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/bad-manifest.yaml"
    run get_source_files "rules"
    [[ "$output" == *"Archivo no encontrado"* ]]
}

# =============================================================================
# get_target_paths tests
# =============================================================================

@test "get_target_paths resolves single path" {
    local result
    result=$(get_target_paths ".agents.enabled-agent.targets.rules")
    [[ "$result" == "${HOME}/.test-agent/rules.md" ]]
}

@test "get_target_paths returns empty for nonexistent target" {
    local result
    result=$(get_target_paths ".agents.enabled-agent.targets.nonexistent" || true)
    [[ -z "$result" ]]
}

# =============================================================================
# Content change detection (using real write_sync_file)
# =============================================================================

@test "write_sync_file skips unchanged content" {
    local target="${TEST_FIXTURES}/output/unchanged.md"
    mkdir -p "$(dirname "${target}")"
    printf '%s\n' "same content" > "${target}"

    run write_sync_file "${target}" "same content"
    [[ "$status" -eq 0 ]]
    [[ "$(cat "${target}")" == "same content" ]]
}

@test "write_sync_file writes changed content" {
    local target="${TEST_FIXTURES}/output/changed.md"
    mkdir -p "$(dirname "${target}")"
    printf '%s\n' "old content" > "${target}"

    write_sync_file "${target}" "new content"
    [[ "$(cat "${target}")" == "new content" ]]
}

@test "write_sync_file creates new file" {
    local target="${TEST_FIXTURES}/output/new_file.md"

    write_sync_file "${target}" "brand new"
    [[ -f "${target}" ]]
    [[ "$(cat "${target}")" == "brand new" ]]
}

@test "write_sync_file dry-run does not write" {
    local target="${TEST_FIXTURES}/output/dry.md"
    DRY_RUN=true

    run write_sync_file "${target}" "dry content"
    [[ "$status" -eq 0 ]]
    [[ ! -f "${target}" ]]
    [[ "$output" == *"DRY-RUN"* ]]
}

@test "write_sync_file creates backup when enabled" {
    local target="${TEST_FIXTURES}/output/backup_test.md"
    mkdir -p "$(dirname "${target}")"
    printf '%s\n' "old" > "${target}"
    CREATE_BACKUP=true

    write_sync_file "${target}" "new"

    local backup_count
    backup_count=$(find /tmp/agent-development-rules-backup -name "backup_test.md.*.bak" -type f 2>/dev/null | wc -l | tr -d ' ')
    [[ "$backup_count" -ge 1 ]]
}

# =============================================================================
# transform_file_frontmatter tests
# =============================================================================

@test "transform_file_frontmatter replaces frontmatter with template" {
    local result
    result=$(transform_file_frontmatter \
        "${TEST_FIXTURES}/content/rules/test-rule.md" \
        "transform-agent" \
        ".agents.transform-agent.targets.rules")

    # Should contain template-generated frontmatter
    [[ "$result" == *"name: test-rule"* ]]
    [[ "$result" == *"generated: ${TIMESTAMP}"* ]]
    # Should contain body content
    [[ "$result" == *"# Test Rule"* ]]
    [[ "$result" == *"This is a test rule."* ]]
    # Should NOT contain original frontmatter
    [[ "$result" != *"trigger: always"* ]]
}

# =============================================================================
# sync_merged_impl tests
# =============================================================================

@test "sync_merged_impl creates merged file with header" {
    local target_dir="${TEST_FIXTURES}/output/merged"
    mkdir -p "${target_dir}"

    # Override target path to writable fixture dir
    cat > "${TEST_FIXTURES}/merge-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
    - second-rule.md
agents:
  merge-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}/merged-rules.md"
        format: merged
        strip_frontmatter: true
        header: "# Header {{timestamp}}"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/merge-manifest.yaml"

    sync_merged_impl "merge-test" "rules" "rules" ".agents.merge-test.targets.rules"

    [[ -f "${target_dir}/merged-rules.md" ]]
    local content
    content=$(cat "${target_dir}/merged-rules.md")
    # Header with timestamp
    [[ "$content" == *"# Header ${TIMESTAMP}"* ]]
    # Both rules present
    [[ "$content" == *"# Test Rule"* ]]
    [[ "$content" == *"# Second Rule"* ]]
    # Frontmatter stripped
    [[ "$content" != *"trigger:"* ]]
    # Separator between files
    [[ "$content" == *"---"* ]]
}

@test "sync_merged_impl to directory creates default rules.md" {
    local target_dir="${TEST_FIXTURES}/output/dir-merge"
    mkdir -p "${target_dir}/dest"

    cat > "${TEST_FIXTURES}/dir-merge-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  dir-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}/dest"
        format: merged
        strip_frontmatter: true
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/dir-merge-manifest.yaml"

    sync_merged_impl "dir-test" "rules" "rules" ".agents.dir-test.targets.rules"

    [[ -f "${target_dir}/dest/rules.md" ]]
}

# =============================================================================
# sync_individual_impl tests
# =============================================================================

@test "sync_individual_impl creates individual files" {
    local target_dir="${TEST_FIXTURES}/output/individual"
    mkdir -p "${target_dir}"

    cat > "${TEST_FIXTURES}/indiv-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
    - second-rule.md
agents:
  indiv-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}"
        format: individual
        strip_frontmatter: true
        output_extension: ".md"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/indiv-manifest.yaml"

    sync_individual_impl "indiv-test" "rules" "rules" ".agents.indiv-test.targets.rules"

    [[ -f "${target_dir}/test-rule.md" ]]
    [[ -f "${target_dir}/second-rule.md" ]]
    # Frontmatter stripped
    local content
    content=$(cat "${target_dir}/test-rule.md")
    [[ "$content" != *"trigger:"* ]]
    [[ "$content" == *"# Test Rule"* ]]
}

@test "sync_individual_impl with transform creates transformed files" {
    local target_dir="${TEST_FIXTURES}/output/transform"
    mkdir -p "${target_dir}"

    cat > "${TEST_FIXTURES}/transform-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  xform-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}"
        format: individual
        strip_frontmatter: false
        transform_frontmatter: true
        output_extension: ".mdc"
        header: |
          ---
          name: {{name}}
          ---
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/transform-manifest.yaml"

    sync_individual_impl "xform-test" "rules" "rules" ".agents.xform-test.targets.rules"

    [[ -f "${target_dir}/test-rule.mdc" ]]
    local content
    content=$(cat "${target_dir}/test-rule.mdc")
    [[ "$content" == *"name: test-rule"* ]]
}

# =============================================================================
# sync_target tests
# =============================================================================

@test "sync_target dispatches merged format" {
    local target_dir="${TEST_FIXTURES}/output/sync-target"
    mkdir -p "${target_dir}"

    cat > "${TEST_FIXTURES}/st-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  st-agent:
    enabled: true
    targets:
      rules:
        path: "${target_dir}/rules.md"
        format: merged
        strip_frontmatter: true
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/st-manifest.yaml"

    sync_target "st-agent" "rules" "rules"
    [[ -f "${target_dir}/rules.md" ]]
}

@test "sync_target skips nonexistent target config" {
    run sync_target "enabled-agent" "nonexistent" "nonexistent"
    [[ "$status" -eq 0 ]]
}

@test "sync_target rejects unknown format" {
    cat > "${TEST_FIXTURES}/bad-format-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  bad-agent:
    enabled: true
    targets:
      rules:
        path: "/tmp/bad"
        format: unknown_format
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/bad-format-manifest.yaml"

    run sync_target "bad-agent" "rules" "rules"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Formato desconocido"* ]]
}

# =============================================================================
# sync_agent tests
# =============================================================================

@test "sync_agent skips disabled agent" {
    run sync_agent "disabled-agent"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"deshabilitado"* ]]
}

@test "sync_agent skips uninstalled agent" {
    DEBUG=true
    run sync_agent "detected-agent"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"no está instalado"* ]]
}

@test "sync_agent syncs enabled and installed agent" {
    local target_dir="${TEST_FIXTURES}/output/sync-agent"
    mkdir -p "${target_dir}"

    cat > "${TEST_FIXTURES}/sa-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  sa-test:
    enabled: true
    description: "Sync Agent Test"
    detect:
      paths:
        - "/tmp"
      commands: []
    targets:
      rules:
        path: "${target_dir}/rules.md"
        format: merged
        strip_frontmatter: true
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/sa-manifest.yaml"

    run sync_agent "sa-test"
    [[ "$status" -eq 0 ]]
    [[ -f "${target_dir}/rules.md" ]]
}

@test "sync_agent warns when no targets configured" {
    cat > "${TEST_FIXTURES}/no-targets-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  empty-agent:
    enabled: true
    description: "Empty"
    detect:
      paths:
        - "/tmp"
      commands: []
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-targets-manifest.yaml"

    run sync_agent "empty-agent"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"No hay targets"* ]]
}

# =============================================================================
# list_agents tests
# =============================================================================

@test "list_agents shows all agents with status" {
    run list_agents
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"enabled-agent"* ]]
    [[ "$output" == *"disabled-agent"* ]]
    [[ "$output" == *"habilitado"* ]]
    [[ "$output" == *"deshabilitado"* ]]
}
