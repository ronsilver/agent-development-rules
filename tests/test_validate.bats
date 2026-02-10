#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2034
# =============================================================================
# Tests for scripts/validate.sh functions
# =============================================================================
# Run: bats tests/test_validate.bats

SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../scripts" && pwd)"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

bats_require_minimum_version 1.5.0

setup() {
    # Source real implementations (validate.sh is now sourceable)
    source "${SCRIPT_DIR}/validate.sh"

    TEST_FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
    mkdir -p "${TEST_FIXTURES}"

    # Reset counters
    ERRORS=0
    WARNINGS=0

    # Create valid test manifest
    cat > "${TEST_FIXTURES}/valid-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
workflows:
  source_dir: "workflows"
  files:
    - test-workflow.md
prompts:
  source_dir: "prompts"
  files:
    - test-prompt.md
agents:
  test-agent:
    enabled: true
    description: "Test Agent"
    targets:
      rules:
        path: "${HOME}/.test/rules.md"
        format: merged
  disabled-agent:
    enabled: false
    description: "Disabled Agent"
YAML

    # Override globals — REPO_ROOT must point to fixtures so resolve_content_dir works
    REPO_ROOT="${TEST_FIXTURES}"
    MANIFEST_FILE="${TEST_FIXTURES}/valid-manifest.yaml"
    CONTENT_DIR="${TEST_FIXTURES}/content"

    # Create content directories and files
    mkdir -p "${TEST_FIXTURES}/content/rules"
    mkdir -p "${TEST_FIXTURES}/content/workflows"
    mkdir -p "${TEST_FIXTURES}/content/prompts"

    cat > "${TEST_FIXTURES}/content/rules/test-rule.md" <<'MD'
---
trigger: always
---

# Test Rule
MD

    cat > "${TEST_FIXTURES}/content/workflows/test-workflow.md" <<'MD'
---
description: Test workflow
---

# Test Workflow
MD

    cat > "${TEST_FIXTURES}/content/prompts/test-prompt.md" <<'MD'
---
name: test
description: Test prompt
---

# Test Prompt
MD
}

teardown() {
    rm -rf "${TEST_FIXTURES}"
}

# =============================================================================
# validate_manifest tests
# =============================================================================

@test "validate_manifest succeeds with valid manifest" {
    run validate_manifest
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"manifest.yaml es válido"* ]]
}

@test "validate_manifest fails when manifest does not exist" {
    MANIFEST_FILE="${TEST_FIXTURES}/nonexistent.yaml"

    run validate_manifest
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"no encontrado"* ]]
}

@test "validate_manifest fails with invalid YAML" {
    cat > "${TEST_FIXTURES}/invalid.yaml" <<'YAML'
invalid: [yaml: broken
  - not: valid
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/invalid.yaml"

    run validate_manifest
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"sintaxis YAML inválida"* ]]
}

@test "validate_manifest warns when version is missing" {
    cat > "${TEST_FIXTURES}/no-version.yaml" <<'YAML'
content_dir: "content"
rules:
  files:
    - test.md
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-version.yaml"

    validate_manifest
    # Function succeeds but increments WARNINGS
    [[ $WARNINGS -gt 0 ]]
}

# =============================================================================
# validate_content_dir tests
# =============================================================================

@test "validate_content_dir succeeds with valid directory" {
    run validate_content_dir
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Directorio de contenido"* ]]
}

@test "validate_content_dir fails when directory missing" {
    cat > "${TEST_FIXTURES}/bad-content-manifest.yaml" <<'YAML'
content_dir: "nonexistent_dir"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/bad-content-manifest.yaml"

    run validate_content_dir
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"no encontrado"* ]]
}

# =============================================================================
# validate_file_list tests
# =============================================================================

@test "validate_file_list returns 0 errors for existing files" {
    local result
    result=$(validate_file_list "rules")
    [[ "$result" -eq 0 ]]
}

@test "validate_file_list returns error count for missing files" {
    cat > "${TEST_FIXTURES}/missing-files-manifest.yaml" <<'YAML'
rules:
  source_dir: "rules"
  files:
    - test-rule.md
    - missing-file.md
    - another-missing.md
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/missing-files-manifest.yaml"

    local result
    result=$(validate_file_list "rules")
    [[ "$result" -eq 2 ]]
}

