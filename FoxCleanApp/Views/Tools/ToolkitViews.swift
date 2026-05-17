import AppKit
import SwiftUI
import FoxCleanCore

struct AnalyzerView: View {
    @State private var rootPath = FileManager.default.homeDirectoryForCurrentUser.path
    @State private var rootNode: DiskNode?
    @State private var focusedNode: DiskNode?
    @State private var displayMode: AnalyzerDisplayMode = .tree
    @State private var isScanning = false
    @State private var errorMessage: String?
    @State private var pendingTrashNode: DiskNode?
    @State private var resultMessage: String?

    var body: some View {
        ToolPage(title: "Disk Analyzer", subtitle: "Inspect the largest files and folders in a path.") {
            HStack {
                TextField("Path", text: $rootPath)
                    .textFieldStyle(.roundedBorder)
                Button {
                    scan()
                } label: {
                    Label("Scan", systemImage: "magnifyingglass")
                }
                Picker("Mode", selection: $displayMode) {
                    ForEach(AnalyzerDisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            if isScanning {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(Tint.red)
            }

            if let resultMessage {
                Label(resultMessage, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Tint.green)
            }

            if let focusedNode {
                analyzerHeader(focusedNode)

                switch displayMode {
                case .tree:
                    Table(focusedNode.children) {
                        TableColumn("Name") { node in
                            Label(node.url.lastPathComponent.isEmpty ? node.url.path : node.url.lastPathComponent,
                                  systemImage: node.children.isEmpty ? "doc.fill" : "folder.fill")
                                .contextMenu { contextMenu(for: node) }
                        }
                        TableColumn("Size") { node in
                            Text(ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file))
                                .monospacedDigit()
                        }
                        TableColumn("Path") { node in
                            Text(node.url.path)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(minHeight: 420)
                case .treemap:
                    TreemapCanvas(nodes: focusedNode.children) { node in
                        if !node.children.isEmpty {
                            self.focusedNode = node
                        }
                    }
                    .frame(minHeight: 420)
                    .contextMenu {
                        Button("Reveal Current Folder in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([focusedNode.url])
                        }
                    }
                }
            } else if !isScanning {
                EmptyStateView("No Scan", systemImage: "internaldrive", description: "Scan a folder to inspect disk usage.", action: { scan() }, actionLabel: "Scan Home")
            }
        }
        .confirmationDialog(
            "Move to Trash?",
            isPresented: Binding(
                get: { pendingTrashNode != nil },
                set: { if !$0 { pendingTrashNode = nil } }
            ),
            presenting: pendingTrashNode
        ) { node in
            Button("Move to Trash", role: .destructive) {
                trash(node)
            }
        } message: { node in
            Text("FoxClean will move \(node.url.lastPathComponent) to Trash and write an OperationLog entry.")
        }
        .onAppear { if rootNode == nil { scan() } }
    }

    @ViewBuilder
    private func analyzerHeader(_ node: DiskNode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file), systemImage: "chart.pie.fill")
                    .font(.headline)
                Spacer()
                Text("\(node.children.count) items")
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Button {
                        focusedNode = rootNode
                    } label: {
                        Label("Root", systemImage: "house.fill")
                    }
                    .buttonStyle(.bordered)

                    if let path = pathToFocusedNode() {
                        ForEach(path) { item in
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button(item.url.lastPathComponent.isEmpty ? item.url.path : item.url.lastPathComponent) {
                                focusedNode = item
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
    }

    private func scan(preserveMessage: Bool = false) {
        isScanning = true
        errorMessage = nil
        if !preserveMessage {
            resultMessage = nil
        }
        rootNode = nil
        focusedNode = nil
        let root = URL(fileURLWithPath: NSString(string: rootPath).expandingTildeInPath)
        Task.detached(priority: .userInitiated) {
            do {
                let scanner = DiskScanner()
                let scanned = try await scanner.scan(path: root, maxDepth: 5)
                await MainActor.run {
                    rootNode = scanned
                    focusedNode = scanned
                    isScanning = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isScanning = false
                }
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for node: DiskNode) -> some View {
        if !node.children.isEmpty {
            Button("Zoom Into Folder") {
                focusedNode = node
            }
        }
        Button("Reveal in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([node.url])
        }
        Divider()
        Button("Move to Trash", role: .destructive) {
            pendingTrashNode = node
        }
        .disabled(!isAnalyzerTrashSafe(node.url))
    }

    private func trash(_ node: DiskNode) {
        pendingTrashNode = nil
        guard isAnalyzerTrashSafe(node.url) else {
            errorMessage = "FoxClean refused to trash a protected system path."
            return
        }
        Task.detached(priority: .userInitiated) {
            var resultingURL: NSURL?
            do {
                try FileManager.default.trashItem(at: node.url, resultingItemURL: &resultingURL)
                try await OperationLog().append(OperationEntry(
                    sessionID: UUID(),
                    action: .trash,
                    originalPath: node.url.path,
                    trashPath: resultingURL?.path,
                    size: node.size,
                    category: .largeFiles,
                    success: true,
                    message: "Moved to Trash from Disk Analyzer"
                ))
                await MainActor.run {
                    resultMessage = "Moved \(node.url.lastPathComponent) to Trash."
                    scan(preserveMessage: true)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func isAnalyzerTrashSafe(_ url: URL) -> Bool {
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL.path
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        let protectedExact = ["/", home, "/Applications", "/Library", "/System", "/Users", "/bin", "/sbin", "/usr", "/private", "/var"]
        let protectedPrefixes = ["/System/", "/Library/", "/Applications/", "/bin/", "/sbin/", "/usr/", "/private/", "/var/"]
        if protectedExact.contains(resolved) { return false }
        if protectedPrefixes.contains(where: { resolved.hasPrefix($0) }) { return false }
        return resolved.hasPrefix(home + "/")
    }

    private func pathToFocusedNode() -> [DiskNode]? {
        guard let rootNode, let focusedNode else { return nil }
        return path(from: rootNode, to: focusedNode)?.dropFirst().map { $0 }
    }

    private func path(from root: DiskNode, to target: DiskNode) -> [DiskNode]? {
        if root.id == target.id { return [root] }
        for child in root.children {
            if let found = path(from: child, to: target) {
                return [root] + found
            }
        }
        return nil
    }
}

private enum AnalyzerDisplayMode: String, CaseIterable, Identifiable {
    case tree = "Tree"
    case treemap = "Treemap"

    var id: String { rawValue }
}

private struct TreemapCanvas: View {
    let nodes: [DiskNode]
    let onZoom: (DiskNode) -> Void

    var body: some View {
        GeometryReader { proxy in
            let rects = TreemapLayout.layout(nodes: nodes, width: proxy.size.width, height: proxy.size.height)
            let nodeByID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

            Canvas { context, _ in
                for rect in rects {
                    let cgRect = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height).insetBy(dx: 1, dy: 1)
                    guard cgRect.width > 1, cgRect.height > 1 else { continue }
                    let color = color(for: rect.id)
                    context.fill(Path(cgRect), with: .color(color.opacity(0.78)))
                    context.stroke(Path(cgRect), with: .color(.white.opacity(0.18)), lineWidth: 1)

                    if cgRect.width > 70, cgRect.height > 32, let node = nodeByID[rect.id] {
                        let label = node.url.lastPathComponent.isEmpty ? node.url.path : node.url.lastPathComponent
                        context.draw(
                            Text(label)
                                .font(.caption2.bold())
                                .foregroundColor(.white),
                            at: CGPoint(x: cgRect.midX, y: cgRect.midY)
                        )
                    }
                }
            }
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        if let rect = rects.first(where: { rect in
                            CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height).contains(value.location)
                        }), let node = nodeByID[rect.id] {
                            onZoom(node)
                        }
                    }
            )
        }
        .accessibilityLabel("Disk usage treemap")
    }

    private func color(for id: String) -> Color {
        let hash = abs(id.hashValue)
        let hue = Double(hash % 360) / 360
        return Color(hue: hue, saturation: 0.58, brightness: 0.72)
    }
}

struct MonitorView: View {
    @State private var snapshot: SystemSnapshot?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ToolPage(title: "System Monitor", subtitle: "Live local health snapshot without telemetry.") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                metric("Uptime", value: uptime, icon: "clock.fill", tint: Tint.blue)
                metric("Memory", value: memory, icon: "memorychip.fill", tint: Tint.purple)
                metric("Disk Free", value: diskFree, icon: "internaldrive.fill", tint: Tint.green)
                metric("Disk I/O", value: diskIO, icon: "externaldrive.connected.to.line.below.fill", tint: Tint.blue)
                metric("CPU", value: cpu, icon: "cpu.fill", tint: Tint.orange)
                metric("Network", value: network, icon: "arrow.up.arrow.down", tint: Tint.cyan)
                metric("Processes", value: processCount, icon: "list.bullet.rectangle", tint: Tint.pink)
                metric("Battery", value: battery, icon: "battery.100percent", tint: Tint.yellow)
                metric("Thermal", value: thermalState, icon: "thermometer.medium", tint: Tint.orange)
                metric("Health", value: healthScore, icon: "heart.fill", tint: Tint.red)
            }

            if let snapshot, !snapshot.topProcesses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Top Processes")
                        .font(.headline)
                    Table(snapshot.topProcesses) {
                        TableColumn("Process") { process in
                            Text(process.name)
                        }
                        TableColumn("PID") { process in
                            Text("\(process.pid)")
                                .monospacedDigit()
                        }
                        TableColumn("CPU Time") { process in
                            Text(String(format: "%.1fs", process.cpuTimeSeconds))
                                .monospacedDigit()
                        }
                        TableColumn("Memory") { process in
                            Text(ByteCountFormatter.string(fromByteCount: Int64(process.residentMemoryBytes), countStyle: .memory))
                                .monospacedDigit()
                        }
                    }
                    .frame(minHeight: 180)
                }
            }
        }
        .onAppear { refresh() }
        .onReceive(timer) { _ in refresh() }
    }

    private var uptime: String {
        let hours = Int(ProcessInfo.processInfo.systemUptime / 3600)
        return "\(hours)h"
    }

    private var memory: String {
        guard let snapshot else { return "--" }
        let used = ByteCountFormatter.string(fromByteCount: Int64(snapshot.memoryUsedBytes), countStyle: .memory)
        let total = ByteCountFormatter.string(fromByteCount: Int64(snapshot.memoryTotalBytes), countStyle: .memory)
        return "\(used) / \(total)"
    }

    private var diskFree: String {
        guard let snapshot else { return "--" }
        return ByteCountFormatter.string(fromByteCount: snapshot.diskFreeBytes, countStyle: .file)
    }

    private var diskIO: String {
        guard let snapshot else { return "--" }
        let read = ByteCountFormatter.string(fromByteCount: Int64(snapshot.diskReadBytesPerSecond), countStyle: .file)
        let written = ByteCountFormatter.string(fromByteCount: Int64(snapshot.diskWrittenBytesPerSecond), countStyle: .file)
        return "\(read)/s read, \(written)/s write"
    }

    private var cpu: String {
        guard let snapshot else { return "--%" }
        return "\(Int((snapshot.cpuLoad * 100).rounded()))%"
    }

    private var network: String {
        guard let snapshot else { return "--" }
        let received = ByteCountFormatter.string(fromByteCount: Int64(snapshot.networkReceivedBytesPerSecond), countStyle: .file)
        let sent = ByteCountFormatter.string(fromByteCount: Int64(snapshot.networkSentBytesPerSecond), countStyle: .file)
        return "\(received)/s down, \(sent)/s up"
    }

    private var processCount: String {
        guard let snapshot else { return "--" }
        return "\(snapshot.processCount)"
    }

    private var battery: String {
        guard let value = snapshot?.batteryPercent else { return "N/A" }
        return "\(Int((value * 100).rounded()))%"
    }

    private var thermalState: String {
        guard let snapshot else { return "--" }
        return snapshot.thermalState.capitalized
    }

    private var healthScore: String {
        guard let snapshot else { return "--" }
        return "\(snapshot.healthScore)"
    }

    private func metric(_ title: String, value: String, icon: String, tint: Color) -> some View {
        CardSurface(padding: 16) {
            HStack(spacing: 12) {
                IconTile(systemName: icon, tint: tint, size: 34)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.system(size: 20, weight: .bold))
                        .monospacedDigit()
                }
                Spacer()
            }
        }
    }

