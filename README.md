# FoxClean

FoxClean is a free, open-source macOS cleaner and optimizer that combines a native SwiftUI app with a shared Swift core and the `fox` CLI.

## Build

```sh
brew bundle
xcodegen generate
xcodebuild -scheme FoxCleanApp -destination 'platform=macOS' build
swift test
swift run fox --version
```

## Features

- Native SwiftUI app based on PureMac.
- Shared `FoxCleanCore` with app scanning, junk scanning, orphan detection, dry-run cleaning, Trash-first deletion, JSONL operation logs, rollback, disk analyzer, system status, installer cleanup, project purge, and optimization task plumbing.
- CLI commands: `scan`, `clean`, `uninstall`, `log`, `analyze`, `status`, `purge`, `installer`, `optimize`, `completion`, `open`, and `touchid`.
- No telemetry, no subscription, MIT licensed.

## Safety

Destructive CLI actions default to dry-run. Use `--confirm` for Trash moves. Permanent deletion requires both `--permanent` and `--confirm-permanent`.
