#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2016,SC2034
# =============================================================================
# Tests for scripts/lib/common.sh
# =============================================================================
# Run: bats tests/test_common.bats

SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../scripts" && pwd)"

bats_require_minimum_version 1.5.0

setup() {
    source "${SCRIPT_DIR}/lib/common.sh"
    TEST_FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
    mkdir -p "${TEST_FIXTURES}"
}

teardown() {
    rm -rf "${TEST_FIXTURES}"
}

# =============================================================================
# expand_path tests
# =============================================================================

@test "expand_path replaces \${HOME}" {
    result=$(expand_path '${HOME}/.config')
    [[ "$result" == "${HOME}/.config" ]]
}

@test "expand_path leaves bare \$HOME untouched (only \${HOME} supported)" {
    result=$(expand_path '$HOME/.config')
    [[ "$result" == '$HOME/.config' ]]
}

@test "expand_path replaces \${USER}" {
    result=$(expand_path '${USER}/data')
    [[ "$result" == "${USER}/data" ]]
}

@test "expand_path does not execute injected commands" {
    result=$(expand_path '$(echo PWNED)')
    [[ "$result" != "PWNED" ]]
    [[ "$result" == '$(echo PWNED)' ]]
}

@test "expand_path handles paths without variables" {
    result=$(expand_path '/usr/local/bin')
    [[ "$result" == "/usr/local/bin" ]]
}

# =============================================================================
# extract_content tests
# =============================================================================

@test "extract_content strips YAML frontmatter" {
    cat > "${TEST_FIXTURES}/with_fm.md" <<'EOF'
---
trigger: always
---

# Title

Content here.
EOF
    result=$(extract_content "${TEST_FIXTURES}/with_fm.md")
    [[ "$result" != *"trigger:"* ]]
    [[ "$result" == *"# Title"* ]]
    [[ "$result" == *"Content here."* ]]
}

@test "extract_content returns full content without frontmatter" {
    cat > "${TEST_FIXTURES}/no_fm.md" <<'EOF'
# No Frontmatter

Just content.
EOF
    result=$(extract_content "${TEST_FIXTURES}/no_fm.md")
    [[ "$result" == *"# No Frontmatter"* ]]
}

@test "extract_content handles empty file" {
    touch "${TEST_FIXTURES}/empty.md"
    result=$(extract_content "${TEST_FIXTURES}/empty.md")
    [[ -z "$result" ]]
}

@test "extract_content handles file with only frontmatter" {
    cat > "${TEST_FIXTURES}/only_fm.md" <<'EOF'
---
trigger: always
---
EOF
    result=$(extract_content "${TEST_FIXTURES}/only_fm.md")
    [[ -z "$result" || "$result" =~ ^[[:space:]]*$ ]]
}

# =============================================================================
# has_frontmatter tests
# =============================================================================

@test "has_frontmatter returns true for file with frontmatter" {
    cat > "${TEST_FIXTURES}/with_fm.md" <<'EOF'
---
trigger: always
---

Content.
EOF
    has_frontmatter "${TEST_FIXTURES}/with_fm.md"
}

@test "has_frontmatter returns false for file without frontmatter" {
    cat > "${TEST_FIXTURES}/no_fm.md" <<'EOF'
# Title

Content.
EOF
    run ! has_frontmatter "${TEST_FIXTURES}/no_fm.md"
    [[ "$status" -ne 0 ]]
}

# =============================================================================
# backup_file tests
# =============================================================================

@test "backup_file creates backup of existing file" {
    local src="${TEST_FIXTURES}/original.txt"
    local backup_dir="${TEST_FIXTURES}/backups"
    echo "original content" > "${src}"

    backup_file "${src}" "${backup_dir}"

    local backup_count
    backup_count=$(find "${backup_dir}" -name "original.txt.*.bak" | wc -l)
    [[ "$backup_count" -ge 1 ]]
}

@test "backup_file does nothing for non-existent file" {
    local backup_dir="${TEST_FIXTURES}/backups"
    backup_file "${TEST_FIXTURES}/nonexistent.txt" "${backup_dir}"
    [[ ! -d "${backup_dir}" ]]
}

