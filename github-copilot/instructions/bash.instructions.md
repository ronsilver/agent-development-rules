# Bash Instructions

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
```

### Operadores Comunes
| Operador | Descripción |
|----------|-------------|
| `-f` | Es archivo regular |
| `-d` | Es directorio |
| `-e` | Existe |
| `-z` | String vacío |
| `-n` | String no vacío |
| `==` | Igualdad de strings |
| `-eq`, `-ne`, `-gt`, `-lt` | Comparación numérica |

## Funciones

```bash
function process_file() {
    local file="${1:?Error: file argument required}"
    local output_dir="${2:-./output}"

    # Validación
    if [[ ! -f "${file}" ]]; then
        echo "Error: File not found: ${file}" >&2
        return 1
    fi

    # Crear directorio si no existe
    mkdir -p "${output_dir}"

    # Procesar...
    echo "Processing ${file}"
}
```

## Error Handling y Cleanup

```bash
# Cleanup automático al salir
trap cleanup EXIT

function cleanup() {
    rm -f "${temp_file:-}"
    echo "Cleanup completed" >&2
}

# Archivo temporal seguro
temp_file="$(mktemp)"
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
```

## Verificar Dependencias

```bash
function check_dependencies() {
    local deps=("jq" "curl" "aws")
    for cmd in "${deps[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            echo "Error: ${cmd} is required" >&2
            exit 1
        fi
    done
}
```

## Logging

```bash
# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
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
