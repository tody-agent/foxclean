# 📋 OpenSpec cho Dự án **FoxClean**

Vì FoxClean là dự án greenfield, tôi tổ chức OpenSpec thành **8 changes** tương ứng với 8 phases trong kế hoạch trước. Mỗi change là một folder hoàn chỉnh với `proposal.md`, `design.md`, `tasks.md`, và `specs/` delta. Dưới đây là cấu trúc đầy đủ.

## Cấu trúc thư mục OpenSpec đề xuất

```
openspec/
├── project.md                              # context cho AI agents
├── config.yaml
├── specs/                                  # source of truth (empty lúc đầu)
└── changes/
    ├── add-foxclean-foundation/            # Phase 0
    ├── add-scan-clean-core/                # Phase 1
    ├── add-gui-onboarding-mascot/          # Phase 2
    ├── add-clean-uninstall-orphans/        # Phase 3
    ├── add-disk-analyzer-system-monitor/   # Phase 4
    ├── add-purge-installer-optimize/       # Phase 5
    ├── add-cli-menubar-launchers/          # Phase 6
    └── add-polish-i18n-release/            # Phase 7
```

---

## 📄 `openspec/project.md`

```markdown
# FoxClean Project Context

## Tổng quan
FoxClean là ứng dụng dọn dẹp & tối ưu macOS miễn phí, mã nguồn mở (MIT).
Kết hợp UI native SwiftUI của PureMac với toolkit mạnh mẽ của Mole, thêm
mascot 🦊 Foxie làm dấu ấn riêng.

## Mục tiêu
- 100% miễn phí, không telemetry, không subscription
- GUI native macOS + CLI mạnh dùng chung 1 binary
- Mascot Foxie tạo trải nghiệm thân thiện
- Đa ngôn ngữ, tiếng Việt là primary

## Tech Stack
- **Ngôn ngữ**: Swift 5.9+
- **UI**: SwiftUI (macOS 13.0+)
- **CLI**: swift-argument-parser
- **Build**: Swift Package Manager + XcodeGen
- **Target**: macOS 13.0+ (Ventura), universal binary (Intel + Apple Silicon)
- **Distribution**: GitHub Releases (DMG signed/notarized) + Homebrew Cask

## Domain Conventions
- File paths sử dụng `URL`, không phải `String`
- Operations destructive đều phải qua `OperationLog`
- Tất cả async dùng `async/await` (không Combine)
- UI strings phải vào `Localizable.xcstrings`
- RFC 2119 cho requirements (MUST/SHALL/SHOULD/MAY)

## Cấu trúc Repo
- `FoxCleanApp/` - SwiftUI app target
- `FoxCleanCore/` - Swift Package, logic dùng chung
- `FoxCleanCLI/` - executable target
- `Tests/` - unit & integration tests
- `Resources/data/` - JSON rule databases

## Inspirations & Credits
- PureMac (MIT) bởi @momenbasel: scan engine architecture
- Mole (MIT) bởi @tw93: cleaning rules, CLI UX, app protection DB
```

---

# 🚀 Change 1: `add-foxclean-foundation`

## `openspec/changes/add-foxclean-foundation/proposal.md`

```markdown
# Proposal: FoxClean Foundation - Project Skeleton & CI

## Intent
Thiết lập bộ khung dự án FoxClean để team có thể bắt đầu phát triển:
repo, project files, CI/CD, dependency manager, và một build "Hello Foxie"
chạy được trên macOS 13+.

## Scope
**In scope:**
- Khởi tạo monorepo với SwiftPM + XcodeGen
- 3 targets: `FoxCleanApp` (GUI), `FoxCleanCore` (library), `FoxCleanCLI` (executable)
- GitHub Actions CI: build + lint + test trên macOS-14
- SwiftLint + swift-format config
- MIT License + NOTICE ghi credit PureMac & Mole
- Skeleton SwiftUI window hiển thị mascot Foxie placeholder
- README song ngữ vi-VN/en-US

**Out of scope:**
- Logic scan/clean (Change 2)
- UI features ngoài cửa sổ chính (Change 3)
- Notarization production (Change 8)

## Approach
- Dùng XcodeGen để generate `.xcodeproj` từ `project.yml` (tránh merge conflict)
- `FoxCleanCore` là Swift Package độc lập, được cả App và CLI import
- CI dùng GitHub-hosted runner `macos-14`, cache SwiftPM dependencies
- Foxie placeholder dùng SF Symbol `pawprint.fill` + animation rung lắc

## Dependencies
- Không có (đây là change đầu tiên)

## Risks
- XcodeGen có thể thay đổi format → pin version trong `Brewfile`
- macOS 13 minimum target loại trừ một số API mới → đã chấp nhận
```

## `openspec/changes/add-foxclean-foundation/design.md`

```markdown
# Design: FoxClean Foundation

## Technical Approach
Greenfield Swift monorepo. SwiftPM cho dependency, XcodeGen cho project file.
Tách rõ 3 layer: App (UI), Core (logic), CLI (terminal).

## Architecture Decisions

### Decision: XcodeGen thay vì commit .xcodeproj
- Tránh merge conflict trên file pbxproj
- Project structure thành code (project.yml) review được
- Dễ thêm/bớt file, target

### Decision: Swift Package cho Core thay vì static framework
- Build nhanh hơn, không cần Xcode để compile
- Có thể test bằng `swift test` trên CI không cần Xcode mở
- Dễ reuse cho CLI target

### Decision: macOS 13.0 minimum
- PureMac đã chứng minh 13.0+ là sweet spot
- Hỗ trợ NavigationSplitView, MenuBarExtra, Charts
- Bỏ 13.0 → cần Charts thì lên 14.0; cân nhắc lại ở Change 5

### Decision: swift-argument-parser cho CLI
- Apple official, type-safe, async support
- Auto-generate help, completion

## Repository Layout

\`\`\`
foxclean/
├── .github/workflows/
│   ├── build.yml
│   ├── test.yml
│   └── lint.yml
├── .swiftlint.yml
├── .swift-format
├── Brewfile                    # xcodegen, swiftlint
├── LICENSE                     # MIT
├── NOTICE                      # credits PureMac, Mole
├── README.md
├── README.vi.md
├── Package.swift               # cho FoxCleanCore
├── project.yml                 # XcodeGen
├── FoxCleanApp/
│   ├── FoxCleanApp.swift
│   ├── AppDelegate.swift
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   └── Localizable.xcstrings
│   ├── Features/
│   │   └── Placeholder/PlaceholderView.swift
│   └── Foxie/
│       └── FoxieView.swift
├── Sources/FoxCleanCore/
│   ├── Models/
│   │   └── FoxCleanError.swift
│   ├── Logging/
│   │   └── Logger.swift
│   └── Version.swift
├── Sources/FoxCleanCLI/
│   └── main.swift
└── Tests/
    └── FoxCleanCoreTests/
        └── VersionTests.swift
\`\`\`

## Foxie Mascot Architecture
\`\`\`swift
public enum FoxieMood {
    case idle, scanning, cleaning, success, error, sleeping, curious, dancing
}

public struct FoxieView: View {
    public var mood: FoxieMood
    public var size: CGFloat = 64
    public var body: some View { /* SF Symbol + animation per mood */ }
}
\`\`\`

## CI Pipeline
\`\`\`yaml
# .github/workflows/build.yml
on: [push, pull_request]
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: brew bundle
      - run: xcodegen generate
      - run: xcodebuild -scheme FoxCleanApp -destination 'platform=macOS' build
      - run: swift test --package-path .
\`\`\`

## File Changes (new)
- Tất cả file trên là mới — đây là greenfield init
```

## `openspec/changes/add-foxclean-foundation/tasks.md`

```markdown
# Tasks: FoxClean Foundation

## 1. Repository Bootstrap
- [ ] 1.1 Tạo repo GitHub `foxclean/foxclean` (MIT license)
- [ ] 1.2 Thêm `.gitignore` cho Xcode + SwiftPM + macOS
- [ ] 1.3 Tạo `LICENSE` (MIT) và `NOTICE` (credits PureMac, Mole)
- [ ] 1.4 Tạo `README.md` (en) và `README.vi.md` (vi) với badges placeholder

## 2. Project Skeleton
- [ ] 2.1 Tạo `Brewfile` (xcodegen, swiftlint, swift-format)
- [ ] 2.2 Viết `project.yml` cho XcodeGen với 3 targets
- [ ] 2.3 Viết `Package.swift` cho `FoxCleanCore`
- [ ] 2.4 Tạo `FoxCleanApp/FoxCleanApp.swift` với 1 cửa sổ tối thiểu
- [ ] 2.5 Tạo `Sources/FoxCleanCore/Version.swift` (chứa hằng số version)
- [ ] 2.6 Tạo `Sources/FoxCleanCLI/main.swift` in ra `fox v0.0.1`
- [ ] 2.7 Verify: `xcodegen generate && xcodebuild build` thành công

## 3. Foxie Placeholder
- [ ] 3.1 Tạo enum `FoxieMood` (8 cases) trong `FoxCleanCore`
- [ ] 3.2 Implement `FoxieView` dùng SF Symbol `pawprint.fill`
- [ ] 3.3 Thêm animation rung lắc cho mood `.idle` và `.dancing`
- [ ] 3.4 Hiển thị FoxieView trong cửa sổ chính

## 4. Tooling & Style
- [ ] 4.1 Thêm `.swiftlint.yml` (rules thông dụng)
- [ ] 4.2 Thêm `.swift-format` config
- [ ] 4.3 Thêm `.editorconfig`

## 5. CI/CD
- [ ] 5.1 Tạo `.github/workflows/build.yml` (xcodebuild)
- [ ] 5.2 Tạo `.github/workflows/test.yml` (swift test)
- [ ] 5.3 Tạo `.github/workflows/lint.yml` (swiftlint + swift-format check)
- [ ] 5.4 Verify: CI xanh trên PR mẫu

## 6. Documentation
- [ ] 6.1 Viết `CONTRIBUTING.md` (brief)
- [ ] 6.2 Viết `ARCHITECTURE.md` (mô tả 3 layers)
- [ ] 6.3 Update README với hướng dẫn `git clone && brew bundle && xcodegen && open`

## 7. Verification
- [ ] 7.1 Clone fresh, follow README, app chạy ≤ 5 phút
- [ ] 7.2 Foxie hiển thị và animation chạy
- [ ] 7.3 `fox --version` in ra phiên bản đúng
- [ ] 7.4 Tag release `v0.0.1-foundation`
```

