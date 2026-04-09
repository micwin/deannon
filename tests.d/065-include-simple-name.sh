#!/usr/bin/env bash
# 065-include-simple-name: include without explicit include_file should fall
# back to <name>.ini in the working directory.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${TESTDATA_DIR:?}"
: "${SMOKEY_STATE_DIR:?}"

INCLUDE_DIR="${SMOKEY_STATE_DIR}/include-simple"
mkdir -p "$INCLUDE_DIR"
CONFIG_PATH="$INCLUDE_DIR/include-simple-base.ini"
INC_FILE="$INCLUDE_DIR/tenant2.ini"
INPUT_PATH="$INCLUDE_DIR/include-simple-work.txt"
EXPECTED_PATH="$INCLUDE_DIR/include-simple-expected.txt"

cp "$TESTDATA_DIR/include-simple-base.ini" "$CONFIG_PATH"
cp "$TESTDATA_DIR/tenant2.ini" "$INC_FILE"
cp "$TESTDATA_DIR/include-simple-original.txt" "$INPUT_PATH"
cp "$TESTDATA_DIR/include-simple-expected.txt" "$EXPECTED_PATH"

if pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH"; then
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
