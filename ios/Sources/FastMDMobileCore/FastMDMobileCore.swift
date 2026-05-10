import Foundation

public enum MobileFontTier: String, CaseIterable, Equatable, Sendable {
    case compact
    case `default`
    case large
    case reader

    public var bodyPointSize: Double {
        switch self {
        case .compact:
            return 14
        case .default:
            return 16
        case .large:
            return 18
        case .reader:
            return 21
        }
    }

    public var lineHeightMultiple: Double {
        switch self {
        case .compact:
            return 1.48
        case .default:
            return 1.52
        case .large:
            return 1.56
        case .reader:
            return 1.60
        }
    }

    public var monospacePointSize: Double {
        max(12, bodyPointSize - 1)
    }
}

public enum ReaderState: String, CaseIterable, Equatable, Sendable {
    case empty
    case loading
    case rendering
    case ready
    case searching
    case editingSource
    case editingBlock
    case saving
    case readOnly
    case permissionLost
    case error
}

public enum MobileSourceOrigin: String, CaseIterable, Equatable, Sendable {
    case launcher
    case documentPicker
    case filesAppOpen
    case shareText
    case shareDocumentURL
    case recentBookmark
    case temporary
}

public enum MobileDocumentAccess: String, CaseIterable, Equatable, Sendable {
    case readOnly
    case readWrite
}

public struct MobileDocumentHandle: Equatable, Sendable {
    public let identifier: String
    public let displayName: String
    public let origin: MobileSourceOrigin
    public let access: MobileDocumentAccess
    public let bookmarkData: Data?

    public init(
        identifier: String,
        displayName: String,
        origin: MobileSourceOrigin,
        access: MobileDocumentAccess,
        bookmarkData: Data? = nil
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.origin = origin
        self.access = access
        self.bookmarkData = bookmarkData
    }

    public var canWrite: Bool {
        access == .readWrite
    }
}

public enum MarkdownTextEncoding: String, CaseIterable, Equatable, Sendable {
    case utf8
    case utf8WithBOM
    case unsupported
}

public enum MarkdownLineEnding: String, CaseIterable, Equatable, Sendable {
    case lf
    case crlf
    case mixed
    case none
}

public struct MobileFileMetadata: Equatable, Sendable {
    public let displayName: String
    public let byteCount: Int
    public let contentTypeIdentifier: String?
    public let modifiedAt: Date?

    public init(
        displayName: String,
        byteCount: Int,
        contentTypeIdentifier: String? = nil,
        modifiedAt: Date? = nil
    ) {
        self.displayName = displayName
        self.byteCount = byteCount
        self.contentTypeIdentifier = contentTypeIdentifier
        self.modifiedAt = modifiedAt
    }
}

public struct MarkdownLoadResult: Equatable, Sendable {
    public let handle: MobileDocumentHandle
    public let metadata: MobileFileMetadata
    public let source: String
    public let encoding: MarkdownTextEncoding
    public let lineEnding: MarkdownLineEnding
    public let loadedAt: Date

    public init(
        handle: MobileDocumentHandle,
        metadata: MobileFileMetadata,
        source: String,
        encoding: MarkdownTextEncoding,
        lineEnding: MarkdownLineEnding,
        loadedAt: Date
    ) {
        self.handle = handle
        self.metadata = metadata
        self.source = source
        self.encoding = encoding
        self.lineEnding = lineEnding
        self.loadedAt = loadedAt
    }
}

public struct MarkdownSourceRange: Equatable, Sendable {
    public let startUTF8Offset: Int
    public let endUTF8Offset: Int
    public let startLine: Int
    public let endLine: Int

    public init(
        startUTF8Offset: Int,
        endUTF8Offset: Int,
        startLine: Int,
        endLine: Int
    ) {
        self.startUTF8Offset = startUTF8Offset
        self.endUTF8Offset = endUTF8Offset
        self.startLine = startLine
        self.endLine = endLine
    }

    public var isValid: Bool {
        startUTF8Offset <= endUTF8Offset && startLine <= endLine
    }
}

public enum MarkdownRenderBlockKind: String, CaseIterable, Equatable, Sendable {
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

public struct MarkdownBlockID: RawRepresentable, Hashable, Equatable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(
        kind: MarkdownRenderBlockKind,
        sourceRange: MarkdownSourceRange,
        ordinal: Int
    ) {
        self.rawValue = [
            kind.rawValue,
            String(sourceRange.startUTF8Offset),
            String(sourceRange.endUTF8Offset),
            String(sourceRange.startLine),
            String(sourceRange.endLine),
            String(ordinal)
        ].joined(separator: ":")
    }
}

public struct MarkdownRenderBlock: Identifiable, Equatable, Sendable {
    public let id: MarkdownBlockID
    public let kind: MarkdownRenderBlockKind
    public let sourceRange: MarkdownSourceRange
    public let ordinal: Int
    public let textPreview: String

