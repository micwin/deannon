# deannon

A PowerShell-based anonymizer/deanonymizer for structured and semi-structured text (logs, JSON snippets, config files). Replacement rules come from a simple INI file, and hints (regex) can dynamically mint new pairs while keeping everything reversible. Works cross-platform (requires PowerShell 7+).

## Highlights

- **Automatic direction detection** based on existing `full.*` pairs (anonymize vs. deanonymize). Falls back to optional `direction_markers` when no full pair hits.
- **Regex hints** (`hint.*`) discover new tokens, generate replacements (`prefix`, `width`, `next_index`), and fold them into `full.*` entries for future runs.
- **External auto-entry store** to keep generated mappings separate from curated ones via `[global] generated_entries_file=generated-full.ini`.
- **Two-stage safety**: mixed original/anonymized tokens trigger warnings and skip the file; optional verbose output shows which pair matched.
- **Smokey smoke tests** verify round-trip anonymize/deanonymize flows on sample fixtures.

## Requirements

- PowerShell 7.6+ (`pwsh` in `PATH`)
- Bash (only for the Smokey tests)
- [Smokey](https://github.com/micwin/smokey) CLI for the smoke suite
- Write access to your INI (and the optional generated auto-entry INI)

## Configuration

```ini
[direction_markers]
original=io.metafence,de.micwin

[full.base-domain]
original=io.metafence
anonymized=custA.example

[hint.namespaces]
hint=ns-prod-[a-z0-9]+
prefix=NSX
width=3
next_index=1

[hint.metafence]
hint=metafence(?=\.net)
prefix=CARL
width=3
next_index=1

[global]
generated_entries_file=generated-full.ini
```

- `direction_markers` *(optional)*: strings that only appear in original data; used if no `full` hits exist.
- `full.<name>`: fixed replacements, case-insensitive, work in both directions.
- `hint.<name>`: regex-based discovery. Provide at least `hint`; `prefix`, `width`, `next_index` are optional.
- `[global].generated_entries_file`: when present, auto-generated pairs are written to the referenced INI file; the main INI stays human-managed.

## Usage

```bash
./deannon.ps1 -Config myrules.ini file1.txt file2.txt
```

- Omit `-Config` to use `./deannon.ini` automatically (errors if missing).
- During anonymization, the INI (and, if configured, the generated auto-entry INI) will be updated. Commit changes if you keep them in Git.
- Run with `-Verbose` for detailed direction/match logging.

## Tests

Smoke tests (Linux/macOS) ensure anonymize → deanonymize round trips:

```bash
cd /home/micwin/projects/deannon
smokey --tests-dir tests.d
```

The suite:
- copies fixtures from `tests/testdata/`
- runs `./deannon.ps1` once to anonymize (checking the generated auto-entry INI for new pairs)
- runs again to deanonymize and verifies both the text and the generated auto-entry snapshot remain unchanged

## Roadmap / Open Tasks

See [`tasks/`](tasks/) for follow-up items such as collision handling, randomized replacements, metadata improvements, etc.
