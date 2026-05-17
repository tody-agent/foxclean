# FoxClean

FoxClean la ung dung don dep va toi uu macOS mien phi, ma nguon mo, gom GUI SwiftUI native va CLI `fox`.

## Build

```sh
brew bundle
xcodegen generate
xcodebuild -scheme FoxCleanApp -destination 'platform=macOS' build
swift test
swift run fox --version
```

## Tinh nang

- GUI native dua tren PureMac.
- `FoxCleanCore` gom scan app, scan rac he thong, tim orphan, dry-run cleaning, dua vao Trash mac dinh, operation log JSONL, rollback, disk analyzer, system status, installer cleanup, project purge va optimize tasks.
- CLI: `scan`, `clean`, `uninstall`, `log`, `analyze`, `status`, `purge`, `installer`, `optimize`, `completion`, `open`, `touchid`.
- Khong telemetry, khong subscription, MIT.
