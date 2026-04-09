#!/usr/bin/env bash
# 060-include-support: ensure include directives with include_file work.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${SMOKEY_STATE_DIR:?}"
: "${SMOKEY_TEST_DIR:?}"

STATE_DIR="${SMOKEY_STATE_DIR}/include"
mkdir -p "$STATE_DIR"
CONFIG_PATH="$STATE_DIR/include-base.ini"
INC_PATH="$STATE_DIR/include-tenant1.ini"
INPUT_PATH="$STATE_DIR/include-work.txt"
EXPECTED_PATH="$STATE_DIR/include-expected.txt"

cp "$SMOKEY_TEST_DIR/include-base.ini" "$CONFIG_PATH"
cp "$SMOKEY_TEST_DIR/include-tenant1.ini" "$INC_PATH"
cp "$SMOKEY_TEST_DIR/include-original.txt" "$INPUT_PATH"
cp "$SMOKEY_TEST_DIR/include-expected.txt" "$EXPECTED_PATH"

if pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" -File "$INPUT_PATH"; then
    :
else
    echo "Include-enabled anonymization run failed" >&2
    exit 1
fi

if ! diff -u "$EXPECTED_PATH" "$INPUT_PATH"; then
    echo "Include handling missing: anonymized file mismatch" >&2
    exit 1
fi

echo "INCLUDE_OK=1"
