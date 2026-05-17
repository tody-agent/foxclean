import Foundation
import FoxCleanCore
import Darwin

@main
struct FoxCLI {
    private struct TouchIDStatus: Codable {
        let enabled: Bool
        let checkedFiles: [String]
        let targetFile: String
        let needsAdmin: Bool
        let writable: Bool
        let message: String
    }

    private struct TouchIDPlan: Codable {
        let command: String
        let targetFile: String
        let enabledBefore: Bool
        let wouldChange: Bool
        let needsAdmin: Bool
        let message: String
    }

    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        do {
            try await run(args)
        } catch {
            FileHandle.standardError.write(Data("fox: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    static func run(_ args: [String]) async throws {
        guard let command = args.first else {
            if isInteractiveTerminal {
                try await runInteractiveMenu()
            } else {
                printUsage()
            }
            return
        }

        switch command {
        case "--version", "-v", "version":
            print("fox \(FoxCleanVersion.version)")
        case "--help", "-h", "help":
            printUsage()
        case "scan":
            try await scan(Array(args.dropFirst()))
        case "clean":
            try await clean(Array(args.dropFirst()))
        case "uninstall":
            try await uninstall(Array(args.dropFirst()))
        case "log":
            try await log(Array(args.dropFirst()))
        case "analyze":
            try await analyze(Array(args.dropFirst()))
        case "status":
            try await status(Array(args.dropFirst()))
        case "purge":
            purge(Array(args.dropFirst()))
        case "installer":
            installer(Array(args.dropFirst()))
        case "optimize":
            optimize(Array(args.dropFirst()))
        case "completion":
            completion(Array(args.dropFirst()))
        case "open":
            openGUI(Array(args.dropFirst()))
        case "touchid":
            try touchID(Array(args.dropFirst()))
        default:
            throw FoxCleanError.invalidArgument("Unknown command: \(command)")
        }
    }

    private static func scan(_ args: [String]) async throws {
        let engine = ScanEngine()
        let json = args.contains("--json")
        let subcommand = args.first { !$0.hasPrefix("-") }
        switch subcommand {
        case "apps":
            let apps = try await engine.scanInstalledApps()
            if json {
                printJSON(apps)
            } else {
                for app in apps {
                    print("\(app.isProtected ? "LOCK" : "APP ") \(app.name) [\(app.bundleIdentifier)]")
                }
            }
        case "orphans":
            printResult(try await engine.scanOrphans(), json: json)
        case "junk", nil:
            printResult(try await engine.scanSystemJunk(), json: json)
        default:
            if let category = ScanCategory.allCases.first(where: { $0.rawValue == subcommand }) {
                printResult(try await engine.scanCategory(category), json: json)
            } else {
                throw FoxCleanError.invalidArgument("Unknown scan target: \(subcommand ?? "")")
            }
        }
    }

    private static func clean(_ args: [String]) async throws {
        let confirmed = args.contains("--confirm")
        let permanent = args.contains("--permanent") && args.contains("--confirm-permanent")
        let categoryName = args.first { !$0.hasPrefix("-") } ?? "systemJunk"
        let category = ScanCategory(rawValue: categoryName) ?? .systemJunk
        let result = try await ScanEngine().scanCategory(category)
        let mode: FileOperator.Mode = permanent ? .permanentDelete(doubleConfirmed: true) : (confirmed ? .trash : .dryRun)
        let cleanResult = await FileOperator().clean(result.files.filter(\.suggested), mode: mode)
        printJSON(cleanResult)
    }

    private static func uninstall(_ args: [String]) async throws {
        guard let needle = args.first, !needle.hasPrefix("-") else {
            throw FoxCleanError.invalidArgument("Usage: fox uninstall <app-name-or-bundle-id> [--confirm]")
        }
        let confirmed = args.contains("--confirm")
        let engine = ScanEngine()
        guard let app = try await engine.scanInstalledApps().first(where: {
            $0.name.localizedCaseInsensitiveContains(needle) || $0.bundleIdentifier.localizedCaseInsensitiveContains(needle)
        }) else {
            throw FoxCleanError.invalidArgument("No installed app matched \(needle)")
        }
        guard !app.isProtected else { throw FoxCleanError.protectedApplication(app.bundleIdentifier) }
        let matches = await AppPathFinder().findPaths(for: app)
        let files = matches.map { ScannedFile(url: $0.url, size: 0, category: .appCache, confidence: $0.score, suggested: true) }
        let mode: FileOperator.Mode = confirmed ? .trash : .dryRun
        printJSON(await FileOperator().clean(files, mode: mode))
    }

    private static func log(_ args: [String]) async throws {
        let log = OperationLog()
        if args.first == "rollback", args.count >= 2, let id = UUID(uuidString: args[1]) {
            printJSON(try await RollbackEngine(operationLog: log).rollback(sessionID: id))
        } else if args.first == "show" {
            printJSON(try await log.allEntries())
        } else {
            printJSON(try await log.sessions().map(\.uuidString))
        }
    }

    private static func analyze(_ args: [String]) async throws {
        let path = URL(fileURLWithPath: args.first { !$0.hasPrefix("-") } ?? FileManager.default.currentDirectoryPath)
        let node = try await DiskScanner().scan(path: path)
        if args.contains("--json") {
            printJSON(node)
        } else {
            printTree(node)
        }
    }

    private static func status(_ args: [String]) async throws {
        let monitor = SystemMonitor()
        if args.contains("--watch") {
            for await snapshot in await monitor.stream() {
                let read = ByteCountFormatter.string(fromByteCount: Int64(snapshot.diskReadBytesPerSecond), countStyle: .file)
                let written = ByteCountFormatter.string(fromByteCount: Int64(snapshot.diskWrittenBytesPerSecond), countStyle: .file)
                print("Health \(snapshot.healthScore) CPU \(percent(snapshot.cpuLoad)) MEM \(percent(snapshot.memoryUsedRatio)) DISK \(read)/s read \(written)/s write THERMAL \(snapshot.thermalState)")
            }
        } else {
            printJSON(await monitor.snapshot())
        }
    }

    private static func purge(_ args: [String]) {
        let roots = values(after: "--paths", in: args).map(URL.init(fileURLWithPath:))
        printJSON(ProjectScanner().scan(roots: roots.isEmpty ? ProjectScanner.configuredRoots() : roots))
    }

    private static func installer(_ args: [String]) {
        printJSON(InstallerScanner().scan())
    }

    private static func optimize(_ args: [String]) {
        let selected = Set(values(after: "--tasks", in: args))
        let whitelist = args.contains("--whitelist") ? Optimizer.loadWhitelist() : nil
        printJSON(Optimizer().run(
            selectedTasks: selected.isEmpty ? nil : selected,
            dryRun: !args.contains("--confirm"),
            whitelist: whitelist,
            includeSkipped: args.contains("--whitelist"),
            allowAdminPrompt: args.contains("--admin-prompt")
        ))
    }

    private static func completion(_ args: [String]) {
        let shell = args.first ?? "zsh"
        switch shell {
        case "zsh":
            print("""
            #compdef fox
            _fox() {
              local -a commands
              commands=(
                'scan:scan apps, orphans, junk, or a cleanup category'
                'clean:clean a category, dry-run by default'
                'uninstall:remove app support files, dry-run by default'
                'log:show operation log or rollback a session'
                'analyze:scan disk usage for a path'
                'status:print system status'
                'purge:find project build artifacts'
                'installer:find installer archives'
                'optimize:run optimization tasks'
                'completion:generate shell completion'
                'open:open the FoxClean GUI'
                'touchid:show Touch ID sudo status'
              )
              _describe 'fox command' commands
            }
            _fox "$@"
            """)
        case "bash":
            print("""
            _fox_completion() {
              local cur="${COMP_WORDS[COMP_CWORD]}"
              local commands="scan clean uninstall log analyze status purge installer optimize completion open touchid help version"
              COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
            }
            complete -F _fox_completion fox
            """)
        case "fish":
            print("""
            complete -c fox -f -n '__fish_use_subcommand' -a 'scan' -d 'Scan apps, orphans, junk, or a cleanup category'
            complete -c fox -f -n '__fish_use_subcommand' -a 'clean' -d 'Clean a category, dry-run by default'
            complete -c fox -f -n '__fish_use_subcommand' -a 'uninstall' -d 'Remove app support files, dry-run by default'
            complete -c fox -f -n '__fish_use_subcommand' -a 'log' -d 'Show operation log or rollback a session'
            complete -c fox -f -n '__fish_use_subcommand' -a 'analyze' -d 'Scan disk usage for a path'
            complete -c fox -f -n '__fish_use_subcommand' -a 'status' -d 'Print system status'
            complete -c fox -f -n '__fish_use_subcommand' -a 'purge' -d 'Find project build artifacts'
            complete -c fox -f -n '__fish_use_subcommand' -a 'installer' -d 'Find installer archives'
            complete -c fox -f -n '__fish_use_subcommand' -a 'optimize' -d 'Run optimization tasks'
            complete -c fox -f -n '__fish_use_subcommand' -a 'completion' -d 'Generate shell completion'
            complete -c fox -f -n '__fish_use_subcommand' -a 'open' -d 'Open the FoxClean GUI'
            complete -c fox -f -n '__fish_use_subcommand' -a 'touchid' -d 'Show Touch ID sudo status'
            """)
        default:
            print("Unsupported shell: \(shell). Supported shells: zsh, bash, fish")
        }
    }

    private static func openGUI(_ args: [String]) {
        let view = args.first { !$0.hasPrefix("-") } ?? "dashboard"
        let url = "foxclean://\(view)"
        if args.contains("--print-url") {
            print(url)
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [url]
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                throw FoxCleanError.invalidArgument("Could not open \(url)")
            }
        } catch {
            FileHandle.standardError.write(Data("fox: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }

    private static func touchID(_ args: [String]) throws {
        let command = args.first ?? "status"
        let json = args.contains("--json")
        let dryRun = args.contains("--dry-run")
        switch command {
        case "enable":
            let plan = touchIDPlan(command: "enable")
            if dryRun {
                printTouchIDPlan(plan, json: json)
                return
            }
            try setTouchIDEnabled(true)
            printTouchIDStatus(json: json)
        case "disable":
            let plan = touchIDPlan(command: "disable")
            if dryRun {
                printTouchIDPlan(plan, json: json)
                return
            }
            try setTouchIDEnabled(false)
            printTouchIDStatus(json: json)
        default:
            printTouchIDStatus(json: json)
        }
    }

    private static func printTouchIDStatus(json: Bool) {
        let status = touchIDStatus()
        if json {
            printJSON(status)
        } else {
            print(status.message)
        }
    }

    private static func printTouchIDPlan(_ plan: TouchIDPlan, json: Bool) {
        if json {
            printJSON(plan)
        } else {
            print(plan.message)
        }
    }

    private static func touchIDStatus() -> TouchIDStatus {
        let files = ["/etc/pam.d/sudo_local", "/etc/pam.d/sudo"]
        let enabled = files.contains { path in
            (try? String(contentsOfFile: path)).map { $0.contains("pam_tid.so") } ?? false
        }
        let target = "/etc/pam.d/sudo_local"
        let writable = FileManager.default.isWritableFile(atPath: target) || geteuid() == 0
        let needsAdmin = !writable
        return TouchIDStatus(
            enabled: enabled,
            checkedFiles: files,
            targetFile: target,
            needsAdmin: needsAdmin,
            writable: writable,
            message: enabled ? "Touch ID sudo appears enabled." : "Touch ID sudo is not enabled."
        )
    }

    private static func touchIDPlan(command: String) -> TouchIDPlan {
        let status = touchIDStatus()
        let enabling = command == "enable"
        let wouldChange = enabling ? !status.enabled : status.enabled
        return TouchIDPlan(
            command: command,
            targetFile: status.targetFile,
            enabledBefore: status.enabled,
            wouldChange: wouldChange,
            needsAdmin: status.needsAdmin,
            message: wouldChange
                ? "fox touchid \(command) will update \(status.targetFile)\(status.needsAdmin ? " through sudo" : "")."
                : "Touch ID sudo is already \(enabling ? "enabled" : "disabled")."
        )
    }

    private static func setTouchIDEnabled(_ enabled: Bool) throws {
        if geteuid() == 0 || FileManager.default.isWritableFile(atPath: "/etc/pam.d/sudo_local") {
            try editSudoLocal(enabled: enabled)
        } else {
            try runSudoTouchIDEdit(enabled: enabled)
        }
    }

    private static func editSudoLocal(enabled: Bool) throws {
        let path = "/etc/pam.d/sudo_local"
        let url = URL(fileURLWithPath: path)
        let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let lines = existing.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let filtered = lines.filter { !$0.contains("pam_tid.so") }
        let updatedLines = enabled ? ["auth       sufficient     pam_tid.so"] + filtered : filtered
        let updated = updatedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        if existing != updated, FileManager.default.fileExists(atPath: path) {
            try? existing.write(to: URL(fileURLWithPath: "\(path).foxclean.bak"), atomically: true, encoding: .utf8)
        }
        try updated.write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: path)
    }

    private static func runSudoTouchIDEdit(enabled: Bool) throws {
        let script: String
        if enabled {
            script = """
            set -e
            file=/etc/pam.d/sudo_local
            touch "$file"
            cp "$file" "$file.foxclean.bak" 2>/dev/null || true
            grep -v 'pam_tid\\.so' "$file" > "$file.tmp"
            { printf '%s\\n' 'auth       sufficient     pam_tid.so'; cat "$file.tmp"; } > "$file"
            rm -f "$file.tmp"
            chmod 644 "$file"
            """
        } else {
            script = """
            set -e
            file=/etc/pam.d/sudo_local
            [ -f "$file" ] || exit 0
            cp "$file" "$file.foxclean.bak" 2>/dev/null || true
            grep -v 'pam_tid\\.so' "$file" > "$file.tmp" || true
            cat "$file.tmp" > "$file"
            rm -f "$file.tmp"
            chmod 644 "$file"
            """
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["/bin/sh", "-c", script]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw FoxCleanError.invalidArgument("Touch ID sudo update failed or was cancelled.")
        }
    }

    private static func printResult(_ result: CategoryScanResult, json: Bool) {
        if json {
            printJSON(result)
        } else {
            print("\(result.category.title): \(result.files.count) items, \(ByteCountFormatter.string(fromByteCount: result.totalSize, countStyle: .file))")
            for file in result.files.prefix(50) {
                print("  \(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file)) \(file.url.path)")
            }
        }
    }

    private static func printTree(_ node: DiskNode, indent: String = "") {
        print("\(indent)\(ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file)) \(node.url.lastPathComponent)")
        for child in node.children.prefix(20) {
            printTree(child, indent: indent + "  ")
        }
    }

    private static func printJSON<T: Encodable>(_ value: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = (try? encoder.encode(value)) ?? Data("null".utf8)
        print(String(decoding: data, as: UTF8.self))
    }

    private static func values(after flag: String, in args: [String]) -> [String] {
        guard let index = args.firstIndex(of: flag), index + 1 < args.count else { return [] }
        return args[index + 1].split(separator: ",").map(String.init)
    }

    private static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static var isInteractiveTerminal: Bool {
        isatty(STDIN_FILENO) == 1 && isatty(STDOUT_FILENO) == 1
    }

    private struct MenuOption {
        let title: String
        let detail: String
        let command: [String]
    }

    private static let menuOptions: [MenuOption] = [
        MenuOption(title: "Smart Scan", detail: "Scan system junk", command: ["scan", "junk"]),
        MenuOption(title: "Installed Apps", detail: "List apps and protected bundles", command: ["scan", "apps"]),
        MenuOption(title: "Orphaned Files", detail: "Find leftovers", command: ["scan", "orphans"]),
        MenuOption(title: "Disk Analyzer", detail: "Analyze current directory", command: ["analyze", "."]),
        MenuOption(title: "System Status", detail: "Print local health metrics", command: ["status"]),
        MenuOption(title: "Project Purge", detail: "Find build artifacts", command: ["purge"]),
        MenuOption(title: "Installer Cleanup", detail: "Find installers and archives", command: ["installer"]),
        MenuOption(title: "Optimize", detail: "Preview maintenance tasks", command: ["optimize"]),
        MenuOption(title: "Open GUI", detail: "Launch FoxClean window", command: ["open"]),
    ]

    private static func runInteractiveMenu() async throws {
        var selected = 0
        var term = termios()
        let hasTerm = tcgetattr(STDIN_FILENO, &term) == 0
        let original = term
        if hasTerm {
            term.c_lflag &= ~UInt(ECHO | ICANON)
            term.c_cc.16 = 1
            term.c_cc.17 = 0
            tcsetattr(STDIN_FILENO, TCSANOW, &term)
        }
        defer {
            if hasTerm {
                var restore = original
                tcsetattr(STDIN_FILENO, TCSANOW, &restore)
            }
        }

        while true {
            renderMenu(selected: selected)
            let key = readMenuKey()
            switch key {
            case "up":
                selected = (selected - 1 + menuOptions.count) % menuOptions.count
            case "down":
                selected = (selected + 1) % menuOptions.count
            case "enter", "right":
                print("\u{001B}[2J\u{001B}[H")
                try await run(menuOptions[selected].command)
                return
            case "quit":
                print("\u{001B}[2J\u{001B}[H")
                return
            default:
                if key.hasPrefix("select:"),
                   let index = Int(key.dropFirst("select:".count)),
                   menuOptions.indices.contains(index) {
                    selected = index
                    print("\u{001B}[2J\u{001B}[H")
                    try await run(menuOptions[selected].command)
                    return
                }
                break
            }
        }
    }

    private static func renderMenu(selected: Int) {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
        print("""
         /\\_/\\
        ( o.o )  FoxClean \(FoxCleanVersion.version)
         > ^ <

        Use j/k or arrows, Enter/l to run, q to quit.

        """)
        for (index, option) in menuOptions.enumerated() {
            let marker = index == selected ? ">" : " "
            let number = "\(index + 1).".padding(toLength: 3, withPad: " ", startingAt: 0)
            print("\(marker) \(number) \(option.title.padding(toLength: 18, withPad: " ", startingAt: 0)) \(option.detail)")
        }
        print("")
    }

    private static func readMenuKey() -> String {
        var byte: UInt8 = 0
        guard read(STDIN_FILENO, &byte, 1) == 1 else { return "quit" }
        switch byte {
        case 3, 113:
            return "quit"
        case 10, 13:
            return "enter"
        case 106:
            return "down"
        case 107:
            return "up"
        case 108:
            return "right"
        case 27:
            var sequence = [UInt8](repeating: 0, count: 2)
            guard read(STDIN_FILENO, &sequence, 2) == 2 else { return "" }
            if sequence == [91, 65] { return "up" }
            if sequence == [91, 66] { return "down" }
            if sequence == [91, 67] { return "right" }
            return ""
        default:
            let digit = Int(byte) - 49
            if menuOptions.indices.contains(digit) {
                return "select:\(digit)"
            }
            return ""
        }
    }

    private static func printUsage() {
        print("""
        Usage: fox <command> [options]

        Commands:
          scan apps|orphans|junk [--json]
          clean <category> [--confirm] [--permanent --confirm-permanent]
          uninstall <app> [--confirm]
          log show | log rollback <session>
          analyze [path] [--json]
          status [--watch]
          purge [--paths a,b]
          installer
          optimize [--tasks id1,id2] [--whitelist] [--confirm] [--admin-prompt]
          completion {zsh,bash,fish}
          open [view] [--print-url]
          touchid {status,enable,disable} [--dry-run] [--json]
        """)
    }
}
