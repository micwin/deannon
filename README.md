# deannon

PowerShell-based utility for anonymizing and deanonymizing plain-text files via an INI configuration. The script (`deannon.ps1`) includes a shebang so you can run it directly on Linux/macOS or via `pwsh -File` on any platform.

## Prerequisites

- PowerShell 7.6 or newer in `PATH`
- Bash (only needed to run the Smokey test suite)
- [Smokey](https://github.com/micwin/smokey) available in `PATH`
- Optional but recommended: Git and write access to the INI file (the tool appends new `full.*` sections when hints discover fresh tokens)

## How It Works

1. Direction is detected from `full.*` pairs:
   - If at least one `original` token exists but no `anonymized` token, the file is anonymized.
   - If only anonymized tokens appear, the file is deanonymized.
   - Files containing both or none are skipped with a warning.
   - `direction_markers` act only as a fallback when no `full` pairs exist.
2. `full.*` sections define case-insensitive replacements that work in both directions.
3. `hint.*` sections accept regular expressions (case-insensitive). Every match is anonymized and recorded as a new `full.*` pair so future runs (including deanonymization) rely solely on the growing `full` list.

## INI Structure Example

```ini
[direction_markers]
original=io.metafence,de.micwin

[full.base-domain]
original=io.metafence
anonymized=custA.example

; Example of an auto-generated hint hit
[full.ns-prod-alpha]
original=ns-prod-alpha
anonymized=NSX001

[hint.namespaces]
hint=ns-prod-[a-z0-9]+   ; regex pattern (case-insensitive)
prefix=NSX               ; prefix for generated values
width=3                  ; zero-padding length (default 4)
next_index=1             ; incremented after each new match

[hint.metafence]
hint=metafence(?=\.net) ; only replace "metafence" before ".net"
prefix=CARL
width=3
next_index=1
```

- `direction_markers` is optional and only used when no `full` pairs exist.
- `full.<name>` defines a static pair.
- `hint.<name>` needs at least a regex; `prefix`, `width`, and `next_index` are optional.
- Newly discovered matches are appended as `full.*` sections.

## Installation

```bash
chmod +x deannon.ps1
```

## Usage

```bash
./deannon.ps1 -Config deannon.ini file1.txt file2.txt
```

If `-Config` is omitted, the script looks for `./deannon.ini` in the current working directory and aborts if the file does not exist.

```bash
pwsh -File deannon.ps1 -Config deannon.ini file.txt
```

During anonymization the script updates the INI; please commit those changes if you track the file in Git.

## Tests

Smoke tests run via Smokey (<https://github.com/micwin/smokey>):

```bash
cd /home/micwin/projects/deannon
smokey --tests-dir tests.d
```

Each run creates a scratch directory under `tests.d/.smokey-state/` and executes:
- `000-setup` copies fixtures from `tests/testdata/` into the temporary workspace.
- `010-anonymize` runs `./deannon.ps1` and checks the anonymized output.
- `020-deanonymize` runs the tool again and ensures the original content is restored without mutating the config snapshot.

Fixtures live in `tests/testdata/`, and the suite requires `pwsh` to be available.
