# Security

FoxClean is a local filesystem utility. Report security issues privately before public disclosure.

Safety expectations:

- Destructive operations default to dry-run in the CLI.
- Confirmed cleanup moves files to Trash by default.
- Permanent deletion requires an explicit double confirmation.
- Symlinks are resolved and validated against allow-listed roots before deletion.
- Operation logs are append-only JSONL unless `FOX_NO_OPLOG` is set.
