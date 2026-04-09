#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <version>" >&2
    exit 1
fi

VERSION="$1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"

if ! command -v ~/projects/smokey/smokey >/dev/null 2>&1; then
    echo "Smokey CLI not found at ~/projects/smokey/smokey" >&2
    exit 1
fi

echo "==> Running smoke tests"
~/projects/smokey/smokey --tests-dir tests.d

echo "==> Setting VERSION to $VERSION"
printf '%s\n' "$VERSION" > VERSION

CHANGELOG="$ROOT/CHANGELOG.md"
if [[ ! -f "$CHANGELOG" ]]; then
    cat <<'HEADER' > "$CHANGELOG"
# Changelog
HEADER
fi

date_str=$(date +%Y-%m-%d)
if ! grep -q "\[$VERSION\]" "$CHANGELOG"; then
    echo "==> Adding placeholder changelog entry for $VERSION"
    tmp="$(mktemp)"
    {
        echo "# Changelog"
        echo
        echo "## [$VERSION] - $date_str"
        echo "### Added"
        echo "- Describe new features."
        echo
        echo "### Changed"
        echo "- Describe behavioural changes."
        echo
        echo "### Fixed"
        echo "- Describe bug fixes."
        echo
        if [[ -s "$CHANGELOG" ]]; then
            awk 'NR>1 { print }' "$CHANGELOG"
        fi
    } > "$tmp"
    mv "$tmp" "$CHANGELOG"
else
    echo "Changelog already contains entry for $VERSION"
fi

echo
cat <<INSTRUCTIONS
Next steps (manual):
  1. Review/adjust README.md, CHANGELOG.md, and VERSION as needed.
  2. git status
  3. git add README.md CHANGELOG.md VERSION
  4. git commit -m "Prepare release v$VERSION"
  5. git tag v$VERSION
  6. git push origin develop
  7. git push origin v$VERSION
INSTRUCTIONS
