import AppKit
import WebKit

private final class PreviewPanelWindow: NSPanel {
    var shouldStartTopChromeDrag: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown, shouldStartTopChromeDrag?(event) == true {
            performDrag(with: event)
            return
        }

        super.sendEvent(event)
    }
}

struct WarmedPreviewKey: Hashable {
    let path: String
    let selectedWidthTierIndex: Int
    let backgroundMode: MarkdownRenderer.BackgroundMode
}

struct WarmedPreviewFingerprint: Equatable {
    let contentModificationDate: Date?
    let fileSize: Int?

    static func capture(for fileURL: URL) -> WarmedPreviewFingerprint {
        let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
        return WarmedPreviewFingerprint(
            contentModificationDate: values?.contentModificationDate,
            fileSize: values?.fileSize
        )
    }

    func matches(fileURL: URL) -> Bool {
        Self.capture(for: fileURL) == self
    }
}

struct WarmedPreviewSnapshot {
    let key: WarmedPreviewKey
    let fileURL: URL
    let title: String
    let markdown: String
    let contentBaseURL: URL
    let fingerprint: WarmedPreviewFingerprint
}

private struct PreviewShellPayload: Encodable {
    let title: String
    let markdown: String
    let contentBaseURL: String?
    let filePath: String
    let cacheToken: String
}

enum WarmedPreviewLoader {
    static func load(
        fileURL: URL,
        selectedWidthTierIndex: Int,
        backgroundMode: MarkdownRenderer.BackgroundMode
    ) throws -> WarmedPreviewSnapshot {
        let normalizedURL = fileURL.standardizedFileURL
        let markdown = try String(contentsOf: normalizedURL, encoding: .utf8)
        let contentBaseURL = normalizedURL.deletingLastPathComponent()
        return WarmedPreviewSnapshot(
            key: WarmedPreviewKey(
                path: normalizedURL.path,
                selectedWidthTierIndex: selectedWidthTierIndex,
                backgroundMode: backgroundMode
            ),
            fileURL: normalizedURL,
            title: normalizedURL.lastPathComponent,
            markdown: markdown,
            contentBaseURL: contentBaseURL,
            fingerprint: WarmedPreviewFingerprint.capture(for: normalizedURL)
        )
    }
}

final class WarmedPreviewCache {
    private var snapshots: [WarmedPreviewKey: WarmedPreviewSnapshot] = [:]

    func snapshot(
        for fileURL: URL,
        selectedWidthTierIndex: Int,
        backgroundMode: MarkdownRenderer.BackgroundMode
    ) -> WarmedPreviewSnapshot? {
        let normalizedURL = fileURL.standardizedFileURL
        let key = WarmedPreviewKey(
            path: normalizedURL.path,
            selectedWidthTierIndex: selectedWidthTierIndex,
            backgroundMode: backgroundMode
        )
        guard let snapshot = snapshots[key] else {
            return nil
        }
        guard snapshot.fingerprint.matches(fileURL: normalizedURL) else {
            snapshots.removeValue(forKey: key)
            return nil
        }
        return snapshot
    }

    func store(_ snapshot: WarmedPreviewSnapshot) {
        snapshots[snapshot.key] = snapshot
    }

    func invalidate(fileURL: URL) {
        let normalizedPath = fileURL.standardizedFileURL.path
        snapshots = snapshots.filter { $0.key.path != normalizedPath }
    }
}

@MainActor
final class PreviewPanelController: NSObject, WKNavigationDelegate, NSWindowDelegate {
    nonisolated static let topChromeDragHeight: CGFloat = 58

