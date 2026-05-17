import Foundation

public struct InstallerScanner: Sendable {
    private let home: URL

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.home = home
    }

    public func scan() -> [ScannedFile] {
        let roots: [(url: URL, source: String)] = [
            (home.appendingPathComponent("Downloads"), "Downloads"),
            (home.appendingPathComponent("Desktop"), "Desktop"),
            (home.appendingPathComponent("Documents"), "Documents"),
            (home.appendingPathComponent("Library/Caches/Homebrew"), "Homebrew"),
            (URL(fileURLWithPath: "/Library/Caches/Homebrew"), "Homebrew"),
            (home.appendingPathComponent("Library/Mail Downloads"), "Mail"),
            (home.appendingPathComponent("Library/Containers/com.apple.mail/Data/Library/Mail Downloads"), "Mail"),
            (home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/Downloads"), "iCloud"),
            (URL(fileURLWithPath: "/Users/Shared"), "Shared"),
            (home.appendingPathComponent("Library/Caches"), "App Cache"),
        ]
        let extensions = Set(["7z", "bz2", "dmg", "gz", "ipa", "ipsw", "pkg", "rar", "tar", "xar", "xz", "zip"])
        var files: [ScannedFile] = []
        for root in roots where FileManager.default.fileExists(atPath: root.url.path) {
            guard let enumerator = FileManager.default.enumerator(at: root.url, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            for case let url as URL in enumerator {
                let ext = url.pathExtension.lowercased()
                let lowercasedName = url.lastPathComponent.lowercased()
                guard extensions.contains(ext) || lowercasedName.hasSuffix(".tar.gz") || lowercasedName.hasSuffix(".tar.bz2") else { continue }
                let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey])
                guard values?.isRegularFile == true else { continue }
                files.append(ScannedFile(url: url, size: Int64(values?.fileSize ?? 0), category: .installers, confidence: 25, lastModified: values?.contentModificationDate, suggested: isOlderThan30Days(values?.contentModificationDate), source: root.source))
            }
        }
        return files.sorted { $0.size > $1.size }
    }

    private func isOlderThan30Days(_ date: Date?) -> Bool {
        guard let date else { return false }
        return date < (Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
    }
}

public struct ProjectArtifact: Codable, Hashable, Identifiable, Sendable {
    public var id: String { url.path }
    public let url: URL
    public let projectRoot: URL
    public let kind: String
    public let size: Int64
    public let isRecent: Bool
}

public struct ProjectScanner: Sendable {
    public init() {}

    public static func configuredRoots(
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        configURL: URL? = nil
    ) -> [URL] {
        let config = configURL ?? home
            .appendingPathComponent(".config")
            .appendingPathComponent("foxclean")
            .appendingPathComponent("purge_paths")

        if let raw = try? String(contentsOf: config, encoding: .utf8) {
            let configured = raw
                .split(whereSeparator: \.isNewline)
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
                .map { expandPath($0, home: home) }
            if !configured.isEmpty {
                return configured
            }
        }

        return [
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("GitHub"),
            home.appendingPathComponent("dev"),
        ]
    }

