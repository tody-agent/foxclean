import AppKit
import SwiftUI

final class KeyboardShortcutsWindowController {
    static let shared = KeyboardShortcutsWindowController()

    private var window: NSWindow?

    private init() {}

    func show() {
        if window == nil {
            let view = KeyboardShortcutsView()
            let hostingView = NSHostingView(rootView: view)
            let newWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            newWindow.title = "Keyboard Shortcuts"
            newWindow.contentView = hostingView
            newWindow.isReleasedWhenClosed = false
            newWindow.center()
            window = newWindow
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct KeyboardShortcutsView: View {
    private let groups: [ShortcutGroup] = [
        ShortcutGroup(title: "Navigate", shortcuts: [
            ShortcutItem(action: "Dashboard", keys: "Command-1"),
            ShortcutItem(action: "Installed Apps", keys: "Command-2"),
            ShortcutItem(action: "Orphaned Files", keys: "Command-3"),
            ShortcutItem(action: "Disk Analyzer", keys: "Command-4"),
            ShortcutItem(action: "System Monitor", keys: "Command-5"),
            ShortcutItem(action: "Installers", keys: "Command-6"),
            ShortcutItem(action: "Project Purge", keys: "Command-7"),
            ShortcutItem(action: "Optimize", keys: "Command-8"),
        ]),
        ShortcutGroup(title: "Actions", shortcuts: [
            ShortcutItem(action: "Smart Scan", keys: "Command-R"),
            ShortcutItem(action: "Full Disk Access Settings", keys: "Command-Shift-Comma"),
            ShortcutItem(action: "Keyboard Shortcuts", keys: "Command-?"),
        ]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Keyboard Shortcuts")
                .font(.title.bold())

            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.title)
                        .font(.headline)
                    VStack(spacing: 0) {
                        ForEach(group.shortcuts) { shortcut in
                            HStack {
                                Text(shortcut.action)
                                Spacer()
                                Text(shortcut.keys)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 7)
                            Divider()
                        }
                    }
                    .accessibilityElement(children: .contain)
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 520, height: 460)
        .accessibilityLabel("Keyboard shortcuts")
    }
}

private struct ShortcutGroup: Identifiable {
    let title: String
    let shortcuts: [ShortcutItem]

    var id: String { title }
}

private struct ShortcutItem: Identifiable {
    let action: String
    let keys: String

    var id: String { "\(action)-\(keys)" }
}
