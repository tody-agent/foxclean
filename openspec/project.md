# FoxClean Project Context

FoxClean is a free, open-source macOS cleaner and optimizer. It combines the native SwiftUI user experience from PureMac with Mole-derived cleanup rules and CLI workflows.

## Targets

- `FoxCleanApp`: native macOS SwiftUI app.
- `FoxCleanCore`: shared Swift package core.
- `FoxCleanCLI`: `fox` executable.

## Rules

- File paths use `URL`.
- Destructive operations go through `OperationLog`.
- Async work uses Swift concurrency.
- UI strings live in localization resources.
- Requirements use RFC 2119 language.
