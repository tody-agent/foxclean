# FoxClean Implementation Audit

This file records what has been implemented locally against `spec.md`, what has
repeatable evidence, and what remains blocked by external release credentials or
distribution access.

## Local Verification Gate

Run:

```sh
script/verify_local.sh
```

Optional GUI launch check:

```sh
script/verify_local.sh --launch
```

Optional local unsigned DMG packaging check:

```sh
script/verify_local.sh --launch --package
```

External release-readiness preflight:

```sh
script/release_preflight.sh
script/release_preflight.sh --strict
```

Prompt-to-artifact completion audit:

```sh
script/completion_audit.sh
script/completion_audit.sh --strict
```

The script writes logs and smoke-test JSON outputs to `.build/verification/`.

Last local verification:

- Date: 2026-05-17
- Command: `script/verify_local.sh --launch --package`
- Result: passed
- Evidence directory: `.build/verification/`
- Includes completion audit log: `.build/verification/completion-audit.log`

Last release preflight:

- Date: 2026-05-17
- Command: `script/release_preflight.sh`
- Result: local distributable passed; 6 external/manual blockers remain
- Passing checks: DMG exists, SHA-256 sidecar exists, checksum verifies,
  `hdiutil verify` passes, release workflow exists, GitHub workflow static
  validation passes, git remote origin is configured, GitHub CLI is
  authenticated, `tody-agent/foxclean` is accessible, GitHub Pages is enabled
  for workflow deploys, latest GitHub Build/Test/Lint/Pages runs passed for
  `HEAD`, Homebrew cask draft exists, Homebrew cask static validation passes
- Blockers: Developer ID Application identity, notarization env vars,
  Homebrew publication/PR access, Full Disk Access, Touch ID authorization,
  manual VoiceOver/contrast/RTL/Gatekeeper QA

Previous GitHub publication attempt:

- Date: 2026-05-17
- Command: `gh repo create foxclean/foxclean --public --source . --remote origin --push`
- Result: blocked by account permission
- Error: `tody-agent cannot create a repository for foxclean`
- Required input: an account with permission to create or administer
  `foxclean/foxclean`, or a replacement repository owner plus matching URL
  updates in README, release workflow, Homebrew cask, Pages links, and launch
  drafts

Updated GitHub target:

- Date: 2026-05-17
- User instruction: create repo as `tody-agent/foxclean`
- Status: public repo created and `main` pushed
- URL: `https://github.com/tody-agent/foxclean`
- Evidence: `gh repo view tody-agent/foxclean --json nameWithOwner,url,visibility`
  returned `PUBLIC`

GitHub CI and Pages:

- Date: 2026-05-17
- Workflows: `Build`, `Test`, `Lint`, and `Pages` all completed successfully
  on `main`; `script/release_preflight.sh` verifies this against the current
  `HEAD`
- Pages URL: `https://tody-agent.github.io/foxclean/`
- Evidence: `gh run list --repo tody-agent/foxclean --limit 8` and
  `gh api repos/tody-agent/foxclean/pages`

## Implemented With Local Evidence

