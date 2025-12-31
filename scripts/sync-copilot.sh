#!/usr/bin/env bash
set -euo pipefail

# Script para sincronizar reglas de agent-rules a GitHub Copilot (IntelliJ)
# Uso: ./scripts/sync-copilot.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
COPILOT_DIR="${REPO_ROOT}/github-copilot"
# Directorios destino fijos
TARGET_DIRS=(
  "${HOME}/.config/github-copilot/intellij"
  "${HOME}/Library/Application Support/Code/User/prompts"
)

# Directorios con glob pattern (se expanden en tiempo de ejecución)
TARGET_GLOB_PATTERNS=(
  "${HOME}/.vscode/extensions/github.copilot-chat-*/assets/prompts"
)

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Verificar que existe el directorio fuente
if [[ ! -d "${COPILOT_DIR}" ]]; then
    log_error "Directorio de GitHub Copilot no encontrado: ${COPILOT_DIR}"
    exit 1
fi

# ============================================================================
# Definir archivos de instrucciones y prompts
# ============================================================================
INSTRUCTIONS_DIR="${COPILOT_DIR}/instructions"
PROMPTS_DIR="${COPILOT_DIR}/prompts"

INSTRUCTION_FILES=(
    "terraform.instructions.md"
    "go.instructions.md"
    "python.instructions.md"
    "typescript.instructions.md"
    "bash.instructions.md"
    "docker.instructions.md"
    "kubernetes.instructions.md"
)

PROMPT_FILES=(
    "validate.prompt.md"
    "review.prompt.md"
    "test.prompt.md"
    "refactor.prompt.md"
    "document.prompt.md"
    "security.prompt.md"
)

# ============================================================================
# Función para sincronizar a un directorio destino
# ============================================================================
sync_to_target() {
    local target_dir="$1"
    
    mkdir -p "${target_dir}"
    
    # Copiar global-copilot-instructions.md
    if [[ -f "${COPILOT_DIR}/copilot-instructions.md" ]]; then
        cp "${COPILOT_DIR}/copilot-instructions.md" "${target_dir}/global-copilot-instructions.md"
    fi
    
    # Copiar global-git-commit-instructions.md
    if [[ -f "${COPILOT_DIR}/git-commit-instructions.md" ]]; then
        cp "${COPILOT_DIR}/git-commit-instructions.md" "${target_dir}/global-git-commit-instructions.md"
    fi
    
    # Generar Default.instructions.md
    {
        echo "---"
        echo "applyTo: '**'"
        echo "description: 'Instrucciones globales de desarrollo'"
        echo "---"
        echo ""
        echo "<!-- Generado automáticamente por sync-copilot.sh -->"
        echo "<!-- Última actualización: $(date '+%Y-%m-%d %H:%M:%S') -->"
        echo ""
        
        for instruction_file in "${INSTRUCTION_FILES[@]}"; do
            local file_path="${INSTRUCTIONS_DIR}/${instruction_file}"
            if [[ -f "${file_path}" ]]; then
                cat "${file_path}"
                echo ""
                echo "---"
                echo ""
            fi
        done
    } > "${target_dir}/Default.instructions.md"
    
    # Generar default.prompt.md
    {
        echo "---"
        echo "description: 'Prompts reutilizables para tareas comunes'"
        echo "---"
        echo ""
        echo "<!-- Generado automáticamente por sync-copilot.sh -->"
        echo "<!-- Última actualización: $(date '+%Y-%m-%d %H:%M:%S') -->"
        echo ""
        
        for prompt_file in "${PROMPT_FILES[@]}"; do
            local file_path="${PROMPTS_DIR}/${prompt_file}"
            if [[ -f "${file_path}" ]]; then
                cat "${file_path}"
                echo ""
                echo "---"
                echo ""
            fi
        done
    } > "${target_dir}/default.prompt.md"
    
    log_info "  → Sincronizado: ${target_dir}"
}

# ============================================================================
# 1. Sincronizar a directorios fijos
# ============================================================================
log_info "Sincronizando a directorios fijos..."

for target_dir in "${TARGET_DIRS[@]}"; do
    sync_to_target "${target_dir}"
done

# ============================================================================
# 2. Sincronizar a directorios con glob patterns
# ============================================================================
log_info "Sincronizando a directorios con glob patterns..."

for pattern in "${TARGET_GLOB_PATTERNS[@]}"; do
    shopt -s nullglob
    expanded_dirs=($pattern)
    shopt -u nullglob
    
    if [[ ${#expanded_dirs[@]} -eq 0 ]]; then
        log_warn "  → No se encontraron directorios para: ${pattern}"
        continue
    fi
    
    for target_dir in "${expanded_dirs[@]}"; do
        sync_to_target "${target_dir}"
    done
done

# ============================================================================
# Resumen
# ============================================================================
echo ""
log_info "Sincronización completada"
log_info "Archivos generados por destino:"
log_info "  - global-copilot-instructions.md"
log_info "  - global-git-commit-instructions.md"
log_info "  - Default.instructions.md (consolidado)"
log_info "  - default.prompt.md (consolidado)"
