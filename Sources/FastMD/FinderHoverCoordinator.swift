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
        hoverMonitor.onHoverPause = { [weak self] point in
            self?.handleHoverPause(at: point)
        }
        previewPanel.onOutsideClick = { [weak self] in
            self?.hideCurrentPreview(reason: "Clicked outside preview.")
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
        let trusted = AccessibilityPermissionManager.ensureTrusted(prompt: true)
        RuntimeLogger.log("Coordinator start requested. accessibilityTrusted=\(trusted)")
        guard trusted else {
            RuntimeLogger.log("Coordinator start aborted because Accessibility permission is missing.")
            return
        }
        isRunning = true
        hoverMonitor.start()
        RuntimeLogger.log("Coordinator started.")
    }

    func stop() {
        guard isRunning else { return }
        RuntimeLogger.log("Coordinator stopping.")
        isRunning = false
        hoverMonitor.stop()
        hideCurrentPreview(reason: "Coordinator stopped.", force: true)
        RuntimeLogger.log("Coordinator stopped.")
    }

    @objc
    private func frontAppChanged() {
        let frontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
        RuntimeLogger.log("Frontmost app changed to \(frontmostBundleID)")
        if frontmostBundleID != "com.apple.finder" {
            hideCurrentPreview(reason: "Finder lost focus.")
        }
    }

    private func handleHoverPause(at point: NSPoint) {
        guard isRunning else { return }
        RuntimeLogger.log(
            String(
                format: "Hover pause fired at screen point x=%.1f y=%.1f",
                point.x,
                point.y
            )
        )
        if previewPanel.isEditing {
            RuntimeLogger.log("Hover pause ignored because preview edit mode is active.")
            return
        }
        guard let item = resolver.resolveMarkdown(at: point) else {
            RuntimeLogger.log("Resolver returned nil for hover point. Keeping current preview state.")
            return
        }

        if currentItem == item && previewPanel.isVisible {
            RuntimeLogger.log("Resolved same item again; suppressing reopen for \(item.fileURL.path)")
            return
        }

        if previewPanel.isVisible {
            let previousPath = currentItem?.fileURL.path ?? "none"
            RuntimeLogger.log("Switching preview from \(previousPath) to \(item.fileURL.path)")
            previewPanel.hide(force: true)
        }

        currentItem = item
        RuntimeLogger.log("Resolved markdown item: \(item.fileURL.path) via \(item.elementDescription)")
        previewPanel.showMarkdown(fileURL: item.fileURL, near: point)
    }

    private func hideCurrentPreview(reason: String, force: Bool = false) {
        if previewPanel.isEditing && !force {
            RuntimeLogger.log("\(reason) ignored because preview edit mode is active.")
            return
        }
        let previousPath = currentItem?.fileURL.path ?? "none"
        guard currentItem != nil || previewPanel.isVisible else { return }
        currentItem = nil
        RuntimeLogger.log("\(reason) Clearing current preview item \(previousPath)")
        previewPanel.hide(force: force)
    }
}
