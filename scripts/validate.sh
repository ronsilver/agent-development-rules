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
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    # Verificar sintaxis YAML
    if ! yq '.' "$MANIFEST_FILE" > /dev/null 2>&1; then
        log_error "manifest.yaml tiene sintaxis YAML inválida"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    # Verificar versión
    local version
    version=$(yq '.version // ""' "$MANIFEST_FILE")
    if [[ -z "$version" || "$version" == "null" ]]; then
        log_warn "manifest.yaml no tiene versión definida"
        WARNINGS=$((WARNINGS + 1))
    else
        log_debug "Versión del manifest: $version"
    fi

    log_success "manifest.yaml es válido"
    return 0
}

validate_content_dir() {
    log_section "Validando directorio de contenido"

    CONTENT_DIR=$(resolve_content_dir "${REPO_ROOT}" "${MANIFEST_FILE}")

    if [[ ! -d "$CONTENT_DIR" ]]; then
        log_error "Directorio de contenido no encontrado: $CONTENT_DIR"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    log_success "Directorio de contenido: $CONTENT_DIR"
    return 0
}

# Validar archivos de un tipo específico (genérico)
validate_file_list() {
    local type="$1"
    local errors=0

    log_info "Validando ${type}..."
    local source_dir
    source_dir=$(yq ".${type}.source_dir // \"${type}\"" "$MANIFEST_FILE")

    while IFS= read -r file; do
        [[ -z "$file" || "$file" == "null" ]] && continue
        local full_path="${CONTENT_DIR}/${source_dir}/${file}"
        if [[ ! -f "$full_path" ]]; then
            log_error "  Archivo no encontrado: ${source_dir}/${file}"
            errors=$((errors + 1))
        else
            log_debug "  ✓ ${source_dir}/${file}"
        fi
    done < <(yq ".${type}.files[]" "$MANIFEST_FILE" 2>/dev/null)

    echo "${errors}"
}

validate_files() {
    log_section "Validando archivos referenciados"

    local file_errors=0
    local type_errors

    for type in rules workflows prompts; do
        type_errors=$(validate_file_list "${type}")
        file_errors=$((file_errors + type_errors))
    done

    if [[ $file_errors -gt 0 ]]; then
        log_error "Se encontraron $file_errors archivos faltantes"
        ERRORS=$((ERRORS + file_errors))
        return 1
    fi

    log_success "Todos los archivos existen"
    return 0
}

# Validar frontmatter de archivos en un directorio con campos requeridos
validate_frontmatter_dir() {
    local dir_path="$1"
    local label="$2"
    shift 2
    local required_fields=("$@")
    local warnings=0

    if [[ ! -d "${dir_path}" ]]; then
        echo "0"
        return
    fi

    log_info "Validando frontmatter de ${label}..."
    while IFS= read -r file; do
        local rel_path="${file#"${CONTENT_DIR}"/}"
        if ! has_frontmatter "$file"; then
            log_warn "  Sin frontmatter: ${rel_path}"
            warnings=$((warnings + 1))
        else
            local fm_content
            fm_content=$(awk '/^---$/{if(n++)exit}n' "$file")
            for field in "${required_fields[@]}"; do
                if ! printf '%s\n' "$fm_content" | grep -q "^${field}:"; then
                    log_warn "  Falta '${field}' en frontmatter: ${rel_path}"
                    warnings=$((warnings + 1))
                fi
            done
        fi
    done < <(find "${dir_path}" -name "*.md" -type f 2>/dev/null)

    echo "${warnings}"
}

validate_frontmatter() {
    log_section "Validando frontmatter de archivos"

    local fm_warnings=0
    local type_warnings

    # Esquema de campos requeridos por tipo
    local rules_dir
    rules_dir=$(yq '.rules.source_dir // "rules"' "$MANIFEST_FILE")
    type_warnings=$(validate_frontmatter_dir "${CONTENT_DIR}/${rules_dir}" "rules" "trigger")
    fm_warnings=$((fm_warnings + type_warnings))

    local workflows_dir
    workflows_dir=$(yq '.workflows.source_dir // "workflows"' "$MANIFEST_FILE")
    type_warnings=$(validate_frontmatter_dir "${CONTENT_DIR}/${workflows_dir}" "workflows" "description")
    fm_warnings=$((fm_warnings + type_warnings))

    local prompts_dir
    prompts_dir=$(yq '.prompts.source_dir // "prompts"' "$MANIFEST_FILE")
    type_warnings=$(validate_frontmatter_dir "${CONTENT_DIR}/${prompts_dir}" "prompts" "name" "description")
    fm_warnings=$((fm_warnings + type_warnings))

    if [[ $fm_warnings -gt 0 ]]; then
        log_warn "Se encontraron $fm_warnings problemas de frontmatter"
        WARNINGS=$((WARNINGS + fm_warnings))
    else
        log_success "Todos los archivos tienen frontmatter válido"
    fi

    return 0
}

