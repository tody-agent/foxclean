# 📊 Báo cáo nghiên cứu & Kế hoạch triển khai

## Phần 1: Tổng hợp nghiên cứu

### 🟦 PureMac — Kiến trúc Swift/SwiftUI Native macOS App

```
PureMac/
├── PureMacApp.swift          (entry point, có sẵn CLI mode!)
├── Core/                     (CLI handlers)
├── Logic/
│   ├── Scanning/
│   │   ├── AppPathFinder.swift     (15KB - heuristic 10 levels)
│   │   ├── Conditions.swift         (18KB - 25 rules cho app đặc biệt)
│   │   ├── Locations.swift          (6.7KB - 120+ search paths)
│   │   ├── AppInfoFetcher.swift     (Spotlight + Info.plist)
│   │   └── StringNormalization.swift
│   └── Utilities/                   (os.log)
├── Services/
│   ├── ScanEngine.swift             (37KB - engine chính)
│   ├── CleaningEngine.swift         (14KB)
│   ├── FullDiskAccessManager.swift  (4.5KB)
│   └── SchedulerService.swift       (4.5KB - auto scan)
├── Models/                          (typed errors, data models)
├── ViewModels/                      (AppState)
├── Views/
│   ├── Apps/ Cleaning/ Orphans/ Settings/ Components/
└── *.lproj/                         (6 ngôn ngữ)
```

**Điểm mạnh PureMac:**
- GUI SwiftUI thuần native, dùng `NavigationSplitView`, `Table`, `Form`
- Onboarding hướng dẫn Full Disk Access — UX rất tốt
- **Đã có CLI mode embedded** trong `PureMacApp.swift` (chú ý `CLI.isKnownCommand`)
- Heuristic matching 10 levels cực kỳ chính xác
- Symlink attack prevention
- 27 Apple apps được bảo vệ
- Đa ngôn ngữ sẵn (6 lproj)

**Điểm yếu PureMac:**
- Không có **disk analyzer** (DaisyDisk-style)
- Không có **system status** dashboard real-time
- Không có **project artifact purge** (`node_modules`, etc.)
- Không có **installer cleanup**
- Không có **system optimization** (rebuild caches, reset network…)
- Không có operation log để rollback
- UI thiếu "cá tính" — quá native, hơi khô khan

### 🟫 Mole — Bash Shell Toolkit + Go Helpers

```
mole/                          (37KB main bash script — orchestrator)
├── mo                         (alias)
├── lib/
│   ├── core/
│   │   ├── base.sh            (27KB - bootstrap)
│   │   ├── app_protection.sh  (73KB - DB apps cần bảo vệ!)
│   │   ├── file_ops.sh        (35KB - safe delete, trash)
│   │   ├── bundle_resolver.sh (resolve bundle ID → paths)
│   │   ├── log.sh             (operation log ~/Library/Logs/mole/)
│   │   ├── sudo.sh            (Touch ID sudo)
│   │   ├── timeout.sh         (cancel hung operations)
│   │   ├── ui.sh              (TUI: arrows, vim h/j/k/l)
│   │   ├── pkg_receipts.sh    (đọc /var/db/receipts/)
│   │   └── common.sh, commands.sh, help.sh
│   ├── clean/
│   │   ├── user.sh            (90KB - user cache cleanup!)
│   │   ├── dev.sh             (67KB - Xcode/Node/Cargo)
│   │   ├── project.sh         (60KB - node_modules purge)
│   │   ├── apps.sh            (37KB - app caches)
│   │   ├── hints.sh           (27KB - app-specific rules)
│   │   ├── app_caches.sh, brew.sh, caches.sh, system.sh, purge_shared.sh, maven.sh
│   ├── optimize/              (system optimize)
│   ├── uninstall/             (smart uninstaller)
│   ├── manage/                (update, completion, touchid)
│   ├── check/                 (preflight checks)
│   └── ui/                    (TUI components)
├── cmd/                       (Go binaries)
│   ├── analyze/               (disk analyzer Go binary)
│   └── status/                (system status Go binary)
├── internal/units/            (Go - byte formatting)
├── go.mod, go.sum, Makefile
├── install.sh                 (30KB installer)
└── scripts/
```