    public init(
        kind: MarkdownRenderBlockKind,
        sourceRange: MarkdownSourceRange,
        ordinal: Int,
        textPreview: String = ""
    ) {
        self.id = MarkdownBlockID(
            kind: kind,
            sourceRange: sourceRange,
            ordinal: ordinal
        )
        self.kind = kind
        self.sourceRange = sourceRange
        self.ordinal = ordinal
        self.textPreview = textPreview
    }
}

public struct MarkdownRenderDocument: Equatable, Sendable {
    public let blocks: [MarkdownRenderBlock]
    public let sourceByteCount: Int

    public init(blocks: [MarkdownRenderBlock], sourceByteCount: Int) {
        self.blocks = blocks
        self.sourceByteCount = sourceByteCount
    }

    public func block(id: MarkdownBlockID) -> MarkdownRenderBlock? {
        blocks.first { $0.id == id }
    }
}

public struct MarkdownParserAdapter: Equatable, Sendable {
    public init() {}

    public func parse(_ source: String) -> MarkdownRenderDocument {
        let lines = MarkdownSourceLine.makeLines(from: source)
        var blocks: [MarkdownRenderBlock] = []
        var index = 0

        while index < lines.count {
            if lines[index].isBlank {
                index += 1
                continue
            }

            let startIndex = index
            let kind: MarkdownRenderBlockKind
            let endIndex: Int

            if let fence = fenceMarker(in: lines[index].trimmedText) {
                endIndex = closingFenceIndex(
                    in: lines,
                    startIndex: index,
                    marker: fence.marker
                )
                kind = fence.language == "mermaid" ? .richFallback : .codeFence
            } else if lines[index].trimmedText == "$$" {
                endIndex = closingMathIndex(in: lines, startIndex: index)
                kind = .richFallback
            } else if isTableStart(in: lines, at: index) {
                endIndex = consumeTable(in: lines, startIndex: index)
                kind = .table
            } else if isHeading(lines[index].trimmedText) {
                endIndex = index
                kind = .heading
            } else if isHorizontalRule(lines[index].trimmedText) {
                endIndex = index
                kind = .horizontalRule
            } else if isBlockquote(lines[index].trimmedText) {
                endIndex = consumeBlockquote(in: lines, startIndex: index)
                kind = .blockquote
            } else if let listKind = listBlockKind(for: lines[index].trimmedText) {
                endIndex = consumeList(in: lines, startIndex: index)
                kind = listKind
            } else if isFootnoteDefinition(lines[index].trimmedText) {
                endIndex = consumeUntilBlank(in: lines, startIndex: index)
                kind = .footnote
            } else if isImageBlock(lines[index].trimmedText) {
                endIndex = index
                kind = .image
            } else if isHTMLBlockStart(lines[index].trimmedText) {
                endIndex = consumeHTMLBlock(in: lines, startIndex: index)
                kind = .htmlFallback
            } else {
                endIndex = consumeParagraph(in: lines, startIndex: index)
                kind = .paragraph
            }

            blocks.append(
                MarkdownRenderBlock(
                    kind: kind,
                    sourceRange: sourceRange(in: lines, startIndex: startIndex, endIndex: endIndex),
                    ordinal: blocks.count,
                    textPreview: textPreview(in: lines, startIndex: startIndex, endIndex: endIndex)
                )
            )
            index = endIndex + 1
        }

        return MarkdownRenderDocument(blocks: blocks, sourceByteCount: source.utf8.count)
    }

    private func sourceRange(
        in lines: [MarkdownSourceLine],
        startIndex: Int,
        endIndex: Int
    ) -> MarkdownSourceRange {
        MarkdownSourceRange(
            startUTF8Offset: lines[startIndex].startUTF8Offset,
            endUTF8Offset: lines[endIndex].endUTF8Offset,
            startLine: lines[startIndex].lineNumber,
            endLine: lines[endIndex].lineNumber
        )
    }

    private func textPreview(
        in lines: [MarkdownSourceLine],
        startIndex: Int,
        endIndex: Int
    ) -> String {
        let joined = lines[startIndex...endIndex]
            .map(\.trimmedText)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard joined.count > 120 else {
            return joined
        }

        return String(joined.prefix(120))
    }

    private func fenceMarker(in trimmedText: String) -> (marker: String, language: String)? {
        guard trimmedText.hasPrefix("```") || trimmedText.hasPrefix("~~~") else {
            return nil
        }

        let marker = String(trimmedText.prefix(3))
        let language = trimmedText.dropFirst(3)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return (marker, language)
    }

    private func closingFenceIndex(
        in lines: [MarkdownSourceLine],
        startIndex: Int,
        marker: String
    ) -> Int {
        var index = startIndex + 1
        while index < lines.count {
            if lines[index].trimmedText.hasPrefix(marker) {
                return index
            }
            index += 1
        }
        return lines.count - 1
    }

    private func closingMathIndex(in lines: [MarkdownSourceLine], startIndex: Int) -> Int {
        var index = startIndex + 1
        while index < lines.count {
            if lines[index].trimmedText == "$$" {
                return index
            }
            index += 1
        }
        return lines.count - 1
    }

