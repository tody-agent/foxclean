import Foundation

public struct DiskNode: Codable, Hashable, Identifiable, Sendable {
    public var id: String { url.path }
    public let url: URL
    public let size: Int64
    public let children: [DiskNode]

    public init(url: URL, size: Int64, children: [DiskNode] = []) {
        self.url = url
        self.size = size
        self.children = children
    }
}

public actor DiskScanner {
    private static let cache = DiskScanCache()
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func scan(path: URL, maxDepth: Int = 4) async throws -> DiskNode {
        let normalized = path.resolvingSymlinksInPath().standardizedFileURL
        if let cached = await Self.cache.cachedNode(for: normalized, maxDepth: maxDepth) {
            return cached
        }
        let node = try await scan(normalized, depth: 0, maxDepth: maxDepth)
        await Self.cache.store(node, for: normalized, maxDepth: maxDepth)
        return node
    }

    private func scan(_ url: URL, depth: Int, maxDepth: Int) async throws -> DiskNode {
        if Task.isCancelled { throw FoxCleanError.operationCancelled }
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey])
        guard values?.isDirectory == true, depth < maxDepth else {
            let size = Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
            return DiskNode(url: url, size: size)
        }

        let childrenURLs = (try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey], options: [.skipsHiddenFiles])) ?? []
        var children: [DiskNode] = []
        var total: Int64 = 0
        for child in childrenURLs.prefix(2_000) {
            let node = try await scan(child, depth: depth + 1, maxDepth: maxDepth)
            total += node.size
            if node.size > 0 { children.append(node) }
        }
        return DiskNode(url: url, size: total, children: children.sorted { $0.size > $1.size })
    }
}

public struct TreemapRect: Codable, Hashable, Sendable {
    public let id: String
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let size: Int64
}

public enum TreemapLayout {
    public static func layout(nodes: [DiskNode], width: Double, height: Double) -> [TreemapRect] {
        guard width > 0, height > 0 else { return [] }
        let totalSize = nodes.reduce(Int64(0)) { $0 + max(0, $1.size) }
        guard totalSize > 0 else { return [] }

        let totalArea = width * height
        var remaining = nodes
            .filter { $0.size > 0 }
            .sorted { $0.size > $1.size }
            .map { item in
                TreemapItem(node: item, area: totalArea * Double(item.size) / Double(totalSize))
            }
        var bounds = TreemapBounds(x: 0, y: 0, width: width, height: height)
        var row: [TreemapItem] = []
        var rects: [TreemapRect] = []

        while !remaining.isEmpty {
            let next = remaining[0]
            if row.isEmpty {
                row.append(next)
                remaining.removeFirst()
                continue
            }

            let side = max(0.0001, min(bounds.width, bounds.height))
            if worstAspect(row + [next], side: side) <= worstAspect(row, side: side) {
                row.append(next)
                remaining.removeFirst()
            } else {
                append(row: row, in: &bounds, to: &rects)
                row.removeAll(keepingCapacity: true)
            }
        }

        if !row.isEmpty {
            append(row: row, in: &bounds, to: &rects)
        }
        return rects
    }

    private static func worstAspect(_ row: [TreemapItem], side: Double) -> Double {
        let areas = row.map(\.area).filter { $0 > 0 }
        guard let minArea = areas.min(), let maxArea = areas.max() else { return .infinity }
        let sum = areas.reduce(0, +)
        guard sum > 0 else { return .infinity }
        let sideSquared = side * side
        return max((sideSquared * maxArea) / (sum * sum), (sum * sum) / (sideSquared * minArea))
    }

    private static func append(row: [TreemapItem], in bounds: inout TreemapBounds, to rects: inout [TreemapRect]) {
        let area = row.reduce(0) { $0 + $1.area }
        guard area > 0, bounds.width > 0, bounds.height > 0 else { return }

        if bounds.width >= bounds.height {
            let rowHeight = min(bounds.height, area / bounds.width)
            var x = bounds.x
            for item in row {
                let itemWidth = min(bounds.x + bounds.width - x, item.area / max(rowHeight, 0.0001))
                rects.append(TreemapRect(
                    id: item.node.id,
                    x: x,
                    y: bounds.y,
                    width: max(0, itemWidth),
                    height: max(0, rowHeight),
                    size: item.node.size
                ))
                x += itemWidth
            }
            bounds.y += rowHeight
            bounds.height = max(0, bounds.height - rowHeight)
        } else {
            let rowWidth = min(bounds.width, area / bounds.height)
            var y = bounds.y
            for item in row {
                let itemHeight = min(bounds.y + bounds.height - y, item.area / max(rowWidth, 0.0001))
                rects.append(TreemapRect(
                    id: item.node.id,
                    x: bounds.x,
                    y: y,
                    width: max(0, rowWidth),
                    height: max(0, itemHeight),
                    size: item.node.size
                ))
                y += itemHeight
            }
            bounds.x += rowWidth
            bounds.width = max(0, bounds.width - rowWidth)
        }
    }
}

private struct TreemapItem {
    let node: DiskNode
    let area: Double
}

private struct TreemapBounds {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

private actor DiskScanCache {
    private struct Entry: Codable {
        let modifiedAt: Date?
        let node: DiskNode
    }

    private var entries: [String: Entry] = [:]
    private let cacheURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = appSupport.appendingPathComponent("FoxClean", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        cacheURL = directory.appendingPathComponent("disk_scan_cache.json")
        if let data = try? Data(contentsOf: cacheURL),
           let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) {
            entries = decoded
        }
    }

    func cachedNode(for url: URL, maxDepth: Int) -> DiskNode? {
        let key = cacheKey(for: url, maxDepth: maxDepth)
        guard let entry = entries[key],
              entry.modifiedAt == modifiedAt(url)
        else { return nil }
        return entry.node
    }

    func store(_ node: DiskNode, for url: URL, maxDepth: Int) {
        entries[cacheKey(for: url, maxDepth: maxDepth)] = Entry(modifiedAt: modifiedAt(url), node: node)
        persist()
    }

    func clear() {
        entries.removeAll()
        try? FileManager.default.removeItem(at: cacheURL)
    }

    private func cacheKey(for url: URL, maxDepth: Int) -> String {
        "\(url.path)#\(maxDepth)"
    }

    private func modifiedAt(_ url: URL) -> Date? {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
