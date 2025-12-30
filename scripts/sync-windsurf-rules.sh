#!/usr/bin/env bash
set -euo pipefail

# Script para sincronizar reglas de agent-rules a Windsurf global_rules.md
# Uso: ./scripts/sync-windsurf-rules.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
RULES_DIR="${REPO_ROOT}/windsurf/rules"
TARGET_FILE="${HOME}/.codeium/windsurf/memories/global_rules.md"

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

# Verificar que existe el directorio de reglas
if [[ ! -d "${RULES_DIR}" ]]; then
    log_error "Directorio de reglas no encontrado: ${RULES_DIR}"
    exit 1
fi

# Crear directorio destino si no existe
mkdir -p "$(dirname "${TARGET_FILE}")"

# Orden de archivos (global primero, luego alfabético)
RULE_FILES=(
    "global.md"
    "aws.md"
    "bash.md"
    "docker.md"
    "documentation.md"
    "git.md"
    "go.md"
    "kubernetes.md"
    "nodejs.md"
    "python.md"
    "terraform.md"
)

# Función para extraer contenido sin frontmatter
extract_content() {
    local file="$1"
    # Elimina el frontmatter YAML (entre ---)
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
log_info "Generando archivo de reglas consolidado..."

{
    echo "---"
    echo "trigger: always"
    echo "---"
    echo ""
    echo "# Reglas de Desarrollo para Windsurf/Cascade"
    echo ""
    echo "<!-- Generado automáticamente por sync-windsurf-rules.sh -->"
    echo "<!-- Última actualización: $(date '+%Y-%m-%d %H:%M:%S') -->"
    echo ""
    
    for rule_file in "${RULE_FILES[@]}"; do
        file_path="${RULES_DIR}/${rule_file}"
        if [[ -f "${file_path}" ]]; then
            extract_content "${file_path}"
            echo ""
            echo "---"
            echo ""
        else
            log_warn "Archivo no encontrado: ${rule_file}"
        fi
    done
} > "${TARGET_FILE}"

log_info "Reglas sincronizadas exitosamente a: ${TARGET_FILE}"
log_info "Total de archivos procesados: ${#RULE_FILES[@]}"

# Mostrar tamaño del archivo generado
if command -v wc &> /dev/null; then
    LINES=$(wc -l < "${TARGET_FILE}")
    log_info "Líneas generadas: ${LINES}"
fi