## `openspec/changes/add-foxclean-foundation/specs/foundation/spec.md`

```markdown
# Delta for Foundation

## ADDED Requirements

### Requirement: Repository Structure
Dự án FoxClean MUST có cấu trúc monorepo với 3 Swift targets riêng biệt:
GUI app, core library, và CLI executable.

#### Scenario: Fresh clone build
- GIVEN một máy macOS 13+ với Xcode 15+ cài đặt
- WHEN người dùng `git clone`, chạy `brew bundle`, `xcodegen generate`
- THEN file `.xcodeproj` được sinh ra
- AND `xcodebuild -scheme FoxCleanApp build` thành công không lỗi
- AND `swift test --package-path .` chạy xong với 0 failure

#### Scenario: CLI binary runs
- GIVEN dự án đã build
- WHEN người dùng chạy `./fox --version`
- THEN stdout in ra chuỗi khớp regex `fox v\d+\.\d+\.\d+`

### Requirement: Foxie Mascot Foundation
Hệ thống MUST cung cấp một component SwiftUI có tên `FoxieView` với
ít nhất 8 trạng thái cảm xúc.

#### Scenario: Foxie hiển thị mood idle
- GIVEN ứng dụng vừa mở
- WHEN cửa sổ chính render
- THEN `FoxieView(mood: .idle)` hiển thị
- AND có animation lặp với chu kỳ 2-4 giây

#### Scenario: Foxie thay đổi mood
- GIVEN `FoxieView` đang hiển thị mood `.idle`
- WHEN binding mood đổi sang `.dancing`
- THEN animation chuyển sang animation dancing trong ≤ 300ms
- AND không bị flicker

### Requirement: Continuous Integration
Mỗi push hoặc PR lên nhánh chính MUST chạy build, test, và lint trên CI.

#### Scenario: PR mở triggers CI
- GIVEN một pull request mới
- WHEN PR được mở hoặc đẩy commit
- THEN GitHub Actions chạy 3 workflows: build, test, lint
- AND kết quả hiển thị trong PR checks trong ≤ 10 phút

#### Scenario: Lint failure block merge
- GIVEN một PR có vi phạm SwiftLint
- WHEN CI chạy
- THEN workflow lint FAIL
- AND PR check "lint" hiển thị đỏ

### Requirement: Licensing & Attribution
Dự án MUST tuân thủ MIT License và ghi rõ attribution cho các dự án nguồn.

#### Scenario: NOTICE file exists
- GIVEN repo đã được clone
- WHEN người dùng đọc `NOTICE`
- THEN file chứa credit cho PureMac (momenbasel) và Mole (tw93)
- AND ghi rõ rule database được adapted từ Mole MIT-licensed

#### Scenario: License file exists
- GIVEN repo
- WHEN người dùng đọc `LICENSE`
- THEN nội dung là chuẩn MIT License
- AND copyright holder là "FoxClean Contributors"
```

---

# 🧠 Change 2: `add-scan-clean-core`

## `proposal.md`

```markdown
# Proposal: Scan & Clean Core Engine + CLI

## Intent
Cung cấp engine quét và dọn dẹp file rác mạnh mẽ, an toàn, có thể test
qua CLI trước khi xây GUI. Port logic của PureMac và rule database của Mole.

## Scope
**In scope:**
- `PathFinder` với heuristic 10-level matching (port từ PureMac)
- `ScanEngine` async/await scan apps, orphans, system junk
- `CleaningEngine` với dry-run mặc định và OperationLog
- Rule database: `protected_apps.json`, `locations.json`, `conditions.json`, `cleanup_hints.json`
- CLI commands: `scan apps`, `scan orphans`, `clean <category> --dry-run`, `uninstall <app> --dry-run`
- `OperationLog` ghi mọi destructive op vào JSONL
- **Tính năng mới**: `log rollback <session-id>` khôi phục từ Trash

**Out of scope:**
- GUI (Change 3)
- Disk analyzer, system monitor (Change 4)
- Project purge, installer cleanup (Change 5)

## Approach
- Sửa code Swift của PureMac sang `FoxCleanCore` (refactor sync → async)
- Trích app protection list từ Mole bash scripts bằng script Python phụ trợ
- Mọi delete đi qua `FileOperator` có support 2 mode: trash (mặc định) hoặc permanent
- OperationLog dùng JSONL append-only, đường dẫn `~/Library/Logs/FoxClean/`

## Dependencies
- Change 1 (foundation)
```

## `design.md`

```markdown
# Design: Scan & Clean Core

## Module Layout (FoxCleanCore)
\`\`\`
Sources/FoxCleanCore/
├── Scanning/
│   ├── PathFinder.swift           # 10-level heuristic
│   ├── ScanEngine.swift           # async scan orchestration
│   ├── AppInfoFetcher.swift       # Spotlight + Info.plist
│   ├── StringNormalization.swift
│   ├── RuleDatabase.swift         # loads JSON rules
│   └── ProtectedApps.swift
├── Cleaning/
│   ├── CleaningEngine.swift
│   ├── FileOperator.swift         # safe delete with symlink check
│   └── ConfirmationPolicy.swift
├── Logging/
│   ├── OperationLog.swift         # JSONL append
│   ├── OperationEntry.swift
│   └── RollbackEngine.swift       # restore from Trash
├── FullDiskAccess/
│   └── FullDiskAccessManager.swift
└── Models/
    ├── ScannedApp.swift
    ├── ScannedFile.swift
    ├── ScanCategory.swift
    └── FoxCleanError.swift
\`\`\`

## Key Algorithms

### PathFinder 10-Level Matching
Mỗi candidate file được chấm điểm theo 10 dấu hiệu, weighted:
1. Bundle identifier exact match (weight 10)
2. Bundle identifier prefix (8)
3. Team identifier (7)
4. Entitlements match (6)
5. Company/developer name (5)
6. Executable name (4)
7. CFBundleName (4)
8. Spotlight metadata kMDItemCFBundleIdentifier (3)
9. Container directory naming (3)
10. Substring fuzzy (2)

Sensitivity threshold:
- Strict: total ≥ 18
- Enhanced: total ≥ 12  
- Deep: total ≥ 7

### OperationLog Schema (JSONL)
\`\`\`json
{
  "ts": "2026-05-16T10:23:45Z",
  "session_id": "01HXY8...",
  "action": "trash",
  "src_path": "/Users/x/Library/Caches/com.foo/Cache.db",
  "trashed_to": "/Users/x/.Trash/Cache.db",
  "size_bytes": 1048576,
  "dry_run": false,
  "category": "user_cache",
  "app_bundle_id": "com.foo.bar"
}
\`\`\`

### Rollback Engine
- Đọc tất cả entry của một `session_id`
- Với mỗi entry có `trashed_to`, dùng `FileManager.moveItem` từ Trash trở lại `src_path`
- Nếu file gốc đã có (user tạo lại), tạo bản `.restored-<timestamp>`

## Decisions

### Decision: JSONL không phải JSON array
- Append-only, an toàn nếu app crash giữa chừng
- `jq` parse được từng dòng
- Mole dùng plain log file, ta nâng cấp lên structured

### Decision: Mặc định move-to-Trash, không permanent delete
- An toàn hơn Mole (Mole có cờ nhưng dễ permanent)
- User có thể restore qua Finder
- `--permanent` flag để xóa thẳng (vd CI)

### Decision: Rule database dạng JSON declarative
- Bash script của Mole khó parse, khó test
- JSON dễ validate bằng schema
- Có thể auto-sync từ Mole repo bằng script `tools/sync-mole-rules.py`

## CLI Surface
\`\`\`
fox scan apps [--json]
fox scan orphans [--json]
fox scan junk [--json]
fox clean <category> [--dry-run] [--permanent] [--debug]
fox uninstall <bundle-id-or-name> [--sensitivity strict|enhanced|deep] [--dry-run]
fox log show [--session=<id>] [--last=<n>]
fox log rollback <session-id>
\`\`\`
```

## `tasks.md`

