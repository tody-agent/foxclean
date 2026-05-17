import AppKit
import Foundation

public struct FileOperator: Sendable {
    public enum Mode: Sendable {
        case dryRun
        case trash
        case permanentDelete(doubleConfirmed: Bool)
    }

    private let home: URL

    public init(home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.home = home
    }

    public func clean(_ files: [ScannedFile], mode: Mode = .dryRun, operationLog: OperationLog = OperationLog()) async -> CleanResult {
        let sessionID = UUID()
        var freed: Int64 = 0
        var affected = 0
        var errors: [String] = []

        for file in files {
            do {
                let result = try await clean(file, mode: mode)
                affected += result.success ? 1 : 0
                freed += result.success ? file.size : 0
                try await operationLog.append(OperationEntry(
                    sessionID: sessionID,
                    action: result.action,
                    originalPath: file.url.path,
                    trashPath: result.trashPath,
                    size: file.size,
                    category: file.category,
                    success: result.success,
                    message: result.message
                ))
            } catch {
                errors.append(error.localizedDescription)
                try? await operationLog.append(OperationEntry(
                    sessionID: sessionID,
                    action: .dryRun,
                    originalPath: file.url.path,
                    trashPath: nil,
                    size: file.size,
                    category: file.category,
                    success: false,
                    message: error.localizedDescription
                ))
            }
        }

        return CleanResult(sessionID: sessionID, freedBytes: freed, affectedCount: affected, errors: errors)
    }

    private func clean(_ file: ScannedFile, mode: Mode) async throws -> (success: Bool, action: OperationEntry.Action, trashPath: String?, message: String) {
        let resolved = file.url.resolvingSymlinksInPath().standardizedFileURL
        guard FileManager.default.fileExists(atPath: resolved.path) else {
            throw FoxCleanError.missingFile(resolved)
        }
        guard isSafeToDelete(resolved, category: file.category) else {
            throw FoxCleanError.unsafePath(resolved)
        }

        switch mode {
        case .dryRun:
            return (true, .dryRun, nil, "Dry-run only")
        case .trash:
            var resultingURL: NSURL?
            try FileManager.default.trashItem(at: resolved, resultingItemURL: &resultingURL)
            return (true, .trash, resultingURL?.path, "Moved to Trash")
        case .permanentDelete(let doubleConfirmed):
            guard doubleConfirmed else {
                throw FoxCleanError.invalidArgument("Permanent delete requires double confirmation.")
            }
            try FileManager.default.removeItem(at: resolved)
            return (true, .delete, nil, "Deleted permanently")
        }
    }

    public func isSafeToDelete(_ url: URL, category: ScanCategory) -> Bool {
        let path = url.standardizedFileURL.path
        let allowedRoots = [
            home.appendingPathComponent("Library/Caches").path,
            home.appendingPathComponent("Library/Logs").path,
            home.appendingPathComponent("Library/Saved Application State").path,
            home.appendingPathComponent("Library/HTTPStorages").path,
            home.appendingPathComponent("Library/WebKit").path,
            home.appendingPathComponent("Library/Containers").path,
            home.appendingPathComponent("Library/Group Containers").path,
            home.appendingPathComponent("Library/Application Support").path,
            home.appendingPathComponent("Library/Preferences").path,
            home.appendingPathComponent("Library/LaunchAgents").path,
            home.appendingPathComponent("Library/Mail Downloads").path,
            home.appendingPathComponent("Library/Developer/Xcode/DerivedData").path,
            home.appendingPathComponent("Library/Developer/Xcode/Archives").path,
            home.appendingPathComponent(".Trash").path,
            home.appendingPathComponent(".npm").path,
            home.appendingPathComponent(".cache").path,
            URL(fileURLWithPath: "/Library/Caches").path,
            URL(fileURLWithPath: "/Library/Logs").path,
            URL(fileURLWithPath: "/private/var/log").path,
            URL(fileURLWithPath: "/private/var/tmp").path,
            URL(fileURLWithPath: "/tmp").path,
        ]
        if category == .largeFiles {
            let singleFileRoots = [
                home.appendingPathComponent("Downloads").path + "/",
                home.appendingPathComponent("Documents").path + "/",
                home.appendingPathComponent("Desktop").path + "/",
            ]
            return singleFileRoots.contains { path.hasPrefix($0) }
        }
        return allowedRoots.contains { root in path == root || path.hasPrefix(root + "/") }
    }
}
