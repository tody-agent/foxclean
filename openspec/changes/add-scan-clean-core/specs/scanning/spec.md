# Delta: Scanning

## ADDED Requirements

### Requirement: App Discovery
FoxClean MUST discover installed macOS apps and protect system/protected apps.

### Requirement: Heuristic Path Matching
FoxClean MUST score candidate files from 0 to 30 and reject weak matches under
strict matching.

### Requirement: Orphan Detection
FoxClean MUST detect likely leftover files whose owning app is no longer
installed.

### Requirement: Machine-Readable Output
The CLI MUST provide JSON output for scan commands when `--json` is passed.
