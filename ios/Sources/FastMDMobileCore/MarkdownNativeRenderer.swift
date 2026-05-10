import Foundation

public enum NativeMarkdownBlockRole: String, CaseIterable, Equatable, Sendable {
    case heading
    case paragraph
    case blockquote
    case unorderedList
    case orderedList
    case taskList
    case table
    case codeFence
    case richFallback
    case image
    case horizontalRule
    case footnote
    case htmlFallback
}

public struct NativeMarkdownInlineStyle: OptionSet, Equatable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let bold = NativeMarkdownInlineStyle(rawValue: 1 << 0)
    public static let italic = NativeMarkdownInlineStyle(rawValue: 1 << 1)
    public static let strikethrough = NativeMarkdownInlineStyle(rawValue: 1 << 2)
    public static let inlineCode = NativeMarkdownInlineStyle(rawValue: 1 << 3)
    public static let highlight = NativeMarkdownInlineStyle(rawValue: 1 << 4)
    public static let subscriptText = NativeMarkdownInlineStyle(rawValue: 1 << 5)
    public static let superscriptText = NativeMarkdownInlineStyle(rawValue: 1 << 6)
    public static let inlineMath = NativeMarkdownInlineStyle(rawValue: 1 << 7)
}

public struct NativeMarkdownInlineRun: Equatable, Sendable {
    public let text: String
    public let styles: NativeMarkdownInlineStyle
    public let linkDecision: MobileLinkPolicyDecision?

    public init(
        text: String,
        styles: NativeMarkdownInlineStyle = [],
        linkDecision: MobileLinkPolicyDecision? = nil
    ) {
        self.text = text
        self.styles = styles
        self.linkDecision = linkDecision
    }
}

public struct NativeMarkdownBlockquoteLine: Equatable, Sendable {
    public let depth: Int
    public let inlineRuns: [NativeMarkdownInlineRun]

    public init(depth: Int, inlineRuns: [NativeMarkdownInlineRun]) {
        self.depth = depth
        self.inlineRuns = inlineRuns
    }

    public var plainText: String {
        inlineRuns.map(\.text).joined()
    }
}

public struct NativeMarkdownListItem: Equatable, Sendable {
    public let nestingLevel: Int
    public let marker: String
    public let checked: Bool?
    public let inlineRuns: [NativeMarkdownInlineRun]

    public init(
        nestingLevel: Int,
        marker: String,
        checked: Bool? = nil,
        inlineRuns: [NativeMarkdownInlineRun]
    ) {
        self.nestingLevel = nestingLevel
        self.marker = marker
        self.checked = checked
        self.inlineRuns = inlineRuns
    }

    public var plainText: String {
        inlineRuns.map(\.text).joined()
    }
}

public struct NativeMarkdownTable: Equatable, Sendable {
    public let rows: [[String]]
    public let columnCount: Int
    public let scrollsHorizontallyWithinBlock: Bool

    public init(rows: [[String]], scrollsHorizontallyWithinBlock: Bool = true) {
        self.rows = rows
        self.columnCount = rows.map(\.count).max() ?? 0
        self.scrollsHorizontallyWithinBlock = scrollsHorizontallyWithinBlock
    }
}

public enum NativeMarkdownCodeHighlighting: String, Equatable, Sendable {
    case plainFallback
}

public struct NativeMarkdownCodeBlock: Equatable, Sendable {
    public let language: String?
    public let code: String
    public let supportsCopyAction: Bool
    public let highlighting: NativeMarkdownCodeHighlighting
    public let scrollsHorizontallyWithinBlock: Bool

    public init(
        language: String?,
        code: String,
        supportsCopyAction: Bool = true,
        highlighting: NativeMarkdownCodeHighlighting = .plainFallback,
        scrollsHorizontallyWithinBlock: Bool = true
    ) {
        self.language = language
        self.code = code
        self.supportsCopyAction = supportsCopyAction
        self.highlighting = highlighting
        self.scrollsHorizontallyWithinBlock = scrollsHorizontallyWithinBlock
    }
}

