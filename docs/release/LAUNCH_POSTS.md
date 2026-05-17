# FoxClean Launch Posts

These drafts are ready for maintainers to adapt once the signed and notarized
v1.0.0 release is published.

## Hacker News

Title:

```text
Show HN: FoxClean - a free, telemetry-free macOS cleaner with native GUI and CLI
```

Post:

```text
FoxClean is an MIT-licensed macOS cleaner built with SwiftUI and a shared Swift
core for the app and `fox` CLI.

It focuses on dry-run-first cleanup, Trash-first deletes, JSONL operation logs,
rollback hooks, app leftovers, disk analysis, installer cleanup, project purge,
and system health checks. It has no analytics SDKs, no subscription, and no
outbound telemetry endpoints.

The v1.0.0 release includes a universal macOS app, an embedded CLI, Homebrew
Cask metadata, and release checks for localization, accessibility labels,
telemetry-free source, package verification, and checksums.
```

## Product Hunt

Tagline:

```text
Free, telemetry-free Mac cleanup with a native app and CLI
```

Description:

```text
FoxClean helps Mac users inspect and clean app leftovers, junk files, installers,
project caches, and disk usage without subscriptions or telemetry. It combines
a native SwiftUI app, a shared safety-first cleanup core, and the `fox` CLI for
automation-friendly workflows.
```

Topics:

```text
macOS, open source, developer tools, productivity, privacy
```

## X / Twitter

```text
FoxClean v1.0 is ready: a free, MIT-licensed macOS cleaner with a native SwiftUI
app, embedded `fox` CLI, dry-run-first cleanup, Trash-first deletes, operation
logs, rollback hooks, disk analyzer, and no telemetry.

Download: https://github.com/tody-agent/foxclean/releases/latest
```

## Maintainer Checklist

- [ ] Confirm the DMG is Developer ID signed, notarized, and stapled.
- [ ] Confirm GitHub Release assets include DMG, `.sha256`, and Homebrew cask.
- [ ] Confirm Homebrew Cask SHA matches the uploaded DMG.
- [ ] Replace draft URLs with final release URLs if repository name changes.
- [ ] Post HN only after download and Homebrew install paths are live.
