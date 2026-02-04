#!/usr/bin/env bash
# =============================================================================
# copilot.sh - Sincronización para GitHub Copilot
# =============================================================================

# Sincronizar reglas y prompts a GitHub Copilot
sync_copilot() {
    local manifest="$1"
    local content_dir="$2"
    local dry_run="${3:-false}"
    local create_backup="${4:-false}"
    
    log_info "Sincronizando GitHub Copilot..."
    
    # Obtener configuración de rules
    local rules_header
    rules_header=$(yq '.agents.github-copilot.targets.rules.header // ""' "$manifest")
    rules_header=$(echo "$rules_header" | sed "s/{{timestamp}}/$(get_timestamp)/g")
    
    local output_filename
    output_filename=$(yq '.agents.github-copilot.targets.rules.output_filename // "Default.instructions.md"' "$manifest")
    
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
    
    # Obtener paths de destino
    local paths=()
    
    # Paths estáticos
    while IFS= read -r p; do
        [[ -z "$p" || "$p" == "null" ]] && continue
        paths+=("$(expand_path "$p")")
    done < <(yq '.agents.github-copilot.targets.rules.paths[]?' "$manifest" 2>/dev/null)
    
    # Glob paths (para extensiones de VS Code)
    while IFS= read -r pattern; do
        [[ -z "$pattern" || "$pattern" == "null" ]] && continue
        local expanded_pattern
        expanded_pattern=$(expand_path "$pattern")
        shopt -s nullglob
        for expanded_dir in $expanded_pattern; do
            if [[ -d "$expanded_dir" ]]; then
                paths+=("$expanded_dir")
            fi
        done
        shopt -u nullglob
    done < <(yq '.agents.github-copilot.targets.rules.glob_paths[]?' "$manifest" 2>/dev/null)
    
    # Escribir a cada destino
    for target_path in "${paths[@]}"; do
        local final_path="${target_path}/${output_filename}"
        
        if [[ "$create_backup" == "true" ]]; then
            backup_file "$final_path"
        fi
        
        write_file "$final_path" "$rules_content" "$dry_run"
    done
    
    # --- Prompts ---
    local prompts_output
    prompts_output=$(yq '.agents.github-copilot.targets.prompts.output_filename // "default.prompt.md"' "$manifest")
    
    local prompts_header
    prompts_header=$(yq '.agents.github-copilot.targets.prompts.header // ""' "$manifest")
    prompts_header=$(echo "$prompts_header" | sed "s/{{timestamp}}/$(get_timestamp)/g")
    
    local prompts_content=""
    
    if [[ -n "$prompts_header" && "$prompts_header" != "null" ]]; then
        prompts_content+="$prompts_header"
    fi
    
    # Concatenar prompts
    while IFS= read -r prompt_file; do
        [[ -z "$prompt_file" ]] && continue
        local full_path="${content_dir}/prompts/${prompt_file}"
        if [[ -f "$full_path" ]]; then
            prompts_content+=$(extract_content "$full_path")
            prompts_content+=$'\n\n---\n\n'
            log_debug "  Agregado: prompts/${prompt_file}"
        fi
    done < <(yq '.prompts.files[]' "$manifest" 2>/dev/null)
    
    # Obtener paths para prompts
    local prompt_paths=()
    while IFS= read -r p; do
        [[ -z "$p" || "$p" == "null" ]] && continue
        prompt_paths+=("$(expand_path "$p")")
    done < <(yq '.agents.github-copilot.targets.prompts.paths[]?' "$manifest" 2>/dev/null)
    
    for target_path in "${prompt_paths[@]}"; do
        local final_path="${target_path}/${prompts_output}"
        
        if [[ "$create_backup" == "true" ]]; then
            backup_file "$final_path"
        fi
        
        write_file "$final_path" "$prompts_content" "$dry_run"
    done
    
    log_success "GitHub Copilot sincronizado"
}
