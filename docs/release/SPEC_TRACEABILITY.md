# FoxClean Spec Traceability

Objective: read `spec.md` and implement FoxClean from the two downloaded source
folders (`PureMac/` and `Mole/`) as fully as possible without asking for more
input.

Status legend:

- `Pass`: implemented and verified locally.
- `Partial`: implemented in a pragmatic form but not at the full spec depth.
- `Blocked`: needs external credentials, account ownership, OS consent, or
  network publishing.

## Prompt-to-Artifact Checklist

| Requirement from objective/spec | Evidence inspected | Status |
| --- | --- | --- |
| Read `sped.md` / project spec | Original source file present in workspace was `spec.md`; `sped.md` now exists as an alias note pointing to `spec.md`. `spec.md` was inspected and mapped here. | Pass |
| Use two downloaded repos/folders | `PureMac/` and `Mole/` are present; app baseline under `FoxCleanApp/`, rule/hint resources and scripts derive from them. | Pass |
| Create OpenSpec with 8 changes | `openspec/changes/*/{proposal.md,design.md,tasks.md,specs/.../spec.md}` now exists for all 8 changes. | Pass |
| Local git repository | `git rev-parse --is-inside-work-tree` returns `true`; commits exist; `origin` points at `https://github.com/tody-agent/foxclean.git`; `main` tracks `origin/main`. Public GitHub repo existence/access is checked by preflight. | Pass |
| Foundation targets | `Package.swift`, `project.yml`, `FoxCleanApp`, `Sources/FoxCleanCore`, `Sources/FoxCleanCLI`; Xcode builds pass. | Pass |
| MIT license and credits | `LICENSE`, `NOTICE`, `README.md`, `README.vi.md`. | Pass |
| Root ignore/tooling | `.gitignore`, `.swiftlint.yml`, `.swift-format`, `.editorconfig`, `Brewfile`. | Pass |
| CI workflows | `.github/workflows/build.yml`, `test.yml`, `lint.yml`, `release.yml` plus `script/check_github_workflows.sh` static validation for required files, YAML parsing, macOS runners, build/test/lint/package commands, and artifact upload. `script/release_preflight.sh` verifies `Build`, `Test`, `Lint`, and `Pages` passed for the current `HEAD`. | Pass |
| Foxie mascot | `FoxCleanApp/Foxie/FoxieView.swift`; integrated in app shell. | Pass |
| Scan engine | `Sources/FoxCleanCore/Scanning/*`; covered by `swift test`, including 20 app/path fixtures, deep team/entitlement matching, and CLI smoke JSON. Bundled JSON rules decode through typed schemas. | Pass |
| Cleaning safety | `FileOperator`, `OperationLog`, `RollbackEngine`; dry-run, symlink escape rejection, and roundtrip tests exist. | Pass |
| Full Disk Access | PureMac-derived `FullDiskAccessManager.swift` exists in app services; actual macOS consent is manual. | Partial |
| CLI command surface | `Sources/FoxCleanCLI/main.swift`; smoke checked `--version`, non-TTY no-args usage, `status`, `scan apps --json`, `analyze Sources --json`, completions, `open --print-url`, and Touch ID dry-runs. | Pass |
| GUI onboarding/dashboard/settings | SwiftUI views under `FoxCleanApp/Views`; `script/check_gui_static.sh` verifies onboarding page flow, Full Disk Access controls, dashboard scan/clean states, destructive clean confirmation, category toggles, and settings tabs/toggles for startup, menu bar, scanning, safety, accessibility, scheduling, and repository links. App build and launch verification pass. | Pass |
| Keyboard shortcuts | `FoxCleanApp.swift` command menus provide navigation shortcuts, Smart Scan shortcut, Full Disk Access shortcut, and a Help -> Keyboard Shortcuts window. App build/launch verifier passes. | Pass |
| Clean/uninstall/orphans UI | PureMac-derived app views and services exist; `script/check_clean_ui_static.sh` verifies at least 9 cleanup categories, sidebar category rendering, select/deselect controls, destructive confirmations, protected app hiding, orphan safety policy, remove actions, and Finder reveal affordances. | Pass |
| Disk analyzer | `DiskScanner`, mtime-based persistent SQLite scan cache in Application Support, squarified `TreemapLayout`, Analyzer Tree/Treemap modes, breadcrumb zoom, Finder reveal, guarded Move to Trash with `OperationLog`, and `fox analyze`; tests cover cache persistence behavior and treemap area/rows. | Pass |
| System monitor | `SystemMonitor`, `MonitorView`, menu bar metrics, and `fox status` now use host CPU ticks, VM memory stats, network counters, disk I/O throughput via IOKit storage statistics, process count, top processes via libproc, battery percent via IOKit Power Sources, disk free, public macOS thermal state, and health score. | Pass |
| Menu bar widget | `MenuBarController` uses AppKit `NSStatusItem` with a SwiftUI `NSPopover`, mini CPU chart, health/memory metrics, Smart Scan/Open/Monitor/Quit actions, and a Settings toggle. `app-responsive` passes after launch. | Pass |
| App responsiveness | `script/check_app_responsive.sh` verifies the launched app stays below the CPU threshold after startup; `script/check_app_runtime_static.sh` guards against reintroducing SwiftUI `MenuBarExtra` and missing local sidebar selection state. | Pass |
| Project purge | Toolkit project marker scanning in core/GUI/CLI; `ProjectPurgeView` groups artifacts by project, marks Recent artifacts, leaves Recent artifacts unchecked by default, and confirms before moving selected artifacts to Trash. Unit tests cover marker safety and `~/.config/foxclean/purge_paths` custom roots; CLI JSON smoke covers `fox purge --paths Sources`; `script/check_toolkit_ui_static.sh` guards the GUI behavior. | Pass |
| Installer cleanup | `InstallerScanner` scans Downloads/Desktop/Documents/Shared, Homebrew caches, Mail Downloads, iCloud Downloads, and common archive/installer extensions; `ScannedFile.source` labels origin in CLI JSON and GUI. `InstallerCleanupView` supports source filters, size/age sorting, auto-selects installers older than 30 days, and confirms before moving selected installers to Trash. `script/check_toolkit_ui_static.sh` guards the GUI behavior. | Pass |
| Optimize tasks | `Optimizer` exposes six independent task descriptors with ids, descriptions, admin flags, command previews, selected-task filtering, dry-run JSON, `~/.config/foxclean/optimize_whitelist`, skipped-task reports, safe non-admin execution paths, and native macOS admin prompt plumbing for whitelisted admin commands. `OptimizeView` has toggles plus Preview, Run Selected, Run All, progress, and result rows. `script/check_optimize_static.sh`, unit tests, and CLI JSON smokes cover the local behavior; real admin execution still requires explicit user authorization. | Pass |
| Shell completion/Raycast | `fox completion zsh`, `bash`, and `fish` are smoke checked; `scripts/raycast/*.sh` and setup script exist. | Pass |
| Local run action | `.codex/environments/environment.toml` points `Run` to `./script/build_and_run.sh` and `Verify` to `./script/verify_local.sh --launch`. | Pass |
| GUI URL scheme | `FoxCleanApp/Info.plist` registers `foxclean://`; `AppState.route(to:)` maps links to sections; `fox open monitor --print-url` is verified. | Pass |
| Touch ID sudo | `fox touchid status --json` reports real PAM state; `enable/disable --dry-run --json` are smoke checked; real `enable/disable` edits `/etc/pam.d/sudo_local` directly when root/writable or via `sudo`, with `.foxclean.bak` backup. Real authorization still requires user admin consent. | Partial |
| Localization | `FoxCleanApp/{en,vi,es,ja,zh-Hans,zh-Hant,ar}.lproj/Localizable.strings`, `Resources/Localizable.xcstrings`, and README files exist. `script/check_localization.sh` verifies all 7 locale files exist and have key parity with English; `script/check_swiftui_localization_keys.sh` verifies common SwiftUI user-visible literals have base localization keys. Missing non-primary translations fall back to English. | Pass |
| Accessibility | Sidebar, FDA footer, treemap, dashboard storage/scan gauges, optimizer result rows, menu bar chart, menu bar buttons, and status item have static labels/descriptions. Foxie and dashboard gauges honor macOS Reduce Motion, with an app-level "Reduce Foxie animations" toggle. `script/check_accessibility_static.sh` verifies required labels and reduce-motion hooks. Full VoiceOver/tab-order/contrast audit remains manual. | Partial |
| Telemetry-free | No telemetry SDK or endpoint is included; release QA tracks this. | Pass |
| Signed/notarized DMG | `script/package_release.sh` supports Developer ID signing plus notarization through Apple notary API key env vars or Apple ID app-specific password env vars. Actual notarization still requires credentials and network submission. | Blocked |
| Local unsigned DMG | `script/package_release.sh` creates `dist/FoxClean-1.0.0.dmg` and `dist/FoxClean-1.0.0.dmg.sha256` with an Applications symlink for drag-install; verifier runs `hdiutil verify`, `shasum -a 256 -c`, and checks the staging symlink. | Pass |
| External release preflight | `script/release_preflight.sh` reports signing, notarization, GitHub release, Homebrew, Full Disk Access, Touch ID, and manual QA readiness; `--strict` fails until external prerequisites are present. | Pass |
| Completion audit | `script/completion_audit.sh` maps the objective to concrete artifacts and checks verifier/release evidence; `--strict` fails while external blockers remain. | Pass |
| Universal binary | `script/package_release.sh` enforces arm64+x86_64 slices for `FoxClean`, embedded `fox`, and `FoxCleanCore.framework`; verifier records `lipo -archs`. | Pass |
| Homebrew publication | Draft formula exists at `homebrew/foxclean.rb` with concrete SHA-256 generated from the local DMG; publication still requires tap/PR access. | Blocked |
| Homebrew app CLI symlink target | `FoxClean.app/Contents/Resources/fox` is embedded with `FoxCleanCore.framework`; verifier executes embedded `fox --version`; `script/check_homebrew_formula.sh` verifies the cask URL, SHA-256, app stanza, binary stanza, zap paths, and Ruby syntax. | Pass |
| GitHub release/site/social launch | Public repo `https://github.com/tody-agent/foxclean` exists and `main` is pushed. `Build`, `Test`, `Lint`, and `Pages` passed on `main`; GitHub Pages is enabled at `https://tody-agent.github.io/foxclean/`; release workflow can create GitHub Release assets; `docs/release/LAUNCH_POSTS.md` contains HN/Product Hunt/X drafts. Actual release publication still needs signed/notarized artifacts. | Partial |
| Local verification gate | `script/verify_local.sh --launch --package` passed on 2026-05-17. | Pass |

