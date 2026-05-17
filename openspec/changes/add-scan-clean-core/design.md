# Design: Scan and Clean Core

`FoxCleanCore` owns all destructive-operation safety boundaries. Scanning
produces typed models and confidence scores; cleaning consumes those models
through `FileOperator`, records `OperationLog` JSONL entries, and supports
rollback through `RollbackEngine`.

The CLI and SwiftUI app should call the same core APIs. Destructive operations
default to dry-run and must not bypass path validation, symlink resolution, or
protected-app checks.
