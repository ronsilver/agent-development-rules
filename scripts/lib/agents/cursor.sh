#!/usr/bin/env bash
# =============================================================================
# cursor.sh - Sincronización para Cursor IDE
# =============================================================================

# Sincronizar reglas a Cursor
sync_cursor() {
    local manifest="$1"
    local content_dir="$2"
    local dry_run="${3:-false}"
    local create_backup="${4:-false}"
    
    log_info "Sincronizando Cursor..."
    
    # Obtener configuración de rules
    local rules_path
    rules_path=$(yq '.agents.cursor.targets.rules.path' "$manifest")
    rules_path=$(expand_path "$rules_path")
    
    local rules_header
    rules_header=$(yq '.agents.cursor.targets.rules.header // ""' "$manifest")
    rules_header=$(echo "$rules_header" | sed "s/{{timestamp}}/$(get_timestamp)/g")
    
    # Generar contenido merged para rules
    local rules_content=""
    
    if [[ -n "$rules_header" && "$rules_header" != "null" ]]; then
        rules_content+="$rules_header"
    fi
    
    # Concatenar todos los archivos de reglas
    while IFS= read -r rule_file; do
        [[ -z "$rule_file" ]] && continue
        local full_path="${content_dir}/rules/${rule_file}"
        if [[ -f "$full_path" ]]; then
            rules_content+=$(extract_content "$full_path")
            rules_content+=$'\n\n---\n\n'
            log_debug "  Agregado: rules/${rule_file}"
        fi
    done < <(yq '.rules.files[]' "$manifest" 2>/dev/null)
    
    # Backup si está habilitado
    if [[ "$create_backup" == "true" ]]; then
        backup_file "$rules_path"
    fi
    
    # Escribir archivo de rules
    write_file "$rules_path" "$rules_content" "$dry_run"
    
    log_success "Cursor sincronizado"
}
