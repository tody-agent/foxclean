# Cleaning Spec

Destructive operations MUST default to dry-run in the CLI. Confirmed cleaning MUST move files to Trash by default, validate resolved paths against an allow-list, write JSONL operation logs, and support rollback by session ID.