@test "backup_file rotates keeping only 5" {
    local src="${TEST_FIXTURES}/rotate.txt"
    local backup_dir="${TEST_FIXTURES}/backups"
    echo "content" > "${src}"

    # Create 6 backups with distinct timestamps
    for i in $(seq 1 6); do
        mkdir -p "${backup_dir}"
        cp "${src}" "${backup_dir}/rotate.txt.2026010${i}_000000.bak"
    done

    # Now call backup_file which creates a 7th and rotates
    backup_file "${src}" "${backup_dir}"

    local count
    count=$(find "${backup_dir}" -name "rotate.txt.*.bak" -type f | wc -l | tr -d ' ')
    [[ "$count" -le 5 ]]
}

# =============================================================================
# resolve_content_dir tests
# =============================================================================

@test "resolve_content_dir returns repo_root/content_dir when defined" {
    local manifest="${TEST_FIXTURES}/manifest_with_content.yaml"
    cat > "${manifest}" <<'YAML'
content_dir: "content"
YAML
    result=$(resolve_content_dir "/fake/root" "${manifest}")
    [[ "$result" == "/fake/root/content" ]]
}

@test "resolve_content_dir falls back to repo_root when content_dir missing" {
    local manifest="${TEST_FIXTURES}/manifest_no_content.yaml"
    cat > "${manifest}" <<'YAML'
version: "2.0"
YAML
    result=$(resolve_content_dir "/fake/root" "${manifest}")
    [[ "$result" == "/fake/root" ]]
}

# =============================================================================
# show_diff tests
# =============================================================================

@test "show_diff prints new file message for non-existent path" {
    run show_diff "${TEST_FIXTURES}/nonexistent.md" "new content"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Archivo nuevo"* ]]
}

@test "show_diff shows diff for existing file with changes" {
    local target="${TEST_FIXTURES}/existing.md"
    echo "old" > "${target}"
    run show_diff "${target}" "new"
    [[ "$status" -eq 0 ]]
}

# =============================================================================
# Logging functions tests
# =============================================================================

@test "log_info outputs to stderr with INFO prefix" {
    run log_info "test message"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"[INFO]"* ]]
    [[ "$output" == *"test message"* ]]
}

@test "log_warn outputs to stderr with WARN prefix" {
    run log_warn "warning message"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"[WARN]"* ]]
    [[ "$output" == *"warning message"* ]]
}

@test "log_error outputs to stderr with ERROR prefix" {
    run log_error "error message"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"[ERROR]"* ]]
    [[ "$output" == *"error message"* ]]
}

@test "log_debug outputs nothing when DEBUG is not set" {
    DEBUG=false
    run log_debug "hidden message"
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
}

@test "log_debug outputs when DEBUG is true" {
    DEBUG=true
    run log_debug "visible message"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"[DEBUG]"* ]]
    [[ "$output" == *"visible message"* ]]
}

@test "log_section outputs section header" {
    run log_section "My Section"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"My Section"* ]]
    [[ "$output" == *"━"* ]]
}

@test "log_success outputs with checkmark" {
    run log_success "all good"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"✓"* ]]
    [[ "$output" == *"all good"* ]]
}

@test "log_fail outputs with cross mark" {
    run log_fail "something failed"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"✗"* ]]
    [[ "$output" == *"something failed"* ]]
}

@test "log_info handles multiple arguments" {
    run log_info "arg1" "arg2" "arg3"
    [[ "$output" == *"arg1 arg2 arg3"* ]]
}

# =============================================================================
# get_timestamp tests
# =============================================================================

@test "get_timestamp returns valid format YYYY-MM-DD HH:MM:SS" {
    local ts
    ts=$(get_timestamp)
    [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]
}

# =============================================================================
# check_dependency tests
# =============================================================================

@test "check_dependency returns 0 for existing command" {
    run check_dependency "bash"
    [[ "$status" -eq 0 ]]
}

@test "check_dependency returns 1 for missing command" {
    run check_dependency "nonexistent_command_xyz"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Dependencia faltante"* ]]
}

@test "check_dependency shows install hint when provided" {
    run check_dependency "nonexistent_command_xyz" "brew install xyz"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"brew install xyz"* ]]
}

