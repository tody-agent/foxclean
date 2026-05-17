import SwiftUI

struct OrphanListView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedOrphans: Set<URL> = []
    @State private var isRemoving = false
    @State private var removalErrorMessage: String?
    @State private var searchText = ""
    @State private var showRemoveConfirmation = false

    private var filteredOrphans: [URL] {
        guard !searchText.isEmpty else { return appState.orphanedFiles }
        return appState.orphanedFiles.filter {
            $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) ||
            $0.path.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if appState.isSearchingOrphans {
                VStack(spacing: 16) {
                    ProgressView("Scanning for orphaned files...")
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 300)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.orphanedFiles.isEmpty {
                EmptyStateView("No Orphaned Files", systemImage: "checkmark.circle", description: "No leftover files from uninstalled apps were found.", action: { appState.findOrphans() }, actionLabel: "Scan for Orphans")
            } else {
                List(filteredOrphans, id: \.self) { fileURL in
                    Toggle(isOn: orphanBinding(for: fileURL)) {
                        HStack {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: fileURL.path))
                                .resizable()
                                .frame(width: 16, height: 16)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(fileURL.lastPathComponent)
                                    .lineLimit(1)
                                Text(fileURL.path)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            if let size = fileSize(fileURL) {
                                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .toggleStyle(.checkbox)
                    .contextMenu {
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Filter orphan files")
        .navigationTitle("Orphaned Files (\(appState.orphanedFiles.count))")
        .toolbar {
            ToolbarItemGroup {
                if !filteredOrphans.isEmpty {
                    Button(selectedOrphans.count == filteredOrphans.count ? "Deselect All" : "Select All") {
                        if selectedOrphans.count == filteredOrphans.count {
                            selectedOrphans.removeAll()
                        } else {
                            selectedOrphans = Set(filteredOrphans)
                        }
                    }
                    Button("Smart Select") {
                        selectedOrphans = Set(filteredOrphans.filter(isSmartCandidate))
                    }
                }

                Button("Scan for Orphans") {
                    appState.findOrphans()
                }

                if !selectedOrphans.isEmpty {
                    Button("Remove Selected (\(selectedOrphans.count))", role: .destructive) {
                        showRemoveConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isRemoving)
                }
            }
        }
        .alert("Some files could not be removed", isPresented: Binding(
            get: { removalErrorMessage != nil },
            set: { if !$0 { removalErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(removalErrorMessage ?? "")
        }
        .confirmationDialog(
            "Remove selected orphan files?",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                Task {
                    await removeSelectedOrphans()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("FoxClean will remove orphaned files that pass the safety policy.")
        }
    }

    private func orphanBinding(for url: URL) -> Binding<Bool> {
        Binding(
            get: { selectedOrphans.contains(url) },
            set: { selected in
                if selected {
                    selectedOrphans.insert(url)
                } else {
                    selectedOrphans.remove(url)
                }
            }
        )
    }

    private func fileSize(_ url: URL) -> Int64? {
        if let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
           let size = values.totalFileAllocatedSize, size > 0 {
            return Int64(size)
        }
        if let values = try? url.resourceValues(forKeys: [.fileAllocatedSizeKey]),
           let size = values.fileAllocatedSize {
            return Int64(size)
        }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else { return nil }
        return size
    }

    private func isSmartCandidate(_ url: URL) -> Bool {
        guard OrphanSafetyPolicy.isSafeCandidate(url) else { return false }
        let size = fileSize(url) ?? 0
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        let oldCutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let isOld = (values?.contentModificationDate ?? .distantFuture) < oldCutoff
        return size > 100_000_000 || isOld
    }

    private func removeSelectedOrphans() async {
        isRemoving = true
        defer { isRemoving = false }

        let urlsToRemove = selectedOrphans
        var failedPaths: [String] = []
        var removedURLs: Set<URL> = []
        var needsAdminURLs: [URL] = []

        for url in urlsToRemove {
            guard OrphanSafetyPolicy.isSafeCandidate(url) else {
                failedPaths.append("\(url.path) (blocked by safety policy)")
                continue
            }

            switch removeOrphan(url) {
            case .removed:
                removedURLs.insert(url)
            case .needsAdmin:
                needsAdminURLs.append(url)
            case .failed:
                failedPaths.append(url.path)
            }
        }

        if !needsAdminURLs.isEmpty {
            if removeWithAdminPrivileges(needsAdminURLs) {
                for url in needsAdminURLs {
                    if !FileManager.default.fileExists(atPath: url.path) {
                        removedURLs.insert(url)
                    } else {
                        failedPaths.append(url.path)
                    }
                }
            } else {
                failedPaths.append(contentsOf: needsAdminURLs.map(\.path))
            }
        }

        appState.orphanedFiles.removeAll { removedURLs.contains($0) }
        selectedOrphans.subtract(removedURLs)

        if !failedPaths.isEmpty {
            let preview = failedPaths.prefix(3).joined(separator: "\n")
            let suffix = failedPaths.count > 3 ? "\n…" : ""
            removalErrorMessage = "\(failedPaths.count) item(s) failed to delete.\n\n\(preview)\(suffix)"
        }
    }

    private enum OrphanRemoveOutcome {
        case removed
        case needsAdmin
        case failed
    }

    private func removeOrphan(_ url: URL) -> OrphanRemoveOutcome {
        do {
            try FileManager.default.removeItem(at: url)
            return .removed
        } catch {
            let nsError = error as NSError
            let permissionDeniedCodes = [
                NSFileReadNoPermissionError,
                NSFileWriteNoPermissionError,
                NSFileWriteUnknownError,
                257,
                513,
            ]

            guard permissionDeniedCodes.contains(nsError.code) else {
                return .failed
            }

            return .needsAdmin
        }
    }

    private func removeWithAdminPrivileges(_ urls: [URL]) -> Bool {
        guard !urls.isEmpty else { return true }
        guard urls.allSatisfy({ OrphanSafetyPolicy.isSafeCandidate($0) }) else { return false }

        // Quote path for a POSIX shell command.
        let quotedPaths = urls.map { url in
            "'\(url.path.replacingOccurrences(of: "'", with: "'\\\"'\\\"'"))'"
        }
        let shellCommand = "rm -rf -- \(quotedPaths.joined(separator: " "))"
        let appleScriptCommand = shellCommand
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(appleScriptCommand)\" with administrator privileges"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                return false
            }
            return true
        } catch {
            return false
        }
    }
}
