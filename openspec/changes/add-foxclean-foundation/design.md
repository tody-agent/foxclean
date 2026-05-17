# Design: FoxClean Foundation

FoxClean is structured as a monorepo with three build surfaces:

- `FoxCleanApp` for the native SwiftUI macOS app.
- `FoxCleanCore` for shared scan, clean, monitor, toolkit, and safety logic.
- `FoxCleanCLI` for the `fox` command line tool.

`project.yml` is the source for the Xcode project. `Package.swift` is the
source for local package testing and CLI smoke checks. CI workflows mirror the
local gate where possible: generate the Xcode project, build, test, and lint.

The app baseline is derived from PureMac under `FoxCleanApp/`; shared CLI and
toolkit concepts are derived from Mole under `Sources/FoxCleanCore`.