```markdown
# Tasks: Scan & Clean Core

## 1. Rule Database
- [ ] 1.1 Viết script `tools/extract_mole_rules.py` parse `lib/core/app_protection.sh` → `protected_apps.json`
- [ ] 1.2 Viết script `tools/extract_mole_hints.py` parse `lib/clean/hints.sh` → `cleanup_hints.json`
- [ ] 1.3 Port `Locations.swift` của PureMac → `locations.json` + Swift loader
- [ ] 1.4 Port `Conditions.swift` của PureMac → `conditions.json` + Swift loader
- [ ] 1.5 JSON Schema validation cho 4 file trên
- [ ] 1.6 Unit test: load 4 file thành công, count entries

## 2. Models & Errors
- [ ] 2.1 `ScannedApp` struct với bundle ID, paths, size, install date
- [ ] 2.2 `ScannedFile` struct với URL, size, category, confidence
- [ ] 2.3 `ScanCategory` enum (10 cases)
- [ ] 2.4 `FoxCleanError` typed errors

## 3. PathFinder
- [ ] 3.1 Port `AppPathFinder.swift` từ PureMac, refactor sang Swift 5.9
- [ ] 3.2 Implement 10-level scoring algorithm
- [ ] 3.3 Sensitivity threshold logic
- [ ] 3.4 Symlink resolution + path validation
- [ ] 3.5 Unit tests với 20+ fixture apps

## 4. ScanEngine
- [ ] 4.1 `scanInstalledApps()` async, dùng FileManager + Spotlight
- [ ] 4.2 `scanOrphans()` so sánh ~/Library vs installed apps
- [ ] 4.3 `scanSystemJunk()` với category breakdown
- [ ] 4.4 Progress reporting qua AsyncStream
- [ ] 4.5 Cancellation support
- [ ] 4.6 Unit tests với mock FileManager

## 5. FileOperator & CleaningEngine
- [ ] 5.1 `FileOperator.trash(url)` dùng NSWorkspace.recycle
- [ ] 5.2 `FileOperator.permanentDelete(url)` với double confirmation
- [ ] 5.3 Symlink attack prevention: resolve → validate parent
- [ ] 5.4 `CleaningEngine.clean(items, dryRun:)` orchestrator
- [ ] 5.5 Hooks `willDelete`, `didDelete` cho UI
- [ ] 5.6 Unit tests với temp directory

## 6. OperationLog
- [ ] 6.1 `OperationEntry` Codable struct
- [ ] 6.2 `OperationLog.append(_:)` JSONL append-only
- [ ] 6.3 `OperationLog.sessions()` list session IDs
- [ ] 6.4 `OperationLog.entries(forSession:)` query
- [ ] 6.5 Log rotation (7 ngày)
- [ ] 6.6 `MO_NO_OPLOG`-equivalent env var `FOX_NO_OPLOG`

## 7. RollbackEngine
- [ ] 7.1 `RollbackEngine.rollback(sessionId:)` async
- [ ] 7.2 Conflict resolution: rename existing với suffix `.restored-<ts>`
- [ ] 7.3 Trash path discovery (~/.Trash + Volume Trash)
- [ ] 7.4 Unit tests rollback round-trip

## 8. FullDiskAccess
- [ ] 8.1 Port `FullDiskAccessManager.swift` từ PureMac
- [ ] 8.2 `triggerRegistration()` chạm tới TCC-protected paths
- [ ] 8.3 `hasFullDiskAccess()` check
- [ ] 8.4 `openSystemSettings()` deep link

## 9. CLI
- [ ] 9.1 Setup `swift-argument-parser` trong FoxCleanCLI
- [ ] 9.2 Command `scan apps` với `--json`
- [ ] 9.3 Command `scan orphans`
- [ ] 9.4 Command `scan junk`
- [ ] 9.5 Command `clean <category>` với flags
- [ ] 9.6 Command `uninstall <app>`
- [ ] 9.7 Command `log show`
- [ ] 9.8 Command `log rollback <session>`
- [ ] 9.9 Pretty-print với colors khi TTY, JSON khi piped

## 10. Verification
- [ ] 10.1 E2E test: cài app test → uninstall dry-run → kiểm tra output
- [ ] 10.2 E2E test: clean với log → rollback → file phục hồi
- [ ] 10.3 Coverage ≥ 70% cho FoxCleanCore
- [ ] 10.4 Tag `v0.1.0-core`
```

## `specs/scanning/spec.md`

```markdown
# Delta for Scanning

## ADDED Requirements

### Requirement: App Discovery
Hệ thống SHALL phát hiện tất cả ứng dụng đã cài đặt từ `/Applications`,
`~/Applications`, và `/System/Applications`.

#### Scenario: List installed apps
- GIVEN máy có ≥ 5 ứng dụng cài đặt
- WHEN người dùng chạy `fox scan apps`
- THEN stdout liệt kê các app với bundle ID, version, size
- AND các app hệ thống Apple được flag `protected: true`

#### Scenario: System apps protection
- GIVEN ứng dụng `Safari.app` ở `/System/Applications`
- WHEN scan trả về kết quả
- THEN Safari có `protected: true`
- AND không thể bị uninstall qua CLI (lệnh trả lỗi)

### Requirement: Heuristic Path Matching
Hệ thống MUST gán điểm tin cậy 0-30 cho mỗi file ứng viên dựa trên
10 tiêu chí matching đã định nghĩa.

#### Scenario: High-confidence match
- GIVEN app `com.example.foo` có bundle ID đúng, team ID đúng
- WHEN PathFinder scan thư mục `~/Library/Caches`
- THEN file `~/Library/Caches/com.example.foo/` có score ≥ 18
- AND được phân loại "Strict match"

#### Scenario: Low-confidence không match ở Strict
- GIVEN file `~/Library/Logs/foo.log` chỉ có substring "foo" với app
- WHEN sensitivity là `strict`
- THEN file KHÔNG được liệt kê
- WHEN sensitivity là `deep`
- THEN file ĐƯỢC liệt kê với confidence "Low"

### Requirement: Orphan Detection
Hệ thống SHALL phát hiện các file ở `~/Library` không thuộc app nào đang cài.

#### Scenario: Detect orphan
- GIVEN `~/Library/Caches/com.removed.app/` tồn tại nhưng app không cài
- WHEN người dùng chạy `fox scan orphans`
- THEN folder `com.removed.app` xuất hiện trong kết quả
- AND có total size hiển thị

## ADDED Requirements (cont.)

### Requirement: Async Cancellation
Mọi scan operation SHALL hỗ trợ hủy bằng Task cancellation.

#### Scenario: Cancel mid-scan
- GIVEN scan đang chạy được 30%
- WHEN caller gọi `task.cancel()`
- THEN scan dừng trong ≤ 500ms
- AND trả về `CancellationError`
- AND không có file leak handles
```

## `specs/cleaning/spec.md`

```markdown
# Delta for Cleaning

## ADDED Requirements

### Requirement: Dry-Run Default
Mọi lệnh destructive trên CLI MUST chạy ở chế độ dry-run nếu không có
flag confirm tường minh.

#### Scenario: Default is dry-run
- GIVEN người dùng chạy `fox clean system`
- WHEN command thực thi
- THEN không có file nào bị xóa
- AND stdout hiển thị `[DRY-RUN]` prefix
- AND output liệt kê file sẽ bị xóa với size

#### Scenario: Explicit confirm
- GIVEN người dùng chạy `fox clean system --confirm`
- WHEN command thực thi
- THEN files thực sự được move vào Trash
- AND mỗi file được log vào OperationLog

### Requirement: Trash by Default
Hệ thống MUST move files vào Trash thay vì xóa vĩnh viễn, trừ khi
có flag `--permanent`.

#### Scenario: Trash mode
- GIVEN một file `/tmp/foo.cache` được chọn xóa
- WHEN cleaning chạy không có `--permanent`
- THEN file xuất hiện trong `~/.Trash/`
- AND có thể restore qua Finder

#### Scenario: Permanent mode requires double confirm
- GIVEN người dùng chạy với `--permanent` trong terminal interactive
- WHEN command bắt đầu
- THEN hiển thị prompt cảnh báo
- AND yêu cầu gõ `DELETE` để xác nhận

### Requirement: Symlink Attack Prevention
Hệ thống MUST resolve và validate đường dẫn trước mọi delete để chặn
symlink traversal attacks.

#### Scenario: Symlink trỏ ra ngoài bị từ chối
- GIVEN file `~/Library/Caches/com.foo/leak → /Users/x/Documents/secret.pdf`
- WHEN cleaning trying delete `~/Library/Caches/com.foo/leak`
- THEN system resolve symlink, phát hiện target ngoài `~/Library/Caches`
- AND skip với log warning `symlink_outside_safe_root`
- AND `secret.pdf` không bị động đến

### Requirement: Operation Logging
Mọi delete operation MUST được ghi vào file JSONL append-only.

#### Scenario: Log entry shape
- GIVEN một clean operation xóa 5 files
- WHEN session kết thúc
- THEN file `~/Library/Logs/FoxClean/operations-YYYYMMDD.jsonl` có 5 dòng
- AND mỗi dòng là JSON hợp lệ với fields: ts, session_id, action, src_path, size_bytes
- AND tất cả 5 dòng có cùng session_id

#### Scenario: Disable logging
- GIVEN env var `FOX_NO_OPLOG=1`
- WHEN cleaning chạy
- THEN không có entry nào được ghi
- AND command vẫn chạy bình thường

### Requirement: Rollback from Trash
Hệ thống MUST khôi phục files từ Trash về vị trí gốc dựa trên session ID.

#### Scenario: Successful rollback
- GIVEN session `01HXY8...` đã xóa 3 files vào Trash
- WHEN người dùng chạy `fox log rollback 01HXY8...`
- THEN 3 files quay về vị trí gốc
- AND CLI in `Restored 3 files`

#### Scenario: Conflict on rollback
- GIVEN file gốc `~/foo.txt` đã được tạo lại sau khi xóa
- WHEN rollback chạy
- THEN file từ Trash được restore với tên `foo.txt.restored-<timestamp>`
- AND CLI cảnh báo conflict
```

---

# 🎨 Change 3: `add-gui-onboarding-mascot`

## `proposal.md`

```markdown
# Proposal: GUI Shell, Onboarding Flow & Foxie Animations

## Intent
Xây dựng GUI shell với SwiftUI: cửa sổ chính, sidebar, dashboard, onboarding 
flow hướng dẫn Full Disk Access, và hệ thống mascot Foxie có hồn.

## Scope
**In scope:**
- Onboarding 3 bước (welcome, FDA, ready)
- MainWindow với NavigationSplitView (sidebar 10 mục)
- Dashboard cards: Disk Space, Last Scan, Foxie Says, Quick Actions
- FoxieView nâng cấp: 8 mood, Lottie hoặc SF Symbol composite animation
- ThemeManager: light/dark/auto + accent color
- Settings window cơ bản
- Localizable.xcstrings với en, vi

**Out of scope:**
- Cleaning/uninstall views chi tiết (Change 4)
- Disk analyzer (Change 4)
- Menu bar app (Change 7)

## Approach
- Map sidebar items → SwiftUI Views placeholder, fill ở Changes sau
- Dashboard gọi `FoxCleanCore` qua AppState đã có ở Change 2
- Foxie dùng `TimelineView` cho animation deterministic
- Onboarding skip được trong dev mode (UserDefaults flag)

## Dependencies
- Change 1, Change 2
```

## `design.md`