| Area | Evidence |
| --- | --- |
| Project foundation | `Package.swift`, `project.yml`, generated `FoxClean.xcodeproj`, `FoxCleanCore`, `FoxCleanCLI`, `FoxCleanApp`. |
| Local repository scaffold | `.git/` initialized locally, commits exist, `origin` is configured for `https://github.com/tody-agent/foxclean.git`, and `main` tracks `origin/main`. Repository existence/access is checked by `script/release_preflight.sh`. |
| PureMac fork baseline | App code copied into `FoxCleanApp`, renamed to FoxClean identifiers and bundle metadata. |
| Mole-derived cleanup knowledge | `Sources/FoxCleanCore/Resources/Data/cleanup_hints.json`, `Resources/data/locations.json`, `Resources/data/conditions.json`, extraction tools under `tools/`. |
| Bundled data validation | `RuleDatabase.bundled()`, `loadBundledLocations()`, `loadBundledConditions()`, and `testBundledRuleResourcesDecode` validate the four JSON resource schemas. |
| Scan core | `ScanEngine`, `PathFinder`, `RuleDatabase`, safe app/path metadata, 20 app/path fixtures, deep team/entitlement matching tests, and JSON CLI smoke checks. |
| Cleaning core | `FileOperator`, `OperationLog`, `RollbackEngine`, dry-run first semantics, symlink escape rejection, and trash-based operations. |
| Disk analyzer | `DiskScanner` with mtime-based persistent SQLite cache in Application Support, squarified `TreemapLayout`, CLI `fox analyze`, and `AnalyzerView` Tree/Treemap modes with breadcrumb zoom, Finder reveal, and guarded Move to Trash logging. |
| System monitor | `SystemMonitor` and `MonitorView` for uptime, host CPU ticks, VM memory stats, network throughput, disk I/O throughput via IOKit storage statistics, thermal state, battery percent, disk, process count, top processes, and health metrics. |
| Toolkit features | Installer cleanup, project purge, and optimize flows in core/CLI/SwiftUI views; project purge reads `~/.config/foxclean/purge_paths`; installer scanning includes source labels for Homebrew, Mail, iCloud, downloads, shared folders, and app caches; optimizer tasks include command previews, admin flags, and selected-task dry-runs. |
| GUI shell | SwiftUI sidebar sections, dashboard, onboarding, settings, toolkit views, mascot component, and AppKit menu bar status item. |
| Keyboard commands | App command menus route to dashboard/apps/orphans/toolkit sections, run Smart Scan, open Full Disk Access settings, and show the Help -> Keyboard Shortcuts window. |
| Menu bar widget | `MenuBarController` installs an AppKit `NSStatusItem` controlled by Settings -> Show FoxClean in menu bar; `MenuBarMiniView` provides a mini CPU chart, health/memory metrics, and Smart Scan/Open/Monitor/Quit actions without using SwiftUI `MenuBarExtra`. |
| Accessibility pass | Static labels exist for the sidebar, Full Disk Access footer, treemap, menu bar chart/buttons, and status item. Foxie and dashboard gauges honor macOS Reduce Motion, with an app-level "Reduce Foxie animations" toggle. Full VoiceOver audit remains a release task. |
| App runtime static guard | `script/check_app_runtime_static.sh` fails if `MenuBarExtra` returns, and verifies `MenuBarController`, `NSStatusItem`, `NSPopover`, and local sidebar selection state remain present. |
| GUI static guard | `script/check_gui_static.sh` verifies the onboarding page flow and Full Disk Access controls, dashboard scan/clean states and destructive confirmation, and settings tabs/toggles for startup, menu bar, scanning, safety, accessibility, scheduling, and repository links. |
| Clean UI static guard | `script/check_clean_ui_static.sh` verifies cleanup categories, sidebar category rendering, select/deselect controls, destructive confirmations, protected app hiding, orphan safety policy, and Finder reveal affordances. |
| CLI | `fox scan`, `clean`, `uninstall`, `log`, `analyze`, `status`, `purge`, `installer`, `optimize`, `completion`, `open`, `touchid`, plus an interactive TUI when launched in a TTY with no args. |
| Deep links | `FoxClean.app` registers the `foxclean://` URL scheme; `AppState.route(to:)` maps links to sidebar sections; `fox open <view>` invokes `/usr/bin/open`, with `--print-url` smoke checked. |
| Shell completion | `fox completion zsh`, `fox completion bash`, and `fox completion fish` generate shell-specific scripts and are smoke checked by `script/verify_local.sh`. |
| Touch ID status | `fox touchid status --json` inspects `/etc/pam.d/sudo_local` and `/etc/pam.d/sudo`; `enable/disable --dry-run --json` are verified; real enable/disable can update `/etc/pam.d/sudo_local` directly when root/writable or through `sudo`, leaving `.foxclean.bak`. |
| Quick launchers | `scripts/raycast/*.sh`, `scripts/setup-quick-launchers.sh`, and `script/build_and_run.sh`. |
| App-bundled CLI | `project.yml` embeds `fox` and `FoxCleanCore.framework` into `FoxClean.app`; verifier runs `dist/FoxClean.app/Contents/Resources/fox --version`. |
| App responsiveness | `script/check_app_responsive.sh` catches startup hangs by failing when FoxClean remains above the CPU threshold after launch. |
| Codex run action | `.codex/environments/environment.toml` exposes `Run` and `Verify` actions backed by project-local scripts. |
| Release scaffolding | CI workflows, Brewfile, lint configs, Homebrew formula draft, release notes, QA checklist, security docs. |
| GitHub workflow validation | `script/check_github_workflows.sh` statically verifies required workflow files, YAML parseability, macOS runners, build/test/lint/package commands, GitHub Release creation, and release artifact upload of the DMG, checksum, and Homebrew cask. |
| GitHub Pages scaffold | `docs/site/index.html` provides a static landing page using the app icon as the visual asset; `.github/workflows/pages.yml` deploys it through GitHub Pages; GitHub Pages is enabled for `https://tody-agent.github.io/foxclean/`; `script/check_pages_site.sh` statically validates the site and workflow. |
| Launch content scaffold | `docs/release/LAUNCH_POSTS.md` contains draft HN, Product Hunt, and X/Twitter launch copy; `script/check_release_docs.sh` verifies release notes, QA, audit, traceability, checksum references, preflight command, and launch drafts. |
| Homebrew validation | `script/check_homebrew_formula.sh` verifies cask syntax, version, release URL, app stanza, embedded CLI binary stanza, and zap cleanup paths. |
| Homebrew SHA update | `script/update_homebrew_cask_sha.sh` rewrites `homebrew/foxclean.rb` from `dist/FoxClean-1.0.0.dmg.sha256`; `script/package_release.sh` runs it after each DMG build. |
| Localization validation | `script/check_localization.sh` verifies 7 locale folders, `Resources/Localizable.xcstrings`, and key parity against English strings; `script/check_swiftui_localization_keys.sh` verifies SwiftUI literal coverage for common user-visible controls, dialogs, and accessibility labels. |
| Accessibility validation | `script/check_accessibility_static.sh` verifies required labels/descriptions for key navigational and visual surfaces. |
| App runtime validation | `script/check_app_runtime_static.sh` guards the menu bar and sidebar implementation that fixed the startup hang/click regression. |
| GUI validation | `script/check_gui_static.sh` guards the onboarding, dashboard, and settings surfaces that are otherwise hard to cover through local non-interactive launch checks. |
| Local release packaging | `script/package_release.sh` builds Release, verifies embedded `fox`, stages a drag-install Applications symlink, creates `dist/FoxClean-1.0.0.dmg` plus `dist/FoxClean-1.0.0.dmg.sha256`, updates the Homebrew cask SHA, and supports optional Developer ID signing/notarization through Apple notary API key or Apple ID password env vars. |
| Release preflight | `script/release_preflight.sh` checks the local DMG/checksum, signing identity env, API-key or Apple-ID notarization env, GitHub remote/auth/repository readiness, Homebrew cask scaffold, and manual OS gates; `--strict` fails when external release prerequisites are missing. |
| Completion audit | `script/completion_audit.sh` restates the objective and checks spec/sped inputs, two downloaded source folders, OpenSpec changes, project targets, git commit/remote state, verifier evidence, release artifacts, Homebrew cask validation, and external/manual blockers. |
| Universal binary | Release packaging builds `generic/platform=macOS` with `ARCHS="arm64 x86_64"` and fails unless app, embedded CLI, and core framework contain both slices. |
| Telemetry-free gate | `script/check_telemetry_free.sh` scans source/build manifests for analytics SDKs, tracking identifiers, and outbound network APIs. |
| Multi-language docs | `README.md`, `README.vi.md`, `README.en.md`, `README.es.md`, `README.ja.md`, `README.zh-Hans.md`, `README.zh-Hant.md`, and `README.ar.md`. |
| Tests | `Tests/FoxCleanCoreTests/FoxCleanCoreTests.swift` covers core safety, scanning fixtures, symlink safety, logging, treemap layout, installer scanning, system monitor snapshots, optimizer task metadata, project custom paths, and disk/project behavior. CLI JSON smokes now parse output as JSON instead of only checking non-empty stdout. |

