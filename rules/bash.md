---
trigger: glob
globs: ["*.sh"]
---

# Bash Best Practices

## Mandatory Header - NO EXCEPTIONS

Every script MUST start with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

If a script does not have this, it is **REJECTED**.

## Variables

### Always Quote Variables
```bash
# ✅ Correct
echo "${variable}"
cp "${source}" "${destination}"

# ❌ Incorrect - breaks on spaces
echo $variable
cp $source $destination
```

### Naming Convention
- **Locals**: `snake_case`
- **Constants**: `UPPER_CASE`
- **Environment**: `UPPER_CASE` (Values exported)

## Conditionals

### Use `[[ ]]` (not `[ ]`)
```bash
# ✅ Correct
if [[ -f "${file}" ]]; then
    echo "File exists"
fi
```

## Error Handling & Cleanup

Use `trap` for cleanup.

```bash
trap cleanup EXIT

function cleanup() {
    rm -f "${TEMP_FILE}"
}
```

## Mandatory Verification

Before any commit or PR, you **MUST** run:
```bash
shfmt -l -d *.sh        # Format check
shellcheck *.sh          # Linting
```

## Formatting with shfmt

**shfmt** formats bash scripts according to the Google Shell Style Guide.

### Installation
```bash
# macOS
brew install shfmt

# Linux
GO111MODULE=on go install mvdan.cc/sh/v3/cmd/shfmt@latest

# Docker
docker run --rm -v $(pwd):/mnt -w /mnt mvdan/shfmt:latest
```

### Usage

```bash
# Check format (show diff, exit 1 if changes needed)
shfmt -l -d script.sh

# Format in-place
shfmt -w script.sh

# Format all shell scripts recursively
shfmt -w .

# With specific options (Google Shell Style)
shfmt -w -i 2 -ci -bn script.sh
```

### Options
- `-i 2`: Indent with 2 spaces
- `-ci`: Indent switch cases
- `-bn`: Binary ops like `&&` and `|` may start a line
- `-l`: List files that would be formatted
- `-d`: Show diff instead of rewriting
- `-w`: Write result to file

### Configuration - `.editorconfig`
```ini
[*.sh]
shell_variant = bash
indent_style = space
indent_size = 2
binary_next_line = true
switch_case_indent = true
```

## Linting with ShellCheck

ShellCheck detects bugs and issues in shell scripts.

### Usage

```bash
# Basic linting
shellcheck script.sh

# Multiple files
shellcheck *.sh

# Specify shell dialect
shellcheck -s bash script.sh

# Format output
shellcheck -f json script.sh
shellcheck -f gcc script.sh  # For CI/CD

# Ignore specific warnings
shellcheck -e SC2034,SC2086 script.sh
```

### Configuration - `.shellcheckrc`

```bash
# .shellcheckrc

# Enable all optional checks
enable=all

# Ignore specific checks
disable=SC2034  # Unused variables (false positives)

# Specify shell dialect
shell=bash
```

### Common ShellCheck Warnings

**SC2086**: Unquoted variable
```bash
# ❌ Bad
rm $file

# ✅ Good
rm "${file}"
```

**SC2046**: Quote expansion
```bash
# ❌ Bad
for file in $(ls *.txt); do

# ✅ Good
for file in *.txt; do
```

**SC2164**: Use `cd ... || exit`
```bash
# ❌ Bad
cd /path/to/dir
do_something

# ✅ Good
cd /path/to/dir || exit
do_something
```

## Anti-Patterns
- Using `[ ]` instead of `[[ ]]`.
- Parsing `ls` output (use globs).
- `cat file | grep` (use `grep pattern file`).
- Missing `set -euo pipefail`.
- Unquoted variables.
- Not checking `cd` return status.
