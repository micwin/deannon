#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${SMOKEY_STATE_DIR}/state.env"
if [[ ! -f "$STATE_FILE" ]]; then
    echo "state.env fehlt (000-setup ausgeführt?)." >&2
    exit 1
fi
# shellcheck disable=SC1090
source "$STATE_FILE"

if [[ -z "${CONFIG_AFTER_ANON:-}" || ! -f "$CONFIG_AFTER_ANON" ]]; then
    echo "CONFIG_AFTER_ANON fehlt – wurde 010-anonymize erfolgreich ausgeführt?" >&2
    exit 1
fi

pushd "$PROJECT_ROOT" >/dev/null
./deannon.ps1 --config "$CONFIG_PATH" "$INPUT_PATH"
popd >/dev/null

if ! diff -u "$ORIGINAL_PATH" "$INPUT_PATH"; then
    echo "De-Anonymisierung hat Original nicht wiederhergestellt" >&2
    exit 1
fi

if ! diff -u "$CONFIG_AFTER_ANON" "$CONFIG_PATH"; then
    echo "Konfig hat sich beim Deanonymisieren verändert" >&2
    exit 1
fi

cat <<INFO
DEANON_OK=1
INFO