    private func refresh() {
        Task {
            snapshot = await monitorService.snapshot()
        }
    }
}

private let monitorService = SystemMonitor()

struct InstallerCleanupView: View {
    @State private var entries: [ToolFileEntry] = []
    @State private var selectedIDs: Set<String> = []
    @State private var selectedSource = "All"
    @State private var sortMode: InstallerSort = .size
    @State private var showConfirmation = false
    @State private var resultMessage: String?

    var body: some View {
        ToolPage(title: "Installer Cleanup", subtitle: "Find downloaded installers from common locations.") {
            HStack {
                Button {
                    scan()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                Picker("Sort", selection: $sortMode) {
                    ForEach(InstallerSort.allCases) { sort in
                        Text(sort.rawValue).tag(sort)
                    }
                }
                .pickerStyle(.segmented)
                Spacer()
                Button("Remove Selected") {
                    showConfirmation = true
                }
                .disabled(selectedEntries.isEmpty)
            }

            HStack {
                ForEach(sourceFilters, id: \.self) { source in
                    Button(source) {
                        selectedSource = source
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(selectedSource == source ? .accentColor : .secondary)
                }
            }

            Table(displayedEntries, selection: $selectedIDs) {
                TableColumn("Installer") { entry in Label(entry.name, systemImage: "shippingbox.fill") }
                TableColumn("Source") { entry in Text(entry.source ?? "Other") }
                TableColumn("Age") { entry in Text(entry.ageDescription) }
                TableColumn("Size") { entry in Text(ByteCountFormatter.string(fromByteCount: entry.size, countStyle: .file)) }
                TableColumn("Path") { entry in Text(entry.url.path).foregroundStyle(.secondary) }
            }
            .frame(minHeight: 420)

            if let resultMessage {
                Label(resultMessage, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Tint.green)
            }
        }
        .onAppear { scan() }
        .confirmationDialog(
            "Remove selected installers?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                removeSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("FoxClean will move selected installer files to Trash and write an OperationLog entry.")
        }
    }

    private func scan() {
        let files = InstallerScanner().scan()
        entries = files.map { file in
            ToolFileEntry(
                url: file.url,
                size: file.size,
                isDirectory: false,
                source: file.source,
                modifiedAt: file.lastModified,
                suggested: file.suggested
            )
        }
        selectedIDs = Set(entries.filter(\.suggested).map(\.id))
    }

    private var sourceFilters: [String] {
        ["All"] + Array(Set(entries.map { $0.source ?? "Other" })).sorted()
    }

    private var displayedEntries: [ToolFileEntry] {
        let filtered = selectedSource == "All"
            ? entries
            : entries.filter { ($0.source ?? "Other") == selectedSource }
        switch sortMode {
        case .size:
            return filtered.sorted { $0.size > $1.size }
        case .age:
            return filtered.sorted { ($0.modifiedAt ?? .distantFuture) < ($1.modifiedAt ?? .distantFuture) }
        }
    }

    private var selectedEntries: [ToolFileEntry] {
        entries.filter { selectedIDs.contains($0.id) }
    }

    private func removeSelected() {
        let files = selectedEntries.map {
            ScannedFile(
                url: $0.url,
                size: $0.size,
                category: .installers,
                lastModified: $0.modifiedAt,
                suggested: $0.suggested,
                source: $0.source
            )
        }
        Task {
            let result = await FileOperator().clean(files, mode: .trash)
            await MainActor.run {
                resultMessage = "Moved \(result.affectedCount) installer item(s) to Trash."
                scan()
            }
        }
    }
}

struct ProjectPurgeView: View {
    @State private var entries: [ToolFileEntry] = []
    @State private var selectedIDs: Set<String> = []
    @State private var showConfirmation = false
    @State private var resultMessage: String?

    var body: some View {
        ToolPage(title: "Project Purge", subtitle: "Detect build artifacts only inside folders with project markers.") {
            HStack {
                Button {
                    scan()
                } label: {
                    Label("Scan Projects", systemImage: "folder.badge.gearshape")
                }
                Spacer()
                Button("Remove Selected") {
                    showConfirmation = true
                }
                .disabled(selectedEntries.isEmpty)
            }

            List(selection: $selectedIDs) {
                ForEach(projectGroups, id: \.project) { group in
                    Section(group.project) {
                        ForEach(group.entries) { entry in
                            HStack(spacing: 12) {
                                Label(entry.name, systemImage: "folder.fill")
                                    .frame(minWidth: 180, alignment: .leading)
                                if entry.isRecent {
                                    Text("Recent")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Tint.orange.opacity(0.18), in: Capsule())
                                }
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: entry.size, countStyle: .file))
                                    .monospacedDigit()
                                Text(entry.url.path)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: 320, alignment: .trailing)
                            }
                            .tag(entry.id)
                        }
                    }
                }
            }
            .frame(minHeight: 420)