```markdown
# Design: GUI Shell + Mascot

## Feature Module Layout
\`\`\`
FoxCleanApp/Features/
├── Onboarding/
│   ├── OnboardingView.swift
│   ├── WelcomeStep.swift
│   ├── FullDiskAccessStep.swift
│   ├── ReadyStep.swift
│   └── OnboardingState.swift
├── Main/
│   ├── MainWindow.swift
│   ├── SidebarView.swift
│   └── SidebarItem.swift
├── Dashboard/
│   ├── DashboardView.swift
│   ├── DiskSpaceCard.swift
│   ├── LastScanCard.swift
│   ├── FoxieSaysCard.swift
│   └── QuickActionsCard.swift
└── Settings/
    └── SettingsView.swift
\`\`\`

## AppState
\`\`\`swift
@MainActor final class AppState: ObservableObject {
    @Published var selectedSidebar: SidebarItem = .dashboard
    @Published var foxieMood: FoxieMood = .idle
    @Published var lastScanResult: ScanResult?
    @Published var diskUsage: DiskUsage?
    let scanEngine: ScanEngine
    let cleaningEngine: CleaningEngine
    let operationLog: OperationLog
}
\`\`\`

## Foxie Mood Reactivity
\`\`\`
Action → Foxie Mood
─────────────────────────
App launch       → .idle
Scan start       → .scanning (đào hang)
Scan complete    → .success (nháy mắt)
Clean start      → .cleaning (cầm chổi)
Clean complete   → .sleeping (ngủ trên đống rác)
Error            → .curious (nghiêng đầu)
Empty state      → .idle
Easter egg (F×5) → .dancing
\`\`\`

## Sidebar Items (placeholder cho Changes sau)
1. 🏠 Dashboard
2. ✨ Smart Scan
3. 🧹 Clean (Change 4)
4. 🗑️ Uninstall (Change 4)
5. 👻 Orphans (Change 4)
6. 📂 Project Purge (Change 6)
7. 💿 Installer Cleanup (Change 6)
8. 🥧 Disk Analyzer (Change 5)
9. ⚡ Optimize (Change 6)
10. 📊 Monitor (Change 5)

Settings tách riêng (Cmd+,)

## Onboarding Logic
\`\`\`
state = .welcome
  ↓ Next
state = .fullDiskAccess
  ↓ if hasFDA() == true → .ready
  ↓ else show "Open Settings" button
state = .ready
  ↓ Finish → @AppStorage("OnboardingComplete") = true
\`\`\`

## Decisions

### Decision: Lottie optional, SF Symbols default
- Lottie thêm ~2MB binary, có thể đẹp hơn
- MVP dùng SF Symbol + manual animation
- Plug-in Lottie sau khi có designer (V2)

### Decision: Skip onboarding bằng `FOX_SKIP_ONBOARDING=1`
- Hữu ích cho dev và E2E tests
```

## `tasks.md`

```markdown
# Tasks: GUI Shell + Mascot

## 1. AppState & Theme
- [ ] 1.1 Tạo `AppState` ObservableObject inject xuống environment
- [ ] 1.2 `ThemeManager` (light/dark/auto + 5 accent colors)
- [ ] 1.3 Settings UserDefaults keys (theme, accent, foxie_reduce)

## 2. Onboarding
- [ ] 2.1 `OnboardingView` với 3 step TabView style
- [ ] 2.2 `WelcomeStep`: Foxie vẫy tay + welcome copy
- [ ] 2.3 `FullDiskAccessStep`: button "Open Settings" → dùng FullDiskAccessManager
- [ ] 2.4 `ReadyStep`: Foxie nháy mắt + "Let's go" button
- [ ] 2.5 Persist `OnboardingComplete` qua `@AppStorage`
- [ ] 2.6 Dev skip qua env var `FOX_SKIP_ONBOARDING`

## 3. MainWindow
- [ ] 3.1 `MainWindow` với `NavigationSplitView`
- [ ] 3.2 `SidebarView` với 10 items + icons
- [ ] 3.3 Toolbar: app icon trái, "Smart Scan" button, Foxie ở góc phải
- [ ] 3.4 Detail view router theo `selectedSidebar`

## 4. Dashboard
- [ ] 4.1 `DashboardView` grid 2x2
- [ ] 4.2 `DiskSpaceCard` circular progress (statfs)
- [ ] 4.3 `LastScanCard` đọc OperationLog
- [ ] 4.4 `FoxieSaysCard` heuristic gợi ý (vd: "Bạn có 12GB Chrome cache")
- [ ] 4.5 `QuickActionsCard` 4 nút lớn

## 5. Foxie V2
- [ ] 5.1 Implement 8 mood animations với TimelineView
- [ ] 5.2 Sound effects nhẹ (optional, default off)
- [ ] 5.3 Hover/click interactions
- [ ] 5.4 Easter egg: bấm F 5 lần → mood `.dancing`
- [ ] 5.5 Settings toggle "Reduce Foxie animations"

## 6. Settings Window
- [ ] 6.1 `SettingsView` với Form
- [ ] 6.2 Tab General: theme, accent, Foxie reduce
- [ ] 6.3 Tab Privacy: Full Disk Access status + open Settings
- [ ] 6.4 Tab About: version, credits PureMac/Mole

## 7. Localization
- [ ] 7.1 Tạo `Localizable.xcstrings`
- [ ] 7.2 Add keys cho toàn bộ UI hiện có (~50 strings)
- [ ] 7.3 Dịch tiếng Việt
- [ ] 7.4 Dịch tiếng Anh

## 8. Verification
- [ ] 8.1 UI snapshot tests cho onboarding (3 step)
- [ ] 8.2 UI snapshot tests cho dashboard
- [ ] 8.3 Manual test: full onboarding flow đến main window ≤ 30s
- [ ] 8.4 Foxie animations smooth 60fps
- [ ] 8.5 Tag `v0.2.0-gui`
```

## `specs/gui/spec.md`

```markdown
# Delta for GUI

## ADDED Requirements

### Requirement: First-Launch Onboarding
Khi mở app lần đầu, người dùng MUST trải qua flow onboarding gồm 3 bước
trước khi vào MainWindow.

#### Scenario: Onboarding hiển thị
- GIVEN `OnboardingComplete` chưa được set
- WHEN app mở
- THEN OnboardingView hiển thị, không phải MainWindow
- AND step đầu tiên là Welcome với Foxie

#### Scenario: Hoàn thành onboarding
- GIVEN người dùng đã đi qua 3 step
- WHEN bấm "Let's go" ở ReadyStep
- THEN `OnboardingComplete = true` được lưu
- AND MainWindow hiển thị
- AND lần mở app sau, MainWindow hiển thị ngay

#### Scenario: Yêu cầu Full Disk Access
- GIVEN ở step FullDiskAccess
- WHEN `hasFullDiskAccess()` = false
- THEN button "Open System Settings" enabled
- AND step Next button disabled (hoặc warning)

### Requirement: Sidebar Navigation
MainWindow MUST có sidebar với ít nhất 10 navigation items, mỗi item có
icon và label, hỗ trợ phím tắt Cmd+1..Cmd+9.

#### Scenario: Chọn sidebar
- GIVEN MainWindow đang ở Dashboard
- WHEN người dùng click "Clean" trong sidebar
- THEN detail view render `CleanView`
- AND `AppState.selectedSidebar = .clean`

#### Scenario: Keyboard shortcut
- GIVEN MainWindow đang focus
- WHEN người dùng nhấn Cmd+2
- THEN sidebar chuyển sang item thứ 2

### Requirement: Dashboard Cards
DashboardView MUST hiển thị ít nhất 4 cards: disk space, last scan,
Foxie suggestions, quick actions.

#### Scenario: Disk space card
- GIVEN Dashboard đang hiển thị
- WHEN card render
- THEN hiển thị tổng disk, dung lượng đã dùng, % dùng
- AND circular progress visualization

#### Scenario: Foxie suggestion
- GIVEN Dashboard sau khi quét xong
- WHEN có category > 5GB
- THEN FoxieSaysCard hiển thị gợi ý cụ thể với category đó
- AND có button "Show me"

### Requirement: Foxie Mood Reactivity
FoxieView MUST phản ứng tự động theo trạng thái ứng dụng (idle, scanning,
cleaning, success, error, sleeping, curious, dancing).

#### Scenario: Scan triggers scanning mood
- GIVEN Foxie ở mood `.idle`
- WHEN ScanEngine bắt đầu scan
- THEN Foxie chuyển sang mood `.scanning` trong ≤ 200ms
- AND giữ mood này đến khi scan xong

#### Scenario: Easter egg dancing
- GIVEN Foxie ở mood `.idle`
- WHEN người dùng nhấn phím F 5 lần liên tiếp trong 2 giây
- THEN Foxie chuyển sang mood `.dancing` trong 5 giây
- AND quay về `.idle`

### Requirement: Theme System
Ứng dụng MUST hỗ trợ Light, Dark, và Auto theme, áp dụng ngay lập tức.

#### Scenario: Switch theme
- GIVEN theme đang là Light
- WHEN người dùng đổi sang Dark trong Settings
- THEN toàn bộ UI chuyển sang dark trong ≤ 100ms
- AND lựa chọn persist qua launches

### Requirement: Localization
Ứng dụng SHALL hỗ trợ ít nhất 2 ngôn ngữ (vi, en) tại Change này; cấu trúc
phải dễ dàng mở rộng.

#### Scenario: Vietnamese UI
- GIVEN macOS preferred language là `vi`
- WHEN app mở
- THEN tất cả UI strings hiển thị tiếng Việt
- AND không có placeholder string `LOCALIZED_KEY_*` lộ ra
```

---

# 🧹 Change 4: `add-clean-uninstall-orphans`

## `proposal.md`

```markdown
# Proposal: Clean / Uninstall / Orphans Views

## Intent
Ba feature cốt lõi của user-facing app: dọn rác theo category, gỡ ứng dụng
hoàn chỉnh, và tìm file orphan. UI master-detail chuẩn macOS.

## Scope
**In scope:**
- `CleanView` với 9 categories, master-detail, multi-select
- `UninstallView` với app list, sensitivity slider, file panel
- `OrphansView` với scan + cleanup
- Confirmation dialogs với Foxie animations
- Progress UI khi đang scan/clean
- Search & filter trên cả 3 views

**Out of scope:**
- Disk analyzer (Change 5)
- Project purge (Change 6)

## Dependencies
- Change 2 (Core), Change 3 (GUI Shell)
```

## `design.md`

