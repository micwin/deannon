#!/usr/bin/env bash
# 010-anonymize: run anonymization, verify the output, and capture snapshots
#                for the deanonymization test.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${CONFIG_PATH:?Missing CONFIG_PATH (did 000-setup run?)}"
: "${INPUT_PATH:?Missing INPUT_PATH}"
: "${EXPECTED_ANON_PATH:?Missing EXPECTED_ANON_PATH}"
: "${AUTO_FILE:?Missing AUTO_FILE}"
: "${SMOKEY_STATE_DIR:?}"

pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH"

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

CONFIG_AFTER_ANON="${SMOKEY_STATE_DIR}/config.after-anon"
cp "$CONFIG_PATH" "$CONFIG_AFTER_ANON"
AUTO_AFTER_ANON="${SMOKEY_STATE_DIR}/generated.after"
cp "$AUTO_FILE" "$AUTO_AFTER_ANON"

export CONFIG_AFTER_ANON AUTO_AFTER_ANON
smokey_env_save CONFIG_AFTER_ANON
smokey_env_save AUTO_AFTER_ANON

cat <<INFO
ANON_OK=1
INFO
