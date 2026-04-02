#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${SMOKEY_STATE_DIR:-}"
if [[ -n "$STATE_DIR" && -d "$STATE_DIR" ]]; then
    rm -rf -- "$STATE_DIR"
fi

echo "TEARDOWN_CLEAN=1"