```markdown
# Design: Clean / Uninstall / Orphans

## Module Layout
\`\`\`
FoxCleanApp/Features/
├── Clean/
│   ├── CleanView.swift
│   ├── CategoryList.swift
│   ├── FileTable.swift
│   ├── CleanToolbar.swift
│   └── CleanViewModel.swift
├── Uninstall/
│   ├── UninstallView.swift
│   ├── AppList.swift
│   ├── AppDetailPanel.swift
│   ├── SensitivitySlider.swift
│   └── UninstallViewModel.swift
└── Orphans/
    ├── OrphansView.swift
    └── OrphansViewModel.swift
\`\`\`

## Categories (CleanView)
1. System Junk
2. User Cache
3. AI Apps (Ollama, LM Studio)
4. Mail Attachments
5. Trash Bins
6. Large & Old Files (> 100MB hoặc > 1 năm)
7. Purgeable Space
8. Xcode Junk (DerivedData, Archives, Simulators)
9. Brew Cache

## Confirmation Dialog Tree
\`\`\`
User clicks "Clean"
       │
       ├─ Total < 1 GB → confirm bằng Cmd+Return không hỏi
       ├─ Total < 5 GB → dialog đơn giản, Foxie smile
       └─ Total ≥ 5 GB → dialog cảnh báo, Foxie worried
                          + checkbox "Move to Trash (recommended)"
\`\`\`

## File Table Design
Cột: ☐ Checkbox | Name | Size | Path | Last Modified
- Sort by size descending mặc định
- Multi-select Cmd+click, Shift+click
- Right-click: Open in Finder, Reveal, Add to Whitelist

## Decisions

### Decision: Master-detail thay vì single list
- Đồng nhất với PureMac UI
- Cho phép scan category này khi user xem category khác
- Memory hiệu quả

### Decision: Sensitivity slider thay vì dropdown
- Cảm giác trực quan hơn
- 3 nấc: Strict (xanh) → Enhanced (vàng) → Deep (cam)
```

## `tasks.md`

```markdown
# Tasks: Clean / Uninstall / Orphans

## 1. CleanView
- [ ] 1.1 Layout master-detail với HSplitView
- [ ] 1.2 `CategoryList` 9 categories với badge count + size
- [ ] 1.3 `FileTable` SwiftUI Table với 5 cột, multi-select
- [ ] 1.4 Bottom bar: "Selected: X GB" + "Clean" button
- [ ] 1.5 Search field filter file by name/path
- [ ] 1.6 Foxie scanning animation overlay khi scan

## 2. Clean Confirmation
- [ ] 2.1 `CleanConfirmationDialog` view
- [ ] 2.2 Size-based tier (< 1GB, < 5GB, ≥ 5GB)
- [ ] 2.3 "Move to Trash" / "Delete permanently" toggle
- [ ] 2.4 "Don't ask again under 1GB" preference

## 3. UninstallView
- [ ] 3.1 `AppList` sortable table với icon, name, size, install date
- [ ] 3.2 Filter: hide system apps, hide protected apps
- [ ] 3.3 `AppDetailPanel` hiển thị 8 categories liên quan
- [ ] 3.4 `SensitivitySlider` 3 nấc với màu
- [ ] 3.5 "Uninstall Completely" button

## 4. OrphansView
- [ ] 4.1 Bảng orphan files với guess "from app"
- [ ] 4.2 "Select All" / "Smart Select" (large + old)
- [ ] 4.3 1-click cleanup button

## 5. Progress UI
- [ ] 5.1 `ScanProgressView` overlay với % + Foxie scanning
- [ ] 5.2 `CleanProgressView` với file đang xóa
- [ ] 5.3 `CleanResultSheet` "Đã giải phóng X GB" + Foxie success

## 6. ViewModels
- [ ] 6.1 `CleanViewModel` bind tới `ScanEngine` + `CleaningEngine`
- [ ] 6.2 `UninstallViewModel` với sensitivity logic
- [ ] 6.3 `OrphansViewModel`
- [ ] 6.4 Cancellation handling đúng

## 7. Verification
- [ ] 7.1 E2E: clean Xcode junk dry-run → kết quả khớp CLI
- [ ] 7.2 E2E: uninstall test app → verify operationLog
- [ ] 7.3 UI snapshot tests
- [ ] 7.4 Tag `v0.3.0-clean`
```

## `specs/clean-ui/spec.md`

```markdown
# Delta for Clean UI

## ADDED Requirements

### Requirement: Clean Category Browser
CleanView MUST hiển thị ít nhất 9 categories với badge tổng size,
mỗi category có thể chọn để scan riêng biệt.

#### Scenario: Smart Scan
- GIVEN người dùng ở CleanView
- WHEN bấm "Smart Scan" trên toolbar
- THEN tất cả 9 categories được scan song song
- AND badge size update khi từng category xong
- AND Foxie hiển thị mood `.scanning`

#### Scenario: Scan single category
- GIVEN CleanView đã mở
- WHEN người dùng click "Xcode Junk" category
- THEN chỉ category này scan, các category khác giữ trạng thái cũ
- AND file table phải hiển thị files

### Requirement: Multi-File Selection
File table MUST hỗ trợ multi-select Cmd+click, Shift+click, Cmd+A.

#### Scenario: Select range
- GIVEN file table có 100 rows
- WHEN người dùng click row 1, Shift+click row 50
- THEN 50 rows được select
- AND bottom bar update "Selected: X GB"

#### Scenario: Select all and clean
- GIVEN file table đang hiển thị
- WHEN người dùng nhấn Cmd+A
- THEN tất cả rows được select
- WHEN bấm "Clean"
- THEN confirmation dialog mở với tổng size

### Requirement: Size-Tiered Confirmation
Hệ thống MUST hiển thị level cảnh báo khác nhau theo tổng size cần xóa.

#### Scenario: Small clean không hỏi
- GIVEN người dùng có pref "Don't ask under 1GB"
- WHEN clean 800MB
- THEN không hiển thị dialog, clean ngay
- AND Foxie show success

#### Scenario: Large clean strong warning
- GIVEN tổng selected = 12 GB
- WHEN bấm "Clean"
- THEN dialog với Foxie worried + đếm số file
- AND require checkbox "I understand"
- AND nút "Confirm" disabled đến khi checkbox checked

## ADDED Requirements (Uninstall)

### Requirement: App List with Protection
UninstallView SHALL hiển thị các ứng dụng cài đặt, ẩn (hoặc lock) các
app trong protected list.

#### Scenario: System apps locked
- GIVEN UninstallView mở
- WHEN list render
- THEN Safari, Mail, Messages (Apple system apps) không xuất hiện
- WHEN người dùng bật toggle "Show protected"
- THEN xuất hiện nhưng có badge 🔒 và button Uninstall disabled

### Requirement: Sensitivity Slider
UninstallView MUST có slider 3 nấc (Strict / Enhanced / Deep), khi đổi
sẽ update file panel phải.

#### Scenario: Đổi sensitivity
- GIVEN app `Spotify` chọn, sensitivity `Strict`, hiển thị 12 files
- WHEN người dùng kéo sang `Deep`
- THEN file panel update trong ≤ 1 giây
- AND hiển thị 40+ files (nhiều hơn)
- AND files mới có badge "Medium/Low confidence"

## ADDED Requirements (Orphans)

### Requirement: Orphan Detection UI
OrphansView MUST tự động quét khi mở và hiển thị file orphan kèm best-guess
app name.

#### Scenario: Mở Orphans tab
- GIVEN người dùng vừa click sidebar "Orphans"
- WHEN view xuất hiện
- THEN auto-trigger scan
- AND Foxie scanning animation
- AND list update progressive khi tìm thấy
```

---

# 📊 Change 5: `add-disk-analyzer-system-monitor`

## `proposal.md`

```markdown
# Proposal: Disk Analyzer + System Monitor

## Intent
Hai feature "wow" của Mole, làm đẹp hơn với GUI: phân tích dung lượng disk
trực quan kiểu treemap, và dashboard hệ thống real-time có menu bar widget.

## Scope
**In scope:**
- `DiskAnalyzerView` 2 modes: Tree + Treemap (squarified algorithm)
- Scan cache SQLite tăng tốc lần sau
- Top 10 largest files panel
- Right-click context menu (Open, Reveal, Trash, Whitelist)
- `SystemMonitorView` real-time CPU, RAM, Disk I/O, Network, Battery, Temp
- Health score 0-100 algorithm
- Process table top 5 CPU + Memory
- SwiftUI Charts cho 60s history
- Menu bar widget với mini chart (NSStatusItem + MenuBarExtra)

**Out of scope:**
- External drive analyzer optimization (V1.1)
- GPU monitoring (cần Metal performance counters phức tạp)
```

## `design.md`

```markdown
# Design: Disk Analyzer + System Monitor

## Module Layout
\`\`\`
Sources/FoxCleanCore/
├── Analyzing/
│   ├── DiskScanner.swift       # parallel BFS
│   ├── ScanCache.swift         # SQLite cache
│   ├── TreemapLayout.swift     # squarified algorithm
│   └── DiskEntry.swift
└── Monitoring/
    ├── SystemMonitor.swift      # actor
    ├── CPUStats.swift           # host_statistics64
    ├── MemoryStats.swift        # vm_statistics64
    ├── DiskIOStats.swift        # IOKit
    ├── NetworkStats.swift       # getifaddrs
    ├── BatteryStats.swift       # IOPSCopyPowerSourcesInfo
    ├── ProcessStats.swift       # libproc
    └── HealthScore.swift

FoxCleanApp/Features/
├── Analyzer/
│   ├── AnalyzerView.swift
│   ├── TreeView.swift
│   ├── TreemapCanvas.swift     # SwiftUI Canvas vẽ
│   └── AnalyzerViewModel.swift
├── Monitor/
│   ├── MonitorView.swift
│   ├── MetricCard.swift
│   ├── HealthCircle.swift
│   ├── ProcessTable.swift
│   └── MonitorViewModel.swift
└── MenuBar/
    ├── MenuBarController.swift
    └── MenuBarMiniView.swift
\`\`\`

## DiskScanner Algorithm
- Concurrent BFS với 4 worker tasks
- Mỗi worker xử lý một subtree
- AsyncStream cho progress
- SQLite schema: `entries(path TEXT PRIMARY KEY, size INTEGER, mtime INTEGER, is_dir INTEGER, parent TEXT)`
- Cache hit nếu mtime không đổi

## Treemap Algorithm (Squarified)
- Input: array `(name, size)` đã sort desc
- Output: rectangles với x, y, w, h
- Color: hash(path) → HSL
- Hover: tooltip với full path + size
- Click: zoom-in (push subtree)

## Health Score Formula
\`\`\`
score = 100
  - (cpu_5min_avg > 70%) ? 20 : 0
  - (mem_used > 90%) ? 15 : 0
  - (disk_used > 95%) ? 20 : 0
  - (temp > 90°C) ? 15 : 0
  - (swap_used > 4GB) ? 10 : 0
  - (io_wait > 30%) ? 10 : 0
  - (battery_cycles > 1000) ? 5 : 0
  - (battery_health < 80%) ? 5 : 0
\`\`\`

## Menu Bar Widget
- `MenuBarExtra(content:)` (macOS 13+)
- Compact: chỉ icon Foxie + CPU%
- Mở rộng: mini chart 60s + 4 quick actions

## Decisions

### Decision: SQLite thay vì JSON cache
- Query nhanh với index trên parent
- Atomic update
- Có thể vacuum

### Decision: Custom SwiftUI Canvas treemap thay vì WebView
- Native, không cần JS bridge
- Smooth animations
- Hit-testing tốt

### Decision: Tránh private API cho temp/GPU
- Skip CPU temp ở MVP nếu không có public API
- Có thể dùng `powermetrics` qua Process nhưng cần sudo
- V1.1 cân nhắc spawn helper tool có entitlement
```

