#!/usr/bin/env bash
# 065-include-simple-name: include directives without include_file fallback to
# <name>.ini in the config directory.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${SMOKEY_STATE_DIR:?}"
: "${SMOKEY_TEST_DIR:?}"

STATE_DIR="${SMOKEY_STATE_DIR}/include-simple"
mkdir -p "$STATE_DIR"
CONFIG_PATH="$STATE_DIR/include-simple-base.ini"
INC_PATH="$STATE_DIR/tenant2.ini"
INPUT_PATH="$STATE_DIR/include-simple-work.txt"
EXPECTED_PATH="$STATE_DIR/include-simple-expected.txt"

cp "$SMOKEY_TEST_DIR/include-simple-base.ini" "$CONFIG_PATH"
cp "$SMOKEY_TEST_DIR/tenant2.ini" "$INC_PATH"
cp "$SMOKEY_TEST_DIR/include-simple-original.txt" "$INPUT_PATH"
cp "$SMOKEY_TEST_DIR/include-simple-expected.txt" "$EXPECTED_PATH"

if pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" -File "$INPUT_PATH"; then
    :
else
    echo "Include (simple) anonymization run failed" >&2
    exit 1
fi

if ! diff -u "$EXPECTED_PATH" "$INPUT_PATH"; then
    echo "Simple include handling missing: anonymized file mismatch" >&2
    exit 1
fi

echo "INCLUDE_SIMPLE_OK=1"
