# FoxClean

FoxClean is a free, open-source macOS cleaner and optimizer. It combines a
native SwiftUI app, a shared Swift core, and the `fox` CLI.

## Quick Start

```sh
brew bundle
xcodegen generate
script/verify_local.sh --launch
```

## Highlights

- App and CLI share `FoxCleanCore`.
- Destructive operations default to dry-run and move to Trash when confirmed.
- Operation logs are JSONL and support rollback.
- Includes app scan, junk scan, orphan detection, disk analyzer, system status,
  installer cleanup, project purge, optimize tasks, shell completion, and quick
  launcher scripts.
- No telemetry, no subscription, MIT licensed.

## Release Note

Public distribution still requires Developer ID signing, notarization, and
repository/package-manager publishing credentials.