**Điểm mạnh Mole:**
- **Hybrid Go + Bash**: Bash cho orchestration & cleaning rules (dễ contribute, ai cũng đọc được), Go cho perf-critical (disk scan & live stats)
- 7 commands rõ ràng: `clean / uninstall / optimize / analyze / status / purge / installer`
- `--dry-run` mặc định cho mọi destructive op
- Operation log với `~/Library/Logs/mole/operations.log`
- Touch ID sudo integration
- `--json` output cho automation
- TUI navigation Vim-style
- Whitelist system qua file config
- **App protection database** đồ sộ (73KB) — hơn hẳn PureMac 27 apps

**Điểm yếu Mole:**
- **Không có GUI**: GUI native ($9) là closed-source
- Terminal-only — user thường không quen
- iTerm2 có incompatibilities
- Phụ thuộc thư viện `fd` cho `purge`
- Bash khó test, khó refactor
- Không có visualization trực quan kiểu treemap thật sự

---

## Phần 2: Tầm nhìn dự án mới — **🦊 FoxClean**

### Triết lý

> *"Mạnh như Mole, dễ thương như Studio Ghibli, mở như PureMac, native như Apple."*

| Tiêu chí | PureMac | Mole | **FoxClean** |
|---|---|---|---|
| GUI | ✅ SwiftUI | ❌ | ✅ SwiftUI **+ cute mascot** |
| CLI | 🟡 cơ bản | ✅ mạnh | ✅ **CLI + GUI cùng binary** |
| Disk Analyzer | ❌ | ✅ TUI | ✅ **TUI + Treemap visual** |
| Live Status | ❌ | ✅ TUI | ✅ **Menu bar widget** |
| Project Purge | ❌ | ✅ | ✅ |
| Installer Cleanup | ❌ | ✅ | ✅ |
| System Optimize | ❌ | ✅ | ✅ |
| Heuristic Matching | ✅ 10 levels | ✅ DB lớn | ✅ **Kết hợp cả hai** |
| App Protection | 27 apps | ~hàng nghìn | ✅ **Import từ Mole DB** |
| Operation Log | ❌ | ✅ | ✅ **+ Rollback từ Trash** |
| Onboarding | ✅ | ❌ | ✅ |
| Đa ngôn ngữ | ✅ 6 lang | ❌ | ✅ 6 lang **+ Vietnamese** |
| Mascot/Character | ❌ | 🟡 cat | ✅ **Foxie mascot** |
| Menu bar | ❌ | ❌ | ✅ |
| Touch ID sudo | ❌ | ✅ | ✅ |
| Telemetry | ❌ | ❌ | ❌ (giữ nguyên) |
| License | MIT | MIT | **MIT** |

### Kiến trúc đề xuất — Hybrid 3-Layer

```
┌─────────────────────────────────────────────────┐
│  Layer 3: PRESENTATION                          │
│  ┌──────────────┐  ┌──────────────┐  ┌────────┐ │
│  │ SwiftUI GUI  │  │  TUI (term)  │  │ MenuBar│ │
│  │ + Foxie 🦊   │  │  vim-style   │  │ widget │ │
│  └──────────────┘  └──────────────┘  └────────┘ │
├─────────────────────────────────────────────────┤
│  Layer 2: CORE LIBRARY (Swift Package)          │
│  FoxCleanCore – ALL business logic:             │
│  • ScanEngine   • CleaningEngine                │
│  • DiskAnalyzer • SystemMonitor                 │
│  • ProjectPurge • Uninstaller                   │
│  • Optimizer    • OperationLog                  │
│  Có async/await, structured concurrency, JSON   │
├─────────────────────────────────────────────────┤
│  Layer 1: DATA & RULES                          │
│  • app_protection.json (mượn của Mole)          │
│  • locations.json       (mượn của PureMac)      │
│  • conditions.json      (mượn của PureMac)      │
│  • purge_patterns.json  (mượn của Mole)         │
│  • optimize_scripts/    (mượn của Mole)         │
└─────────────────────────────────────────────────┘
```