    private func isTableStart(in lines: [MarkdownSourceLine], at index: Int) -> Bool {
        guard index + 1 < lines.count else {
            return false
        }

        return lines[index].trimmedText.contains("|")
            && isTableDelimiter(lines[index + 1].trimmedText)
    }

    private func isTableDelimiter(_ trimmedText: String) -> Bool {
        guard trimmedText.contains("|") else {
            return false
        }

        let cells = trimmedText
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return !cells.isEmpty && cells.allSatisfy { cell in
            let stripped = cell.replacingOccurrences(of: ":", with: "")
            return stripped.count >= 3 && stripped.allSatisfy { $0 == "-" }
        }
    }

    private func consumeTable(in lines: [MarkdownSourceLine], startIndex: Int) -> Int {
        var index = startIndex + 2
        while index < lines.count,
              !lines[index].isBlank,
              lines[index].trimmedText.contains("|") {
            index += 1
        }
        return index - 1
    }

    private func isHeading(_ trimmedText: String) -> Bool {
        let hashCount = trimmedText.prefix { $0 == "#" }.count
        guard (1...6).contains(hashCount) else {
            return false
        }

        guard trimmedText.count == hashCount else {
            let nextIndex = trimmedText.index(trimmedText.startIndex, offsetBy: hashCount)
            return trimmedText[nextIndex].isWhitespace
        }

        return true
    }

    private func isHorizontalRule(_ trimmedText: String) -> Bool {
        let compact = trimmedText.filter { !$0.isWhitespace }
        guard compact.count >= 3, let first = compact.first else {
            return false
        }

        return (first == "-" || first == "*" || first == "_")
            && compact.allSatisfy { $0 == first }
    }

    private func isBlockquote(_ trimmedText: String) -> Bool {
        trimmedText.hasPrefix(">")
    }

    private func consumeBlockquote(in lines: [MarkdownSourceLine], startIndex: Int) -> Int {
        var index = startIndex + 1
        while index < lines.count, isBlockquote(lines[index].trimmedText) {
            index += 1
        }
        return index - 1
    }

    private func listBlockKind(for trimmedText: String) -> MarkdownRenderBlockKind? {
        let lowercased = trimmedText.lowercased()
        if lowercased.hasPrefix("- [ ] ")
            || lowercased.hasPrefix("- [x] ")
            || lowercased.hasPrefix("* [ ] ")
            || lowercased.hasPrefix("* [x] ") {
            return .taskList
        }

        if trimmedText.hasPrefix("- ")
            || trimmedText.hasPrefix("* ")
            || trimmedText.hasPrefix("+ ") {
            return .unorderedList
        }

        return isOrderedListItem(trimmedText) ? .orderedList : nil
    }

    private func isOrderedListItem(_ trimmedText: String) -> Bool {
        var digitCount = 0
        for character in trimmedText {
            if character.isNumber {
                digitCount += 1
                continue
            }

            guard digitCount > 0, character == "." || character == ")" else {
                return false
            }

            let markerEnd = trimmedText.index(trimmedText.startIndex, offsetBy: digitCount + 1)
            return markerEnd < trimmedText.endIndex && trimmedText[markerEnd].isWhitespace
        }

        return false
    }

    private func consumeList(in lines: [MarkdownSourceLine], startIndex: Int) -> Int {
        var index = startIndex + 1
        while index < lines.count {
            if lines[index].isBlank {
                break
            }
            if listBlockKind(for: lines[index].trimmedText) != nil
                || lines[index].text.first?.isWhitespace == true {
                index += 1
                continue
            }
            break
        }
        return index - 1
    }

    private func isFootnoteDefinition(_ trimmedText: String) -> Bool {
        trimmedText.hasPrefix("[^") && trimmedText.contains("]:")
    }

    private func isImageBlock(_ trimmedText: String) -> Bool {
        trimmedText.hasPrefix("![") && trimmedText.contains("](")
    }

    private func isHTMLBlockStart(_ trimmedText: String) -> Bool {
        guard trimmedText.hasPrefix("<") else {
            return false
        }

        let lowercased = trimmedText.lowercased()
        return lowercased.hasPrefix("</")
            || lowercased.hasPrefix("<details")
            || lowercased.hasPrefix("<summary")
            || lowercased.hasPrefix("<div")
            || lowercased.hasPrefix("<p")
            || lowercased.hasPrefix("<ul")
            || lowercased.hasPrefix("<ol")
            || lowercased.hasPrefix("<li")
            || lowercased.hasPrefix("<video")
            || lowercased.hasPrefix("<source")
            || lowercased.hasPrefix("<img")
            || lowercased.hasPrefix("<iframe")
            || lowercased.hasPrefix("<script")
    }

    private func consumeHTMLBlock(in lines: [MarkdownSourceLine], startIndex: Int) -> Int {
        var index = startIndex + 1
        while index < lines.count, !lines[index].isBlank {
            index += 1
        }
        return index - 1
    }

