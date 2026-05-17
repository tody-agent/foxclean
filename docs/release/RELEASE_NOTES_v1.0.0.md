# FoxClean 1.0.0

Initial local implementation:

- Native macOS SwiftUI app ported from PureMac and branded for FoxClean.
- Shared SwiftPM core for scanning, cleaning, operation logging, rollback, disk analysis, system status, installer cleanup, project purge, and optimization plumbing.
- `fox` CLI with dry-run defaults and JSON output.
- Mole-derived protection and cleanup hint data.
- XcodeGen project with app, core, and CLI schemes.
- CI workflows for build, test, lint, and release packaging.

External release requirements still need maintainer credentials: Apple Developer ID signing, notarization secrets, GitHub release upload, and Homebrew cask PR.
