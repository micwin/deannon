# Changelog

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