## Verification Performed

Last command:

```sh
script/verify_local.sh --launch --package
```

Verified:

- `swift test` (21 tests)
- `./script/check_github_workflows.sh`
- `./script/check_pages_site.sh`
- `./script/check_homebrew_formula.sh`
- `./script/update_homebrew_cask_sha.sh`
- `./script/check_release_docs.sh`
- `./script/check_localization.sh`
- `./script/check_swiftui_localization_keys.sh`
- `./script/check_accessibility_static.sh`
- `./script/check_clean_ui_static.sh`
- `./script/check_app_runtime_static.sh`
- `./script/check_gui_static.sh`
- `./script/check_optimize_static.sh`
- `./script/check_toolkit_ui_static.sh`
- `xcodegen generate`
- `xcodebuild -scheme FoxCleanCore -destination 'platform=macOS' build`
- `xcodebuild -scheme FoxCleanCLI -destination 'platform=macOS' build`
- `xcodebuild -scheme FoxCleanApp -destination 'platform=macOS' build`
- `swift run fox --version`
- `swift run fox status`, including JSON field checks for
  `diskReadBytesPerSecond`, `diskWrittenBytesPerSecond`, and `thermalState`
- `swift run fox completion zsh`
- `swift run fox completion bash`
- `swift run fox completion fish`
- `swift run fox open monitor --print-url`
- `swift run fox touchid status --json`
- `swift run fox touchid enable --dry-run --json`
- `swift run fox touchid disable --dry-run --json`
- `swift run fox optimize`
- `swift run fox optimize --whitelist`
- `swift run fox scan apps --json`
- `swift run fox scan orphans --json`
- `swift run fox clean systemJunk`
- `swift run fox installer`
- `swift run fox purge --paths Sources`
- `swift run fox log show`
- `swift run fox analyze Sources --json`
- `./script/build_and_run.sh --verify`
- `dist/FoxClean.app/Contents/Resources/fox --version`
- `./script/check_app_responsive.sh FoxClean`
- `./script/check_telemetry_free.sh`
- `./script/package_release.sh`
- `./script/release_preflight.sh`
- `./script/completion_audit.sh`
- `test -L dist/release/Applications`
- `lipo -archs dist/release/FoxClean.app/Contents/MacOS/FoxClean`
- `lipo -archs dist/release/FoxClean.app/Contents/Resources/fox`
- `lipo -archs dist/release/FoxClean.app/Contents/Frameworks/FoxCleanCore.framework/Versions/A/FoxCleanCore`
- `hdiutil verify dist/FoxClean-1.0.0.dmg`
- `shasum -a 256 -c dist/FoxClean-1.0.0.dmg.sha256`
- `./script/completion_audit.sh`

Additional unit coverage includes `testBundledRuleResourcesDecode`, which
decodes `protected_apps.json`, `cleanup_hints.json`, `locations.json`, and
`conditions.json` through `FoxCleanCore`.

Evidence directory: `.build/verification/`.

## Not Complete Without External Inputs

The original objective asks for 100% completion. Local implementation and
verification are complete for the parts that can be built and tested in this
workspace. The full product release is not complete until these externally
controlled gates are done:

- Apple Developer ID signing certificate is installed.
- Notarization credentials are configured and a stapled DMG is produced.
- GitHub repository exists at `https://github.com/tody-agent/foxclean`; Pages
  is enabled at `https://tody-agent.github.io/foxclean/`; release publication
  still requires maintainer action after signing/notarization.
- Homebrew publication or PR access is available.
- macOS Full Disk Access and Touch ID prompts are manually granted/tested.
