#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${SMOKEY_STATE_DIR}/state.env"
if [[ ! -f "$STATE_FILE" ]]; then
    echo "state.env missing (did 000-setup run?)." >&2
    exit 1
fi
# shellcheck disable=SC1090
source "$STATE_FILE"

if [[ -z "${CONFIG_AFTER_ANON:-}" || ! -f "$CONFIG_AFTER_ANON" ]]; then
    echo "CONFIG_AFTER_ANON missing – did 010-anonymize succeed?" >&2
    exit 1
fi

pushd "$PROJECT_ROOT" >/dev/null
./deannon.ps1 --config "$CONFIG_PATH" "$INPUT_PATH"
popd >/dev/null

if ! diff -u "$ORIGINAL_PATH" "$INPUT_PATH"; then
    echo "Deanonymization did not restore the original file" >&2
    exit 1
fi

if ! diff -u "$CONFIG_AFTER_ANON" "$CONFIG_PATH"; then
    echo "Config changed during deanonymization" >&2
    exit 1
fi

cat <<INFO
DEANON_OK=1
INFO
