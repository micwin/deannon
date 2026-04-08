#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="${SMOKEY_STATE_DIR}/state.env"
if [[ ! -f "$STATE_FILE" ]]; then
    echo "state.env missing (did 000-setup run?)" >&2
    exit 1
fi
# shellcheck disable=SC1090
source "$STATE_FILE"

CONFIG_PATH="$STATE_DIR/random-config.ini"
INPUT_PATH="$STATE_DIR/random-input.txt"
AUTO_PATH="$STATE_DIR/random-generated.ini"
cp "$PROJECT_ROOT/tests/testdata/random-config.ini" "$CONFIG_PATH"
cp "$PROJECT_ROOT/tests/testdata/random-input.txt" "$INPUT_PATH"

if ./deannon.ps1 -Config "$CONFIG_PATH" "$INPUT_PATH"; then
    :
else
    echo "random hint anonymization failed" >&2
    exit 1
fi

if grep -q 'svc-rand-' "$INPUT_PATH"; then
    echo "Random identifiers still present in anonymized output" >&2
    exit 1
fi

if ! grep -Eq 'RND[[:alnum:]]{8}' "$INPUT_PATH"; then
    echo "Anonymized identifiers do not match expected random format" >&2
    exit 1
fi

if [[ -f "$AUTO_PATH" ]] && grep -q 'original=svc-rand-1234' "$AUTO_PATH"; then
    :
else
    echo "Generated entries file missing random mapping" >&2
    exit 1
fi

cat <<INFO
RANDOM_HINTS_OK=1
INFO
