#!/usr/bin/env bash
set -euo pipefail

# Script para sincronizar workflows de agent-rules a Windsurf global_workflows
# Uso: ./scripts/sync-windsurf-workflows.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
WORKFLOWS_DIR="${REPO_ROOT}/windsurf/workflows"
TARGET_FILE="${HOME}/.codeium/global_workflows/default.md"

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

# Verificar que existe el directorio de workflows
if [[ ! -d "${WORKFLOWS_DIR}" ]]; then
    log_error "Directorio de workflows no encontrado: ${WORKFLOWS_DIR}"
    exit 1
fi

# Crear directorio destino si no existe
mkdir -p "$(dirname "${TARGET_FILE}")"

# Orden de archivos de workflows
WORKFLOW_FILES=(
    "validate.md"
    "test.md"
    "lint.md"
    "pre-push.md"
    "pr-review.md"
    "fix-pr-comments.md"
    "terraform-module.md"
    "docker-build.md"
    "k8s-validate.md"
    "security-check.md"
)

# Función para extraer contenido sin frontmatter
extract_content() {
    local file="$1"
    awk '
        BEGIN { in_frontmatter=0; found_end=0 }
        /^---$/ && !found_end { 
            if (in_frontmatter) { found_end=1; next }
            in_frontmatter=1
            next
        }
        found_end { print }
    ' "${file}"
}

# Generar contenido consolidado
log_info "Generando archivo de workflows consolidado..."

{
    echo "---"
    echo "name: global-workflows"
    echo "description: Workflows globales para Windsurf"
    echo "---"
    echo ""
    echo "# Workflows Globales"
    echo ""
    echo "<!-- Generado automáticamente por sync-windsurf-workflows.sh -->"
    echo "<!-- Última actualización: $(date '+%Y-%m-%d %H:%M:%S') -->"
    echo ""
    
    for workflow_file in "${WORKFLOW_FILES[@]}"; do
        file_path="${WORKFLOWS_DIR}/${workflow_file}"
        if [[ -f "${file_path}" ]]; then
            extract_content "${file_path}"
            echo ""
            echo "---"
            echo ""
        else
            log_warn "Archivo no encontrado: ${workflow_file}"
        fi
    done
} > "${TARGET_FILE}"

log_info "Workflows sincronizados exitosamente a: ${TARGET_FILE}"
log_info "Total de archivos procesados: ${#WORKFLOW_FILES[@]}"

# Mostrar tamaño del archivo generado
if command -v wc &> /dev/null; then
    LINES=$(wc -l < "${TARGET_FILE}")
    log_info "Líneas generadas: ${LINES}"
fi
