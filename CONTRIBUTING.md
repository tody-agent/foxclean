# Contributing

1. Run `swift test` before submitting changes.
2. Run `xcodegen generate` before opening the Xcode project.
3. Keep destructive filesystem changes behind `FileOperator` and `OperationLog`.
4. Put user-facing strings in localization resources.
5. Do not add telemetry or analytics.
