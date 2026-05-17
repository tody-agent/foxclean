import SwiftUI

struct AppListView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selection: InstalledApp.ID?
    @State private var hideSystemApps = true
    @State private var hideProtectedApps = true
    @State private var sensitivity = 1.0
    @State private var sortOrder: [KeyPathComparator<InstalledApp>] = [
        .init(\.appName, order: .forward)
    ]

    private var filteredApps: [InstalledApp] {
        let base: [InstalledApp]
        if searchText.isEmpty {
            base = appState.installedApps
        } else {
            let query = searchText.lowercased()
            base = appState.installedApps.filter {
                $0.appName.lowercased().contains(query) ||
                $0.bundleIdentifier.lowercased().contains(query) ||
                $0.path.path.lowercased().contains(query)
            }
        }
        return base
            .filter { !hideSystemApps || !$0.isSystemApp }
            .filter { !hideProtectedApps || !$0.isProtected }
            .sorted(using: sortOrder)
    }

    var body: some View {
        HSplitView {
            // Cap the left pane's maxWidth so dragging the splitter cannot
            // push it past half the window and break the layout (#60).
            appTable
                .frame(minWidth: 300, idealWidth: 380, maxWidth: 600)

            fileDetail
                .frame(minWidth: 300)
        }
        .searchable(text: $searchText, prompt: "Search apps")
        .navigationTitle("Installed Apps (\(appState.installedApps.count))")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    appState.loadInstalledApps()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                Toggle("Hide system apps", isOn: $hideSystemApps)
                Toggle("Hide protected apps", isOn: $hideProtectedApps)

                if !appState.selectedFiles.isEmpty {
                    Button("Uninstall (\(appState.selectedFiles.count) files)", role: .destructive) {
                        appState.removeSelectedFiles()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
    }

    // MARK: - App Table (left side)

    private var appTable: some View {
        Group {
            if appState.isLoadingApps {
                VStack(spacing: 12) {
                    ProgressView("Loading installed apps...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.installedApps.isEmpty {
                EmptyStateView(
                    "No Apps Found",
                    systemImage: "square.grid.2x2",
                    description: "Could not find any installed applications.",
                    action: { appState.loadInstalledApps() },
                    actionLabel: "Retry"
                )
            } else {
                Table(filteredApps, selection: $selection, sortOrder: $sortOrder) {
                    TableColumn("Application", value: \.appName) { app in
                        HStack(spacing: 8) {
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text(app.appName)
                        }
                    }
                    .width(min: 150)

                    TableColumn("Size", value: \.size) { app in
                        Text(app.formattedSize)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .width(ideal: 70)
                }
                .onChange(of: selection) { newValue in
                    if let id = newValue,
                       let app = appState.installedApps.first(where: { $0.id == id }) {
                        appState.selectedApp = app
                        appState.scanForAppFiles(app, sensitivity: appSensitivity)
                    }
                }
            }
        }
    }

    // MARK: - File Detail (right side)

    @ViewBuilder
    private var fileDetail: some View {
        if let app = appState.selectedApp {
            VStack(spacing: 0) {
                sensitivityControl
                Divider()
                AppFilesView(app: app)
            }
        } else {
            EmptyStateView(
                "Select an App",
                systemImage: "cursorarrow.click.2",
                description: "Select an app from the list to see all its related files across your system."
            )
        }
    }

    private var sensitivityControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Sensitivity")
                    .font(.caption.bold())
                Spacer()
                Text(sensitivityLabel)
                    .font(.caption)
                    .foregroundStyle(sensitivityColor)
            }
            Slider(value: $sensitivity, in: 0...2, step: 1) {
                Text("Sensitivity")
            } minimumValueLabel: {
                Text("Strict").font(.caption2)
            } maximumValueLabel: {
                Text("Deep").font(.caption2)
            }
            .tint(sensitivityColor)
            .onChange(of: sensitivity) { _ in
                if let app = appState.selectedApp {
                    appState.scanForAppFiles(app, sensitivity: appSensitivity)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var appSensitivity: AppPathFinder.Sensitivity {
        switch Int(sensitivity.rounded()) {
        case 0: return .strict
        case 2: return .deep
        default: return .enhanced
        }
    }

    private var sensitivityLabel: String {
        switch appSensitivity {
        case .strict: return "Strict"
        case .enhanced: return "Enhanced"
        case .deep: return "Deep"
        }
    }

    private var sensitivityColor: Color {
        switch appSensitivity {
        case .strict: return Tint.green
        case .enhanced: return Tint.orange
        case .deep: return Tint.red
        }
    }
}
