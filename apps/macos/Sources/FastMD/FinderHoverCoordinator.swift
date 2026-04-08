import AppKit
import Foundation

@MainActor
final class FinderHoverCoordinator {
    private let hoverMonitor = HoverMonitorService()
    private let resolver = FinderItemResolver()
    private let selectionResolver = FinderSelectionResolver()
    private let previewPanel = PreviewPanelController()
    private let spaceKeyMonitor: SpaceKeyMonitor
    private var currentItem: HoveredMarkdownItem?
    /// When true, the currently visible preview was opened by a Space-key
    /// toggle (not by hover). Hover pause events suppress the usual
    /// "switch to hovered file" behavior until the user closes the preview,
    /// so Space-triggered previews feel stable.
    private var isOpenedBySpace = false

    private(set) var isRunning = false

    init() {
        self.spaceKeyMonitor = SpaceKeyMonitor(snapshotHolder: selectionResolver.snapshotHolder)

        hoverMonitor.onHoverPause = { [weak self] point in
            self?.handleHoverPause(at: point)
        }
        previewPanel.onOutsideClick = { [weak self] in
            self?.hideCurrentPreview(reason: "Clicked outside preview.")
        }
        spaceKeyMonitor.onSpacePressed = { [weak self] in
            self?.togglePreviewForSelection()
        }
        spaceKeyMonitor.onEscapePressed = { [weak self] in
            self?.hideCurrentPreview(reason: "Escape pressed.")
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
        spaceKeyMonitor.start()
        selectionResolver.refreshNow(reason: "coordinator start")
        RuntimeLogger.log("Coordinator started.")
    }

    func stop() {
        guard isRunning else { return }
        RuntimeLogger.log("Coordinator stopping.")
        isRunning = false
        hoverMonitor.stop()
        spaceKeyMonitor.stop()
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
        if isOpenedBySpace && previewPanel.isVisible {
            RuntimeLogger.log("Hover pause ignored because preview is currently Space-owned.")
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
        }

        currentItem = item
        RuntimeLogger.log("Resolved markdown item: \(item.fileURL.path) via \(item.elementDescription)")
        previewPanel.showMarkdown(fileURL: item.fileURL, near: point)
        spaceKeyMonitor.setPreviewVisible(true)
    }

    /// Called by SpaceKeyMonitor when the user presses Space while Finder is
    /// frontmost and a Markdown file is selected. Strict toggle: if the
    /// preview is visible, close it; otherwise open it for the selected file.
    private func togglePreviewForSelection() {
        guard isRunning else { return }
        if previewPanel.isEditing {
            RuntimeLogger.log("Space toggle ignored because preview edit mode is active.")
            return
        }
        if previewPanel.isVisible {
            RuntimeLogger.log("Space toggle: preview is visible, closing.")
            hideCurrentPreview(reason: "Space toggle close.")
            return
        }

        let snapshot = selectionResolver.snapshotHolder.current
        guard case .markdown(let url) = snapshot.state else {
            RuntimeLogger.log("Space toggle: snapshot is not markdown (state=\(describeState(snapshot.state))); ignoring.")
            return
        }

        // Anchor the preview at the current pointer location for now. When
        // anchor geometry lands we will prefer the selected row's AX frame.
        let anchor = NSEvent.mouseLocation
        currentItem = HoveredMarkdownItem(fileURL: url, elementDescription: "Space toggle selection")
        isOpenedBySpace = true
        previewPanel.showMarkdown(fileURL: url, near: anchor)
        spaceKeyMonitor.setPreviewVisible(true)
        RuntimeLogger.log("Space toggle: opened preview for \(url.path)")
    }

    private func hideCurrentPreview(reason: String, force: Bool = false) {
        if previewPanel.isEditing && !force {
            RuntimeLogger.log("\(reason) ignored because preview edit mode is active.")
            return
        }
        let previousPath = currentItem?.fileURL.path ?? "none"
        guard currentItem != nil || previewPanel.isVisible else { return }
        currentItem = nil
        isOpenedBySpace = false
        RuntimeLogger.log("\(reason) Clearing current preview item \(previousPath)")
        previewPanel.hide(force: force)
        spaceKeyMonitor.setPreviewVisible(false)
    }

    private func describeState(_ state: FinderSelectionState) -> String {
        switch state {
        case .unknown: return "unknown"
        case .nonMarkdown: return "nonMarkdown"
        case .markdown(let url): return "markdown(\(url.lastPathComponent))"
        }
    }
}
