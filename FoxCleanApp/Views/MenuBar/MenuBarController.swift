import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    private let defaultsKey = "settings.general.showMenuBar"
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var defaultsObserver: NSObjectProtocol?

    override init() {
        super.init()
        registerDefaultSetting()
        applyVisibility()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.applyVisibility()
            }
        }
    }

    deinit {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    private func registerDefaultSetting() {
        UserDefaults.standard.register(defaults: [defaultsKey: true])
    }

    private func applyVisibility() {
        if UserDefaults.standard.bool(forKey: defaultsKey) {
            installStatusItemIfNeeded()
        } else {
            removeStatusItem()
        }
    }

    private func installStatusItemIfNeeded() {
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.behavior = [.removalAllowed, .terminationOnRemoval]
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "FoxClean")
            button.imagePosition = .imageLeading
            button.title = " --%"
            button.toolTip = "FoxClean quick actions"
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        statusItem = item
        updateStatusTitle(cpuLoad: nil)
    }

    private func removeStatusItem() {
        closePopover()
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover?.isShown == true {
            closePopover()
        } else {
            showPopover(relativeTo: sender)
        }
    }

    private func showPopover(relativeTo button: NSStatusBarButton) {
        let model = MenuBarMiniModel { [weak self] action in
            self?.handle(action)
        } onSnapshot: { [weak self] snapshot in
            self?.updateStatusTitle(cpuLoad: snapshot.cpuLoad)
        }
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 280, height: 260)
        popover.contentViewController = NSHostingController(rootView: MenuBarMiniView(model: model))
        self.popover = popover
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        popover?.performClose(nil)
        popover = nil
    }

    private func updateStatusTitle(cpuLoad: Double?) {
        guard let button = statusItem?.button else { return }
        if let cpuLoad {
            button.title = " \(Int((cpuLoad * 100).rounded()))%"
        } else {
            button.title = " --%"
        }
    }

    private func handle(_ action: MenuBarQuickAction) {
        closePopover()
        switch action {
        case .smartScan:
            NotificationCenter.default.post(name: .foxCleanSmartScan, object: nil)
            openMainWindow(route: .cleaning(.smartScan))
        case .openApp:
            openMainWindow(route: .cleaning(.smartScan))
        case .openMonitor:
            openMainWindow(route: .monitor)
        case .quit:
            NSApp.terminate(nil)
        }
    }

    private func openMainWindow(route: AppSection) {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where !window.isMiniaturized {
            window.makeKeyAndOrderFront(nil)
        }
        NotificationCenter.default.post(name: .foxCleanRoute, object: route)
    }
}
