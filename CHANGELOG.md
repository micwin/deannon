# Changelog

## [0.2.6] - 2026-04-09
### Changed
- CLI now mandates `-File/-f` for every input; positional arguments are no longer accepted. Smokey tests and docs were updated accordingly.

### Fixed
- Resolved an additional PowerShell quirk where `$Files` could be bound as a scalar and lacked `.Count`, triggering runtime errors.


## [0.2.5] - 2026-04-09
### Changed
- CLI now requires explicit `-File/-f` arguments for every input; positional arguments are no longer interpreted as files. This removes ambiguity with the `-Config` parameter.

### Fixed
- Further hardened positional argument handling on Windows PowerShell: the script now wraps the supplied file array safely, preventing the `Count` property errors even when PowerShell binds values oddly.

## [0.2.4] - 2026-04-09
### Added
- CLI convenience: when `-Config` is omitted, every positional argument is now treated as an input file. This makes `./deannon.ps1 output.json` work with the default config.

### Changed
- README usage section documents the new behavior.

### Fixed
- Suppressed property-access crashes that happened when the first positional argument was interpreted as `-Config`; mixed token detection now gracefully flips to deanonymization only when generated entries exist.

## [0.2.2] - 2026-04-09
### Added
- `disabled=true` / `enabled=false` support on `full.*`, `hint.*`, and `include.*` blocks, plus the `025-disabled-sections` Smokey test to guard the behavior.

### Changed
- Config rewriting preserves include order, inline include metadata, and arbitrary/renamed sections; unknown blocks such as `[0full.*]` now survive untouched.
- When a `generated_entries_file` exists, ambiguous files (containing both original and anonymized tokens) automatically switch into deanonymization mode so round-trips still succeed.
- Smoke fixtures now live inside each numbered test directory; the shared `tests/testdata/` directory was removed.

### Fixed
- Includes, comments, and disabled sections are no longer dropped when saving the config or the generated auto-entry INI.

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
