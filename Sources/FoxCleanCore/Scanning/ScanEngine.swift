import AppKit
import Foundation

public enum ScanEvent: Sendable {
    case started(String)
    case progress(Double, String)
    case completed(String)
}

public actor ScanEngine {
    private let fileManager: FileManager
    private let rules: RuleDatabase
    private let home: URL

    public init(fileManager: FileManager = .default, rules: RuleDatabase = RuleDatabase(), home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.fileManager = fileManager
        self.rules = rules
        self.home = home
    }

    public func scanInstalledApps() async throws -> [ScannedApp] {
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            home.appendingPathComponent("Applications"),
            URL(fileURLWithPath: "/Applications/Setapp"),
        ]

        var apps: [ScannedApp] = []
        for root in roots where fileManager.fileExists(atPath: root.path) {
            if Task.isCancelled { throw FoxCleanError.operationCancelled }
            let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
            guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: [.contentModificationDateKey], options: options) else { continue }
            while let url = enumerator.nextObject() as? URL {
                guard url.pathExtension == "app" else { continue }
                if Task.isCancelled { throw FoxCleanError.operationCancelled }
                apps.append(appInfo(at: url))
                enumerator.skipDescendants()
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func scanSystemJunk() async throws -> CategoryScanResult {
        let targets: [(URL, ScanCategory, Bool)] = [
            (URL(fileURLWithPath: "/Library/Caches"), .systemJunk, false),
            (URL(fileURLWithPath: "/Library/Logs"), .systemJunk, true),
            (URL(fileURLWithPath: "/private/var/log"), .systemJunk, true),
            (home.appendingPathComponent("Library/Logs"), .systemJunk, true),
            (URL(fileURLWithPath: "/tmp"), .systemJunk, false),
            (URL(fileURLWithPath: "/private/var/tmp"), .systemJunk, false),
            (home.appendingPathComponent("Library/Caches"), .userCache, false),
            (home.appendingPathComponent("Library/Developer/Xcode/DerivedData"), .xcodeJunk, false),
            (home.appendingPathComponent("Library/Developer/Xcode/Archives"), .xcodeJunk, false),
            (home.appendingPathComponent("Library/Developer/CoreSimulator/Caches"), .xcodeJunk, false),
        ]

        var files: [ScannedFile] = []
        for target in targets {
            if Task.isCancelled { throw FoxCleanError.operationCancelled }
            files.append(contentsOf: scanDirectory(target.0, category: target.1, recursive: target.2, maxDepth: target.2 ? 2 : 1))
        }

        for hint in rules.hints {
            for path in hint.paths {
                let url = expand(path)
                if let file = scannedRoot(url, category: hint.category, suggested: hint.category != .largeFiles) {
                    files.append(file)
                }
            }
        }

        return CategoryScanResult(category: .systemJunk, files: deduplicate(files))
    }

    public func scanCategory(_ category: ScanCategory) async throws -> CategoryScanResult {
        switch category {
        case .orphans:
            return try await scanOrphans()
        case .installers:
            let installers = InstallerScanner(home: home).scan()
            return CategoryScanResult(category: .installers, files: installers)
        case .largeFiles:
            return try await scanLargeFiles()
        default:
            let all = try await scanSystemJunk().files
            return CategoryScanResult(category: category, files: all.filter { $0.category == category })
        }
    }

    public func scanOrphans(sensitivity: MatchSensitivity = .enhanced) async throws -> CategoryScanResult {
        let apps = try await scanInstalledApps()
        let installedIDs = Set(apps.map(\.bundleIdentifier).filter { !$0.isEmpty })
        let installedNames = Set(apps.map { normalize($0.name) })
        let roots = [
            home.appendingPathComponent("Library/Application Support"),
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Preferences"),
            home.appendingPathComponent("Library/Containers"),
            home.appendingPathComponent("Library/Logs"),
        ]

        var files: [ScannedFile] = []
        for root in roots where fileManager.fileExists(atPath: root.path) {
            if Task.isCancelled { throw FoxCleanError.operationCancelled }
            guard let children = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles]) else { continue }
            for url in children {
                let token = normalize(url.deletingPathExtension().lastPathComponent)
                let claimedByBundle = installedIDs.contains { id in token.contains(normalize(id)) || normalize(id).contains(token) }
                let claimedByName = installedNames.contains { name in token.count >= 5 && (token.contains(name) || name.contains(token)) }
                guard !claimedByBundle && !claimedByName else { continue }
                if let file = scannedRoot(url, category: .orphans, confidence: sensitivity == .strict ? 18 : 12, suggested: false) {
                    files.append(file)
                }
            }
        }
        return CategoryScanResult(category: .orphans, files: files.sorted { $0.size > $1.size })
    }

    public func progressStream(categories: [ScanCategory] = ScanCategory.allCases) -> AsyncThrowingStream<ScanEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    continuation.yield(.started("scan"))
                    for (index, category) in categories.enumerated() {
                        _ = try await scanCategory(category)
                        continuation.yield(.progress(Double(index + 1) / Double(categories.count), category.title))
                    }
                    continuation.yield(.completed("scan"))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func scanLargeFiles() async throws -> CategoryScanResult {
        let roots = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
        ]
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        var files: [ScannedFile] = []
        for root in roots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            var seen = 0
            while let url = enumerator.nextObject() as? URL {
                if Task.isCancelled { throw FoxCleanError.operationCancelled }
                seen += 1
                if seen > 100_000 { break }
                let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey])
                guard values?.isRegularFile == true, let size = values?.fileSize else { continue }
                let date = values?.contentModificationDate
                if Int64(size) >= 100 * 1024 * 1024 || (Int64(size) >= 10 * 1024 * 1024 && (date ?? Date()) < oneYearAgo) {
                    files.append(ScannedFile(url: url, size: Int64(size), category: .largeFiles, confidence: 20, lastModified: date, suggested: false))
                }
            }
        }
        return CategoryScanResult(category: .largeFiles, files: files.sorted { $0.size > $1.size })
    }

    private func appInfo(at url: URL) -> ScannedApp {
        let infoURL = url.appendingPathComponent("Contents/Info.plist")
        let info = NSDictionary(contentsOf: infoURL)
        let name = (info?["CFBundleDisplayName"] as? String)
            ?? (info?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let bundleID = info?["CFBundleIdentifier"] as? String ?? ""
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return ScannedApp(
            name: name,
            bundleIdentifier: bundleID,
            url: url,
            size: directorySize(url),
            installDate: values?.contentModificationDate,
            isProtected: url.path.hasPrefix("/System/Applications/") || rules.isProtected(bundleIdentifier: bundleID, appName: name)
        )
    }

    private func scanDirectory(_ url: URL, category: ScanCategory, recursive: Bool, maxDepth: Int) -> [ScannedFile] {
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        if !recursive { return scannedRoot(url, category: category).map { [$0] } ?? [] }

        var files: [ScannedFile] = []
        func walk(_ current: URL, depth: Int) {
            guard depth <= maxDepth, let children = try? fileManager.contentsOfDirectory(at: current, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles]) else { return }
            for child in children {
                if let file = scannedRoot(child, category: category) {
                    files.append(file)
                }
                if depth < maxDepth {
                    walk(child, depth: depth + 1)
                }
            }
        }
        walk(url, depth: 0)
        return files
    }

    private func scannedRoot(_ url: URL, category: ScanCategory, confidence: Int = 30, suggested: Bool = true) -> ScannedFile? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey, .contentModificationDateKey, .isDirectoryKey])
        let isDirectory = values?.isDirectory ?? false
        let size = isDirectory ? directorySize(url) : Int64(values?.fileSize ?? values?.totalFileAllocatedSize ?? 0)
        guard size > 0 || category == .trash else { return nil }
        return ScannedFile(url: url, size: size, category: category, confidence: confidence, lastModified: values?.contentModificationDate, suggested: suggested)
    }

    private func directorySize(_ url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey], options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        var seen = 0
        for case let file as URL in enumerator {
            seen += 1
            if seen > 200_000 { break }
            let values = try? file.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey])
            total += Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
        }
        return total
    }

    private func deduplicate(_ files: [ScannedFile]) -> [ScannedFile] {
        var seen: Set<String> = []
        return files.filter { seen.insert($0.url.standardizedFileURL.path).inserted }
    }

    private func expand(_ path: String) -> URL {
        if path == "~" { return home }
        if path.hasPrefix("~/") {
            return home.appendingPathComponent(String(path.dropFirst(2)))
        }
        return URL(fileURLWithPath: path)
    }

    private func normalize(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
