#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# sync.sh - Script unificado para sincronizar reglas a agentes de AI
# =============================================================================
# Lee configuración de manifest.yaml y sincroniza reglas, workflows y prompts
# a los destinos configurados para cada agente.
#
# Uso:
#   ./scripts/sync.sh                    # Sincroniza todos los agentes habilitados
#   ./scripts/sync.sh --agent windsurf   # Sincroniza solo un agente
#   ./scripts/sync.sh --dry-run          # Muestra qué haría sin ejecutar
#   ./scripts/sync.sh --list             # Lista agentes disponibles
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
MANIFEST_FILE="${REPO_ROOT}/manifest.yaml"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales
DRY_RUN=false
SPECIFIC_AGENT=""
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

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

# =============================================================================
# Verificar dependencias
# =============================================================================

check_dependencies() {
    local missing=()
    
    if ! command -v yq &> /dev/null; then
        missing+=("yq")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Dependencias faltantes: ${missing[*]}"
        log_info "Instalar con: brew install ${missing[*]}"
        exit 1
    fi
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

# Verificar si un agente está habilitado
is_agent_enabled() {
    local agent="$1"
    local enabled
    enabled=$(yq ".agents.${agent}.enabled // false" "${MANIFEST_FILE}")
    [[ "${enabled}" == "true" ]]
}

# Obtener lista de archivos para un tipo (rules, workflows, prompts)
get_source_files() {
    local type="$1"
    local source_dir
    source_dir=$(yq ".${type}.source_dir" "${MANIFEST_FILE}")
    
    yq ".${type}.files[]" "${MANIFEST_FILE}" | while read -r file; do
        local full_path="${REPO_ROOT}/${source_dir}/${file}"
        if [[ -f "${full_path}" ]]; then
            echo "${full_path}"
        else
            log_warn "Archivo no encontrado: ${full_path}"
        fi
    done
}

# =============================================================================
# Función principal de sincronización
# =============================================================================

sync_merged() {
    local agent="$1"
    local target_type="$2"  # rules, workflows, prompts
    local source_type="$3"  # tipo en manifest (rules, workflows, prompts)
    
    local target_config=".agents.${agent}.targets.${target_type}"
    
    # Verificar si existe la configuración
    if [[ $(yq "${target_config}" "${MANIFEST_FILE}") == "null" ]]; then
        log_debug "No hay configuración de ${target_type} para ${agent}"
        return 0
    fi
    
    local format
    format=$(yq "${target_config}.format // \"merged\"" "${MANIFEST_FILE}")
    
    local strip_frontmatter
    strip_frontmatter=$(yq "${target_config}.strip_frontmatter // false" "${MANIFEST_FILE}")
    
    local header
    header=$(yq "${target_config}.header // \"\"" "${MANIFEST_FILE}" | sed "s/{{timestamp}}/${TIMESTAMP}/g")
    
    # Obtener paths de destino
    local paths=()
    
    # Path único
    local single_path
    single_path=$(yq "${target_config}.path // \"\"" "${MANIFEST_FILE}")
    if [[ -n "${single_path}" && "${single_path}" != "null" ]]; then
        paths+=("$(expand_path "${single_path}")")
    fi
    
    # Múltiples paths
    local multi_paths
    multi_paths=$(yq "${target_config}.paths[]? // empty" "${MANIFEST_FILE}" 2>/dev/null || true)
    if [[ -n "${multi_paths}" ]]; then
        while IFS= read -r p; do
            paths+=("$(expand_path "${p}")")
        done <<< "${multi_paths}"
    fi
    
    # Glob paths
    local glob_paths
    glob_paths=$(yq "${target_config}.glob_paths[]? // empty" "${MANIFEST_FILE}" 2>/dev/null || true)
    if [[ -n "${glob_paths}" ]]; then
        while IFS= read -r pattern; do
            local expanded_pattern
            expanded_pattern=$(expand_path "${pattern}")
            shopt -s nullglob
            for expanded_dir in ${expanded_pattern}; do
                paths+=("${expanded_dir}")
            done
            shopt -u nullglob
        done <<< "${glob_paths}"
    fi
    
    if [[ ${#paths[@]} -eq 0 ]]; then
        log_warn "No hay paths configurados para ${agent}/${target_type}"
        return 0
    fi
    
    # Obtener nombre de archivo de salida
    local output_filename
    output_filename=$(yq "${target_config}.output_filename // \"\"" "${MANIFEST_FILE}")
    
    # Generar contenido
    local content=""
    
    # Agregar header si existe
    if [[ -n "${header}" && "${header}" != "null" ]]; then
        content="${header}"
    fi
    
    # Agregar contenido de archivos
    while IFS= read -r source_file; do
        [[ -z "${source_file}" ]] && continue
        
        if [[ "${strip_frontmatter}" == "true" ]]; then
            content+=$(extract_content "${source_file}")
        else
            content+=$(cat "${source_file}")
        fi
        content+=$'\n\n---\n\n'
    done < <(get_source_files "${source_type}")
    
    # Escribir a cada destino
    for target_path in "${paths[@]}"; do
        local final_path="${target_path}"
        
        # Si es un directorio, usar output_filename
        if [[ -d "${target_path}" || "${target_path}" != *".md" ]]; then
            mkdir -p "${target_path}"
            if [[ -n "${output_filename}" && "${output_filename}" != "null" ]]; then
                final_path="${target_path}/${output_filename}"
            else
                final_path="${target_path}/rules.md"
            fi
        else
            mkdir -p "$(dirname "${target_path}")"
        fi
        
        if [[ "${DRY_RUN}" == "true" ]]; then
            log_info "[DRY-RUN] Escribiría a: ${final_path}"
        else
            echo "${content}" > "${final_path}"
            log_info "  → ${final_path}"
        fi
    done
}

# =============================================================================
# Sincronizar un agente específico
# =============================================================================

sync_agent() {
    local agent="$1"
    
    if ! is_agent_enabled "${agent}"; then
        log_warn "Agente '${agent}' está deshabilitado"
        return 0
    fi
    
    local description
    description=$(yq ".agents.${agent}.description // \"${agent}\"" "${MANIFEST_FILE}")
    
    log_section "Sincronizando: ${description}"
    
    # Sincronizar rules
    log_info "Sincronizando rules..."
    sync_merged "${agent}" "rules" "rules"
    
    # Sincronizar workflows
    log_info "Sincronizando workflows..."
    sync_merged "${agent}" "workflows" "workflows"
    
    # Sincronizar prompts
    log_info "Sincronizando prompts..."
    sync_merged "${agent}" "prompts" "prompts"
}

# =============================================================================
# Listar agentes disponibles
# =============================================================================

list_agents() {
    log_section "Agentes Disponibles"
    
    local agents
    agents=$(yq '.agents | keys | .[]' "${MANIFEST_FILE}")
    
    while IFS= read -r agent; do
        local enabled
        enabled=$(yq ".agents.${agent}.enabled" "${MANIFEST_FILE}")
        local description
        description=$(yq ".agents.${agent}.description // \"\"" "${MANIFEST_FILE}")
        
        local status_color="${RED}"
        local status_text="deshabilitado"
        if [[ "${enabled}" == "true" ]]; then
            status_color="${GREEN}"
            status_text="habilitado"
        fi
        
        echo -e "  ${CYAN}${agent}${NC} - ${description}"
        echo -e "    Estado: ${status_color}${status_text}${NC}"
    done <<< "${agents}"
}

# =============================================================================
# Parsear argumentos
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --agent|-a)
                SPECIFIC_AGENT="$2"
                shift 2
                ;;
            --dry-run|-n)
                DRY_RUN=true
                shift
                ;;
            --list|-l)
                list_agents
                exit 0
                ;;
            --debug|-d)
                export DEBUG=true
                shift
                ;;
            --help|-h)
                echo "Uso: $0 [opciones]"
                echo ""
                echo "Opciones:"
                echo "  --agent, -a <nombre>  Sincronizar solo un agente específico"
                echo "  --dry-run, -n         Mostrar qué haría sin ejecutar"
                echo "  --list, -l            Listar agentes disponibles"
                echo "  --debug, -d           Mostrar información de debug"
                echo "  --help, -h            Mostrar esta ayuda"
                exit 0
                ;;
            *)
                log_error "Opción desconocida: $1"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Main
# =============================================================================

main() {
    parse_args "$@"
    
    # Verificar que existe el manifest
    if [[ ! -f "${MANIFEST_FILE}" ]]; then
        log_error "Manifest no encontrado: ${MANIFEST_FILE}"
        exit 1
    fi
    
    check_dependencies
    
    log_section "Agent Rules - Sincronización"
    log_info "Manifest: ${MANIFEST_FILE}"
    log_info "Timestamp: ${TIMESTAMP}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "Modo DRY-RUN activado - no se realizarán cambios"
    fi
    
    if [[ -n "${SPECIFIC_AGENT}" ]]; then
        # Sincronizar agente específico
        sync_agent "${SPECIFIC_AGENT}"
    else
        # Sincronizar todos los agentes habilitados
        local agents
        agents=$(yq '.agents | keys | .[]' "${MANIFEST_FILE}")
        
        while IFS= read -r agent; do
            if is_agent_enabled "${agent}"; then
                sync_agent "${agent}"
            else
                log_debug "Saltando agente deshabilitado: ${agent}"
            fi
        done <<< "${agents}"
    fi
    
    echo ""
    log_info "✓ Sincronización completada"
}

main "$@"
