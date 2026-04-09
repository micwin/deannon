#!/usr/bin/env bash
# 025-disabled-sections: ensure disabled sections and unknown blocks persist.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${SMOKEY_STATE_DIR:?}"
: "${SMOKEY_TEST_DIR:?}"

STATE_DIR="${SMOKEY_STATE_DIR}/disabled"
mkdir -p "$STATE_DIR"
CONFIG_PATH="$STATE_DIR/config.ini"
INPUT_PATH="$STATE_DIR/input.txt"
EXPECTED_PATH="$STATE_DIR/expected.txt"

cp "$SMOKEY_TEST_DIR/config.ini" "$CONFIG_PATH"
cp "$SMOKEY_TEST_DIR/input.txt" "$INPUT_PATH"
cp "$SMOKEY_TEST_DIR/expected.txt" "$EXPECTED_PATH"

pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH"

if ! diff -u "$EXPECTED_PATH" "$INPUT_PATH"; then
    echo "Disabled-sections output mismatch" >&2
    exit 1
fi

if grep -q 'customer-disabled' "$INPUT_PATH"; then
    echo "Disabled full pair should not apply" >&2
    exit 1
fi

if grep -q 'TNT' "$INPUT_PATH"; then
    echo "Disabled hint should not generate replacements" >&2
    exit 1
fi

if ! grep -q '\[full.disabled\]' "$CONFIG_PATH"; then
    echo "Disabled full section missing after rewrite" >&2
    exit 1
fi

if ! grep -q 'disabled=true' "$CONFIG_PATH"; then
    echo "Disabled flag not preserved" >&2
    exit 1
fi

if ! grep -q '\[0full.legacy\]' "$CONFIG_PATH"; then
    echo "Unknown section [0full.legacy] was dropped" >&2
    exit 1
fi

echo "DISABLED_SECTIONS_OK=1"
