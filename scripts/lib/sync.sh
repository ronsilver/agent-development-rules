#!/usr/bin/env bash
# =============================================================================
# sync.sh (library) - Funciones de sincronización para agent-development-rules
# This file is meant to be sourced by scripts/sync.sh, not executed directly.
# =============================================================================
# Requires: common.sh sourced first, and the following globals:
#   MANIFEST_FILE, CONTENT_DIR, DRY_RUN, CREATE_BACKUP, TIMESTAMP
# =============================================================================

# Obtener lista de archivos para un tipo (rules, workflows, prompts)
get_source_files() {
    local type="$1"
    local source_dir
    source_dir=$(yq ".${type}.source_dir // \"${type}\"" "${MANIFEST_FILE}")

    while IFS= read -r file; do
        [[ -z "${file}" ]] && continue
        local full_path="${CONTENT_DIR}/${source_dir}/${file}"
        if [[ -f "${full_path}" ]]; then
            echo "${full_path}"
        else
            log_warn "Archivo no encontrado: ${full_path}"
        fi
    done < <(yq ".${type}.files[]" "${MANIFEST_FILE}" 2>/dev/null)
}

# =============================================================================
# Funciones de sincronización
# =============================================================================

# Obtener paths de destino para un target
get_target_paths() {
    local target_config="$1"
    local result_paths=()

    # Path único
    local single_path
    single_path=$(yq "${target_config}.path // \"\"" "${MANIFEST_FILE}")
    if [[ -n "${single_path}" && "${single_path}" != "null" ]]; then
        result_paths+=("$(expand_path "${single_path}")")
    fi

    # Múltiples paths
    local multi_paths
    multi_paths=$(yq "${target_config}.paths[]?" "${MANIFEST_FILE}" 2>/dev/null || true)
    if [[ -n "${multi_paths}" ]]; then
        while IFS= read -r p; do
            result_paths+=("$(expand_path "${p}")")
        done <<< "${multi_paths}"
    fi

    # Glob paths
    local glob_paths
    glob_paths=$(yq "${target_config}.glob_paths[]?" "${MANIFEST_FILE}" 2>/dev/null || true)
    if [[ -n "${glob_paths}" ]]; then
        while IFS= read -r pattern; do
            local expanded_pattern
            expanded_pattern=$(expand_path "${pattern}")
            # Subshell para aislar nullglob (B5)
            local matched
            matched=$(shopt -s nullglob; for d in ${expanded_pattern}; do echo "${d}"; done)
            if [[ -n "${matched}" ]]; then
                while IFS= read -r d; do
                    result_paths+=("${d}")
                done <<< "${matched}"
            fi
        done <<< "${glob_paths}"
    fi

    if [[ ${#result_paths[@]} -gt 0 ]]; then
        printf '%s\n' "${result_paths[@]}"
    fi
}

# Escribir archivo con soporte para backup y dry-run
write_sync_file() {
    local final_path="$1"
    local content="$2"

    # Skip si contenido no cambió (comparar por checksum para robustez)
    if [[ -f "${final_path}" ]]; then
        local existing_hash new_hash
        existing_hash=$(shasum -a 256 "${final_path}" | cut -d' ' -f1)
        new_hash=$(printf '%s\n' "${content}" | shasum -a 256 | cut -d' ' -f1)
        if [[ "${existing_hash}" == "${new_hash}" ]]; then
            log_debug "  Sin cambios: ${final_path}"
            return 0
        fi
    fi

    # Backup SOLO si hay cambio real
    if [[ "${CREATE_BACKUP}" == "true" ]]; then
        backup_file "${final_path}"
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Escribiría a: ${final_path}"
        show_diff "${final_path}" "${content}"
    else
        mkdir -p "$(dirname "${final_path}")"
        printf '%s\n' "${content}" > "${final_path}"
        log_info "  → ${final_path}"
    fi
}

# Transformar frontmatter para agentes que lo requieran (e.g. Cursor .mdc)
transform_file_frontmatter() {
    local source_file="$1"
    local agent="$2"
    local target_config="$3"

    # Obtener la plantilla de header del agente
    local header_template
    header_template=$(yq "${target_config}.header // \"\"" "${MANIFEST_FILE}")

    # Extraer nombre del archivo fuente (sin extensión ni path)
    local file_name
    file_name=$(basename "${source_file}" .md)

    # Generar nuevo frontmatter basado en la plantilla del agente
    local new_header
    new_header=$(awk -v name="${file_name}" -v ts="${TIMESTAMP}" '{
        gsub(/\{\{name\}\}/, name); gsub(/\{\{timestamp\}\}/, ts); print
    }' <<< "${header_template}")

    # Combinar: nuevo frontmatter + contenido sin frontmatter original
    printf '%s\n' "${new_header}"
    extract_content "${source_file}"
}

# Sincronización en formato merged (un archivo con todo el contenido)
sync_merged_impl() {
    local agent="$1"
    local target_type="$2"
    local source_type="$3"
    local target_config="$4"

    local strip_frontmatter
    strip_frontmatter=$(yq "${target_config}.strip_frontmatter // false" "${MANIFEST_FILE}")

    local header
    header=$(yq "${target_config}.header // \"\"" "${MANIFEST_FILE}" | \
        awk -v ts="${TIMESTAMP}" '{ gsub(/\{\{timestamp\}\}/, ts); print }')

    local output_filename
    output_filename=$(yq "${target_config}.output_filename // \"\"" "${MANIFEST_FILE}")

    # Generar contenido
    local content=""

    if [[ -n "${header}" && "${header}" != "null" ]]; then
        content="${header}"
    fi

    local first=true
    while IFS= read -r source_file; do
        [[ -z "${source_file}" ]] && continue

        if [[ "${first}" == "true" ]]; then
            first=false
        else
            content+=$'\n\n---\n\n'
        fi

        if [[ "${strip_frontmatter}" == "true" ]]; then
            content+=$(extract_content "${source_file}")
        else
            content+=$(cat "${source_file}")
        fi
    done < <(get_source_files "${source_type}")

    # Obtener paths de destino
    local target_paths
    target_paths=$(get_target_paths "${target_config}")

    while IFS= read -r target_path; do
        [[ -z "${target_path}" ]] && continue
        local final_path="${target_path}"

        if [[ -d "${target_path}" || "${target_path}" != *".md" ]]; then
            mkdir -p "${target_path}"
            if [[ -n "${output_filename}" && "${output_filename}" != "null" ]]; then
                final_path="${target_path}/${output_filename}"
            else
                final_path="${target_path}/rules.md"
            fi
        fi

        write_sync_file "${final_path}" "${content}"
    done <<< "${target_paths}"
}

# Sincronización en formato individual (un archivo por regla/workflow)
sync_individual_impl() {
    local agent="$1"
    local target_type="$2"
    local source_type="$3"
    local target_config="$4"

    local strip_frontmatter
    strip_frontmatter=$(yq "${target_config}.strip_frontmatter // false" "${MANIFEST_FILE}")

    local output_extension
    output_extension=$(yq "${target_config}.output_extension // \".md\"" "${MANIFEST_FILE}")

    local transform
    transform=$(yq "${target_config}.transform_frontmatter // false" "${MANIFEST_FILE}")

    # Obtener paths de destino
    local target_paths
    target_paths=$(get_target_paths "${target_config}")

    while IFS= read -r source_file; do
        [[ -z "${source_file}" ]] && continue

        # Derivar nombre de archivo de salida desde el fuente
        local base_name
        base_name=$(basename "${source_file}" .md)
        local file_content

        if [[ "${transform}" == "true" ]]; then
            file_content=$(transform_file_frontmatter "${source_file}" "${agent}" "${target_config}")
        elif [[ "${strip_frontmatter}" == "true" ]]; then
            file_content=$(extract_content "${source_file}")
        else
            file_content=$(cat "${source_file}")
        fi

        # Escribir a cada directorio destino
        while IFS= read -r target_path; do
            [[ -z "${target_path}" ]] && continue
            mkdir -p "${target_path}"
            local final_path="${target_path}/${base_name}${output_extension}"
            write_sync_file "${final_path}" "${file_content}"
        done <<< "${target_paths}"
    done < <(get_source_files "${source_type}")
}

# Dispatcher: elige merged o individual según configuración
sync_target() {
    local agent="$1"
    local target_type="$2"
    local source_type="$3"

    local target_config=".agents.${agent}.targets.${target_type}"

    # Verificar si existe la configuración
    if [[ $(yq "${target_config}" "${MANIFEST_FILE}") == "null" ]]; then
        log_debug "No hay configuración de ${target_type} para ${agent}"
        return 0
    fi

    local format
    format=$(yq "${target_config}.format // \"merged\"" "${MANIFEST_FILE}")

    case "${format}" in
        merged)
            sync_merged_impl "${agent}" "${target_type}" "${source_type}" "${target_config}"
            ;;
        individual)
            sync_individual_impl "${agent}" "${target_type}" "${source_type}" "${target_config}"
            ;;
        *)
            log_error "Formato desconocido '${format}' para ${agent}/${target_type}"
            return 1
            ;;
    esac
}
