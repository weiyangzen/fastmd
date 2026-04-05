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
    private var animationGeneration = 0
    private var pendingContentFadeIn = false

    private let showAnimationDuration: TimeInterval = 0.27
    private let hideAnimationDuration: TimeInterval = 0.21
    private let resizeAnimationDuration: TimeInterval = 0.36
    private let contentFadeOutDuration: TimeInterval = 0.21
    private let contentFadeInDuration: TimeInterval = 0.27

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
        installClickMonitors()
        installKeyMonitors()
        installScrollMonitors()
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
        let targetFrame = frameForPanel(near: screenPoint)

        if panel.isVisible {
            loadPreview(markdown: markdown, title: fileURL.lastPathComponent, animatedContentTransition: true)
            animatePanel(to: targetFrame, alpha: 1.0, duration: resizeAnimationDuration)
            panel.makeKey()
            panel.makeFirstResponder(webView)
        } else {
            loadPreview(markdown: markdown, title: fileURL.lastPathComponent, animatedContentTransition: false)
            presentPanel(at: targetFrame)
        }

        let origin = targetFrame.origin
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
        dismissPanel()
        RuntimeLogger.log("Preview hidden. previousURL=\(previousPath)")
    }

    private func loadPreview(markdown: String, title: String, animatedContentTransition: Bool) {
        let contentBaseURL = currentURL?.deletingLastPathComponent()
        let html = MarkdownRenderer.renderHTML(
            from: markdown,
            title: title,
            selectedWidthTierIndex: widthTierIndex,
            backgroundMode: backgroundMode,
            contentBaseURL: contentBaseURL
        )

        if animatedContentTransition && panel.isVisible {
            pendingContentFadeIn = true
            NSAnimationContext.runAnimationGroup { context in
                context.duration = contentFadeOutDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                webView.animator().alphaValue = 0.0
            } completionHandler: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.loadRenderedHTML(html, markdown: markdown, contentBaseURL: contentBaseURL)
                }
            }
        } else {
            pendingContentFadeIn = false
            webView.alphaValue = 1.0
            loadRenderedHTML(html, markdown: markdown, contentBaseURL: contentBaseURL)
        }
    }

    private func loadRenderedHTML(_ html: String, markdown: String, contentBaseURL: URL?) {
        let cacheDirectory = previewCacheDirectory()
        let htmlURL = cacheDirectory.appendingPathComponent("preview.html")
        let readAccessURL = readAccessRoot(for: markdown, contentBaseURL: contentBaseURL)

        do {
            try html.write(to: htmlURL, atomically: true, encoding: .utf8)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: readAccessURL)
        } catch {
            RuntimeLogger.log("Preview HTML cache write failed, falling back to loadHTMLString: \(error)")
            webView.loadHTMLString(html, baseURL: contentBaseURL)
        }
    }

    private func previewCacheDirectory() -> URL {
        let cacheBase = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = cacheBase.appendingPathComponent("FastMD/Preview", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func readAccessRoot(for markdown: String, contentBaseURL: URL?) -> URL {
        let homeDirectory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).standardizedFileURL
        let needsRootAccess = ([contentBaseURL] + extractedFileURLs(from: markdown))
            .compactMap { $0?.standardizedFileURL }
            .contains { url in
                let path = url.path
                return path != homeDirectory.path && !path.hasPrefix(homeDirectory.path + "/")
            }

        return needsRootAccess ? URL(fileURLWithPath: "/", isDirectory: true) : homeDirectory
    }

    private func extractedFileURLs(from markdown: String) -> [URL] {
        let pattern = #"file://[^\s"'()<>]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
        return regex.matches(in: markdown, range: range).compactMap { match in
            guard let tokenRange = Range(match.range, in: markdown) else {
                return nil
            }
            return URL(string: String(markdown[tokenRange]))
        }
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
            return
        }

        widthTierIndex = nextIndex
        let targetFrame = frameForPanel(near: lastAnchorPoint)
        if panel.isVisible {
            animatePanel(to: targetFrame, alpha: 1.0, duration: resizeAnimationDuration)
        } else {
            panel.setFrame(targetFrame, display: false)
        }
        animateWidthTierIntoWebView()
        RuntimeLogger.log("Preview width tier changed to index \(widthTierIndex) width=\(MarkdownRenderer.widthTiers[widthTierIndex])")
    }

    private func syncWidthTierIntoWebView() {
        let script = "window.FastMD && window.FastMD.syncWidthTier(\(widthTierIndex));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func animateWidthTierIntoWebView() {
        let script = "window.FastMD && window.FastMD.animateWidthTier(\(widthTierIndex));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func toggleBackgroundMode() {
        backgroundMode = backgroundMode.opposite
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

    private func frameForPanel(near point: NSPoint) -> NSRect {
        let allScreens = NSScreen.screens
        let screen = allScreens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let aspectRatio: CGFloat = 4.0 / 3.0
        let edgeInset: CGFloat = 12
        let pointerOffset: CGFloat = 18
        let availableWidth = max(bounds.width - edgeInset * 2, 320)
        let availableHeight = max(bounds.height - edgeInset * 2, 240)
        let maxFitWidth = min(availableWidth, availableHeight * aspectRatio)
        let maxFitHeight = maxFitWidth / aspectRatio

        let requestedWidth = CGFloat(MarkdownRenderer.widthTiers[widthTierIndex])
        let requestedHeight = requestedWidth / aspectRatio
        let width = min(requestedWidth, maxFitWidth)
        let height = min(requestedHeight, maxFitHeight)

        let preferred = NSSize(width: width, height: height)

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

        return NSRect(origin: origin, size: preferred)
    }

    private func presentPanel(at targetFrame: NSRect) {
        animationGeneration += 1
        let generation = animationGeneration
        let startFrame = scaledFrame(targetFrame, scale: 0.985, yOffset: -8)

        panel.alphaValue = 0.0
        panel.setFrame(startFrame, display: false)
        panel.orderFrontRegardless()
        panel.makeKey()
        panel.makeFirstResponder(webView)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = showAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 1.0
            panel.animator().setFrame(targetFrame, display: true)
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, generation == self.animationGeneration else { return }
                self.panel.alphaValue = 1.0
                self.panel.setFrame(targetFrame, display: true)
            }
        }
    }

    private func dismissPanel() {
        animationGeneration += 1
        let generation = animationGeneration
        let currentFrame = panel.frame
        let endFrame = scaledFrame(currentFrame, scale: 0.985, yOffset: -8)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = hideAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0.0
            panel.animator().setFrame(endFrame, display: true)
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, generation == self.animationGeneration else { return }
                self.panel.orderOut(nil)
                self.panel.alphaValue = 1.0
                self.panel.setFrame(currentFrame, display: false)
            }
        }
    }

    private func animatePanel(to targetFrame: NSRect, alpha: CGFloat, duration: TimeInterval) {
        animationGeneration += 1
        let generation = animationGeneration

        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = alpha
            panel.animator().setFrame(targetFrame, display: true)
        } completionHandler: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, generation == self.animationGeneration else { return }
                self.panel.alphaValue = alpha
                self.panel.setFrame(targetFrame, display: true)
            }
        }
    }

    private func scaledFrame(_ frame: NSRect, scale: CGFloat, yOffset: CGFloat) -> NSRect {
        let scaledSize = NSSize(width: frame.width * scale, height: frame.height * scale)
        let originX = frame.midX - scaledSize.width / 2
        let originY = frame.midY - scaledSize.height / 2 + yOffset
        return NSRect(origin: NSPoint(x: originX, y: originY), size: scaledSize)
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard pendingContentFadeIn else { return }
        pendingContentFadeIn = false

        NSAnimationContext.runAnimationGroup { context in
            context.duration = contentFadeInDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            webView.animator().alphaValue = 1.0
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        pendingContentFadeIn = false
        webView.alphaValue = 1.0
        RuntimeLogger.log("Preview web navigation failed: \(error)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        pendingContentFadeIn = false
        webView.alphaValue = 1.0
        RuntimeLogger.log("Preview provisional navigation failed: \(error)")
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
