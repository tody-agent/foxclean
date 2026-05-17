import Foundation

public actor OperationLog {
    private let directory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directory: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/FoxClean")) {
        self.directory = directory
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public func append(_ entry: OperationEntry) async throws {
        guard ProcessInfo.processInfo.environment["FOX_NO_OPLOG"] == nil else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(entry)
        let file = logFile(for: entry.timestamp)
        if !FileManager.default.fileExists(atPath: file.path) {
            FileManager.default.createFile(atPath: file.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.write(contentsOf: Data("\n".utf8))
        try handle.close()
    }

    public func sessions() async throws -> [UUID] {
        let entries = try await allEntries()
        return Array(Set(entries.map(\.sessionID))).sorted { $0.uuidString < $1.uuidString }
    }

    public func entries(forSession sessionID: UUID) async throws -> [OperationEntry] {
        try await allEntries().filter { $0.sessionID == sessionID }
    }

    public func allEntries() async throws -> [OperationEntry] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        var entries: [OperationEntry] = []
        for file in files where file.lastPathComponent.hasPrefix("operations-") && file.pathExtension == "jsonl" {
            let text = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
            for line in text.split(separator: "\n") {
                if let data = line.data(using: .utf8),
                   let entry = try? decoder.decode(OperationEntry.self, from: data) {
                    entries.append(entry)
                }
            }
        }
        return entries.sorted { $0.timestamp < $1.timestamp }
    }

    public func rotate(keepingDays days: Int = 7) async throws {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        for file in files {
            let values = try? file.resourceValues(forKeys: [.contentModificationDateKey])
            if let modified = values?.contentModificationDate, modified < cutoff {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private func logFile(for date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return directory.appendingPathComponent("operations-\(formatter.string(from: date)).jsonl")
    }
}
