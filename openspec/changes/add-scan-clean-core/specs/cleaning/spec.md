# Delta: Cleaning

## ADDED Requirements

### Requirement: Dry-Run Default
Destructive CLI operations MUST run as dry-run unless explicitly confirmed.

### Requirement: Trash by Default
Confirmed deletion MUST move files to Trash by default.

### Requirement: Symlink Attack Prevention
FoxClean MUST resolve and validate paths before deletion.

### Requirement: Operation Logging
Delete operations MUST be recorded in append-only JSONL unless explicitly
disabled.

### Requirement: Rollback from Trash
FoxClean MUST support restoring logged Trash operations by session ID.
