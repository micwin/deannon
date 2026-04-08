# deannon

A PowerShell-based anonymizer/deanonymizer for structured and semi-structured text (logs, JSON snippets, config files). Replacement rules come from a simple INI file, and hints (regex) can dynamically mint new pairs while keeping everything reversible. Works cross-platform (requires PowerShell 7+).

## Highlights

- **Automatic direction detection** uses existing `full.*` pairs to decide anonymize vs. deanonymize (only falls back to `direction_markers` if no full pair hits).
- **Regex hints** (`hint.*`) can either run sequential counters (`width`/`next_index`) or mint random tokens (`randomize`/`random_charset`) and persist the results; `prefix`/`postfix` optionally wrap the generated value.
- **Curated+generated pairs** always store the final anonymized token (including any brackets/prefixes), making deanonymization straightforward.
- **External auto-entry store** keeps generated mappings in a dedicated INI via `[global] generated_entries_file=…`; the auto file uses the same format and is recreated on every successful run.
- **Two-stage safety**: mixed original/anonymized tokens trigger warnings and skip the file; optional verbose output shows which pair matched.
- **Smokey smoke tests** verify anonymize/deanonymize round trips plus random hint and wrap scenarios.

## Requirements

- PowerShell 7.6+ (`pwsh` in `PATH`)
- Bash (only for the Smokey tests)
- [Smokey](https://github.com/micwin/smokey) CLI for the smoke suite
- Write access to your INI (and the optional generated auto-entry INI)

## Configuration

```ini
[global]
generated_entries_file=generated-full.ini

[direction_markers]
original=io.metafence,de.micwin

[full.base-domain]
original=io.metafence
anonymized=custA.example

[full.mgmt-namespace]
original=de.micwin.core
anonymized=<<tenant-42.core>>

[hint.namespaces]
hint=ns-prod-[a-z0-9]+
prefix=NSX
width=3
next_index=1

[hint.random-services]
hint=svc-rand-[0-9]{4}
randomize=8
random_charset=alnum
prefix=[[
postfix=]]
```

- `[global]`: points to the external auto-entry INI. The file is created if missing and re-written using the same INI format as the main config.
- `direction_markers` *(optional)*: strings that only occur in original texts; used only when no `full.*` hits exist.
- `full.<name>`: fixed, case-insensitive replacements that work for both directions. Store the anonymized value exactly as it should appear (e.g., including `<< >>`).
- `hint.<name>`: regex-based discovery. Either specify `width` + `next_index` for sequential IDs or `randomize` (+ optional `random_charset`, default `alnum`) for random IDs. Optional `prefix`/`postfix` wrap the generated payload before it is persisted as a `full.*` entry.

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
~/projects/smokey/smokey --tests-dir tests.d
```

The Smokey suite:
- copies fixtures from `tests/testdata/`
- runs `./deannon.ps1` once to anonymize (checking / creating the generated auto-entry INI)
- runs again to deanonymize and verifies both the text and the generated auto-entry snapshot remain unchanged
- includes dedicated cases for random hints and wrapped replacements

## Roadmap / Open Tasks

See [`tasks/`](tasks/) for follow-up items such as collision handling, randomized replacements, metadata improvements, etc.
