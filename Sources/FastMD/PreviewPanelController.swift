import AppKit
import WebKit

@MainActor
final class PreviewPanelController: NSObject, WKNavigationDelegate {
    private let panel: NSPanel
    private let webView: WKWebView
    private var currentURL: URL?

    override init() {
        webView = WKWebView(frame: .zero)
        webView.setValue(false, forKey: "drawsBackground")

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
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
        panel.contentView = webView

        super.init()
        webView.navigationDelegate = self
    }

    func showMarkdown(fileURL: URL, near screenPoint: NSPoint) {
        guard let markdown = try? String(contentsOf: fileURL, encoding: .utf8) else {
            hide()
            return
        }

        currentURL = fileURL
        let html = MarkdownRenderer.renderHTML(from: markdown, title: fileURL.lastPathComponent)
        webView.loadHTMLString(html, baseURL: fileURL.deletingLastPathComponent())
        placePanel(near: screenPoint)
        panel.orderFrontRegardless()
    }

    func hide() {
        currentURL = nil
        panel.orderOut(nil)
    }

    private func placePanel(near point: NSPoint) {
        let preferred = NSSize(width: 560, height: 420)
        panel.setContentSize(preferred)

        let allScreens = NSScreen.screens
        let screen = allScreens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main
        let bounds = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        var origin = NSPoint(x: point.x + 18, y: point.y - preferred.height - 18)
        if origin.x + preferred.width > bounds.maxX {
            origin.x = point.x - preferred.width - 18
        }
        if origin.x < bounds.minX {
            origin.x = bounds.minX + 12
        }
        if origin.y < bounds.minY {
            origin.y = point.y + 18
        }
        if origin.y + preferred.height > bounds.maxY {
            origin.y = bounds.maxY - preferred.height - 12
        }

        panel.setFrameOrigin(origin)
    }
}
