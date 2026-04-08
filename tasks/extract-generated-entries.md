# Separate Generated Entries

Currently, auto-generated `full.*` entries mix with user-maintained ones in the same INI. Add logic to store generated pairs in a separate section/file so human-maintained mappings remain untouched (e.g., write auto-pairs to `full.auto.*` or a companion INI). Provide tooling to merge/export them when needed.
