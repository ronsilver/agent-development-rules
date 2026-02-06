#!/usr/bin/env bash
# =============================================================================
# common.sh - Funciones comunes para agent-development-rules
# =============================================================================

# Colores
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export NC='\033[0m'

# =============================================================================
# Funciones de logging
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1" >&2
    fi
}

log_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
    echo -e "${BLUE}  $1${NC}" >&2
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

log_fail() {
    echo -e "${RED}✗${NC} $1" >&2
}

# =============================================================================
# Funciones de utilidad
# =============================================================================

# Expandir variables de entorno en un string
expand_path() {
    local path="$1"
    eval echo "$path"
}

# Extraer contenido sin frontmatter YAML
extract_content() {
    local file="$1"
    awk '
        BEGIN { in_frontmatter=0; found_end=0 }
        /^---$/ && !found_end {
            if (in_frontmatter) { found_end=1; next }
            in_frontmatter=1
            next
        }
        found_end { print }
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

# =============================================================================
# Funciones de archivo
# =============================================================================

# Escribir contenido a archivo (con dry-run support)
write_file() {
    local path="$1"
    local content="$2"
    local dry_run="${3:-false}"

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY-RUN] Escribiría: $path"
        return 0
    fi

    mkdir -p "$(dirname "$path")"
    echo -e "$content" > "$path"
    log_info "  → $path"
}

# Mostrar diff entre archivo existente y nuevo contenido
show_diff() {
    local path="$1"
    local new_content="$2"

    if [[ -f "$path" ]]; then
        diff --color=auto <(cat "$path") <(echo -e "$new_content") || true
    else
        echo -e "${GREEN}+ [Archivo nuevo]${NC}"
    fi
}
