#!/usr/bin/env bash
# 020-deanonymize: ensure the anonymized file returns to its original form and
#                  that neither the config nor generated entries mutate.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${CONFIG_PATH:?Missing CONFIG_PATH (did 000-setup run?)}"
: "${INPUT_PATH:?Missing INPUT_PATH}"
: "${ORIGINAL_PATH:?Missing ORIGINAL_PATH}"
: "${CONFIG_AFTER_ANON:?Missing CONFIG_AFTER_ANON (did 010-anonymize run?)}"
: "${AUTO_FILE:?Missing AUTO_FILE}"
: "${AUTO_AFTER_ANON:?Missing AUTO_AFTER_ANON}"

pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH"

if ! diff -u "$ORIGINAL_PATH" "$INPUT_PATH"; then
    echo "Deanonymization did not restore the original file" >&2
    exit 1
fi

if ! diff -u "$CONFIG_AFTER_ANON" "$CONFIG_PATH"; then
    echo "Config changed during deanonymization" >&2
    exit 1
fi

if ! diff -u "$AUTO_AFTER_ANON" "$AUTO_FILE"; then
    echo "Generated entries file changed during deanonymization" >&2
    exit 1
fi

cat <<INFO
DEANON_OK=1
INFO