    private func consumeUntilBlank(in lines: [MarkdownSourceLine], startIndex: Int) -> Int {
        var index = startIndex + 1
        while index < lines.count, !lines[index].isBlank {
            index += 1
        }
        return index - 1
    }

    private func consumeParagraph(in lines: [MarkdownSourceLine], startIndex: Int) -> Int {
        var index = startIndex + 1
        while index < lines.count, !lines[index].isBlank, !isBlockStart(in: lines, at: index) {
            index += 1
        }
        return index - 1
    }

    private func isBlockStart(in lines: [MarkdownSourceLine], at index: Int) -> Bool {
        let trimmedText = lines[index].trimmedText
        return fenceMarker(in: trimmedText) != nil
            || trimmedText == "$$"
            || isTableStart(in: lines, at: index)
            || isHeading(trimmedText)
            || isHorizontalRule(trimmedText)
            || isBlockquote(trimmedText)
            || listBlockKind(for: trimmedText) != nil
            || isFootnoteDefinition(trimmedText)
            || isImageBlock(trimmedText)
            || isHTMLBlockStart(trimmedText)
    }
}

private struct MarkdownSourceLine: Equatable {
    let lineNumber: Int
    let text: String
    let startUTF8Offset: Int
    let endUTF8Offset: Int

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        trimmedText.isEmpty
    }

    static func makeLines(from source: String) -> [MarkdownSourceLine] {
        guard !source.isEmpty else {
            return []
        }

        let rawLines = source.split(separator: "\n", omittingEmptySubsequences: false)
        var lines: [MarkdownSourceLine] = []
        var offset = 0

        for rawIndex in rawLines.indices {
            if rawIndex == rawLines.indices.last, rawLines[rawIndex].isEmpty, source.hasSuffix("\n") {
                break
            }

            let rawLine = String(rawLines[rawIndex])
            let text = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine
            lines.append(
                MarkdownSourceLine(
                    lineNumber: rawIndex + 1,
                    text: text,
                    startUTF8Offset: offset,
                    endUTF8Offset: offset + text.utf8.count
                )
            )

            let hasFollowingLine = rawIndex < rawLines.index(before: rawLines.endIndex)
            offset += rawLine.utf8.count + (hasFollowingLine ? 1 : 0)
        }

        return lines
    }
}

public enum FastMDErrorCategory: String, CaseIterable, Equatable, Sendable {
    case open
    case read
    case parse
    case render
    case search
    case edit
    case save
    case link
    case permission
    case security
}

public enum FastMDErrorCode: String, CaseIterable, Equatable, Sendable {
    case openFailed
    case readFailed
    case unsupportedEncoding
    case parseFailed
    case renderFailed
    case searchFailed
    case editConflict
    case saveFailed
    case externalMutation
    case linkRequiresConfirmation
    case linkBlocked
    case permissionDenied
    case permissionLost
    case securityBlocked

    public var category: FastMDErrorCategory {
        switch self {
        case .openFailed:
            return .open
        case .readFailed, .unsupportedEncoding:
            return .read
        case .parseFailed:
            return .parse
        case .renderFailed:
            return .render
        case .searchFailed:
            return .search
        case .editConflict:
            return .edit
        case .saveFailed, .externalMutation:
            return .save
        case .linkRequiresConfirmation, .linkBlocked:
            return .link
        case .permissionDenied, .permissionLost:
            return .permission
        case .securityBlocked:
            return .security
        }
    }
}

public enum MobileLinkDecisionKind: String, CaseIterable, Equatable, Sendable {
    case allowed
    case confirm
    case blocked
}

public enum MobileLinkBlockReason: String, CaseIterable, Equatable, Sendable {
    case empty
    case malformed
    case missingScheme
    case dangerousScheme
    case unsupportedScheme
    case remoteResourceDisabled
}

public struct MobileLinkPolicyDecision: Equatable, Sendable {
    public let kind: MobileLinkDecisionKind
    public let normalizedURLString: String?
    public let reason: MobileLinkBlockReason?

    public init(
        kind: MobileLinkDecisionKind,
        normalizedURLString: String?,
        reason: MobileLinkBlockReason? = nil
    ) {
        self.kind = kind
        self.normalizedURLString = normalizedURLString
        self.reason = reason
    }
}

public struct MobileLinkPolicy: Equatable, Sendable {
    public let allowedSchemes: Set<String>
    public let confirmationSchemes: Set<String>
    public let blockedSchemes: Set<String>
    public let allowRemoteResources: Bool

    public init(
        allowedSchemes: Set<String> = ["mailto"],
        confirmationSchemes: Set<String> = ["http", "https"],
        blockedSchemes: Set<String> = ["data", "file", "javascript"],
        allowRemoteResources: Bool = false
    ) {
        self.allowedSchemes = Set(allowedSchemes.map { $0.lowercased() })
        self.confirmationSchemes = Set(confirmationSchemes.map { $0.lowercased() })
        self.blockedSchemes = Set(blockedSchemes.map { $0.lowercased() })
        self.allowRemoteResources = allowRemoteResources
    }