            if let resultMessage {
                Label(resultMessage, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Tint.green)
            }
        }
        .onAppear { scan() }
        .confirmationDialog(
            "Remove selected project artifacts?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                removeSelected()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("FoxClean will move selected build artifacts to Trash and write an OperationLog entry. Recent artifacts are left unchecked by default.")
        }
    }

    private func scan() {
        let roots = ProjectScanner.configuredRoots()
        entries = ProjectScanner().scan(roots: roots).map { artifact in
            ToolFileEntry(
                url: artifact.url,
                size: artifact.size,
                isDirectory: true,
                projectName: artifact.projectRoot.lastPathComponent,
                modifiedAt: nil,
                isRecent: artifact.isRecent,
                suggested: !artifact.isRecent
            )
        }
        selectedIDs = Set(entries.filter(\.suggested).map(\.id))
    }

    private var projectGroups: [(project: String, entries: [ToolFileEntry])] {
        Dictionary(grouping: entries, by: { $0.projectName ?? "Other" })
            .map { (project: $0.key, entries: $0.value.sorted { $0.size > $1.size }) }
            .sorted { $0.project < $1.project }
    }

    private var selectedEntries: [ToolFileEntry] {
        entries.filter { selectedIDs.contains($0.id) }
    }

    private func removeSelected() {
        let files = selectedEntries.map {
            ScannedFile(url: $0.url, size: $0.size, category: .developerCache, lastModified: $0.modifiedAt, suggested: $0.suggested, source: "Project Purge")
        }
        Task {
            let result = await FileOperator().clean(files, mode: .trash)
            await MainActor.run {
                resultMessage = "Moved \(result.affectedCount) project artifact(s) to Trash."
                scan()
            }
        }
    }
}

