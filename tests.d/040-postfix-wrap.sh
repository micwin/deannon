#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${SMOKEY_STATE_DIR}/state.env"
if [[ ! -f "$STATE_FILE" ]]; then
    echo "state.env missing (did 000-setup run?)" >&2
    exit 1
fi
# shellcheck disable=SC1090
source "$STATE_FILE"

CONFIG_PATH="$STATE_DIR/postfix-config.ini"
INPUT_PATH="$STATE_DIR/postfix-input.txt"
cp "$PROJECT_ROOT/tests/testdata/postfix-config.ini" "$CONFIG_PATH"
cp "$PROJECT_ROOT/tests/testdata/postfix-input.txt" "$INPUT_PATH"

./deannon.ps1 -Config "$CONFIG_PATH" "$INPUT_PATH"

if ! grep -q 'Connecting to <<tenant-service>> endpoint\.' "$INPUT_PATH"; then
    echo "Postfix wrapping did not occur as expected" >&2
    exit 1
fi

cat <<INFO
POSTFIX_OK=1
INFO
