#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# sync.sh - Script unificado para sincronizar reglas a agentes de AI v2.0
# =============================================================================
# Lee configuración de manifest.yaml y sincroniza reglas, workflows y prompts
# a los destinos configurados para cada agente.
#
# Uso:
#   ./scripts/sync.sh                    # Sincroniza todos los agentes habilitados
#   ./scripts/sync.sh --agent windsurf   # Sincroniza solo un agente
#   ./scripts/sync.sh --dry-run          # Muestra qué haría sin ejecutar
#   ./scripts/sync.sh --list             # Lista agentes disponibles
#   ./scripts/sync.sh --backup           # Crear backup antes de escribir
#   ./scripts/sync.sh --validate         # Validar antes de sincronizar
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
MANIFEST_FILE="${REPO_ROOT}/manifest.yaml"

# Cargar funciones comunes
source "${SCRIPT_DIR}/lib/common.sh"

# Variables globales
DRY_RUN=false
SPECIFIC_AGENT=""
CREATE_BACKUP=false
VALIDATE_FIRST=false
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
CONTENT_DIR=""

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

# Verificar si un agente está habilitado
is_agent_enabled() {
    local agent="$1"
    local enabled
    enabled=$(yq ".agents.${agent}.enabled // false" "${MANIFEST_FILE}")
    [[ "${enabled}" == "true" ]]
}

# Verificar si un agente está instalado
is_agent_installed() {
    local agent="$1"
    local detect_config=".agents.${agent}.detect"

    # Si no hay configuración de detección, asumir instalado
    if [[ $(yq "${detect_config}" "${MANIFEST_FILE}") == "null" ]]; then
        return 0
    fi

    # Verificar paths (cualquiera que exista)
    local paths
    paths=$(yq "${detect_config}.paths[]" "${MANIFEST_FILE}" 2>/dev/null || echo "")
    if [[ -n "${paths}" ]]; then
        while IFS= read -r path; do
            # Expandir variables de entorno
            local expanded_path
            expanded_path=$(eval echo "${path}")
            # Soportar globs
            if compgen -G "${expanded_path}" > /dev/null 2>&1; then
                log_debug "Detectado ${agent} via path: ${expanded_path}"
                return 0
            fi
        done <<< "${paths}"
    fi

    # Verificar comandos (cualquiera que funcione)
    local commands
    commands=$(yq "${detect_config}.commands[]" "${MANIFEST_FILE}" 2>/dev/null || echo "")
    if [[ -n "${commands}" ]]; then
        while IFS= read -r cmd; do
            if [[ -n "${cmd}" ]] && eval "${cmd}" &>/dev/null; then
                log_debug "Detectado ${agent} via comando: ${cmd}"
                return 0
            fi
        done <<< "${commands}"
    fi

    # Si hay configuración pero no se detectó nada
    return 1
}

# Obtener lista de archivos para un tipo (rules, workflows, prompts)
get_source_files() {
    local type="$1"
    local source_dir
    source_dir=$(yq ".${type}.source_dir" "${MANIFEST_FILE}")

    yq ".${type}.files[]" "${MANIFEST_FILE}" | while read -r file; do
        local full_path="${CONTENT_DIR}/${source_dir}/${file}"
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
    multi_paths=$(yq "${target_config}.paths[]?" "${MANIFEST_FILE}" 2>/dev/null || true)
    if [[ -n "${multi_paths}" ]]; then
        while IFS= read -r p; do
            paths+=("$(expand_path "${p}")")
        done <<< "${multi_paths}"
    fi

    # Glob paths
    local glob_paths
    glob_paths=$(yq "${target_config}.glob_paths[]?" "${MANIFEST_FILE}" 2>/dev/null || true)
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

    # Verificar si el agente está instalado
    if ! is_agent_installed "${agent}"; then
        log_debug "Agente '${agent}' no está instalado - saltando"
        return 0
    fi

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

    # Sincronizar instructions (para agentes que lo soporten)
    log_info "Sincronizando instructions..."
    sync_merged "${agent}" "instructions" "rules"
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

        # Verificar instalación
        local install_color="${RED}"
        local install_text="no instalado"
        if is_agent_installed "${agent}"; then
            install_color="${GREEN}"
            install_text="instalado"
        fi

        echo -e "  ${CYAN}${agent}${NC} - ${description}"
        echo -e "    Estado: ${status_color}${status_text}${NC} | ${install_color}${install_text}${NC}"
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
            --backup|-b)
                CREATE_BACKUP=true
                shift
                ;;
            --validate|-v)
                VALIDATE_FIRST=true
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
                echo "  --backup, -b          Crear backup antes de escribir"
                echo "  --validate, -v        Validar configuración antes de sincronizar"
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

    # Obtener directorio de contenido desde manifest (v2.0)
    local content_dir_name
    content_dir_name=$(yq '.content_dir // ""' "${MANIFEST_FILE}")
    if [[ -n "${content_dir_name}" && "${content_dir_name}" != "null" ]]; then
        CONTENT_DIR="${REPO_ROOT}/${content_dir_name}"
    else
        # Fallback para v1.0 (compatibilidad)
        CONTENT_DIR="${REPO_ROOT}"
    fi

    log_section "Agent Development Rules - Sincronización v2.0"
    log_info "Manifest: ${MANIFEST_FILE}"
    log_info "Content: ${CONTENT_DIR}"
    log_info "Timestamp: ${TIMESTAMP}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "Modo DRY-RUN activado - no se realizarán cambios"
    fi

    if [[ "${CREATE_BACKUP}" == "true" ]]; then
        log_info "Backups habilitados"
    fi

    # Validar si se solicitó
    if [[ "${VALIDATE_FIRST}" == "true" ]]; then
        log_info "Ejecutando validación..."
        if [[ -x "${SCRIPT_DIR}/validate.sh" ]]; then
            "${SCRIPT_DIR}/validate.sh" || exit 1
        else
            log_warn "validate.sh no encontrado, saltando validación"
        fi
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
