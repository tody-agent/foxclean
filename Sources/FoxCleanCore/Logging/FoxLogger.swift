import Foundation
import os

public struct FoxLogger: Sendable {
    private let logger = Logger(subsystem: "dev.foxclean", category: "core")

    public init() {}

    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    public func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
