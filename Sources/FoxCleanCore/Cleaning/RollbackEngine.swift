import Foundation

public actor RollbackEngine {
    private let operationLog: OperationLog

    public init(operationLog: OperationLog = OperationLog()) {
        self.operationLog = operationLog
    }

    public func rollback(sessionID: UUID) async throws -> CleanResult {
        let entries = try await operationLog.entries(forSession: sessionID)
            .filter { $0.action == .trash && $0.success && $0.trashPath != nil }
        var restored = 0
        var bytes: Int64 = 0
        var errors: [String] = []

        for entry in entries {
            guard let trashPath = entry.trashPath else { continue }
            let trashURL = URL(fileURLWithPath: trashPath)
            var destination = URL(fileURLWithPath: entry.originalPath)
            if FileManager.default.fileExists(atPath: destination.path) {
                destination = destination.deletingLastPathComponent()
                    .appendingPathComponent(destination.lastPathComponent + ".restored-\(Int(Date().timeIntervalSince1970))")
            }
            do {
                try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: trashURL, to: destination)
                restored += 1
                bytes += entry.size
                try await operationLog.append(OperationEntry(
                    sessionID: sessionID,
                    action: .rollback,
                    originalPath: entry.originalPath,
                    trashPath: trashPath,
                    size: entry.size,
                    category: entry.category,
                    success: true,
                    message: "Restored"
                ))
            } catch {
                errors.append(error.localizedDescription)
            }
        }

        return CleanResult(sessionID: sessionID, freedBytes: -bytes, affectedCount: restored, errors: errors)
    }
}