struct OptimizeView: View {
    private let optimizer = Optimizer()
    @State private var selected: Set<String> = Set(Optimizer().tasks.map(\.id))
    @State private var useWhitelist = false
    @State private var isRunning = false
    @State private var reports: [OptimizationReport] = []

    var body: some View {
        ToolPage(title: "Optimize", subtitle: "Run safe maintenance tasks. Admin tasks stay opt-in.") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Use optimize_whitelist", isOn: $useWhitelist)
                    .help(Optimizer.defaultWhitelistURL.path)

                ForEach(optimizer.tasks) { task in
                    Toggle(isOn: Binding(
                        get: { selected.contains(task.id) },
                        set: { isOn in
                            if isOn { selected.insert(task.id) } else { selected.remove(task.id) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(task.name)
                                if task.requiresAdmin {
                                    Text("Admin")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Tint.orange.opacity(0.18), in: Capsule())
                                }
                            }
                            Text(task.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack {
                    Button {
                        run(selectedTasks: selected, dryRun: true)
                    } label: {
                        Label("Preview", systemImage: "eye")
                    }
                    Button {
                        run(selectedTasks: selected, dryRun: false)
                    } label: {
                        Label("Run Selected", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        let allTasks = Set(optimizer.tasks.map(\.id))
                        selected = allTasks
                        run(selectedTasks: allTasks, dryRun: false)
                    } label: {
                        Label("Run All", systemImage: "forward.end.fill")
                    }
                }
                .disabled(isRunning)

                if isRunning {
                    ProgressView("Running optimization tasks…")
                }

                Link("Edit whitelist", destination: Optimizer.defaultWhitelistURL.deletingLastPathComponent())

                ForEach(reports, id: \.id) { report in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(report.task)
                            Text(report.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: reportIcon(report))
                            .foregroundStyle(reportColor(report))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Optimization result")
                    .accessibilityValue("\(report.task): \(report.message)")
                }
            }
        }
    }

    private func run(selectedTasks: Set<String>, dryRun: Bool) {
        isRunning = true
        reports = []
        let whitelist = useWhitelist ? Optimizer.loadWhitelist() : nil
        Task.detached {
            let output = optimizer.run(
                selectedTasks: selectedTasks,
                dryRun: dryRun,
                whitelist: whitelist,
                includeSkipped: true,
                allowAdminPrompt: true
            )
            await MainActor.run {
                reports = output
                isRunning = false
            }
        }
    }

    private func reportIcon(_ report: OptimizationReport) -> String {
        if report.skipped { return "forward.fill" }
        return report.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    private func reportColor(_ report: OptimizationReport) -> Color {
        if report.skipped { return .secondary }
        return report.success ? Tint.green : Tint.orange
    }
}

private struct ToolPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            content
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct ToolFileEntry: Identifiable {
    var id: String { url.path }
    let url: URL
    let size: Int64
    let isDirectory: Bool
    var source: String?
    var projectName: String?
    var modifiedAt: Date?
    var isRecent: Bool = false
    var suggested: Bool = true
    var name: String { url.lastPathComponent }

    var ageDescription: String {
        guard let modifiedAt else { return "--" }
        let days = Calendar.current.dateComponents([.day], from: modifiedAt, to: Date()).day ?? 0
        if days <= 0 { return "Today" }
        return "\(days)d"
    }
}

private enum InstallerSort: String, CaseIterable, Identifiable {
    case size = "Size"
    case age = "Age"

    var id: String { rawValue }
}
