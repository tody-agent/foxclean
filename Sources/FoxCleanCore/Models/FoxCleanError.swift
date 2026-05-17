import Foundation

public enum FoxCleanError: Error, LocalizedError, Equatable {
    case fullDiskAccessRequired
    case unsafePath(URL)
    case protectedApplication(String)
    case missingFile(URL)
    case operationCancelled
    case rollbackConflict(URL)
    case resourceMissing(String)
    case invalidArgument(String)
    case io(String)

    public var errorDescription: String? {
        switch self {
        case .fullDiskAccessRequired:
            return "Full Disk Access is required for this operation."
        case .unsafePath(let url):
            return "Refused unsafe path: \(url.path)"
        case .protectedApplication(let bundleID):
            return "Protected application cannot be removed: \(bundleID)"
        case .missingFile(let url):
            return "File does not exist: \(url.path)"
        case .operationCancelled:
            return "Operation was cancelled."
        case .rollbackConflict(let url):
            return "Rollback conflict at \(url.path)"
        case .resourceMissing(let name):
            return "Missing bundled resource: \(name)"
        case .invalidArgument(let message):
            return message
        case .io(let message):
            return message
        }
    }
}
