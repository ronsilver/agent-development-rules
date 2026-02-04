#!/usr/bin/env bash
# =============================================================================
# windsurf.sh - Sincronización para Windsurf IDE
# =============================================================================

# Sincronizar reglas y workflows a Windsurf
sync_windsurf() {
    local manifest="$1"
    local content_dir="$2"
    local dry_run="${3:-false}"
    local create_backup="${4:-false}"
    
    log_info "Sincronizando Windsurf..."
    
    # Obtener configuración de rules
    local rules_path
    rules_path=$(yq '.agents.windsurf.targets.rules.path' "$manifest")
    rules_path=$(expand_path "$rules_path")
    
    local rules_header
    rules_header=$(yq '.agents.windsurf.targets.rules.header // ""' "$manifest")
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
        else
            log_warn "Archivo no encontrado: rules/${rule_file}"
        fi
    done < <(yq '.rules.files[]' "$manifest" 2>/dev/null)
    
    # Backup si está habilitado
    if [[ "$create_backup" == "true" ]]; then
        backup_file "$rules_path"
    fi
    
    # Escribir archivo de rules
    write_file "$rules_path" "$rules_content" "$dry_run"
    
    # --- Workflows ---
    local workflows_path
    workflows_path=$(yq '.agents.windsurf.targets.workflows.path // ""' "$manifest")
    
    if [[ -n "$workflows_path" && "$workflows_path" != "null" ]]; then
        workflows_path=$(expand_path "$workflows_path")
        
        local workflows_header
        workflows_header=$(yq '.agents.windsurf.targets.workflows.header // ""' "$manifest")
        workflows_header=$(echo "$workflows_header" | sed "s/{{timestamp}}/$(get_timestamp)/g")
        
        local workflows_content=""
        
        if [[ -n "$workflows_header" && "$workflows_header" != "null" ]]; then
            workflows_content+="$workflows_header"
        fi
        
        # Concatenar workflows
        while IFS= read -r workflow_file; do
            [[ -z "$workflow_file" ]] && continue
            local full_path="${content_dir}/workflows/${workflow_file}"
            if [[ -f "$full_path" ]]; then
                workflows_content+=$(extract_content "$full_path")
                workflows_content+=$'\n\n---\n\n'
                log_debug "  Agregado: workflows/${workflow_file}"
            else
                log_warn "Archivo no encontrado: workflows/${workflow_file}"
            fi
        done < <(yq '.workflows.files[]' "$manifest" 2>/dev/null)
        
        if [[ "$create_backup" == "true" ]]; then
            backup_file "$workflows_path"
        fi
        
        write_file "$workflows_path" "$workflows_content" "$dry_run"
    fi
    
    log_success "Windsurf sincronizado"
}