    private let panel: PreviewPanelWindow
    private let contentContainer = NSView()
    private let webView: WKWebView
    private var currentURL: URL?
    private var currentMarkdown: String?
    private var lastAnchorPoint = NSPoint(x: 0, y: 0)
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var localKeyMonitor: Any?
    private var globalScrollMonitor: Any?
    private var localScrollMonitor: Any?
    private var widthTierIndex = 0
    private var backgroundMode: MarkdownRenderer.BackgroundMode = .white
    private var interactionHot = false
    private var animationGeneration = 0
    private var pendingContentFadeIn = false
    private let warmedPreviewCache = WarmedPreviewCache()
    private var pendingWarmups: Set<WarmedPreviewKey> = []
    private var shellLoaded = false
    private var shellLoadInFlight = false
    private var pendingShellSnapshot: WarmedPreviewSnapshot?
    private var pagingIdleWorkItem: DispatchWorkItem?
    private var isPagingInteractionActive = false
    private var widthTransitionRequestID = 0
    private var pageTransitionRequestID = 0
    private var pendingScrollDelta: CGFloat = 0
    private var scrollFlushScheduled = false
    private var scrollIdleWorkItem: DispatchWorkItem?
    private var isScrollInteractionActive = false

    private let showAnimationDuration: TimeInterval = 0.27
    private let hideAnimationDuration: TimeInterval = 0.21
    private let resizeAnimationDuration: TimeInterval = 0.36
    private let contentFadeOutDuration: TimeInterval = 0.21
    private let contentFadeInDuration: TimeInterval = 0.27

    var isVisible: Bool { panel.isVisible }
    var isEditing = false
    var onOutsideClick: (() -> Void)?
    var onFrameChanged: ((CGRect?, Bool) -> Void)?

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
        panel.isMovable = true
        // Becomes key on demand so the panel can receive arrow / PgUp / PgDn / scroll
        // input via NSEvent local monitors. The panel is a `.nonactivatingPanel`, so
        // Finder remains the frontmost (active) application even while we hold the key
        // window — `frontAppChanged` in the coordinator only checks frontmost, not key.
        panel.becomesKeyOnlyIfNeeded = false

        super.init()

        panel.delegate = self
        panel.shouldStartTopChromeDrag = { [weak self] event in
            guard let self else { return false }
            return self.shouldStartTopChromeDrag(for: event)
        }

