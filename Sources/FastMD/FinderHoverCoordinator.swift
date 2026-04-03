import AppKit
import Foundation

@MainActor
final class FinderHoverCoordinator {
    private let hoverMonitor = HoverMonitorService()
    private let resolver = FinderItemResolver()
    private let previewPanel = PreviewPanelController()
    private var currentItem: HoveredMarkdownItem?

    private(set) var isRunning = false

    init() {
        hoverMonitor.onMouseActivity = { [weak self] in
            self?.previewPanel.hide()
        }
        hoverMonitor.onHoverPause = { [weak self] point in
            self?.handleHoverPause(at: point)
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontAppChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func start() {
        guard !isRunning else { return }
        guard AccessibilityPermissionManager.ensureTrusted(prompt: true) else {
            return
        }
        isRunning = true
        hoverMonitor.start()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        currentItem = nil
        hoverMonitor.stop()
        previewPanel.hide()
    }

    @objc
    private func frontAppChanged() {
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier != "com.apple.finder" {
            currentItem = nil
            previewPanel.hide()
        }
    }

    private func handleHoverPause(at point: NSPoint) {
        guard isRunning else { return }
        guard let item = resolver.resolveMarkdown(at: point) else {
            currentItem = nil
            previewPanel.hide()
            return
        }

        if currentItem == item {
            return
        }

        currentItem = item
        previewPanel.showMarkdown(fileURL: item.fileURL, near: point)
    }
}
