import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let coordinator = FinderHoverCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        coordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stop()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "FastMD"

        let menu = NSMenu()
        let toggleTitle = coordinator.isRunning ? "Pause Monitoring" : "Resume Monitoring"
        menu.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleMonitoring), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Request Accessibility Permission", action: #selector(requestPermission), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        item.menu = menu
        self.statusItem = item
    }

    @objc
    private func toggleMonitoring() {
        if coordinator.isRunning {
            coordinator.stop()
        } else {
            coordinator.start()
        }
        configureStatusItem()
    }

    @objc
    private func requestPermission() {
        _ = AccessibilityPermissionManager.ensureTrusted(prompt: true)
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }
}
