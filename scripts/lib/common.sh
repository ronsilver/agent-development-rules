#!/usr/bin/env bash
# =============================================================================
# common.sh - Funciones comunes para agent-development-rules
# This file is meant to be sourced, not executed directly.
# =============================================================================

# Colores (solo si stderr es un terminal)
if [[ -t 2 ]]; then
    export RED='\033[0;31m'
    export GREEN='\033[0;32m'
    export YELLOW='\033[1;33m'
    export BLUE='\033[0;34m'
    export CYAN='\033[0;36m'
    export BOLD='\033[1m'
    export NC='\033[0m'
else
    export RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# =============================================================================
# Funciones de logging
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*" >&2
    fi
}

log_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
    echo -e "${BLUE}  $*${NC}" >&2
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✓${NC} $*" >&2
}

log_fail() {
    echo -e "${RED}✗${NC} $*" >&2
}

# =============================================================================
# Funciones de utilidad
# =============================================================================

# Expandir variables de entorno en un string (sin eval por seguridad)
expand_path() {
    local path="$1"
    local user="${USER:-$(whoami)}"
    local repo_root="${REPO_ROOT:-$(pwd)}"
    # Expansión segura solo de formas braced ${VAR} — evita ambigüedad
    # (e.g. $HOME matchearía $HOME_DIR, $USER matchearía $USERNAME)
    path="${path//\$\{HOME\}/${HOME}}"
    path="${path//\$\{USER\}/${user}}"
    path="${path//\$\{XDG_CONFIG_HOME\}/${XDG_CONFIG_HOME:-${HOME}/.config}}"
    path="${path//\$\{XDG_DATA_HOME\}/${XDG_DATA_HOME:-${HOME}/.local/share}}"
    path="${path//\$\{REPO_ROOT\}/${repo_root}}"
    echo "${path}"
}

# Extraer contenido sin frontmatter YAML
extract_content() {
    local file="$1"
    awk '
        NR==1 && /^---$/ { in_frontmatter=1; next }
        in_frontmatter && /^---$/ { in_frontmatter=0; found_end=1; next }
        !in_frontmatter && found_end { print; next }
        !in_frontmatter { print }
    ' "${file}"
}

# Verificar si un archivo tiene frontmatter
has_frontmatter() {
    local file="$1"
    head -1 "$file" 2>/dev/null | grep -q "^---$"
}

# Obtener timestamp actual
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Crear backup de un archivo
backup_file() {
    local file="$1"
    local backup_dir="${2:-/tmp/agent-development-rules-backup}"

    if [[ -f "$file" ]]; then
        mkdir -p "$backup_dir"
        local backup_name
        backup_name="$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
        cp "$file" "${backup_dir}/${backup_name}"
        log_debug "Backup creado: ${backup_dir}/${backup_name}"

        # Rotación: mantener solo los últimos 5 backups por archivo
        local base_pattern
        base_pattern="$(basename "$file").*.bak"
        local backup_list
        backup_list=$(find "$backup_dir" -name "${base_pattern}" -type f 2>/dev/null | sort -r)
        local old_backups
        old_backups=$(echo "${backup_list}" | awk 'NR > 5')
        if [[ -n "${old_backups}" ]]; then
            while IFS= read -r old_file; do
                rm -f "${old_file}"
            done <<< "${old_backups}"
            log_debug "Backups antiguos eliminados"
        fi
    fi
}

# Verificar dependencias
check_dependency() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" &> /dev/null; then
        log_error "Dependencia faltante: $cmd"
        if [[ -n "$install_hint" ]]; then
            log_info "Instalar con: $install_hint"
        fi
        return 1
    fi
    return 0
}

# Resolver directorio de contenido desde manifest
resolve_content_dir() {
    local repo_root="$1"
    local manifest="$2"
    local content_dir_name
    content_dir_name=$(yq '.content_dir // ""' "${manifest}")
    if [[ -n "${content_dir_name}" && "${content_dir_name}" != "null" ]]; then
        echo "${repo_root}/${content_dir_name}"
    else
        echo "${repo_root}"
    fi
}

# =============================================================================
# Funciones de archivo
# =============================================================================

# Mostrar diff entre archivo existente y nuevo contenido
show_diff() {
    local path="$1"
    local new_content="$2"

    if [[ -f "$path" ]]; then
        diff --color=auto "$path" <(printf '%s\n' "$new_content") || true
    else
        printf '%b\n' "${GREEN}+ [Archivo nuevo]${NC}"
    fi
}