    public func decision(for rawURLString: String, isRemoteResource: Bool = false) -> MobileLinkPolicyDecision {
        let trimmedURLString = rawURLString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedURLString.isEmpty else {
            return MobileLinkPolicyDecision(kind: .blocked, normalizedURLString: nil, reason: .empty)
        }

        guard let components = URLComponents(string: trimmedURLString) else {
            return MobileLinkPolicyDecision(kind: .blocked, normalizedURLString: nil, reason: .malformed)
        }

        guard let scheme = components.scheme?.lowercased(), !scheme.isEmpty else {
            return MobileLinkPolicyDecision(kind: .blocked, normalizedURLString: trimmedURLString, reason: .missingScheme)
        }

        if blockedSchemes.contains(scheme) {
            return MobileLinkPolicyDecision(kind: .blocked, normalizedURLString: trimmedURLString, reason: .dangerousScheme)
        }

        if isRemoteResource && !allowRemoteResources && (scheme == "http" || scheme == "https") {
            return MobileLinkPolicyDecision(kind: .blocked, normalizedURLString: trimmedURLString, reason: .remoteResourceDisabled)
        }

        if allowedSchemes.contains(scheme) {
            return MobileLinkPolicyDecision(kind: .allowed, normalizedURLString: trimmedURLString)
        }

        if confirmationSchemes.contains(scheme) {
            return MobileLinkPolicyDecision(kind: .confirm, normalizedURLString: trimmedURLString)
        }

        return MobileLinkPolicyDecision(kind: .blocked, normalizedURLString: trimmedURLString, reason: .unsupportedScheme)
    }
}

public enum IOSImageDecodeImplementation: String, CaseIterable, Equatable, Sendable {
    case imageIO
}

public struct IOSLocalImageDownsamplePolicy: Equatable, Sendable {
    public let implementation: IOSImageDecodeImplementation
    public let maximumPixelDimension: Int
    public let createsThumbnailFromImageIfAbsent: Bool
    public let createsThumbnailWithTransform: Bool
    public let cachesFullSizeImageImmediately: Bool
    public let decodesRemoteImages: Bool

    public init(
        implementation: IOSImageDecodeImplementation = .imageIO,
        maximumPixelDimension: Int = 2048,
        createsThumbnailFromImageIfAbsent: Bool = true,
        createsThumbnailWithTransform: Bool = true,
        cachesFullSizeImageImmediately: Bool = false,
        decodesRemoteImages: Bool = false
    ) {
        self.implementation = implementation
        self.maximumPixelDimension = max(256, maximumPixelDimension)
        self.createsThumbnailFromImageIfAbsent = createsThumbnailFromImageIfAbsent
        self.createsThumbnailWithTransform = createsThumbnailWithTransform
        self.cachesFullSizeImageImmediately = cachesFullSizeImageImmediately
        self.decodesRemoteImages = decodesRemoteImages
    }

    public var satisfiesStageOneLocalImageRule: Bool {
        implementation == .imageIO
            && createsThumbnailFromImageIfAbsent
            && createsThumbnailWithTransform
            && !cachesFullSizeImageImmediately
            && !decodesRemoteImages
    }
}

public enum IOSSecurityAuditStatus: String, CaseIterable, Equatable, Sendable {
    case satisfied
    case blocked
}

public struct IOSSecurityScopedAccessAudit: Equatable, Sendable {
    public let startedAccessCount: Int
    public let stoppedAccessCount: Int
    public let unresolvedStaleBookmarksReturnPermissionLost: Bool

    public init(
        startedAccessCount: Int,
        stoppedAccessCount: Int,
        unresolvedStaleBookmarksReturnPermissionLost: Bool = true
    ) {
        self.startedAccessCount = max(0, startedAccessCount)
        self.stoppedAccessCount = max(0, stoppedAccessCount)
        self.unresolvedStaleBookmarksReturnPermissionLost = unresolvedStaleBookmarksReturnPermissionLost
    }

    public var balancesEveryStartedAccess: Bool {
        startedAccessCount == stoppedAccessCount
    }

    public var status: IOSSecurityAuditStatus {
        balancesEveryStartedAccess && unresolvedStaleBookmarksReturnPermissionLost ? .satisfied : .blocked
    }
}

public struct IOSReleaseSecurityPosture: Equatable, Sendable {
    public let appTransportSecurityAllowsArbitraryLoads: Bool
    public let privacyManifestTracksUsers: Bool
    public let backgroundModes: [String]
    public let usesWKWebViewRichRendering: Bool
    public let localRendererPolicy: LocalRichRendererAssetPolicy

    public init(
        appTransportSecurityAllowsArbitraryLoads: Bool = false,
        privacyManifestTracksUsers: Bool = false,
        backgroundModes: [String] = [],
        usesWKWebViewRichRendering: Bool = false,
        localRendererPolicy: LocalRichRendererAssetPolicy = .nativeFallbackOnly
    ) {
        self.appTransportSecurityAllowsArbitraryLoads = appTransportSecurityAllowsArbitraryLoads
        self.privacyManifestTracksUsers = privacyManifestTracksUsers
        self.backgroundModes = backgroundModes
        self.usesWKWebViewRichRendering = usesWKWebViewRichRendering
        self.localRendererPolicy = localRendererPolicy
    }

