import Foundation

enum MarkdownRenderer {
    static func renderHTML(from markdown: String, title: String) -> String {
        let escaped = escapeHTML(markdown)
        let htmlBody = lineBasedRender(escaped)

        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            :root { color-scheme: light dark; }
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
              margin: 0;
              padding: 16px 18px;
              line-height: 1.55;
              background: rgba(255,255,255,0.96);
              color: #1f2328;
            }
            h1, h2, h3, h4, h5, h6 { margin: 1.0em 0 0.45em; line-height: 1.25; }
            h1 { font-size: 1.45rem; }
            h2 { font-size: 1.2rem; }
            h3 { font-size: 1.05rem; }
            p { margin: 0.55em 0; }
            code {
              background: #f6f8fa;
              border-radius: 6px;
              padding: 0.15em 0.35em;
              font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
              font-size: 0.92em;
            }
            pre {
              background: #f6f8fa;
              border-radius: 10px;
              padding: 12px;
              overflow-x: auto;
              white-space: pre-wrap;
              word-break: break-word;
            }
            pre code {
              background: transparent;
              padding: 0;
            }
            blockquote {
              border-left: 3px solid #d0d7de;
              margin: 0.75em 0;
              padding-left: 12px;
              color: #57606a;
            }
            ul { padding-left: 20px; }
            a { color: #0969da; text-decoration: none; }
            a:hover { text-decoration: underline; }
            .meta {
              position: sticky;
              top: 0;
              background: rgba(255,255,255,0.9);
              backdrop-filter: blur(8px);
              padding-bottom: 10px;
              margin-bottom: 8px;
              border-bottom: 1px solid #d8dee4;
            }
            .meta strong { font-size: 0.9rem; }
          </style>
        </head>
        <body>
          <div class="meta"><strong>\(escapeHTML(title))</strong></div>
          \(htmlBody)
        </body>
        </html>
        """
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
