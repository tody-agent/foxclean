import Foundation

public enum ScanCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case systemJunk
    case userCache
    case appCache
    case browserCache
    case xcodeJunk
    case developerCache
    case installers
    case trash
    case largeFiles
    case orphans

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .systemJunk: return "System Junk"
        case .userCache: return "User Cache"
        case .appCache: return "Application Cache"
        case .browserCache: return "Browser Cache"
        case .xcodeJunk: return "Xcode Junk"
        case .developerCache: return "Developer Cache"
        case .installers: return "Installers"
        case .trash: return "Trash"
        case .largeFiles: return "Large Files"
        case .orphans: return "Orphans"
        }
    }
}

public enum MatchSensitivity: String, CaseIterable, Codable, Sendable {
    case strict
    case enhanced
    case deep

    public var threshold: Int {
        switch self {
        case .strict: return 22
        case .enhanced: return 15
        case .deep: return 9
        }
    }
}

public struct ScannedFile: Codable, Hashable, Identifiable, Sendable {
    public var id: String { url.path }
    public let url: URL
    public let size: Int64
    public let category: ScanCategory
    public let confidence: Int
    public let lastModified: Date?
    public let suggested: Bool
    public let source: String?

    public init(url: URL, size: Int64, category: ScanCategory, confidence: Int = 30, lastModified: Date? = nil, suggested: Bool = true, source: String? = nil) {
        self.url = url
        self.size = size
        self.category = category
        self.confidence = confidence
        self.lastModified = lastModified
        self.suggested = suggested
        self.source = source
    }
}

public struct ScannedApp: Codable, Hashable, Identifiable, Sendable {
    public var id: String { bundleIdentifier.isEmpty ? url.path : bundleIdentifier }
    public let name: String
    public let bundleIdentifier: String
    public let url: URL
    public let size: Int64
    public let installDate: Date?
    public let isProtected: Bool

    public init(name: String, bundleIdentifier: String, url: URL, size: Int64, installDate: Date?, isProtected: Bool) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.url = url
        self.size = size
        self.installDate = installDate
        self.isProtected = isProtected
    }
}

public struct CategoryScanResult: Codable, Sendable {
    public let category: ScanCategory
    public let files: [ScannedFile]
    public var totalSize: Int64 { files.reduce(0) { $0 + $1.size } }

    public init(category: ScanCategory, files: [ScannedFile]) {
        self.category = category
        self.files = files
    }
}

public struct OperationEntry: Codable, Hashable, Sendable {
    public enum Action: String, Codable, Sendable {
        case dryRun
        case trash
        case delete
        case rollback
    }

    public let sessionID: UUID
    public let timestamp: Date
    public let action: Action
    public let originalPath: String
    public let trashPath: String?
    public let size: Int64
    public let category: ScanCategory
    public let success: Bool
    public let message: String

    public init(sessionID: UUID, timestamp: Date = Date(), action: Action, originalPath: String, trashPath: String?, size: Int64, category: ScanCategory, success: Bool, message: String) {
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.action = action
        self.originalPath = originalPath
        self.trashPath = trashPath
        self.size = size
        self.category = category
        self.success = success
        self.message = message
    }
}

public struct CleanResult: Codable, Sendable {
    public let sessionID: UUID
    public let freedBytes: Int64
    public let affectedCount: Int
    public let errors: [String]

    public init(sessionID: UUID, freedBytes: Int64, affectedCount: Int, errors: [String]) {
        self.sessionID = sessionID
        self.freedBytes = freedBytes
        self.affectedCount = affectedCount
        self.errors = errors
    }
}
