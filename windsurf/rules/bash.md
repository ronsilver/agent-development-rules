---
trigger: glob
globs: ["*.sh"]
---

# Bash Best Practices

## Header Obligatorio

```bash
#!/usr/bin/env bash
set -euo pipefail
```

| Flag | Efecto |
|------|--------|
| `-e` | Exit inmediato si un comando falla |
| `-u` | Error si se usa variable no definida |
| `-o pipefail` | Pipe falla si cualquier comando falla |

## Variables

### Siempre con Comillas Dobles
```bash
# ✅ Correcto
echo "${variable}"
cp "${source}" "${destination}"

# ❌ Incorrecto - puede romper con espacios
echo $variable
cp $source $destination
```

### Naming Convention
```bash
# Variables locales: snake_case
local file_path="/tmp/data.txt"
local user_count=0

# Constantes: UPPERCASE
readonly MAX_RETRIES=3
readonly CONFIG_DIR="/etc/myapp"

# Variables de entorno exportadas
export DATABASE_URL="postgres://..."
```

### Valores por Defecto y Validación
```bash
# Valor por defecto
name="${1:-default_value}"

# Requerido (falla si no existe)
required_arg="${1:?Error: primer argumento requerido}"

# Valor si está vacío
result="${value:-fallback}"

# Usar default solo si no está definido
: "${CONFIG_FILE:=/etc/app/config.yaml}"
```

## Condicionales

### Usar `[[ ]]` (no `[ ]`)
```bash
# ✅ Correcto
if [[ -f "${file}" ]]; then
    echo "File exists"
fi

if [[ "${status}" == "active" ]]; then
    echo "Active"
fi

# Operadores lógicos
if [[ -n "${var}" && "${count}" -gt 0 ]]; then
    echo "Valid"
fi

# Pattern matching
if [[ "${filename}" == *.log ]]; then
    echo "Log file"
fi
```

### Operadores Comunes
| Operador | Descripción |
|----------|-------------|
| `-f` | Es archivo regular |
| `-d` | Es directorio |
| `-e` | Existe |
| `-r` | Es legible |
| `-w` | Es escribible |
| `-x` | Es ejecutable |
| `-z` | String vacío |
| `-n` | String no vacío |
| `==` | Igualdad de strings |
| `=~` | Regex match |
| `-eq`, `-ne`, `-gt`, `-lt`, `-ge`, `-le` | Comparación numérica |

## Funciones

```bash
function process_file() {
    local file="${1:?Error: file argument required}"
    local output_dir="${2:-./output}"

    # Validación
    if [[ ! -f "${file}" ]]; then
        log_error "File not found: ${file}"
        return 1
    fi

    # Crear directorio si no existe
    mkdir -p "${output_dir}"

    # Procesar...
    log_info "Processing ${file}"
}

# Llamar función
process_file "data.txt" "./results" || exit 1
```

## Error Handling y Cleanup

```bash
# Cleanup automático al salir (EXIT, ERR, INT, TERM)
trap cleanup EXIT

function cleanup() {
    local exit_code=$?
    rm -f "${TEMP_FILE:-}"
    rm -rf "${TEMP_DIR:-}"
    exit "${exit_code}"
}

# Archivo temporal seguro
TEMP_FILE="$(mktemp)"
TEMP_DIR="$(mktemp -d)"
```

## Loops

```bash
# Iterar archivos (seguro con espacios)
for file in *.txt; do
    [[ -f "${file}" ]] || continue
    process "${file}"
done

# Leer líneas de archivo
while IFS= read -r line; do
    echo "${line}"
done < "${input_file}"

# Iterar con índice
for i in "${!array[@]}"; do
    echo "Index ${i}: ${array[i]}"
done
```

## Verificar Dependencias

```bash
function check_dependencies() {
    local deps=("jq" "curl" "aws")
    local missing=()
    
    for cmd in "${deps[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            missing+=("${cmd}")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}
```

## Logging con Colores

```bash
# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'  # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
```

## Argument Parsing

```bash
function usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <file>

Options:
    -h, --help      Show this help
    -v, --verbose   Verbose output
    -o, --output    Output directory
EOF
}

VERBOSE=false
OUTPUT_DIR="./output"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="${2:?Error: --output requires argument}"
            shift 2
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done
```

## Validación

```bash
shellcheck script.sh
```

## Anti-Patrones

| Anti-Patrón | Solución |
|-------------|----------|
| Variables sin comillas | Siempre usar `"${var}"` |
| `[ ]` para condicionales | Usar `[[ ]]` |
| Parsear ls output | Usar globs directamente |
| `cat file \| grep` | `grep pattern file` |
| Sin `set -euo pipefail` | Siempre incluir en header |
