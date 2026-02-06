#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# validate.sh - Validar configuración de agent-development-rules
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
MANIFEST_FILE="${REPO_ROOT}/manifest.yaml"

# Cargar funciones comunes
source "${SCRIPT_DIR}/lib/common.sh"

# Variables
CONTENT_DIR=""
ERRORS=0
WARNINGS=0

# =============================================================================
# Funciones de validación
# =============================================================================

validate_manifest() {
    log_section "Validando manifest.yaml"

    # Verificar que existe
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_error "manifest.yaml no encontrado: $MANIFEST_FILE"
        ((ERRORS++))
        return 1
    fi

    # Verificar sintaxis YAML
    if ! yq '.' "$MANIFEST_FILE" > /dev/null 2>&1; then
        log_error "manifest.yaml tiene sintaxis YAML inválida"
        ((ERRORS++))
        return 1
    fi

    # Verificar versión
    local version
    version=$(yq '.version // ""' "$MANIFEST_FILE")
    if [[ -z "$version" || "$version" == "null" ]]; then
        log_warn "manifest.yaml no tiene versión definida"
        ((WARNINGS++))
    else
        log_debug "Versión del manifest: $version"
    fi

    log_success "manifest.yaml es válido"
    return 0
}

validate_content_dir() {
    log_section "Validando directorio de contenido"

    local content_dir_name
    content_dir_name=$(yq '.content_dir // ""' "$MANIFEST_FILE")

    if [[ -n "$content_dir_name" && "$content_dir_name" != "null" ]]; then
        CONTENT_DIR="${REPO_ROOT}/${content_dir_name}"
    else
        CONTENT_DIR="${REPO_ROOT}"
    fi

    if [[ ! -d "$CONTENT_DIR" ]]; then
        log_error "Directorio de contenido no encontrado: $CONTENT_DIR"
        ((ERRORS++))
        return 1
    fi

    log_success "Directorio de contenido: $CONTENT_DIR"
    return 0
}

validate_files() {
    log_section "Validando archivos referenciados"

    local file_errors=0

    # Validar rules
    log_info "Validando rules..."
    local rules_dir
    rules_dir=$(yq '.rules.source_dir // "rules"' "$MANIFEST_FILE")

    while IFS= read -r file; do
        [[ -z "$file" || "$file" == "null" ]] && continue
        local full_path="${CONTENT_DIR}/${rules_dir}/${file}"
        if [[ ! -f "$full_path" ]]; then
            log_error "  Archivo no encontrado: ${rules_dir}/${file}"
            ((file_errors++))
        else
            log_debug "  ✓ ${rules_dir}/${file}"
        fi
    done < <(yq '.rules.files[]' "$MANIFEST_FILE" 2>/dev/null)

    # Validar workflows
    log_info "Validando workflows..."
    local workflows_dir
    workflows_dir=$(yq '.workflows.source_dir // "workflows"' "$MANIFEST_FILE")

    while IFS= read -r file; do
        [[ -z "$file" || "$file" == "null" ]] && continue
        local full_path="${CONTENT_DIR}/${workflows_dir}/${file}"
        if [[ ! -f "$full_path" ]]; then
            log_error "  Archivo no encontrado: ${workflows_dir}/${file}"
            ((file_errors++))
        else
            log_debug "  ✓ ${workflows_dir}/${file}"
        fi
    done < <(yq '.workflows.files[]' "$MANIFEST_FILE" 2>/dev/null)

    # Validar prompts
    log_info "Validando prompts..."
    local prompts_dir
    prompts_dir=$(yq '.prompts.source_dir // "prompts"' "$MANIFEST_FILE")

    while IFS= read -r file; do
        [[ -z "$file" || "$file" == "null" ]] && continue
        local full_path="${CONTENT_DIR}/${prompts_dir}/${file}"
        if [[ ! -f "$full_path" ]]; then
            log_error "  Archivo no encontrado: ${prompts_dir}/${file}"
            ((file_errors++))
        else
            log_debug "  ✓ ${prompts_dir}/${file}"
        fi
    done < <(yq '.prompts.files[]' "$MANIFEST_FILE" 2>/dev/null)

    if [[ $file_errors -gt 0 ]]; then
        log_error "Se encontraron $file_errors archivos faltantes"
        ERRORS=$((ERRORS + file_errors))
        return 1
    fi

    log_success "Todos los archivos existen"
    return 0
}

