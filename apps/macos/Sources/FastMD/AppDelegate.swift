import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let coordinator = FinderHoverCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        RuntimeLogger.markSession("Launch \(Date())")
        RuntimeLogger.log("App launched. Bundle path=\(Bundle.main.bundleURL.path)")
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        coordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        RuntimeLogger.log("App terminating.")
        coordinator.stop()
    }

    private func configureStatusItem() {
        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = "FastMD"
            statusItem = item
        }
        guard let item = statusItem else { return }

        let menu = NSMenu()

        let toggleTitle = coordinator.isRunning ? "Pause Monitoring" : "Resume Monitoring"
        menu.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleMonitoring), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        let hoverItem = NSMenuItem(
            title: "Hover Trigger",
            action: #selector(toggleHoverTrigger),
            keyEquivalent: ""
        )
        hoverItem.state = coordinator.isHoverTriggerEnabled ? .on : .off
        menu.addItem(hoverItem)

        let spaceItem = NSMenuItem(
            title: "Space Key Trigger",
            action: #selector(toggleSpaceTrigger),
            keyEquivalent: ""
        )
        spaceItem.state = coordinator.isSpaceTriggerEnabled ? .on : .off
        menu.addItem(spaceItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Request Accessibility Permission", action: #selector(requestPermission), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Runtime Log", action: #selector(openRuntimeLog), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        item.menu = menu
    }

    @objc
    private func toggleHoverTrigger() {
        coordinator.setHoverTriggerEnabled(!coordinator.isHoverTriggerEnabled)
        configureStatusItem()
    }

    @objc
    private func toggleSpaceTrigger() {
        coordinator.setSpaceTriggerEnabled(!coordinator.isSpaceTriggerEnabled)
        configureStatusItem()
    }

    @objc
    private func toggleMonitoring() {
        if coordinator.isRunning {
            RuntimeLogger.log("Menu action: pause monitoring.")
            coordinator.stop()
        } else {
            RuntimeLogger.log("Menu action: resume monitoring.")
            coordinator.start()
        }
        configureStatusItem()
    }

    @objc
    private func requestPermission() {
        let trusted = AccessibilityPermissionManager.ensureTrusted(prompt: true)
        RuntimeLogger.log("Menu action: request Accessibility permission. trusted=\(trusted)")
    }

    @objc
    private func openRuntimeLog() {
        RuntimeLogger.log("Menu action: open runtime log at \(RuntimeLogger.logFileURL.path)")
        if !FileManager.default.fileExists(atPath: RuntimeLogger.logFileURL.path) {
            try? Data().write(to: RuntimeLogger.logFileURL, options: .atomic)
        }
        NSWorkspace.shared.open(RuntimeLogger.logFileURL)
    }

    @objc
    private func quitApp() {
        RuntimeLogger.log("Menu action: quit app.")
        NSApp.terminate(nil)
    }
}
