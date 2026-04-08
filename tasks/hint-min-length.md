# Hint Minimum Length

Short regex patterns (like `.` or `svc-`) are risky because they match too much. Add configuration to require a minimum match length (e.g., 5 chars) or explicitly whitelist hints. The tool should warn/fail when hints are too unspecific.