# =============================================================================
# validate_files tests
# =============================================================================

@test "validate_files succeeds with all files present" {
    run validate_files
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Todos los archivos existen"* ]]
}

@test "validate_files fails with missing files" {
    cat > "${TEST_FIXTURES}/missing-manifest.yaml" <<'YAML'
rules:
  source_dir: "rules"
  files:
    - nonexistent.md
workflows:
  source_dir: "workflows"
  files:
    - test-workflow.md
prompts:
  source_dir: "prompts"
  files:
    - test-prompt.md
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/missing-manifest.yaml"

    run validate_files
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"archivos faltantes"* ]]
}

# =============================================================================
# validate_frontmatter_dir tests
# =============================================================================

@test "validate_frontmatter_dir returns 0 for valid frontmatter" {
    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/content/rules" "rules" "trigger")
    [[ "$result" -eq 0 ]]
}

@test "validate_frontmatter_dir returns warnings for missing fields" {
    # Create a file without the required 'trigger' field
    cat > "${TEST_FIXTURES}/content/rules/bad-fm.md" <<'MD'
---
description: no trigger field
---

# Bad Frontmatter
MD

    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/content/rules" "rules" "trigger")
    [[ "$result" -gt 0 ]]
}

@test "validate_frontmatter_dir returns warnings for files without frontmatter" {
    cat > "${TEST_FIXTURES}/content/rules/no-fm.md" <<'MD'
# No Frontmatter At All
MD

    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/content/rules" "rules" "trigger")
    [[ "$result" -gt 0 ]]
}

@test "validate_frontmatter_dir returns 0 for nonexistent directory" {
    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/nonexistent" "nope" "trigger")
    [[ "$result" -eq 0 ]]
}

@test "validate_frontmatter_dir checks multiple required fields" {
    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/content/prompts" "prompts" "name" "description")
    [[ "$result" -eq 0 ]]
}

# =============================================================================
# validate_frontmatter tests
# =============================================================================

@test "validate_frontmatter succeeds with valid frontmatter" {
    run validate_frontmatter
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"frontmatter válido"* ]]
}

@test "validate_frontmatter reports warnings for bad frontmatter" {
    # Add a file without required frontmatter field
    cat > "${TEST_FIXTURES}/content/rules/missing-trigger.md" <<'MD'
---
description: no trigger
---

# Missing Trigger
MD

    validate_frontmatter
    [[ $WARNINGS -gt 0 ]]
}

# =============================================================================
# validate_agents tests
# =============================================================================

@test "validate_agents succeeds with configured agents" {
    run validate_agents
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"agente(s) habilitado(s)"* ]]
}

@test "validate_agents shows enabled and disabled agents" {
    DEBUG=true
    run validate_agents
    [[ "$output" == *"test-agent"* ]]
    [[ "$output" == *"habilitado"* ]]
}

@test "validate_agents warns when no agents configured" {
    cat > "${TEST_FIXTURES}/no-agents-manifest.yaml" <<'YAML'
version: "2.0"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-agents-manifest.yaml"

    validate_agents
    [[ $WARNINGS -gt 0 ]]
}

@test "validate_agents warns when no agents enabled" {
    cat > "${TEST_FIXTURES}/all-disabled-manifest.yaml" <<'YAML'
version: "2.0"
agents:
  agent-a:
    enabled: false
    description: "Disabled A"
  agent-b:
    enabled: false
    description: "Disabled B"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/all-disabled-manifest.yaml"

    validate_agents
    [[ $WARNINGS -gt 0 ]]
}

# =============================================================================
# main integration tests (via run to capture exit)
# =============================================================================

@test "main succeeds with valid configuration" {
    run main
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Validación completada"* ]]
}

@test "main fails with missing manifest" {
    MANIFEST_FILE="${TEST_FIXTURES}/nonexistent.yaml"

    run main
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Manifest inválido"* ]]
}

@test "main accepts --debug flag" {
    run main --debug
    [[ "$status" -eq 0 ]]
}

@test "main rejects unknown flags" {
    run main --unknown
    [[ "$status" -eq 1 ]]
}