validate_skills() {
    log_section "Validando skills"

    local skills_source_dir
    skills_source_dir=$(yq '.skills.source_dir // "skills"' "$MANIFEST_FILE")
    local skills_base="${CONTENT_DIR}/${skills_source_dir}"

    # Verificar que el directorio de skills existe
    if [[ ! -d "${skills_base}" ]]; then
        log_warn "Directorio de skills no encontrado: ${skills_base}"
        WARNINGS=$((WARNINGS + 1))
        return 0
    fi

    local skill_errors=0
    local skill_warnings=0

    while IFS= read -r dir_name; do
        [[ -z "${dir_name}" || "${dir_name}" == "null" ]] && continue
        local skill_path="${skills_base}/${dir_name}"

        # Verificar que el directorio existe
        if [[ ! -d "${skill_path}" ]]; then
            log_error "  Directorio de skill no encontrado: ${skills_source_dir}/${dir_name}"
            skill_errors=$((skill_errors + 1))
            continue
        fi

        # Verificar que SKILL.md existe
        if [[ ! -f "${skill_path}/SKILL.md" ]]; then
            log_error "  SKILL.md no encontrado en: ${skills_source_dir}/${dir_name}/"
            skill_errors=$((skill_errors + 1))
            continue
        fi

        # Validar frontmatter de SKILL.md (name y description requeridos)
        local skill_md="${skill_path}/SKILL.md"
        if ! has_frontmatter "${skill_md}"; then
            log_error "  Sin frontmatter en SKILL.md: ${skills_source_dir}/${dir_name}/"
            skill_errors=$((skill_errors + 1))
            continue
        fi

        local fm_content
        fm_content=$(awk '/^---$/{if(n++)exit}n' "${skill_md}")

        for field in name description license; do
            if ! printf '%s\n' "${fm_content}" | grep -q "^${field}:"; then
                log_error "  Falta '${field}' en SKILL.md: ${skills_source_dir}/${dir_name}/"
                skill_errors=$((skill_errors + 1))
            fi
        done

        # Validar que no tenga metadata/version individual (canonical version is in manifest.yaml)
        if printf '%s\n' "${fm_content}" | grep -q "^metadata:"; then
            log_warn "  SKILL.md tiene 'metadata' (version es canónica en manifest.yaml): ${skills_source_dir}/${dir_name}/"
            skill_warnings=$((skill_warnings + 1))
        fi

        # Validar que name coincide con el nombre del directorio
        local skill_name
        skill_name=$(printf '%s\n' "${fm_content}" | grep '^name:' | sed 's/^name:[[:space:]]*//')
        if [[ -n "${skill_name}" && "${skill_name}" != "${dir_name}" ]]; then
            log_warn "  Nombre del skill '${skill_name}' no coincide con directorio '${dir_name}'"
            skill_warnings=$((skill_warnings + 1))
        fi

        # Validar formato del nombre (lowercase, hyphens, no consecutive hyphens)
        if [[ -n "${skill_name}" ]] && ! [[ "${skill_name}" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
            log_warn "  Nombre del skill no sigue convención (lowercase, hyphens): '${skill_name}'"
            skill_warnings=$((skill_warnings + 1))
        fi

        log_debug "  ✓ ${skills_source_dir}/${dir_name}/"
    done < <(yq '.skills.directories[]' "$MANIFEST_FILE" 2>/dev/null)

    if [[ ${skill_errors} -gt 0 ]]; then
        log_error "Se encontraron ${skill_errors} errores en skills"
        ERRORS=$((ERRORS + skill_errors))
    fi

    if [[ ${skill_warnings} -gt 0 ]]; then
        log_warn "Se encontraron ${skill_warnings} advertencias en skills"
        WARNINGS=$((WARNINGS + skill_warnings))
    fi

    if [[ ${skill_errors} -eq 0 && ${skill_warnings} -eq 0 ]]; then
        log_success "Todos los skills son válidos"
    fi

    return 0
}

validate_agents() {
    log_section "Validando configuración de agentes"

    local agents
    agents=$(yq '.agents | keys | .[]' "$MANIFEST_FILE" 2>/dev/null || true)

    if [[ -z "$agents" ]]; then
        log_warn "No hay agentes configurados"
        WARNINGS=$((WARNINGS + 1))
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
            enabled_count=$((enabled_count + 1))
        else
            log_debug "  ○ ${agent}: ${description} (deshabilitado)"
        fi
    done <<< "$agents"

    if [[ $enabled_count -eq 0 ]]; then
        log_warn "No hay agentes habilitados"
        WARNINGS=$((WARNINGS + 1))
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
    check_dependency "yq" "brew install yq" || exit 1

    # Validaciones fatales — sin estas no se puede continuar
    if ! validate_manifest; then
        log_fail "Manifest inválido, abortando"
        exit 1
    fi
    if ! validate_content_dir; then
        log_fail "Content dir inválido, abortando"
        exit 1
    fi

    # Validaciones no-fatales — solo si las fatales pasaron
    if [[ $ERRORS -eq 0 ]]; then
        validate_files || true
        validate_frontmatter || true
        validate_skills || true
        validate_agents || true
    fi

    # Resumen
    echo "" >&2
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

    echo "" >&2

    if [[ $ERRORS -gt 0 ]]; then
        log_fail "Validación fallida"
        exit 1
    else
        log_success "Validación completada"
        exit 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
