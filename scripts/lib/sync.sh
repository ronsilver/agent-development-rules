#!/usr/bin/env bash
# =============================================================================
# sync.sh (library) - Funciones de sincronización para agent-development-rules
# This file is meant to be sourced by scripts/sync.sh, not executed directly.
# =============================================================================
# Requires: common.sh sourced first, and the following globals:
#   MANIFEST_FILE, CONTENT_DIR, DRY_RUN, CREATE_BACKUP, TIMESTAMP
# =============================================================================

# =============================================================================
# Sync Registry — tracks managed files to detect and remove stale remnants
# =============================================================================

SYNC_REGISTRY_DIR="${HOME}/.config/agent-development-rules"
SYNC_REGISTRY="${SYNC_REGISTRY_DIR}/.sync-registry"
_SYNC_REGISTRY_NEW=""

init_sync_registry() {
    mkdir -p "${SYNC_REGISTRY_DIR}"
    _SYNC_REGISTRY_NEW=$(mktemp)
    log_debug "Registry initialized: ${_SYNC_REGISTRY_NEW}"
}

register_managed_file() {
    local file_path="$1"
    [[ -z "${_SYNC_REGISTRY_NEW}" ]] && return 0
    echo "${file_path}" >> "${_SYNC_REGISTRY_NEW}"
}

cleanup_stale_files() {
    [[ ! -f "${SYNC_REGISTRY}" ]] && return 0
    [[ -z "${_SYNC_REGISTRY_NEW}" ]] && return 0

    local stale_count=0

    while IFS= read -r old_file; do
        [[ -z "${old_file}" ]] && continue
        [[ ! -f "${old_file}" ]] && continue

        if ! grep -qxF "${old_file}" "${_SYNC_REGISTRY_NEW}"; then
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[DRY-RUN] Eliminaría stale: ${old_file}"
            else
                if [[ "${CREATE_BACKUP}" == "true" ]]; then
                    backup_file "${old_file}"
                fi
                rm -f "${old_file}"
                log_warn "  ✗ Stale eliminado: ${old_file}"
            fi
            stale_count=$((stale_count + 1))
        fi
    done < "${SYNC_REGISTRY}"

    if [[ ${stale_count} -gt 0 ]]; then
        log_info "Cleanup: ${stale_count} archivo(s) stale eliminado(s)"
    else
        log_debug "Cleanup: sin archivos stale"
    fi
}

save_sync_registry() {
    [[ -z "${_SYNC_REGISTRY_NEW}" ]] && return 0

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_debug "[DRY-RUN] Registry no guardado"
        rm -f "${_SYNC_REGISTRY_NEW}"
        return 0
    fi

    sort -u "${_SYNC_REGISTRY_NEW}" > "${SYNC_REGISTRY}"
    rm -f "${_SYNC_REGISTRY_NEW}"
    log_debug "Registry guardado: ${SYNC_REGISTRY} ($(wc -l < "${SYNC_REGISTRY}") archivos)"
}

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

# Obtener lista de directorios de skills
get_source_skill_dirs() {
    local source_dir
    source_dir=$(yq '.skills.source_dir // "skills"' "${MANIFEST_FILE}")

    while IFS= read -r dir_name; do
        [[ -z "${dir_name}" ]] && continue
        local full_path="${CONTENT_DIR}/${source_dir}/${dir_name}"
        if [[ -d "${full_path}" ]]; then
            echo "${full_path}"
        else
            log_warn "Directorio de skill no encontrado: ${full_path}"
        fi
    done < <(yq '.skills.directories[]' "${MANIFEST_FILE}" 2>/dev/null)
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

    register_managed_file "${final_path}"
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

# Sincronización en formato directory (copiar directorios completos de skills)
sync_directory_impl() {
    local agent="$1"
    local target_type="$2"
    local source_type="$3"
    local target_config="$4"

    # Obtener paths de destino
    local target_paths
    target_paths=$(get_target_paths "${target_config}")

    while IFS= read -r source_dir; do
        [[ -z "${source_dir}" ]] && continue

        local skill_name
        skill_name=$(basename "${source_dir}")

        # Verificar que SKILL.md existe en el directorio fuente
        if [[ ! -f "${source_dir}/SKILL.md" ]]; then
            log_warn "SKILL.md no encontrado en: ${source_dir} — saltando"
            continue
        fi

        # Copiar a cada directorio destino
        while IFS= read -r target_path; do
            [[ -z "${target_path}" ]] && continue
            local dest_dir="${target_path}/${skill_name}"

            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[DRY-RUN] Copiaría directorio: ${source_dir} → ${dest_dir}"
                continue
            fi

            # Crear destino y copiar recursivamente
            mkdir -p "${dest_dir}"

            # Sincronizar archivos del skill preservando estructura
            local changed=false
            while IFS= read -r src_file; do
                local rel_path="${src_file#"${source_dir}"/}"
                local dest_file="${dest_dir}/${rel_path}"
                local dest_file_dir
                dest_file_dir=$(dirname "${dest_file}")

                # Comparar checksums para detectar cambios
                if [[ -f "${dest_file}" ]]; then
                    local src_hash dest_hash
                    src_hash=$(shasum -a 256 "${src_file}" | cut -d' ' -f1)
                    dest_hash=$(shasum -a 256 "${dest_file}" | cut -d' ' -f1)
                    if [[ "${src_hash}" == "${dest_hash}" ]]; then
                        log_debug "  Sin cambios: ${dest_file}"
                        continue
                    fi
                fi

                changed=true

                if [[ "${CREATE_BACKUP}" == "true" ]]; then
                    backup_file "${dest_file}"
                fi

                mkdir -p "${dest_file_dir}"
                cp "${src_file}" "${dest_file}"
                log_debug "  → ${dest_file}"
                register_managed_file "${dest_file}"
            done < <(find "${source_dir}" -type f 2>/dev/null)

            if [[ "${changed}" != "true" ]]; then
                log_debug "  Sin cambios: ${dest_dir}/"
                # Register existing files even if unchanged
                while IFS= read -r existing_file; do
                    register_managed_file "${existing_file}"
                done < <(find "${dest_dir}" -type f 2>/dev/null)
            else
                log_info "  → ${dest_dir}/"
            fi
        done <<< "${target_paths}"
    done < <(get_source_skill_dirs)
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
        directory)
            sync_directory_impl "${agent}" "${target_type}" "${source_type}" "${target_config}"
            ;;
        *)
            log_error "Formato desconocido '${format}' para ${agent}/${target_type}"
            return 1
            ;;
    esac
}
