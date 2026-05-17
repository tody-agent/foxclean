import Foundation

public enum FoxCleanVersion {
    public static let version = "1.0.0"
    public static let build = "1"
    public static let userAgent = "FoxClean/\(version)"
}

public enum FoxieMood: String, CaseIterable, Codable, Sendable {
    case idle
    case scanning
    case cleaning
    case success
    case error
    case sleeping
    case curious
    case dancing
}
