#!/usr/bin/env bash
# 066-anon-complex-setup: prepare complex JSON/INI fixtures for reproducing
#                         missing anonymization scenarios.
set -euo pipefail

: "${SMOKEY_STATE_DIR:?}"
: "${SMOKEY_TEST_DIR:?}"
: "${DEANNON_PS1:?}"


# Copy json and ini data to state dir
STATE_DIR="${SMOKEY_STATE_DIR}/anon-complex"
mkdir -p "$STATE_DIR"

shopt -s nullglob
copied=0
for src in "$SMOKEY_TEST_DIR"/*.ini "$SMOKEY_TEST_DIR"/*.json; do
    [[ -e "$src" ]] || continue
    cp "$src" "$STATE_DIR/"
    copied=1
done
shopt -u nullglob

# Prepare call to deannon.ps1
CONFIG_PATH="$STATE_DIR/config.ini"
INPUT_PATH="$STATE_DIR/input.json"
GENERATED_PATH="$STATE_DIR/generated.ini"
TENANT_PATH="$STATE_DIR/tenant.ini"


if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "Missing config.ini in $STATE_DIR" >&2
    exit 1
fi
if [[ ! -f "$INPUT_PATH" ]]; then
    echo "Missing input.json in $STATE_DIR" >&2
    exit 1
fi
cp "$INPUT_PATH" "${INPUT_PATH}.orig"

random_default_len=$(rg --no-filename --no-line-number --pcre2 '^randomize_default_length=(\d+)$' --replace '$1' "$CONFIG_PATH" || true)
if [[ -z "$random_default_len" ]]; then
    random_default_len=8
fi

pushd "$STATE_DIR" >/dev/null
pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" -File "$INPUT_PATH"
popd >/dev/null


# output result
echo annonimyzed input:
cat "$INPUT_PATH"

echo generated full entried
cat "$GENERATED_PATH"

# Assertions validating random
assert_file_matches "$INPUT_PATH" "SVC-[A-Za-z0-9]{${random_default_len}}"

# replacements in input file
assert_file_not_matches "$INPUT_PATH" 'svc-1001'
assert_file_not_matches "$INPUT_PATH" 'svc-1002'
assert_file_not_matches "$INPUT_PATH" 'svc-1003'
assert_file_not_matches "$INPUT_PATH" 'svc-1004'
assert_file_not_matches "$INPUT_PATH" 'svc-1005'
assert_file_matches "$INPUT_PATH" 'undisclosed-1\.domain' 1
assert_file_matches "$INPUT_PATH" 'undisclosed-2\.domain' 1
assert_file_matches "$INPUT_PATH" 'undisclosed-3\.domain' 1
assert_file_not_matches "$INPUT_PATH" 'undisclosed-4\.domain'
assert_file_matches "$INPUT_PATH" 'undisclosed-5\.domain' 1

# check wether general.ini hit
assert_file_matches "$INPUT_PATH" 'dom-[A-Za-z0-9]{10}' 1
