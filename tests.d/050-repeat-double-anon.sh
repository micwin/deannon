#!/usr/bin/env bash
# 050-repeat-double-anon: ensure the tool does not anonymize twice in a row.
# After the first anonymization run, a second invocation should classify the
# already anonymized file as "deanonymized" and restore the original content.
set -euo pipefail

: "${DEANNON_PS1:?}"
: "${TESTDATA_DIR:?}"
: "${SMOKEY_STATE_DIR:?}"

REPEAT_DIR="${SMOKEY_STATE_DIR}/repeat-double"
mkdir -p "$REPEAT_DIR"
CONFIG_PATH="$REPEAT_DIR/repeat-config.ini"
INPUT_PATH="$REPEAT_DIR/repeat-work.txt"
ORIGINAL_PATH="$REPEAT_DIR/repeat-original.txt"
EXPECTED_ANON_PATH="$REPEAT_DIR/repeat-expected.txt"
AUTO_PATH="$REPEAT_DIR/repeat-generated.ini"

cp "$TESTDATA_DIR/repeat-config.ini" "$CONFIG_PATH"
cp "$TESTDATA_DIR/repeat-original.txt" "$INPUT_PATH"
cp "$TESTDATA_DIR/repeat-original.txt" "$ORIGINAL_PATH"
cp "$TESTDATA_DIR/repeat-expected-anonymized.txt" "$EXPECTED_ANON_PATH"
: > "$AUTO_PATH"

run1=$(pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH")
if ! grep -q "anonymized replacements" <<<"$run1"; then
    echo "First run did not perform anonymization" >&2
    echo "$run1" >&2
    exit 1
fi

if ! diff -u "$EXPECTED_ANON_PATH" "$INPUT_PATH"; then
    echo "First anonymization did not match expectation" >&2
    exit 1
fi

run2=$(pwsh "$DEANNON_PS1" -Config "$CONFIG_PATH" "$INPUT_PATH")
if ! grep -q "deanonymized replacements" <<<"$run2"; then
    echo "Second run failed to detect already anonymized content" >&2
    echo "$run2" >&2
    exit 1
fi

if ! diff -u "$ORIGINAL_PATH" "$INPUT_PATH"; then
    echo "Second run did not restore the original text" >&2
    exit 1
fi

cat <<INFO
REPEAT_DOUBLE_OK=1
INFO