public enum NativeMarkdownRichFallbackKind: String, Equatable, Sendable {
    case mermaidDiagramSource
    case blockMath
}

public enum NativeMarkdownRichFallbackSurface: String, Equatable, Sendable {
    case nativeSafeCard
    case localWKWebView
}

public struct NativeMarkdownRichFallback: Equatable, Sendable {
    public let kind: NativeMarkdownRichFallbackKind
    public let title: String
    public let source: String
    public let surface: NativeMarkdownRichFallbackSurface
    public let rendersAsNativeSafeCard: Bool
    public let requiresVendoredRendererAssets: Bool
    public let allowsNetworkRequests: Bool
    public let allowsExternalNavigation: Bool
    public let allowsRemoteSubresources: Bool

    public init(
        kind: NativeMarkdownRichFallbackKind,
        title: String,
        source: String,
        surface: NativeMarkdownRichFallbackSurface = .nativeSafeCard,
        rendersAsNativeSafeCard: Bool = true,
        requiresVendoredRendererAssets: Bool = false,
        allowsNetworkRequests: Bool = false,
        allowsExternalNavigation: Bool = false,
        allowsRemoteSubresources: Bool = false
    ) {
        self.kind = kind
        self.title = title
        self.source = source
        self.surface = surface
        self.rendersAsNativeSafeCard = rendersAsNativeSafeCard
        self.requiresVendoredRendererAssets = requiresVendoredRendererAssets
        self.allowsNetworkRequests = allowsNetworkRequests
        self.allowsExternalNavigation = allowsExternalNavigation
        self.allowsRemoteSubresources = allowsRemoteSubresources
    }
}

public struct NativeMarkdownImage: Equatable, Sendable {
    public let altText: String
    public let source: String
    public let isRemote: Bool
    public let loadsAutomatically: Bool
    public let requiresManualOpenAction: Bool
    public let requiresBoundedLocalDecode: Bool
    public let downsamplePolicy: IOSLocalImageDownsamplePolicy?
    public let linkDecision: MobileLinkPolicyDecision

    public init(
        altText: String,
        source: String,
        isRemote: Bool,
        loadsAutomatically: Bool,
        requiresManualOpenAction: Bool,
        requiresBoundedLocalDecode: Bool,
        downsamplePolicy: IOSLocalImageDownsamplePolicy? = nil,
        linkDecision: MobileLinkPolicyDecision
    ) {
        self.altText = altText
        self.source = source
        self.isRemote = isRemote
        self.loadsAutomatically = loadsAutomatically
        self.requiresManualOpenAction = requiresManualOpenAction
        self.requiresBoundedLocalDecode = requiresBoundedLocalDecode
        self.downsamplePolicy = downsamplePolicy
        self.linkDecision = linkDecision
    }
}

public enum NativeMarkdownHTMLFallbackKind: String, Equatable, Sendable {
    case detailsDisclosure
    case videoPlaceholder
    case genericSanitizedText
}

public struct NativeMarkdownHTMLFallback: Equatable, Sendable {
    public let kind: NativeMarkdownHTMLFallbackKind
    public let summary: String?
    public let sanitizedText: String
    public let blocksExternalNavigation: Bool
    public let blocksRemoteSubresources: Bool

    public init(
        kind: NativeMarkdownHTMLFallbackKind,
        summary: String?,
        sanitizedText: String,
        blocksExternalNavigation: Bool = true,
        blocksRemoteSubresources: Bool = true
    ) {
        self.kind = kind
        self.summary = summary
        self.sanitizedText = sanitizedText
        self.blocksExternalNavigation = blocksExternalNavigation
        self.blocksRemoteSubresources = blocksRemoteSubresources
    }
}

