import AppKit
import Foundation

@MainActor
final class FinderHoverCoordinator {
    private let hoverMonitor = HoverMonitorService()
    private let resolver = FinderItemResolver()
    private let selectionResolver = FinderSelectionResolver()
    private let previewPanel = PreviewPanelController()
    private let spaceKeyMonitor: SpaceKeyMonitor
    private var pendingWarmedHoverItem: HoveredMarkdownItem?
    private var currentItem: HoveredMarkdownItem?
    /// When true, the currently visible preview was opened by a Space-key
    /// toggle (not by hover). Hover pause events suppress the usual
    /// "switch to hovered file" behavior until the user closes the preview,
    /// so Space-triggered previews feel stable.
    private var isOpenedBySpace = false

    private(set) var isRunning = false

    init() {
        self.spaceKeyMonitor = SpaceKeyMonitor(snapshotHolder: selectionResolver.snapshotHolder)

        hoverMonitor.onMouseActivity = { [weak self] in
            self?.pendingWarmedHoverItem = nil
        }
        hoverMonitor.onHoverWarmup = { [weak self] point in
            self?.handleHoverWarmup(at: point)
        }
        hoverMonitor.onHoverPause = { [weak self] point in
            self?.handleHoverPause(at: point)
        }
        selectionResolver.onSnapshotChanged = { [weak self] snapshot in
            self?.handleSelectionSnapshot(snapshot)
        }
        previewPanel.onOutsideClick = { [weak self] in
            self?.hideCurrentPreview(reason: "Clicked outside preview.")
        }
        previewPanel.onFrameChanged = { [weak self] frame, isVisible in
            self?.spaceKeyMonitor.setPreviewVisible(isVisible)
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

    var isHoverTriggerEnabled: Bool { PreferencesStore.hoverTriggerEnabled }
    var isSpaceTriggerEnabled: Bool { PreferencesStore.spaceTriggerEnabled }

    func start() {
        guard !isRunning else { return }
        let trusted = AccessibilityPermissionManager.ensureTrusted(prompt: true)
        RuntimeLogger.log("Coordinator start requested. accessibilityTrusted=\(trusted)")
        guard trusted else {
            RuntimeLogger.log("Coordinator start aborted because Accessibility permission is missing.")
            return
        }
        isRunning = true
        // Trust has just been confirmed; it is now safe to touch the AX API
        // and install the observer on Finder.
        selectionResolver.activate()
        applyTriggerPreferences()
        RuntimeLogger.log(
            "Coordinator started. hover=\(PreferencesStore.hoverTriggerEnabled) space=\(PreferencesStore.spaceTriggerEnabled)"
        )
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

    func setHoverTriggerEnabled(_ enabled: Bool) {
        PreferencesStore.hoverTriggerEnabled = enabled
        RuntimeLogger.log("Preference hoverTriggerEnabled -> \(enabled)")
        if isRunning {
            applyTriggerPreferences()
        }
    }

    func setSpaceTriggerEnabled(_ enabled: Bool) {
        PreferencesStore.spaceTriggerEnabled = enabled
        RuntimeLogger.log("Preference spaceTriggerEnabled -> \(enabled)")
        selectionResolver.setSpaceTriggerEnabled(enabled)
        if isRunning {
            applyTriggerPreferences()
        }
    }

    /// Start or stop the hover and space subsystems to match the current
    /// preference flags. Runs any time preferences change (including at
    /// initial start) so the two monitors stay in sync with the user's
    /// intent without leaking resources when either is turned off.
    private func applyTriggerPreferences() {
        if PreferencesStore.hoverTriggerEnabled {
            hoverMonitor.start()
        } else {
            hoverMonitor.stop()
        }
        if PreferencesStore.spaceTriggerEnabled {
            spaceKeyMonitor.start()
        } else {
            spaceKeyMonitor.stop()
        }
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
        let selectionSnapshot = selectionResolver.snapshotHolder.current
        if selectionSnapshot.blocksPreviewTriggers {
            pendingWarmedHoverItem = nil
            RuntimeLogger.log("Hover pause ignored because Finder text input is active.")
            return
        }
        if previewPanel.isEditing {
            pendingWarmedHoverItem = nil
            RuntimeLogger.log("Hover pause ignored because preview edit mode is active.")
            return
        }
        if isOpenedBySpace && previewPanel.isVisible {
            pendingWarmedHoverItem = nil
            RuntimeLogger.log("Hover pause ignored because preview is currently Space-owned.")
            return
        }
        let item = pendingWarmedHoverItem ?? resolver.resolveMarkdown(at: point)
        pendingWarmedHoverItem = nil
        guard let item else {
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

    private func handleHoverWarmup(at point: NSPoint) {
        guard isRunning else { return }
        let selectionSnapshot = selectionResolver.snapshotHolder.current
        if selectionSnapshot.blocksPreviewTriggers || previewPanel.isEditing {
            pendingWarmedHoverItem = nil
            return
        }
        if isOpenedBySpace && previewPanel.isVisible {
            pendingWarmedHoverItem = nil
            return
        }
        guard let item = resolver.resolveMarkdown(at: point) else {
            pendingWarmedHoverItem = nil
            return
        }
        pendingWarmedHoverItem = item
        previewPanel.prepareMarkdown(fileURL: item.fileURL)
        RuntimeLogger.log("Hover warmup prepared \(item.fileURL.path) via \(item.elementDescription)")
    }

    private func handleSelectionSnapshot(_ snapshot: FinderSelectionSnapshot) {
        if snapshot.blocksPreviewTriggers {
            pendingWarmedHoverItem = nil
            if previewPanel.isVisible {
                hideCurrentPreview(reason: "Finder text input is active.")
            }
            return
        }

        guard snapshot.spaceTriggerEnabled else { return }
        guard case .markdown(let url) = snapshot.state else { return }

        previewPanel.prepareMarkdown(fileURL: url)
        RuntimeLogger.log("Selection warmup prepared \(url.path)")
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
        pendingWarmedHoverItem = nil
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