**Lý do chọn 100% Swift (không kế thừa Bash/Go của Mole):**
1. Universal Binary cho Intel + Apple Silicon dễ dàng
2. Có thể ship trong **một bundle .app duy nhất** (binary + library)
3. Type-safety, dễ test, dễ maintain hơn 90KB bash
4. Tận dụng được `Process`, `FileManager`, `IOKit`, `Metal`... native
5. SwiftUI + SwiftPM = workflow đơn giản

**Tuy nhiên,** chúng ta sẽ **port** rule database & cleaning patterns từ Mole sang JSON declarative để giữ được giá trị từ 90KB shell code đó.

---

## Phần 3: Kế hoạch triển khai chi tiết — 8 giai đoạn

### 🚀 Phase 0 — Setup & Foundation (Tuần 1)

**Goal**: Có repo, có CI, có project skeleton biên dịch được.

**Việc cần làm**:
1. Tạo repo GitHub `foxclean/foxclean` với MIT license
2. Setup project structure dùng `xcodegen`:
   ```
   FoxClean/
   ├── Package.swift              (Swift Package cho Core)
   ├── project.yml                (xcodegen config)
   ├── FoxClean/                  (App target)
   │   ├── FoxCleanApp.swift
   │   ├── Resources/
   │   │   ├── Foxie/             (Lottie hoặc SF Symbols animation)
   │   │   ├── data/              (JSON rule databases)
   │   │   └── Localizable/
   │   ├── Features/              (mỗi feature 1 folder)
   │   │   ├── Onboarding/
   │   │   ├── Dashboard/
   │   │   ├── Clean/
   │   │   ├── Uninstall/
   │   │   ├── Orphans/
   │   │   ├── Purge/
   │   │   ├── Installer/
   │   │   ├── Analyzer/
   │   │   ├── Optimize/
   │   │   ├── Monitor/
   │   │   └── Settings/
   │   └── App/                   (AppDelegate, AppState, ThemeManager)
   ├── FoxCleanCore/              (Swift Package – Library)
   │   └── Sources/FoxCleanCore/
   │       ├── Scanning/
   │       ├── Cleaning/
   │       ├── Analyzing/
   │       ├── Monitoring/
   │       ├── Optimizing/
   │       ├── Logging/
   │       └── Models/
   ├── FoxCleanCLI/               (Executable target dùng chung Core)
   │   └── main.swift             (ArgumentParser)
   ├── Tests/
   │   ├── FoxCleanCoreTests/
   │   └── FoxCleanCLITests/
   └── .github/workflows/
       ├── build.yml
       ├── test.yml
       └── release.yml            (notarize + dmg)
   ```
3. Dependencies (SwiftPM):
   - `apple/swift-argument-parser` — CLI
   - `pointfreeco/swift-snapshot-testing` — UI tests
   - Có thể `Lottie-iOS` cho mascot animations (optional, dùng SF Symbols thay cũng được)
4. CI: GitHub Actions chạy `xcodebuild test` trên macOS-14
5. Setup `SwiftLint` + `swift-format`

**Output**: Repo build được với 1 cửa sổ "Hello Foxie 🦊".

---

### 🧠 Phase 1 — FoxCleanCore: Scan & Clean engine (Tuần 2-3)

**Goal**: Port logic scan/clean của PureMac vào library, có CLI test được.

**Việc cần làm**:
1. **Port từ PureMac sang FoxCleanCore**:
   - `AppPathFinder.swift` → `FoxCleanCore/Scanning/PathFinder.swift`
   - `Conditions.swift` → tách thành `Resources/data/conditions.json` + Swift decoder
   - `Locations.swift` → `Resources/data/locations.json` + Swift decoder
   - `AppInfoFetcher.swift`, `StringNormalization.swift` giữ nguyên
   - `ScanEngine.swift` → refactor dùng `async/await`
   - `CleaningEngine.swift` → thêm `OperationLog` (mượn ý Mole)
   - `FullDiskAccessManager.swift` giữ nguyên

2. **Đưa rule DB của Mole vào JSON**:
   - Đọc `lib/core/app_protection.sh` (73KB), trích danh sách app + bundle IDs → `Resources/data/protected_apps.json`
   - Đọc `lib/clean/hints.sh` (27KB), trích app-specific cleanup rules → `Resources/data/cleanup_hints.json`

