# deannon

Tool zum Anonymisieren bzw. De-Anonymisieren von Textdateien auf Basis einer einfachen INI-Konfiguration. Die komplette Logik liegt in PowerShell (`deannon.ps1`) mit Shebang, sodass das Skript direkt (oder via `pwsh -File …`) gestartet werden kann.

## Voraussetzungen

- PowerShell 7.6 (oder höher) im `PATH`
- Bash (für die Smokey-Smoke-Tests)
- Smokey Smoke-Runner: <https://github.com/micwin/smokey>

Optional, aber empfohlen:
- Git für Versionsverwaltung/Commits
- Schreibrechte auf die INI, da das Tool neue `full.*`-Sektionen anhängt

## Funktionsweise

1. Die Richtung pro Datei wird primär über `full.*`-Paare erkannt:
   - Findet das Skript mindestens ein `original`, aber kein `anonymized`, wird anonymisiert.
   - Findet es nur `anonymized`-Tokens, wird de-anonymisiert.
   - Enthält die Datei beides oder gar keine Treffer, wird sie mit Warnung übersprungen.
   - Nur wenn keine `full`-Paare definiert sind, dienen `direction_markers` als Fallback für „Original“.
2. **Full-Paare** (Sektionen `full.*`) ersetzen Strings 1:1 in beide Richtungen (case-insensitive).
3. **Hint-Paare** (Sektionen `hint.*`) enthalten reguläre Ausdrücke (case-insensitive). Jede Übereinstimmung wird anonymisiert, und das Tool legt für jeden neuen Treffer automatisch eine zusätzliche `full.*`-Sektion ab. Dadurch reicht die `full`-Liste für spätere Läufe (inkl. De-Anonymisierung) vollständig aus.

## INI-Struktur

```ini
[direction_markers]
original=io.metafence,de.micwin

[full.base-domain]
original=io.metafence
anonymized=custA.example

; Beispiel für einen automatisch erzeugten Hint-Treffer
[full.ns-prod-alpha]
original=ns-prod-alpha
anonymized=NSX001

[hint.namespaces]
hint=ns-prod-[a-z0-9]+   ; Regex (case-insensitive)
prefix=NSX               ; Prefix für automatisch erzeugte Werte
width=3                  ; Zero-Padding-Länge, default=4
next_index=1             ; Wird automatisch hochgezählt

[hint.metafence]
hint=metafence(?=\.net) ; Nur „metafence“ vor ".net" ersetzen
prefix=CARL
width=3
next_index=1
```

- `direction_markers` ist optional und dient nur als Fallback, falls keine `full`-Paare vorhanden sind.
- `full.<name>` repräsentiert feste Paare.
- `hint.<name>` benötigt mindestens einen Regex (`hint`), optional `prefix`, `width`, `next_index`.
- Neue Matches aus `hint.*` werden beim Speichern als zusätzliche `full.*`-Sektionen abgelegt; `assignments` existieren nicht mehr.

## Installation

```bash
chmod +x deannon.ps1
```

## Nutzung

```bash
./deannon.ps1 --config deannon.ini file1.txt file2.txt
```

- Alternativ (plattformunabhängig): `pwsh -File deannon.ps1 -Config deannon.ini file.txt`.
- Während des Anonymisierens erweitert das Tool die INI. Bitte ins Versionskontrollsystem übernehmen.

## Tests

Die Smoke-Tests basieren auf Smokey (`~/projects/smokey`). Beispielaufruf unter Linux:

```bash
cd /home/micwin/projects/deannon
~/projects/smokey/smokey --tests-dir tests.d
```

Jeder Lauf verwendet `tests.d/.smokey-state/…` als Scratch-Bereich und prüft:
- `000-setup` kopiert das Sample-INI in einen temporären Ort und erzeugt Eingabe-/Erwartungsdateien.
- `010-anonymize` führt `./deannon.ps1` aus und vergleicht die Ausgabe mit den erwarteten anonymisierten Zeilen.
- `020-deanonymize` läuft das Tool erneut und stellt sicher, dass die Originaldaten wiederhergestellt werden.

Die Tests benötigen `pwsh` im `PATH`. Setze `SMOKEY_STATE_DIR` nur, wenn du den Scratch-Ordner manuell vorgeben möchtest.
Die dazugehörigen Fixtures liegen unter `tests/testdata/`.
