import Foundation

public struct PathMatch: Codable, Hashable, Sendable {
    public let url: URL
    public let score: Int
    public let reasons: [String]
}

public struct AppPathFinder: Sendable {
    public let sensitivity: MatchSensitivity
    public let searchRoots: [URL]

    public init(sensitivity: MatchSensitivity = .enhanced, searchRoots: [URL] = AppPathFinder.defaultSearchRoots()) {
        self.sensitivity = sensitivity
        self.searchRoots = searchRoots
    }

    public func score(candidate url: URL, appName: String, bundleIdentifier: String, teamIdentifier: String? = nil, entitlements: [String] = []) -> PathMatch? {
        let normalizedName = normalize(url.deletingPathExtension().lastPathComponent)
        let bundle = normalize(bundleIdentifier)
        let app = normalize(appName)
        let letters = normalize(appName.filter(\.isLetter))
        let bundleParts = bundle.split(separator: ".").map(String.init)
        let lastTwo = bundleParts.suffix(2).joined()
        let company = bundleParts.dropFirst().first ?? ""
        let base = stripHelperSuffix(bundle)
        let strippedApp = stripVersion(app)
        let team = normalize(teamIdentifier ?? "")
        let entitlementTokens = entitlements.flatMap { entitlement in
            entitlement
                .split { !$0.isLetter && !$0.isNumber }
                .map(String.init)
                .map(normalize)
        }.filter { !$0.isEmpty }

        var score = 0
        var reasons: [String] = []
        func add(_ amount: Int, _ reason: String, when condition: Bool) {
            if condition {
                score += amount
                reasons.append(reason)
            }
        }

        add(10, "full bundle id", when: bundle.count >= 5 && normalizedName.contains(bundle))
        add(6, "exact app name", when: app.count >= 5 && normalizedName == app)
        add(5, "app name contains", when: sensitivity != .strict && app.count >= 5 && normalizedName.contains(app))
        add(4, "letters-only app name", when: letters.count >= 5 && normalizedName.contains(letters))
        add(3, "last bundle components", when: sensitivity != .strict && lastTwo.count >= 5 && normalizedName.contains(lastTwo))
        add(3, "base bundle id", when: sensitivity != .strict && base.count >= 5 && normalizedName.contains(base))
        add(2, "version stripped app name", when: sensitivity != .strict && strippedApp.count >= 5 && normalizedName.contains(strippedApp))
        add(2, "company token", when: sensitivity == .deep && company.count >= 5 && normalizedName.contains(company))
        add(2, "team identifier", when: sensitivity == .deep && team.count >= 5 && normalizedName.contains(team))
        add(3, "entitlement token", when: entitlementTokens.contains { $0.count >= 5 && normalizedName.contains($0) })

        guard score >= sensitivity.threshold else { return nil }
        return PathMatch(url: url, score: min(score, 30), reasons: reasons)
    }

    public func findPaths(for app: ScannedApp) async -> [PathMatch] {
        var matches: [PathMatch] = []
        for root in searchRoots where FileManager.default.fileExists(atPath: root.path) {
            if Task.isCancelled { break }
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            var seen = 0
            while let url = enumerator.nextObject() as? URL {
                if Task.isCancelled { break }
                seen += 1
                if seen > 20_000 { break }
                if let match = score(candidate: url, appName: app.name, bundleIdentifier: app.bundleIdentifier) {
                    matches.append(match)
                }
            }
        }
        return filterSubpaths(matches)
    }

    private func filterSubpaths(_ matches: [PathMatch]) -> [PathMatch] {
        let sorted = matches.sorted { $0.url.path < $1.url.path }
        var filtered: [PathMatch] = []
        for match in sorted {
            if filtered.contains(where: { match.url.path.hasPrefix($0.url.path + "/") }) { continue }
            filtered.removeAll { $0.url.path.hasPrefix(match.url.path + "/") }
            filtered.append(match)
        }
        return filtered
    }

    private func normalize(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private func stripVersion(_ value: String) -> String {
        value.replacingOccurrences(of: #"\d+(\.\d+)*$"#, with: "", options: .regularExpression)
    }

    private func stripHelperSuffix(_ value: String) -> String {
        value.replacingOccurrences(of: #"(helper|agent|daemon|loginitem)$"#, with: "", options: .regularExpression)
    }

    public static func defaultSearchRoots(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [URL] {
        [
            home.appendingPathComponent("Library/Application Support"),
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Containers"),
            home.appendingPathComponent("Library/Group Containers"),
            home.appendingPathComponent("Library/HTTPStorages"),
            home.appendingPathComponent("Library/LaunchAgents"),
            home.appendingPathComponent("Library/Logs"),
            home.appendingPathComponent("Library/Preferences"),
            home.appendingPathComponent("Library/Saved Application State"),
            home.appendingPathComponent("Library/WebKit"),
            URL(fileURLWithPath: "/Library/Application Support"),
            URL(fileURLWithPath: "/Library/Caches"),
            URL(fileURLWithPath: "/Library/Logs"),
            URL(fileURLWithPath: "/Library/Preferences"),
        ]
    }
}
