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

private enum PreviewNavigationMode {
    case markdown
    case externalURL(URL)
}

enum MarkdownOpenWidthTierBehavior {
    case bestFitCurrentScreen
    case preserveCurrent
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
    let byteCount: Int
}

private struct PreviewShellPayload: Encodable {
    let title: String
    let markdown: String
    let selectedWidthTierIndex: Int
    let backgroundMode: MarkdownRenderer.BackgroundMode
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
            fingerprint: WarmedPreviewFingerprint.capture(for: normalizedURL),
            byteCount: markdown.lengthOfBytes(using: .utf8)
        )
    }
}

final class WarmedPreviewCache {
    private var snapshots: [WarmedPreviewKey: WarmedPreviewSnapshot] = [:]
    private var accessOrder: [WarmedPreviewKey] = []
    private var totalByteCount = 0
    private let entryLimit = 24
    private let totalByteLimit = 6 * 1024 * 1024

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
            removeSnapshot(forKey: key)
            return nil
        }
        touch(key)
        return snapshot
    }

    func store(_ snapshot: WarmedPreviewSnapshot) {
        removeSnapshot(forKey: snapshot.key)
        snapshots[snapshot.key] = snapshot
        totalByteCount += snapshot.byteCount
        touch(snapshot.key)
        evictIfNeeded()
    }

    func invalidate(fileURL: URL) {
        let normalizedPath = fileURL.standardizedFileURL.path
        let keysToRemove = snapshots.keys.filter { $0.path == normalizedPath }
        keysToRemove.forEach(removeSnapshot(forKey:))
    }

    private func touch(_ key: WarmedPreviewKey) {
        accessOrder.removeAll(where: { $0 == key })
        accessOrder.append(key)
    }

    private func removeSnapshot(forKey key: WarmedPreviewKey) {
        if let existing = snapshots.removeValue(forKey: key) {
            totalByteCount -= existing.byteCount
        }
        accessOrder.removeAll(where: { $0 == key })
    }

    private func evictIfNeeded() {
        while snapshots.count > entryLimit || totalByteCount > totalByteLimit {
            guard let oldest = accessOrder.first else { break }
            removeSnapshot(forKey: oldest)
        }
    }
}

private struct RemoteMarkdownSnapshot {
    let url: URL
    let title: String
    let markdown: String
    let contentBaseURL: URL
    let etag: String?
    let lastModified: String?
    let cacheToken: String
    let byteCount: Int
}

private final class RemoteMarkdownCache {
    private var snapshots: [String: RemoteMarkdownSnapshot] = [:]
    private var accessOrder: [String] = []
    private var totalByteCount = 0
    private let entryLimit = 16
    private let totalByteLimit = 8 * 1024 * 1024

    func snapshot(for url: URL) -> RemoteMarkdownSnapshot? {
        let key = url.absoluteString
        guard let snapshot = snapshots[key] else { return nil }
        touch(key)
        return snapshot
    }

    func store(_ snapshot: RemoteMarkdownSnapshot) {
        let key = snapshot.url.absoluteString
        removeSnapshot(forKey: key)
        snapshots[key] = snapshot
        totalByteCount += snapshot.byteCount
        touch(key)
        evictIfNeeded()
    }

    private func touch(_ key: String) {
        accessOrder.removeAll(where: { $0 == key })
        accessOrder.append(key)
    }

    private func removeSnapshot(forKey key: String) {
        if let existing = snapshots.removeValue(forKey: key) {
            totalByteCount -= existing.byteCount
        }
        accessOrder.removeAll(where: { $0 == key })
    }

    private func evictIfNeeded() {
        while snapshots.count > entryLimit || totalByteCount > totalByteLimit {
            guard let oldest = accessOrder.first else { break }
            removeSnapshot(forKey: oldest)
        }
    }
}

private actor RemoteMarkdownStore {
    private let cache = RemoteMarkdownCache()

    func snapshot(for url: URL) -> RemoteMarkdownSnapshot? {
        cache.snapshot(for: url)
    }

    func store(_ snapshot: RemoteMarkdownSnapshot) {
        cache.store(snapshot)
    }
}