    public func scan(roots: [URL]) -> [ProjectArtifact] {
        let patterns = ["node_modules", ".next", "dist", "build", ".turbo", ".gradle", "target", ".pytest_cache", "__pycache__", "DerivedData", ".build"]
        let markers = ["package.json", "Cargo.toml", "pyproject.toml", "Package.swift", "go.mod", "pom.xml", "build.gradle"]
        var artifacts: [ProjectArtifact] = []

        for root in roots where FileManager.default.fileExists(atPath: root.path) {
            var seen = 0
            func walk(_ directory: URL) {
                guard seen <= 100_000,
                      let children = try? FileManager.default.contentsOfDirectory(
                        at: directory,
                        includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                        options: [.skipsHiddenFiles]
                      )
                else { return }
                for url in children {
                seen += 1
                    if seen > 100_000 { return }
                    let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey])
                    guard values?.isDirectory == true else { continue }
                    if patterns.contains(url.lastPathComponent),
                       let projectRoot = nearestProjectRoot(from: url.deletingLastPathComponent(), markers: markers, stopAt: root) {
                        let recentCutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        artifacts.append(ProjectArtifact(url: url, projectRoot: projectRoot, kind: url.lastPathComponent, size: directorySize(url), isRecent: (values?.contentModificationDate ?? .distantPast) > recentCutoff))
                    } else {
                        walk(url)
                    }
                }
            }
            walk(root)
        }

        return artifacts.sorted { $0.size > $1.size }
    }

    private func nearestProjectRoot(from start: URL, markers: [String], stopAt: URL) -> URL? {
        var current = start.resolvingSymlinksInPath().standardizedFileURL
        let stopPath = stopAt.resolvingSymlinksInPath().standardizedFileURL.path
        while current.path.hasPrefix(stopPath) {
            if markers.contains(where: { FileManager.default.fileExists(atPath: current.appendingPathComponent($0).path) }) {
                return current
            }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
        }
        return nil
    }
}

private func expandPath(_ path: String, home: URL) -> URL {
    if path == "~" {
        return home
    }
    if path.hasPrefix("~/") {
        return home.appendingPathComponent(String(path.dropFirst(2)))
    }
    return URL(fileURLWithPath: path)
}

public struct OptimizationTaskDescriptor: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let requiresAdmin: Bool
    public let commandPreview: String
}

public struct OptimizationReport: Codable, Sendable {
    public let id: String
    public let task: String
    public let requiresAdmin: Bool
    public let commandPreview: String
    public let success: Bool
    public let skipped: Bool
    public let message: String
}