        webView.navigationDelegate = self
        contentController.add(PreviewBridgeScriptHandler(owner: self), name: "previewBridge")
        configureContentContainer()
        installClickMonitors()
        installKeyMonitors()
        installScrollMonitors()
        ensureShellLoaded()
    }

    func prepareMarkdown(fileURL: URL) {
        let normalizedURL = fileURL.standardizedFileURL
        let key = WarmedPreviewKey(
            path: normalizedURL.path,
            selectedWidthTierIndex: widthTierIndex,
            backgroundMode: backgroundMode
        )

        if warmedPreviewCache.snapshot(
            for: normalizedURL,
            selectedWidthTierIndex: widthTierIndex,
            backgroundMode: backgroundMode
        ) != nil || pendingWarmups.contains(key) {
            return
        }

        pendingWarmups.insert(key)
        DispatchQueue.global(qos: .utility).async { [selectedWidthTierIndex = widthTierIndex, backgroundMode] in
            let snapshot = try? WarmedPreviewLoader.load(
                fileURL: normalizedURL,
                selectedWidthTierIndex: selectedWidthTierIndex,
                backgroundMode: backgroundMode
            )

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.pendingWarmups.remove(key)
                guard let snapshot else {
                    RuntimeLogger.log("Preview warmup failed for \(normalizedURL.path)")
                    return
                }
                self.warmedPreviewCache.store(snapshot)
                RuntimeLogger.log(
                    "Preview warmup ready for \(snapshot.fileURL.path) widthTier=\(selectedWidthTierIndex) background=\(backgroundMode.rawValue)"
                )
            }
        }
    }

    func showMarkdown(fileURL: URL, near screenPoint: NSPoint) {
        let normalizedURL = fileURL.standardizedFileURL
        let warmedSnapshot = warmedPreviewCache.snapshot(
            for: normalizedURL,
            selectedWidthTierIndex: widthTierIndex,
            backgroundMode: backgroundMode
        )
        let snapshot = warmedSnapshot ?? immediateSnapshot(fileURL: normalizedURL)
        let reusedWarmup = warmedSnapshot != nil

        guard let snapshot else {
            RuntimeLogger.log("Preview load failed for \(normalizedURL.path) using UTF-8.")
            hide(force: true)
            return
        }

        warmedPreviewCache.store(snapshot)
        currentURL = snapshot.fileURL
        currentMarkdown = snapshot.markdown
        lastAnchorPoint = screenPoint
        interactionHot = true
        let targetFrame = frameForPanel(near: screenPoint)

        if panel.isVisible {
            loadPreview(snapshot: snapshot, animatedContentTransition: true)
            animatePanel(to: targetFrame, alpha: 1.0, duration: resizeAnimationDuration)
            panel.makeKey()
            panel.makeFirstResponder(webView)
        } else {
            loadPreview(snapshot: snapshot, animatedContentTransition: false)
            presentPanel(at: targetFrame)
        }
        publishFrameChange()

        let origin = targetFrame.origin
        RuntimeLogger.log(
            String(
                format: "Preview shown for %@ at panel origin x=%.1f y=%.1f widthTier=%d requestedWidth=%d warmed=%@",
                snapshot.fileURL.path,
                origin.x,
                origin.y,
                widthTierIndex,
                MarkdownRenderer.widthTiers[widthTierIndex],
                reusedWarmup ? "true" : "false"
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
        pendingShellSnapshot = nil
        dismissPanel()
        publishFrameChange()
        RuntimeLogger.log("Preview hidden. previousURL=\(previousPath)")
    }

    private func loadPreview(snapshot: WarmedPreviewSnapshot, animatedContentTransition: Bool) {
        if !shellLoaded {
            pendingShellSnapshot = snapshot
            ensureShellLoaded()
            pendingContentFadeIn = false
            webView.alphaValue = 1.0
            return
        }

        if animatedContentTransition && panel.isVisible {
            pendingContentFadeIn = true
            NSAnimationContext.runAnimationGroup { context in
                context.duration = contentFadeOutDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                webView.animator().alphaValue = 0.0
            } completionHandler: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.applySnapshotToShell(snapshot)
                }
            }
        } else {
            pendingContentFadeIn = false
            webView.alphaValue = 1.0
            applySnapshotToShell(snapshot)
        }
    }

    private func immediateSnapshot(fileURL: URL) -> WarmedPreviewSnapshot? {
        do {
            return try WarmedPreviewLoader.load(
                fileURL: fileURL,
                selectedWidthTierIndex: widthTierIndex,
                backgroundMode: backgroundMode
            )
        } catch {
            RuntimeLogger.log("Preview load failed for \(fileURL.path): \(error)")
            return nil
        }
    }

    private func ensureShellLoaded() {
        if shellLoaded || shellLoadInFlight {
            return
        }

        let html = MarkdownRenderer.renderHTML(
            from: "",
            title: "Preview",
            selectedWidthTierIndex: widthTierIndex,
            backgroundMode: backgroundMode,
            contentBaseURL: nil
        )
        let cacheDirectory = previewCacheDirectory()
        let htmlURL = cacheDirectory.appendingPathComponent("preview-shell.html")

        do {
            try html.write(to: htmlURL, atomically: true, encoding: .utf8)
            shellLoadInFlight = true
            webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: "/", isDirectory: true))
        } catch {
            RuntimeLogger.log("Preview shell cache write failed, falling back to loadHTMLString: \(error)")
            shellLoadInFlight = true
            webView.loadHTMLString(html, baseURL: URL(fileURLWithPath: "/", isDirectory: true))
        }
    }

    private func previewCacheDirectory() -> URL {
        let cacheBase = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = cacheBase.appendingPathComponent("FastMD/Preview", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func applySnapshotToShell(_ snapshot: WarmedPreviewSnapshot) {
        let payload = PreviewShellPayload(
            title: snapshot.title,
            markdown: snapshot.markdown,
            contentBaseURL: snapshot.contentBaseURL.absoluteString,
            filePath: snapshot.fileURL.path,
            cacheToken: snapshotCacheToken(for: snapshot)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]

        guard let data = try? encoder.encode(payload) else {
            RuntimeLogger.log("Preview shell payload encoding failed for \(snapshot.fileURL.path)")
            return
        }

        let base64 = data.base64EncodedString()
        let script = #"""
        (() => {
          const binary = atob("\#(base64)");
          const bytes = Uint8Array.from(binary, (value) => value.charCodeAt(0));
          const payload = JSON.parse(new TextDecoder().decode(bytes));
          if (window.FastMD && typeof window.FastMD.updateDocument === "function") {
            window.FastMD.updateDocument(payload);
          }
        })();
        """#
        webView.evaluateJavaScript(script) { [weak self] _, error in
            guard let self else { return }
            if let error {
                RuntimeLogger.log("Preview shell update failed for \(snapshot.fileURL.path): \(error)")
                self.pendingContentFadeIn = false
                self.webView.alphaValue = 1.0
                return
            }

            if self.pendingContentFadeIn {
                self.pendingContentFadeIn = false
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = self.contentFadeInDuration
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    self.webView.animator().alphaValue = 1.0
                }
            }
        }
    }

    private func snapshotCacheToken(for snapshot: WarmedPreviewSnapshot) -> String {
        let fileSize = snapshot.fingerprint.fileSize ?? -1
        let modifiedAt = snapshot.fingerprint.contentModificationDate?.timeIntervalSince1970 ?? 0
        return "\(snapshot.fileURL.path)|\(fileSize)|\(modifiedAt)"
    }

    private func installClickMonitors() {
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            Task { @MainActor in
                self?.handlePotentialOutsideClick()
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            guard let self else { return event }
            Task { @MainActor in
                self.handlePotentialOutsideClick()
            }
            return event
        }
    }

    private func installKeyMonitors() {
        // Local-only on purpose. A global key monitor cannot consume the event,
        // so installing one would cause the preview to scroll/page AND Finder to
        // simultaneously act on the same key (selection move, list scroll, etc.).
        // The panel becomes the key window when shown, so the local monitor fires
        // for arrow / PgUp / PgDn / Tab while the user interacts with the
        // preview. PR2's CGEventTap will reroute these from Finder for the
        // "preview is hot but Finder is key" case.
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handlePotentialHotKey(event, canConsume: true) ? nil : event
        }
    }

    private func installScrollMonitors() {
        // Scroll uses both monitors on purpose, unlike key input.
        //
        // Right after a hover-triggered show, the cursor is usually still over
        // Finder, not over the panel. The local monitor never sees scroll events
        // dispatched to Finder's window, so without a global monitor the user
        // would have to first move the pointer into the panel before the wheel
        // could scroll the preview — that breaks the "hover-then-scroll" flow.
        //
        // We accept that the wheel will also scroll Finder's list underneath the
        // preview while it is hot. That bleed is far less harmful than the key
        // bleed: scroll direction matches user intent in both surfaces, the
        // Finder list is largely hidden by the panel, and nothing about Finder's
        // selection state changes. The PR2 CGEventTap will replace this with a
        // proper consume-and-route policy.
        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            Task { @MainActor in
                _ = self?.handlePotentialScroll(event, canConsume: false)
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

    private func shouldStartTopChromeDrag(for event: NSEvent) -> Bool {
        guard event.type == .leftMouseDown else { return false }
        guard panel.isVisible else { return false }
        guard !isEditing else { return false }
        guard event.window === panel else { return false }
        RuntimeLogger.log("Preview top chrome drag started.")
        return Self.isPointInTopChromeDragRegion(
            event.locationInWindow,
            windowSize: contentContainer.bounds.size
        )
    }

    nonisolated static func topChromeDragRegion(windowSize: NSSize) -> NSRect {
        let clampedHeight = max(0, min(topChromeDragHeight, windowSize.height))
        return NSRect(
            x: 0,
            y: max(0, windowSize.height - clampedHeight),
            width: max(0, windowSize.width),
            height: clampedHeight
        )
    }

    nonisolated static func isPointInTopChromeDragRegion(_ point: NSPoint, windowSize: NSSize) -> Bool {
        topChromeDragRegion(windowSize: windowSize).contains(point)
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
        default:
            return false
        }
    }

    private func handlePotentialScroll(_ event: NSEvent, canConsume: Bool) -> Bool {
        guard panel.isVisible else { return false }
        guard !isEditing else { return false }
        guard interactionHot || panel.frame.contains(NSEvent.mouseLocation) else { return false }
        if !canConsume && panel.frame.contains(NSEvent.mouseLocation) {
            return false
        }

        let delta = event.hasPreciseScrollingDeltas ? -event.scrollingDeltaY : -event.scrollingDeltaY * 10
        guard abs(delta) > 0.01 else { return false }
        enqueueScrollPreview(delta)
        return canConsume
    }

    private func adjustWidthTier(by delta: Int) {
        let nextIndex = MarkdownRenderer.clampedWidthTierIndex(widthTierIndex + delta)
        guard nextIndex != widthTierIndex else {
            syncWidthTierIntoWebView()
            return
        }

        let previousIndex = widthTierIndex
        widthTierIndex = nextIndex
        let requestID = nextWidthTransitionRequestID()
        let startedAt = CFAbsoluteTimeGetCurrent()
        let targetFrame = frameForPanel(near: lastAnchorPoint)
        RuntimeLogger.log(
            "Preview perf metric [widthTierRequest] id=\(requestID) from=\(previousIndex) to=\(widthTierIndex) requestedWidth=\(MarkdownRenderer.widthTiers[widthTierIndex]) panelVisible=\(panel.isVisible)"
        )
        if panel.isVisible {
            animatePanel(to: targetFrame, alpha: 1.0, duration: resizeAnimationDuration) {
                RuntimeLogger.log(
                    String(
                        format: "Preview perf metric [widthTierPanel] id=%d durationMs=%.1f frame=%.0fx%.0f",
                        requestID,
                        (CFAbsoluteTimeGetCurrent() - startedAt) * 1000,
                        targetFrame.width,
                        targetFrame.height
                    )
                )
            }
        } else {
            panel.setFrame(targetFrame, display: false)
            RuntimeLogger.log(
                String(
                    format: "Preview perf metric [widthTierPanel] id=%d durationMs=0.0 frame=%.0fx%.0f",
                    requestID,
                    targetFrame.width,
                    targetFrame.height
                )
            )
        }
        animateWidthTierIntoWebView(requestID: requestID)
        RuntimeLogger.log("Preview width tier changed to index \(widthTierIndex) width=\(MarkdownRenderer.widthTiers[widthTierIndex])")
        if let currentURL {
            prepareMarkdown(fileURL: currentURL)
        }
    }

    private func syncWidthTierIntoWebView() {
        let script = "window.FastMD && window.FastMD.syncWidthTier(\(widthTierIndex));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func animateWidthTierIntoWebView(requestID: Int) {
        let script = "window.FastMD && window.FastMD.animateWidthTier(\(widthTierIndex), \(requestID));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func toggleBackgroundMode() {
        backgroundMode = backgroundMode.opposite
        let script = "window.FastMD && window.FastMD.syncBackgroundMode(\"\(backgroundMode.rawValue)\");"
        webView.evaluateJavaScript(script, completionHandler: nil)
        RuntimeLogger.log("Preview background mode changed to \(backgroundMode.rawValue)")
        if let currentURL {
            prepareMarkdown(fileURL: currentURL)
        }
    }

    private func scrollPreview(by delta: CGFloat) {
        let script = "window.FastMD && window.FastMD.scrollBy(\(delta));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func enqueueScrollPreview(_ delta: CGFloat) {
        pendingScrollDelta += delta
        beginScrollInteraction()

        guard !scrollFlushScheduled else { return }
        scrollFlushScheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.flushScrollPreview()
        }
    }

    private func flushScrollPreview() {
        scrollFlushScheduled = false
        let delta = pendingScrollDelta
        pendingScrollDelta = 0
        guard abs(delta) > 0.01 else { return }
        scrollPreview(by: delta)
    }

    private func beginScrollInteraction() {
        if !isScrollInteractionActive {
            isScrollInteractionActive = true
            webView.evaluateJavaScript("window.FastMD && window.FastMD.setScrollActive(true);", completionHandler: nil)
        }

        scrollIdleWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isScrollInteractionActive = false
            self.webView.evaluateJavaScript("window.FastMD && window.FastMD.setScrollActive(false);", completionHandler: nil)
        }
        scrollIdleWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14, execute: workItem)
    }

    private func performPagePreview(by pages: Int) {
        guard pages != 0 else { return }
        let requestID = nextPageTransitionRequestID()
        RuntimeLogger.log(
            "Preview perf metric [pageRequest] id=\(requestID) pages=\(pages) panelHeight=\(Int(panel.frame.height))"
        )
        beginPagingInteraction()
        let script = #"""
        (() => {
          if (window.FastMD && typeof window.FastMD.pageBy === "function") {
            window.FastMD.pageBy(\#(pages), \#(requestID));
            return true;
          }
          return false;
        })();
        """#
        webView.evaluateJavaScript(script) { [weak self] result, error in
            guard let self else { return }
            let handled = result as? Bool ?? false
            guard error != nil || !handled else {
                return
            }

            if let error {
                RuntimeLogger.log("Preview page bridge failed for id=\(requestID), falling back to native paging: \(error)")
            } else {
                RuntimeLogger.log("Preview page bridge unavailable for id=\(requestID), falling back to native paging.")
            }

            if pages > 0 {
                for _ in 0..<pages {
                    self.webView.pageDown(nil)
                }
                return
            }

            for _ in 0..<(-pages) {
                self.webView.pageUp(nil)
            }
        }
    }

    private func beginPagingInteraction() {
        if !isPagingInteractionActive {
            isPagingInteractionActive = true
            webView.evaluateJavaScript("window.FastMD && window.FastMD.setPagingActive(true);", completionHandler: nil)
        }

        pagingIdleWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isPagingInteractionActive = false
            self.webView.evaluateJavaScript("window.FastMD && window.FastMD.setPagingActive(false);", completionHandler: nil)
        }
        pagingIdleWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30, execute: workItem)
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
            warmedPreviewCache.invalidate(fileURL: currentURL)
            prepareMarkdown(fileURL: currentURL)
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
                self.publishFrameChange()
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
                self.publishFrameChange()
            }
        }
    }

    private func animatePanel(
        to targetFrame: NSRect,
        alpha: CGFloat,
        duration: TimeInterval,
        completion: (@Sendable () -> Void)? = nil
    ) {
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
                self.publishFrameChange()
                completion?()
            }
        }
    }

    private func nextWidthTransitionRequestID() -> Int {
        widthTransitionRequestID += 1
        return widthTransitionRequestID
    }

    private func nextPageTransitionRequestID() -> Int {
        pageTransitionRequestID += 1
        return pageTransitionRequestID
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
        case "perfMetric":
            let stage = body["stage"] as? String ?? "unknown"
            let detail = body["detail"] as? String ?? ""
            RuntimeLogger.log("Preview perf metric [\(stage)] \(detail)")
        default:
            break
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        shellLoadInFlight = false
        shellLoaded = true

        if let snapshot = pendingShellSnapshot {
            pendingShellSnapshot = nil
            applySnapshotToShell(snapshot)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        shellLoadInFlight = false
        pendingContentFadeIn = false
        webView.alphaValue = 1.0
        RuntimeLogger.log("Preview web navigation failed: \(error)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        shellLoadInFlight = false
        pendingContentFadeIn = false
        webView.alphaValue = 1.0
        RuntimeLogger.log("Preview provisional navigation failed: \(error)")
    }

    func pagePreview(by pages: Int) {
        guard panel.isVisible else { return }
        performPagePreview(by: pages)
    }

    func windowDidMove(_ notification: Notification) {
        publishFrameChange()
    }

    func windowDidResize(_ notification: Notification) {
        publishFrameChange()
    }

    private func publishFrameChange() {
        onFrameChanged?(panel.isVisible ? panel.frame : nil, panel.isVisible)
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
