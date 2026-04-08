#!/usr/bin/env bash
# 040-postfix-wrap: confirm that static full pairs that already include their
# own wrappers are replaced as-is.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${TESTDATA_DIR:?}"
: "${SMOKEY_STATE_DIR:?}"

POSTFIX_DIR="${SMOKEY_STATE_DIR}/postfix"
mkdir -p "$POSTFIX_DIR"
CONFIG_PATH="$POSTFIX_DIR/postfix-config.ini"
INPUT_PATH="$POSTFIX_DIR/postfix-input.txt"

cp "$TESTDATA_DIR/postfix-config.ini" "$CONFIG_PATH"
cp "$TESTDATA_DIR/postfix-input.txt" "$INPUT_PATH"

pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH"

if ! grep -q 'Connecting to <<tenant-service>> endpoint\.' "$INPUT_PATH"; then
    echo "Postfix wrapping did not occur as expected" >&2
    exit 1
fi

cat <<INFO
POSTFIX_OK=1
INFO