    public var appTransportSecurityStatus: IOSSecurityAuditStatus {
        appTransportSecurityAllowsArbitraryLoads ? .blocked : .satisfied
    }

    public var privacyManifestStatus: IOSSecurityAuditStatus {
        privacyManifestTracksUsers ? .blocked : .satisfied
    }

    public var backgroundModeStatus: IOSSecurityAuditStatus {
        backgroundModes.isEmpty ? .satisfied : .blocked
    }

    public var richRendererStatus: IOSSecurityAuditStatus {
        guard usesWKWebViewRichRendering else {
            return localRendererPolicy.mode == .nativeFallbackOnly ? .satisfied : .blocked
        }

        let isBundledLocalOnly = localRendererPolicy.mode == .vendoredLocalBundle
            && localRendererPolicy.bundleResourceRoot != nil
        return isBundledLocalOnly
            && !localRendererPolicy.allowsNetworkRequests
            && !localRendererPolicy.allowsExternalNavigation
            && !localRendererPolicy.allowsDataURLs
            && !localRendererPolicy.allowsIFrames
            ? .satisfied
            : .blocked
    }

    public var satisfiesStageOneReleasePosture: Bool {
        appTransportSecurityStatus == .satisfied
            && privacyManifestStatus == .satisfied
            && backgroundModeStatus == .satisfied
            && richRendererStatus == .satisfied
    }
}

public enum MobilePlatform: String, CaseIterable, Equatable, Sendable {
    case android
    case iOS
}

public enum MobilePerformanceProfileKind: String, CaseIterable, Equatable, Sendable {
    case androidWatchCompact
    case androidLegacyEfficient
    case androidModernStandard
    case androidLargeScreen
    case iOSPhone12Standard
    case iOSMemoryConstrained
    case iOSTabletStandard
}

public struct MobilePerformanceProfile: Equatable, Sendable {
    public let platform: MobilePlatform
    public let kind: MobilePerformanceProfileKind
    public let keepsFileIOOffMainActor: Bool
    public let keepsParseAndSearchOffMainActor: Bool
    public let usesLazyBlockRendering: Bool
    public let disablesExpensiveAnimations: Bool
    public let boundsLocalImageDecode: Bool

    public init(
        platform: MobilePlatform,
        kind: MobilePerformanceProfileKind,
        keepsFileIOOffMainActor: Bool,
        keepsParseAndSearchOffMainActor: Bool,
        usesLazyBlockRendering: Bool,
        disablesExpensiveAnimations: Bool,
        boundsLocalImageDecode: Bool
    ) {
        self.platform = platform
        self.kind = kind
        self.keepsFileIOOffMainActor = keepsFileIOOffMainActor
        self.keepsParseAndSearchOffMainActor = keepsParseAndSearchOffMainActor
        self.usesLazyBlockRendering = usesLazyBlockRendering
        self.disablesExpensiveAnimations = disablesExpensiveAnimations
        self.boundsLocalImageDecode = boundsLocalImageDecode
    }

    public static let iOSPhone12Standard = MobilePerformanceProfile(
        platform: .iOS,
        kind: .iOSPhone12Standard,
        keepsFileIOOffMainActor: true,
        keepsParseAndSearchOffMainActor: true,
        usesLazyBlockRendering: true,
        disablesExpensiveAnimations: false,
        boundsLocalImageDecode: true
    )

    public static let iOSMemoryConstrained = MobilePerformanceProfile(
        platform: .iOS,
        kind: .iOSMemoryConstrained,
        keepsFileIOOffMainActor: true,
        keepsParseAndSearchOffMainActor: true,
        usesLazyBlockRendering: true,
        disablesExpensiveAnimations: true,
        boundsLocalImageDecode: true
    )

    public static let androidLegacyEfficient = MobilePerformanceProfile(
        platform: .android,
        kind: .androidLegacyEfficient,
        keepsFileIOOffMainActor: true,
        keepsParseAndSearchOffMainActor: true,
        usesLazyBlockRendering: true,
        disablesExpensiveAnimations: true,
        boundsLocalImageDecode: true
    )
}

public enum RichRendererBlockKind: String, CaseIterable, Equatable, Sendable {
    case mermaid
    case inlineMath
    case blockMath
}

public enum RichRendererDependencyKind: String, CaseIterable, Equatable, Sendable {
    case javascript
    case css
    case font
}

public enum RichRendererMode: String, CaseIterable, Equatable, Sendable {
    case nativeFallbackOnly
    case vendoredLocalBundle
}

public enum RichRendererPackagingStatus: String, CaseIterable, Equatable, Sendable {
    case notRequiredNativeFallback
    case packagedLocalAssets
    case missingLocalAssets
}