3. **OperationLog module mới** (ý tưởng từ Mole, nâng cấp):
   - Lưu mỗi xóa vào `~/Library/Logs/FoxClean/operations-YYYYMMDD.jsonl`
   - Schema: `{ts, action, src_path, trashed_to, size, session_id, dry_run}`
   - API: `try OperationLog.append(entry)` / `OperationLog.recentSessions()`
   - **Tính năng vượt Mole**: rollback từ Trash dùng `NSWorkspace.recycle` reverse path

4. **CLI cơ bản**:
   ```bash
   fox scan --apps               # list installed apps + sizes
   fox scan --orphans            # orphaned library files
   fox clean --dry-run system    # preview only
   fox uninstall <app> --dry-run
   ```

5. Unit tests cho `PathFinder`, `OperationLog`, JSON decoders.

**Output**: CLI `fox` binary chạy được với 2 commands `scan` & `clean`, có dry-run, có log.

---

### 🎨 Phase 2 — GUI cốt lõi + Onboarding + Foxie mascot (Tuần 4-5)

**Goal**: App có giao diện chính, đáng yêu, mở lên dùng được.

**Việc cần làm**:
1. **Onboarding flow** (3 bước, lấy cảm hứng từ PureMac):
   - Welcome — Foxie vẫy tay
   - Full Disk Access — Foxie chỉ vào System Settings, có nút "Open Settings"
   - Cảm ơn — Foxie nháy mắt

2. **Foxie mascot system**:
   - Tạo `FoxieView` (SwiftUI) với 8 trạng thái: `idle, scanning, cleaning, success, error, sleeping, curious, dancing`
   - **MVP**: dùng SF Symbols sequence + `withAnimation` (không cần asset thật) — VD: 🦊 + animation rung lắc
   - **V2**: convert sang Lottie/Rive nếu có designer
   - Easter egg: bấm `F` 5 lần → Foxie nhảy

3. **Main window** với `NavigationSplitView`:
   - Sidebar: Dashboard, Clean, Uninstall, Orphans, Purge, Installer, Analyzer, Optimize, Monitor, Settings
   - Mỗi mục có icon SF Symbol + tên
   - Toolbar có "Smart Scan" button (1-click) và Foxie ở góc

4. **Dashboard** (màn hình chính):
   - Card "Disk space" — circular progress kiểu Apple Storage
   - Card "Last scan" — bao nhiêu GB đã giải phóng
   - Card "Foxie says" — gợi ý thông minh ("Bạn có 12GB cache Chrome, dọn không?")
   - Card "Quick actions" — 4 nút lớn

5. **ThemeManager** (giữ từ PureMac): light/dark/auto + accent colors

6. **Localizable.strings** — Vietnamese first 🇻🇳, rồi English, rồi 5 ngôn ngữ PureMac

**Output**: App có UI đẹp, có Foxie, đã làm onboarding, có Dashboard.

---

### 🧹 Phase 3 — Clean / Uninstall / Orphans (Tuần 6-7)

**Goal**: 3 features cốt lõi giống PureMac nhưng đẹp hơn.

**Việc cần làm**:
1. **CleanView**:
   - Master-detail: trái là 9 categories (System Junk, User Cache, AI Apps, Mail, Trash, Large&Old, Purgeable, Xcode, Brew)
   - Phải: list file kèm checkbox, size, path
   - Bottom bar: "Selected: X GB" + nút "Clean" với confirmation
   - Animation: scan progress với Foxie đang đào

2. **UninstallView**:
   - List apps với icon, version, install date, size, badge "Recent/Old"
   - Click app → panel phải hiện all related files (Application Support, Caches, Preferences, Logs, WebKit, Cookies, Extensions, LaunchDaemons)
   - 3 sensitivity sliders: Strict / Enhanced / Deep (giữ từ PureMac)
   - Smart Filter: ẩn 27 Apple apps + apps trong `protected_apps.json`

3. **OrphansView**:
   - Scan `~/Library` so sánh với apps installed
   - Bảng: name, path, size, last modified, "from app" (best guess)
   - 1-click cleanup

