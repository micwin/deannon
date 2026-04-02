#!/usr/bin/env bash
set -euo pipefail

if ! command -v pwsh >/dev/null 2>&1; then
    echo "pwsh (PowerShell 7+) ist erforderlich, wurde aber nicht gefunden." >&2
    exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTDATA_DIR="$PROJECT_ROOT/tests/testdata"
STATE_DIR="${SMOKEY_STATE_DIR:-"$PROJECT_ROOT/.testrun"}"
mkdir -p "$STATE_DIR"

CONFIG_PATH="$STATE_DIR/config.ini"
INPUT_PATH="$STATE_DIR/work.txt"
ORIGINAL_PATH="$STATE_DIR/original.txt"
EXPECTED_ANON_PATH="$STATE_DIR/expected-anonymized.txt"
STATE_FILE="$STATE_DIR/state.env"
INITIAL_CONFIG="$STATE_DIR/config.initial"

cp "$TESTDATA_DIR/config.ini" "$CONFIG_PATH"
cp "$TESTDATA_DIR/config.ini" "$INITIAL_CONFIG"

cp "$TESTDATA_DIR/original.txt" "$ORIGINAL_PATH"
cp "$ORIGINAL_PATH" "$INPUT_PATH"
cp "$TESTDATA_DIR/expected-anonymized.txt" "$EXPECTED_ANON_PATH"

cat > "$STATE_FILE" <<STATE
export PROJECT_ROOT="$PROJECT_ROOT"
export CONFIG_PATH="$CONFIG_PATH"
export INPUT_PATH="$INPUT_PATH"
export ORIGINAL_PATH="$ORIGINAL_PATH"
export EXPECTED_ANON_PATH="$EXPECTED_ANON_PATH"
export INITIAL_CONFIG="$INITIAL_CONFIG"
export STATE_DIR="$STATE_DIR"
STATE

cat <<INFO
STATE_DIR: $STATE_DIR
CONFIG_PATH: $CONFIG_PATH
INIT_DONE=1
INFO