public struct LocalRichRendererAssetPolicy: Equatable, Sendable {
    public let mode: RichRendererMode
    public let allowedBlockKinds: Set<RichRendererBlockKind>
    public let allowedDependencyKinds: Set<RichRendererDependencyKind>
    public let bundleResourceRoot: String?
    public let allowsNetworkRequests: Bool
    public let allowsCDNResources: Bool
    public let allowsExternalNavigation: Bool
    public let allowsDataURLs: Bool
    public let allowsIFrames: Bool

    public init(
        mode: RichRendererMode = .nativeFallbackOnly,
        allowedBlockKinds: Set<RichRendererBlockKind> = [.mermaid, .inlineMath, .blockMath],
        allowedDependencyKinds: Set<RichRendererDependencyKind> = [],
        bundleResourceRoot: String? = nil,
        allowsNetworkRequests: Bool = false,
        allowsCDNResources: Bool = false,
        allowsExternalNavigation: Bool = false,
        allowsDataURLs: Bool = false,
        allowsIFrames: Bool = false
    ) {
        self.mode = mode
        self.allowedBlockKinds = allowedBlockKinds
        self.allowedDependencyKinds = allowedDependencyKinds
        self.bundleResourceRoot = bundleResourceRoot
        self.allowsNetworkRequests = allowsNetworkRequests
        self.allowsCDNResources = allowsCDNResources
        self.allowsExternalNavigation = allowsExternalNavigation
        self.allowsDataURLs = allowsDataURLs
        self.allowsIFrames = allowsIFrames
    }

    public static let nativeFallbackOnly = LocalRichRendererAssetPolicy()

    public static func vendoredLocalBundle(bundleResourceRoot: String) -> LocalRichRendererAssetPolicy {
        LocalRichRendererAssetPolicy(
            mode: .vendoredLocalBundle,
            allowedDependencyKinds: [.javascript, .css, .font],
            bundleResourceRoot: bundleResourceRoot
        )
    }
}

public struct LocalRichRendererRuntimeAudit: Equatable, Sendable {
    public let policy: LocalRichRendererAssetPolicy
    public let declaredAssetNames: [String]
    public static let allowedDeclaredAssetExtensions: Set<String> = [
        "js",
        "mjs",
        "css",
        "woff",
        "woff2",
        "ttf",
        "otf",
        "html",
        "htm"
    ]

    public init(
        policy: LocalRichRendererAssetPolicy = .nativeFallbackOnly,
        declaredAssetNames: [String] = []
    ) {
        self.policy = policy
        self.declaredAssetNames = declaredAssetNames
    }

    public var usesNativeFallbackOnly: Bool {
        policy.mode == .nativeFallbackOnly
    }

    public var requiresVendoredAssetPackaging: Bool {
        policy.mode == .vendoredLocalBundle
    }

    public var packagingStatus: RichRendererPackagingStatus {
        switch policy.mode {
        case .nativeFallbackOnly:
            return .notRequiredNativeFallback
        case .vendoredLocalBundle:
            guard policy.bundleResourceRoot?.isEmpty == false,
                  !declaredAssetNames.isEmpty,
                  declaredAssetNamesAreUnique,
                  declaredAssetNamesAreLocalBundleReferences else {
                return .missingLocalAssets
            }
            return .packagedLocalAssets
        }
    }

    public var declaredAssetNamesAreUnique: Bool {
        Set(declaredAssetNames).count == declaredAssetNames.count
    }

    public var declaredAssetNamesAreLocalBundleReferences: Bool {
        declaredAssetNames.allSatisfy(Self.isValidDeclaredRendererAssetName)
    }

    public var blocksAllNetworkAndNavigationSurfaces: Bool {
        !policy.allowsNetworkRequests
            && !policy.allowsCDNResources
            && !policy.allowsExternalNavigation
            && !policy.allowsDataURLs
            && !policy.allowsIFrames
    }

    public var canRenderStageOneRichBlocksOffline: Bool {
        blocksAllNetworkAndNavigationSurfaces
            && (
                packagingStatus == .notRequiredNativeFallback
                    || packagingStatus == .packagedLocalAssets
            )
    }

    private static func isValidDeclaredRendererAssetName(_ assetName: String) -> Bool {
        let trimmed = assetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed == assetName,
              !trimmed.hasPrefix("/"),
              !trimmed.hasPrefix("./"),
              !trimmed.contains("\\"),
              !trimmed.contains("://"),
              !trimmed.contains(":"),
              !trimmed.contains("?"),
              !trimmed.contains("#") else {
            return false
        }

        let segments = trimmed.split(separator: "/", omittingEmptySubsequences: false)
        guard !segments.isEmpty,
              segments.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else {
            return false
        }

        let fileName = String(segments.last ?? "")
        guard let extensionStart = fileName.lastIndex(of: ".") else {
            return false
        }

        let fileExtension = fileName[fileName.index(after: extensionStart)...].lowercased()
        return allowedDeclaredAssetExtensions.contains(String(fileExtension))
    }
}

