#!/usr/bin/env bash
set -euo pipefail

# Script para sincronizar reglas de agent-rules a GitHub Copilot (IntelliJ)
# Uso: ./scripts/sync-copilot.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
COPILOT_DIR="${REPO_ROOT}/github-copilot"
TARGET_DIR="${HOME}/.config/github-copilot/intellij"

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

# Crear directorio destino si no existe
mkdir -p "${TARGET_DIR}"

# ============================================================================
# 1. Sincronizar global-copilot-instructions.md
# ============================================================================
log_info "Sincronizando global-copilot-instructions.md..."

if [[ -f "${COPILOT_DIR}/copilot-instructions.md" ]]; then
    cp "${COPILOT_DIR}/copilot-instructions.md" "${TARGET_DIR}/global-copilot-instructions.md"
    log_info "  → global-copilot-instructions.md actualizado"
else
    log_warn "  → copilot-instructions.md no encontrado"
fi

# ============================================================================
# 2. Sincronizar global-git-commit-instructions.md
# ============================================================================
log_info "Sincronizando global-git-commit-instructions.md..."

if [[ -f "${COPILOT_DIR}/git-commit-instructions.md" ]]; then
    cp "${COPILOT_DIR}/git-commit-instructions.md" "${TARGET_DIR}/global-git-commit-instructions.md"
    log_info "  → global-git-commit-instructions.md actualizado"
else
    log_warn "  → git-commit-instructions.md no encontrado"
fi

# ============================================================================
# 3. Consolidar instructions/*.instructions.md → Default.instructions.md
# ============================================================================
log_info "Consolidando instructions en Default.instructions.md..."

INSTRUCTIONS_DIR="${COPILOT_DIR}/instructions"
TARGET_INSTRUCTIONS="${TARGET_DIR}/Default.instructions.md"

# Orden de archivos de instrucciones
INSTRUCTION_FILES=(
    "terraform.instructions.md"
    "go.instructions.md"
    "python.instructions.md"
    "typescript.instructions.md"
    "bash.instructions.md"
    "docker.instructions.md"
    "kubernetes.instructions.md"
)

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
        file_path="${INSTRUCTIONS_DIR}/${instruction_file}"
        if [[ -f "${file_path}" ]]; then
            cat "${file_path}"
            echo ""
            echo "---"
            echo ""
        else
            log_warn "  → Archivo no encontrado: ${instruction_file}"
        fi
    done
} > "${TARGET_INSTRUCTIONS}"

log_info "  → Default.instructions.md actualizado (${#INSTRUCTION_FILES[@]} archivos)"

# ============================================================================
# 4. Consolidar prompts/*.prompt.md → default.prompt.md
# ============================================================================
log_info "Consolidando prompts en default.prompt.md..."

PROMPTS_DIR="${COPILOT_DIR}/prompts"
TARGET_PROMPTS="${TARGET_DIR}/default.prompt.md"

# Orden de archivos de prompts
PROMPT_FILES=(
    "validate.prompt.md"
    "review.prompt.md"
    "test.prompt.md"
    "refactor.prompt.md"
    "document.prompt.md"
    "security.prompt.md"
)

{
    echo "---"
    echo "description: 'Prompts reutilizables para tareas comunes'"
    echo "---"
    echo ""
    echo "<!-- Generado automáticamente por sync-copilot.sh -->"
    echo "<!-- Última actualización: $(date '+%Y-%m-%d %H:%M:%S') -->"
    echo ""
    
    for prompt_file in "${PROMPT_FILES[@]}"; do
        file_path="${PROMPTS_DIR}/${prompt_file}"
        if [[ -f "${file_path}" ]]; then
            cat "${file_path}"
            echo ""
            echo "---"
            echo ""
        else
            log_warn "  → Archivo no encontrado: ${prompt_file}"
        fi
    done
} > "${TARGET_PROMPTS}"

log_info "  → default.prompt.md actualizado (${#PROMPT_FILES[@]} archivos)"

# ============================================================================
# Resumen
# ============================================================================
echo ""
log_info "Sincronización completada:"
log_info "  Target: ${TARGET_DIR}"
log_info "  Archivos actualizados:"
log_info "    - global-copilot-instructions.md"
log_info "    - global-git-commit-instructions.md"
log_info "    - Default.instructions.md (consolidado)"
log_info "    - default.prompt.md (consolidado)"
