import Foundation

public struct CleanupHint: Codable, Hashable, Sendable {
    public let key: String
    public let title: String
    public let paths: [String]
    public let category: ScanCategory
}

public struct ProtectedAppsResource: Codable, Sendable {
    public let source: String
    public let patterns: [String]
}

public struct CleanupHintsResource: Codable, Sendable {
    public let source: String
    public let hints: [CleanupHint]
}

public struct LocationsResource: Codable, Sendable {
    public let appSearch: [String]
}

public struct ScanCondition: Codable, Hashable, Sendable {
    public let bundleID: String
    public let includeTerms: [String]
    public let excludeTerms: [String]
}

public struct ConditionsResource: Codable, Sendable {
    public let conditions: [ScanCondition]
}

private final class ResourceBundleAnchor {}

public struct RuleDatabase: Sendable {
    public let protectedBundlePatterns: [String]
    public let dataProtectedBundlePatterns: [String]
    public let hints: [CleanupHint]

    public init(
        protectedBundlePatterns: [String] = RuleDatabase.defaultProtectedBundlePatterns,
        dataProtectedBundlePatterns: [String] = RuleDatabase.defaultDataProtectedBundlePatterns,
        hints: [CleanupHint] = RuleDatabase.defaultHints
    ) {
        self.protectedBundlePatterns = protectedBundlePatterns
        self.dataProtectedBundlePatterns = dataProtectedBundlePatterns
        self.hints = hints
    }

    public func isProtected(bundleIdentifier: String, appName: String = "") -> Bool {
        let candidates = [bundleIdentifier, appName.lowercased()].filter { !$0.isEmpty }
        return protectedBundlePatterns.contains { pattern in
            candidates.contains { wildcard($0, matches: pattern) }
        }
    }

    public func protectsUserData(bundleIdentifier: String) -> Bool {
        dataProtectedBundlePatterns.contains { wildcard(bundleIdentifier, matches: $0) }
    }

    public static func bundled() throws -> RuleDatabase {
        let protectedApps: ProtectedAppsResource = try loadResource("protected_apps")
        let cleanupHints: CleanupHintsResource = try loadResource("cleanup_hints")
        return RuleDatabase(
            protectedBundlePatterns: protectedApps.patterns,
            dataProtectedBundlePatterns: defaultDataProtectedBundlePatterns,
            hints: cleanupHints.hints
        )
    }

    public static func loadBundledLocations() throws -> LocationsResource {
        try loadResource("locations")
    }

    public static func loadBundledConditions() throws -> ConditionsResource {
        try loadResource("conditions")
    }

    private static func loadResource<T: Decodable>(_ name: String) throws -> T {
        let url = resourceBundles.lazy.compactMap { bundle in
            bundle.url(forResource: name, withExtension: "json", subdirectory: "Data")
                ?? bundle.url(forResource: name, withExtension: "json")
        }.first
        guard let url else {
            throw FoxCleanError.resourceMissing(name)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static var resourceBundles: [Bundle] {
        var bundles: [Bundle] = []
        #if SWIFT_PACKAGE
        bundles.append(Bundle.module)
        #endif
        bundles.append(Bundle(for: ResourceBundleAnchor.self))
        bundles.append(.main)
        bundles.append(contentsOf: Bundle.allBundles)
        bundles.append(contentsOf: Bundle.allFrameworks)

        var seen: Set<String> = []
        return bundles.filter { bundle in
            seen.insert(bundle.bundlePath).inserted
        }
    }

    private func wildcard(_ value: String, matches pattern: String) -> Bool {
        let regex = "^" + NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*") + "$"
        return value.range(of: regex, options: [.regularExpression, .caseInsensitive]) != nil
    }

    public static let defaultProtectedBundlePatterns: [String] = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.systempreferences",
        "com.apple.SystemSettings",
        "com.apple.loginwindow",
        "com.apple.security*",
        "com.apple.keychain*",
        "com.apple.SoftwareUpdate*",
        "com.apple.installer*",
        "loginwindow",
        "finder",
        "dock",
        "systempreferences",
        "security*",
        "keychain*",
        "tcc",
        "GlobalPreferences",
        ".GlobalPreferences",
        "org.cups.*",
    ]

    public static let defaultDataProtectedBundlePatterns: [String] = [
        "com.1password.*",
        "com.agilebits.*",
        "com.bitwarden.*",
        "com.dashlane.*",
        "com.lastpass.*",
        "com.googlecode.rimeime.*",
        "im.rime.*",
        "*.inputmethod",
        "*.InputMethod",
        "*IME",
    ]

    public static let defaultHints: [CleanupHint] = [
        CleanupHint(key: "xcode-derived-data", title: "Xcode DerivedData", paths: ["~/Library/Developer/Xcode/DerivedData"], category: .xcodeJunk),
        CleanupHint(key: "xcode-archives", title: "Xcode Archives", paths: ["~/Library/Developer/Xcode/Archives"], category: .xcodeJunk),
        CleanupHint(key: "homebrew-cache", title: "Homebrew Cache", paths: ["~/Library/Caches/Homebrew", "/opt/homebrew/Library/Caches", "/usr/local/Homebrew/Library/Caches"], category: .developerCache),
        CleanupHint(key: "npm-cache", title: "npm Cache", paths: ["~/.npm", "~/Library/Caches/npm"], category: .developerCache),
        CleanupHint(key: "yarn-cache", title: "Yarn Cache", paths: ["~/Library/Caches/Yarn"], category: .developerCache),
        CleanupHint(key: "pnpm-store", title: "pnpm Store", paths: ["~/Library/pnpm/store"], category: .developerCache),
        CleanupHint(key: "trash", title: "User Trash", paths: ["~/.Trash"], category: .trash),
        CleanupHint(key: "mail-downloads", title: "Mail Downloads", paths: ["~/Library/Mail Downloads", "~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"], category: .userCache),
    ]
}
