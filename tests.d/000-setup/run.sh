#!/usr/bin/env bash
# 000-setup: prepare shared fixtures under SMOKEY_STATE_DIR and record the
#            important paths via smokey_env_save so later tests see them.
set -euo pipefail

if ! command -v pwsh >/dev/null 2>&1; then
    echo "pwsh (PowerShell 7+) ist erforderlich, wurde aber nicht gefunden." >&2
    exit 1
fi

: "${PROJECT_ROOT:?PROJECT_ROOT missing (check tests.d/env.preseed)}"
: "${DEANNON_PS1:?DEANNON_PS1 missing (check tests.d/env.preseed)}"
: "${SMOKEY_STATE_DIR:?SMOKEY_STATE_DIR is required}"
: "${SMOKEY_TEST_DIR:?SMOKEY_TEST_DIR is required}"

WORK_DIR="${SMOKEY_STATE_DIR}/main"
mkdir -p "$WORK_DIR"

CONFIG_PATH="$WORK_DIR/config.ini"
INPUT_PATH="$WORK_DIR/work.txt"
ORIGINAL_PATH="$WORK_DIR/original.txt"
EXPECTED_ANON_PATH="$WORK_DIR/expected-anonymized.txt"
AUTO_FILE="$WORK_DIR/generated-full.ini"

cp "$SMOKEY_TEST_DIR/config.ini" "$CONFIG_PATH"
cp "$SMOKEY_TEST_DIR/original.txt" "$ORIGINAL_PATH"
cp "$ORIGINAL_PATH" "$INPUT_PATH"
cp "$SMOKEY_TEST_DIR/expected-anonymized.txt" "$EXPECTED_ANON_PATH"
: > "$AUTO_FILE"

export WORK_DIR CONFIG_PATH INPUT_PATH ORIGINAL_PATH EXPECTED_ANON_PATH AUTO_FILE
smokey_env_save WORK_DIR
smokey_env_save CONFIG_PATH
smokey_env_save INPUT_PATH
smokey_env_save ORIGINAL_PATH
smokey_env_save EXPECTED_ANON_PATH
smokey_env_save AUTO_FILE

cat <<INFO
WORK_DIR: $WORK_DIR
CONFIG_PATH: $CONFIG_PATH
INIT_DONE=1
INFO
