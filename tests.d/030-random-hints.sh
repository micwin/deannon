#!/usr/bin/env bash
# 030-random-hints: run a dedicated config that exercises random token
# generation and ensures mappings are persisted externally.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${TESTDATA_DIR:?TESTDATA_DIR missing}"
: "${SMOKEY_STATE_DIR:?}"

RANDOM_DIR="${SMOKEY_STATE_DIR}/random"
mkdir -p "$RANDOM_DIR"
CONFIG_PATH="$RANDOM_DIR/random-config.ini"
INPUT_PATH="$RANDOM_DIR/random-input.txt"
AUTO_PATH="$RANDOM_DIR/random-generated.ini"

cp "$TESTDATA_DIR/random-config.ini" "$CONFIG_PATH"
cp "$TESTDATA_DIR/random-input.txt" "$INPUT_PATH"

if pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH"; then
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

cat <<INFO
RANDOM_HINTS_OK=1
INFO