## `tasks.md`

```markdown
# Tasks: Disk Analyzer + System Monitor

## 1. DiskScanner Core
- [ ] 1.1 `DiskScanner.scan(path:)` async với 4 workers
- [ ] 1.2 Progress qua AsyncStream
- [ ] 1.3 `ScanCache` SQLite với schema entries
- [ ] 1.4 Cache invalidation by mtime
- [ ] 1.5 Skip external volumes mặc định
- [ ] 1.6 Unit tests với fixtures

## 2. Treemap Algorithm
- [ ] 2.1 Implement squarified treemap
- [ ] 2.2 Unit tests với input có sẵn output (3 fixture)
- [ ] 2.3 Performance test: 10k entries < 100ms

## 3. AnalyzerView
- [ ] 3.1 `AnalyzerView` với segmented control (Tree/Treemap)
- [ ] 3.2 `TreeView` outline view với expand/collapse
- [ ] 3.3 `TreemapCanvas` dùng Canvas + GeometryReader
- [ ] 3.4 Hover tooltip
- [ ] 3.5 Click → zoom-in navigation
- [ ] 3.6 Right-click context menu
- [ ] 3.7 Top 10 largest files panel
- [ ] 3.8 Breadcrumb navigation

## 4. SystemMonitor Core
- [ ] 4.1 `CPUStats` dùng host_statistics64
- [ ] 4.2 `MemoryStats` dùng vm_statistics64
- [ ] 4.3 `DiskIOStats` dùng IOKit
- [ ] 4.4 `NetworkStats` dùng getifaddrs
- [ ] 4.5 `BatteryStats` dùng IOPSCopyPowerSourcesInfo
- [ ] 4.6 `ProcessStats.top(n:)` dùng libproc
- [ ] 4.7 SystemMonitor actor refresh mỗi 1s
- [ ] 4.8 HealthScore calculator
- [ ] 4.9 `--json` output cho `fox status`

## 5. MonitorView
- [ ] 5.1 `MonitorView` grid 3x2 metric cards
- [ ] 5.2 `HealthCircle` ring với màu theo điểm
- [ ] 5.3 SwiftUI Charts cho CPU/Mem/Network 60s
- [ ] 5.4 `ProcessTable` top 5 sortable
- [ ] 5.5 Auto-refresh khi visible (Timer.publish)

## 6. Menu Bar Widget
- [ ] 6.1 `MenuBarExtra` setup
- [ ] 6.2 Mini compact view: Foxie + CPU%
- [ ] 6.3 Expanded popover với mini chart
- [ ] 6.4 Quick actions: Smart Scan, Open App, Quit
- [ ] 6.5 Settings toggle "Show in menu bar"

## 7. CLI Extension
- [ ] 7.1 `fox analyze [path]` TUI tree + JSON
- [ ] 7.2 `fox status [--watch] [--json]`

## 8. Verification
- [ ] 8.1 Treemap render 100k entries không lag
- [ ] 8.2 Menu bar widget không drain pin (< 1% CPU avg)
- [ ] 8.3 Tag `v0.4.0-analyzer`
```

## `specs/analyzer/spec.md`

```markdown
# Delta for Analyzer

## ADDED Requirements

### Requirement: Disk Tree Scan
Hệ thống MUST scan một thư mục bất kỳ và trả về cây với size mỗi node.

#### Scenario: Scan home directory
- GIVEN người dùng chọn `~`
- WHEN AnalyzerView trigger scan
- THEN trong ≤ 60s với máy SSD bình thường, scan xong
- AND `TreeView` hiển thị các thư mục con sorted by size desc

#### Scenario: Cache hit
- GIVEN một thư mục đã scan trước, mtime chưa đổi
- WHEN scan lại
- THEN result trả về từ cache trong ≤ 2s

### Requirement: Treemap Visualization
AnalyzerView SHALL có chế độ treemap dùng squarified algorithm.

#### Scenario: Switch to treemap
- GIVEN AnalyzerView đang ở chế độ Tree
- WHEN người dùng chọn segmented "Treemap"
- THEN canvas vẽ rectangles cho top-level children
- AND tỷ lệ diện tích tương ứng với size
- AND màu phân biệt giữa các node

#### Scenario: Treemap zoom
- GIVEN treemap đang vẽ root
- WHEN người dùng click một rectangle thư mục con
- THEN canvas zoom vào subtree với breadcrumb update
- AND nút "Back" hiển thị

### Requirement: Trash from Analyzer
Right-click trên một node MUST cho phép move to Trash với confirmation.

#### Scenario: Move to Trash
- GIVEN một file 2GB hiển thị trong analyzer
- WHEN người dùng right-click → "Move to Trash"
- THEN dialog confirm
- WHEN xác nhận
- THEN file vào Trash
- AND analyzer refresh node parent
- AND OperationLog có entry

## ADDED Requirements (Monitor)

### Requirement: Live System Metrics
SystemMonitor MUST cung cấp CPU, Memory, Disk I/O, Network, Battery refresh
mỗi 1 giây.

#### Scenario: CPU usage update
- GIVEN MonitorView đang hiển thị
- WHEN 1 giây trôi qua
- THEN CPU % update với giá trị mới từ host_statistics64
- AND chart history có thêm 1 data point

#### Scenario: Cancel khi view ẩn
- GIVEN MonitorView không visible
- WHEN sidebar chuyển sang view khác
- THEN refresh timer dừng
- AND CPU usage của FoxClean < 0.5%

### Requirement: Health Score
Hệ thống MUST tính health score 0-100 dựa trên ≥ 5 yếu tố.

#### Scenario: Healthy system
- GIVEN CPU 20%, RAM 50%, Disk 60%, temp 50°C
- WHEN HealthScore tính
- THEN score ≥ 90
- AND HealthCircle render màu xanh

#### Scenario: Unhealthy system
- GIVEN CPU 95%, RAM 95%, Disk 98%
- WHEN HealthScore tính
- THEN score ≤ 50
- AND HealthCircle render màu đỏ
- AND Foxie mood `.curious`

### Requirement: Menu Bar Widget
Ứng dụng SHALL cung cấp NSStatusItem hoặc MenuBarExtra hiển thị metrics
nhanh, có thể bật/tắt qua Settings.

#### Scenario: Show in menu bar
- GIVEN Settings → "Show in menu bar" = ON
- WHEN app chạy
- THEN icon Foxie nhỏ xuất hiện trên menu bar
- AND hiển thị CPU%

#### Scenario: Click menu bar
- GIVEN menu bar icon hiển thị
- WHEN người dùng click
- THEN popover mở với mini chart 60s + 4 nút quick action

#### Scenario: Hide from menu bar
- GIVEN menu bar đang hiển thị
- WHEN Settings → toggle OFF
- THEN icon biến mất ngay lập tức
```

---

# 🛠️ Change 6: `add-purge-installer-optimize`

## `proposal.md`

```markdown
# Proposal: Project Purge + Installer Cleanup + System Optimize

## Intent
Hoàn thiện 3 feature parity với Mole: dọn build artifacts (node_modules,
target...), tìm installer cũ, và optimize hệ thống (rebuild caches, reset
network...).

## Scope
**In scope:**
- `ProjectPurgeView` quét theo patterns
- Configurable scan paths
- "Recent" badge tự động uncheck (< 7 ngày)
- `InstallerCleanupView` quét Downloads, iCloud, Mail, Homebrew cache
- `OptimizeView` với 6+ optimization tasks, whitelist
- Touch ID sudo integration qua `osascript`

**Out of scope:**
- Network proxy detection (V1.1)
- Time Machine cleanup (V1.1)

## Dependencies
- Change 2, 3
```

## `design.md`

```markdown
# Design: Purge + Installer + Optimize

## Module Layout
\`\`\`
Sources/FoxCleanCore/
├── Purging/
│   ├── ProjectScanner.swift     # find với patterns
│   ├── PurgePatterns.swift      # node_modules, target...
│   └── ProjectGroup.swift
├── Installing/
│   ├── InstallerScanner.swift
│   └── InstallerSources.swift   # Downloads, Brew, Mail, iCloud
└── Optimizing/
    ├── OptimizationTask.swift   # protocol
    ├── Tasks/
    │   ├── RebuildLaunchServices.swift
    │   ├── RefreshFinderDock.swift
    │   ├── FlushDNS.swift
    │   ├── RebuildSpotlight.swift
    │   ├── ClearDiagnosticLogs.swift
    │   └── ResetSwap.swift
    └── SudoHelper.swift          # osascript admin

FoxCleanApp/Features/
├── Purge/
├── Installer/
└── Optimize/
\`\`\`

## Purge Patterns (port từ Mole lib/clean/project.sh)
\`\`\`json
{
  "patterns": [
    { "name": "node_modules", "marker": "package.json" },
    { "name": "target", "marker": "Cargo.toml" },
    { "name": ".build", "marker": "Package.swift" },
    { "name": "build", "marker": "build.gradle|pom.xml" },
    { "name": "dist", "marker": "package.json" },
    { "name": ".next", "marker": "next.config.js" },
    { "name": "venv", "marker": "pyproject.toml|setup.py" },
    { "name": "__pycache__", "marker": "*.py" },
    { "name": "Pods", "marker": "Podfile" },
    { "name": "DerivedData", "marker": "*.xcodeproj" },
    { "name": ".gradle", "marker": "build.gradle" }
  ]
}
\`\`\`

## Installer Sources
- `~/Downloads/**/*.{dmg,pkg,zip,tar.gz}`
- `~/Desktop/**/*.{dmg,pkg}`
- `~/Library/Caches/Homebrew/downloads/*`
- iCloud Drive: `~/Library/Mobile Documents/com~apple~CloudDocs/`
- Mail attachments: `~/Library/Mail/V*/MailData/`

## Optimization Tasks
Protocol-based:
\`\`\`swift
protocol OptimizationTask {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var requiresSudo: Bool { get }
    func run() async throws -> OptimizationResult
}
\`\`\`

## Sudo via Touch ID
- Dùng `osascript -e 'do shell script "..." with administrator privileges'`
- macOS prompt sẽ tự dùng Touch ID nếu user enabled
- Cache không cần — `osascript` quản lý session
```