public struct Optimizer: Sendable {
    public static var defaultWhitelistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/foxclean/optimize_whitelist")
    }

    public let tasks: [OptimizationTaskDescriptor] = [
        .init(
            id: "flush-dns",
            name: "Flush DNS",
            description: "Reset DNS cache through dscacheutil and mDNSResponder.",
            requiresAdmin: true,
            commandPreview: "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
        ),
        .init(
            id: "purge-inactive-memory",
            name: "Purge inactive memory",
            description: "Ask macOS to reclaim inactive memory pages.",
            requiresAdmin: false,
            commandPreview: "/usr/bin/purge"
        ),
        .init(
            id: "trim-logs",
            name: "Trim logs",
            description: "Identify old user logs for cleanup; deletion remains dry-run.",
            requiresAdmin: false,
            commandPreview: "find ~/Library/Logs -mtime +30"
        ),
        .init(
            id: "rebuild-launchservices",
            name: "Rebuild LaunchServices",
            description: "Refresh LaunchServices app registration database.",
            requiresAdmin: false,
            commandPreview: "lsregister -kill -r -domain local -domain system -domain user"
        ),
        .init(
            id: "clear-quicklook-cache",
            name: "Clear QuickLook cache",
            description: "Clear QuickLook preview cache.",
            requiresAdmin: false,
            commandPreview: "qlmanage -r cache"
        ),
        .init(
            id: "verify-disk",
            name: "Verify disk permissions",
            description: "Run disk verification for the boot volume.",
            requiresAdmin: false,
            commandPreview: "diskutil verifyVolume /"
        ),
    ]

    public init() {}

    public static func loadWhitelist(from url: URL = Optimizer.defaultWhitelistURL) -> Set<String> {
        guard let body = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return Set(body
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") })
    }

    public func run(
        selectedTasks: Set<String>? = nil,
        dryRun: Bool = true,
        whitelist: Set<String>? = nil,
        includeSkipped: Bool = false,
        allowAdminPrompt: Bool = false
    ) -> [OptimizationReport] {
        let selected = selectedTasks.map { Set($0.map { $0.lowercased() }) }
        let allowed = whitelist.map { Set($0.map { $0.lowercased() }) }

        return tasks.compactMap { task in
            if let selected, !matches(task, in: selected) {
                return includeSkipped
                    ? report(task, success: true, skipped: true, message: "Skipped (not selected).")
                    : nil
            }
            if let allowed, !allowed.isEmpty, !matches(task, in: allowed) {
                return includeSkipped
                    ? report(task, success: true, skipped: true, message: "Skipped (whitelisted).")
                    : nil
            }
            if dryRun {
                return report(task, success: true, skipped: true, message: "Dry-run: \(task.commandPreview)")
            }
            if task.requiresAdmin {
                guard allowAdminPrompt else {
                    return report(task, success: false, skipped: true, message: "Skipped: requires admin prompt. Run from the GUI or enable Touch ID sudo first.")
                }
                return runWithAdminPrompt(task)
            }
            return run(task)
        }
    }

    private func matches(_ task: OptimizationTaskDescriptor, in values: Set<String>) -> Bool {
        values.contains(task.id) || values.contains(task.name.lowercased())
    }

    private func report(_ task: OptimizationTaskDescriptor, success: Bool, skipped: Bool, message: String) -> OptimizationReport {
        OptimizationReport(
            id: task.id,
            task: task.name,
            requiresAdmin: task.requiresAdmin,
            commandPreview: task.commandPreview,
            success: success,
            skipped: skipped,
            message: message
        )
    }

    private func run(_ task: OptimizationTaskDescriptor) -> OptimizationReport {
        switch task.id {
        case "clear-quicklook-cache":
            return runProcess(task, executable: "/usr/bin/qlmanage", arguments: ["-r", "cache"])
        case "verify-disk":
            return runProcess(task, executable: "/usr/sbin/diskutil", arguments: ["verifyVolume", "/"])
        case "rebuild-launchservices":
            let executable = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
            return runProcess(task, executable: executable, arguments: ["-kill", "-r", "-domain", "local", "-domain", "system", "-domain", "user"])
        case "purge-inactive-memory":
            return runProcess(task, executable: "/usr/bin/purge", arguments: [])
        case "trim-logs":
            return report(task, success: true, skipped: true, message: "Skipped: log deletion remains dry-run to avoid removing diagnostics unexpectedly.")
        default:
            return report(task, success: false, skipped: true, message: "Skipped: unsupported optimization task.")
        }
    }

    private func runWithAdminPrompt(_ task: OptimizationTaskDescriptor) -> OptimizationReport {
        let shellCommand: String
        switch task.id {
        case "flush-dns":
            shellCommand = "/usr/bin/dscacheutil -flushcache && /usr/bin/killall -HUP mDNSResponder"
        default:
            return report(task, success: false, skipped: true, message: "Skipped: no admin command is whitelisted for this task.")
        }

        let escaped = shellCommand
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return runProcess(
            task,
            executable: "/usr/bin/osascript",
            arguments: ["-e", "do shell script \"\(escaped)\" with administrator privileges"]
        )
    }

    private func runProcess(_ task: OptimizationTaskDescriptor, executable: String, arguments: [String]) -> OptimizationReport {
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            return report(task, success: false, skipped: true, message: "Skipped: \(executable) is unavailable.")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        do {
            try process.run()
            process.waitUntilExit()
            let success = process.terminationStatus == 0
            return report(task, success: success, skipped: false, message: success ? "Completed." : "Failed with exit code \(process.terminationStatus).")
        } catch {
            return report(task, success: false, skipped: false, message: error.localizedDescription)
        }
    }
}

private func directorySize(_ url: URL) -> Int64 {
    guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey], options: [.skipsHiddenFiles]) else { return 0 }
    var total: Int64 = 0
    for case let child as URL in enumerator {
        let values = try? child.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey])
        total += Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
    }
    return total
}