public enum IOSRichRendererRequestContext: String, CaseIterable, Equatable, Sendable {
    case mainDocument
    case script
    case stylesheet
    case font
    case image
    case iframe
    case externalNavigation
}

public enum IOSRichRendererRequestDecisionKind: String, CaseIterable, Equatable, Sendable {
    case allowed
    case blocked
}

public enum IOSRichRendererRequestBlockReason: String, CaseIterable, Equatable, Sendable {
    case missingURL
    case dangerousScheme
    case remoteNetwork
    case remoteSubresource
    case externalNavigation
    case iframe
    case nonBundledFile
    case unsupportedRendererAssetType
    case unsupportedScheme
}

public struct IOSRichRendererRequestDecision: Equatable, Sendable {
    public let kind: IOSRichRendererRequestDecisionKind
    public let normalizedURLString: String?
    public let reason: IOSRichRendererRequestBlockReason?

    public init(
        kind: IOSRichRendererRequestDecisionKind,
        normalizedURLString: String?,
        reason: IOSRichRendererRequestBlockReason? = nil
    ) {
        self.kind = kind
        self.normalizedURLString = normalizedURLString
        self.reason = reason
    }
}

public struct IOSRichRendererRequestBlockingPolicy: Equatable, Sendable {
    public let bundledRendererRoot: URL

    public init(bundledRendererRoot: URL) {
        self.bundledRendererRoot = bundledRendererRoot.standardizedFileURL
    }

    public func decision(
        for requestedURL: URL?,
        context: IOSRichRendererRequestContext
    ) -> IOSRichRendererRequestDecision {
        guard let requestedURL else {
            return IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: nil,
                reason: .missingURL
            )
        }

        let normalizedURLString = requestedURL.absoluteString

        switch context {
        case .externalNavigation:
            return IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: normalizedURLString,
                reason: .externalNavigation
            )
        case .iframe:
            return IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: normalizedURLString,
                reason: .iframe
            )
        case .mainDocument, .script, .stylesheet, .font, .image:
            break
        }

        guard let scheme = requestedURL.scheme?.lowercased(), !scheme.isEmpty else {
            return IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: normalizedURLString,
                reason: .unsupportedScheme
            )
        }

        if scheme == "javascript" || scheme == "data" {
            return IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: normalizedURLString,
                reason: .dangerousScheme
            )
        }

        if scheme == "http" || scheme == "https" {
            return IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: normalizedURLString,
                reason: context == .mainDocument ? .remoteNetwork : .remoteSubresource
            )
        }

        guard scheme == "file" else {
            return IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: normalizedURLString,
                reason: .unsupportedScheme
            )
        }

        guard isBundledRendererFile(requestedURL) else {
            return IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: normalizedURLString,
                reason: .nonBundledFile
            )
        }

        guard supportsBundledRendererAssetType(requestedURL, context: context) else {
            return IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: normalizedURLString,
                reason: .unsupportedRendererAssetType
            )
        }

        return IOSRichRendererRequestDecision(
            kind: .allowed,
            normalizedURLString: normalizedURLString
        )
    }

    public func blocksAllStageOneForbiddenRequests(
        sampleRemoteURL: URL,
        sampleExternalNavigationURL: URL,
        sampleJavaScriptURL: URL,
        sampleDataURL: URL,
        sampleIframeURL: URL
    ) -> Bool {
        [
            decision(for: sampleRemoteURL, context: .script),
            decision(for: sampleExternalNavigationURL, context: .externalNavigation),
            decision(for: sampleJavaScriptURL, context: .mainDocument),
            decision(for: sampleDataURL, context: .image),
            decision(for: sampleIframeURL, context: .iframe)
        ].allSatisfy { $0.kind == .blocked }
    }

    private func isBundledRendererFile(_ requestedURL: URL) -> Bool {
        let requestedPath = requestedURL.standardizedFileURL.path
        let rootPath = bundledRendererRoot.path
        return requestedPath.hasPrefix(rootPath + "/")
    }

    private func supportsBundledRendererAssetType(
        _ requestedURL: URL,
        context: IOSRichRendererRequestContext
    ) -> Bool {
        let fileExtension = requestedURL.pathExtension.lowercased()

        switch context {
        case .mainDocument:
            return fileExtension == "html" || fileExtension == "htm"
        case .script:
            return fileExtension == "js" || fileExtension == "mjs"
        case .stylesheet:
            return fileExtension == "css"
        case .font:
            return ["woff", "woff2", "ttf", "otf"].contains(fileExtension)
        case .image:
            return ["png", "jpg", "jpeg", "gif", "webp"].contains(fileExtension)
        case .iframe, .externalNavigation:
            return false
        }
    }
}

public struct IOSValidationTarget: Equatable, Sendable {
    public let iPhone12: String
    public let iOS141: String

    public init(
        iPhone12: String = "iPhone 12 / 12 mini / 12 Pro / 12 Pro Max",
        iOS141: String = "iOS 14.1"
    ) {
        self.iPhone12 = iPhone12
        self.iOS141 = iOS141
    }
}
