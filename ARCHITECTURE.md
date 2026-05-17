# Architecture

FoxClean follows the spec's three-target layout.

- `FoxCleanApp/`: SwiftUI macOS GUI ported from PureMac and branded for FoxClean.
- `Sources/FoxCleanCore/`: shared Swift core for scanning, cleaning, logs, rollback, disk analyzer, monitor, and toolkit workflows.
- `Sources/FoxCleanCLI/`: `fox` executable using the shared core.

Destructive operations go through `FileOperator` and `OperationLog`. The CLI is dry-run by default and Trash-first when confirmed.