4. **Confirmation dialog system**:
   - Dialog đẹp với Foxie nghiêng đầu lo lắng khi user xóa > 5GB
   - Hiển thị bytes sẽ vào Trash chứ không xóa thẳng (mặc định)
   - Toggle "Move to Trash (safer) / Delete permanently"

**Output**: User có thể uninstall apps & dọn rác qua GUI, an toàn, có log.

---

### 📊 Phase 4 — Disk Analyzer + System Monitor (Tuần 8-9)

**Goal**: Hai tính năng "wow" Mole có mà PureMac không có, làm đẹp hơn.

**Việc cần làm**:
1. **Disk Analyzer** (`Features/Analyzer/`):
   - Core: `DiskScanner` async, parallel BFS dùng `FileManager.enumerator`
   - Cache kết quả vào `~/Library/Application Support/FoxClean/scan_cache.sqlite`
   - **Hai chế độ view**:
     - **Tree view**: cột Name / Size / % / Modified — kiểu Finder
     - **Treemap view** — *điểm khác biệt vs Mole*: dùng SwiftUI Canvas vẽ squarified treemap (giống DaisyDisk free version)
   - Right-click: Open in Finder / Move to Trash / Add to Whitelist
   - Top 10 largest files panel

2. **System Monitor** (`Features/Monitor/`):
   - Port Go logic của Mole sang Swift dùng:
     - `host_statistics64` (CPU)
     - `vm_statistics64` (Memory)
     - `IOPSCopyPowerSourcesInfo` (battery)
     - `IOServiceMatching("IOPMrootDomain")` (temp - cần helper hoặc skip nếu khó)
     - `getfsstat` (disk)
     - `getifaddrs` + ioctl (network)
   - SwiftUI Charts để vẽ history 60s
   - Health score 0-100 algorithm
   - Process table top CPU/RAM
   - **Menu bar item** (NSStatusItem) hiện CPU% + RAM% mini chart — *điểm vượt Mole*

**Output**: Hai feature lớn xong, app đã có "đặc sản".

---

### 🛠️ Phase 5 — Project Purge + Installer Cleanup + Optimize (Tuần 10-11)

**Goal**: 3 features còn lại từ Mole, port sang Swift.

**Việc cần làm**:
1. **ProjectPurge** (`Features/Purge/`):
   - Patterns: `node_modules`, `target`, `.build`, `build`, `dist`, `.next`, `venv`, `__pycache__`, `Pods`, `DerivedData`, `.gradle`, `.cargo` — port từ `lib/clean/project.sh`
   - Scan paths configurable: `~/Projects`, `~/GitHub`, `~/dev`, `~/Documents` + custom
   - Hiển thị grouped by project, "Recent" badge (< 7 ngày)
   - Default unchecked cho Recent (an toàn)
   - Dùng `Process` chạy `fd` nếu có, fallback `FileManager` BFS

2. **InstallerCleanup** (`Features/Installer/`):
   - Quét `.dmg`, `.pkg`, `.zip`, `.tar.gz` ở:
     - `~/Downloads`, `~/Desktop`, `~/Library/Caches/Homebrew/downloads`, iCloud, Mail attachments
   - Label nguồn (Downloads/Homebrew/Mail/iCloud)
   - Size + age, default select files > 30 ngày

3. **SystemOptimize** (`Features/Optimize/`):
   - Port từ `lib/optimize/` của Mole. Các task:
     - Rebuild Launch Services: `lsregister -kill -r -domain local -domain system -domain user`
     - Refresh Finder/Dock: `killall Finder Dock`
     - Clear DNS: `dscacheutil -flushcache; killall -HUP mDNSResponder`
     - Rebuild Spotlight: `mdutil -E /`
     - Remove crash logs: `~/Library/Logs/DiagnosticReports/*`
     - Reset swap (nếu free disk thấp): cần sudo
   - **Whitelist UI**: từng task có toggle on/off lưu vào `~/.config/foxclean/optimize_whitelist`
   - Touch ID sudo helper qua `osascript -e "do shell script ... with administrator privileges"`

**Output**: FoxClean parity 100% với Mole về feature.

