import XCTest
@testable import FoxCleanCore

final class FoxCleanCoreTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(FoxCleanVersion.version, "1.0.0")
    }

    func testPathFinderScoresBundleIdentifier() {
        let finder = AppPathFinder(sensitivity: .enhanced, searchRoots: [])
        let url = URL(fileURLWithPath: "/Users/me/Library/Caches/com.example.Fox.appcache")
        let match = finder.score(candidate: url, appName: "Fox", bundleIdentifier: "com.example.fox")
        XCTAssertNotNil(match)
        XCTAssertGreaterThanOrEqual(match?.score ?? 0, MatchSensitivity.enhanced.threshold)
    }

    func testStrictRejectsWeakMatch() {
        let finder = AppPathFinder(sensitivity: .strict, searchRoots: [])
        let url = URL(fileURLWithPath: "/Users/me/Library/Caches/example")
        XCTAssertNil(finder.score(candidate: url, appName: "Fox", bundleIdentifier: "com.example.fox"))
    }

    func testPathFinderFixtureMatrix() {
        let fixtures: [(String, String, String)] = [
            ("com.apple.dt.Xcode", "Xcode", "com.apple.dt.Xcode"),
            ("com.google.Chrome", "Google Chrome", "com.google.Chrome"),
            ("org.mozilla.firefox", "Firefox", "org.mozilla.firefox"),
            ("com.tinyspeck.slackmacgap", "Slack", "com.tinyspeck.slackmacgap"),
            ("com.microsoft.VSCode", "Visual Studio Code", "com.microsoft.VSCode"),
            ("com.docker.docker", "Docker", "com.docker.docker"),
            ("com.figma.Desktop", "Figma", "com.figma.Desktop"),
            ("com.postmanlabs.mac", "Postman", "com.postmanlabs.mac"),
            ("com.spotify.client", "Spotify", "com.spotify.client"),
            ("us.zoom.xos", "zoom.us", "us.zoom.xos"),
            ("com.adobe.Photoshop", "Adobe Photoshop", "com.adobe.Photoshop"),
            ("com.jetbrains.intellij", "IntelliJ IDEA", "com.jetbrains.intellij"),
            ("com.apple.Safari", "Safari", "com.apple.Safari"),
            ("com.linear", "Linear", "com.linear"),
            ("notion.id", "Notion", "notion.id"),
            ("com.openai.chat", "ChatGPT", "com.openai.chat"),
            ("com.apple.MobileSMS", "Messages", "com.apple.MobileSMS"),
            ("com.flexibits.fantastical2.mac", "Fantastical", "com.flexibits.fantastical2.mac"),
            ("com.todoist.mac.Todoist", "Todoist", "com.todoist.mac.Todoist"),
            ("com.1password.1password", "1Password", "com.1password.1password"),
        ]
        let finder = AppPathFinder(sensitivity: .enhanced, searchRoots: [])

        for (pathToken, appName, bundleID) in fixtures {
            let nameToken = appName.replacingOccurrences(of: " ", with: "")
            let url = URL(fileURLWithPath: "/Users/me/Library/Caches/\(pathToken).\(nameToken).appcache")
            let match = finder.score(candidate: url, appName: appName, bundleIdentifier: bundleID)
            XCTAssertNotNil(match, "Expected \(appName) fixture to match")
            XCTAssertGreaterThanOrEqual(match?.score ?? 0, MatchSensitivity.enhanced.threshold, appName)
        }
    }

    func testPathFinderDeepUsesTeamAndEntitlements() {
        let finder = AppPathFinder(sensitivity: .deep, searchRoots: [])
        let url = URL(fileURLWithPath: "/Users/me/Library/Caches/9Y5TQ6X4Q8.network.client.appcache")
        let match = finder.score(
            candidate: url,
            appName: "Network Client",
            bundleIdentifier: "com.example.client",
            teamIdentifier: "9Y5TQ6X4Q8",
            entitlements: ["com.apple.security.network.client"]
        )
        XCTAssertNotNil(match)
        XCTAssertTrue(match?.reasons.contains("team identifier") == true)
        XCTAssertTrue(match?.reasons.contains("entitlement token") == true)
    }

    func testRuleDatabaseProtectsSystemSettings() {
        let rules = RuleDatabase()
        XCTAssertTrue(rules.isProtected(bundleIdentifier: "com.apple.systempreferences", appName: "System Settings"))
    }

    func testBundledRuleResourcesDecode() throws {
        let rules = try RuleDatabase.bundled()
        let locations = try RuleDatabase.loadBundledLocations()
        let conditions = try RuleDatabase.loadBundledConditions()

        XCTAssertGreaterThanOrEqual(rules.protectedBundlePatterns.count, 10)
        XCTAssertGreaterThanOrEqual(rules.hints.count, 4)
        XCTAssertTrue(rules.isProtected(bundleIdentifier: "com.apple.finder", appName: "Finder"))
        XCTAssertGreaterThanOrEqual(locations.appSearch.count, 10)
        XCTAssertEqual(conditions.conditions.first?.bundleID, "com.apple.dt.Xcode")
    }

    func testHealthScoreBounds() {
        XCTAssertEqual(HealthScore.calculate(cpuLoad: 0, memoryUsedRatio: 0, freeRatio: 1, batteryPercent: 1), 100)
        XCTAssertGreaterThanOrEqual(HealthScore.calculate(cpuLoad: 1, memoryUsedRatio: 1, freeRatio: 0, batteryPercent: 0), 0)
    }

    func testSystemMonitorSnapshotIncludesProcesses() async {
        let snapshot = await SystemMonitor().snapshot()
        XCTAssertGreaterThan(snapshot.processCount, 0)
        XCTAssertLessThanOrEqual(snapshot.topProcesses.count, 5)
        XCTAssertGreaterThanOrEqual(snapshot.cpuLoad, 0)
        XCTAssertLessThanOrEqual(snapshot.cpuLoad, 1)
        XCTAssertGreaterThanOrEqual(snapshot.diskReadBytesPerSecond, 0)
        XCTAssertGreaterThanOrEqual(snapshot.diskWrittenBytesPerSecond, 0)
        XCTAssertFalse(snapshot.thermalState.isEmpty)
    }

    func testTreemapPreservesArea() {
        let nodes = [
            DiskNode(url: URL(fileURLWithPath: "/a"), size: 25),
            DiskNode(url: URL(fileURLWithPath: "/b"), size: 75),
        ]
        let rects = TreemapLayout.layout(nodes: nodes, width: 100, height: 50)
        XCTAssertEqual(rects.count, 2)
        let area = rects.reduce(0) { $0 + ($1.width * $1.height) }
        XCTAssertEqual(area, 5_000, accuracy: 0.001)
    }

    func testTreemapUsesTwoDimensionalRows() {
        let nodes = [
            DiskNode(url: URL(fileURLWithPath: "/a"), size: 60),
            DiskNode(url: URL(fileURLWithPath: "/b"), size: 25),
            DiskNode(url: URL(fileURLWithPath: "/c"), size: 15),
        ]
        let rects = TreemapLayout.layout(nodes: nodes, width: 120, height: 80)
        XCTAssertEqual(rects.count, 3)
        XCTAssertGreaterThan(Set(rects.map { $0.y.rounded() }).count, 1)
    }

    func testDiskScannerReturnsCachedResultWhenRootMTimeUnchanged() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("foxclean-disk-\(UUID().uuidString)")
        let file = root.appendingPathComponent("a.txt")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try "a".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: root) }

        let scanner = DiskScanner()
        let first = try await scanner.scan(path: root, maxDepth: 2)
        let second = try await scanner.scan(path: root, maxDepth: 2)
        XCTAssertEqual(first, second)

        let cache = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("FoxClean/disk_scan_cache.json")
        XCTAssertTrue(cache.map { FileManager.default.fileExists(atPath: $0.path) } ?? false)
    }

    func testProjectScannerRequiresMarker() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("foxclean-tests-\(UUID().uuidString)")
        let project = root.appendingPathComponent("app")
        let artifact = project.appendingPathComponent("node_modules")
        try FileManager.default.createDirectory(at: artifact, withIntermediateDirectories: true)
        try "{}".write(to: project.appendingPathComponent("package.json"), atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: root) }
        let artifacts = ProjectScanner().scan(roots: [root])
        XCTAssertEqual(artifacts.first?.url.resolvingSymlinksInPath().standardizedFileURL, artifact.resolvingSymlinksInPath().standardizedFileURL)
        XCTAssertEqual(artifacts.first?.projectRoot.resolvingSymlinksInPath().standardizedFileURL, project.resolvingSymlinksInPath().standardizedFileURL)
    }

    func testProjectScannerConfiguredRoots() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent("foxclean-home-\(UUID().uuidString)")
        let config = home.appendingPathComponent(".config/foxclean/purge_paths")
        try FileManager.default.createDirectory(at: config.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "~/Work\n# ignored\n/tmp/foxclean-custom\n".write(to: config, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: home) }

        let roots = ProjectScanner.configuredRoots(home: home, configURL: config)
        XCTAssertEqual(roots.count, 2)
        XCTAssertEqual(roots[0], home.appendingPathComponent("Work"))
        XCTAssertEqual(roots[1], URL(fileURLWithPath: "/tmp/foxclean-custom"))
    }

    func testInstallerScannerIncludesHomebrewCache() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent("foxclean-installer-\(UUID().uuidString)")
        let cache = home.appendingPathComponent("Library/Caches/Homebrew")
        let installer = cache.appendingPathComponent("tool.dmg")
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        try "pkg".write(to: installer, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: home) }

        let files = InstallerScanner(home: home).scan()
        let expected = installer.resolvingSymlinksInPath().standardizedFileURL.path
        XCTAssertTrue(files.contains { $0.url.resolvingSymlinksInPath().standardizedFileURL.path == expected })
        XCTAssertEqual(files.first?.source, "Homebrew")
    }

    func testOptimizerExposesIndependentTasks() {
        let optimizer = Optimizer()
        XCTAssertGreaterThanOrEqual(optimizer.tasks.count, 6)
        XCTAssertTrue(optimizer.tasks.contains { $0.requiresAdmin })

        let reports = optimizer.run(selectedTasks: ["clear-quicklook-cache"], dryRun: true)
        XCTAssertEqual(reports.count, 1)
        XCTAssertEqual(reports.first?.id, "clear-quicklook-cache")
        XCTAssertEqual(reports.first?.skipped, true)
    }

    func testOperationLogRoundTrip() async throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("foxclean-log-\(UUID().uuidString)")
        let log = OperationLog(directory: dir)
        let session = UUID()
        try await log.append(OperationEntry(sessionID: session, action: .dryRun, originalPath: "/tmp/a", trashPath: nil, size: 1, category: .trash, success: true, message: "ok"))
        let entries = try await log.entries(forSession: session)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.message, "ok")
        try? FileManager.default.removeItem(at: dir)
    }

    func testFileOperatorDryRun() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("foxclean-op-\(UUID().uuidString)")
        let caches = root.appendingPathComponent("Library/Caches")
        try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        let file = caches.appendingPathComponent("a.tmp")
        try "x".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: root) }
        let item = ScannedFile(url: file, size: 1, category: .userCache)
        let result = await FileOperator(home: root).clean([item], mode: .dryRun, operationLog: OperationLog(directory: root.appendingPathComponent("logs")))
        XCTAssertEqual(result.affectedCount, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
    }

    func testFileOperatorRejectsSymlinkEscapingAllowedRoot() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("foxclean-symlink-\(UUID().uuidString)")
        let caches = root.appendingPathComponent("Library/Caches")
        let target = root.appendingPathComponent("Documents/secret.txt")
        let link = caches.appendingPathComponent("secret-link")
        do {
            try FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            try "secret".write(to: target, atomically: true, encoding: .utf8)
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
            defer { try? FileManager.default.removeItem(at: root) }

            XCTAssertFalse(FileOperator(home: root).isSafeToDelete(link.resolvingSymlinksInPath(), category: .userCache))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
