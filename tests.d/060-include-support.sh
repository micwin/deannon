#!/usr/bin/env bash
# 060-include-support: ensure include directives are honored.
# The base config relies on include-tenant1.ini for its only full pair; without
# include support anonymization should fail.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${TESTDATA_DIR:?}"
: "${SMOKEY_STATE_DIR:?}"

INCLUDE_DIR="${SMOKEY_STATE_DIR}/include"
mkdir -p "$INCLUDE_DIR"
CONFIG_PATH="$INCLUDE_DIR/include-base.ini"
INC_FILE="$INCLUDE_DIR/include-tenant1.ini"
INPUT_PATH="$INCLUDE_DIR/include-work.txt"
EXPECTED_PATH="$INCLUDE_DIR/include-expected.txt"

cp "$TESTDATA_DIR/include-base.ini" "$CONFIG_PATH"
cp "$TESTDATA_DIR/include-tenant1.ini" "$INC_FILE"
cp "$TESTDATA_DIR/include-original.txt" "$INPUT_PATH"
cp "$TESTDATA_DIR/include-expected.txt" "$EXPECTED_PATH"

if pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH"; then
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