## `tasks.md`

```markdown
# Tasks: Purge + Installer + Optimize

## 1. ProjectPurge
- [ ] 1.1 `PurgePatterns.json` với 11 patterns
- [ ] 1.2 `ProjectScanner.scan(roots:)` dùng FileManager BFS hoặc spawn `fd` nếu có
- [ ] 1.3 Marker detection (chỉ trả về nếu thư mục cha có marker file)
- [ ] 1.4 Recent badge logic (mtime < 7 ngày)
- [ ] 1.5 `ProjectPurgeView` table grouped by project
- [ ] 1.6 Settings: configurable scan paths (`~/Projects`, `~/GitHub`, `~/dev`)
- [ ] 1.7 Confirmation dialog với Foxie

## 2. InstallerCleanup
- [ ] 2.1 `InstallerScanner` 5 sources với label
- [ ] 2.2 `InstallerCleanupView` table sortable by size/age
- [ ] 2.3 Auto-select files > 30 ngày
- [ ] 2.4 Source filter chips

## 3. Optimize Core
- [ ] 3.1 `OptimizationTask` protocol + 6 implementations
- [ ] 3.2 `SudoHelper` osascript wrapper với progress callback
- [ ] 3.3 Whitelist file: `~/.config/foxclean/optimize_whitelist`
- [ ] 3.4 Result aggregation

## 4. OptimizeView
- [ ] 4.1 List tasks với toggle on/off
- [ ] 4.2 "Run all" button
- [ ] 4.3 Progress per task
- [ ] 4.4 Result panel với "before/after" cho applicable tasks
- [ ] 4.5 Settings: whitelist editor

## 5. CLI Extension
- [ ] 5.1 `fox purge` với `--paths`, `--dry-run`
- [ ] 5.2 `fox installer`
- [ ] 5.3 `fox optimize [--whitelist]`

## 6. Verification
- [ ] 6.1 Purge dry-run trên repo test → output match expectation
- [ ] 6.2 Optimize FlushDNS → verify DNS reset
- [ ] 6.3 Tag `v0.5.0-toolkit`
```

## `specs/toolkit/spec.md`

```markdown
# Delta for Toolkit

## ADDED Requirements

### Requirement: Project Artifact Detection
Hệ thống MUST phát hiện thư mục build artifacts dựa trên pattern + marker file
của project cha.

#### Scenario: Detect node_modules
- GIVEN cấu trúc `~/dev/my-app/{package.json, node_modules/}`
- WHEN purge scan
- THEN `node_modules` của my-app xuất hiện trong kết quả
- AND group by project name "my-app"

#### Scenario: Skip orphan node_modules
- GIVEN `~/random/node_modules` không có `package.json` ở cấp cha
- WHEN purge scan
- THEN node_modules này KHÔNG xuất hiện
- AND log debug "skipped: no marker"

### Requirement: Recent Project Safety
Files mới hơn 7 ngày MUST được mark "Recent" và uncheck mặc định.

#### Scenario: Recent badge
- GIVEN project có mtime 3 ngày trước
- WHEN render trong PurgeView
- THEN row có badge "Recent" màu vàng
- AND checkbox default OFF

### Requirement: Custom Scan Paths
Người dùng MUST có thể cấu hình scan paths qua Settings hoặc file
`~/.config/foxclean/purge_paths`.

#### Scenario: Custom paths
- GIVEN file `purge_paths` chứa `~/Work/ClientA`
- WHEN purge scan
- THEN chỉ scan path đó, bỏ qua default `~/Projects`

## ADDED Requirements (Installer)

### Requirement: Multi-Source Installer Discovery
InstallerScanner SHALL tìm `.dmg`, `.pkg`, `.zip`, `.tar.gz` từ ≥ 5 nguồn,
mỗi file có label nguồn.

#### Scenario: Label by source
- GIVEN `~/Downloads/Spotify.dmg` và `Homebrew downloads/Spotify.dmg`
- WHEN scan
- THEN cả 2 rows với labels "Downloads" và "Homebrew"

## ADDED Requirements (Optimize)

### Requirement: Modular Optimization Tasks
Hệ thống MUST có ≥ 6 optimization tasks chạy độc lập với toggle on/off.

#### Scenario: Toggle off task
- GIVEN OptimizeView có 6 tasks
- WHEN user toggle off "Rebuild Spotlight"
- THEN khi "Run all", task này skip
- AND status hiển thị "Skipped (whitelisted)"

### Requirement: Sudo via System Dialog
Tasks cần admin SHALL trigger native macOS prompt (Touch ID fallback password).

#### Scenario: Sudo prompt
- GIVEN task "Reset Swap" cần sudo
- WHEN người dùng bấm Run
- THEN macOS hệ thống hiện dialog admin
- AND nếu user có Touch ID, fingerprint prompt
- AND task chạy sau khi auth thành công
```

---

# 🔧 Change 7: `add-cli-menubar-launchers`

## `proposal.md`

```markdown
# Proposal: Complete CLI + Quick Launchers + TUI Polish

## Intent
Hoàn thiện CLI ngang bằng Mole với TUI interactive, tích hợp Raycast/Alfred,
shell completion, Touch ID sudo.

## Scope
**In scope:**
- `fox` interactive TUI menu (gõ `fox` không args)
- Shell completion (bash, zsh, fish)
- Raycast script commands
- Alfred workflow
- `fox open` mở GUI từ terminal
- `fox touchid enable` config sudo Touch ID
- TUI navigation Vim-style (h/j/k/l)
- Progress bars đẹp trong terminal

**Out of scope:**
- Windows port (Mole có experimental, ta bỏ qua)
```

## `design.md`

```markdown
# Design: CLI Polish

## TUI Library Decision
- Tự viết minimal TUI bằng ANSI escape (giống Mole)
- Hoặc dùng [swift-tui](https://github.com/...) (community)
- MVP: tự viết, code nhỏ gọn ~500 LoC

## Interactive Menu
\`\`\`
$ fox
  ╭─────────────────────────────────╮
  │  🦊 FoxClean v1.0.0             │
  ╰─────────────────────────────────╯
  
  Chọn lệnh:
  ❯ 1. Clean        Dọn rác hệ thống
    2. Uninstall    Gỡ ứng dụng
    3. Orphans      Tìm file mồ côi
    4. Analyze      Phân tích disk
    5. Status       Health dashboard
    6. Purge        Build artifacts
    7. Installer    Dọn .dmg cũ
    8. Optimize     Tối ưu hệ thống
    9. Open GUI     Mở app
    
  ↑↓/jk navigate · Enter select · q quit
\`\`\`

## Raycast Integration
- `scripts/raycast/clean.sh`, `uninstall.sh`, ...
- Script bằng `#!/bin/bash` + Raycast headers
- `setup-quick-launchers.sh` script một lệnh

## Shell Completion
- swift-argument-parser auto-generate
- `fox completion zsh > ~/.zfunc/_fox`

## Touch ID Sudo
\`\`\`bash
fox touchid enable
# → ghi /etc/pam.d/sudo_local với auth pam_tid.so
# Cần sudo
\`\`\`
```

## `tasks.md`

```markdown
# Tasks: CLI Polish

## 1. Interactive TUI
- [ ] 1.1 `InteractiveMenu` view-controller pattern
- [ ] 1.2 Vim keys h/j/k/l + arrows
- [ ] 1.3 Color rendering với fallback no-color
- [ ] 1.4 Cancel với Ctrl+C đúng

## 2. Commands Polish
- [ ] 2.1 Progress bars với ETA
- [ ] 2.2 Spinner cho long-running
- [ ] 2.3 Auto-detect TTY vs pipe → JSON
- [ ] 2.4 `--no-color` flag

## 3. Open GUI
- [ ] 3.1 `fox open [view]` → URL scheme `foxclean://...`
- [ ] 3.2 App đăng ký URL handler

## 4. Touch ID
- [ ] 4.1 `fox touchid enable/disable/status`
- [ ] 4.2 Edit `/etc/pam.d/sudo_local` an toàn
- [ ] 4.3 Verify command sau khi enable

## 5. Shell Completion
- [ ] 5.1 `fox completion {bash,zsh,fish}`
- [ ] 5.2 Test trên zsh, bash 5+

## 6. Raycast & Alfred
- [ ] 6.1 9 scripts trong `scripts/raycast/`
- [ ] 6.2 Alfred workflow `.alfredworkflow`
- [ ] 6.3 `setup-quick-launchers.sh` script

## 7. Verification
- [ ] 7.1 Test trên Terminal, iTerm2, Warp, Ghostty
- [ ] 7.2 Tag `v0.6.0-cli`
```

## `specs/cli/spec.md`

```markdown
# Delta for CLI

## ADDED Requirements

### Requirement: Interactive Menu
Khi chạy `fox` không args, hệ thống MUST hiển thị TUI menu.

#### Scenario: Launch interactive
- GIVEN terminal interactive (TTY)
- WHEN người dùng gõ `fox`
- THEN menu hiển thị với 9 options
- AND Foxie ASCII art ở header

#### Scenario: Pipe → no menu
- GIVEN command `fox | cat`
- WHEN execute
- THEN không hiển thị menu (vì stdout không TTY)
- AND in `--help` thay vì

### Requirement: Vim-Style Navigation
TUI menu MUST hỗ trợ cả arrow keys và Vim bindings h/j/k/l.

