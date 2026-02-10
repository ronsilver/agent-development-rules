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
source "${SCRIPT_DIR}/lib/sync.sh"

# Variables globales
DRY_RUN=false
SPECIFIC_AGENT=""
CREATE_BACKUP=false
VALIDATE_FIRST=false
TIMESTAMP=$(get_timestamp)
CONTENT_DIR=""

# =============================================================================
# Verificar dependencias
# =============================================================================

check_dependencies() {
    check_dependency "yq" "brew install yq" || exit 1
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
            local expanded_path
            expanded_path=$(expand_path "${path}")
            # Soportar globs
            if compgen -G "${expanded_path}" > /dev/null 2>&1; then
                log_debug "Detectado ${agent} via path: ${expanded_path}"
                return 0
            fi
        done <<< "${paths}"
    fi

    # Verificar comandos (solo el binario principal, sin eval)
    local commands
    commands=$(yq "${detect_config}.commands[]" "${MANIFEST_FILE}" 2>/dev/null || echo "")
    if [[ -n "${commands}" ]]; then
        while IFS= read -r cmd; do
            [[ -z "${cmd}" ]] && continue
            # Extraer solo el binario principal para verificar existencia
            local binary="${cmd%% *}"
            if command -v "${binary}" &>/dev/null; then
                log_debug "Detectado ${agent} via comando: ${binary}"
                return 0
            fi
        done <<< "${commands}"
    fi

    # Si hay configuración pero no se detectó nada
    return 1
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

    # Descubrir target types desde el manifest
    local target_types
    target_types=$(yq ".agents.${agent}.targets | keys | .[]" "${MANIFEST_FILE}" 2>/dev/null || echo "")

    if [[ -z "${target_types}" ]]; then
        log_warn "No hay targets configurados para ${agent}"
        return 0
    fi

    while IFS= read -r target_type; do
        [[ -z "${target_type}" ]] && continue
        local source_type
        source_type=$(yq ".agents.${agent}.targets.${target_type}.source_type // \"${target_type}\"" "${MANIFEST_FILE}")
        log_info "Sincronizando ${target_type}..."
        sync_target "${agent}" "${target_type}" "${source_type}"
    done <<< "${target_types}"
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

        echo -e "  ${CYAN}${agent}${NC} - ${description}" >&2
        echo -e "    Estado: ${status_color}${status_text}${NC} | ${install_color}${install_text}${NC}" >&2
    done <<< "${agents}"
}

# =============================================================================
# Parsear argumentos
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --agent|-a)
                if [[ $# -lt 2 ]]; then
                    log_error "--agent requiere un nombre de agente"
                    exit 1
                fi
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
    CONTENT_DIR=$(resolve_content_dir "${REPO_ROOT}" "${MANIFEST_FILE}")

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
        # Validar formato del nombre de agente
        if ! [[ "${SPECIFIC_AGENT}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            log_error "Nombre de agente inválido: '${SPECIFIC_AGENT}' (solo alfanuméricos, guiones y guiones bajos)"
            exit 1
        fi
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

    echo "" >&2
    log_info "✓ Sincronización completada"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
