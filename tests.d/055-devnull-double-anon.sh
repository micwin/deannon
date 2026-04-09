#!/usr/bin/env bash
# 055-devnull-double-anon: reproduces the double-anonymization bug by pointing
# the generated entries file at /dev/null so no mappings survive.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${TESTDATA_DIR:?}"
: "${SMOKEY_STATE_DIR:?}"

DEVNULL_DIR="${SMOKEY_STATE_DIR}/repeat-devnull"
mkdir -p "$DEVNULL_DIR"
CONFIG_PATH="$DEVNULL_DIR/repeat-devnull-config.ini"
INPUT_PATH="$DEVNULL_DIR/work.txt"
ORIGINAL_PATH="$DEVNULL_DIR/original.txt"
EXPECTED_ANON="$DEVNULL_DIR/expected-anonymized.txt"

cp "$TESTDATA_DIR/repeat-devnull-config.ini" "$CONFIG_PATH"
cp "$TESTDATA_DIR/repeat-original.txt" "$INPUT_PATH"
cp "$TESTDATA_DIR/repeat-original.txt" "$ORIGINAL_PATH"
cp "$TESTDATA_DIR/repeat-expected-anonymized.txt" "$EXPECTED_ANON"

run1_log=$(pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH")
if ! diff -u "$EXPECTED_ANON" "$INPUT_PATH"; then
    echo "First anonymization did not match expectation" >&2
    echo "$run1_log" >&2
    exit 1
fi

run2_log=$(pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH")
if ! grep -q 'deanonymized replacements' <<<"$run2_log"; then
    echo "BUG: second run did not switch to deanonymization" >&2
    echo "$run2_log" >&2
    exit 1
fi

if ! diff -u "$ORIGINAL_PATH" "$INPUT_PATH"; then
    echo "Second run failed to restore original text" >&2
    exit 1
fi

echo "DEVNULL_DOUBLE_OK=1"