---

### 🔧 Phase 6 — CLI hoàn chỉnh + Quick Launchers + Menu bar (Tuần 12)

**Goal**: Đảm bảo CLI mạnh ngang Mole, tích hợp Raycast/Alfred.

**Việc cần làm**:
1. **CLI hoàn thiện** (ArgumentParser):
   ```bash
   fox                          # Interactive TUI menu (như mo)
   fox clean [--dry-run] [--debug] [--whitelist] [category]
   fox uninstall <app> [--dry-run]
   fox orphans
   fox purge [--paths] [--dry-run]
   fox installer
   fox analyze [path] [--json]
   fox status [--json] [--watch]
   fox optimize [--whitelist]
   fox log show [--session=<id>]
   fox log rollback <session-id>      # 🆕 đặc sản FoxClean
   fox --help
   fox --version
   ```
2. **TUI mode** dùng `swift-tui` hoặc tự viết với ANSI escape — hỗ trợ vim h/j/k/l
3. **`fox open`** mở GUI app từ terminal
4. **Raycast script commands** trong `scripts/raycast/`
5. **Alfred workflow** trong `scripts/alfred/`
6. **Menu bar app** với `MenuBarExtra` (macOS 13+): mini status + quick scan

**Output**: CLI ngon ngang Mole, Raycast launcher xong.

---

### 🌍 Phase 7 — Polish + i18n + Docs + Release (Tuần 13-14)

**Goal**: Sản phẩm sẵn sàng v1.0.

**Việc cần làm**:
1. **Localization**: vi, en, es, ja, zh-Hans, zh-Hant, ar (mượn của PureMac, dịch + bổ sung)
2. **Animations**: Foxie polish, transitions
3. **Sound effects** (optional, tắt mặc định): pop khi xóa file, chime khi xong
4. **Accessibility**: VoiceOver labels, keyboard shortcuts (Cmd+1..0 chuyển sidebar)
5. **Empty states**: mỗi view có illustration Foxie khi chưa scan
6. **Error handling**: typed errors → friendly messages với Foxie bối rối
7. **Docs**:
   - README.md (đa ngôn ngữ như PureMac)
   - CONTRIBUTING.md
   - SECURITY.md (mượn từ Mole, adapt)
   - ARCHITECTURE.md
   - Screenshots cho 6 features chính
8. **Notarization + signing**:
   - Apple Developer ID
   - DMG đẹp với background custom (Foxie ôm folder Applications)
9. **Homebrew Cask**:
   ```ruby
   cask "foxclean" do
     version "1.0.0"
     url "https://github.com/foxclean/foxclean/releases/..."
     name "FoxClean"
     desc "Cute & powerful Mac cleaner"
     homepage "https://github.com/foxclean/foxclean"
     app "FoxClean.app"
   end
   ```
10. **Website đơn giản** (GitHub Pages): foxclean.dev hoặc tương tự
11. **Tag v1.0.0 release** 🎉

---

## Phần 4: Bảng tóm tắt nguồn gốc tính năng

| Module FoxClean | Học từ PureMac | Học từ Mole | Cải tiến mới |
|---|---|---|---|
| `PathFinder` | 10-level heuristic (chính) | App protection DB | Merge |
| `ScanEngine` | Toàn bộ (chính) | `--json` output | `async/await` |
| `CleaningEngine` | Symlink safety, confirmation | Operation log, dry-run | **Rollback từ Trash** |
| `Onboarding` | Full Disk Access flow | — | Foxie animation |
| `DiskAnalyzer` | — | Algorithm scan | **Treemap visual** |
| `SystemMonitor` | — | Health score, JSON | **Menu bar widget** |
| `ProjectPurge` | — | Patterns, recent badge | UI groupings |
| `InstallerCleanup` | — | Source labels | — |
| `Optimize` | — | Toàn bộ scripts | Touch ID GUI flow |
| `Uninstaller` | UI + sensitivity | Protection DB | Both |
| `CLI` | Embedded CLI mode | 7 commands, TUI | `log rollback` |
| `i18n` | 6 .lproj | — | + Vietnamese |
| `Mascot` | — | Cat reference | **