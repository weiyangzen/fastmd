import AppKit
import WebKit

private final class PreviewPanelWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class PreviewPanelController: NSObject, WKNavigationDelegate {
    private let panel: PreviewPanelWindow
    private let contentContainer = NSView()
    private let webView: WKWebView
    private let overlayControls = NSView()
    private let widthLabel = NSTextField(labelWithString: "")
    private let hotkeyHintLabel = NSTextField(labelWithString: "←/→ 宽度 · Tab 明暗")
    private var currentURL: URL?
    private var currentMarkdown: String?
    private var lastAnchorPoint = NSPoint(x: 0, y: 0)
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var globalScrollMonitor: Any?
    private var localScrollMonitor: Any?
    private var widthTierIndex = 0
    private var backgroundMode: MarkdownRenderer.BackgroundMode = .white
    private var interactionHot = false

    var isVisible: Bool { panel.isVisible }
    var isEditing = false
    var onOutsideClick: (() -> Void)?

    override init() {
        let contentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")

        panel = PreviewPanelWindow(
            contentRect: NSRect(x: 0, y: 0, width: CGFloat(MarkdownRenderer.widthTiers[0]), height: 680),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = true

        super.init()

        webView.navigationDelegate = self
        contentController.add(PreviewBridgeScriptHandler(owner: self), name: "previewBridge")
        configureContentContainer()
        configureOverlayControls()
        installClickMonitors()
        installKeyMonitors()
        installScrollMonitors()
        syncNativeWidthControls()
    }

    func showMarkdown(fileURL: URL, near screenPoint: NSPoint) {
        guard let markdown = try? String(contentsOf: fileURL, encoding: .utf8) else {
            RuntimeLogger.log("Preview load failed for \(fileURL.path) using UTF-8.")
            hide(force: true)
            return
        }

        currentURL = fileURL
        currentMarkdown = markdown
        lastAnchorPoint = screenPoint
        interactionHot = true
        loadPreview(markdown: markdown, title: fileURL.lastPathComponent)
        placePanel(near: screenPoint)
        panel.orderFrontRegardless()
        panel.makeKey()
        panel.makeFirstResponder(webView)
        let origin = panel.frame.origin
        RuntimeLogger.log(
            String(
                format: "Preview shown for %@ at panel origin x=%.1f y=%.1f widthTier=%d requestedWidth=%d",
                fileURL.path,
                origin.x,
                origin.y,
                widthTierIndex,
                MarkdownRenderer.widthTiers[widthTierIndex]
            )
        )
    }

    func hide(force: Bool = false) {
        if isEditing && !force {
            RuntimeLogger.log("Preview hide ignored because inline edit mode is active.")
            return
        }

        guard currentURL != nil || panel.isVisible else { return }
        let previousPath = currentURL?.path ?? "none"
        currentURL = nil
        currentMarkdown = nil
        isEditing = false
        interactionHot = false
        syncNativeWidthControls()
        panel.orderOut(nil)
        RuntimeLogger.log("Preview hidden. previousURL=\(previousPath)")
    }

    private func loadPreview(markdown: String, title: String) {
        let html = MarkdownRenderer.renderHTML(
            from: markdown,
            title: title,
            selectedWidthTierIndex: widthTierIndex,
            backgroundMode: backgroundMode
        )
        webView.loadHTMLString(html, baseURL: currentURL?.deletingLastPathComponent())
    }

    private func installClickMonitors() {
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            Task { @MainActor in
                self?.handlePotentialOutsideClick()
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            Task { @MainActor in
                self?.handlePotentialOutsideClick()
            }
            return event
        }
    }

    private func installKeyMonitors() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handlePotentialHotKey(event, canConsume: false)
            }
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handlePotentialHotKey(event, canConsume: true) ? nil : event
        }
    }

    private func installScrollMonitors() {
        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            Task { @MainActor in
                self?.handlePotentialScroll(event, canConsume: false)
            }
        }

        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self else { return event }
            return self.handlePotentialScroll(event, canConsume: true) ? nil : event
        }
    }

    private func configureContentContainer() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = contentContainer
        contentContainer.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            webView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            webView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])
    }

    private func configureOverlayControls() {
        overlayControls.translatesAutoresizingMaskIntoConstraints = false
        overlayControls.wantsLayer = true
        overlayControls.layer?.cornerRadius = 14
        overlayControls.layer?.masksToBounds = true

        widthLabel.translatesAutoresizingMaskIntoConstraints = false
        hotkeyHintLabel.translatesAutoresizingMaskIntoConstraints = false
        widthLabel.alignment = .center
        widthLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        hotkeyHintLabel.alignment = .center
        hotkeyHintLabel.font = .systemFont(ofSize: 11, weight: .regular)

        let stack = NSStackView(views: [widthLabel, hotkeyHintLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 2

        overlayControls.addSubview(stack)
        contentContainer.addSubview(overlayControls)

        NSLayoutConstraint.activate([
            overlayControls.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 12),
            overlayControls.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -14),

            stack.leadingAnchor.constraint(equalTo: overlayControls.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: overlayControls.trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: overlayControls.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: overlayControls.bottomAnchor, constant: -8),

            widthLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 140),
        ])
    }

    private func handlePotentialOutsideClick() {
        guard panel.isVisible else { return }
        guard !isEditing else { return }
        guard !panel.frame.contains(NSEvent.mouseLocation) else { return }
        RuntimeLogger.log("Outside click detected for preview panel.")
        onOutsideClick?()
    }

    private func handlePotentialHotKey(_ event: NSEvent, canConsume: Bool) -> Bool {
        guard panel.isVisible else { return false }
        guard !isEditing else { return false }
        guard interactionHot || panel.frame.contains(NSEvent.mouseLocation) else { return false }

        switch Int(event.keyCode) {
        case 123:
            adjustWidthTier(by: -1)
            return canConsume
        case 124:
            adjustWidthTier(by: 1)
            return canConsume
        case 125:
            scrollPreview(by: 84)
            return canConsume
        case 126:
            scrollPreview(by: -84)
            return canConsume
        case 48:
            toggleBackgroundMode()
            return canConsume
        case 49:
            pagePreview(by: event.modifierFlags.contains(.shift) ? -1 : 1)
            return canConsume
        case 116:
            pagePreview(by: -1)
            return canConsume
        case 121:
            pagePreview(by: 1)
            return canConsume
        default:
            return false
        }
    }

    private func handlePotentialScroll(_ event: NSEvent, canConsume: Bool) -> Bool {
        guard panel.isVisible else { return false }
        guard !isEditing else { return false }
        guard interactionHot || panel.frame.contains(NSEvent.mouseLocation) else { return false }

        let delta = event.hasPreciseScrollingDeltas ? -event.scrollingDeltaY : -event.scrollingDeltaY * 10
        guard abs(delta) > 0.01 else { return false }
        scrollPreview(by: delta)
        return canConsume
    }

    private func adjustWidthTier(by delta: Int) {
        let nextIndex = MarkdownRenderer.clampedWidthTierIndex(widthTierIndex + delta)
        guard nextIndex != widthTierIndex else {
            syncWidthTierIntoWebView()
            syncNativeWidthControls()
            return
        }

        widthTierIndex = nextIndex
        placePanel(near: lastAnchorPoint)
        syncWidthTierIntoWebView()
        syncNativeWidthControls()
        RuntimeLogger.log("Preview width tier changed to index \(widthTierIndex) width=\(MarkdownRenderer.widthTiers[widthTierIndex])")
    }

    private func syncNativeWidthControls() {
        widthLabel.stringValue = "\(widthTierIndex + 1)/\(MarkdownRenderer.widthTiers.count) · \(MarkdownRenderer.widthTiers[widthTierIndex])px"
        hotkeyHintLabel.stringValue = "←/→ 宽度 · Tab 明暗"
        let isBlack = backgroundMode == .black
        overlayControls.layer?.backgroundColor = (isBlack ? NSColor(calibratedWhite: 0.08, alpha: 0.92) : NSColor(calibratedWhite: 1.0, alpha: 0.92)).cgColor
        widthLabel.textColor = isBlack ? .white : .black
        hotkeyHintLabel.textColor = isBlack ? NSColor(calibratedWhite: 0.82, alpha: 1.0) : NSColor(calibratedWhite: 0.33, alpha: 1.0)
    }

    private func syncWidthTierIntoWebView() {
        let script = "window.FastMD && window.FastMD.syncWidthTier(\(widthTierIndex));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func toggleBackgroundMode() {
        backgroundMode = backgroundMode.opposite
        syncNativeWidthControls()
        let script = "window.FastMD && window.FastMD.syncBackgroundMode(\"\(backgroundMode.rawValue)\");"
        webView.evaluateJavaScript(script, completionHandler: nil)
        RuntimeLogger.log("Preview background mode changed to \(backgroundMode.rawValue)")
    }

    private func scrollPreview(by delta: CGFloat) {
        let script = "window.FastMD && window.FastMD.scrollBy(\(delta));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func pagePreview(by pages: Int) {
        let script = "window.FastMD && window.FastMD.pageBy(\(pages));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func saveMarkdown(_ markdown: String) {
        guard let currentURL else {
            finishJavaScriptSave(success: false, message: "No current file is attached to the preview.")
            return
        }

        do {
            try markdown.write(to: currentURL, atomically: true, encoding: .utf8)
            currentMarkdown = markdown
            isEditing = false
            syncNativeWidthControls()
            RuntimeLogger.log("Inline block edit saved back to \(currentURL.path)")
            finishJavaScriptSave(success: true, message: nil)
        } catch {
            RuntimeLogger.log("Inline block edit save failed for \(currentURL.path): \(error)")
            finishJavaScriptSave(success: false, message: String(describing: error))
        }
    }

    private func finishJavaScriptSave(success: Bool, message: String?) {
        let escapedMessage = (message ?? "").replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        let script = "window.FastMD && window.FastMD.didFinishSave(\(success ? "true" : "false"), \"\(escapedMessage)\");"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func placePanel(near point: NSPoint) {
        let allScreens = NSScreen.screens
        let screen = allScreens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let aspectRatio: CGFloat = 4.0 / 3.0
        let edgeInset: CGFloat = 12
        let pointerOffset: CGFloat = 18
        let maxWidth = max(bounds.width - edgeInset * 2, CGFloat(MarkdownRenderer.widthTiers[0]))
        let maxHeight = max(bounds.height - edgeInset * 2, maxWidth / aspectRatio)

        let requestedWidth = CGFloat(MarkdownRenderer.widthTiers[widthTierIndex])
        let requestedHeight = requestedWidth / aspectRatio
        var width = requestedWidth
        var height = requestedHeight

        if requestedWidth > maxWidth || requestedHeight > maxHeight {
            let fallbackWidth = min(bounds.width * 0.5, maxWidth)
            let fallbackHeight = min(bounds.height * 0.5, maxHeight)

            if requestedWidth > maxWidth {
                width = fallbackWidth
                height = width / aspectRatio
            }

            if requestedHeight > maxHeight || height > fallbackHeight {
                height = fallbackHeight
                width = height * aspectRatio
            }
        }

        if width > maxWidth {
            width = maxWidth
            height = width / aspectRatio
        }

        if height > maxHeight {
            height = maxHeight
            width = height * aspectRatio
        }

        width = max(width, CGFloat(MarkdownRenderer.widthTiers[0]))
        height = max(height, width / aspectRatio)

        let preferred = NSSize(width: width, height: height)
        panel.setContentSize(preferred)

        var origin = NSPoint(x: point.x + pointerOffset, y: point.y - preferred.height - pointerOffset)
        let minX = bounds.minX + edgeInset
        let maxX = bounds.maxX - preferred.width - edgeInset
        let minY = bounds.minY + edgeInset
        let maxY = bounds.maxY - preferred.height - edgeInset

        if origin.x > maxX {
            origin.x = point.x - preferred.width - pointerOffset
        }
        if origin.x < minX {
            origin.x = minX
        }
        if origin.x > maxX {
            origin.x = maxX
        }

        if origin.y < minY {
            origin.y = point.y + pointerOffset
        }
        if origin.y > maxY {
            origin.y = maxY
        }
        if origin.y < minY {
            origin.y = minY
        }

        panel.setFrameOrigin(origin)
    }

    fileprivate func handleBridgeMessage(_ message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String
        else {
            return
        }

        switch type {
        case "adjustWidthTier":
            guard !isEditing, let delta = body["delta"] as? Int else { return }
            adjustWidthTier(by: delta)
        case "toggleBackgroundMode":
            guard !isEditing else { return }
            toggleBackgroundMode()
        case "editingState":
            let editing = body["editing"] as? Bool ?? false
            isEditing = editing
            syncNativeWidthControls()
            if editing {
                panel.makeKeyAndOrderFront(nil)
            }
            RuntimeLogger.log("Preview editing state changed. editing=\(editing)")
        case "saveMarkdown":
            guard let markdown = body["markdown"] as? String else { return }
            saveMarkdown(markdown)
        case "clientError":
            let message = body["message"] as? String ?? "Unknown web preview error"
            RuntimeLogger.log("Preview web client error: \(message)")
        default:
            break
        }
    }
}

private final class PreviewBridgeScriptHandler: NSObject, WKScriptMessageHandler {
    weak var owner: PreviewPanelController?

    init(owner: PreviewPanelController) {
        self.owner = owner
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Task { @MainActor in
            self.owner?.handleBridgeMessage(message)
        }
    }
}