#### Scenario: Navigate down
- GIVEN menu đang ở item 1
- WHEN nhấn `j` (hoặc ↓)
- THEN selection chuyển xuống item 2

### Requirement: Shell Completion
Hệ thống SHALL generate completion scripts cho bash, zsh, fish.

#### Scenario: Generate zsh
- GIVEN người dùng chạy `fox completion zsh`
- WHEN stdout
- THEN output là valid zsh completion file
- AND chứa tất cả subcommands

### Requirement: Touch ID Sudo
`fox touchid enable` SHALL config `/etc/pam.d/sudo_local` để sudo dùng Touch ID.

#### Scenario: Enable Touch ID
- GIVEN máy Mac có Touch ID hardware
- WHEN người dùng chạy `fox touchid enable`
- THEN command prompt sudo password 1 lần
- AND ghi `auth sufficient pam_tid.so` vào file
- AND sudo subsequent dùng Touch ID

### Requirement: GUI Launch from CLI
`fox open` SHALL launch GUI app, optionally đến view cụ thể.

#### Scenario: Open Dashboard
- GIVEN GUI chưa mở
- WHEN người dùng chạy `fox open`
- THEN FoxClean.app launches
- AND hiển thị Dashboard

#### Scenario: Open specific view
- GIVEN GUI có thể chạy
- WHEN `fox open analyzer`
- THEN app mở trực tiếp AnalyzerView
```

---

# 🌍 Change 8: `add-polish-i18n-release`

## `proposal.md`

```markdown
# Proposal: Polish, i18n, Documentation, v1.0 Release

## Intent
Hoàn thiện sản phẩm: dịch 7 ngôn ngữ, accessibility, sound, docs đa ngôn ngữ,
notarize, distribute qua Homebrew Cask.

## Scope
**In scope:**
- Localization 7 ngôn ngữ: vi, en, es, ja, zh-Hans, zh-Hant, ar
- Accessibility: VoiceOver labels, keyboard shortcuts toàn app
- Empty states với Foxie illustrations
- Error handling friendly với Foxie
- README đa ngôn ngữ (giống PureMac)
- ARCHITECTURE.md, CONTRIBUTING.md, SECURITY.md
- Apple Developer ID signing + notarization
- DMG đẹp với background custom
- Homebrew Cask submission
- GitHub Pages landing site
- v1.0.0 release

**Out of scope:**
- Mac App Store submission (cần app sandbox xung khắc với scan)
- Paid version
```

## `design.md`

```markdown
# Design: Polish & Release

## i18n Strategy
- `Localizable.xcstrings` (Xcode 15+ format)
- vi-VN làm primary (translation source)
- Hire/community translators cho 6 ngôn ngữ khác
- String key naming: `feature.element.state`, ví dụ `clean.toolbar.smart_scan`

## Notarization
- Apple Developer ID Application cert
- `codesign` deep với hardened runtime + entitlements
- `xcrun notarytool submit` qua API key
- Staple ticket vào DMG

## DMG Layout
- Background image 540x380 với Foxie ôm Applications folder
- Drag-to-Applications shortcut
- Generated bằng `create-dmg`

## Homebrew Cask
\`\`\`ruby
cask "foxclean" do
  version "1.0.0"
  sha256 "..."
  url "https://github.com/foxclean/foxclean/releases/download/v#{version}/FoxClean-#{version}.dmg"
  name "FoxClean"
  desc "Cute & powerful Mac cleaner with Foxie mascot"
  homepage "https://foxclean.dev"
  app "FoxClean.app"
  binary "#{appdir}/FoxClean.app/Contents/Resources/fox"
  zap trash: [
    "~/Library/Application Support/FoxClean",
    "~/Library/Caches/com.foxclean",
    "~/Library/Logs/FoxClean",
    "~/Library/Preferences/com.foxclean.plist"
  ]
end
\`\`\`
```

## `tasks.md`

```markdown
# Tasks: Polish & Release

## 1. Localization
- [ ] 1.1 Audit toàn bộ string trong UI và CLI
- [ ] 1.2 Hoàn thiện vi (primary)
- [ ] 1.3 Hoàn thiện en
- [ ] 1.4 Dịch es, ja, zh-Hans, zh-Hant, ar (community hoặc service)
- [ ] 1.5 RTL layout test cho ar

## 2. Accessibility
- [ ] 2.1 VoiceOver labels cho tất cả buttons/controls
- [ ] 2.2 Keyboard shortcuts table trong Help menu
- [ ] 2.3 Tab order kiểm tra
- [ ] 2.4 Color contrast WCAG AA
- [ ] 2.5 Reduced Motion support

## 3. Empty States & Errors
- [ ] 3.1 6 empty states với Foxie illustrations
- [ ] 3.2 Error catalog → user-friendly messages
- [ ] 3.3 Crash reporter (opt-in, không telemetry mặc định)

## 4. Sound (optional)
- [ ] 4.1 3 sound effects: pop, chime, error
- [ ] 4.2 Settings toggle (off by default)

## 5. Documentation
- [ ] 5.1 README.md với badges, screenshots, install instructions
- [ ] 5.2 README.vi.md (đầy đủ tiếng Việt)
- [ ] 5.3 README.{en,es,ja,zh-Hans,zh-Hant}.md
- [ ] 5.4 ARCHITECTURE.md
- [ ] 5.5 CONTRIBUTING.md
- [ ] 5.6 SECURITY.md (adapt từ Mole)
- [ ] 5.7 CHANGELOG.md từ git history

## 6. Build & Sign
- [ ] 6.1 Setup Apple Developer ID cert trong CI secrets
- [ ] 6.2 Notarization API key
- [ ] 6.3 GitHub Action `release.yml` trigger trên tag
- [ ] 6.4 Universal binary (x86_64 + arm64)
- [ ] 6.5 DMG với background custom

## 7. Distribution
- [ ] 7.1 Submit Homebrew Cask PR
- [ ] 7.2 GitHub Pages site (`foxclean.dev`)
- [ ] 7.3 ProductHunt / HN launch posts
- [ ] 7.4 Twitter/X announcement

## 8. Release v1.0.0
- [ ] 8.1 Final QA checklist
- [ ] 8.2 Tag `v1.0.0`
- [ ] 8.3 Generate release notes
- [ ] 8.4 Upload DMG đã notarized
- [ ] 8.5 Tweet 🎉
```

## `specs/release/spec.md`

```markdown
# Delta for Release Quality

## ADDED Requirements

### Requirement: Multi-Language Support
Ứng dụng MUST hỗ trợ tối thiểu 7 ngôn ngữ với fallback về tiếng Anh.

#### Scenario: Vietnamese as primary
- GIVEN macOS preferred = vi-VN
- WHEN app mở
- THEN toàn bộ UI tiếng Việt
- AND không có string nào còn ở dạng key

#### Scenario: Fallback unknown language
- GIVEN macOS preferred = de-DE (chưa hỗ trợ)
- WHEN app mở
- THEN UI fallback về en-US
- AND không crash

### Requirement: Accessibility
Mọi UI control SHALL có VoiceOver label và keyboard shortcut.

#### Scenario: VoiceOver smart scan
- GIVEN VoiceOver bật
- WHEN focus button "Smart Scan"
- THEN VO đọc "Smart Scan, button, quét toàn bộ rác hệ thống"

#### Scenario: Reduced motion
- GIVEN System Settings → Reduce Motion = ON
- WHEN Foxie hiển thị
- THEN animations giảm tốc 50% hoặc tĩnh
- AND không có spring/bounce

### Requirement: Notarized Distribution
DMG MUST được Apple notarized và stapled trước khi public release.

#### Scenario: Download và mở DMG
- GIVEN user download `FoxClean-1.0.0.dmg` từ release
- WHEN mở DMG bằng double-click
- THEN không có Gatekeeper warning
- AND app mở được mà không cần "Open Anyway"

### Requirement: Homebrew Installation
Ứng dụng SHALL cài đặt được qua `brew install --cask foxclean`.

#### Scenario: Brew install
- GIVEN máy có Homebrew
- WHEN chạy `brew install --cask foxclean`
- THEN FoxClean.app vào `/Applications`
- AND symlink `fox` CLI vào PATH

### Requirement: Telemetry-Free
Ứng dụng MUST KHÔNG gửi bất kỳ telemetry, analytics, hay crash report nào
mà không có opt-in tường minh.

#### Scenario: Fresh install
- GIVEN máy network monitor (Little Snitch)
- WHEN app chạy lần đầu, làm scan + clean
- THEN không có outbound connection
- AND không có background daemon
```

---

## 📦 Tổng kết OpenSpec

Toàn bộ OpenSpec cho FoxClean gồm:

| Change | Phase | Tuần | Files trong folder |
|---|---|---|---|
| `add-foxclean-foundation` | 0 | 1 | proposal, design, tasks, specs/foundation/spec.md |
| `add-scan-clean-core` | 1 | 2-3 | + specs/scanning, specs/cleaning |
| `add-gui-onboarding-mascot` | 2 | 4-5 | + specs/gui |
| `add-clean-uninstall-orphans` | 3 | 6-7 | + specs/clean-ui |
| `add-disk-analyzer-system-monitor` | 4 | 8-9 | + specs/analyzer |
| `add-purge-installer-optimize` | 5 | 10-11 | + specs/toolkit |
| `add-cli-menubar-launchers` | 6 | 12 | + specs/cli |
| `add-polish-i18n-release` | 7 | 13-14 | + specs/release |

**Tổng cộng**: 8 domain specs sau khi archive hết → `openspec/specs/{foundation, scanning, cleaning, gui, clean-ui, analyzer, toolkit, cli, release}/spec.md`.

## Cách dùng OpenSpec này

1. Tại repo gốc FoxClean, chạy `openspec init` (cài qua `npm i -g @fission-ai/openspec`).
2. Copy nội dung trên vào các file tương ứng dưới `openspec/changes/<change-id>/`.
3. Bắt đầu với Change 1: `openspec show add-foxclean-foundation` rồi `openspec validate`.
4. AI agent (Claude Code, Cursor, etc.) đọc `openspec/project.md` + change folder để implement.
5. Hoàn thành tasks → `openspec archive add-foxclean-foundation` → tự động merge delta vào `specs/`.
6. Lặp lại với Change 2 → 8.
