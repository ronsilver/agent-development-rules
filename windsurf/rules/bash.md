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

- `set -e` - Exit on error
- `set -u` - Error on undefined variables
- `set -o pipefail` - Pipe fails if any command fails

## Variables

### Siempre con Comillas
```bash
echo "${variable}"
cp "${source}" "${destination}"
```

### Naming
- Locales: `lowercase_snake_case`
- Constantes: `UPPERCASE_SNAKE_CASE`

```bash
local file_path="/tmp/data.txt"
readonly MAX_RETRIES=3
```

### Defaults
```bash
name="${1:-default}"
required="${1:?Error: argument required}"
```

## Condicionales

Usar `[[ ]]`:
```bash
if [[ -f "${file}" ]]; then
    echo "File exists"
fi

if [[ "${status}" == "active" ]]; then
    echo "Active"
fi
```

## Funciones

```bash
function process_file() {
    local file="${1:?Error: file required}"
    
    if [[ ! -f "${file}" ]]; then
        echo "Error: File not found" >&2
        return 1
    fi
    
    # process...
}
```

## Loops

```bash
for file in *.txt; do
    [[ -f "${file}" ]] || continue
    process "${file}"
done

while IFS= read -r line; do
    echo "${line}"
done < "${input_file}"
```

## Error Handling

```bash
trap cleanup EXIT

function cleanup() {
    rm -f "${temp_file:-}"
}
```

## Verificar Comandos

```bash
if ! command -v jq &> /dev/null; then
    echo "Error: jq required" >&2
    exit 1
fi
```
