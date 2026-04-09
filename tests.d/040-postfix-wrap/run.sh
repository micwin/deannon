#!/usr/bin/env bash
# 040-postfix-wrap: ensure full pairs with embedded wrappers work as-is.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${SMOKEY_STATE_DIR:?}"
: "${SMOKEY_TEST_DIR:?}"

STATE_DIR="${SMOKEY_STATE_DIR}/postfix"
mkdir -p "$STATE_DIR"
CONFIG_PATH="$STATE_DIR/postfix-config.ini"
INPUT_PATH="$STATE_DIR/postfix-input.txt"

cp "$SMOKEY_TEST_DIR/postfix-config.ini" "$CONFIG_PATH"
cp "$SMOKEY_TEST_DIR/postfix-input.txt" "$INPUT_PATH"

pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH"

if ! grep -q 'Connecting to <<tenant-service>> endpoint\.' "$INPUT_PATH"; then
    echo "Postfix wrapping did not occur as expected" >&2
    exit 1
fi

echo "POSTFIX_OK=1"