## External Or Manual Gates

These are intentionally not marked complete by local verification because they
require credentials, account ownership, network publishing, or manual OS consent.

| Gate | Required input |
| --- | --- |
| Developer ID signing | Apple Developer account, certificate, signing identity selection. |
| Notarization and stapling | Apple notary credentials and network submission. |
| GitHub release upload | Repository ownership and authenticated `gh` or API credentials. |
| Homebrew publication | Tap ownership or PR workflow access. |
| GitHub release publication | Signed/notarized release artifact and maintainer approval to publish the public release. |
| Full Disk Access | User must grant macOS Privacy & Security permission manually. |
| Touch ID authorization | Real device policy and enrolled biometrics. |
| Public update feed | Hosting endpoint and signing/update strategy. |

## Known Scope Reductions

- The CLI uses a small built-in parser instead of `swift-argument-parser` so the
  project can build without network dependency resolution in this environment.
- Optimization tasks provide dry-run reports, command previews, and safe
  non-admin execution paths; privileged or destructive system changes still
  require explicit user authorization.
- The monitor gathers host CPU ticks, VM memory, network, disk I/O throughput,
  process count, top processes, battery, disk, thermal state, and health
  metrics. It uses public macOS thermal state instead of private temperature
  sensor APIs.
- UI snapshot and full VoiceOver/tab-order/contrast automation are not yet part
  of the local gate.
- Localization coverage is static and keyed to common SwiftUI literal
  constructors; runtime-only strings assembled through interpolation still rely
  on the existing English fallback behavior.
- `swiftlint` and `swift-format` are configured for CI/developer machines but
  are not bundled in this workspace.