@MainActor
final class PreviewPanelController: NSObject, WKNavigationDelegate, NSWindowDelegate {
    nonisolated static let topChromeDragHeight: CGFloat = 58
    private static let sharedWarmedPreviewCache = WarmedPreviewCache()
    nonisolated(unsafe) private static var sharedShellFileURL: URL?
    private static let sharedShellLock = NSLock()
    private static let sharedRemoteMarkdownStore = RemoteMarkdownStore()
    private static let sharedURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 80 * 1024 * 1024
        )
        return URLSession(configuration: configuration)
    }()

    private let panel: PreviewPanelWindow
    private let contentContainer = NSView()
    private let webView: WKWebView
    private let pinButton = NSButton()
    private var currentURL: URL?
    private var currentMarkdown: String?
    private var lastAnchorPoint = NSPoint(x: 0, y: 0)
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var lastHandledClickTimestamp: TimeInterval = 0
    private var lastHandledClickType: NSEvent.EventType?
    private var localKeyMonitor: Any?
    private var globalScrollMonitor: Any?
    private var localScrollMonitor: Any?
    private var widthTierIndex = 0
    private var backgroundMode: MarkdownRenderer.BackgroundMode = .white
    private var interactionHot = false
    private var animationGeneration = 0
    private var pendingContentFadeIn = false
    private var warmedPreviewCache: WarmedPreviewCache { Self.sharedWarmedPreviewCache }
    private var pendingWarmups: Set<WarmedPreviewKey> = []
    private var shellLoaded = false
    private var shellLoadInFlight = false
    private var shellHTMLURL: URL?
    private var pendingShellSnapshot: WarmedPreviewSnapshot?
    private var pagingIdleWorkItem: DispatchWorkItem?
    private var isPagingInteractionActive = false
    private var widthTransitionRequestID = 0
    private var pageTransitionRequestID = 0
    private var pendingScrollDelta: CGFloat = 0
    private var scrollFlushScheduled = false
    private var scrollIdleWorkItem: DispatchWorkItem?
    private var isScrollInteractionActive = false
    private var navigationMode: PreviewNavigationMode = .markdown
    private var retainedPinnedPanels: [UUID: PreviewPanelController] = [:]
    private var activeChildPanelID: UUID?
    private var isPinnedManually = false
    private var isPinnedForChildLayer = false

    private let showAnimationDuration: TimeInterval = 0.27
    private let hideAnimationDuration: TimeInterval = 0.21
    private let resizeAnimationDuration: TimeInterval = 0.36
    private let contentFadeOutDuration: TimeInterval = 0.21
    private let contentFadeInDuration: TimeInterval = 0.27

    var isVisible: Bool { panel.isVisible }
    var isEditing = false
    var pinned: Bool { isPinnedManually || isPinnedForChildLayer }
    var onOutsideClick: (() -> Void)?
    var onFrameChanged: ((CGRect?, Bool) -> Void)?
    var onDidHide: (() -> Void)?
    var onScrollInterceptionChanged: ((Bool) -> Void)?

    private var activeVisibleChildPanel: PreviewPanelController? {
        guard let activeChildPanelID,
              let child = retainedPinnedPanels[activeChildPanelID],
              child.isVisible
        else {
            return nil
        }
        return child
    }

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
        updatePinButtonAppearance()
    }

    func prepareMarkdown(
        fileURL: URL,
        near screenPoint: NSPoint? = nil,
        widthTierBehavior: MarkdownOpenWidthTierBehavior = .preserveCurrent
    ) {
        let normalizedURL = fileURL.standardizedFileURL
        let selectedWidthTierIndex = resolvedWidthTierIndex(
            for: widthTierBehavior,
            near: screenPoint ?? lastAnchorPoint
        )
        let key = WarmedPreviewKey(
            path: normalizedURL.path,
            selectedWidthTierIndex: selectedWidthTierIndex,
            backgroundMode: backgroundMode
        )

        if warmedPreviewCache.snapshot(
            for: normalizedURL,
            selectedWidthTierIndex: selectedWidthTierIndex,
            backgroundMode: backgroundMode
        ) != nil || pendingWarmups.contains(key) {
            return
        }

        pendingWarmups.insert(key)
        DispatchQueue.global(qos: .utility).async { [selectedWidthTierIndex, backgroundMode] in
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

    func showMarkdown(
        fileURL: URL,
        near screenPoint: NSPoint,
        widthTierBehavior: MarkdownOpenWidthTierBehavior = .bestFitCurrentScreen,
        preferredFrame: NSRect? = nil
    ) {
        let selectedWidthTierIndex = resolvedWidthTierIndex(for: widthTierBehavior, near: screenPoint)
        let previousWidthTierIndex = widthTierIndex
        widthTierIndex = selectedWidthTierIndex
        if case .bestFitCurrentScreen = widthTierBehavior, previousWidthTierIndex != selectedWidthTierIndex {
            RuntimeLogger.log(
                "Preview auto-selected width tier \(selectedWidthTierIndex) width=\(MarkdownRenderer.widthTiers[selectedWidthTierIndex]) for screen near x=\(Int(screenPoint.x)) y=\(Int(screenPoint.y))"
            )
        }

        let normalizedURL = fileURL.standardizedFileURL
        let warmedSnapshot = warmedPreviewCache.snapshot(
            for: normalizedURL,
            selectedWidthTierIndex: selectedWidthTierIndex,
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
        navigationMode = .markdown
        setPinnedManually(false)
        setPinnedForChildLayer(false)
        currentURL = snapshot.fileURL
        currentMarkdown = snapshot.markdown
        lastAnchorPoint = screenPoint
        interactionHot = true
        let targetFrame = preferredFrame ?? frameForPanel(near: screenPoint)

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

    func showExternalURL(
        _ url: URL,
        near screenPoint: NSPoint? = nil,
        preferredFrame: NSRect? = nil
    ) {
        interactionHot = true
        navigationMode = .externalURL(url)
        setPinnedManually(false)
        setPinnedForChildLayer(false)
        currentURL = nil
        currentMarkdown = nil
        pendingShellSnapshot = nil
        shellLoaded = false
        shellLoadInFlight = false
        webView.alphaValue = 1.0

        let targetFrame = preferredFrame ?? frameForPanel(near: screenPoint ?? lastAnchorPoint)
        if panel.isVisible {
            if preferredFrame != nil {
                animatePanel(to: targetFrame, alpha: 1.0, duration: resizeAnimationDuration)
            }
            panel.makeKey()
            panel.makeFirstResponder(webView)
        } else {
            presentPanel(at: targetFrame)
        }

        webView.load(URLRequest(url: url))
        publishFrameChange()
        RuntimeLogger.log("External link preview opened for \(url.absoluteString) pinned=\(pinned)")
    }

    func showDetachedMarkdown(
        title: String,
        markdown: String,
        contentBaseURL: URL?,
        cacheToken: String? = nil,
        preferredFrame: NSRect? = nil
    ) {
        interactionHot = true
        navigationMode = .markdown
        setPinnedManually(false)
        setPinnedForChildLayer(false)
        currentURL = nil
        currentMarkdown = markdown
        pendingShellSnapshot = nil

        if !shellLoaded {
            ensureShellLoaded()
        }

        let targetFrame = preferredFrame ?? frameForPanel(near: lastAnchorPoint)
        if panel.isVisible {
            if preferredFrame != nil {
                animatePanel(to: targetFrame, alpha: 1.0, duration: resizeAnimationDuration)
            }
            panel.makeKey()
            panel.makeFirstResponder(webView)
        } else {
            presentPanel(at: targetFrame)
        }

        let payload = PreviewShellPayload(
            title: title,
            markdown: markdown,
            selectedWidthTierIndex: widthTierIndex,
            backgroundMode: backgroundMode,
            contentBaseURL: contentBaseURL?.absoluteString,
            filePath: "",
            cacheToken: cacheToken ?? "detached|\(title)|\(markdown.lengthOfBytes(using: .utf8))"
        )
        applyShellPayload(payload, logLabel: title)
        publishFrameChange()
        RuntimeLogger.log("Detached markdown preview opened for \(title)")
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
        onScrollInterceptionChanged?(false)
        interactionHot = false
        pendingShellSnapshot = nil
        navigationMode = .markdown
        dismissPanel()
        publishFrameChange()
        if force {
            let retainedPanels = retainedPinnedPanels.values
            retainedPinnedPanels.removeAll()
            retainedPanels.forEach { $0.hide(force: true) }
        }
        onDidHide?()
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

        if let htmlURL = Self.sharedShellURL(previewCacheDirectory: previewCacheDirectory()) {
            shellHTMLURL = htmlURL
            shellLoadInFlight = true
            webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: "/", isDirectory: true))
            return
        }

        let html = MarkdownRenderer.renderHTML(
            from: "",
            title: "Preview",
            selectedWidthTierIndex: 0,
            backgroundMode: .white,
            contentBaseURL: nil
        )
        shellLoadInFlight = true
        webView.loadHTMLString(html, baseURL: URL(fileURLWithPath: "/", isDirectory: true))
    }

    private func previewCacheDirectory() -> URL {
        let cacheBase = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directory = cacheBase.appendingPathComponent("FastMD/Preview", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func sharedShellURL(previewCacheDirectory: URL) -> URL? {
        sharedShellLock.lock()
        defer { sharedShellLock.unlock() }

        if let sharedShellFileURL, FileManager.default.fileExists(atPath: sharedShellFileURL.path) {
            return sharedShellFileURL
        }

        let html = MarkdownRenderer.renderHTML(
            from: "",
            title: "Preview",
            selectedWidthTierIndex: 0,
            backgroundMode: .white,
            contentBaseURL: nil
        )
        let htmlURL = previewCacheDirectory.appendingPathComponent("preview-shell-shared.html")
        do {
            try html.write(to: htmlURL, atomically: true, encoding: .utf8)
            sharedShellFileURL = htmlURL
            return htmlURL
        } catch {
            RuntimeLogger.log("Shared preview shell cache write failed: \(error)")
            return nil
        }
    }

    private func applySnapshotToShell(_ snapshot: WarmedPreviewSnapshot) {
        let payload = PreviewShellPayload(
            title: snapshot.title,
            markdown: snapshot.markdown,
            selectedWidthTierIndex: widthTierIndex,
            backgroundMode: backgroundMode,
            contentBaseURL: snapshot.contentBaseURL.absoluteString,
            filePath: snapshot.fileURL.path,
            cacheToken: snapshotCacheToken(for: snapshot)
        )
        applyShellPayload(payload, logLabel: snapshot.fileURL.path)
    }

    private func applyShellPayload(_ payload: PreviewShellPayload, logLabel: String) {
        let arguments: [String: Any] = [
            "title": payload.title,
            "markdown": payload.markdown,
            "contentBaseURL": payload.contentBaseURL as Any,
            "filePath": payload.filePath,
            "cacheToken": payload.cacheToken,
        ]
        let script = #"""
        if (window.FastMD && typeof window.FastMD.updateDocument === "function") {
          window.FastMD.updateDocument(payload);
        }
        """#
        webView.callAsyncJavaScript(script, arguments: ["payload": arguments], in: nil, in: .page) { [weak self] result in
            guard let self else { return }
            if case .failure(let error) = result {
                RuntimeLogger.log("Preview shell update failed for \(logLabel): \(error)")
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

    private func isMarkdownURL(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "md" || ext == "markdown"
    }

    private func handleActivatedLink(_ url: URL) {
        guard let scheme = url.scheme?.lowercased() else { return }

        if isMarkdownURL(url) {
            openMarkdownChildPanel(for: url)
            return
        }

        if scheme == "http" || scheme == "https" {
            openExternalChildPanel(for: url)
            return
        }

        if url.isFileURL {
            NSWorkspace.shared.open(url)
            return
        }

        if scheme != "about" {
            NSWorkspace.shared.open(url)
        }
    }

    private func openExternalChildPanel(for url: URL) {
        let child = PreviewPanelController()
        let identifier = UUID()
        retainedPinnedPanels[identifier] = child
        activeChildPanelID = identifier
        setPinnedForChildLayer(true)
        child.onOutsideClick = { [weak child] in
            child?.hide()
        }
        child.onDidHide = { [weak self] in
            self?.handleChildPanelDidHide(identifier: identifier)
        }
        child.setPinnedManually(false)
        child.setPinnedForChildLayer(false)
        interactionHot = false
        child.showExternalURL(
            url,
            preferredFrame: offsetPinnedLinkFrame(from: panel.isVisible ? panel.frame : nil)
        )
    }

    private func openMarkdownChildPanel(for url: URL) {
        let child = PreviewPanelController()
        let identifier = UUID()
        retainedPinnedPanels[identifier] = child
        activeChildPanelID = identifier
        setPinnedForChildLayer(true)
        child.onOutsideClick = { [weak child] in
            child?.hide()
        }
        child.onDidHide = { [weak self] in
            self?.handleChildPanelDidHide(identifier: identifier)
        }
        child.setPinnedManually(false)
        child.setPinnedForChildLayer(false)
        interactionHot = false
        child.widthTierIndex = widthTierIndex
        let preferredFrame = offsetPinnedLinkFrame(from: panel.isVisible ? panel.frame : nil)

        if url.isFileURL {
            let anchorPoint = panel.isVisible
                ? NSPoint(x: panel.frame.maxX, y: panel.frame.maxY)
                : NSEvent.mouseLocation
            child.showMarkdown(
                fileURL: url.standardizedFileURL,
                near: anchorPoint,
                widthTierBehavior: .preserveCurrent,
                preferredFrame: preferredFrame
            )
            return
        }

        Task { @MainActor [weak child] in
            guard let child else { return }
            do {
                let remoteSnapshot = try await Self.fetchRemoteMarkdown(url)
                child.showDetachedMarkdown(
                    title: remoteSnapshot.title,
                    markdown: remoteSnapshot.markdown,
                    contentBaseURL: remoteSnapshot.contentBaseURL,
                    cacheToken: remoteSnapshot.cacheToken,
                    preferredFrame: preferredFrame
                )
            } catch {
                RuntimeLogger.log("Remote markdown child load failed for \(url.absoluteString): \(error)")
                child.showExternalURL(
                    url,
                    preferredFrame: preferredFrame
                )
            }
        }
    }

    private static func fetchRemoteMarkdown(_ url: URL) async throws -> RemoteMarkdownSnapshot {
        let cachedSnapshot = await sharedRemoteMarkdownStore.snapshot(for: url)

        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy
        if let cachedSnapshot {
            if let etag = cachedSnapshot.etag {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            if let lastModified = cachedSnapshot.lastModified {
                request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
            }
        }

        do {
            let (data, response) = try await sharedURLSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 304,
               let cachedSnapshot {
                return cachedSnapshot
            }

            guard let markdown = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }

            let httpResponse = response as? HTTPURLResponse
            let etag = httpResponse?.value(forHTTPHeaderField: "ETag")
            let lastModified = httpResponse?.value(forHTTPHeaderField: "Last-Modified")
            let title = url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent
            let cacheToken = [
                url.absoluteString,
                etag ?? "",
                lastModified ?? "",
                String(data.count),
            ].joined(separator: "|")
            let snapshot = RemoteMarkdownSnapshot(
                url: url,
                title: title,
                markdown: markdown,
                contentBaseURL: url.deletingLastPathComponent(),
                etag: etag,
                lastModified: lastModified,
                cacheToken: cacheToken,
                byteCount: data.count
            )
            await sharedRemoteMarkdownStore.store(snapshot)
            return snapshot
        } catch {
            if let cachedSnapshot {
                return cachedSnapshot
            }
            throw error
        }
    }

    private func handleChildPanelDidHide(identifier: UUID) {
        retainedPinnedPanels.removeValue(forKey: identifier)
        if activeChildPanelID == identifier {
            activeChildPanelID = nil
            setPinnedForChildLayer(false)
            interactionHot = panel.isVisible
            RuntimeLogger.log("Child FastMD layer closed; parent layer auto-unpinned.")
        }
    }

    private func collapseActiveChildLayerIfNeeded() {
        guard let activeChildPanelID,
              let child = retainedPinnedPanels[activeChildPanelID]
        else {
            return
        }

        child.hide()
        RuntimeLogger.log("Returned to parent FastMD layer; child layer closed and parent auto-unpinned.")
    }

    private func offsetPinnedLinkFrame(from sourceFrame: NSRect?) -> NSRect? {
        guard let sourceFrame else { return nil }

        let screens = NSScreen.screens
        let containingScreen = screens.first(where: { $0.visibleFrame.intersects(sourceFrame) }) ?? NSScreen.main
        let visibleFrame = containingScreen?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        var offsetFrame = sourceFrame.offsetBy(dx: 28, dy: -28)
        offsetFrame.origin.x = min(max(offsetFrame.origin.x, visibleFrame.minX + 12), visibleFrame.maxX - offsetFrame.width - 12)
        offsetFrame.origin.y = min(max(offsetFrame.origin.y, visibleFrame.minY + 12), visibleFrame.maxY - offsetFrame.height - 12)
        return offsetFrame
    }

    private func installClickMonitors() {
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            Task { @MainActor in
                self?.handlePotentialOutsideClick(event)
            }
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            guard let self else { return event }
            Task { @MainActor in
                self.handlePotentialOutsideClick(event)
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
        // Finder-targeted wheel events are intercepted by the CGEventTap in
        // SpaceKeyMonitor so they can be consumed instead of scrolling Finder
        // underneath the preview. The local monitor remains for events that
        // already target this panel / WKWebView.
        localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self else { return event }
            return self.handlePotentialScroll(event, canConsume: true) ? nil : event
        }
    }

    private func configureContentContainer() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        pinButton.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView = contentContainer
        contentContainer.addSubview(webView)
        contentContainer.addSubview(pinButton)

        pinButton.bezelStyle = .texturedRounded
        pinButton.isBordered = false
        pinButton.contentTintColor = .secondaryLabelColor
        pinButton.target = self
        pinButton.action = #selector(toggleExternalLinkPinning)
        pinButton.setButtonType(.momentaryPushIn)
        pinButton.focusRingType = .none

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            webView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            webView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            pinButton.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 14),
            pinButton.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            pinButton.widthAnchor.constraint(equalToConstant: 24),
            pinButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    @objc
    private func toggleExternalLinkPinning() {
        setPinnedManually(!isPinnedManually)
        RuntimeLogger.log("Preview manual pin toggle -> \(pinned)")
    }

    private func updatePinButtonAppearance() {
        let symbolName = pinned ? "pin.fill" : "pin.slash"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            image.isTemplate = true
            pinButton.image = image
        }
        pinButton.toolTip = pinned
            ? "Pinned: this window will stay visible until you explicitly close or unpin it."
            : "Unpinned: this window follows normal auto-dismiss behavior."
        pinButton.contentTintColor = pinned
            ? .controlAccentColor
            : .secondaryLabelColor
    }

    private func setPinnedManually(_ pinned: Bool) {
        isPinnedManually = pinned
        updatePinButtonAppearance()
    }

    private func setPinnedForChildLayer(_ pinned: Bool) {
        isPinnedForChildLayer = pinned
        updatePinButtonAppearance()
    }

    private func handlePotentialOutsideClick(_ event: NSEvent?) {
        guard panel.isVisible else { return }
        guard !isEditing else { return }
        guard !pinned else { return }
        if let event, isDuplicateClick(event: event) {
            return
        }
        guard !panel.frame.contains(NSEvent.mouseLocation) else { return }
        RuntimeLogger.log("Outside click detected for preview panel.")
        onOutsideClick?()
    }

    private func isDuplicateClick(event: NSEvent) -> Bool {
        let isSameType = lastHandledClickType == event.type
        let isSameTimestamp = abs(lastHandledClickTimestamp - event.timestamp) < 0.0001
        lastHandledClickTimestamp = event.timestamp
        lastHandledClickType = event.type
        return isSameType && isSameTimestamp
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
        guard activeVisibleChildPanel == nil else { return false }
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
        guard activeVisibleChildPanel == nil else { return false }
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
        if let activeVisibleChildPanel {
            activeVisibleChildPanel.adjustWidthTier(by: delta)
            return
        }

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
        if let activeVisibleChildPanel {
            activeVisibleChildPanel.toggleBackgroundMode()
            return
        }

        backgroundMode = backgroundMode.opposite
        let script = "window.FastMD && window.FastMD.syncBackgroundMode(\"\(backgroundMode.rawValue)\");"
        webView.evaluateJavaScript(script, completionHandler: nil)
        RuntimeLogger.log("Preview background mode changed to \(backgroundMode.rawValue)")
        if let currentURL {
            prepareMarkdown(fileURL: currentURL)
        }
    }

    private func scrollPreview(by delta: CGFloat) {
        if let activeVisibleChildPanel {
            activeVisibleChildPanel.scrollPreview(by: delta)
            return
        }

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
            onScrollInterceptionChanged?(true)
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

    private func resolvedWidthTierIndex(
        for behavior: MarkdownOpenWidthTierBehavior,
        near point: NSPoint
    ) -> Int {
        switch behavior {
        case .bestFitCurrentScreen:
            return bestFitWidthTierIndex(near: point)
        case .preserveCurrent:
            return widthTierIndex
        }
    }

    private func bestFitWidthTierIndex(near point: NSPoint) -> Int {
        let visibleFrame = visibleFrameForPanel(near: point)
        let aspectRatio: CGFloat = 4.0 / 3.0
        let edgeInset: CGFloat = 12
        let availableWidth = max(visibleFrame.width - edgeInset * 2, 320)
        let availableHeight = max(visibleFrame.height - edgeInset * 2, 240)

        for index in MarkdownRenderer.widthTiers.indices.reversed() {
            let candidateWidth = CGFloat(MarkdownRenderer.widthTiers[index])
            let candidateHeight = candidateWidth / aspectRatio
            if candidateWidth <= availableWidth && candidateHeight <= availableHeight {
                return index
            }
        }

        return 0
    }

    private func visibleFrameForPanel(near point: NSPoint) -> NSRect {
        let allScreens = NSScreen.screens
        let screen = allScreens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main
        return screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private func frameForPanel(near point: NSPoint) -> NSRect {
        let bounds = visibleFrameForPanel(near: point)
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
            onScrollInterceptionChanged?(panel.isVisible && !editing)
            if editing {
                panel.makeKeyAndOrderFront(nil)
            }
            RuntimeLogger.log("Preview editing state changed. editing=\(editing)")
        case "saveMarkdown":
            guard let markdown = body["markdown"] as? String else { return }
            saveMarkdown(markdown)
        case "activateLink":
            guard let rawURL = body["url"] as? String,
                  let url = URL(string: rawURL)
            else { return }
            handleActivatedLink(url)
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
        let currentPageURL = webView.url?.standardizedFileURL
        let shellURL = shellHTMLURL?.standardizedFileURL
        let isShellNavigation = shellURL != nil && currentPageURL == shellURL

        shellLoadInFlight = false
        shellLoaded = isShellNavigation
        if isShellNavigation {
            navigationMode = .markdown
        }

        if isShellNavigation, let snapshot = pendingShellSnapshot {
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

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType == .linkActivated,
              let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased()
        else {
            decisionHandler(.allow)
            return
        }

        if scheme == "about" {
            decisionHandler(.allow)
            return
        }

        handleActivatedLink(url)
        decisionHandler(.cancel)
    }

    func pagePreview(by pages: Int) {
        if let activeVisibleChildPanel {
            activeVisibleChildPanel.pagePreview(by: pages)
            return
        }
        guard panel.isVisible else { return }
        performPagePreview(by: pages)
    }

    func windowDidMove(_ notification: Notification) {
        publishFrameChange()
    }

    func windowDidResize(_ notification: Notification) {
        publishFrameChange()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        collapseActiveChildLayerIfNeeded()
    }

    private func publishFrameChange() {
        onFrameChanged?(panel.isVisible ? panel.frame : nil, panel.isVisible)
        onScrollInterceptionChanged?(panel.isVisible && !isEditing)
    }

    func scrollPreview(byExternalDelta delta: CGFloat) {
        if let activeVisibleChildPanel {
            activeVisibleChildPanel.scrollPreview(byExternalDelta: delta)
            return
        }
        guard panel.isVisible else { return }
        guard !isEditing else { return }
        enqueueScrollPreview(delta)
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
