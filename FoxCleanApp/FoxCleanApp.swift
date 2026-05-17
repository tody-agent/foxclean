import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        // Touch TCC-protected paths so macOS registers FoxClean in the
        // Full Disk Access pane on first launch (fixes issue #75).
        FullDiskAccessManager.shared.triggerRegistration()
        menuBarController = MenuBarController()
    }
}

@main
struct FoxCleanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var theme = ThemeManager.shared
    @AppStorage("FoxClean.OnboardingComplete") private var onboardingComplete = false

    private var shouldSkipOnboarding: Bool {
        ProcessInfo.processInfo.environment["FOX_SKIP_ONBOARDING"] == "1"
    }

    init() {
        // Enter CLI mode only when the first arg is a known command. Xcode and
        // LaunchServices inject args like -NSDocumentRevisionsDebugMode and
        // -psn_<pid> that must not be interpreted as CLI commands.
        if let first = CommandLine.arguments.dropFirst().first,
           CLI.isKnownCommand(first) {
            CLI.run()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingComplete || shouldSkipOnboarding {
                    MainWindow()
                        .environmentObject(appState)
                        .frame(minWidth: 900, minHeight: 600)
                } else {
                    OnboardingView(isComplete: $onboardingComplete)
                }
            }
            .environmentObject(theme)
            .preferredColorScheme(theme.appearance.colorScheme)
            .tint(theme.accent.color)
            .onOpenURL { url in
                appState.route(to: url)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1000, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Navigate") {
                Button("Dashboard") { appState.route(to: "dashboard") }
                    .keyboardShortcut("1", modifiers: [.command])
                Button("Installed Apps") { appState.route(to: "apps") }
                    .keyboardShortcut("2", modifiers: [.command])
                Button("Orphaned Files") { appState.route(to: "orphans") }
                    .keyboardShortcut("3", modifiers: [.command])
                Divider()
                Button("Disk Analyzer") { appState.route(to: "analyzer") }
                    .keyboardShortcut("4", modifiers: [.command])
                Button("System Monitor") { appState.route(to: "monitor") }
                    .keyboardShortcut("5", modifiers: [.command])
                Button("Installers") { appState.route(to: "installers") }
                    .keyboardShortcut("6", modifiers: [.command])
                Button("Project Purge") { appState.route(to: "projects") }
                    .keyboardShortcut("7", modifiers: [.command])
                Button("Optimize") { appState.route(to: "optimize") }
                    .keyboardShortcut("8", modifiers: [.command])
            }
            CommandMenu("Actions") {
                Button("Smart Scan") { appState.startSmartScan() }
                    .keyboardShortcut("r", modifiers: [.command])
                Button("Open Full Disk Access Settings") {
                    appState.openFullDiskAccessSettings()
                }
                .keyboardShortcut(",", modifiers: [.command, .shift])
            }
            CommandMenu("Help") {
                Button("Keyboard Shortcuts") {
                    KeyboardShortcutsWindowController.shared.show()
                }
                .keyboardShortcut("/", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
