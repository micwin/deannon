#!/usr/bin/env bash
# 050-repeat-double-anon: ensure a second invocation flips to deanonymization.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${SMOKEY_STATE_DIR:?}"
: "${SMOKEY_TEST_DIR:?}"

STATE_DIR="${SMOKEY_STATE_DIR}/repeat-double"
mkdir -p "$STATE_DIR"
CONFIG_PATH="$STATE_DIR/repeat-config.ini"
INPUT_PATH="$STATE_DIR/work.txt"
ORIGINAL_PATH="$STATE_DIR/original.txt"
EXPECTED_PATH="$STATE_DIR/expected.txt"
AUTO_PATH="$STATE_DIR/generated-full.ini"

cp "$SMOKEY_TEST_DIR/repeat-config.ini" "$CONFIG_PATH"
cp "$SMOKEY_TEST_DIR/repeat-original.txt" "$INPUT_PATH"
cp "$SMOKEY_TEST_DIR/repeat-original.txt" "$ORIGINAL_PATH"
cp "$SMOKEY_TEST_DIR/repeat-expected-anonymized.txt" "$EXPECTED_PATH"
: > "$AUTO_PATH"

run1=$(pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" -File "$INPUT_PATH")
if ! grep -q "anonymized replacements" <<<"$run1"; then
    echo "First run did not perform anonymization" >&2
    echo "$run1" >&2
    exit 1
fi

if ! diff -u "$EXPECTED_PATH" "$INPUT_PATH"; then
    echo "First anonymization did not match expectation" >&2
    exit 1
fi

run2=$(pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" -File "$INPUT_PATH")
if ! grep -q "deanonymized replacements" <<<"$run2"; then
    echo "Second run failed to detect already anonymized content" >&2
    echo "$run2" >&2
    exit 1
fi

if ! diff -u "$ORIGINAL_PATH" "$INPUT_PATH"; then
    echo "Second run did not restore the original text" >&2
    exit 1
fi

echo "REPEAT_DOUBLE_OK=1"