public struct NativeMarkdownBlockPresentation: Equatable, Sendable {
    public let id: MarkdownBlockID
    public let role: NativeMarkdownBlockRole
    public let sourceRange: MarkdownSourceRange
    public let headingLevel: Int?
    public let inlineRuns: [NativeMarkdownInlineRun]
    public let blockquoteLines: [NativeMarkdownBlockquoteLine]
    public let listItems: [NativeMarkdownListItem]
    public let table: NativeMarkdownTable?
    public let codeBlock: NativeMarkdownCodeBlock?
    public let richFallback: NativeMarkdownRichFallback?
    public let image: NativeMarkdownImage?
    public let htmlFallback: NativeMarkdownHTMLFallback?

    public init(
        id: MarkdownBlockID,
        role: NativeMarkdownBlockRole,
        sourceRange: MarkdownSourceRange,
        headingLevel: Int? = nil,
        inlineRuns: [NativeMarkdownInlineRun],
        blockquoteLines: [NativeMarkdownBlockquoteLine] = [],
        listItems: [NativeMarkdownListItem] = [],
        table: NativeMarkdownTable? = nil,
        codeBlock: NativeMarkdownCodeBlock? = nil,
        richFallback: NativeMarkdownRichFallback? = nil,
        image: NativeMarkdownImage? = nil,
        htmlFallback: NativeMarkdownHTMLFallback? = nil
    ) {
        self.id = id
        self.role = role
        self.sourceRange = sourceRange
        self.headingLevel = headingLevel
        self.inlineRuns = inlineRuns
        self.blockquoteLines = blockquoteLines
        self.listItems = listItems
        self.table = table
        self.codeBlock = codeBlock
        self.richFallback = richFallback
        self.image = image
        self.htmlFallback = htmlFallback
    }

    public var plainText: String {
        inlineRuns.map(\.text).joined()
    }
}

public struct MarkdownNativeRenderer: Equatable, Sendable {
    public let linkPolicy: MobileLinkPolicy

    public init(linkPolicy: MobileLinkPolicy = MobileLinkPolicy()) {
        self.linkPolicy = linkPolicy
    }

    public func render(
        document: MarkdownRenderDocument,
        source: String
    ) -> [NativeMarkdownBlockPresentation] {
        document.blocks.map { block in
            let blockSource = sourceSlice(in: source, range: block.sourceRange)

            switch block.kind {
            case .heading:
                let parsed = parseHeading(blockSource)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .heading,
                    sourceRange: block.sourceRange,
                    headingLevel: parsed.level,
                    inlineRuns: parseInlineRuns(parsed.text)
                )

            case .paragraph:
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .paragraph,
                    sourceRange: block.sourceRange,
                    inlineRuns: parseInlineRuns(normalizeParagraph(blockSource))
                )

            case .blockquote:
                let lines = parseBlockquote(blockSource)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .blockquote,
                    sourceRange: block.sourceRange,
                    inlineRuns: lines.flatMap(\.inlineRuns),
                    blockquoteLines: lines
                )

