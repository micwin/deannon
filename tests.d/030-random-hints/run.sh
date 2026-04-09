#!/usr/bin/env bash
# 030-random-hints: verify random replacement support and external auto-store.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${SMOKEY_STATE_DIR:?}"
: "${SMOKEY_TEST_DIR:?}"

STATE_DIR="${SMOKEY_STATE_DIR}/random"
mkdir -p "$STATE_DIR"
CONFIG_PATH="$STATE_DIR/random-config.ini"
INPUT_PATH="$STATE_DIR/random-input.txt"
AUTO_PATH="$STATE_DIR/random-generated.ini"

cp "$SMOKEY_TEST_DIR/random-config.ini" "$CONFIG_PATH"
cp "$SMOKEY_TEST_DIR/random-input.txt" "$INPUT_PATH"

if pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" -File "$INPUT_PATH"; then
    :
else
    echo "random hint anonymization failed" >&2
    exit 1
fi

if grep -q 'svc-rand-' "$INPUT_PATH"; then
    echo "Random identifiers still present in anonymized output" >&2
    exit 1
fi

if ! grep -Eq '\[\[[[:alnum:]]{8}\]\]' "$INPUT_PATH"; then
    echo "Anonymized identifiers do not match expected random format" >&2
    exit 1
fi

if [[ ! -f "$AUTO_PATH" ]]; then
    echo "Generated entries file missing at $AUTO_PATH" >&2
    exit 1
fi

if ! grep -q '^original=svc-rand-1234$' "$AUTO_PATH"; then
    echo "Generated entries file missing mapping for svc-rand-1234" >&2
    exit 1
fi

if ! grep -q '^original=svc-rand-5678$' "$AUTO_PATH"; then
    echo "Generated entries file missing mapping for svc-rand-5678" >&2
    exit 1
fi

echo "RANDOM_HINTS_OK=1"
