import Foundation

enum MarkdownRenderer {
    enum BackgroundMode: String, Encodable {
        case white
        case black

        var opposite: BackgroundMode {
            switch self {
            case .white: .black
            case .black: .white
            }
        }
    }

    struct PreviewPayload: Encodable {
        let title: String
        let markdown: String
        let widthTiers: [Int]
        let selectedWidthTierIndex: Int
        let backgroundMode: BackgroundMode
        let contentBaseURL: String?
        let filePath: String?
        let cacheToken: String?
    }

    static let widthTiers = [560, 960, 1440, 1920]

    static func clampedWidthTierIndex(_ index: Int) -> Int {
        max(0, min(index, widthTiers.count - 1))
    }

    static func renderHTML(
        from markdown: String,
        title: String,
        selectedWidthTierIndex: Int = 0,
        backgroundMode: BackgroundMode = .white,
        contentBaseURL: URL? = nil
    ) -> String {
        let payload = PreviewPayload(
            title: title,
            markdown: markdown,
            widthTiers: widthTiers,
            selectedWidthTierIndex: clampedWidthTierIndex(selectedWidthTierIndex),
            backgroundMode: backgroundMode,
            contentBaseURL: contentBaseURL?.absoluteString,
            filePath: nil,
            cacheToken: nil
        )

        let payloadJSON = serializedPayload(payload)
        let fallbackHTML = fallbackHTMLBody(from: markdown)

        return #"""
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          \#(baseTag(for: contentBaseURL))
          <title>\#(escapeHTML(title))</title>
          <style>
            \#(highlightCSS)
          </style>
          <style>
            \#(katexCSS)
          </style>
          <style>
            \#(baseCSS)
          </style>
        </head>
        <body>
          <div class="shell">
            <header class="toolbar">
              <div class="toolbar-title">
                <span class="eyebrow">FastMD Preview</span>
                <strong id="doc-title"></strong>
              </div>
              <div class="toolbar-actions" aria-label="Preview controls">
                <span class="hint-chip">
                  <span id="width-label" class="hint-item hint-item-width">← 1/4 →</span>
                  <span class="hint-separator" aria-hidden="true"></span>
                  <span class="hint-item">
                    <span class="hint-icon hint-icon-theme" aria-hidden="true"></span>
                    <span class="hint-text">Tab</span>
                  </span>
                </span>
              </div>
            </header>
            <div id="status-banner" class="status-banner" hidden></div>
            <main id="render-root" class="render-root">\#(fallbackHTML)</main>
          </div>

          <script type="application/json" id="fastmd-payload">\#(payloadJSON)</script>
          <script>\#(vendorScript(named: "highlight.common.min.js"))</script>
          <script>\#(vendorScript(named: "markdown-it.min.js"))</script>
          <script>\#(vendorScript(named: "markdown-it-footnote.min.js"))</script>
          <script>\#(vendorScript(named: "markdown-it-task-lists.min.js"))</script>
          <script>\#(vendorScript(named: "mermaid.min.js"))</script>
          <script>\#(vendorScript(named: "katex.min.js"))</script>
          <script>\#(vendorScript(named: "katex-auto-render.min.js"))</script>
          <script>
            \#(applicationScript)
          </script>
        </body>
        </html>
        """#
    }

    private static let highlightCSS = VendorAssetLoader.text(named: "highlight.github.min.css")
    private static let katexCSS = VendorAssetLoader.inlineKaTeXCSS()

    private static func baseTag(for url: URL?) -> String {
        guard let url else { return "" }
        let href = url.absoluteString.replacingOccurrences(of: "\"", with: "&quot;")
        return #"<base href="\#(href)">"#
    }

    private static func vendorScript(named fileName: String) -> String {
        VendorAssetLoader.text(named: fileName)
            .replacingOccurrences(of: "</script", with: "<\\/script")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }

    private static func serializedPayload(_ payload: PreviewPayload) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        guard let data = try? encoder.encode(payload),
              let json = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }

        return json
            .replacingOccurrences(of: "</", with: "<\\/")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
    }

    private static let baseCSS = #"""
    :root {
      color-scheme: light dark;
      --page-bg: #ffffff;
      --surface: #ffffff;
      --surface-strong: #ffffff;
      --border: rgba(21, 33, 55, 0.12);
      --text: #111111;
      --muted: #5f6b7c;
      --accent: #1f6feb;
      --accent-soft: rgba(31, 111, 235, 0.10);
      --quote: #d0dae8;
      --shadow: 0 24px 56px rgba(15, 23, 42, 0.18);
      --code-bg: #f5f7fb;
      --editor-bg: #fffdf8;
      --editor-border: rgba(208, 150, 24, 0.28);
      --editor-shadow: 0 12px 32px rgba(208, 150, 24, 0.12);
      --image-shadow: 0 10px 24px rgba(15, 23, 42, 0.10);
      --font-ui: "SF Pro Text", "Helvetica Neue", system-ui, sans-serif;
      --font-body: "Charter", "Iowan Old Style", Georgia, serif;
      --font-code: "SF Mono", "Menlo", "Monaco", monospace;
    }

    * { box-sizing: border-box; }

    html, body {
      margin: 0;
      min-height: 100%;
      background: var(--page-bg);
      color: var(--text);
      font-family: var(--font-ui);
      transition: background-color 180ms ease, color 180ms ease;
    }

    body[data-background-mode="black"] {
      --page-bg: #000000;
      --surface: #000000;
      --surface-strong: #000000;
      --border: rgba(255, 255, 255, 0.14);
      --text: #f5f5f5;
      --muted: #b3b3b3;
      --accent: #7fb2ff;
      --accent-soft: rgba(127, 178, 255, 0.12);
      --quote: rgba(255, 255, 255, 0.24);
      --shadow: 0 24px 56px rgba(0, 0, 0, 0.42);
      --code-bg: #0f0f10;
      --editor-bg: #121212;
      --editor-border: rgba(255, 196, 84, 0.36);
      --editor-shadow: 0 12px 32px rgba(0, 0, 0, 0.32);
      --image-shadow: 0 10px 24px rgba(0, 0, 0, 0.36);
    }

    body.is-editing {
      background: var(--page-bg);
    }

    .shell {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }

    .shell.is-width-transition .render-root {
      transform: scale(0.994);
      opacity: 0.985;
      filter: none;
    }

    .shell.is-performance-critical .toolbar {
      backdrop-filter: none;
    }

    .shell.is-performance-critical .render-root {
      filter: none;
    }

    .shell.is-performance-critical .md-block,
    .shell.is-performance-critical img,
    .shell.is-performance-critical video,
    .shell.is-performance-critical .mermaid,
    .shell.is-performance-critical table,
    .shell.is-performance-critical pre,
    .shell.is-performance-critical code {
      transition: none;
      box-shadow: none;
      filter: none;
    }

    .shell.is-performance-critical .md-block:hover {
      background: transparent;
      box-shadow: none;
    }

    .shell.is-performance-critical img,
    .shell.is-performance-critical video {
      box-shadow: none;
    }

    .toolbar {
      position: sticky;
      top: 0;
      z-index: 20;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 14px 18px 12px;
      background: var(--surface-strong);
      backdrop-filter: blur(16px);
      border-bottom: 1px solid var(--border);
      transition: background-color 180ms ease, border-color 180ms ease, color 180ms ease;
    }

    .toolbar-title {
      display: flex;
      flex-direction: column;
      min-width: 0;
      gap: 2px;
    }

    .toolbar-title strong {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      font-size: 0.98rem;
    }

    .eyebrow {
      color: var(--muted);
      font-size: 0.72rem;
      font-weight: 700;
      letter-spacing: 0.08em;
      text-transform: uppercase;
    }

    .toolbar-actions {
      display: inline-flex;
      align-items: center;
      justify-content: flex-end;
      flex-shrink: 0;
      max-width: min(100%, 420px);
      padding-right: 36px;
    }

    .hint-chip {
      display: inline-flex;
      align-items: center;
      flex-wrap: wrap;
      justify-content: flex-end;
      gap: 6px 10px;
      padding: 7px 11px;
      border-radius: 999px;
      border: 1px solid var(--border);
      background: color-mix(in srgb, var(--surface) 94%, transparent);
      transition: background-color 180ms ease, border-color 180ms ease;
    }

    .hint-item {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      color: var(--muted);
      font-size: 0.74rem;
      font-family: var(--font-ui);
      white-space: nowrap;
      transition: color 180ms ease;
    }

    .hint-item-width {
      color: var(--text);
      font-weight: 700;
      letter-spacing: 0.01em;
      font-variant-numeric: tabular-nums;
    }

    .hint-icon {
      width: 18px;
      height: 18px;
      border-radius: 999px;
      border: 1px solid var(--border);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: var(--text);
      font-size: 0.68rem;
      line-height: 1;
      flex-shrink: 0;
      transition: border-color 180ms ease, color 180ms ease, background-color 180ms ease;
    }

    .hint-icon-theme::before {
      content: "◐";
      transform: translateY(-0.02em);
    }

    .hint-icon-page::before {
      content: "⇵";
      transform: translateY(-0.04em);
    }

    .hint-text {
      white-space: nowrap;
    }

    .hint-separator {
      width: 4px;
      height: 4px;
      border-radius: 999px;
      background: color-mix(in srgb, var(--muted) 42%, transparent);
      flex-shrink: 0;
    }

    @media (max-width: 720px) {
      .toolbar {
        align-items: flex-start;
      }

      .toolbar-actions {
        max-width: 100%;
        padding-right: 36px;
      }

      .hint-chip {
        justify-content: flex-start;
      }
    }

    .status-banner {
      margin: 12px 18px 0;
      padding: 10px 12px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      border-radius: 12px;
      border: 1px solid var(--editor-border);
      background: color-mix(in srgb, var(--editor-bg) 88%, transparent);
      color: var(--muted);
      font-size: 0.8rem;
      transition: background-color 180ms ease, border-color 180ms ease, color 180ms ease;
    }

    .status-action {
      appearance: none;
      border: 1px solid color-mix(in srgb, var(--accent) 38%, var(--border));
      border-radius: 999px;
      padding: 6px 10px;
      background: color-mix(in srgb, var(--accent-soft) 52%, var(--surface));
      color: var(--accent);
      font-family: var(--font-ui);
      font-size: 0.76rem;
      font-weight: 700;
      cursor: pointer;
      flex-shrink: 0;
    }

    .render-root {
      flex: 1;
      padding: 18px;
      font-family: var(--font-body);
      line-height: 1.58;
      font-size: 14px;
      transition: color 180ms ease, background-color 180ms ease, transform 360ms ease, opacity 360ms ease, filter 360ms ease;
      transform-origin: top right;
      will-change: transform, opacity, filter;
    }

    .md-block {
      position: relative;
      margin: 0 0 12px;
      padding: 6px 8px;
      border-radius: 10px;
      transition: background-color 180ms ease, box-shadow 180ms ease, color 180ms ease, border-color 180ms ease;
    }

    .md-block:hover {
      background: color-mix(in srgb, var(--accent-soft) 38%, transparent);
      box-shadow: inset 0 0 0 1px color-mix(in srgb, var(--accent) 24%, transparent);
    }

    .md-block.is-editing {
      background: color-mix(in srgb, var(--editor-bg) 88%, transparent);
      box-shadow: inset 0 0 0 1px var(--editor-border), var(--editor-shadow);
    }

    .md-block > :first-child { margin-top: 0; }
    .md-block > :last-child { margin-bottom: 0; }

    h1, h2, h3, h4, h5, h6 {
      margin: 1.05em 0 0.45em;
      line-height: 1.18;
      letter-spacing: -0.02em;
      font-family: var(--font-ui);
    }

    h1 { font-size: 25px; }
    h2 { font-size: 21px; }
    h3 { font-size: 18px; }
    h4 { font-size: 16px; }
    h5 { font-size: 15px; }
    h6 { font-size: 12px; text-transform: uppercase; letter-spacing: 0.08em; color: var(--muted); }

    p { margin: 0.7em 0; }
    em { font-style: italic; }
    strong { font-family: var(--font-ui); font-weight: 700; }
    del { color: var(--muted); }
    mark {
      padding: 0.04em 0.24em;
      border-radius: 0.28em;
      background: rgba(255, 224, 112, 0.72);
      color: inherit;
    }

    sub, sup {
      font-size: 0.72em;
      line-height: 0;
      position: relative;
      vertical-align: baseline;
    }

    sub { bottom: -0.25em; }
    sup { top: -0.48em; }

    a {
      color: var(--accent);
      text-decoration: none;
      border-bottom: 1px solid color-mix(in srgb, var(--accent) 32%, transparent);
    }

    a:hover {
      border-bottom-color: color-mix(in srgb, var(--accent) 70%, transparent);
    }

    hr {
      border: 0;
      border-top: 1px solid var(--border);
      margin: 1.5rem 0;
    }

    blockquote {
      margin: 0.95rem 0;
      padding: 0.24rem 0 0.24rem 1rem;
      border-left: 4px solid var(--quote);
      color: color-mix(in srgb, var(--text) 88%, var(--muted));
      background: color-mix(in srgb, var(--accent-soft) 20%, transparent);
      border-radius: 0 10px 10px 0;
    }

    blockquote blockquote {
      margin-top: 0.8rem;
      background: transparent;
    }

    ul, ol {
      margin: 0.8rem 0;
      padding-left: 1.5rem;
    }

    li { margin: 0.32rem 0; }
    li.task-list-item { list-style: none; margin-left: -1.25rem; }
    li.task-list-item input { margin-right: 0.55rem; }

    table {
      width: 100%;
      border-collapse: collapse;
      margin: 1rem 0;
      font-family: var(--font-ui);
      font-size: 0.96rem;
      overflow: hidden;
      border-radius: 12px;
      border: 1px solid var(--border);
      box-shadow: 0 8px 18px rgba(15, 23, 42, 0.06);
    }

    thead {
      background: color-mix(in srgb, var(--accent-soft) 42%, var(--surface));
    }

    th, td {
      padding: 11px 12px;
      border-bottom: 1px solid var(--border);
      text-align: left;
      vertical-align: top;
    }

    tbody tr:last-child td { border-bottom: 0; }

    code, pre, textarea {
      font-family: var(--font-code);
    }

    code {
      padding: 0.16em 0.38em;
      border-radius: 6px;
      background: var(--code-bg);
      font-size: 0.86em;
      transition: background-color 180ms ease, color 180ms ease;
    }

    pre {
      margin: 0.95rem 0;
      padding: 14px 16px;
      border-radius: 14px;
      background: var(--code-bg);
      overflow-x: auto;
      border: 1px solid var(--border);
      transition: background-color 180ms ease, border-color 180ms ease, color 180ms ease;
    }

    pre code {
      padding: 0;
      background: transparent;
      font-size: 0.88em;
    }

    img, video {
      display: block;
      max-width: 100%;
      height: auto;
      margin: 1rem 0;
      border-radius: 14px;
      box-shadow: var(--image-shadow);
      transition: box-shadow 180ms ease, opacity 180ms ease;
    }

    video {
      background: #000;
    }

    .mermaid {
      overflow-x: auto;
      margin: 1rem 0;
      padding: 16px;
      border-radius: 16px;
      border: 1px solid var(--border);
      background: color-mix(in srgb, var(--surface) 92%, transparent);
      transition: background-color 180ms ease, border-color 180ms ease, color 180ms ease, box-shadow 180ms ease;
    }

    .footnotes {
      margin-top: 2rem;
      padding-top: 1rem;
      border-top: 1px solid var(--border);
      color: var(--muted);
      font-size: 0.86rem;
    }

    .footnotes p {
      margin: 0.35rem 0;
    }

    details {
      margin: 1rem 0;
      border: 1px solid var(--border);
      border-radius: 12px;
      background: color-mix(in srgb, var(--surface) 96%, transparent);
      overflow: hidden;
      transition: background-color 180ms ease, border-color 180ms ease, color 180ms ease;
    }

    details > summary {
      cursor: pointer;
      font-family: var(--font-ui);
      font-weight: 700;
      padding: 12px 14px;
      background: color-mix(in srgb, var(--accent-soft) 30%, transparent);
      transition: background-color 180ms ease, color 180ms ease;
    }

    details > :not(summary) {
      padding: 0 14px 14px;
    }

    .inline-editor {
      display: grid;
      gap: 10px;
      width: 60%;
      max-width: 60%;
      justify-items: start;
    }

    .inline-editor-meta {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      font-family: var(--font-ui);
      font-size: 0.76rem;
      color: var(--muted);
    }

    .inline-editor textarea {
      width: 100%;
      min-height: 0;
      resize: vertical;
      padding: 14px 16px;
      border-radius: 14px;
      border: 1px solid var(--editor-border);
      background: var(--editor-bg);
      color: var(--text);
      line-height: 1.56;
      font-size: 0.88rem;
      box-shadow: inset 0 1px 2px rgba(15, 23, 42, 0.08);
      transition: background-color 180ms ease, border-color 180ms ease, color 180ms ease, box-shadow 180ms ease;
    }

    .inline-editor textarea:focus {
      outline: 2px solid color-mix(in srgb, var(--accent) 38%, transparent);
      outline-offset: 0;
    }

    .inline-editor-actions {
      display: flex;
      justify-content: flex-end;
      gap: 10px;
    }

    .inline-editor-actions button {
      appearance: none;
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 9px 14px;
      background: var(--surface);
      color: var(--text);
      font-family: var(--font-ui);
      font-size: 0.8rem;
      font-weight: 700;
      cursor: pointer;
      transition: background-color 180ms ease, border-color 180ms ease, color 180ms ease, box-shadow 180ms ease;
    }

    .inline-editor-actions button.primary {
      border-color: color-mix(in srgb, var(--accent) 38%, var(--border));
      background: color-mix(in srgb, var(--accent-soft) 52%, var(--surface));
      color: var(--accent);
    }

    .fallback pre {
      white-space: pre-wrap;
      word-break: break-word;
    }
    """#

    private static let applicationScript = #"""
    (() => {
      try {
      const payloadNode = document.getElementById("fastmd-payload");
      const payload = payloadNode ? JSON.parse(payloadNode.textContent || "{}") : {};
      const root = document.getElementById("render-root");
      const titleNode = document.getElementById("doc-title");
      const widthLabel = document.getElementById("width-label");
      const statusBanner = document.getElementById("status-banner");
      const bridge = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.previewBridge
        ? window.webkit.messageHandlers.previewBridge
        : null;

      const state = {
        title: payload.title || "Preview",
        source: payload.markdown || "",
        widthTiers: Array.isArray(payload.widthTiers) ? payload.widthTiers : [560, 960, 1440, 1920],
        selectedWidthTierIndex: Number.isFinite(payload.selectedWidthTierIndex) ? payload.selectedWidthTierIndex : 0,
        backgroundMode: payload.backgroundMode === "black" ? "black" : "white",
        contentBaseURL: payload.contentBaseURL || null,
        filePath: payload.filePath || "",
        cacheToken: payload.cacheToken || "",
        pagingActive: false,
        scrollActive: false,
        editing: false,
        saving: false,
        pendingMarkdown: null,
        currentEdit: null,
        renderGeneration: 0,
      };
      const scrollAnimation = { rafId: 0 };
      const queuedScroll = { rafId: 0, pendingDelta: 0 };
      const interactionPerf = { page: null, width: null };
      const renderCache = new Map();
      let cachePersistTimer = 0;
      let codeHighlightObserver = null;
      const lazyHighlightContext = { profile: null, renderGeneration: 0, cacheKey: "" };
      const RENDER_CACHE_ENTRY_LIMIT = 12;
      const RENDER_CACHE_TOTAL_BYTE_LIMIT = 6 * 1024 * 1024;
      const PERF_LIMITS = {
        deferredBytes: 120 * 1024,
        deferredLines: 2000,
        deferredFences: 24,
        fastBytes: 300 * 1024,
        fastLines: 5000,
        fastFences: 80,
      };

      titleNode.textContent = state.title;

      function post(message) {
        if (bridge) {
          bridge.postMessage(message);
        }
      }

      function setStatus(message, options = {}) {
        if (!message) {
          statusBanner.hidden = true;
          statusBanner.replaceChildren();
          return;
        }

        statusBanner.hidden = false;
        statusBanner.replaceChildren();

        const textNode = document.createElement("span");
        textNode.textContent = message;
        statusBanner.append(textNode);

        if (typeof options.actionLabel === "string" && typeof options.onAction === "function") {
          const actionButton = document.createElement("button");
          actionButton.type = "button";
          actionButton.className = "status-action";
          actionButton.textContent = options.actionLabel;
          actionButton.addEventListener("click", options.onAction);
          statusBanner.append(actionButton);
        }
      }

      function escapeHtml(value) {
        return String(value)
          .replaceAll("&", "&amp;")
          .replaceAll("<", "&lt;")
          .replaceAll(">", "&gt;")
          .replaceAll("\"", "&quot;");
      }

      function syncContentBase(contentBaseURL) {
        const selector = 'base[data-fastmd-content-base="true"]';
        const existing = document.head.querySelector(selector);

        if (!contentBaseURL) {
          if (existing) {
            existing.remove();
          }
          return;
        }

        let base = existing;
        if (!(base instanceof HTMLBaseElement)) {
          base = document.createElement("base");
          base.setAttribute("data-fastmd-content-base", "true");
          document.head.prepend(base);
        }

        base.href = contentBaseURL;
      }

      function sourceLines(source) {
        return String(source).split("\n");
      }

      function syncWidthChrome() {
        const clampedIndex = Math.max(0, Math.min(state.selectedWidthTierIndex, state.widthTiers.length - 1));
        state.selectedWidthTierIndex = clampedIndex;
        const width = state.widthTiers[clampedIndex] || 0;
        const label = `← ${clampedIndex + 1}/${state.widthTiers.length} →`;
        widthLabel.textContent = label;
        widthLabel.title = `${clampedIndex + 1}/${state.widthTiers.length} · ${width}px`;
        widthLabel.setAttribute("aria-label", `宽度档位 ${clampedIndex + 1}/${state.widthTiers.length}，目标宽度 ${width}px`);
      }

      function syncPerformanceCriticalChrome() {
        const shell = document.querySelector(".shell");
        if (!shell) {
          return;
        }

        shell.classList.toggle(
          "is-performance-critical",
          state.pagingActive ||
            state.scrollActive ||
            Boolean(interactionPerf.page) ||
            Boolean(interactionPerf.width),
        );
      }

      function pulseWidthTransition() {
        const shell = document.querySelector(".shell");
        if (!shell) {
          return;
        }

        shell.classList.remove("is-width-transition");
        requestAnimationFrame(() => {
          shell.classList.add("is-width-transition");
          window.setTimeout(() => {
            shell.classList.remove("is-width-transition");
          }, 380);
        });
      }

      function applyBackgroundMode() {
        document.body.dataset.backgroundMode = state.backgroundMode === "black" ? "black" : "white";
      }

      function postPerfMetric(stage, detail) {
        post({
          type: "perfMetric",
          stage,
          detail,
        });
      }

      function currentScrollTop() {
        return window.scrollY || document.documentElement.scrollTop || 0;
      }

      function maxScrollTop() {
        return Math.max(document.documentElement.scrollHeight - window.innerHeight, 0);
      }

      function setScrollTop(value) {
        window.scrollTo({ top: value, behavior: "auto" });
      }

      function cancelQueuedScroll() {
        if (queuedScroll.rafId) {
          window.cancelAnimationFrame(queuedScroll.rafId);
          queuedScroll.rafId = 0;
        }
        queuedScroll.pendingDelta = 0;
      }

      function clearTimer(timerID) {
        if (timerID) {
          window.clearTimeout(timerID);
        }
      }

      function finalizeWidthTransitionProbe(reason) {
        const probe = interactionPerf.width;
        if (!probe) {
          return;
        }

        clearTimer(probe.settleTimer);
        clearTimer(probe.fallbackTimer);
        interactionPerf.width = null;
        postPerfMetric(
          "widthTransition",
          `id=${probe.requestId} targetIndex=${probe.targetIndex} durationMs=${(performance.now() - probe.startedAt).toFixed(1)} firstResizeDelayMs=${probe.firstResizeDelayMs === null ? "none" : probe.firstResizeDelayMs.toFixed(1)} resizeEvents=${probe.resizeEvents} viewport=${window.innerWidth}x${window.innerHeight} reason=${reason}`,
        );
        syncPerformanceCriticalChrome();
      }

      function scheduleWidthTransitionSettle() {
        const probe = interactionPerf.width;
        if (!probe) {
          return;
        }

        clearTimer(probe.settleTimer);
        probe.settleTimer = window.setTimeout(() => {
          finalizeWidthTransitionProbe("settled");
        }, 110);
      }

      function beginWidthTransitionProbe(requestId, targetIndex) {
        if (interactionPerf.width) {
          finalizeWidthTransitionProbe("interrupted");
        }

        interactionPerf.width = {
          requestId: Number.isFinite(requestId) ? requestId : 0,
          targetIndex: Number.isFinite(targetIndex) ? targetIndex : state.selectedWidthTierIndex,
          startedAt: performance.now(),
          firstResizeDelayMs: null,
          resizeEvents: 0,
          settleTimer: 0,
          fallbackTimer: window.setTimeout(() => {
            finalizeWidthTransitionProbe("timeout");
          }, 1000),
        };
        syncPerformanceCriticalChrome();
      }

      function noteWidthResize() {
        const probe = interactionPerf.width;
        if (!probe) {
          return;
        }

        probe.resizeEvents += 1;
        if (probe.firstResizeDelayMs === null) {
          probe.firstResizeDelayMs = performance.now() - probe.startedAt;
        }
        scheduleWidthTransitionSettle();
      }

      function finalizePageTransitionProbe(reason) {
        const probe = interactionPerf.page;
        if (!probe) {
          return;
        }

        clearTimer(probe.settleTimer);
        clearTimer(probe.fallbackTimer);
        interactionPerf.page = null;
        postPerfMetric(
          "pageTransition",
          `id=${probe.requestId} pages=${probe.pages} durationMs=${(performance.now() - probe.startedAt).toFixed(1)} firstScrollDelayMs=${probe.firstScrollDelayMs === null ? "none" : probe.firstScrollDelayMs.toFixed(1)} scrollEvents=${probe.scrollEvents} deltaY=${(currentScrollTop() - probe.startScrollTop).toFixed(1)} viewportH=${window.innerHeight} reason=${reason}`,
        );
        syncPerformanceCriticalChrome();
      }

      function schedulePageTransitionSettle() {
        const probe = interactionPerf.page;
        if (!probe) {
          return;
        }

        clearTimer(probe.settleTimer);
        probe.settleTimer = window.setTimeout(() => {
          finalizePageTransitionProbe("settled");
        }, 90);
      }

      function beginPageTransitionProbe(requestId, pages) {
        if (interactionPerf.page) {
          finalizePageTransitionProbe("interrupted");
        }

        interactionPerf.page = {
          requestId: Number.isFinite(requestId) ? requestId : 0,
          pages: Number.isFinite(pages) ? pages : 0,
          startedAt: performance.now(),
          startScrollTop: currentScrollTop(),
          firstScrollDelayMs: null,
          scrollEvents: 0,
          settleTimer: 0,
          fallbackTimer: window.setTimeout(() => {
            finalizePageTransitionProbe("timeout");
          }, 1000),
        };
        syncPerformanceCriticalChrome();
      }

      function notePageScroll() {
        const probe = interactionPerf.page;
        if (!probe) {
          return;
        }

        probe.scrollEvents += 1;
        if (probe.firstScrollDelayMs === null) {
          probe.firstScrollDelayMs = performance.now() - probe.startedAt;
        }
        schedulePageTransitionSettle();
      }

      function cancelScrollAnimation() {
        if (scrollAnimation.rafId) {
          window.cancelAnimationFrame(scrollAnimation.rafId);
          scrollAnimation.rafId = 0;
        }
      }

      function clamp(value, min, max) {
        return Math.min(max, Math.max(min, value));
      }

      function easeOutQuint(t) {
        return 1 - Math.pow(1 - t, 5);
      }

      function easeOutCubic(t) {
        return 1 - Math.pow(1 - t, 3);
      }

      function animateScrollSegment(from, to, duration, easing, onDone) {
        const startTime = performance.now();

        function frame(now) {
          const progress = clamp((now - startTime) / duration, 0, 1);
          const value = from + (to - from) * easing(progress);
          setScrollTop(value);

          if (progress < 1) {
            scrollAnimation.rafId = window.requestAnimationFrame(frame);
            return;
          }

          scrollAnimation.rafId = 0;
          onDone();
        }

        scrollAnimation.rafId = window.requestAnimationFrame(frame);
      }

      function scrollByDelta(delta) {
        cancelScrollAnimation();
        queuedScroll.pendingDelta += delta;
        if (queuedScroll.rafId) {
          return;
        }

        queuedScroll.rafId = window.requestAnimationFrame(() => {
          queuedScroll.rafId = 0;
          const totalDelta = queuedScroll.pendingDelta;
          queuedScroll.pendingDelta = 0;
          setScrollTop(clamp(currentScrollTop() + totalDelta, 0, maxScrollTop()));
        });
      }

      function pageBy(pages, requestId) {
        if (!Number.isFinite(pages) || pages === 0) {
          return;
        }

        beginPageTransitionProbe(requestId, pages);
        cancelScrollAnimation();
        cancelQueuedScroll();

        const start = currentScrollTop();
        const delta = window.innerHeight * 0.92 * pages;
        const target = clamp(start + delta, 0, maxScrollTop());
        const distance = target - start;

        if (Math.abs(distance) < 1) {
          finalizePageTransitionProbe("no-op");
          return;
        }
        animateScrollSegment(start, target, 140, easeOutCubic, () => {
          setScrollTop(target);
        });
      }

      function normalizeFenceLanguage(info) {
        return String(info || "").trim().split(/\s+/)[0].toLowerCase();
      }

      function renderCodeFenceBlock(source, info) {
        const language = normalizeFenceLanguage(info);
        if (language === "mermaid") {
          return `<div class="mermaid">${escapeHtml(source)}</div>`;
        }

        const escapedSource = escapeHtml(source);
        const languageClass = language ? ` language-${language}` : "";
        const dataLanguage = language || "plaintext";
        return `<pre><code class="${languageClass}" data-fastmd-code="true" data-fastmd-language="${escapeHtml(dataLanguage)}">${escapedSource}</code></pre>`;
      }

      function createMarkdownIt() {
        if (typeof window.markdownit !== "function") {
          return null;
        }

        const md = window.markdownit({
          html: true,
          linkify: true,
          typographer: true,
        });

        if (typeof window.markdownitFootnote === "function") {
          md.use(window.markdownitFootnote);
        }

        if (typeof window.markdownitTaskLists === "function") {
          md.use(window.markdownitTaskLists, { enabled: true, label: true, labelAfter: true });
        }

        const defaultFenceRule = md.renderer.rules.fence ? md.renderer.rules.fence.bind(md.renderer) : null;
        const defaultCodeBlockRule = md.renderer.rules.code_block ? md.renderer.rules.code_block.bind(md.renderer) : null;
        const defaultHTMLBlockRule = md.renderer.rules.html_block ? md.renderer.rules.html_block.bind(md.renderer) : null;
        const defaultHRRule = md.renderer.rules.hr ? md.renderer.rules.hr.bind(md.renderer) : null;

        annotateTopLevelBlocks(md);
        wrapSelfClosingBlocks(md, "fence", (tokens, idx, options, env, self) => {
          const token = tokens[idx];
          if (defaultFenceRule) {
            const fallbackHTML = defaultFenceRule(tokens, idx, options, env, self);
            if (normalizeFenceLanguage(token.info) === "mermaid") {
              return renderCodeFenceBlock(token.content, token.info);
            }
            if (!fallbackHTML.includes("data-fastmd-code=")) {
              return renderCodeFenceBlock(token.content, token.info);
            }
            return fallbackHTML;
          }

          return renderCodeFenceBlock(token.content, token.info);
        });
        wrapSelfClosingBlocks(md, "code_block", (tokens, idx, options, env, self) => {
          const token = tokens[idx];
          if (defaultCodeBlockRule) {
            const fallbackHTML = defaultCodeBlockRule(tokens, idx, options, env, self);
            if (!fallbackHTML.includes("data-fastmd-code=")) {
              return renderCodeFenceBlock(token.content, "");
            }
            return fallbackHTML;
          }

          return renderCodeFenceBlock(token.content, "");
        });
        wrapSelfClosingBlocks(md, "html_block", (tokens, idx, options, env, self) => {
          if (defaultHTMLBlockRule) {
            return defaultHTMLBlockRule(tokens, idx, options, env, self);
          }

          return tokens[idx].content;
        });
        wrapSelfClosingBlocks(md, "hr", (tokens, idx, options, env, self) => {
          if (defaultHRRule) {
            return defaultHRRule(tokens, idx, options, env, self);
          }

          return "<hr>";
        });

        return md;
      }

      function annotateTopLevelBlocks(md) {
        const defaultRenderToken = md.renderer.renderToken.bind(md.renderer);
        const openTypes = new Set([
          "heading_open",
          "paragraph_open",
          "blockquote_open",
          "bullet_list_open",
          "ordered_list_open",
          "table_open",
        ]);

        md.renderer.renderToken = function(tokens, idx, options) {
          const token = tokens[idx];
          const blockMeta = token.meta && token.meta.fastmdBlock;
          let html = defaultRenderToken(tokens, idx, options);

          if (token.level === 0 && token.nesting === 1 && blockMeta && openTypes.has(token.type)) {
            const attrs = [
              `class="md-block"`,
              `data-block-id="${blockMeta.blockId}"`,
              `data-start-line="${blockMeta.startLine}"`,
              `data-end-line="${blockMeta.endLine}"`,
            ].join(" ");
            return `<section ${attrs}>${html}`;
          }

          if (token.level === 0 && token.nesting === -1 && blockMeta && openTypes.has(token.type.replace("_close", "_open"))) {
            return `${html}</section>`;
          }

          return html;
        };
      }

      function wrapSelfClosingBlocks(md, ruleName, renderer) {
        md.renderer.rules[ruleName] = function(tokens, idx, options, env, self) {
          const token = tokens[idx];
          const blockMeta = token.meta && token.meta.fastmdBlock;
          const innerHtml = renderer(tokens, idx, options, env, self);
          if (!blockMeta) {
            return innerHtml;
          }

          return `<section class="md-block" data-block-id="${blockMeta.blockId}" data-start-line="${blockMeta.startLine}" data-end-line="${blockMeta.endLine}">${innerHtml}</section>`;
        };
      }

      function assignBlockMetadata(tokens) {
        const stack = [];
        let nextBlockId = 0;

        for (const token of tokens) {
          token.meta = token.meta || {};

          if (token.level === 0 && token.block && token.nesting === 1 && Array.isArray(token.map)) {
            const blockMeta = {
              blockId: nextBlockId++,
              startLine: token.map[0],
              endLine: token.map[1],
            };
            token.meta.fastmdBlock = blockMeta;
            stack.push(blockMeta);
            continue;
          }

          if (token.level === 0 && token.block && token.nesting === -1 && stack.length > 0) {
            token.meta.fastmdBlock = stack.pop();
            continue;
          }

          if (token.level === 0 && token.block && token.nesting === 0 && Array.isArray(token.map)) {
            token.meta.fastmdBlock = {
              blockId: nextBlockId++,
              startLine: token.map[0],
              endLine: token.map[1],
            };
          }
        }
      }

      const md = createMarkdownIt();

      function renderFallback(cacheKey, profile) {
        disconnectCodeHighlightObserver();
        root.innerHTML = `<div class="fallback md-block"><pre>${escapeHtml(state.source)}</pre></div>`;
        scheduleCachePersist(cacheKey, profile, false);
      }

      function sourceLikelyHasMath(source) {
        return /(?:\$\$|\\\(|\\\[|(^|[^\$])\$[^\$\n]+?\$)/m.test(source);
      }

      function sourceLikelyHasMermaid(source) {
        return /```[\t ]*mermaid\b/i.test(source);
      }

      function countMatches(pattern, value) {
        const matches = String(value).match(pattern);
        return matches ? matches.length : 0;
      }

      function analyzePerformanceProfile(source) {
        const normalizedSource = String(source || "");
        const byteLength = typeof TextEncoder === "function"
          ? new TextEncoder().encode(normalizedSource).length
          : normalizedSource.length;
        const lineCount = sourceLines(normalizedSource).length;
        const codeFenceCount = countMatches(/^```/gm, normalizedSource);
        const hasMath = sourceLikelyHasMath(normalizedSource);
        const hasMermaid = sourceLikelyHasMermaid(normalizedSource);

        let mode = "normal";
        if (
          byteLength >= PERF_LIMITS.fastBytes ||
          lineCount >= PERF_LIMITS.fastLines ||
          codeFenceCount >= PERF_LIMITS.fastFences
        ) {
          mode = "fast";
        } else if (
          byteLength >= PERF_LIMITS.deferredBytes ||
          lineCount >= PERF_LIMITS.deferredLines ||
          codeFenceCount >= PERF_LIMITS.deferredFences
        ) {
          mode = "deferred";
        }

        return {
          mode,
          byteLength,
          lineCount,
          codeFenceCount,
          hasMath,
          hasMermaid,
          shouldPromptHeavyEnhance: mode === "fast" && (hasMath || hasMermaid),
          eagerHighlightBudget: mode === "normal" ? 6 : mode === "deferred" ? 3 : 1,
        };
      }

      function currentRenderCacheKey() {
        if (!state.cacheToken) {
          return "";
        }

        return `${state.cacheToken}|background=${state.backgroundMode}`;
      }

      function disconnectCodeHighlightObserver() {
        if (codeHighlightObserver) {
          codeHighlightObserver.disconnect();
          codeHighlightObserver = null;
        }
      }

      function scheduleCachePersist(cacheKey, profile, enhanced) {
        if (!cacheKey) {
          return;
        }

        if (cachePersistTimer) {
          window.clearTimeout(cachePersistTimer);
        }

        cachePersistTimer = window.setTimeout(() => {
          if (renderCache.has(cacheKey)) {
            renderCache.delete(cacheKey);
          }

          renderCache.set(cacheKey, {
            html: root.innerHTML,
            profile,
            enhanced,
          });

          while (
            renderCache.size > RENDER_CACHE_ENTRY_LIMIT ||
            totalRenderCacheBytes() > RENDER_CACHE_TOTAL_BYTE_LIMIT
          ) {
            const oldestKey = renderCache.keys().next().value;
            renderCache.delete(oldestKey);
          }
        }, 60);
      }

      function totalRenderCacheBytes() {
        let total = 0;
        for (const entry of renderCache.values()) {
          const htmlLength = typeof entry.html === "string" ? entry.html.length : 0;
          total += htmlLength * 2;
        }
        return total;
      }

      function scheduleAfterPaint(task) {
        const runner = () => {
          if (typeof window.requestIdleCallback === "function") {
            window.requestIdleCallback(() => task(), { timeout: 120 });
            return;
          }

          window.setTimeout(task, 0);
        };

        window.requestAnimationFrame(runner);
      }

      function highlightCodeElement(codeNode) {
        if (!(codeNode instanceof HTMLElement)) {
          return false;
        }

        if (codeNode.dataset.fastmdHighlighted === "true") {
          return false;
        }

        const language = String(codeNode.dataset.fastmdLanguage || "").toLowerCase();
        if (!window.hljs || !language || language === "plaintext" || !window.hljs.getLanguage(language)) {
          codeNode.dataset.fastmdHighlighted = "true";
          return false;
        }

        try {
          window.hljs.highlightElement(codeNode);
        } catch (_) {
          codeNode.dataset.fastmdHighlighted = "true";
          return false;
        }

        codeNode.dataset.fastmdHighlighted = "true";
        return true;
      }

      function setupLazyCodeHighlighting(profile, renderGeneration, cacheKey) {
        if (state.scrollActive) {
          disconnectCodeHighlightObserver();
          return;
        }
        lazyHighlightContext.profile = profile;
        lazyHighlightContext.renderGeneration = renderGeneration;
        lazyHighlightContext.cacheKey = cacheKey;
        disconnectCodeHighlightObserver();

        const codeNodes = Array.from(root.querySelectorAll("pre code[data-fastmd-code='true']"));
        if (codeNodes.length === 0) {
          return;
        }

        const highlightStartedAt = performance.now();
        let highlightedCount = 0;
        let eagerCount = 0;
        const eagerViewport = window.innerHeight * 1.6;

        for (const codeNode of codeNodes) {
          if (!(codeNode instanceof HTMLElement)) {
            continue;
          }

          if (eagerCount >= profile.eagerHighlightBudget) {
            break;
          }

          if (codeNode.getBoundingClientRect().top <= eagerViewport) {
            if (highlightCodeElement(codeNode)) {
              highlightedCount += 1;
            }
            eagerCount += 1;
          }
        }

        scheduleCachePersist(cacheKey, profile, false);

        const pendingNodes = codeNodes.filter((codeNode) =>
          codeNode instanceof HTMLElement && codeNode.dataset.fastmdHighlighted !== "true"
        );

        if (pendingNodes.length === 0) {
          postPerfMetric(
            "codeHighlight",
            `highlighted=${highlightedCount} total=${codeNodes.length} mode=${profile.mode} elapsedMs=${(performance.now() - highlightStartedAt).toFixed(1)}`,
          );
          return;
        }

        if (typeof window.IntersectionObserver !== "function") {
          for (const codeNode of pendingNodes) {
            if (highlightCodeElement(codeNode)) {
              highlightedCount += 1;
            }
          }
          scheduleCachePersist(cacheKey, profile, false);
          postPerfMetric(
            "codeHighlight",
            `highlighted=${highlightedCount} total=${codeNodes.length} mode=${profile.mode} elapsedMs=${(performance.now() - highlightStartedAt).toFixed(1)}`,
          );
          return;
        }

        const pendingSet = new Set(pendingNodes);
        codeHighlightObserver = new IntersectionObserver((entries) => {
          if (renderGeneration !== state.renderGeneration) {
            disconnectCodeHighlightObserver();
            return;
          }

          if (state.pagingActive || state.scrollActive) {
            return;
          }

          let mutated = false;
          for (const entry of entries) {
            if (!entry.isIntersecting) {
              continue;
            }

            const codeNode = entry.target;
            codeHighlightObserver?.unobserve(codeNode);
            pendingSet.delete(codeNode);
            if (highlightCodeElement(codeNode)) {
              highlightedCount += 1;
            }
            mutated = true;
          }

          if (mutated) {
            scheduleCachePersist(cacheKey, profile, false);
          }

          if (pendingSet.size === 0) {
            disconnectCodeHighlightObserver();
            postPerfMetric(
              "codeHighlight",
              `highlighted=${highlightedCount} total=${codeNodes.length} mode=${profile.mode} elapsedMs=${(performance.now() - highlightStartedAt).toFixed(1)}`,
            );
          }
        }, {
          root: null,
          rootMargin: profile.mode === "fast" ? "180px 0px" : "520px 0px",
        });

        for (const codeNode of pendingNodes) {
          codeHighlightObserver.observe(codeNode);
        }
      }

      function renderMath(renderGeneration) {
        if (renderGeneration !== state.renderGeneration) {
          return;
        }
        if (typeof window.renderMathInElement !== "function") {
          return;
        }

        window.renderMathInElement(root, {
          delimiters: [
            { left: "$$", right: "$$", display: true },
            { left: "\\[", right: "\\]", display: true },
            { left: "$", right: "$", display: false },
            { left: "\\(", right: "\\)", display: false },
          ],
          throwOnError: false,
          ignoredTags: ["script", "noscript", "style", "textarea", "pre", "code"],
        });
      }

      async function renderMermaid(renderGeneration) {
        if (renderGeneration !== state.renderGeneration) {
          return;
        }
        if (!root.querySelector(".mermaid")) {
          return;
        }
        if (!window.mermaid || typeof window.mermaid.initialize !== "function") {
          return;
        }

        window.mermaid.initialize({
          startOnLoad: false,
          securityLevel: "loose",
          theme: state.backgroundMode === "black" ? "dark" : "default",
        });

        if (typeof window.mermaid.run === "function") {
          await window.mermaid.run({ querySelector: ".mermaid" }).catch(() => {});
        }
      }

      async function runHeavyEnhancements(profile, renderGeneration, cacheKey, manual) {
        if (renderGeneration !== state.renderGeneration) {
          return;
        }
        if (state.scrollActive) {
          return;
        }

        const enhanceStartedAt = performance.now();

        if (profile.hasMath) {
          renderMath(renderGeneration);
        }
        if (profile.hasMermaid) {
          await renderMermaid(renderGeneration);
        }

        if (renderGeneration !== state.renderGeneration) {
          return;
        }

        if (!state.editing && !state.saving) {
          setStatus("");
        }
        scheduleCachePersist(cacheKey, profile, true);
        postPerfMetric(
          "renderEnhance",
          `enhanceMs=${(performance.now() - enhanceStartedAt).toFixed(1)} math=${profile.hasMath} mermaid=${profile.hasMermaid} manual=${manual} mode=${profile.mode}`,
        );
      }

      function scheduleFeaturePipeline(profile, renderGeneration, cacheKey, options = {}) {
        setupLazyCodeHighlighting(profile, renderGeneration, cacheKey);

        if (options.enhanced) {
          if (!state.editing && !state.saving) {
            setStatus("");
          }
          return;
        }

        if (profile.shouldPromptHeavyEnhance) {
          if (!state.editing && !state.saving) {
            setStatus(
              "Fast mode is active for this large Markdown file. Math and Mermaid are paused until requested.",
              {
                actionLabel: "Enhance Now",
                onAction: () => {
                  setStatus("Enhancing preview…");
                  scheduleAfterPaint(() => {
                    if (!state.scrollActive) {
                      void runHeavyEnhancements(profile, renderGeneration, cacheKey, true);
                    }
                  });
                },
              },
            );
          }
          return;
        }

        if (!profile.hasMath && !profile.hasMermaid) {
          if (!state.editing && !state.saving) {
            setStatus("");
          }
          return;
        }

        if (state.scrollActive) {
          return;
        }

        scheduleAfterPaint(() => {
          if (!state.scrollActive) {
            void runHeavyEnhancements(profile, renderGeneration, cacheKey, false);
          }
        });
      }

      function renderDocument() {
        const renderStartedAt = performance.now();
        const renderGeneration = state.renderGeneration + 1;
        state.renderGeneration = renderGeneration;
        const profile = analyzePerformanceProfile(state.source);
        const cacheKey = currentRenderCacheKey();

        disconnectCodeHighlightObserver();
        applyBackgroundMode();
        syncContentBase(state.contentBaseURL);
        syncWidthChrome();
        titleNode.textContent = state.title;
        setStatus(state.editing ? "Edit mode is locked until you save or cancel." : "");

        if (!md) {
          renderFallback(cacheKey, profile);
          postPerfMetric(
            "renderFallback",
            `syncMs=${(performance.now() - renderStartedAt).toFixed(1)} mode=${profile.mode} bytes=${profile.byteLength} lines=${profile.lineCount}`,
          );
          return;
        }

        const cached = cacheKey ? renderCache.get(cacheKey) : null;
        if (cached && typeof cached.html === "string") {
          renderCache.delete(cacheKey);
          renderCache.set(cacheKey, cached);
          root.innerHTML = cached.html;
          postPerfMetric(
            "renderCacheHit",
            `mode=${profile.mode} enhanced=${cached.enhanced ? "true" : "false"} bytes=${profile.byteLength} lines=${profile.lineCount} fences=${profile.codeFenceCount}`,
          );
          scheduleFeaturePipeline(cached.profile || profile, renderGeneration, cacheKey, {
            enhanced: Boolean(cached.enhanced),
          });
          return;
        }

        const env = {};
        const parseStartedAt = performance.now();
        const tokens = md.parse(state.source, env);
        const parsedAt = performance.now();
        assignBlockMetadata(tokens);
        root.innerHTML = md.renderer.render(tokens, md.options, env);
        const domReadyAt = performance.now();
        scheduleCachePersist(cacheKey, profile, false);

        postPerfMetric(
          "renderSync",
          `parseMs=${(parsedAt - parseStartedAt).toFixed(1)} domMs=${(domReadyAt - parsedAt).toFixed(1)} totalMs=${(domReadyAt - renderStartedAt).toFixed(1)} mode=${profile.mode} bytes=${profile.byteLength} lines=${profile.lineCount} fences=${profile.codeFenceCount} math=${profile.hasMath} mermaid=${profile.hasMermaid}`,
        );
        scheduleFeaturePipeline(profile, renderGeneration, cacheKey, {
          enhanced: false,
        });
      }

      function blockSource(startLine, endLine) {
        const lines = sourceLines(state.source);
        return lines.slice(startLine, endLine).join("\n");
      }

      function enterEdit(blockNode) {
        if (state.editing || state.saving) {
          return;
        }

        const startLine = Number.parseInt(blockNode.dataset.startLine || "", 10);
        const endLine = Number.parseInt(blockNode.dataset.endLine || "", 10);
        if (!Number.isFinite(startLine) || !Number.isFinite(endLine) || endLine <= startLine) {
          return;
        }

        state.editing = true;
        state.currentEdit = { startLine, endLine };
        document.body.classList.add("is-editing");
        post({ type: "editingState", editing: true });
        syncWidthChrome();
        setStatus("Edit mode is locked until you save or cancel.");

        const blockHeight = Math.ceil(blockNode.getBoundingClientRect().height);
        const originalSource = blockSource(startLine, endLine);
        blockNode.classList.add("is-editing");
        blockNode.innerHTML = `
          <div class="inline-editor">
            <div class="inline-editor-meta">
              <span>Editing source lines ${startLine + 1}-${endLine}</span>
              <span>Double-clicked block returns to raw Markdown.</span>
            </div>
            <textarea id="inline-editor-textarea">${escapeHtml(originalSource)}</textarea>
            <div class="inline-editor-actions">
              <button type="button" id="inline-editor-cancel">Cancel</button>
              <button type="button" class="primary" id="inline-editor-save">Save</button>
            </div>
          </div>
        `;

        const textarea = blockNode.querySelector("#inline-editor-textarea");
        const saveButton = blockNode.querySelector("#inline-editor-save");
        const cancelButton = blockNode.querySelector("#inline-editor-cancel");

        cancelButton.addEventListener("click", cancelEdit);
        saveButton.addEventListener("click", saveEdit);
        textarea.addEventListener("keydown", (event) => {
          if (event.key === "Escape") {
            event.preventDefault();
            cancelEdit();
            return;
          }

          if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "s") {
            event.preventDefault();
            saveEdit();
          }
        });

        requestAnimationFrame(() => {
          textarea.style.height = `${Math.max(48, blockHeight)}px`;
          textarea.focus();
          textarea.selectionStart = textarea.value.length;
          textarea.selectionEnd = textarea.value.length;
        });
      }

      function cancelEdit() {
        if (!state.editing || state.saving) {
          return;
        }

        state.editing = false;
        state.currentEdit = null;
        state.pendingMarkdown = null;
        document.body.classList.remove("is-editing");
        post({ type: "editingState", editing: false });
        renderDocument();
      }

      function saveEdit() {
        if (!state.currentEdit || state.saving) {
          return;
        }

        const textarea = document.getElementById("inline-editor-textarea");
        if (!textarea) {
          return;
        }

        const replacementSource = textarea.value.replaceAll("\r\n", "\n");
        const lines = sourceLines(state.source);
        const replacementLines = replacementSource.split("\n");
        const { startLine, endLine } = state.currentEdit;
        const newLines = lines.slice(0, startLine)
          .concat(replacementLines)
          .concat(lines.slice(endLine));

        state.pendingMarkdown = newLines.join("\n");
        state.saving = true;
        syncWidthChrome();
        setStatus("Saving Markdown block back to disk…");
        post({ type: "saveMarkdown", markdown: state.pendingMarkdown });
      }

      function requestWidthDelta(delta) {
        if (state.editing || state.saving) {
          return;
        }
        post({ type: "adjustWidthTier", delta });
      }

      root.addEventListener("dblclick", (event) => {
        const blockNode = event.target.closest(".md-block");
        if (!blockNode || state.editing || state.saving) {
          return;
        }
        enterEdit(blockNode);
      });

      root.addEventListener("click", (event) => {
        const anchor = event.target.closest("a[href]");
        if (!anchor || state.editing || state.saving) {
          return;
        }
        if (event.defaultPrevented || event.button !== 0) {
          return;
        }
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
          return;
        }

        const rawHref = anchor.getAttribute("href") || "";
        if (!rawHref) {
          return;
        }

        if (rawHref.startsWith("#")) {
          event.preventDefault();
          const targetID = decodeURIComponent(rawHref.slice(1));
          const target = document.getElementById(targetID);
          if (target) {
            target.scrollIntoView({ behavior: "smooth", block: "start" });
          }
          return;
        }

        const resolvedURL = anchor.href;
        if (!resolvedURL) {
          return;
        }

        event.preventDefault();
        post({ type: "activateLink", url: resolvedURL });
      });

      window.addEventListener("keydown", (event) => {
        if (state.editing || state.saving) {
          return;
        }

        if (event.key === "ArrowLeft") {
          event.preventDefault();
          requestWidthDelta(-1);
          return;
        }

        if (event.key === "ArrowRight") {
          event.preventDefault();
          requestWidthDelta(1);
          return;
        }

        if (event.key === "Tab") {
          event.preventDefault();
          post({ type: "toggleBackgroundMode" });
          return;
        }

        if (event.key === "PageUp" || event.key === "PageDown") {
          event.preventDefault();
          return;
        }

        if (event.code === "Space") {
          event.preventDefault();
        }
      });

      window.addEventListener("resize", () => {
        noteWidthResize();
      });

      window.addEventListener("scroll", () => {
        notePageScroll();
      }, { passive: true });

      window.FastMD = {
        setPagingActive(active) {
          state.pagingActive = Boolean(active);
          syncPerformanceCriticalChrome();
          if (!state.pagingActive && lazyHighlightContext.profile && lazyHighlightContext.renderGeneration === state.renderGeneration) {
            scheduleAfterPaint(() => {
              if (lazyHighlightContext.profile && lazyHighlightContext.renderGeneration === state.renderGeneration) {
                setupLazyCodeHighlighting(
                  lazyHighlightContext.profile,
                  lazyHighlightContext.renderGeneration,
                  lazyHighlightContext.cacheKey,
                );
              }
            });
          }
        },
        setScrollActive(active) {
          state.scrollActive = Boolean(active);
          syncPerformanceCriticalChrome();
          if (!state.scrollActive && lazyHighlightContext.profile && lazyHighlightContext.renderGeneration === state.renderGeneration) {
            scheduleAfterPaint(() => {
              if (lazyHighlightContext.profile && lazyHighlightContext.renderGeneration === state.renderGeneration) {
                setupLazyCodeHighlighting(
                  lazyHighlightContext.profile,
                  lazyHighlightContext.renderGeneration,
                  lazyHighlightContext.cacheKey,
                );
                if (!lazyHighlightContext.profile.shouldPromptHeavyEnhance) {
                  void runHeavyEnhancements(
                    lazyHighlightContext.profile,
                    lazyHighlightContext.renderGeneration,
                    lazyHighlightContext.cacheKey,
                    false,
                  );
                }
              }
            });
          }
        },
        syncWidthTier(index) {
          state.selectedWidthTierIndex = Number(index) || 0;
          syncWidthChrome();
        },
        animateWidthTier(index, requestId) {
          state.selectedWidthTierIndex = Number(index) || 0;
          beginWidthTransitionProbe(Number(requestId), state.selectedWidthTierIndex);
          syncWidthChrome();
          pulseWidthTransition();
        },
        syncBackgroundMode(mode) {
          state.backgroundMode = mode === "black" ? "black" : "white";
          applyBackgroundMode();
          if (state.editing || state.saving || !state.cacheToken) {
            return;
          }
          if (sourceLikelyHasMermaid(state.source)) {
            renderDocument();
            return;
          }
          scheduleCachePersist(currentRenderCacheKey(), analyzePerformanceProfile(state.source), false);
        },
        updateDocument(nextPayload) {
          state.title = typeof nextPayload?.title === "string" && nextPayload.title
            ? nextPayload.title
            : "Preview";
          state.source = typeof nextPayload?.markdown === "string" ? nextPayload.markdown : "";
          state.selectedWidthTierIndex = Number.isFinite(nextPayload?.selectedWidthTierIndex)
            ? Number(nextPayload.selectedWidthTierIndex)
            : state.selectedWidthTierIndex;
          state.backgroundMode = nextPayload?.backgroundMode === "black" ? "black" : "white";
          state.contentBaseURL = typeof nextPayload?.contentBaseURL === "string"
            ? nextPayload.contentBaseURL
            : null;
          state.filePath = typeof nextPayload?.filePath === "string" ? nextPayload.filePath : "";
          state.cacheToken = typeof nextPayload?.cacheToken === "string" ? nextPayload.cacheToken : "";
          titleNode.textContent = state.title;
          renderDocument();
        },
        scrollBy(delta) {
          scrollByDelta(Number(delta) || 0);
        },
        pageBy(pages, requestId) {
          pageBy(Number(pages) || 0, Number(requestId));
        },
        didFinishSave(success, message) {
          state.saving = false;
          syncWidthChrome();

          if (success) {
            state.source = state.pendingMarkdown ?? state.source;
            state.pendingMarkdown = null;
            state.editing = false;
            state.currentEdit = null;
            document.body.classList.remove("is-editing");
            post({ type: "editingState", editing: false });
            setStatus("");
            renderDocument();
            return;
          }

          setStatus(message || "Save failed.");
        },
      };

      renderDocument();
      } catch (error) {
        const root = document.getElementById("render-root");
        const statusBanner = document.getElementById("status-banner");
        if (statusBanner) {
          statusBanner.hidden = false;
          statusBanner.textContent = `Enhanced preview failed, showing fallback content. ${error && error.message ? error.message : error}`;
        }

        const bridge = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.previewBridge
          ? window.webkit.messageHandlers.previewBridge
          : null;
        if (bridge) {
          bridge.postMessage({
            type: "clientError",
            message: error && error.message ? error.message : String(error),
          });
        }

        if (root && !root.innerHTML.trim()) {
          root.innerHTML = "<p>Preview fallback is empty.</p>";
        }
      }
    })();
    """#

    private static func fallbackHTMLBody(from markdown: String) -> String {
        let escaped = escapeHTML(markdown)
        return lineBasedRender(escaped)
    }

    private static func lineBasedRender(_ markdown: String) -> String {
        var output: [String] = []
        var inCodeBlock = false
        var codeLines: [String] = []
        var listLines: [String] = []

        func flushList() {
            guard !listLines.isEmpty else { return }
            output.append("<ul>")
            for item in listLines {
                output.append("<li>\(applyInlineMarkup(item))</li>")
            }
            output.append("</ul>")
            listLines.removeAll()
        }

        func flushCode() {
            guard !codeLines.isEmpty else { return }
            let joined = codeLines.joined(separator: "\n")
            output.append("<pre><code>\(joined)</code></pre>")
            codeLines.removeAll()
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if rawLine.hasPrefix("```") {
                flushList()
                if inCodeBlock {
                    flushCode()
                }
                inCodeBlock.toggle()
                continue
            }

            if inCodeBlock {
                codeLines.append(rawLine)
                continue
            }

            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                listLines.append(String(line.dropFirst(2)))
                continue
            } else {
                flushList()
            }

            if line.isEmpty {
                output.append("<p></p>")
                continue
            }

            if line.hasPrefix(">") {
                output.append("<blockquote>\(applyInlineMarkup(String(line.drop(while: { $0 == ">" || $0 == " " }))))</blockquote>")
                continue
            }

            if let heading = headingHTML(for: line) {
                output.append(heading)
                continue
            }

            output.append("<p>\(applyInlineMarkup(line))</p>")
        }

        flushList()
        flushCode()
        return output.joined(separator: "\n")
    }

    private static func headingHTML(for line: String) -> String? {
        var level = 0
        for ch in line {
            if ch == "#" { level += 1 } else { break }
        }
        guard level > 0, level <= 6 else { return nil }
        let text = line.drop(while: { $0 == "#" || $0 == " " })
        return "<h\(level)>\(applyInlineMarkup(String(text)))</h\(level)>"
    }

    private static func applyInlineMarkup(_ text: String) -> String {
        var value = text
        value = replacingMatches(in: value, pattern: "`([^`]+)`", template: "<code>$1</code>")
        value = replacingMatches(in: value, pattern: "\\*\\*\\*([^*]+)\\*\\*\\*", template: "<strong><em>$1</em></strong>")
        value = replacingMatches(in: value, pattern: "\\*\\*([^*]+)\\*\\*", template: "<strong>$1</strong>")
        value = replacingMatches(in: value, pattern: "\\*([^*]+)\\*", template: "<em>$1</em>")
        value = replacingMatches(in: value, pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)", template: "<a href=\"$2\">$1</a>")
        return value
    }

    private static func replacingMatches(in text: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