            case .unorderedList:
                let items = parseList(blockSource, kind: .unorderedList)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .unorderedList,
                    sourceRange: block.sourceRange,
                    inlineRuns: items.flatMap(\.inlineRuns),
                    listItems: items
                )

            case .orderedList:
                let items = parseList(blockSource, kind: .orderedList)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .orderedList,
                    sourceRange: block.sourceRange,
                    inlineRuns: items.flatMap(\.inlineRuns),
                    listItems: items
                )

            case .taskList:
                let items = parseList(blockSource, kind: .taskList)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .taskList,
                    sourceRange: block.sourceRange,
                    inlineRuns: items.flatMap(\.inlineRuns),
                    listItems: items
                )

            case .table:
                let table = parseTable(blockSource)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .table,
                    sourceRange: block.sourceRange,
                    inlineRuns: table.rows.flatMap { row in
                        row.map { NativeMarkdownInlineRun(text: $0) }
                    },
                    table: table
                )

            case .codeFence:
                let codeBlock = parseCodeFence(blockSource)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .codeFence,
                    sourceRange: block.sourceRange,
                    inlineRuns: [NativeMarkdownInlineRun(text: codeBlock.code)],
                    codeBlock: codeBlock
                )

            case .richFallback:
                let richFallback = parseRichFallback(blockSource)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .richFallback,
                    sourceRange: block.sourceRange,
                    inlineRuns: [NativeMarkdownInlineRun(text: richFallback.source)],
                    richFallback: richFallback
                )

            case .image:
                let image = parseImage(blockSource)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .image,
                    sourceRange: block.sourceRange,
                    inlineRuns: [NativeMarkdownInlineRun(text: image.altText)],
                    image: image
                )

            case .horizontalRule:
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .horizontalRule,
                    sourceRange: block.sourceRange,
                    inlineRuns: []
                )

            case .footnote:
                let text = parseFootnote(blockSource)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .footnote,
                    sourceRange: block.sourceRange,
                    inlineRuns: parseInlineRuns(text)
                )

            case .htmlFallback:
                let htmlFallback = parseHTMLFallback(blockSource)
                return NativeMarkdownBlockPresentation(
                    id: block.id,
                    role: .htmlFallback,
                    sourceRange: block.sourceRange,
                    inlineRuns: parseInlineRuns(htmlFallback.sanitizedText),
                    htmlFallback: htmlFallback
                )

            }
        }
    }

    public func parseInlineRuns(_ text: String) -> [NativeMarkdownInlineRun] {
        InlineRunParser(linkPolicy: linkPolicy).parse(text)
    }

    private func sourceSlice(in source: String, range: MarkdownSourceRange) -> String {
        guard range.startUTF8Offset >= 0,
              range.endUTF8Offset >= range.startUTF8Offset,
              range.endUTF8Offset <= source.utf8.count else {
            return ""
        }

        let start = source.utf8.index(source.utf8.startIndex, offsetBy: range.startUTF8Offset)
        let end = source.utf8.index(source.utf8.startIndex, offsetBy: range.endUTF8Offset)
        return String(decoding: source.utf8[start..<end], as: UTF8.self)
    }

    private func parseHeading(_ source: String) -> (level: Int, text: String) {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let level = min(6, max(1, trimmed.prefix { $0 == "#" }.count))
        let content = trimmed.dropFirst(level)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (level, content)
    }

    private func normalizeParagraph(_ source: String) -> String {
        source.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseBlockquote(_ source: String) -> [NativeMarkdownBlockquoteLine] {
        source.split(whereSeparator: \.isNewline)
            .compactMap { rawLine -> NativeMarkdownBlockquoteLine? in
                var text = String(rawLine).trimmingCharacters(in: .whitespaces)
                var depth = 0

                while text.hasPrefix(">") {
                    depth += 1
                    text = String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
                }

                guard depth > 0 else {
                    return nil
                }

                return NativeMarkdownBlockquoteLine(
                    depth: depth,
                    inlineRuns: parseInlineRuns(text)
                )
            }
    }

    private func parseList(
        _ source: String,
        kind: NativeMarkdownBlockRole
    ) -> [NativeMarkdownListItem] {
        source.split(whereSeparator: \.isNewline)
            .compactMap { rawLine -> NativeMarkdownListItem? in
                let line = String(rawLine)
                let leadingSpaces = line.prefix { $0 == " " || $0 == "\t" }.reduce(0) { count, character in
                    count + (character == "\t" ? 4 : 1)
                }
                let nestingLevel = leadingSpaces / 2
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                switch kind {
                case .taskList:
                    guard let parsed = parseTaskListItem(trimmed) else {
                        return nil
                    }
                    return NativeMarkdownListItem(
                        nestingLevel: nestingLevel,
                        marker: parsed.marker,
                        checked: parsed.checked,
                        inlineRuns: parseInlineRuns(parsed.text)
                    )

                case .orderedList:
                    guard let parsed = parseOrderedListItem(trimmed) else {
                        return nil
                    }
                    return NativeMarkdownListItem(
                        nestingLevel: nestingLevel,
                        marker: parsed.marker,
                        inlineRuns: parseInlineRuns(parsed.text)
                    )

                case .unorderedList:
                    guard trimmed.count >= 2,
                          let marker = trimmed.first,
                          marker == "-" || marker == "*" || marker == "+",
                          trimmed[trimmed.index(after: trimmed.startIndex)].isWhitespace else {
                        return nil
                    }
                    let text = String(trimmed.dropFirst(2))
                    return NativeMarkdownListItem(
                        nestingLevel: nestingLevel,
                        marker: String(marker),
                        inlineRuns: parseInlineRuns(text)
                    )

                default:
                    return nil
                }
            }
    }

    private func parseTaskListItem(_ text: String) -> (marker: String, checked: Bool, text: String)? {
        guard text.count >= 6,
              let marker = text.first,
              marker == "-" || marker == "*" || marker == "+",
              text[text.index(after: text.startIndex)].isWhitespace else {
            return nil
        }

        let checkboxStart = text.index(text.startIndex, offsetBy: 2)
        let checkboxEnd = text.index(checkboxStart, offsetBy: 3)
        let checkbox = String(text[checkboxStart..<checkboxEnd]).lowercased()
        guard checkbox == "[ ]" || checkbox == "[x]" else {
            return nil
        }

        let contentStart = text.index(checkboxEnd, offsetBy: 1, limitedBy: text.endIndex) ?? checkboxEnd
        return (String(marker), checkbox == "[x]", String(text[contentStart...]))
    }

    private func parseOrderedListItem(_ text: String) -> (marker: String, text: String)? {
        var marker = ""
        var index = text.startIndex

        while index < text.endIndex, text[index].isNumber {
            marker.append(text[index])
            index = text.index(after: index)
        }

        guard !marker.isEmpty,
              index < text.endIndex,
              text[index] == "." || text[index] == ")" else {
            return nil
        }

        marker.append(text[index])
        index = text.index(after: index)

        guard index < text.endIndex, text[index].isWhitespace else {
            return nil
        }

        return (marker, String(text[text.index(after: index)...]))
    }

    private func parseTable(_ source: String) -> NativeMarkdownTable {
        let rows = source.split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !isTableDelimiterRow($0) }
            .map { tableCells(in: $0) }

        return NativeMarkdownTable(rows: rows)
    }

    private func isTableDelimiterRow(_ row: String) -> Bool {
        let cells = tableCells(in: row)
        guard !cells.isEmpty else {
            return false
        }

        return cells.allSatisfy { cell in
            let stripped = cell.replacingOccurrences(of: ":", with: "")
            return stripped.count >= 3 && stripped.allSatisfy { $0 == "-" }
        }
    }

    private func tableCells(in row: String) -> [String] {
        var trimmed = row.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("|") {
            trimmed.removeFirst()
        }
        if trimmed.hasSuffix("|") {
            trimmed.removeLast()
        }

        return trimmed
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    private func parseCodeFence(_ source: String) -> NativeMarkdownCodeBlock {
        var lines = source.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        let opening = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let language = String(opening.dropFirst(3))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty

        if !lines.isEmpty {
            lines.removeFirst()
        }
        if let last = lines.last?.trimmingCharacters(in: .whitespacesAndNewlines),
           last.hasPrefix("```") || last.hasPrefix("~~~") {
            lines.removeLast()
        }

        return NativeMarkdownCodeBlock(
            language: language,
            code: lines.joined(separator: "\n")
        )
    }

    private func parseRichFallback(_ source: String) -> NativeMarkdownRichFallback {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            return NativeMarkdownRichFallback(
                kind: .mermaidDiagramSource,
                title: "Mermaid diagram source",
                source: parseCodeFence(source).code
            )
        }

        return NativeMarkdownRichFallback(
            kind: .blockMath,
            title: "Math formula",
            source: source
                .split(whereSeparator: \.isNewline)
                .map(String.init)
                .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines) != "$$" }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func parseImage(_ source: String) -> NativeMarkdownImage {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsed = parseMarkdownImage(trimmed)
        let imageSource = parsed.source
        let isRemote = imageSource.lowercased().hasPrefix("http://")
            || imageSource.lowercased().hasPrefix("https://")
        let decision = imageDecision(for: imageSource, isRemote: isRemote)

        return NativeMarkdownImage(
            altText: parsed.altText,
            source: imageSource,
            isRemote: isRemote,
            loadsAutomatically: !isRemote && decision.kind != .blocked,
            requiresManualOpenAction: isRemote,
            requiresBoundedLocalDecode: !isRemote,
            downsamplePolicy: isRemote ? nil : IOSLocalImageDownsamplePolicy(),
            linkDecision: decision
        )
    }

    private func imageDecision(for source: String, isRemote: Bool) -> MobileLinkPolicyDecision {
        let trimmedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSource.isEmpty else {
            return MobileLinkPolicyDecision(kind: .blocked, normalizedURLString: nil, reason: .empty)
        }

        if isRemote {
            return linkPolicy.decision(for: trimmedSource, isRemoteResource: true)
        }

        let scheme = URLComponents(string: trimmedSource)?.scheme?.lowercased()
        if scheme == nil {
            return MobileLinkPolicyDecision(kind: .allowed, normalizedURLString: trimmedSource)
        }

        return linkPolicy.decision(for: trimmedSource, isRemoteResource: false)
    }

    private func parseMarkdownImage(_ text: String) -> (altText: String, source: String) {
        guard text.hasPrefix("!["),
              let altClose = text.firstIndex(of: "]") else {
            return ("Image", text)
        }

        let destinationOpen = text.index(after: altClose)
        guard destinationOpen < text.endIndex, text[destinationOpen] == "(" else {
            return (String(text[text.index(text.startIndex, offsetBy: 2)..<altClose]), "")
        }

        let destinationStart = text.index(after: destinationOpen)
        guard let destinationClose = text[destinationStart...].firstIndex(of: ")") else {
            return (String(text[text.index(text.startIndex, offsetBy: 2)..<altClose]), "")
        }

        return (
            String(text[text.index(text.startIndex, offsetBy: 2)..<altClose]),
            String(text[destinationStart..<destinationClose]).trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func parseFootnote(_ source: String) -> String {
        let trimmed = normalizeParagraph(source)
        guard let delimiter = trimmed.range(of: "]:") else {
            return trimmed
        }

        return String(trimmed[delimiter.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseHTMLFallback(_ source: String) -> NativeMarkdownHTMLFallback {
        let lowercased = source.lowercased()
        let kind: NativeMarkdownHTMLFallbackKind
        if lowercased.contains("<video") {
            kind = .videoPlaceholder
        } else if lowercased.contains("<details") || lowercased.contains("<summary") {
            kind = .detailsDisclosure
        } else {
            kind = .genericSanitizedText
        }

        return NativeMarkdownHTMLFallback(
            kind: kind,
            summary: summaryText(in: source),
            sanitizedText: sanitizedHTMLText(source)
        )
    }

    private func summaryText(in source: String) -> String? {
        guard let openRange = source.range(of: "<summary", options: .caseInsensitive),
              let openEnd = source[openRange.upperBound...].firstIndex(of: ">"),
              let closeRange = source[openEnd...].range(of: "</summary>", options: .caseInsensitive) else {
            return nil
        }

        let contentStart = source.index(after: openEnd)
        return sanitizedHTMLText(String(source[contentStart..<closeRange.lowerBound]))
            .nilIfEmpty
    }

    private func sanitizedHTMLText(_ source: String) -> String {
        let source = removingBlockedHTMLContent(from: source)
        var output = ""
        var index = source.startIndex
        var insideTag = false

        while index < source.endIndex {
            let character = source[index]
            if character == "<" {
                insideTag = true
            } else if character == ">" {
                insideTag = false
                output.append(" ")
            } else if !insideTag {
                output.append(character)
            }

            index = source.index(after: index)
        }

        return output
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func removingBlockedHTMLContent(from source: String) -> String {
        var result = source
        for tag in ["script", "iframe"] {
            while let openRange = result.range(of: "<\(tag)", options: .caseInsensitive),
                  let openEnd = result[openRange.upperBound...].firstIndex(of: ">"),
                  let closeRange = result[openEnd...].range(of: "</\(tag)>", options: .caseInsensitive) {
                result.removeSubrange(openRange.lowerBound..<closeRange.upperBound)
            }
        }
        return result
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private struct InlineRunParser {
    let linkPolicy: MobileLinkPolicy

    func parse(_ text: String) -> [NativeMarkdownInlineRun] {
        var runs: [NativeMarkdownInlineRun] = []
        parse(text, inheritedStyles: [], into: &runs)
        return coalesce(runs)
    }

    private func parse(
        _ text: String,
        inheritedStyles: NativeMarkdownInlineStyle,
        into runs: inout [NativeMarkdownInlineRun]
    ) {
        var index = text.startIndex
        var literal = ""

        func flushLiteral() {
            guard !literal.isEmpty else {
                return
            }
            runs.append(NativeMarkdownInlineRun(text: literal, styles: inheritedStyles))
            literal = ""
        }

        while index < text.endIndex {
            if text[index] == "\\" {
                let next = text.index(after: index)
                if next < text.endIndex {
                    literal.append(text[next])
                    index = text.index(after: next)
                } else {
                    literal.append(text[index])
                    index = next
                }
                continue
            }

            if let token = matchedToken(in: text, at: index) {
                flushLiteral()

                switch token.kind {
                case .styled(let style):
                    parse(
                        token.content,
                        inheritedStyles: inheritedStyles.union(style),
                        into: &runs
                    )

                case .link(let destination):
                    parseLinkedText(
                        token.content,
                        destination: destination,
                        inheritedStyles: inheritedStyles,
                        into: &runs
                    )

                case .autolink(let destination):
                    runs.append(
                        NativeMarkdownInlineRun(
                            text: token.content,
                            styles: inheritedStyles,
                            linkDecision: linkPolicy.decision(for: destination)
                        )
                    )
                }

                index = token.endIndex
                continue
            }

            literal.append(text[index])
            index = text.index(after: index)
        }

        flushLiteral()
    }

    private func parseLinkedText(
        _ text: String,
        destination: String,
        inheritedStyles: NativeMarkdownInlineStyle,
        into runs: inout [NativeMarkdownInlineRun]
    ) {
        let decision = linkPolicy.decision(for: destination)
        let nestedRuns = InlineRunParser(linkPolicy: linkPolicy).parse(text)

        if nestedRuns.isEmpty {
            runs.append(
                NativeMarkdownInlineRun(
                    text: text,
                    styles: inheritedStyles,
                    linkDecision: decision
                )
            )
            return
        }

        runs.append(
            contentsOf: nestedRuns.map { run in
                NativeMarkdownInlineRun(
                    text: run.text,
                    styles: inheritedStyles.union(run.styles),
                    linkDecision: decision
                )
            }
        )
    }

    private func matchedToken(in text: String, at index: String.Index) -> InlineToken? {
        if let token = markdownLink(in: text, at: index) {
            return token
        }
        if let token = autolink(in: text, at: index) {
            return token
        }
        if let token = pairedToken(in: text, at: index, delimiter: "`", style: .inlineCode) {
            return token
        }
        if let token = htmlStyledToken(in: text, at: index, tag: "mark", style: .highlight) {
            return token
        }
        if let token = htmlStyledToken(in: text, at: index, tag: "sub", style: .subscriptText) {
            return token
        }
        if let token = htmlStyledToken(in: text, at: index, tag: "sup", style: .superscriptText) {
            return token
        }
        if let token = inlineMath(in: text, at: index) {
            return token
        }
        if let token = pairedToken(in: text, at: index, delimiter: "***", style: [.bold, .italic]) {
            return token
        }
        if let token = pairedToken(in: text, at: index, delimiter: "~~", style: .strikethrough) {
            return token
        }
        if let token = pairedToken(in: text, at: index, delimiter: "**", style: .bold) {
            return token
        }
        if let token = pairedToken(in: text, at: index, delimiter: "*", style: .italic) {
            return token
        }
        return nil
    }

    private func inlineMath(in text: String, at index: String.Index) -> InlineToken? {
        guard text[index] == "$" else {
            return nil
        }

        let contentStart = text.index(after: index)
        guard contentStart < text.endIndex,
              text[contentStart] != "$",
              let close = text[contentStart...].firstIndex(of: "$"),
              close > contentStart else {
            return nil
        }

        return InlineToken(
            kind: .styled(.inlineMath),
            content: String(text[contentStart..<close]),
            endIndex: text.index(after: close)
        )
    }

    private func pairedToken(
        in text: String,
        at index: String.Index,
        delimiter: String,
        style: NativeMarkdownInlineStyle
    ) -> InlineToken? {
        guard text[index...].hasPrefix(delimiter) else {
            return nil
        }

        let contentStart = text.index(index, offsetBy: delimiter.count)
        guard let closeRange = text[contentStart...].range(of: delimiter) else {
            return nil
        }

        return InlineToken(
            kind: .styled(style),
            content: String(text[contentStart..<closeRange.lowerBound]),
            endIndex: closeRange.upperBound
        )
    }

    private func htmlStyledToken(
        in text: String,
        at index: String.Index,
        tag: String,
        style: NativeMarkdownInlineStyle
    ) -> InlineToken? {
        let opening = "<\(tag)>"
        let closing = "</\(tag)>"

        guard let openRange = text[index...].range(
            of: opening,
            options: [.caseInsensitive, .anchored]
        ) else {
            return nil
        }

        let contentStart = openRange.upperBound
        guard let closeRange = text[contentStart...].range(of: closing, options: .caseInsensitive) else {
            return nil
        }

        return InlineToken(
            kind: .styled(style),
            content: String(text[contentStart..<closeRange.lowerBound]),
            endIndex: closeRange.upperBound
        )
    }

    private func markdownLink(in text: String, at index: String.Index) -> InlineToken? {
        guard text[index] == "[" else {
            return nil
        }

        let labelStart = text.index(after: index)
        guard let labelClose = text[labelStart...].firstIndex(of: "]") else {
            return nil
        }

        let destinationOpen = text.index(after: labelClose)
        guard destinationOpen < text.endIndex, text[destinationOpen] == "(" else {
            return nil
        }

        let destinationStart = text.index(after: destinationOpen)
        guard let destinationClose = text[destinationStart...].firstIndex(of: ")") else {
            return nil
        }

        let destination = String(text[destinationStart..<destinationClose])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return InlineToken(
            kind: .link(destination: destination),
            content: String(text[labelStart..<labelClose]),
            endIndex: text.index(after: destinationClose)
        )
    }

    private func autolink(in text: String, at index: String.Index) -> InlineToken? {
        guard text[index] == "<" else {
            return nil
        }

        let contentStart = text.index(after: index)
        guard let close = text[contentStart...].firstIndex(of: ">") else {
            return nil
        }

        let content = String(text[contentStart..<close])
        let destination: String
        if content.contains("://") {
            destination = content
        } else if content.contains("@"), !content.contains(" ") {
            destination = "mailto:\(content)"
        } else {
            return nil
        }

        return InlineToken(
            kind: .autolink(destination: destination),
            content: content,
            endIndex: text.index(after: close)
        )
    }

    private func coalesce(_ runs: [NativeMarkdownInlineRun]) -> [NativeMarkdownInlineRun] {
        var coalesced: [NativeMarkdownInlineRun] = []

        for run in runs where !run.text.isEmpty {
            if let last = coalesced.last,
               last.styles == run.styles,
               last.linkDecision == run.linkDecision {
                coalesced[coalesced.count - 1] = NativeMarkdownInlineRun(
                    text: last.text + run.text,
                    styles: last.styles,
                    linkDecision: last.linkDecision
                )
            } else {
                coalesced.append(run)
            }
        }

        return coalesced
    }
}

private struct InlineToken {
    let kind: Kind
    let content: String
    let endIndex: String.Index

    enum Kind {
        case styled(NativeMarkdownInlineStyle)
        case link(destination: String)
        case autolink(destination: String)
    }
}
