# Changelog

## [0.2.1] - 2026-04-09
### Added
- `scripts/release.sh` helper to run Smokey, bump the version, seed the changelog, and list the manual tagging steps.

### Changed
- All Smokey tests (including 000/010/020/999) now live in their own directories with `run.sh`, and each keeps its fixtures locally; the shared `tests/testdata/` directory was removed.

### Fixed
- n/a


## [0.2.0] - 2026-04-09
### Added
- Include directives (`[include.*]`) with optional `include_file` overrides and automatic `<name>.ini` fallback.
- Randomized hint replacements, wrap-aware outputs, and external auto-entry persistence improvements.
- Smokey test coverage for includes, random IDs, postfix wrapping, and repeat anonymization edge cases.
- README updates describing the new configuration options and smoke test structure.

### Changed
- Smoke tests now host their fixtures inside each numbered test directory, keeping cases fully self-contained.

## [0.1.0] - 2026-03-28
- Initial internal version.
