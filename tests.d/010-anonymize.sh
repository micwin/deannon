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
./deannon.ps1 -Config "$CONFIG_PATH" "$INPUT_PATH"
popd >/dev/null

if ! diff -u "$EXPECTED_ANON_PATH" "$INPUT_PATH"; then
    echo "Anonymized file does not match the expectation" >&2
    exit 1
fi

if grep -q 'ns-prod-alpha' "$CONFIG_PATH"; then
    echo "Auto entries leaked into config.ini (ns-prod-alpha present)" >&2
    exit 1
fi

if grep -q 'svc-228845' "$CONFIG_PATH"; then
    echo "Auto entries leaked into config.ini (svc-228845 present)" >&2
    exit 1
fi

if [[ -z "${AUTO_FILE:-}" ]]; then
    echo "State missing AUTO_FILE" >&2
    exit 1
fi

if [[ ! -f "$AUTO_FILE" ]]; then
    echo "Generated entries file missing at $AUTO_FILE" >&2
    exit 1
fi

if ! grep -q '^original=ns-prod-alpha$' "$AUTO_FILE"; then
    echo "Generated entries file lacks ns-prod-alpha mapping" >&2
    exit 1
fi

if ! grep -q '^original=svc-228845$' "$AUTO_FILE"; then
    echo "Generated entries file lacks svc-228845 mapping" >&2
    exit 1
fi

CONFIG_AFTER_ANON="${STATE_DIR:-$SMOKEY_STATE_DIR}/config.after-anon"
cp "$CONFIG_PATH" "$CONFIG_AFTER_ANON"
AUTO_AFTER_ANON="${STATE_DIR:-$SMOKEY_STATE_DIR}/generated.after"
cp "$AUTO_FILE" "$AUTO_AFTER_ANON"
cat >> "$STATE_FILE" <<STATE
export CONFIG_AFTER_ANON="$CONFIG_AFTER_ANON"
export AUTO_AFTER_ANON="$AUTO_AFTER_ANON"
STATE

cat <<INFO
ANON_OK=1
INFO
