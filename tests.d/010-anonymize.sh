#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${SMOKEY_STATE_DIR}/state.env"
if [[ ! -f "$STATE_FILE" ]]; then
    echo "state.env missing (did 000-setup run?)." >&2
    exit 1
fi
# shellcheck disable=SC1090
source "$STATE_FILE"

pushd "$PROJECT_ROOT" >/dev/null
./deannon.ps1 --config "$CONFIG_PATH" "$INPUT_PATH"
popd >/dev/null

if ! diff -u "$EXPECTED_ANON_PATH" "$INPUT_PATH"; then
    echo "Anonymized file does not match the expectation" >&2
    exit 1
fi

if ! grep -q '^original=ns-prod-alpha$' "$CONFIG_PATH"; then
    echo "Missing auto-generated full entry for ns-prod-alpha" >&2
    exit 1
fi

if ! grep -q '^anonymized=NSX001$' "$CONFIG_PATH"; then
    echo "Auto-generated full entry contains an unexpected anonymized value" >&2
    exit 1
fi

CONFIG_AFTER_ANON="${STATE_DIR:-$SMOKEY_STATE_DIR}/config.after-anon"
cp "$CONFIG_PATH" "$CONFIG_AFTER_ANON"
cat >> "$STATE_FILE" <<STATE
export CONFIG_AFTER_ANON="$CONFIG_AFTER_ANON"
STATE

cat <<INFO
ANON_OK=1
INFO