validate_frontmatter() {
    log_section "Validando frontmatter de archivos"

    local fm_warnings=0

    # Validate rules frontmatter (require: trigger)
    local rules_dir
    rules_dir=$(yq '.rules.source_dir // "rules"' "$MANIFEST_FILE")
    local rules_path="${CONTENT_DIR}/${rules_dir}"

    if [[ -d "$rules_path" ]]; then
        log_info "Validando frontmatter de rules..."
        while IFS= read -r file; do
            local rel_path="${file#${CONTENT_DIR}/}"
            if ! has_frontmatter "$file"; then
                log_warn "  Sin frontmatter: ${rel_path}"
                ((fm_warnings++))
            else
                # Check for 'trigger' field
                local trigger
                trigger=$(awk '/^---$/{if(n++)exit}n' "$file" | grep -c "^trigger:" || true)
                if [[ "$trigger" -eq 0 ]]; then
                    log_warn "  Falta 'trigger' en frontmatter: ${rel_path}"
                    ((fm_warnings++))
                fi
            fi
        done < <(find "$rules_path" -name "*.md" -type f 2>/dev/null)
    fi

    # Validate workflows frontmatter (require: description)
    local workflows_dir
    workflows_dir=$(yq '.workflows.source_dir // "workflows"' "$MANIFEST_FILE")
    local workflows_path="${CONTENT_DIR}/${workflows_dir}"

    if [[ -d "$workflows_path" ]]; then
        log_info "Validando frontmatter de workflows..."
        while IFS= read -r file; do
            local rel_path="${file#${CONTENT_DIR}/}"
            if ! has_frontmatter "$file"; then
                log_warn "  Sin frontmatter: ${rel_path}"
                ((fm_warnings++))
            else
                local has_desc
                has_desc=$(awk '/^---$/{if(n++)exit}n' "$file" | grep -c "^description:" || true)
                if [[ "$has_desc" -eq 0 ]]; then
                    log_warn "  Falta 'description' en frontmatter: ${rel_path}"
                    ((fm_warnings++))
                fi
            fi
        done < <(find "$workflows_path" -name "*.md" -type f 2>/dev/null)
    fi

    # Validate prompts frontmatter (require: name, description)
    local prompts_dir
    prompts_dir=$(yq '.prompts.source_dir // "prompts"' "$MANIFEST_FILE")
    local prompts_path="${CONTENT_DIR}/${prompts_dir}"

    if [[ -d "$prompts_path" ]]; then
        log_info "Validando frontmatter de prompts..."
        while IFS= read -r file; do
            local rel_path="${file#${CONTENT_DIR}/}"
            if ! has_frontmatter "$file"; then
                log_warn "  Sin frontmatter: ${rel_path}"
                ((fm_warnings++))
            else
                local fm_content
                fm_content=$(awk '/^---$/{if(n++)exit}n' "$file")
                if ! echo "$fm_content" | grep -q "^name:"; then
                    log_warn "  Falta 'name' en frontmatter: ${rel_path}"
                    ((fm_warnings++))
                fi
                if ! echo "$fm_content" | grep -q "^description:"; then
                    log_warn "  Falta 'description' en frontmatter: ${rel_path}"
                    ((fm_warnings++))
                fi
            fi
        done < <(find "$prompts_path" -name "*.md" -type f 2>/dev/null)
    fi

    if [[ $fm_warnings -gt 0 ]]; then
        log_warn "Se encontraron $fm_warnings problemas de frontmatter"
        WARNINGS=$((WARNINGS + fm_warnings))
    else
        log_success "Todos los archivos tienen frontmatter válido"
    fi

    return 0
}

validate_agents() {
    log_section "Validando configuración de agentes"

    local agents
    agents=$(yq '.agents | keys | .[]' "$MANIFEST_FILE" 2>/dev/null)

    if [[ -z "$agents" ]]; then
        log_warn "No hay agentes configurados"
        ((WARNINGS++))
        return 0
    fi

    local enabled_count=0

    while IFS= read -r agent; do
        [[ -z "$agent" ]] && continue

        local enabled
        enabled=$(yq ".agents.${agent}.enabled // false" "$MANIFEST_FILE")
        local description
        description=$(yq ".agents.${agent}.description // \"\"" "$MANIFEST_FILE")

        if [[ "$enabled" == "true" ]]; then
            log_info "  ✓ ${agent}: ${description} (habilitado)"
            ((enabled_count++))
        else
            log_debug "  ○ ${agent}: ${description} (deshabilitado)"
        fi
    done <<< "$agents"

    if [[ $enabled_count -eq 0 ]]; then
        log_warn "No hay agentes habilitados"
        ((WARNINGS++))
    else
        log_success "$enabled_count agente(s) habilitado(s)"
    fi

    return 0
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug|-d)
                export DEBUG=true
                shift
                ;;
            --help|-h)
                echo "Uso: $0 [opciones]"
                echo ""
                echo "Opciones:"
                echo "  --debug, -d    Mostrar información de debug"
                echo "  --help, -h     Mostrar esta ayuda"
                exit 0
                ;;
            *)
                log_error "Opción desconocida: $1"
                exit 1
                ;;
        esac
    done

    log_section "Agent Development Rules - Validación"

    # Verificar dependencias
    if ! command -v yq &> /dev/null; then
        log_error "yq no encontrado. Instalar con: brew install yq"
        exit 1
    fi

    # Ejecutar validaciones
    validate_manifest || true
    validate_content_dir || true
    validate_files || true
    validate_frontmatter || true
    validate_agents || true

    # Resumen
    echo ""
    log_section "Resumen"

    if [[ $ERRORS -gt 0 ]]; then
        log_error "Errores: $ERRORS"
    else
        log_success "Errores: 0"
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        log_warn "Advertencias: $WARNINGS"
    else
        log_success "Advertencias: 0"
    fi

    echo ""

    if [[ $ERRORS -gt 0 ]]; then
        log_fail "Validación fallida"
        exit 1
    else
        log_success "Validación completada"
        exit 0
    fi
}

main "$@"
