import CryptoKit
import Foundation

public struct IOSParserContractAudit: Equatable, Sendable {
    public let document: MarkdownRenderDocument
    public let source: String

    public init(document: MarkdownRenderDocument, source: String) {
        self.document = document
        self.source = source
    }

    public var containsOnlyValidRanges: Bool {
        document.blocks.allSatisfy { block in
            block.sourceRange.isValid
                && block.sourceRange.startUTF8Offset >= 0
                && block.sourceRange.endUTF8Offset <= source.utf8.count
        }
    }

    public var sourceRangesAreMonotonic: Bool {
        zip(document.blocks, document.blocks.dropFirst()).allSatisfy { previous, next in
            previous.sourceRange.endUTF8Offset <= next.sourceRange.startUTF8Offset
        }
    }

    public var blockIDsAreUnique: Bool {
        Set(document.blocks.map(\.id)).count == document.blocks.count
    }

    public func includesRequiredKinds(_ kinds: Set<MarkdownRenderBlockKind>) -> Bool {
        Set(document.blocks.map(\.kind)).isSuperset(of: kinds)
    }

    public var satisfiesStageOneParserContract: Bool {
        !document.blocks.isEmpty
            && containsOnlyValidRanges
            && sourceRangesAreMonotonic
            && blockIDsAreUnique
            && document.sourceByteCount == source.utf8.count
    }
}

public struct IOSSourceRangeMappingAudit: Equatable, Sendable {
    public let source: String
    public let blocks: [MarkdownRenderBlock]

    public init(source: String, blocks: [MarkdownRenderBlock]) {
        self.source = source
        self.blocks = blocks
    }

    public var everyRangeMapsToNonEmptySourceSlice: Bool {
        blocks.allSatisfy { sourceSlice(for: $0)?.isEmpty == false }
    }

    public var everyMappedSliceMatchesRangeByteLength: Bool {
        blocks.allSatisfy { block in
            guard let slice = sourceSlice(for: block) else {
                return false
            }
            return slice.utf8.count == block.sourceRange.endUTF8Offset - block.sourceRange.startUTF8Offset
        }
    }

    public func sourceSlice(for block: MarkdownRenderBlock) -> String? {
        guard block.sourceRange.isValid,
              block.sourceRange.startUTF8Offset >= 0,
              block.sourceRange.endUTF8Offset <= source.utf8.count else {
            return nil
        }

        let utf8Start = source.utf8.index(
            source.utf8.startIndex,
            offsetBy: block.sourceRange.startUTF8Offset
        )
        let utf8End = source.utf8.index(
            source.utf8.startIndex,
            offsetBy: block.sourceRange.endUTF8Offset
        )

        guard let start = String.Index(utf8Start, within: source),
              let end = String.Index(utf8End, within: source) else {
            return nil
        }

        return String(source[start..<end])
    }

    public var satisfiesStageOneSourceRangeMapping: Bool {
        !blocks.isEmpty
            && everyRangeMapsToNonEmptySourceSlice
            && everyMappedSliceMatchesRangeByteLength
    }
}

public struct IOSRendererSnapshotSignature: Equatable, Sendable {
    public let themeScheme: IOSReaderThemeScheme
    public let fontTier: MobileFontTier
    public let lineCount: Int
    public let text: String

    public init(
        themeScheme: IOSReaderThemeScheme,
        fontTier: MobileFontTier,
        lineCount: Int,
        text: String
    ) {
        self.themeScheme = themeScheme
        self.fontTier = fontTier
        self.lineCount = lineCount
        self.text = text
    }
}

public struct IOSRendererSnapshotSignatureBuilder: Equatable, Sendable {
    public init() {}

    public func signature(
        source: String,
        themeScheme: IOSReaderThemeScheme,
        fontTier: MobileFontTier,
        parser: MarkdownParserAdapter = MarkdownParserAdapter(),
        renderer: MarkdownNativeRenderer = MarkdownNativeRenderer()
    ) -> IOSRendererSnapshotSignature {
        let document = parser.parse(source)
        let rendered = renderer.render(document: document, source: source)
        let typography = NativeMarkdownTypography(fontTier: fontTier)
        let tokens = IOSReaderSemanticColorTokens.tokens(for: themeScheme)
        let roleSummary = roleCounts(for: rendered)

        let text = [
            "fastmd-ios-renderer-snapshot-v1",
            "theme=\(themeScheme.rawValue)",
            "tier=\(fontTier.rawValue)",
            "body=\(format(fontTier.bodyPointSize))",
            "lineHeight=\(format(fontTier.lineHeightMultiple))",
            "heading1=\(format(typography.metrics(for: .heading1).pointSize))",
            "code=\(format(typography.metrics(for: .code).pointSize))",
            "background=\(tokens.background)",
            "primaryText=\(tokens.primaryText)",
            "blockCount=\(rendered.count)",
            "roles=\(roleSummary)",
            "headingLevels=\(rendered.compactMap(\.headingLevel).map(String.init).joined(separator: ","))",
            "horizontalOverflow=\(horizontalOverflowSummary(for: rendered))",
            "remoteImagesManualOpen=\(rendered.filter { $0.image?.isRemote == true && $0.image?.requiresManualOpenAction == true }.count)",
            "unsafeRemoteImageLoads=\(rendered.filter { $0.image?.isRemote == true && $0.image?.loadsAutomatically == true }.count)",
            "htmlBlocksSanitized=\(rendered.filter { $0.htmlFallback?.blocksExternalNavigation == true && $0.htmlFallback?.blocksRemoteSubresources == true }.count)",
            "richFallbacksNative=\(rendered.filter { $0.richFallback?.rendersAsNativeSafeCard == true }.count)"
        ].joined(separator: "\n")

        return IOSRendererSnapshotSignature(
            themeScheme: themeScheme,
            fontTier: fontTier,
            lineCount: text.split(separator: "\n").count,
            text: text + "\n"
        )
    }

    private func roleCounts(for blocks: [NativeMarkdownBlockPresentation]) -> String {
        NativeMarkdownBlockRole.allCases
            .map { role in
                "\(role.rawValue):\(blocks.filter { $0.role == role }.count)"
            }
            .joined(separator: ",")
    }

    private func horizontalOverflowSummary(for blocks: [NativeMarkdownBlockPresentation]) -> String {
        [
            "table:\(blocks.filter { $0.table?.scrollsHorizontallyWithinBlock == true }.count)",
            "code:\(blocks.filter { $0.codeBlock?.scrollsHorizontallyWithinBlock == true }.count)"
        ].joined(separator: ",")
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

public struct IOSLayoutSafetyAudit: Equatable, Sendable {
    public let lazyRenderingPolicy: IOSReaderLazyRenderingPolicy
    public let iconOnlyControlLabels: [IOSReaderAccessibilityControl: String]
    public let renderedBlocks: [NativeMarkdownBlockPresentation]
    public let minimumTappableControlDimension: Double

    public init(
        lazyRenderingPolicy: IOSReaderLazyRenderingPolicy,
        iconOnlyControlLabels: [IOSReaderAccessibilityControl: String],
        renderedBlocks: [NativeMarkdownBlockPresentation],
        minimumTappableControlDimension: Double = 44
    ) {
        self.lazyRenderingPolicy = lazyRenderingPolicy
        self.iconOnlyControlLabels = iconOnlyControlLabels
        self.renderedBlocks = renderedBlocks
        self.minimumTappableControlDimension = minimumTappableControlDimension
    }

    public var blocksWithPageLevelHorizontalOverflow: [MarkdownBlockID] {
        renderedBlocks.compactMap { block in
            switch block.role {
            case .table:
                return block.table?.scrollsHorizontallyWithinBlock == true ? nil : block.id
            case .codeFence:
                return block.codeBlock?.scrollsHorizontallyWithinBlock == true ? nil : block.id
            default:
                return nil
            }
        }
    }

    public var hasRequiredTappableControlSize: Bool {
        minimumTappableControlDimension >= 44
    }

    public var hasNoPageLevelHorizontalOverflow: Bool {
        blocksWithPageLevelHorizontalOverflow.isEmpty
    }

    public var hasNoKnownOverlapRisk: Bool {
        lazyRenderingPolicy.maxContentWidth > 0
            && lazyRenderingPolicy.maxContentWidth <= 760
            && Set(renderedBlocks.map(\.id)).count == renderedBlocks.count
    }

    public var iconOnlyControlsAreLabelled: Bool {
        IOSReaderAccessibilityControl.allCases.allSatisfy {
            iconOnlyControlLabels[$0]?.isEmpty == false
        }
    }

    public var satisfiesStageOneLayoutSafety: Bool {
        lazyRenderingPolicy.satisfiesStageOneLazyBlockRendering
            && hasRequiredTappableControlSize
            && hasNoPageLevelHorizontalOverflow
            && hasNoKnownOverlapRisk
            && iconOnlyControlsAreLabelled
    }
}

public struct IOSFileAccessAutomationAudit: Equatable, Sendable {
    public let loadedDocument: MarkdownLoadResult?
    public let readOnlySaveError: IOSDocumentSaveError?
    public let staleBookmarkResolution: IOSBookmarkResolution
    public let recentDocumentRecord: IOSRecentDocumentRecord?
    public let offMainExecution: IOSOffMainActorExecutionMetadata?

    public init(
        loadedDocument: MarkdownLoadResult?,
        readOnlySaveError: IOSDocumentSaveError?,
        staleBookmarkResolution: IOSBookmarkResolution,
        recentDocumentRecord: IOSRecentDocumentRecord?,
        offMainExecution: IOSOffMainActorExecutionMetadata?
    ) {
        self.loadedDocument = loadedDocument
        self.readOnlySaveError = readOnlySaveError
        self.staleBookmarkResolution = staleBookmarkResolution
        self.recentDocumentRecord = recentDocumentRecord
        self.offMainExecution = offMainExecution
    }

    public var opensReadableMarkdownDocument: Bool {
        loadedDocument?.source.isEmpty == false
            && loadedDocument?.handle.origin == .documentPicker
    }

    public var readOnlySaveFailsClosed: Bool {
        readOnlySaveError == .readOnlyDocument
    }

    public var staleBookmarkMapsToPermissionLost: Bool {
        staleBookmarkResolution == .permissionLost
    }

    public var recentDocumentStoresMetadataOnly: Bool {
        guard let recentDocumentRecord else {
            return false
        }

        let description = String(describing: recentDocumentRecord)
        return !description.contains("#")
            && !description.contains("Body")
            && recentDocumentRecord.bookmarkData.isEmpty == false
    }

    public var fileIOExecutesOffMainActor: Bool {
        offMainExecution?.stayedOffMainThread == true
    }

    public var satisfiesStageOneFileAccessTests: Bool {
        opensReadableMarkdownDocument
            && readOnlySaveFailsClosed
            && staleBookmarkMapsToPermissionLost
            && recentDocumentStoresMetadataOnly
            && fileIOExecutesOffMainActor
    }
}

public struct IOSSaveIntegrityAutomationAudit: Equatable, Sendable {
    public let bomPlan: IOSDocumentSavePlan?
    public let crlfPlan: IOSDocumentSavePlan?
    public let readOnlySaveError: IOSDocumentSaveError?
    public let unsupportedEncodingError: IOSDocumentSaveError?
    public let failedSaveError: IOSDocumentSaveError?
    public let externalMutationError: IOSDocumentSaveError?
    public let successfulSaveResult: IOSDocumentSaveResult?

    public init(
        bomPlan: IOSDocumentSavePlan?,
        crlfPlan: IOSDocumentSavePlan?,
        readOnlySaveError: IOSDocumentSaveError?,
        unsupportedEncodingError: IOSDocumentSaveError?,
        failedSaveError: IOSDocumentSaveError?,
        externalMutationError: IOSDocumentSaveError?,
        successfulSaveResult: IOSDocumentSaveResult?
    ) {
        self.bomPlan = bomPlan
        self.crlfPlan = crlfPlan
        self.readOnlySaveError = readOnlySaveError
        self.unsupportedEncodingError = unsupportedEncodingError
        self.failedSaveError = failedSaveError
        self.externalMutationError = externalMutationError
        self.successfulSaveResult = successfulSaveResult
    }

    public var preservesUTF8BOMWithoutDuplicateBOM: Bool {
        guard let bomPlan else {
            return false
        }

        return bomPlan.encoding == .utf8WithBOM
            && bomPlan.completeOutput.starts(with: [0xEF, 0xBB, 0xBF])
            && !bomPlan.completeOutput.dropFirst(3).starts(with: [0xEF, 0xBB, 0xBF])
    }

    public var preservesCRLFLineEndings: Bool {
        crlfPlan?.lineEnding == .crlf
            && crlfPlan?.normalizedSource.contains("\r\n") == true
            && crlfPlan?.normalizedSource.contains("\n\n") == false
    }

    public var rejectsReadOnlyAndUnsupportedEncoding: Bool {
        readOnlySaveError == .readOnlyDocument
            && unsupportedEncodingError == .unsupportedEncoding
    }

    public var writesCompleteOutputBeforeDestinationWrite: Bool {
        successfulSaveResult?.retainedDirtyBufferAfterFailure == nil
            && (successfulSaveResult?.byteCount ?? 0) > 0
    }

    public var keepsDirtyBufferAfterFailedSave: Bool {
        if case .writeFailed(let retainedDirtyBuffer) = failedSaveError {
            return !retainedDirtyBuffer.isEmpty
        }
        return false
    }

    public var detectsAndBlocksExternalMutation: Bool {
        if case .externalMutation(let retainedDirtyBuffer) = externalMutationError {
            return !retainedDirtyBuffer.isEmpty
        }
        return false
    }

    public var satisfiesStageOneSaveIntegrityTests: Bool {
        preservesUTF8BOMWithoutDuplicateBOM
            && preservesCRLFLineEndings
            && rejectsReadOnlyAndUnsupportedEncoding
            && writesCompleteOutputBeforeDestinationWrite
            && keepsDirtyBufferAfterFailedSave
            && detectsAndBlocksExternalMutation
    }
}

public struct IOSHostileMarkdownFixtureAudit: Equatable, Sendable {
    public let renderedBlocks: [NativeMarkdownBlockPresentation]

    public init(renderedBlocks: [NativeMarkdownBlockPresentation]) {
        self.renderedBlocks = renderedBlocks
    }

    public var htmlFallbacksBlockUnsafeSurfaces: Bool {
        let fallbacks = renderedBlocks.compactMap(\.htmlFallback)
        return !fallbacks.isEmpty
            && fallbacks.allSatisfy {
                $0.blocksExternalNavigation && $0.blocksRemoteSubresources
            }
    }

    public var sanitizedHTMLHasNoExecutableFragments: Bool {
        renderedBlocks
            .compactMap(\.htmlFallback)
            .map { $0.sanitizedText.lowercased() }
            .allSatisfy {
                !$0.contains("<script")
                    && !$0.contains("script>")
                    && !$0.contains("<iframe")
                    && !$0.contains("iframe>")
                    && !$0.contains("onerror")
                    && !$0.contains("onclick")
            }
    }

    public var dangerousLinksAreBlocked: Bool {
        let linkRuns = allInlineRuns.compactMap(\.linkDecision)
        let blockedDangerousLinks = linkRuns.filter { $0.reason == .dangerousScheme }
        return blockedDangerousLinks.count >= 3
            && blockedDangerousLinks.allSatisfy { $0.kind == .blocked }
    }

    public var safeWebLinksRequireConfirmation: Bool {
        allInlineRuns.contains {
            $0.linkDecision?.normalizedURLString == "https://example.com/safe"
                && $0.linkDecision?.kind == .confirm
        }
    }

    public var satisfiesStageOneMaliciousHTMLFixtureTests: Bool {
        htmlFallbacksBlockUnsafeSurfaces && sanitizedHTMLHasNoExecutableFragments
    }

    public var satisfiesStageOneMaliciousLinkFixtureTests: Bool {
        dangerousLinksAreBlocked && safeWebLinksRequireConfirmation
    }

    private var allInlineRuns: [NativeMarkdownInlineRun] {
        renderedBlocks.flatMap { block in
            block.inlineRuns
                + block.listItems.flatMap(\.inlineRuns)
                + block.blockquoteLines.flatMap(\.inlineRuns)
        }
    }
}

public struct IOSRemoteImagePrivacyAudit: Equatable, Sendable {
    public let renderedBlocks: [NativeMarkdownBlockPresentation]

    public init(renderedBlocks: [NativeMarkdownBlockPresentation]) {
        self.renderedBlocks = renderedBlocks
    }

    public var remoteImages: [NativeMarkdownImage] {
        renderedBlocks.compactMap(\.image).filter(\.isRemote)
    }

    public var remoteImagesAreManualOpenPlaceholders: Bool {
        !remoteImages.isEmpty
            && remoteImages.allSatisfy {
                !$0.loadsAutomatically
                    && $0.requiresManualOpenAction
                    && !$0.requiresBoundedLocalDecode
                    && $0.downsamplePolicy == nil
            }
    }

    public var remoteImageLinksAreBlockedAsResources: Bool {
        !remoteImages.isEmpty
            && remoteImages.allSatisfy {
                $0.linkDecision.kind == .blocked
                    && $0.linkDecision.reason == .remoteResourceDisabled
            }
    }

    public var satisfiesStageOneRemoteImagePrivacyTests: Bool {
        remoteImagesAreManualOpenPlaceholders && remoteImageLinksAreBlockedAsResources
    }
}

public enum IOSConditionalRendererGateStatus: String, CaseIterable, Equatable, Sendable {
    case notApplicableNativeFallback
    case requiredAndSatisfied
    case requiredButMissing
    case blockedUnsafeWKWebView

    public var isChecklistSatisfied: Bool {
        self == .notApplicableNativeFallback || self == .requiredAndSatisfied
    }
}

public struct IOSRendererAssetInventory: Equatable, Sendable {
    public static let rendererAssetFileExtensions: Set<String> = [
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

    public static let defaultInventoryCommand = "find ios \\( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \\) -prune -o -type f \\( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \\) -print | sort"

    public static let ignoredInventoryDirectoryPathPrefixes = [
        "ios/.build",
        "ios/.swiftpm",
        "ios/Tests",
        "ios/docs/reports",
        "ios/docs/screenshots"
    ]

    public let discoveredRendererAssetPaths: [String]
    public let discoveredRendererAssets: [IOSRendererAssetManifestEntry]
    public let declaredBundledRendererResourceRoots: [String]
    public let scannedSwiftFileCount: Int
    public let importsWebKitRichRendererCode: Bool

    public init(
        discoveredRendererAssetPaths: [String] = [],
        discoveredRendererAssets: [IOSRendererAssetManifestEntry] = [],
        declaredBundledRendererResourceRoots: [String] = [],
        scannedSwiftFileCount: Int = 0,
        importsWebKitRichRendererCode: Bool = false
    ) {
        let normalizedAssets = discoveredRendererAssets.sorted { $0.path < $1.path }
        self.discoveredRendererAssets = normalizedAssets
        self.discoveredRendererAssetPaths = Array(
            Set(discoveredRendererAssetPaths + normalizedAssets.map(\.path))
        ).sorted()
        self.declaredBundledRendererResourceRoots = Array(Set(
            declaredBundledRendererResourceRoots.map(Self.normalizedPlatformPath)
        )).sorted()
        self.scannedSwiftFileCount = max(0, scannedSwiftFileCount)
        self.importsWebKitRichRendererCode = importsWebKitRichRendererCode
    }

    public static func discover(
        iosRoot: URL,
        sourceRoot: URL? = nil,
        fileManager: FileManager = .default
    ) -> IOSRendererAssetInventory {
        let assets = discoverRendererAssets(
            iosRoot: iosRoot,
            fileManager: fileManager
        )
        let sourceScan = scanSourceForWebKitRichRendererCode(
            sourceRoot: sourceRoot
                ?? iosRoot.appendingPathComponent("Sources"),
            fileManager: fileManager
        )
        let declaredBundledRendererResourceRoots = discoverDeclaredBundledRendererResourceRoots(
            iosRoot: iosRoot,
            fileManager: fileManager
        )

        return IOSRendererAssetInventory(
            discoveredRendererAssets: assets,
            declaredBundledRendererResourceRoots: declaredBundledRendererResourceRoots,
            scannedSwiftFileCount: sourceScan.scannedSwiftFileCount,
            importsWebKitRichRendererCode: sourceScan.importsWebKitRichRendererCode
        )
    }

    public var provesNativeFallbackInventory: Bool {
        discoveredRendererAssetPaths.isEmpty
            && scannedSwiftFileCount > 0
            && !importsWebKitRichRendererCode
    }

    private static func discoverRendererAssets(
        iosRoot: URL,
        fileManager: FileManager
    ) -> [IOSRendererAssetManifestEntry] {
        guard let enumerator = fileManager.enumerator(
            at: iosRoot,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return enumerator.compactMap { item -> IOSRendererAssetManifestEntry? in
            guard let url = item as? URL,
                  let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey]) else {
                return nil
            }

            let platformPath = platformLocalPath(for: url, under: iosRoot)
            if values.isDirectory == true {
                if shouldPruneInventoryDirectory(platformPath) {
                    enumerator.skipDescendants()
                }
                return nil
            }

            guard rendererAssetFileExtensions.contains(url.pathExtension.lowercased()),
                  values.isRegularFile == true else {
                return nil
            }

            guard let data = try? Data(contentsOf: url) else {
                return nil
            }

            let entry = IOSRendererAssetManifestEntry(
                path: platformPath,
                byteCount: data.count,
                sha256Hex: sha256Hex(for: data)
            )
            return entry.isIgnoredValidationArtifactPath ? nil : entry
        }.sorted()
    }

    public static func sha256Hex(for data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private static func scanSourceForWebKitRichRendererCode(
        sourceRoot: URL,
        fileManager: FileManager
    ) -> (scannedSwiftFileCount: Int, importsWebKitRichRendererCode: Bool) {
        guard let enumerator = fileManager.enumerator(
            at: sourceRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (0, false)
        }

        var scannedSwiftFileCount = 0
        var importsWebKitRichRendererCode = false

        for item in enumerator {
            guard let url = item as? URL,
                  url.pathExtension == "swift",
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
                continue
            }

            scannedSwiftFileCount += 1
            guard let source = try? String(contentsOf: url, encoding: .utf8) else {
                continue
            }

            let scannableSource = sourceWithoutCommentsAndStringLiterals(source)
            let importsWebKit = scannableSource
                .split(whereSeparator: \.isNewline)
                .contains { importsWebRenderingFramework(line: String($0)) }
            let constructsWKWebView = constructsWebRenderingView(source: scannableSource)

            if importsWebKit || constructsWKWebView {
                importsWebKitRichRendererCode = true
            }
        }

        return (scannedSwiftFileCount, importsWebKitRichRendererCode)
    }

    private static func importsWebRenderingFramework(line: String) -> Bool {
        let tokens = line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        guard let importIndex = tokens.firstIndex(of: "import") else {
            return false
        }

        let scopedImportKinds = Set([
            "typealias",
            "class",
            "enum",
            "func",
            "let",
            "protocol",
            "struct",
            "var"
        ])
        let webRenderingModule = "Web" + "Kit"
        return tokens
            .dropFirst(importIndex + 1)
            .drop { token in
                token.hasPrefix("@") || scopedImportKinds.contains(token)
            }
            .contains { token in
                token == webRenderingModule || token.hasPrefix(webRenderingModule + ".")
            }
    }

    private static func constructsWebRenderingView(source: String) -> Bool {
        let viewTypeName = "WK" + "WebView"
        let pattern = "(?<![A-Za-z0-9_])\(viewTypeName)\\s*(?:\\(|\\.)"
        return source.range(
            of: pattern,
            options: [.regularExpression]
        ) != nil
    }

    private static func sourceWithoutCommentsAndStringLiterals(_ source: String) -> String {
        enum ScanState {
            case normal
            case lineComment
            case blockComment(depth: Int)
            case stringLiteral
            case multilineStringLiteral
            case rawStringLiteral(hashCount: Int)
            case rawMultilineStringLiteral(hashCount: Int)
        }

        var output = ""
        output.reserveCapacity(source.count)
        var index = source.startIndex
        var state = ScanState.normal

        func hasPrefix(_ prefix: String, at index: String.Index) -> Bool {
            source[index...].hasPrefix(prefix)
        }

        func appendMask(for text: String) {
            for character in text {
                output.append(character.isNewline ? character : " ")
            }
        }

        func advance(_ count: Int) {
            index = source.index(index, offsetBy: count)
        }

        func maskAndAdvance(_ count: Int) {
            let end = source.index(index, offsetBy: count)
            appendMask(for: String(source[index..<end]))
            index = end
        }

        func rawStringOpening(at index: String.Index) -> (hashCount: Int, isMultiline: Bool, length: Int)? {
            var cursor = index
            var hashCount = 0

            while cursor < source.endIndex, source[cursor] == "#" {
                hashCount += 1
                cursor = source.index(after: cursor)
            }

            guard hashCount > 0, cursor < source.endIndex else {
                return nil
            }

            if source[cursor...].hasPrefix("\"\"\"") {
                return (hashCount, true, hashCount + 3)
            }

            if source[cursor] == "\"" {
                return (hashCount, false, hashCount + 1)
            }

            return nil
        }

        func rawStringTerminator(quoteCount: Int, hashCount: Int, at index: String.Index) -> Bool {
            let quotes = String(repeating: "\"", count: quoteCount)
            let hashes = String(repeating: "#", count: hashCount)
            guard source[index...].hasPrefix(quotes) else {
                return false
            }

            let hashStart = source.index(index, offsetBy: quoteCount)
            return source[hashStart...].hasPrefix(hashes)
        }

        while index < source.endIndex {
            switch state {
            case .normal:
                if let opening = rawStringOpening(at: index) {
                    maskAndAdvance(opening.length)
                    state = opening.isMultiline
                        ? .rawMultilineStringLiteral(hashCount: opening.hashCount)
                        : .rawStringLiteral(hashCount: opening.hashCount)
                } else if hasPrefix("//", at: index) {
                    appendMask(for: "//")
                    advance(2)
                    state = .lineComment
                } else if hasPrefix("/*", at: index) {
                    appendMask(for: "/*")
                    advance(2)
                    state = .blockComment(depth: 1)
                } else if hasPrefix("\"\"\"", at: index) {
                    appendMask(for: "\"\"\"")
                    advance(3)
                    state = .multilineStringLiteral
                } else if source[index] == "\"" {
                    output.append(" ")
                    index = source.index(after: index)
                    state = .stringLiteral
                } else {
                    output.append(source[index])
                    index = source.index(after: index)
                }

            case .rawStringLiteral(let hashCount):
                if rawStringTerminator(quoteCount: 1, hashCount: hashCount, at: index) {
                    maskAndAdvance(1 + hashCount)
                    state = .normal
                } else {
                    let character = source[index]
                    output.append(character.isNewline ? character : " ")
                    index = source.index(after: index)
                    if character.isNewline {
                        state = .normal
                    }
                }

            case .rawMultilineStringLiteral(let hashCount):
                if rawStringTerminator(quoteCount: 3, hashCount: hashCount, at: index) {
                    maskAndAdvance(3 + hashCount)
                    state = .normal
                } else {
                    let character = source[index]
                    output.append(character.isNewline ? character : " ")
                    index = source.index(after: index)
                }

            case .lineComment:
                let character = source[index]
                output.append(character.isNewline ? character : " ")
                index = source.index(after: index)
                if character.isNewline {
                    state = .normal
                }

            case .blockComment(let depth):
                if hasPrefix("/*", at: index) {
                    appendMask(for: "/*")
                    advance(2)
                    state = .blockComment(depth: depth + 1)
                } else if hasPrefix("*/", at: index) {
                    appendMask(for: "*/")
                    advance(2)
                    state = depth == 1 ? .normal : .blockComment(depth: depth - 1)
                } else {
                    let character = source[index]
                    output.append(character.isNewline ? character : " ")
                    index = source.index(after: index)
                }

            case .stringLiteral:
                if hasPrefix("\\\"", at: index) || hasPrefix("\\\\", at: index) {
                    appendMask(for: String(source[index..<source.index(index, offsetBy: 2)]))
                    advance(2)
                } else {
                    let character = source[index]
                    output.append(character.isNewline ? character : " ")
                    index = source.index(after: index)
                    if character == "\"" || character.isNewline {
                        state = .normal
                    }
                }

            case .multilineStringLiteral:
                if hasPrefix("\"\"\"", at: index) {
                    appendMask(for: "\"\"\"")
                    advance(3)
                    state = .normal
                } else {
                    let character = source[index]
                    output.append(character.isNewline ? character : " ")
                    index = source.index(after: index)
                }
            }
        }

        return output
    }

    private static func platformLocalPath(for url: URL, under iosRoot: URL) -> String {
        let rootPath = iosRoot.standardizedFileURL.path
        let filePath = url.standardizedFileURL.path
        let relativePath = filePath.hasPrefix(rootPath + "/")
            ? String(filePath.dropFirst(rootPath.count + 1))
            : url.lastPathComponent
        return "ios/" + relativePath
    }

    private static func shouldPruneInventoryDirectory(_ platformPath: String) -> Bool {
        ignoredInventoryDirectoryPathPrefixes.contains { prefix in
            platformPath == prefix || platformPath.hasPrefix(prefix + "/")
        }
    }

    private static func discoverDeclaredBundledRendererResourceRoots(
        iosRoot: URL,
        fileManager: FileManager
    ) -> [String] {
        let manifestURL = iosRoot.appendingPathComponent("Package.swift")
        guard let manifestText = try? String(contentsOf: manifestURL, encoding: .utf8) else {
            return []
        }
        let manifestWithoutComments = swiftSourceWithoutComments(manifestText)

        let pattern = #"\.(?:process|copy)\(\s*"([^"]+)""#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let range = NSRange(
            manifestWithoutComments.startIndex..<manifestWithoutComments.endIndex,
            in: manifestWithoutComments
        )
        let matches = expression.matches(in: manifestWithoutComments, range: range)
        return Array(Set(matches.flatMap { match -> [String] in
            guard let rawRange = Range(match.range(at: 1), in: manifestWithoutComments) else {
                return []
            }
            return expandedBundledRendererResourceRoots(for: String(manifestWithoutComments[rawRange]))
        })).sorted()
    }

    private static func swiftSourceWithoutComments(_ source: String) -> String {
        enum ScanState {
            case normal
            case lineComment
            case blockComment(depth: Int)
            case stringLiteral
            case multilineStringLiteral
        }

        var output = ""
        output.reserveCapacity(source.count)
        var index = source.startIndex
        var state = ScanState.normal

        func hasPrefix(_ prefix: String, at index: String.Index) -> Bool {
            source[index...].hasPrefix(prefix)
        }

        func appendMask(for text: String) {
            for character in text {
                output.append(character.isNewline ? character : " ")
            }
        }

        func appendAndAdvance(_ count: Int) {
            let end = source.index(index, offsetBy: count)
            output.append(contentsOf: source[index..<end])
            index = end
        }

        func maskAndAdvance(_ count: Int) {
            let end = source.index(index, offsetBy: count)
            appendMask(for: String(source[index..<end]))
            index = end
        }

        while index < source.endIndex {
            switch state {
            case .normal:
                if hasPrefix("//", at: index) {
                    maskAndAdvance(2)
                    state = .lineComment
                } else if hasPrefix("/*", at: index) {
                    maskAndAdvance(2)
                    state = .blockComment(depth: 1)
                } else if hasPrefix("\"\"\"", at: index) {
                    appendAndAdvance(3)
                    state = .multilineStringLiteral
                } else if source[index] == "\"" {
                    output.append(source[index])
                    index = source.index(after: index)
                    state = .stringLiteral
                } else {
                    output.append(source[index])
                    index = source.index(after: index)
                }

            case .lineComment:
                let character = source[index]
                output.append(character.isNewline ? character : " ")
                index = source.index(after: index)
                if character.isNewline {
                    state = .normal
                }

            case .blockComment(let depth):
                if hasPrefix("/*", at: index) {
                    maskAndAdvance(2)
                    state = .blockComment(depth: depth + 1)
                } else if hasPrefix("*/", at: index) {
                    maskAndAdvance(2)
                    state = depth == 1 ? .normal : .blockComment(depth: depth - 1)
                } else {
                    let character = source[index]
                    output.append(character.isNewline ? character : " ")
                    index = source.index(after: index)
                }

            case .stringLiteral:
                if hasPrefix("\\\"", at: index) || hasPrefix("\\\\", at: index) {
                    appendAndAdvance(2)
                } else {
                    let character = source[index]
                    output.append(character)
                    index = source.index(after: index)
                    if character == "\"" || character.isNewline {
                        state = .normal
                    }
                }

            case .multilineStringLiteral:
                if hasPrefix("\"\"\"", at: index) {
                    appendAndAdvance(3)
                    state = .normal
                } else {
                    output.append(source[index])
                    index = source.index(after: index)
                }
            }
        }

        return output
    }

    private static func expandedBundledRendererResourceRoots(for resourcePath: String) -> [String] {
        let normalized = normalizedPlatformPath(resourcePath)
        guard normalized.contains("FastMDRenderers") else {
            return []
        }

        if normalized.hasPrefix("ios/") {
            return [normalized]
        }

        if normalized.hasPrefix("Resources/") {
            return [
                "ios/Sources/FastMDMobile/" + normalized,
                "ios/Sources/FastMDMobileCore/" + normalized
            ].map(normalizedPlatformPath)
        }

        if normalized.hasPrefix("Sources/") {
            return ["ios/" + normalized].map(normalizedPlatformPath)
        }

        return []
    }

    private static func normalizedPlatformPath(_ path: String) -> String {
        path
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/", omittingEmptySubsequences: true)
            .joined(separator: "/")
    }
}

public struct IOSRendererAssetManifestEntry: Equatable, Sendable, Comparable {
    public static let bundledRendererResourcePathPrefixes = [
        "ios/Resources/FastMDRenderers/",
        "ios/Sources/FastMDMobile/Resources/FastMDRenderers/",
        "ios/Sources/FastMDMobileCore/Resources/FastMDRenderers/"
    ]

    public static let ignoredValidationArtifactPathPrefixes = [
        "ios/.build/",
        "ios/docs/reports/",
        "ios/docs/screenshots/"
    ]

    public let path: String
    public let byteCount: Int
    public let sha256Hex: String

    public init(path: String, byteCount: Int, sha256Hex: String) {
        self.path = path
        self.byteCount = max(0, byteCount)
        self.sha256Hex = sha256Hex.lowercased()
    }

    public static func < (
        lhs: IOSRendererAssetManifestEntry,
        rhs: IOSRendererAssetManifestEntry
    ) -> Bool {
        lhs.path < rhs.path
    }

    public var isPlatformLocalIOSPath: Bool {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        return path.hasPrefix("ios/")
            && !path.contains("://")
            && !path.contains("..")
            && !path.contains("\\")
            && !path.contains("?")
            && !path.contains("#")
            && path == trimmedPath
            && !path.contains { $0.isWhitespace }
    }

    public var isBundledRendererResourcePath: Bool {
        isPlatformLocalIOSPath && Self.bundledRendererResourcePathPrefixes.contains { prefix in
            path.hasPrefix(prefix)
        }
    }

    public var isIgnoredValidationArtifactPath: Bool {
        Self.ignoredValidationArtifactPathPrefixes.contains { prefix in
            path.hasPrefix(prefix)
        }
    }

    public var hasValidSHA256Hex: Bool {
        sha256Hex.count == 64
            && sha256Hex.allSatisfy { character in
                ("0"..."9").contains(character) || ("a"..."f").contains(character)
            }
    }

    public var hasPositiveByteCount: Bool {
        byteCount > 0
    }
}

public struct IOSRendererAssetInventoryCommandParityAudit: Equatable, Sendable {
    public let inventory: IOSRendererAssetInventory
    public let documentedCommand: String
    public let documentedCommandPaths: [String]

    public init(
        inventory: IOSRendererAssetInventory,
        documentedCommand: String = IOSRendererAssetInventory.defaultInventoryCommand,
        documentedCommandPaths: [String]
    ) {
        self.inventory = inventory
        self.documentedCommand = documentedCommand
        self.documentedCommandPaths = Array(Set(
            documentedCommandPaths.map(Self.normalizedCommandPath)
        )).sorted()
    }

    public var documentedCommandMatchesInventoryContract: Bool {
        documentedCommand == IOSRendererAssetInventory.defaultInventoryCommand
            && documentedCommand.contains("-iname '*.js'")
            && documentedCommand.contains("-iname '*.mjs'")
            && documentedCommand.contains("-iname '*.css'")
            && documentedCommand.contains("-iname '*.woff2'")
            && documentedCommand.contains("-iname '*.html'")
            && documentedCommand.contains("-path 'ios/Tests'")
            && documentedCommand.contains("-path 'ios/docs/reports'")
            && documentedCommand.contains("-path 'ios/docs/screenshots'")
    }

    public var commandPathsExactlyMatchSwiftDiscovery: Bool {
        documentedCommandPaths == inventory.discoveredRendererAssetPaths
    }

    public var commandPathsStayIOSLocal: Bool {
        documentedCommandPaths.allSatisfy { path in
            IOSRendererAssetManifestEntry(
                path: path,
                byteCount: 1,
                sha256Hex: String(repeating: "0", count: 64)
            ).isPlatformLocalIOSPath
        }
    }

    public var commandPathsExcludeIgnoredValidationArtifacts: Bool {
        documentedCommandPaths.allSatisfy { path in
            !IOSRendererAssetManifestEntry(
                path: path,
                byteCount: 1,
                sha256Hex: String(repeating: "0", count: 64)
            ).isIgnoredValidationArtifactPath
        }
    }

    public var satisfiesStageOneInventoryCommandParity: Bool {
        documentedCommandMatchesInventoryContract
            && commandPathsExactlyMatchSwiftDiscovery
            && commandPathsStayIOSLocal
            && commandPathsExcludeIgnoredValidationArtifacts
    }

    private static func normalizedCommandPath(_ path: String) -> String {
        path
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/", omittingEmptySubsequences: true)
            .joined(separator: "/")
    }
}

public struct IOSRendererAssetManifestHashAudit: Equatable, Sendable {
    public let discoveredAssets: [IOSRendererAssetManifestEntry]
    public let manifestEntries: [IOSRendererAssetManifestEntry]

    public init(
        discoveredAssets: [IOSRendererAssetManifestEntry],
        manifestEntries: [IOSRendererAssetManifestEntry]
    ) {
        self.discoveredAssets = discoveredAssets.sorted()
        self.manifestEntries = manifestEntries.sorted()
    }

    public var hasDiscoveredRendererAssets: Bool {
        !discoveredAssets.isEmpty
    }

    public var manifestPathsExactlyMatchDiscoveredAssets: Bool {
        discoveredAssets.map(\.path) == manifestEntries.map(\.path)
    }

    public var manifestHasNoDuplicatePaths: Bool {
        Set(manifestEntries.map(\.path)).count == manifestEntries.count
    }

    public var allAssetsStayPlatformLocal: Bool {
        (discoveredAssets + manifestEntries).allSatisfy(\.isPlatformLocalIOSPath)
    }

    public var allAssetsUseBundledRendererResourcePaths: Bool {
        (discoveredAssets + manifestEntries).allSatisfy(\.isBundledRendererResourcePath)
    }

    public var allManifestEntriesHaveValidHashesAndByteCounts: Bool {
        manifestEntries.allSatisfy {
            $0.hasValidSHA256Hex && $0.hasPositiveByteCount
        }
    }

    public var manifestHashesMatchDiscoveredAssets: Bool {
        discoveredAssets == manifestEntries
    }

    public var satisfiesStageOneManifestHashVerification: Bool {
        hasDiscoveredRendererAssets
            && manifestHasNoDuplicatePaths
            && manifestPathsExactlyMatchDiscoveredAssets
            && allAssetsStayPlatformLocal
            && allAssetsUseBundledRendererResourcePaths
            && allManifestEntriesHaveValidHashesAndByteCounts
            && manifestHashesMatchDiscoveredAssets
    }

    public var failureReasons: [String] {
        [
            hasDiscoveredRendererAssets ? nil : "no discovered renderer assets",
            manifestHasNoDuplicatePaths ? nil : "duplicate manifest paths",
            manifestPathsExactlyMatchDiscoveredAssets ? nil : "manifest paths do not exactly match discovered assets",
            allAssetsStayPlatformLocal ? nil : "asset paths are not iOS-local",
            allAssetsUseBundledRendererResourcePaths ? nil : "assets are outside bundled FastMDRenderers resources",
            allManifestEntriesHaveValidHashesAndByteCounts ? nil : "manifest entries have invalid SHA-256 hashes or byte counts",
            manifestHashesMatchDiscoveredAssets ? nil : "manifest hashes or byte counts do not match discovered assets"
        ].compactMap { $0 }
    }
}

public struct IOSRendererBundleResourceDeclarationAudit: Equatable, Sendable {
    public let discoveredAssets: [IOSRendererAssetManifestEntry]
    public let declaredBundledRendererResourceRoots: [String]

    public init(
        discoveredAssets: [IOSRendererAssetManifestEntry],
        declaredBundledRendererResourceRoots: [String]
    ) {
        self.discoveredAssets = discoveredAssets.sorted()
        self.declaredBundledRendererResourceRoots = Array(Set(
            declaredBundledRendererResourceRoots.map(Self.normalizedRootPath)
        )).sorted()
    }

    public var hasDiscoveredRendererAssets: Bool {
        !discoveredAssets.isEmpty
    }

    public var requiredBundledRendererResourceRoots: [String] {
        Array(Set(discoveredAssets.compactMap(Self.requiredRootPath))).sorted()
    }

    public var allDiscoveredAssetsAreUnderKnownBundledRoots: Bool {
        discoveredAssets.allSatisfy { Self.requiredRootPath(for: $0) != nil }
    }

    public var declaredRootsCoverDiscoveredAssets: Bool {
        discoveredAssets.allSatisfy { asset in
            declaredBundledRendererResourceRoots.contains { root in
                asset.path == root || asset.path.hasPrefix(root + "/")
            }
        }
    }

    public var satisfiesStageOneBundleResourceDeclaration: Bool {
        guard hasDiscoveredRendererAssets else {
            return true
        }

        return allDiscoveredAssetsAreUnderKnownBundledRoots
            && !requiredBundledRendererResourceRoots.isEmpty
            && declaredRootsCoverDiscoveredAssets
    }

    public var failureReasons: [String] {
        [
            hasDiscoveredRendererAssets ? nil : "no discovered renderer assets",
            allDiscoveredAssetsAreUnderKnownBundledRoots ? nil : "renderer assets are outside known bundled FastMDRenderers roots",
            declaredRootsCoverDiscoveredAssets ? nil : "Package.swift resource declarations do not cover discovered renderer assets"
        ].compactMap { $0 }
    }

    private static func requiredRootPath(for asset: IOSRendererAssetManifestEntry) -> String? {
        IOSRendererAssetManifestEntry.bundledRendererResourcePathPrefixes
            .map { String($0.dropLast($0.hasSuffix("/") ? 1 : 0)) }
            .first { asset.path == $0 || asset.path.hasPrefix($0 + "/") }
    }

    private static func normalizedRootPath(_ path: String) -> String {
        path
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\", with: "/")
            .split(separator: "/", omittingEmptySubsequences: true)
            .joined(separator: "/")
    }
}

public struct IOSConditionalRendererChecklistEvidence: Equatable, Sendable {
    public struct Item: Equatable, Sendable {
        public let blueprintChecklistText: String
        public let status: IOSConditionalRendererGateStatus
        public let checklistSatisfied: Bool
        public let evidenceSummary: String

        public init(
            blueprintChecklistText: String,
            status: IOSConditionalRendererGateStatus,
            checklistSatisfied: Bool,
            evidenceSummary: String
        ) {
            self.blueprintChecklistText = blueprintChecklistText
            self.status = status
            self.checklistSatisfied = checklistSatisfied
            self.evidenceSummary = evidenceSummary
        }
    }

    public let localRendererPackagingOfflineStatus: IOSConditionalRendererGateStatus
    public let wkWebViewRequestBlockingStatus: IOSConditionalRendererGateStatus
    public let rendererAssetManifestHashStatus: IOSConditionalRendererGateStatus
    public let usesVendoredRendererAssets: Bool
    public let usesWKWebViewRichSurface: Bool
    public let discoveredRendererAssetPaths: [String]

    public init(
        localRendererPackagingOfflineStatus: IOSConditionalRendererGateStatus,
        wkWebViewRequestBlockingStatus: IOSConditionalRendererGateStatus,
        rendererAssetManifestHashStatus: IOSConditionalRendererGateStatus,
        usesVendoredRendererAssets: Bool,
        usesWKWebViewRichSurface: Bool,
        discoveredRendererAssetPaths: [String]
    ) {
        self.localRendererPackagingOfflineStatus = localRendererPackagingOfflineStatus
        self.wkWebViewRequestBlockingStatus = wkWebViewRequestBlockingStatus
        self.rendererAssetManifestHashStatus = rendererAssetManifestHashStatus
        self.usesVendoredRendererAssets = usesVendoredRendererAssets
        self.usesWKWebViewRichSurface = usesWKWebViewRichSurface
        self.discoveredRendererAssetPaths = discoveredRendererAssetPaths.sorted()
    }

    public var localRendererPackagingOfflineGateSatisfied: Bool {
        localRendererPackagingOfflineStatus.isChecklistSatisfied
    }

    public var wkWebViewRequestBlockingGateSatisfied: Bool {
        wkWebViewRequestBlockingStatus.isChecklistSatisfied
    }

    public var rendererAssetManifestHashGateSatisfied: Bool {
        rendererAssetManifestHashStatus.isChecklistSatisfied
    }

    public var allConditionalRendererGatesSatisfied: Bool {
        localRendererPackagingOfflineGateSatisfied
            && wkWebViewRequestBlockingGateSatisfied
            && rendererAssetManifestHashGateSatisfied
    }

    public var checklistItems: [Item] {
        [
            Item(
                blueprintChecklistText: "Add local renderer packaging/offline tests if JS renderer assets are used.",
                status: localRendererPackagingOfflineStatus,
                checklistSatisfied: localRendererPackagingOfflineGateSatisfied,
                evidenceSummary: localRendererPackagingOfflineStatus == .notApplicableNativeFallback
                    ? "No JS/CSS/font/HTML renderer assets are present; native rich fallback cards keep the gate not applicable."
                    : "Vendored renderer assets require local packaging/offline validation."
            ),
            Item(
                blueprintChecklistText: "Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.",
                status: wkWebViewRequestBlockingStatus,
                checklistSatisfied: wkWebViewRequestBlockingGateSatisfied,
                evidenceSummary: wkWebViewRequestBlockingStatus == .notApplicableNativeFallback
                    ? "No WKWebView rich surface is active; native rich fallback cards keep the gate not applicable."
                    : "WKWebView rich surfaces require request and navigation blocking validation."
            ),
            Item(
                blueprintChecklistText: "Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.",
                status: rendererAssetManifestHashStatus,
                checklistSatisfied: rendererAssetManifestHashGateSatisfied,
                evidenceSummary: rendererAssetManifestHashStatus == .notApplicableNativeFallback
                    ? "No vendored renderer assets are discovered, so no asset manifest/hash lock is required."
                    : "Discovered renderer assets require exact platform-local manifest and SHA-256 verification."
            )
        ]
    }

    public var nativeFallbackNotApplicableReason: String? {
        guard !usesVendoredRendererAssets,
              !usesWKWebViewRichSurface,
              discoveredRendererAssetPaths.isEmpty,
              allConditionalRendererGatesSatisfied else {
            return nil
        }
        return "iOS renders rich Markdown fallback blocks as native safe cards; no JS/CSS/font assets or WKWebView rich surface are present."
    }

    public var capturesSatisfiedRendererModeEvidence: Bool {
        if nativeFallbackNotApplicableReason != nil {
            return true
        }

        let vendoredAssetsAreAccountedFor = !usesVendoredRendererAssets
            || (
                !discoveredRendererAssetPaths.isEmpty
                    && localRendererPackagingOfflineStatus == .requiredAndSatisfied
                    && rendererAssetManifestHashStatus == .requiredAndSatisfied
            )
        let wkWebViewSurfaceIsAccountedFor = !usesWKWebViewRichSurface
            || wkWebViewRequestBlockingStatus == .requiredAndSatisfied

        return allConditionalRendererGatesSatisfied
            && vendoredAssetsAreAccountedFor
            && wkWebViewSurfaceIsAccountedFor
    }

    public var supervisorCompletionRecommendations: [String] {
        checklistItems
            .filter(\.checklistSatisfied)
            .map(\.blueprintChecklistText)
    }
}

public struct IOSConditionalRendererGateReport: Equatable, Sendable {
    public let generatedAt: Date
    public let evidence: IOSConditionalRendererChecklistEvidence
    public let importsWebKitRichRendererCode: Bool
    public let rendererAssetInventoryCommand: String
    public let declaredBundledRendererResourceRoots: [String]
    public let scannedSwiftFileCount: Int

    public init(
        generatedAt: Date,
        evidence: IOSConditionalRendererChecklistEvidence,
        importsWebKitRichRendererCode: Bool,
        rendererAssetInventoryCommand: String,
        declaredBundledRendererResourceRoots: [String] = [],
        scannedSwiftFileCount: Int = 0
    ) {
        self.generatedAt = generatedAt
        self.evidence = evidence
        self.importsWebKitRichRendererCode = importsWebKitRichRendererCode
        self.rendererAssetInventoryCommand = rendererAssetInventoryCommand
        self.declaredBundledRendererResourceRoots = declaredBundledRendererResourceRoots.sorted()
        self.scannedSwiftFileCount = max(0, scannedSwiftFileCount)
    }

    public init(
        generatedAt: Date,
        evidence: IOSConditionalRendererChecklistEvidence,
        inventory: IOSRendererAssetInventory,
        rendererAssetInventoryCommand: String = IOSRendererAssetInventory.defaultInventoryCommand
    ) {
        self.init(
            generatedAt: generatedAt,
            evidence: evidence,
            importsWebKitRichRendererCode: inventory.importsWebKitRichRendererCode,
            rendererAssetInventoryCommand: rendererAssetInventoryCommand,
            declaredBundledRendererResourceRoots: inventory.declaredBundledRendererResourceRoots,
            scannedSwiftFileCount: inventory.scannedSwiftFileCount
        )
    }

    public var capturesConditionalRendererGateEvidence: Bool {
        evidence.allConditionalRendererGatesSatisfied
            && evidence.capturesSatisfiedRendererModeEvidence
            && importsWebKitRichRendererCode == evidence.usesWKWebViewRichSurface
            && scannedSwiftFileCount > 0
    }

    public var markdown: String {
        let assetPaths = evidence.discoveredRendererAssetPaths.isEmpty
            ? "none"
            : evidence.discoveredRendererAssetPaths.joined(separator: ", ")
        let resourceRoots = declaredBundledRendererResourceRoots.isEmpty
            ? "none"
            : declaredBundledRendererResourceRoots.joined(separator: ", ")
        let reason = evidence.nativeFallbackNotApplicableReason ?? "conditional renderer assets or WKWebView rich surface require additional validation"

        return [
            "# Stage 1 iOS Conditional Renderer Gate Report",
            "",
            "- Generated: \(iso8601String(from: generatedAt))",
            "- Uses vendored renderer assets: \(evidence.usesVendoredRendererAssets)",
            "- Uses WKWebView rich surface: \(evidence.usesWKWebViewRichSurface)",
            "- Imports WebKit rich renderer code: \(importsWebKitRichRendererCode)",
            "- Scanned Swift source files: \(scannedSwiftFileCount)",
            "- Renderer asset inventory command: \(safeText(rendererAssetInventoryCommand))",
            "- Discovered renderer asset paths: \(safeText(assetPaths))",
            "- Declared bundled renderer resource roots: \(safeText(resourceRoots))",
            "- Native fallback reason: \(safeText(reason))",
            "",
            "| Gate | Status | Checklist satisfied |",
            "| --- | --- | --- |",
            "| local renderer packaging/offline | \(evidence.localRendererPackagingOfflineStatus.rawValue) | \(evidence.localRendererPackagingOfflineGateSatisfied) |",
            "| WKWebView request blocking | \(evidence.wkWebViewRequestBlockingStatus.rawValue) | \(evidence.wkWebViewRequestBlockingGateSatisfied) |",
            "| renderer asset manifest/hash | \(evidence.rendererAssetManifestHashStatus.rawValue) | \(evidence.rendererAssetManifestHashGateSatisfied) |",
            "",
            "## Supervisor Completion Recommendations",
            "",
            evidence.supervisorCompletionRecommendations.isEmpty
                ? "- None."
                : evidence.supervisorCompletionRecommendations
                    .map { "- \(safeText($0))" }
                    .joined(separator: "\n"),
            "",
            "| Blueprint checklist item | Status | Checklist satisfied | Evidence |",
            "| --- | --- | --- | --- |",
            evidence.checklistItems.map { item in
                "| \(safeText(item.blueprintChecklistText)) | \(item.status.rawValue) | \(item.checklistSatisfied) | \(safeText(item.evidenceSummary)) |"
            }.joined(separator: "\n")
        ].joined(separator: "\n") + "\n"
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private func safeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "/")
    }
}

public struct IOSLocalRendererConditionalGateAudit: Equatable, Sendable {
    public let runtimeAudit: LocalRichRendererRuntimeAudit
    public let releasePosture: IOSReleaseSecurityPosture
    public let renderedBlocks: [NativeMarkdownBlockPresentation]
    public let discoveredRendererAssetPaths: [String]
    public let rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit?
    public let rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit?
    public let wkWebViewRequestBlockingPolicy: IOSRichRendererRequestBlockingPolicy?

    public init(
        runtimeAudit: LocalRichRendererRuntimeAudit = LocalRichRendererRuntimeAudit(),
        releasePosture: IOSReleaseSecurityPosture = IOSReleaseSecurityPosture(),
        renderedBlocks: [NativeMarkdownBlockPresentation],
        discoveredRendererAssetPaths: [String] = [],
        rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit? = nil,
        rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit? = nil,
        wkWebViewRequestBlockingPolicy: IOSRichRendererRequestBlockingPolicy? = nil
    ) {
        self.runtimeAudit = runtimeAudit
        self.releasePosture = releasePosture
        self.renderedBlocks = renderedBlocks
        self.discoveredRendererAssetPaths = discoveredRendererAssetPaths.sorted()
        self.rendererAssetManifestHashAudit = rendererAssetManifestHashAudit
        self.rendererBundleResourceDeclarationAudit = rendererBundleResourceDeclarationAudit
        self.wkWebViewRequestBlockingPolicy = wkWebViewRequestBlockingPolicy
    }

    public var usesVendoredRendererAssets: Bool {
        runtimeAudit.requiresVendoredAssetPackaging
            || !discoveredRendererAssetPaths.isEmpty
            || renderedBlocks.contains { $0.richFallback?.requiresVendoredRendererAssets == true }
    }

    public var usesWKWebViewRichSurface: Bool {
        releasePosture.usesWKWebViewRichRendering
            || renderedBlocks.contains { $0.richFallback?.surface == .localWKWebView }
    }

    public var richFallbacksStayNativeSafeCards: Bool {
        renderedBlocks
            .compactMap(\.richFallback)
            .allSatisfy {
                $0.surface == .nativeSafeCard
                    && $0.rendersAsNativeSafeCard
                    && !$0.requiresVendoredRendererAssets
                    && !$0.allowsNetworkRequests
                    && !$0.allowsExternalNavigation
                    && !$0.allowsRemoteSubresources
            }
    }

    public var wkWebViewRichSurfacesAreRequestBlocked: Bool {
        let wkWebViewFallbacks = renderedBlocks
            .compactMap(\.richFallback)
            .filter { $0.surface == .localWKWebView }

        guard !wkWebViewFallbacks.isEmpty else {
            return true
        }

        return wkWebViewFallbacks.allSatisfy {
            !$0.rendersAsNativeSafeCard
                && $0.requiresVendoredRendererAssets
                && !$0.allowsNetworkRequests
                && !$0.allowsExternalNavigation
                && !$0.allowsRemoteSubresources
        }
    }

    public var wkWebViewRequestPolicyBlocksForbiddenRequests: Bool {
        guard usesWKWebViewRichSurface else {
            return true
        }

        guard let wkWebViewRequestBlockingPolicy,
              let sampleRemoteURL = URL(string: "https://cdn.example.com/fastmd-renderer.js"),
              let sampleExternalNavigationURL = URL(string: "https://example.com/out"),
              let sampleJavaScriptURL = URL(string: "javascript:alert(1)"),
              let sampleDataURL = URL(string: "data:text/html;base64,PGgxPkJsb2NrPC9oMT4=") else {
            return false
        }

        return wkWebViewRequestBlockingPolicy.blocksAllStageOneForbiddenRequests(
            sampleRemoteURL: sampleRemoteURL,
            sampleExternalNavigationURL: sampleExternalNavigationURL,
            sampleJavaScriptURL: sampleJavaScriptURL,
            sampleDataURL: sampleDataURL,
            sampleIframeURL: wkWebViewRequestBlockingPolicy.bundledRendererRoot.appendingPathComponent("blocked-frame.html")
        )
    }

    public var richFallbackSurfacesSatisfyRendererPolicy: Bool {
        usesWKWebViewRichSurface
            ? wkWebViewRichSurfacesAreRequestBlocked && wkWebViewRequestPolicyBlocksForbiddenRequests
            : richFallbacksStayNativeSafeCards
    }

    public var localRendererPackagingGateStatus: IOSConditionalRendererGateStatus {
        guard usesVendoredRendererAssets else {
            return .notApplicableNativeFallback
        }

        return runtimeAudit.packagingStatus == .packagedLocalAssets
            && runtimeAudit.blocksAllNetworkAndNavigationSurfaces
            && rendererAssetPathsArePlatformLocal
            && rendererAssetPathsAreBundledResources
            && rendererAssetsAreDeclaredBundleResources
            && declaredRendererAssetNamesMatchDiscoveredBundledAssets
            ? .requiredAndSatisfied
            : .requiredButMissing
    }

    public var wkWebViewRequestBlockingGateStatus: IOSConditionalRendererGateStatus {
        guard usesWKWebViewRichSurface else {
            return .notApplicableNativeFallback
        }

        return releasePosture.richRendererStatus == .satisfied
            && runtimeAudit.blocksAllNetworkAndNavigationSurfaces
            && wkWebViewRichSurfacesAreRequestBlocked
            && wkWebViewRequestPolicyBlocksForbiddenRequests
            ? .requiredAndSatisfied
            : .blockedUnsafeWKWebView
    }

    public var rendererAssetManifestHashGateStatus: IOSConditionalRendererGateStatus {
        guard !discoveredRendererAssetPaths.isEmpty else {
            return .notApplicableNativeFallback
        }

        return rendererAssetManifestHashAudit?.satisfiesStageOneManifestHashVerification == true
            && rendererAssetPathsArePlatformLocal
            && rendererAssetPathsAreBundledResources
            ? .requiredAndSatisfied
            : .requiredButMissing
    }

    public var rendererAssetPathsArePlatformLocal: Bool {
        discoveredRendererAssetPaths.allSatisfy { path in
            let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
            return path.hasPrefix("ios/")
                && !path.contains("://")
                && !path.contains(":")
                && !path.contains("..")
                && !path.contains("\\")
                && !path.contains("?")
                && !path.contains("#")
                && !path.contains("%")
                && path == trimmedPath
                && path.rangeOfCharacter(from: .controlCharacters) == nil
                && !path.contains { $0.isWhitespace }
        }
    }

    public var rendererAssetPathsAreBundledResources: Bool {
        discoveredRendererAssetPaths.allSatisfy { path in
            IOSRendererAssetManifestEntry.bundledRendererResourcePathPrefixes.contains { prefix in
                path.hasPrefix(prefix)
            }
        }
    }

    public var declaredRendererAssetNamesMatchDiscoveredBundledAssets: Bool {
        guard usesVendoredRendererAssets else {
            return true
        }

        guard runtimeAudit.declaredAssetNamesAreLocalBundleReferences,
              !runtimeAudit.declaredAssetNames.isEmpty,
              !discoveredRendererAssetPaths.isEmpty else {
            return false
        }

        let declaredBundledPaths = Set(
            runtimeAudit.declaredAssetNames.flatMap { assetName in
                IOSRendererAssetManifestEntry.bundledRendererResourcePathPrefixes.map { prefix in
                    prefix + assetName
                }
            }
        )
        let discoveredPaths = Set(discoveredRendererAssetPaths)

        return discoveredPaths.isSubset(of: declaredBundledPaths)
            && runtimeAudit.declaredAssetNames.allSatisfy { assetName in
                IOSRendererAssetManifestEntry.bundledRendererResourcePathPrefixes.contains { prefix in
                    discoveredPaths.contains(prefix + assetName)
                }
            }
    }

    public var rendererAssetsAreDeclaredBundleResources: Bool {
        guard usesVendoredRendererAssets else {
            return true
        }

        return rendererBundleResourceDeclarationAudit?.satisfiesStageOneBundleResourceDeclaration == true
    }

    public var satisfiesStageOneConditionalRendererGates: Bool {
        richFallbackSurfacesSatisfyRendererPolicy
            && localRendererPackagingGateStatus != .requiredButMissing
            && wkWebViewRequestBlockingGateStatus != .blockedUnsafeWKWebView
            && rendererAssetManifestHashGateStatus != .requiredButMissing
    }

    public var checklistEvidence: IOSConditionalRendererChecklistEvidence {
        IOSConditionalRendererChecklistEvidence(
            localRendererPackagingOfflineStatus: localRendererPackagingGateStatus,
            wkWebViewRequestBlockingStatus: wkWebViewRequestBlockingGateStatus,
            rendererAssetManifestHashStatus: rendererAssetManifestHashGateStatus,
            usesVendoredRendererAssets: usesVendoredRendererAssets,
            usesWKWebViewRichSurface: usesWKWebViewRichSurface,
            discoveredRendererAssetPaths: discoveredRendererAssetPaths
        )
    }
}

public struct IOSConditionalRendererGateEvidenceBundle: Equatable, Sendable {
    public let inventory: IOSRendererAssetInventory
    public let audit: IOSLocalRendererConditionalGateAudit
    public let report: IOSConditionalRendererGateReport

    public init(
        inventory: IOSRendererAssetInventory,
        audit: IOSLocalRendererConditionalGateAudit,
        report: IOSConditionalRendererGateReport
    ) {
        self.inventory = inventory
        self.audit = audit
        self.report = report
    }

    public var satisfiesStageOneConditionalRendererChecklist: Bool {
        inventoryMatchesAudit
            && audit.satisfiesStageOneConditionalRendererGates
            && report.capturesConditionalRendererGateEvidence
            && report.evidence == audit.checklistEvidence
    }

    public var inventoryMatchesAudit: Bool {
        guard inventory.scannedSwiftFileCount > 0,
              inventory.discoveredRendererAssetPaths == audit.discoveredRendererAssetPaths,
              inventory.importsWebKitRichRendererCode == audit.usesWKWebViewRichSurface else {
            return false
        }

        if audit.usesVendoredRendererAssets {
            return !inventory.discoveredRendererAssets.isEmpty
                && inventory.discoveredRendererAssets.allSatisfy(\.isPlatformLocalIOSPath)
                && inventory.discoveredRendererAssets.allSatisfy(\.isBundledRendererResourcePath)
                && audit.rendererBundleResourceDeclarationAudit?.declaredBundledRendererResourceRoots == inventory.declaredBundledRendererResourceRoots
        }

        return inventory.provesNativeFallbackInventory
    }
}

public struct IOSConditionalRendererGateEvidenceBuilder: Equatable, Sendable {
    public let iosRoot: URL
    public let generatedAt: Date

    public init(
        iosRoot: URL,
        generatedAt: Date
    ) {
        self.iosRoot = iosRoot
        self.generatedAt = generatedAt
    }

    public func makeEvidence(
        renderedBlocks: [NativeMarkdownBlockPresentation],
        runtimeAudit: LocalRichRendererRuntimeAudit = LocalRichRendererRuntimeAudit(),
        releasePosture: IOSReleaseSecurityPosture = IOSReleaseSecurityPosture(),
        rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit? = nil,
        wkWebViewRequestBlockingPolicy: IOSRichRendererRequestBlockingPolicy? = nil
    ) -> IOSConditionalRendererGateEvidenceBundle {
        let inventory = IOSRendererAssetInventory.discover(iosRoot: iosRoot)
        let resourceDeclarationAudit = IOSRendererBundleResourceDeclarationAudit(
            discoveredAssets: inventory.discoveredRendererAssets,
            declaredBundledRendererResourceRoots: inventory.declaredBundledRendererResourceRoots
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            releasePosture: releasePosture,
            renderedBlocks: renderedBlocks,
            discoveredRendererAssetPaths: inventory.discoveredRendererAssetPaths,
            rendererAssetManifestHashAudit: rendererAssetManifestHashAudit,
            rendererBundleResourceDeclarationAudit: resourceDeclarationAudit,
            wkWebViewRequestBlockingPolicy: wkWebViewRequestBlockingPolicy
        )
        let report = IOSConditionalRendererGateReport(
            generatedAt: generatedAt,
            evidence: audit.checklistEvidence,
            inventory: inventory
        )

        return IOSConditionalRendererGateEvidenceBundle(
            inventory: inventory,
            audit: audit,
            report: report
        )
    }

    public func makeEvidence(
        source: String,
        parser: MarkdownParserAdapter = MarkdownParserAdapter(),
        renderer: MarkdownNativeRenderer = MarkdownNativeRenderer(),
        runtimeAudit: LocalRichRendererRuntimeAudit = LocalRichRendererRuntimeAudit(),
        releasePosture: IOSReleaseSecurityPosture = IOSReleaseSecurityPosture(),
        rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit? = nil,
        wkWebViewRequestBlockingPolicy: IOSRichRendererRequestBlockingPolicy? = nil
    ) -> IOSConditionalRendererGateEvidenceBundle {
        let document = parser.parse(source)
        let renderedBlocks = renderer.render(document: document, source: source)
        return makeEvidence(
            renderedBlocks: renderedBlocks,
            runtimeAudit: runtimeAudit,
            releasePosture: releasePosture,
            rendererAssetManifestHashAudit: rendererAssetManifestHashAudit,
            wkWebViewRequestBlockingPolicy: wkWebViewRequestBlockingPolicy
        )
    }
}

public struct IOSCurrentSourceConditionalRendererCloseoutReport: Equatable, Sendable {
    public let generatedAt: Date
    public let evidenceBundle: IOSConditionalRendererGateEvidenceBundle
    public let swiftPMValidationCommand: String
    public let focusedL11ValidationCommand: String
    public let inventoryValidationCommand: String
    public let webKitSourceScanCommand: String
    public let webKitSourceScanExpectedResult: String

    public init(
        generatedAt: Date,
        evidenceBundle: IOSConditionalRendererGateEvidenceBundle,
        swiftPMValidationCommand: String = "swift test",
        focusedL11ValidationCommand: String = "swift test --filter FastMDMobileCoreTests/testIOSL11",
        inventoryValidationCommand: String = IOSRendererAssetInventory.defaultInventoryCommand,
        webKitSourceScanCommand: String = "rg -n \"^[[:space:]]*import[[:space:]]+(@[A-Za-z0-9_]+[[:space:]]+)*(typealias|class|enum|func|let|protocol|struct|var[[:space:]]+)?WebKit\\\\b|\\\\bWKWebView[[:space:]]*(\\\\(|\\\\.)\" ios/Sources --glob '*.swift'",
        webKitSourceScanExpectedResult: String = "no matches"
    ) {
        self.generatedAt = generatedAt
        self.evidenceBundle = evidenceBundle
        self.swiftPMValidationCommand = swiftPMValidationCommand
        self.focusedL11ValidationCommand = focusedL11ValidationCommand
        self.inventoryValidationCommand = inventoryValidationCommand
        self.webKitSourceScanCommand = webKitSourceScanCommand
        self.webKitSourceScanExpectedResult = webKitSourceScanExpectedResult
    }

    public var closesAllCurrentSourceConditionalRendererRows: Bool {
        evidenceBundle.satisfiesStageOneConditionalRendererChecklist
            && evidenceBundle.inventory.provesNativeFallbackInventory
            && evidenceBundle.audit.richFallbacksStayNativeSafeCards
            && evidenceBundle.audit.checklistEvidence.allConditionalRendererGatesSatisfied
            && conditionalRendererChecklistItemsMatchBlueprint
            && validationCommandsDocumentCurrentGateChecks
            && !evidenceBundle.audit.usesVendoredRendererAssets
            && !evidenceBundle.audit.usesWKWebViewRichSurface
            && evidenceBundle.inventory.discoveredRendererAssetPaths.isEmpty
            && !evidenceBundle.inventory.importsWebKitRichRendererCode
            && evidenceBundle.report.capturesConditionalRendererGateEvidence
    }

    public var expectedConditionalRendererChecklistItems: [String] {
        [
            IOSStageOneReconciliationChecklistItem.localRendererPackagingOfflineTests.rawValue,
            IOSStageOneReconciliationChecklistItem.wkWebViewRequestBlockingTests.rawValue,
            IOSStageOneReconciliationChecklistItem.rendererAssetManifestHashTests.rawValue
        ]
    }

    public var conditionalRendererChecklistItemsMatchBlueprint: Bool {
        evidenceBundle.audit.checklistEvidence.checklistItems.map(\.blueprintChecklistText)
            == expectedConditionalRendererChecklistItems
            && evidenceBundle.audit.checklistEvidence.supervisorCompletionRecommendations
                == expectedConditionalRendererChecklistItems
    }

    public var validationCommandsDocumentCurrentGateChecks: Bool {
        swiftPMValidationCommand == "swift test"
            && focusedL11ValidationCommand.contains("swift test")
            && focusedL11ValidationCommand.contains("testIOSL11")
            && inventoryValidationCommand == IOSRendererAssetInventory.defaultInventoryCommand
            && webKitSourceScanCommand.contains("rg -n")
            && webKitSourceScanCommand.contains("ios/Sources")
            && webKitSourceScanCommand.contains("WKWebView")
            && webKitSourceScanExpectedResult == "no matches"
    }

    public var supervisorCompletionRecommendations: [String] {
        closesAllCurrentSourceConditionalRendererRows
            ? evidenceBundle.audit.checklistEvidence.supervisorCompletionRecommendations
            : []
    }

    public var markdown: String {
        let checklistRows = evidenceBundle.audit.checklistEvidence.checklistItems.map { item in
            "| \(safeText(item.blueprintChecklistText)) | \(item.status.rawValue) | \(item.checklistSatisfied) | \(safeText(item.evidenceSummary)) |"
        }
        let recommendations = supervisorCompletionRecommendations.isEmpty
            ? "- None."
            : supervisorCompletionRecommendations
                .map { "- \(safeText($0))" }
                .joined(separator: "\n")

        return ([
            "# Stage 1 iOS Current-Source Conditional Renderer Closeout",
            "",
            "- Generated: \(iso8601String(from: generatedAt))",
            "- Can mark all conditional L11 renderer rows complete: \(closesAllCurrentSourceConditionalRendererRows)",
            "- Checklist items match blueprint: \(conditionalRendererChecklistItemsMatchBlueprint)",
            "- Validation commands document current gate checks: \(validationCommandsDocumentCurrentGateChecks)",
            "- Uses vendored renderer assets: \(evidenceBundle.audit.usesVendoredRendererAssets)",
            "- Uses WKWebView rich surface: \(evidenceBundle.audit.usesWKWebViewRichSurface)",
            "- Imports WebKit rich renderer code: \(evidenceBundle.inventory.importsWebKitRichRendererCode)",
            "- Scanned Swift source files: \(evidenceBundle.inventory.scannedSwiftFileCount)",
            "- Discovered renderer asset paths: \(evidenceBundle.inventory.discoveredRendererAssetPaths.isEmpty ? "none" : safeText(evidenceBundle.inventory.discoveredRendererAssetPaths.joined(separator: ", ")))",
            "",
            "## Validation Commands",
            "",
            "- SwiftPM: \(safeText(swiftPMValidationCommand))",
            "- Focused L11: \(safeText(focusedL11ValidationCommand))",
            "- Renderer asset inventory: \(safeText(inventoryValidationCommand))",
            "- WebKit source scan: \(safeText(webKitSourceScanCommand))",
            "- WebKit source scan expected result: \(safeText(webKitSourceScanExpectedResult))",
            "",
            "## Supervisor Completion Recommendations",
            "",
            recommendations,
            "",
            "| Blueprint checklist item | Status | Checklist satisfied | Evidence |",
            "| --- | --- | --- | --- |"
        ] + checklistRows).joined(separator: "\n") + "\n"
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private func safeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "/")
    }
}

public enum IOSValidationCommandResultStatus: String, Equatable, Sendable {
    case passed
    case failed
    case blocked
}

public struct IOSValidationCommandResult: Equatable, Sendable {
    public let label: String
    public let command: String
    public let status: IOSValidationCommandResultStatus
    public let detail: String

    public init(
        label: String,
        command: String,
        status: IOSValidationCommandResultStatus,
        detail: String
    ) {
        self.label = label
        self.command = command
        self.status = status
        self.detail = detail
    }

    public var passed: Bool {
        status == .passed
    }
}

public struct IOSCurrentSourceConditionalRendererCompletionEvidence: Equatable, Sendable {
    public let closeoutReport: IOSCurrentSourceConditionalRendererCloseoutReport
    public let evidencePath: String
    public let validationResults: [IOSValidationCommandResult]

    public init(
        closeoutReport: IOSCurrentSourceConditionalRendererCloseoutReport,
        evidencePath: String,
        validationResults: [IOSValidationCommandResult] = []
    ) {
        self.closeoutReport = closeoutReport
        self.evidencePath = evidencePath
        self.validationResults = validationResults
    }

    public var evidencePathIsIOSLocalReport: Bool {
        let trimmedPath = evidencePath.trimmingCharacters(in: .whitespacesAndNewlines)
        return evidencePath == trimmedPath
            && evidencePath.hasPrefix("ios/docs/reports/")
            && evidencePath.hasSuffix(".md")
            && !evidencePath.contains("://")
            && !evidencePath.contains("..")
            && !evidencePath.contains("\\")
            && !evidencePath.contains("?")
            && !evidencePath.contains("#")
            && !evidencePath.contains("|")
            && !evidencePath.contains { $0.isWhitespace }
    }

    public var canMarkConditionalRendererRowsComplete: Bool {
        evidencePathIsIOSLocalReport
            && closeoutReport.closesAllCurrentSourceConditionalRendererRows
            && closeoutReport.supervisorCompletionRecommendations.count == 3
            && validationResultsCoverCurrentGateChecks
    }

    public var validationResultsAllPassed: Bool {
        !validationResults.isEmpty && validationResults.allSatisfy(\.passed)
    }

    public var validationResultsCoverCurrentGateChecks: Bool {
        validationResultsAllPassed
            && validationResultsContainCommand(closeoutReport.swiftPMValidationCommand)
            && validationResultsContainCommand(closeoutReport.focusedL11ValidationCommand)
            && validationResultsContainCommand(closeoutReport.inventoryValidationCommand)
            && validationResultsContainCommand(closeoutReport.webKitSourceScanCommand)
    }

    public var markdown: String {
        let status = canMarkConditionalRendererRowsComplete ? "COMPLETE" : "OPEN"
        let rows = closeoutReport.supervisorCompletionRecommendations.map { item in
            "| \(safeText(item)) | \(status) | \(safeText(evidencePath)) |"
        }
        let validationRows = validationResults.map { result in
            "| \(safeText(result.label)) | \(safeText(result.command)) | \(result.status.rawValue) | \(safeText(result.detail)) |"
        }

        var sections = [
            "# Stage 1 iOS Conditional Renderer Completion Evidence",
            "",
            "- Evidence path: \(safeText(evidencePath))",
            "- Evidence path is iOS-local report: \(evidencePathIsIOSLocalReport)",
            "- Can mark conditional renderer rows complete: \(canMarkConditionalRendererRowsComplete)",
            "- Validation results all passed: \(validationResultsAllPassed)",
            "- Validation results cover current gate checks: \(validationResultsCoverCurrentGateChecks)",
            "",
            "| Checklist item | Status | Evidence path |",
            "| --- | --- | --- |"
        ] + (rows.isEmpty ? ["| None | OPEN | \(safeText(evidencePath)) |"] : rows)

        if !validationRows.isEmpty {
            sections += [
                "",
                "## Validation Results",
                "",
                "| Label | Command | Status | Detail |",
                "| --- | --- | --- | --- |"
            ] + validationRows
        }

        return sections.joined(separator: "\n") + "\n"
    }

    private func validationResultsContainCommand(_ expectedCommand: String) -> Bool {
        validationResults.contains { result in
            result.command == expectedCommand || result.command.contains(expectedCommand)
        }
    }

    private func safeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "/")
    }
}

public struct IOSDiagnosticsLogRedactionInput: Equatable, Sendable {
    public let eventName: String
    public let displayName: String?
    public let fullPath: String?
    public let fullURI: String?
    public let documentContent: String?
    public let searchQuery: String?
    public let clipboardText: String?
    public let diagnostics: IOSDiagnosticsSnapshot

    public init(
        eventName: String,
        displayName: String?,
        fullPath: String?,
        fullURI: String?,
        documentContent: String?,
        searchQuery: String?,
        clipboardText: String?,
        diagnostics: IOSDiagnosticsSnapshot
    ) {
        self.eventName = eventName
        self.displayName = displayName
        self.fullPath = fullPath
        self.fullURI = fullURI
        self.documentContent = documentContent
        self.searchQuery = searchQuery
        self.clipboardText = clipboardText
        self.diagnostics = diagnostics
    }
}

public struct IOSDiagnosticsRedactedLogLine: Equatable, Sendable {
    public let text: String
    public let includesDocumentContent: Bool
    public let includesFullPath: Bool
    public let includesFullURI: Bool
    public let includesQueryStrings: Bool
    public let includesClipboard: Bool

    public init(
        text: String,
        includesDocumentContent: Bool = false,
        includesFullPath: Bool = false,
        includesFullURI: Bool = false,
        includesQueryStrings: Bool = false,
        includesClipboard: Bool = false
    ) {
        self.text = text
        self.includesDocumentContent = includesDocumentContent
        self.includesFullPath = includesFullPath
        self.includesFullURI = includesFullURI
        self.includesQueryStrings = includesQueryStrings
        self.includesClipboard = includesClipboard
    }

    public var isRedactedForLocalExport: Bool {
        !includesDocumentContent
            && !includesFullPath
            && !includesFullURI
            && !includesQueryStrings
            && !includesClipboard
    }
}

public struct IOSDiagnosticsLogRedactionPolicy: Equatable, Sendable {
    public init() {}

    public func redactedLogLine(
        from input: IOSDiagnosticsLogRedactionInput
    ) -> IOSDiagnosticsRedactedLogLine {
        let diagnostics = input.diagnostics
        let fields = [
            "event=\(safeToken(input.eventName, fallback: "diagnostic"))",
            "displayName=\(safeDisplayName(input.displayName))",
            "fileSizeBucket=\(diagnostics.fileSizeBucket.rawValue)",
            "deviceClass=\(diagnostics.deviceClass.rawValue)",
            "rendererProfile=\(safeToken(diagnostics.rendererProfile, fallback: "unknown"))",
            "lastErrorCategory=\(diagnostics.lastErrorCategory?.rawValue ?? "none")",
            "hasSearchQuery=\(input.searchQuery?.isEmpty == false)",
            "hasClipboard=\(input.clipboardText?.isEmpty == false)"
        ]

        return IOSDiagnosticsRedactedLogLine(text: fields.joined(separator: " "))
    }

    private func safeDisplayName(_ displayName: String?) -> String {
        let safeName = IOSDisplayNamePolicy(maximumCharacterCount: 96).displayName(for: displayName)
        return safeToken(safeName, fallback: "Untitled-Markdown")
    }

    private func safeToken(_ value: String, fallback: String) -> String {
        let allowedScalars = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: "._-"))
        let filtered = String(
            value.unicodeScalars.map { scalar in
                allowedScalars.contains(scalar) ? Character(scalar) : "-"
            }
        )
        let collapsed = filtered
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return collapsed.isEmpty ? fallback : collapsed
    }
}

public struct IOSDiagnosticsLogRedactionAudit: Equatable, Sendable {
    public let redactedLine: IOSDiagnosticsRedactedLogLine
    public let forbiddenFragments: [String]

    public init(
        redactedLine: IOSDiagnosticsRedactedLogLine,
        forbiddenFragments: [String]
    ) {
        self.redactedLine = redactedLine
        self.forbiddenFragments = forbiddenFragments.filter { !$0.isEmpty }
    }

    public var excludesForbiddenFragments: Bool {
        forbiddenFragments.allSatisfy { fragment in
            !redactedLine.text.contains(fragment)
        }
    }

    public var satisfiesStageOneLogRedactionTests: Bool {
        redactedLine.isRedactedForLocalExport && excludesForbiddenFragments
    }
}

public enum IOSPerformanceAutomationOperation: String, CaseIterable, Equatable, Sendable {
    case parse
    case render
    case search
    case fontTierSwitch
    case save
}

public struct IOSPerformanceAutomationMeasurement: Equatable, Sendable {
    public let operation: IOSPerformanceAutomationOperation
    public let elapsedMilliseconds: Double
    public let thresholdMilliseconds: Double
    public let execution: IOSOffMainActorExecutionMetadata?

    public init(
        operation: IOSPerformanceAutomationOperation,
        elapsedMilliseconds: Double,
        thresholdMilliseconds: Double,
        execution: IOSOffMainActorExecutionMetadata? = nil
    ) {
        self.operation = operation
        self.elapsedMilliseconds = max(0, elapsedMilliseconds)
        self.thresholdMilliseconds = max(1, thresholdMilliseconds)
        self.execution = execution
    }

    public var isWithinThreshold: Bool {
        elapsedMilliseconds <= thresholdMilliseconds
    }
}

public struct IOSPerformanceAutomationAudit: Equatable, Sendable {
    public let measurements: [IOSPerformanceAutomationMeasurement]
    public let testedFontTiers: Set<MobileFontTier>
    public let performanceProfile: MobilePerformanceProfile

    public init(
        measurements: [IOSPerformanceAutomationMeasurement],
        testedFontTiers: Set<MobileFontTier>,
        performanceProfile: MobilePerformanceProfile = .iOSPhone12Standard
    ) {
        self.measurements = measurements
        self.testedFontTiers = testedFontTiers
        self.performanceProfile = performanceProfile
    }

    public var coversRequiredOperations: Bool {
        Set(measurements.map(\.operation)) == Set(IOSPerformanceAutomationOperation.allCases)
    }

    public var allMeasurementsWithinThreshold: Bool {
        measurements.allSatisfy(\.isWithinThreshold)
    }

    public var coversAllFourFontTiers: Bool {
        testedFontTiers == Set(MobileFontTier.allCases)
    }

    public var offMainOperationsStayedOffMainActor: Bool {
        measurements
            .filter { [.parse, .render, .search, .save].contains($0.operation) }
            .allSatisfy { $0.execution?.stayedOffMainThread == true }
    }

    public var satisfiesStageOnePerformanceTests: Bool {
        performanceProfile.platform == .iOS
            && performanceProfile.kind == .iOSPhone12Standard
            && coversRequiredOperations
            && allMeasurementsWithinThreshold
            && coversAllFourFontTiers
            && offMainOperationsStayedOffMainActor
    }
}

public struct IOSStageOnePerformanceReport: Equatable, Sendable {
    public let generatedAt: Date
    public let audit: IOSPerformanceAutomationAudit
    public let diagnostics: IOSDiagnosticsSnapshot
    public let localValidationDeviceName: String
    public let requiredIPhone12SimulatorBlocker: String?

    public init(
        generatedAt: Date,
        audit: IOSPerformanceAutomationAudit,
        diagnostics: IOSDiagnosticsSnapshot,
        localValidationDeviceName: String,
        requiredIPhone12SimulatorBlocker: String? = nil
    ) {
        self.generatedAt = generatedAt
        self.audit = audit
        self.diagnostics = diagnostics
        self.localValidationDeviceName = localValidationDeviceName
        self.requiredIPhone12SimulatorBlocker = requiredIPhone12SimulatorBlocker
    }

    public var capturesRequiredIOSPerformanceReport: Bool {
        audit.satisfiesStageOnePerformanceTests
            && diagnostics.deviceClass == .iOSPhone12Standard
            && diagnostics.isRedactedForLocalExport
            && diagnostics.rendererProfile.isEmpty == false
            && diagnostics.parseMilliseconds != nil
            && diagnostics.renderMilliseconds != nil
            && diagnostics.searchMilliseconds != nil
            && diagnostics.saveMilliseconds != nil
    }

    public var markdown: String {
        let blocker = requiredIPhone12SimulatorBlocker ?? "none"
        let rows = IOSPerformanceAutomationOperation.allCases.map { operation -> String in
            guard let measurement = measurement(for: operation) else {
                return "| \(operation.rawValue) | missing | missing | no | FAIL |"
            }

            let offMain = measurement.execution.map { $0.stayedOffMainThread ? "yes" : "no" } ?? "n/a"
            return [
                "| \(operation.rawValue)",
                format(measurement.elapsedMilliseconds),
                format(measurement.thresholdMilliseconds),
                offMain,
                measurement.isWithinThreshold ? "PASS" : "FAIL"
            ].joined(separator: " | ") + " |"
        }

        return ([
            "# Stage 1 iOS Performance Report",
            "",
            "- Generated: \(iso8601String(from: generatedAt))",
            "- Profile: \(audit.performanceProfile.kind.rawValue)",
            "- Local validation device: \(safeText(localValidationDeviceName))",
            "- iPhone 12 simulator blocker: \(safeText(blocker))",
            "- Renderer profile: \(safeText(diagnostics.rendererProfile))",
            "- File size bucket: \(diagnostics.fileSizeBucket.rawValue)",
            "- Redacted for local export: \(diagnostics.isRedactedForLocalExport)",
            "",
            "| Operation | Elapsed ms | Threshold ms | Off-main | Result |",
            "| --- | ---: | ---: | --- | --- |"
        ] + rows).joined(separator: "\n") + "\n"
    }

    private func measurement(
        for operation: IOSPerformanceAutomationOperation
    ) -> IOSPerformanceAutomationMeasurement? {
        audit.measurements.first { $0.operation == operation }
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private func safeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "/")
    }
}

public enum IOSStageOneSimulatorValidationStatus: String, Equatable, Sendable {
    case passed
    case blockedSimulatorUnavailable
    case failedBuild
    case failedTests
}

public struct IOSStageOneSimulatorValidationReport: Equatable, Sendable {
    public let generatedAt: Date
    public let scheme: String
    public let destination: String
    public let simulatorDeviceName: String
    public let simulatorIdentifier: String?
    public let swiftPMTestPassed: Bool
    public let simulatorAvailable: Bool
    public let xcodebuildBuildPassed: Bool
    public let xcodebuildTestPassed: Bool
    public let testCaseCount: Int
    public let resultBundlePath: String?
    public let simulatorListCommand: String
    public let buildCommand: String
    public let testCommand: String

    public init(
        generatedAt: Date,
        scheme: String = "FastMDMobile",
        destination: String = "platform=iOS Simulator,name=iPhone 12",
        simulatorDeviceName: String = "iPhone 12",
        simulatorIdentifier: String? = nil,
        swiftPMTestPassed: Bool,
        simulatorAvailable: Bool,
        xcodebuildBuildPassed: Bool,
        xcodebuildTestPassed: Bool,
        testCaseCount: Int,
        resultBundlePath: String? = nil,
        simulatorListCommand: String = "xcrun simctl list devices available | rg 'iPhone 12'",
        buildCommand: String = "xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build",
        testCommand: String = "xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test"
    ) {
        self.generatedAt = generatedAt
        self.scheme = scheme
        self.destination = destination
        self.simulatorDeviceName = simulatorDeviceName
        self.simulatorIdentifier = simulatorIdentifier
        self.swiftPMTestPassed = swiftPMTestPassed
        self.simulatorAvailable = simulatorAvailable
        self.xcodebuildBuildPassed = xcodebuildBuildPassed
        self.xcodebuildTestPassed = xcodebuildTestPassed
        self.testCaseCount = max(0, testCaseCount)
        self.resultBundlePath = resultBundlePath
        self.simulatorListCommand = simulatorListCommand
        self.buildCommand = buildCommand
        self.testCommand = testCommand
    }

    public var status: IOSStageOneSimulatorValidationStatus {
        guard simulatorAvailable else {
            return .blockedSimulatorUnavailable
        }

        guard xcodebuildBuildPassed else {
            return .failedBuild
        }

        guard xcodebuildTestPassed && swiftPMTestPassed else {
            return .failedTests
        }

        return .passed
    }

    public var capturesIPhone12SimulatorBuildGate: Bool {
        simulatorAvailable
            && xcodebuildBuildPassed
            && scheme == "FastMDMobile"
            && destination == "platform=iOS Simulator,name=iPhone 12"
    }

    public var capturesIPhone12SimulatorTestGate: Bool {
        capturesIPhone12SimulatorBuildGate
            && swiftPMTestPassed
            && xcodebuildTestPassed
            && testCaseCount > 0
    }

    public var capturesRequiredIPhone12SimulatorValidation: Bool {
        status == .passed
            && capturesIPhone12SimulatorBuildGate
            && capturesIPhone12SimulatorTestGate
    }

    public var markdown: String {
        let resultBundle = resultBundlePath.map(safeText) ?? "none"
        let simulatorID = simulatorIdentifier.map(safeText) ?? "unknown"

        return [
            "# Stage 1 iOS iPhone 12 Simulator Validation Report",
            "",
            "- Generated: \(iso8601String(from: generatedAt))",
            "- Status: \(status.rawValue)",
            "- Scheme: \(safeText(scheme))",
            "- Destination: \(safeText(destination))",
            "- Simulator: \(safeText(simulatorDeviceName))",
            "- Simulator identifier: \(simulatorID)",
            "- SwiftPM tests passed: \(swiftPMTestPassed)",
            "- xcodebuild build passed: \(xcodebuildBuildPassed)",
            "- xcodebuild tests passed: \(xcodebuildTestPassed)",
            "- XCTest case count: \(testCaseCount)",
            "- Result bundle: \(resultBundle)",
            "",
            "| Gate | Result | Command |",
            "| --- | --- | --- |",
            "| iPhone 12 simulator available | \(simulatorAvailable ? "PASS" : "BLOCKED") | \(safeText(simulatorListCommand)) |",
            "| iPhone 12 simulator build | \(capturesIPhone12SimulatorBuildGate ? "PASS" : "OPEN") | \(safeText(buildCommand)) |",
            "| iPhone 12 simulator tests | \(capturesIPhone12SimulatorTestGate ? "PASS" : "OPEN") | \(safeText(testCommand)) |"
        ].joined(separator: "\n") + "\n"
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private func safeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "/")
    }
}

public struct IOSSimctlDeviceListParser: Equatable, Sendable {
    public init() {}

    public func parseCandidates(from output: String) -> [IOSStageOnePhysicalDeviceCandidate] {
        var currentIOSRuntimeVersion: String?
        var candidates: [IOSStageOnePhysicalDeviceCandidate] = []

        for rawLine in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            if line.hasPrefix("-- "), line.hasSuffix(" --") {
                guard let runtimeVersion = parseIOSRuntimeVersion(fromHeaderLine: line) else {
                    currentIOSRuntimeVersion = nil
                    continue
                }
                currentIOSRuntimeVersion = runtimeVersion
                continue
            }

            guard let candidate = parseDeviceLine(
                line,
                iosRuntimeVersion: currentIOSRuntimeVersion
            ) else {
                continue
            }

            candidates.append(candidate)
        }

        return candidates
    }

    public func iPhone12Simulator(from output: String) -> IOSStageOnePhysicalDeviceCandidate? {
        parseCandidates(from: output).first { candidate in
            candidate.name == "iPhone 12" && candidate.isSimulator && candidate.isConnected
        }
    }

    public func containsAvailableIPhone12Simulator(in output: String) -> Bool {
        iPhone12Simulator(from: output) != nil
    }

    private func parseIOSRuntimeVersion(fromHeaderLine line: String) -> String? {
        guard line.hasPrefix("-- "), line.hasSuffix(" --") else {
            return nil
        }

        let body = line
            .dropFirst(3)
            .dropLast(3)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard body.hasPrefix("iOS ") else {
            return nil
        }

        return String(body.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseDeviceLine(
        _ line: String,
        iosRuntimeVersion: String?
    ) -> IOSStageOnePhysicalDeviceCandidate? {
        guard let iosRuntimeVersion,
              !line.isEmpty,
              !line.hasPrefix("-- "),
              !line.hasPrefix("== "),
              let identifierRange = uuidParenthesizedRange(in: line) else {
            return nil
        }

        let name = line[..<identifierRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let identifier = String(line[identifierRange].dropFirst().dropLast())
        let stateSuffix = line[identifierRange.upperBound...].lowercased()

        guard !name.isEmpty,
              !identifier.isEmpty,
              !stateSuffix.contains("unavailable") else {
            return nil
        }

        return IOSStageOnePhysicalDeviceCandidate(
            name: String(name),
            osVersion: iosRuntimeVersion,
            identifier: identifier,
            hardwareModel: String(name),
            isConnected: true,
            isSimulator: true
        )
    }

    private func uuidParenthesizedRange(in line: String) -> Range<String.Index>? {
        line.range(
            of: #"\([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\)"#,
            options: .regularExpression
        )
    }
}

public struct IOSStageOneSecurityAuditReport: Equatable, Sendable {
    public let generatedAt: Date
    public let localImageDownsamplePolicy: IOSLocalImageDownsamplePolicy
    public let securityScopedAccessAudit: IOSSecurityScopedAccessAudit
    public let releasePosture: IOSReleaseSecurityPosture
    public let hostileHTMLAudit: IOSHostileMarkdownFixtureAudit
    public let hostileLinkAudit: IOSHostileMarkdownFixtureAudit
    public let remoteImageAudit: IOSRemoteImagePrivacyAudit
    public let conditionalRendererAudit: IOSLocalRendererConditionalGateAudit
    public let diagnostics: IOSDiagnosticsSnapshot
    public let importsWebKitRichRendererCode: Bool
    public let rendererAssetInventoryCommand: String

    public init(
        generatedAt: Date,
        localImageDownsamplePolicy: IOSLocalImageDownsamplePolicy,
        securityScopedAccessAudit: IOSSecurityScopedAccessAudit,
        releasePosture: IOSReleaseSecurityPosture,
        hostileHTMLAudit: IOSHostileMarkdownFixtureAudit,
        hostileLinkAudit: IOSHostileMarkdownFixtureAudit,
        remoteImageAudit: IOSRemoteImagePrivacyAudit,
        conditionalRendererAudit: IOSLocalRendererConditionalGateAudit,
        diagnostics: IOSDiagnosticsSnapshot,
        importsWebKitRichRendererCode: Bool,
        rendererAssetInventoryCommand: String
    ) {
        self.generatedAt = generatedAt
        self.localImageDownsamplePolicy = localImageDownsamplePolicy
        self.securityScopedAccessAudit = securityScopedAccessAudit
        self.releasePosture = releasePosture
        self.hostileHTMLAudit = hostileHTMLAudit
        self.hostileLinkAudit = hostileLinkAudit
        self.remoteImageAudit = remoteImageAudit
        self.conditionalRendererAudit = conditionalRendererAudit
        self.diagnostics = diagnostics
        self.importsWebKitRichRendererCode = importsWebKitRichRendererCode
        self.rendererAssetInventoryCommand = rendererAssetInventoryCommand
    }

    public var capturesRequiredIOSSecurityAuditReport: Bool {
        localImageDownsamplePolicy.satisfiesStageOneLocalImageRule
            && securityScopedAccessAudit.status == .satisfied
            && releasePosture.satisfiesStageOneReleasePosture
            && hostileHTMLAudit.satisfiesStageOneMaliciousHTMLFixtureTests
            && hostileLinkAudit.satisfiesStageOneMaliciousLinkFixtureTests
            && remoteImageAudit.satisfiesStageOneRemoteImagePrivacyTests
            && conditionalRendererAudit.satisfiesStageOneConditionalRendererGates
            && diagnostics.isRedactedForLocalExport
            && !importsWebKitRichRendererCode
    }

    public var markdown: String {
        let assetPaths = conditionalRendererAudit.discoveredRendererAssetPaths.isEmpty
            ? "none"
            : conditionalRendererAudit.discoveredRendererAssetPaths.joined(separator: ", ")

        return [
            "# Stage 1 iOS Security Audit Report",
            "",
            "- Generated: \(iso8601String(from: generatedAt))",
            "- Renderer profile: \(safeText(diagnostics.rendererProfile))",
            "- Redacted for local export: \(diagnostics.isRedactedForLocalExport)",
            "- Renderer asset inventory command: \(safeText(rendererAssetInventoryCommand))",
            "- Discovered renderer asset paths: \(safeText(assetPaths))",
            "- Imports WebKit rich renderer code: \(importsWebKitRichRendererCode)",
            "",
            "| Gate | Status | Evidence |",
            "| --- | --- | --- |",
            "| ImageIO local image downsample | \(status(localImageDownsamplePolicy.satisfiesStageOneLocalImageRule)) | maxPixel=\(localImageDownsamplePolicy.maximumPixelDimension), remoteDecode=\(localImageDownsamplePolicy.decodesRemoteImages) |",
            "| Security-scoped access balance | \(securityScopedAccessAudit.status.rawValue) | started=\(securityScopedAccessAudit.startedAccessCount), stopped=\(securityScopedAccessAudit.stoppedAccessCount), stalePermissionLost=\(securityScopedAccessAudit.unresolvedStaleBookmarksReturnPermissionLost) |",
            "| ATS posture | \(releasePosture.appTransportSecurityStatus.rawValue) | arbitraryLoads=\(releasePosture.appTransportSecurityAllowsArbitraryLoads) |",
            "| Privacy manifest posture | \(releasePosture.privacyManifestStatus.rawValue) | tracksUsers=\(releasePosture.privacyManifestTracksUsers) |",
            "| Background modes | \(releasePosture.backgroundModeStatus.rawValue) | count=\(releasePosture.backgroundModes.count) |",
            "| Rich renderer network posture | \(releasePosture.richRendererStatus.rawValue) | WKWebView=\(releasePosture.usesWKWebViewRichRendering), mode=\(releasePosture.localRendererPolicy.mode.rawValue) |",
            "| Malicious HTML fixture | \(status(hostileHTMLAudit.satisfiesStageOneMaliciousHTMLFixtureTests)) | sanitized=\(hostileHTMLAudit.sanitizedHTMLHasNoExecutableFragments), blocksSubresources=\(hostileHTMLAudit.htmlFallbacksBlockUnsafeSurfaces) |",
            "| Malicious link fixture | \(status(hostileLinkAudit.satisfiesStageOneMaliciousLinkFixtureTests)) | dangerousBlocked=\(hostileLinkAudit.dangerousLinksAreBlocked), webConfirm=\(hostileLinkAudit.safeWebLinksRequireConfirmation) |",
            "| Remote image privacy | \(status(remoteImageAudit.satisfiesStageOneRemoteImagePrivacyTests)) | remoteImages=\(remoteImageAudit.remoteImages.count), manualOpen=\(remoteImageAudit.remoteImagesAreManualOpenPlaceholders) |",
            "| Conditional local renderer gates | \(status(conditionalRendererAudit.satisfiesStageOneConditionalRendererGates)) | assets=\(safeText(assetPaths)), WKWebViewSurface=\(conditionalRendererAudit.usesWKWebViewRichSurface) |"
        ].joined(separator: "\n") + "\n"
    }

    private func status(_ passed: Bool) -> String {
        passed ? "satisfied" : "blocked"
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private func safeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "/")
    }
}

public enum IOSRichFixtureRenderCategory: String, CaseIterable, Equatable, Sendable {
    case headingsH1ThroughH6
    case paragraphs
    case bold
    case italic
    case boldItalic
    case strikethrough
    case inlineCode
    case highlightMark
    case subscriptText
    case superscriptText
    case links
    case autolinksEmail
    case blockquote
    case unorderedList
    case orderedList
    case taskList
    case tables
    case fencedCodeBlocks
    case syntaxHighlighting
    case mermaidBlocks
    case inlineMath
    case blockMath
    case images
    case videoHTML
    case horizontalRule
    case footnotes
    case detailsSummaryHTML
    case genericHTMLBlocks
    case mixedCJKEnglishJapaneseKorean
    case escapedMarkerCharacters

    public var displayName: String {
        switch self {
        case .headingsH1ThroughH6:
            return "H1-H6 headings"
        case .paragraphs:
            return "Paragraphs"
        case .bold:
            return "Bold"
        case .italic:
            return "Italic"
        case .boldItalic:
            return "Bold italic"
        case .strikethrough:
            return "Strikethrough"
        case .inlineCode:
            return "Inline code"
        case .highlightMark:
            return "Highlight / mark"
        case .subscriptText:
            return "Subscript"
        case .superscriptText:
            return "Superscript"
        case .links:
            return "Links"
        case .autolinksEmail:
            return "Autolinks / email"
        case .blockquote:
            return "Blockquote"
        case .unorderedList:
            return "Unordered list"
        case .orderedList:
            return "Ordered list"
        case .taskList:
            return "Task list"
        case .tables:
            return "Tables"
        case .fencedCodeBlocks:
            return "Fenced code blocks"
        case .syntaxHighlighting:
            return "Syntax highlighting"
        case .mermaidBlocks:
            return "Mermaid blocks"
        case .inlineMath:
            return "Inline math"
        case .blockMath:
            return "Block math"
        case .images:
            return "Images"
        case .videoHTML:
            return "Video HTML"
        case .horizontalRule:
            return "Horizontal rule"
        case .footnotes:
            return "Footnotes"
        case .detailsSummaryHTML:
            return "Details / summary HTML"
        case .genericHTMLBlocks:
            return "Generic HTML blocks"
        case .mixedCJKEnglishJapaneseKorean:
            return "Mixed CJK / English / Japanese / Korean"
        case .escapedMarkerCharacters:
            return "Escaped marker characters"
        }
    }
}

public struct IOSRichFixtureRenderAudit: Equatable, Sendable {
    public let sourceByteCount: Int
    public let renderedBlocks: [NativeMarkdownBlockPresentation]

    public init(sourceByteCount: Int, renderedBlocks: [NativeMarkdownBlockPresentation]) {
        self.sourceByteCount = max(0, sourceByteCount)
        self.renderedBlocks = renderedBlocks
    }

    public var coveredCategories: Set<IOSRichFixtureRenderCategory> {
        Set(IOSRichFixtureRenderCategory.allCases.filter(isCovered))
    }

    public var missingCategories: Set<IOSRichFixtureRenderCategory> {
        Set(IOSRichFixtureRenderCategory.allCases).subtracting(coveredCategories)
    }

    public var satisfiesStageOneRichFixtureRenderReport: Bool {
        sourceByteCount > 0
            && !renderedBlocks.isEmpty
            && missingCategories.isEmpty
            && renderedBlocks.allSatisfy { $0.sourceRange.isValid }
    }

    public func isCovered(_ category: IOSRichFixtureRenderCategory) -> Bool {
        switch category {
        case .headingsH1ThroughH6:
            return Set(renderedBlocks.compactMap(\.headingLevel)).isSuperset(of: Set(1...6))
        case .paragraphs:
            return renderedBlocks.contains { $0.role == .paragraph && containsCJK($0.plainText) && containsLatin($0.plainText) }
        case .bold:
            return allInlineRuns.contains { $0.styles.contains(.bold) }
        case .italic:
            return allInlineRuns.contains { $0.styles.contains(.italic) }
        case .boldItalic:
            return allInlineRuns.contains { $0.styles.contains(.bold) && $0.styles.contains(.italic) }
        case .strikethrough:
            return allInlineRuns.contains { $0.styles.contains(.strikethrough) }
        case .inlineCode:
            return allInlineRuns.contains { $0.styles.contains(.inlineCode) }
        case .highlightMark:
            return allInlineRuns.contains { $0.styles.contains(.highlight) }
        case .subscriptText:
            return allInlineRuns.contains { $0.styles.contains(.subscriptText) }
        case .superscriptText:
            return allInlineRuns.contains { $0.styles.contains(.superscriptText) }
        case .links:
            return allInlineRuns.contains { $0.linkDecision?.kind == .confirm }
        case .autolinksEmail:
            return allInlineRuns.contains { $0.linkDecision?.normalizedURLString?.hasPrefix("mailto:") == true }
                && allInlineRuns.contains { $0.text.hasPrefix("https://") && $0.linkDecision?.kind == .confirm }
        case .blockquote:
            return renderedBlocks.contains { $0.role == .blockquote && $0.blockquoteLines.contains { $0.depth > 1 } }
        case .unorderedList:
            return renderedBlocks.contains { $0.role == .unorderedList && $0.listItems.contains { $0.nestingLevel > 0 } }
        case .orderedList:
            return renderedBlocks.contains { $0.role == .orderedList && !$0.listItems.isEmpty }
        case .taskList:
            return renderedBlocks.contains { block in
                block.role == .taskList
                    && block.listItems.contains { $0.checked == true }
                    && block.listItems.contains { $0.checked == false }
            }
        case .tables:
            return renderedBlocks.contains { $0.table?.scrollsHorizontallyWithinBlock == true && ($0.table?.columnCount ?? 0) > 1 }
        case .fencedCodeBlocks:
            return renderedBlocks.contains {
                $0.codeBlock?.language?.isEmpty == false
                    && $0.codeBlock?.supportsCopyAction == true
                    && $0.codeBlock?.scrollsHorizontallyWithinBlock == true
            }
        case .syntaxHighlighting:
            return renderedBlocks.contains { $0.codeBlock?.highlighting == .plainFallback }
        case .mermaidBlocks:
            return renderedBlocks.contains {
                $0.richFallback?.kind == .mermaidDiagramSource
                    && $0.richFallback?.rendersAsNativeSafeCard == true
            }
        case .inlineMath:
            return allInlineRuns.contains { $0.styles.contains(.inlineMath) }
        case .blockMath:
            return renderedBlocks.contains {
                $0.richFallback?.kind == .blockMath
                    && $0.richFallback?.rendersAsNativeSafeCard == true
            }
        case .images:
            return renderedBlocks.contains {
                guard let image = $0.image else {
                    return false
                }
                if image.isRemote {
                    return !image.loadsAutomatically && image.requiresManualOpenAction
                }
                return image.requiresBoundedLocalDecode
            }
        case .videoHTML:
            return renderedBlocks.contains { $0.htmlFallback?.kind == .videoPlaceholder }
        case .horizontalRule:
            return renderedBlocks.contains { $0.role == .horizontalRule }
        case .footnotes:
            return renderedBlocks.contains { $0.role == .footnote }
        case .detailsSummaryHTML:
            return renderedBlocks.contains { $0.htmlFallback?.kind == .detailsDisclosure }
        case .genericHTMLBlocks:
            return renderedBlocks.contains { $0.htmlFallback?.kind == .genericSanitizedText }
        case .mixedCJKEnglishJapaneseKorean:
            let text = renderedBlocks.map(\.plainText).joined(separator: " ")
            return containsCJK(text) && containsLatin(text) && containsKorean(text)
        case .escapedMarkerCharacters:
            return renderedBlocks.contains { $0.plainText.contains("*这行前后的星号应该被转义") }
                && renderedBlocks.contains { $0.plainText.contains("# 这行的井号应该显示成普通字符") }
        }
    }

    private var allInlineRuns: [NativeMarkdownInlineRun] {
        renderedBlocks.flatMap { block in
            block.inlineRuns
                + block.blockquoteLines.flatMap(\.inlineRuns)
                + block.listItems.flatMap(\.inlineRuns)
        }
    }

    private func containsLatin(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x0041...0x005A).contains(Int(scalar.value))
                || (0x0061...0x007A).contains(Int(scalar.value))
        }
    }

    private func containsCJK(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
                || (0x3040...0x30FF).contains(Int(scalar.value))
        }
    }

    private func containsKorean(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0xAC00...0xD7AF).contains(Int(scalar.value))
        }
    }
}

public struct IOSRichFixtureRenderReport: Equatable, Sendable {
    public let generatedAt: Date
    public let audit: IOSRichFixtureRenderAudit
    public let parserAudit: IOSParserContractAudit
    public let layoutSafetyAudit: IOSLayoutSafetyAudit
    public let conditionalRendererAudit: IOSLocalRendererConditionalGateAudit
    public let snapshotSignatures: [IOSRendererSnapshotSignature]

    public init(
        generatedAt: Date,
        audit: IOSRichFixtureRenderAudit,
        parserAudit: IOSParserContractAudit,
        layoutSafetyAudit: IOSLayoutSafetyAudit,
        conditionalRendererAudit: IOSLocalRendererConditionalGateAudit,
        snapshotSignatures: [IOSRendererSnapshotSignature]
    ) {
        self.generatedAt = generatedAt
        self.audit = audit
        self.parserAudit = parserAudit
        self.layoutSafetyAudit = layoutSafetyAudit
        self.conditionalRendererAudit = conditionalRendererAudit
        self.snapshotSignatures = snapshotSignatures
    }

    public var capturesRequiredRichFixtureRenderReport: Bool {
        audit.satisfiesStageOneRichFixtureRenderReport
            && parserAudit.satisfiesStageOneParserContract
            && layoutSafetyAudit.satisfiesStageOneLayoutSafety
            && conditionalRendererAudit.satisfiesStageOneConditionalRendererGates
            && hasCompleteSnapshotSignatureMatrix
    }

    public var requiredSnapshotSignatureMatrixCount: Int {
        IOSReaderThemeScheme.allCases.count * MobileFontTier.allCases.count
    }

    public var coveredSnapshotSignaturePairs: Set<String> {
        Set(snapshotSignatures.map(snapshotSignaturePair))
    }

    public var missingSnapshotSignaturePairs: Set<String> {
        requiredSnapshotSignaturePairs.subtracting(coveredSnapshotSignaturePairs)
    }

    public var hasCompleteSnapshotSignatureMatrix: Bool {
        missingSnapshotSignaturePairs.isEmpty
    }

    public var markdown: String {
        let rows = IOSRichFixtureRenderCategory.allCases.map { category in
            "| \(category.displayName) | \(audit.isCovered(category) ? "PASS" : "FAIL") |"
        }

        return ([
            "# Stage 1 iOS Rich Fixture Render Report",
            "",
            "- Generated: \(iso8601String(from: generatedAt))",
            "- Source bytes: \(audit.sourceByteCount)",
            "- Rendered blocks: \(audit.renderedBlocks.count)",
            "- Covered categories: \(audit.coveredCategories.count)/\(IOSRichFixtureRenderCategory.allCases.count)",
            "- Parser contract: \(parserAudit.satisfiesStageOneParserContract)",
            "- Layout safety: \(layoutSafetyAudit.satisfiesStageOneLayoutSafety)",
            "- Conditional renderer gates: \(conditionalRendererAudit.satisfiesStageOneConditionalRendererGates)",
            "- Snapshot signatures: \(coveredSnapshotSignaturePairs.count)/\(requiredSnapshotSignatureMatrixCount)",
            "- Missing snapshot signatures: \(missingSnapshotSignaturePairs.sorted().joined(separator: ", ").isEmpty ? "none" : missingSnapshotSignaturePairs.sorted().joined(separator: ", "))",
            "",
            "| Render type | Result |",
            "| --- | --- |"
        ] + rows).joined(separator: "\n") + "\n"
    }

    private var requiredSnapshotSignaturePairs: Set<String> {
        Set(IOSReaderThemeScheme.allCases.flatMap { themeScheme in
            MobileFontTier.allCases.map { fontTier in
                "\(themeScheme.rawValue):\(fontTier.rawValue)"
            }
        })
    }

    private func snapshotSignaturePair(_ signature: IOSRendererSnapshotSignature) -> String {
        "\(signature.themeScheme.rawValue):\(signature.fontTier.rawValue)"
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}

public enum IOSStageOneRealDeviceFlowStep: String, CaseIterable, Equatable, Sendable {
    case openMarkdown
    case renderRichFixture
    case searchDocument
    case fullSourceEdit
    case blockSourceEdit
    case saveWritableDocument
    case rotateReader

    public var displayName: String {
        switch self {
        case .openMarkdown:
            return "Open Markdown"
        case .renderRichFixture:
            return "Render rich fixture"
        case .searchDocument:
            return "Search document"
        case .fullSourceEdit:
            return "Full source edit"
        case .blockSourceEdit:
            return "Block source edit"
        case .saveWritableDocument:
            return "Save writable document"
        case .rotateReader:
            return "Rotate reader"
        }
    }
}

public enum IOSStageOneRealDeviceValidationStatus: String, Equatable, Sendable {
    case passed
    case blockedStaleDeviceProbe
    case blockedMissingRequiredProbeCommands
    case blockedStaleRequiredProbeCommands
    case blockedMissingPrerequisiteValidation
    case blockedNoConnectedIPhone12FamilyDevice
    case blockedMissingExplicitConnectionEvidence
    case blockedConnectedUnsupportedPhysicalDevice
    case blockedMissingVerifiedHardwareEvidence
    case blockedIncompleteManualFlow
    case blockedMissingStepSpecificManualFlowEvidence
    case blockedMissingPhysicalManualFlowEvidence
    case blockedMismatchedPhysicalManualFlowEvidence
    case blockedSplitPhysicalManualFlowEvidence
    case blockedManualFlowBeforeDeviceProbe
    case blockedStaleManualFlowEvidence
    case blockedMissingCurrentProbeBatchEvidence
}

public enum IOSStageOnePhysicalProbeCommandCoverageStatus: String, Equatable, Sendable {
    case satisfied
    case blockedMissingRequiredCommands
    case blockedStaleRequiredCommands
}

public struct IOSStageOnePhysicalProbeCommandEvidence: Equatable, Sendable {
    public let command: String
    public let observedAt: Date?

    public init(command: String, observedAt: Date?) {
        self.command = command
        self.observedAt = observedAt
    }
}

public enum IOSStageOnePhysicalDeviceEligibilityReason: String, Equatable, Sendable {
    case eligibleIPhone12FamilyDevice
    case simulatorDestination
    case disconnectedPhysicalDevice
    case missingExplicitConnectionEvidence
    case unsupportedHardwareFamily
}

public struct IOSStageOneRealDeviceFlowEvidence: Equatable, Sendable {
    public let step: IOSStageOneRealDeviceFlowStep
    public let observedAt: Date?
    public let evidenceSummary: String
    public let probeBatchObservedAt: Date?

    public init(
        step: IOSStageOneRealDeviceFlowStep,
        observedAt: Date?,
        evidenceSummary: String,
        probeBatchObservedAt: Date? = nil
    ) {
        self.step = step
        self.observedAt = observedAt
        self.evidenceSummary = evidenceSummary
        self.probeBatchObservedAt = probeBatchObservedAt
    }

    public var hasCompletionEvidence: Bool {
        observedAt != nil
            && !evidenceSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var hasStepSpecificFlowEvidence: Bool {
        guard hasCompletionEvidence else {
            return false
        }

        let normalizedSummary = evidenceSummary
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !containsNegatedStepActionClaim(normalizedSummary) else {
            return false
        }

        switch step {
        case .openMarkdown:
            return containsAny(["open", "opened", "picked", "handoff", "import"], in: normalizedSummary)
                && containsAny(["markdown", "document", "file", "fixture"], in: normalizedSummary)
        case .renderRichFixture:
            return containsAny(["render", "rendered", "preview"], in: normalizedSummary)
                && containsAny(["rich fixture", "canonical", "markdown", "overflow"], in: normalizedSummary)
        case .searchDocument:
            return containsAny(["search", "searched", "query"], in: normalizedSummary)
                && containsAny(["document", "match", "matches", "result", "results"], in: normalizedSummary)
        case .fullSourceEdit:
            return containsAny(["edit", "edited", "editor"], in: normalizedSummary)
                && containsAny(["full source", "source editor", "whole source", "markdown source"], in: normalizedSummary)
        case .blockSourceEdit:
            return containsAny(["edit", "edited", "editor"], in: normalizedSummary)
                && containsAny(["block source", "mapped block", "rendered block", "smallest mapped"], in: normalizedSummary)
        case .saveWritableDocument:
            return containsAny(["save", "saved", "write", "wrote"], in: normalizedSummary)
                && containsAny(["writable", "document", "fixture", "dirty state"], in: normalizedSummary)
        case .rotateReader:
            return containsAny(["rotate", "rotated", "orientation"], in: normalizedSummary)
                && containsAny(["reader", "document state", "state", "layout"], in: normalizedSummary)
        }
    }

    private func containsNegatedStepActionClaim(_ normalizedSummary: String) -> Bool {
        stepActionSignals.contains {
            containsNegatedStepActionSignal($0, in: normalizedSummary)
        }
    }

    private var stepActionSignals: [String] {
        switch step {
        case .openMarkdown:
            return ["open", "opened", "picked", "import"]
        case .renderRichFixture:
            return ["render", "rendered", "preview"]
        case .searchDocument:
            return ["search", "searched", "query"]
        case .fullSourceEdit, .blockSourceEdit:
            return ["edit", "edited"]
        case .saveWritableDocument:
            return ["save", "saved", "write", "wrote"]
        case .rotateReader:
            return ["rotate", "rotated"]
        }
    }

    private func containsNegatedStepActionSignal(
        _ signal: String,
        in normalizedSummary: String
    ) -> Bool {
        var searchRange = normalizedSummary.startIndex..<normalizedSummary.endIndex

        while let range = normalizedSummary.range(of: signal, range: searchRange) {
            if hasHardwareSignalBoundary(
                before: range.lowerBound,
                after: range.upperBound,
                in: normalizedSummary
            ) {
                let prefixStart = normalizedSummary.index(
                    range.lowerBound,
                    offsetBy: -96,
                    limitedBy: normalizedSummary.startIndex
                ) ?? normalizedSummary.startIndex
                let prefix = String(normalizedSummary[prefixStart..<range.lowerBound])
                if currentClauseHasStepActionNegation(prefix) {
                    return true
                }

                let suffixEnd = normalizedSummary.index(
                    range.upperBound,
                    offsetBy: 96,
                    limitedBy: normalizedSummary.endIndex
                ) ?? normalizedSummary.endIndex
                let suffix = String(normalizedSummary[range.upperBound..<suffixEnd])
                if currentClauseHasPostActionFailure(suffix) {
                    return true
                }
            }

            searchRange = range.upperBound..<normalizedSummary.endIndex
        }

        return false
    }

    private func currentClauseHasPostActionFailure(_ suffix: String) -> Bool {
        let currentClause = suffix
            .split(whereSeparator: { ".,;:\n|".contains($0) })
            .first
            .map(String.init)
            ?? suffix
        let tokens = currentClause
            .split { character in
                !(character.isLetter || character.isNumber || character == "'")
            }
            .map(String.init)
        let nearbyTokens = Array(tokens.prefix(10))

        guard !nearbyTokens.isEmpty else {
            return false
        }

        let hardFailureTokens: Set<String> = [
            "blocked",
            "crash",
            "crashed",
            "error",
            "errored",
            "failed",
            "failure",
            "incomplete",
            "timeout",
            "unsuccessful"
        ]

        if nearbyTokens.contains(where: { hardFailureTokens.contains($0) }) {
            return true
        }

        let failurePhrases: [[String]] = [
            ["could", "not"],
            ["did", "not"],
            ["does", "not"],
            ["unable", "to"]
        ]

        for index in nearbyTokens.indices {
            for phrase in failurePhrases where nearbyTokens[index...].starts(with: phrase) {
                return true
            }
        }

        return false
    }

    private func currentClauseHasStepActionNegation(_ prefix: String) -> Bool {
        let currentClause = prefix
            .split(whereSeparator: { ".,;:\n|".contains($0) })
            .last
            .map(String.init)
            ?? prefix
        let tokens = currentClause
            .split { character in
                !(character.isLetter || character.isNumber || character == "'")
            }
            .map(String.init)
        let recentTokens = Array(tokens.suffix(8))

        guard !recentTokens.isEmpty else {
            return false
        }

        let actionNegations: Set<String> = [
            "blocked",
            "can't",
            "cannot",
            "couldn't",
            "didn't",
            "doesn't",
            "don't",
            "failed",
            "hadn't",
            "hasn't",
            "haven't",
            "missing",
            "never",
            "no",
            "not",
            "unable",
            "without",
            "wouldn't"
        ]

        for index in recentTokens.indices where actionNegations.contains(recentTokens[index]) {
            if stepActionNegationAtIndexTargetsAction(index, in: recentTokens) {
                return true
            }
        }

        return false
    }

    private func stepActionNegationAtIndexTargetsAction(
        _ index: Int,
        in tokens: [String]
    ) -> Bool {
        let scopedTokens = Array(tokens.dropFirst(index + 1))
        if scopedTokens.contains("simulator") || scopedTokens.contains("simulators") {
            return false
        }

        if scopedTokens.first == "only" {
            return false
        }

        return true
    }

    public var hasPhysicalIPhone12FamilyEvidence: Bool {
        guard hasCompletionEvidence else {
            return false
        }

        let normalizedSummary = evidenceSummary
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !containsUnnegatedSimulatorClaim(normalizedSummary) else {
            return false
        }

        guard !containsPhysicalHardwareAbsenceClaim(normalizedSummary) else {
            return false
        }

        let physicalHardwareSignals = [
            "physical iphone 12",
            "physical iphone 12-class hardware",
            "iphone 12-family hardware",
            "iphone 12 family hardware",
            "iphone 12-class hardware",
            "iphone 12 class hardware",
            "iphone13,1",
            "iphone13,2",
            "iphone13,3",
            "iphone13,4"
        ]

        return physicalHardwareSignals.contains {
            containsBoundedHardwareSignal($0, in: normalizedSummary)
        }
    }

    private func containsPhysicalHardwareAbsenceClaim(_ normalizedSummary: String) -> Bool {
        let absenceClaims = [
            "no connected physical iphone 12",
            "no physical iphone 12",
            "without physical iphone 12",
            "missing physical iphone 12",
            "absent physical iphone 12",
            "not physical iphone 12",
            "no iphone 12-family hardware",
            "without iphone 12-family hardware",
            "missing iphone 12-family hardware",
            "absent iphone 12-family hardware",
            "not iphone 12-family hardware",
            "no iphone 12-class hardware",
            "without iphone 12-class hardware",
            "missing iphone 12-class hardware",
            "absent iphone 12-class hardware",
            "not iphone 12-class hardware",
            "no iphone 12 family hardware",
            "without iphone 12 family hardware",
            "missing iphone 12 family hardware",
            "absent iphone 12 family hardware",
            "not iphone 12 family hardware",
            "no iphone 12 class hardware",
            "without iphone 12 class hardware",
            "missing iphone 12 class hardware",
            "absent iphone 12 class hardware",
            "not iphone 12 class hardware",
            "no iphone13,1",
            "no iphone13,2",
            "no iphone13,3",
            "no iphone13,4"
        ]

        return absenceClaims.contains {
            normalizedSummary.contains($0)
        } || containsNearbyNegatedPhysicalHardwareSignal(in: normalizedSummary)
    }

    private func containsNearbyNegatedPhysicalHardwareSignal(in normalizedSummary: String) -> Bool {
        let physicalHardwareSignals = [
            "physical iphone 12",
            "physical iphone 12-class hardware",
            "iphone 12-family hardware",
            "iphone 12 family hardware",
            "iphone 12-class hardware",
            "iphone 12 class hardware",
            "iphone13,1",
            "iphone13,2",
            "iphone13,3",
            "iphone13,4"
        ]

        return physicalHardwareSignals.contains {
            containsNegatedPhysicalHardwareSignal($0, in: normalizedSummary)
        }
    }

    private func containsNegatedPhysicalHardwareSignal(
        _ signal: String,
        in normalizedSummary: String
    ) -> Bool {
        var searchRange = normalizedSummary.startIndex..<normalizedSummary.endIndex

        while let range = normalizedSummary.range(of: signal, range: searchRange) {
            let prefixStart = normalizedSummary.index(
                range.lowerBound,
                offsetBy: -96,
                limitedBy: normalizedSummary.startIndex
            ) ?? normalizedSummary.startIndex
            let prefix = String(normalizedSummary[prefixStart..<range.lowerBound])
            if currentClauseHasPhysicalHardwareNegation(prefix) {
                return true
            }

            searchRange = range.upperBound..<normalizedSummary.endIndex
        }

        return false
    }

    private func currentClauseHasPhysicalHardwareNegation(_ prefix: String) -> Bool {
        let currentClause = prefix
            .split(whereSeparator: { ".,;:\n|".contains($0) })
            .last
            .map(String.init)
            ?? prefix
        let tokens = currentClause
            .split { character in
                !(character.isLetter || character.isNumber || character == "'")
            }
            .map(String.init)
        let recentTokens = Array(tokens.suffix(8))

        guard !recentTokens.isEmpty else {
            return false
        }

        let singleTokenNegations: Set<String> = [
            "absent",
            "blocked",
            "can't",
            "cannot",
            "couldn't",
            "couldnt",
            "disconnected",
            "didn't",
            "didnt",
            "doesn't",
            "doesnt",
            "don't",
            "dont",
            "missing",
            "no",
            "none",
            "not",
            "failed",
            "hadn't",
            "hadnt",
            "hasn't",
            "hasnt",
            "haven't",
            "havent",
            "isn't",
            "isnt",
            "offline",
            "unavailable",
            "unpaired",
            "unable",
            "wasn't",
            "wasnt",
            "weren't",
            "werent",
            "without",
            "wouldn't",
            "wouldnt",
            "zero"
        ]
        let phraseNegations = [
            ["can", "not"],
            ["cannot"],
            ["are", "not"],
            ["could", "not"],
            ["did", "not"],
            ["does", "not"],
            ["do", "not"],
            ["had", "not"],
            ["has", "not"],
            ["have", "not"],
            ["is", "not"],
            ["was", "not"],
            ["were", "not"],
            ["would", "not"]
        ]

        for index in recentTokens.indices {
            let token = recentTokens[index]
            if singleTokenNegations.contains(token),
               negationAtIndexTargetsPhysicalHardware(index, in: recentTokens) {
                return true
            }

            for phrase in phraseNegations where recentTokens[index...].starts(with: phrase) {
                if negationAtIndexTargetsPhysicalHardware(index + phrase.count - 1, in: recentTokens) {
                    return true
                }
            }
        }

        return false
    }

    private func negationAtIndexTargetsPhysicalHardware(
        _ index: Int,
        in tokens: [String]
    ) -> Bool {
        let scopedTokens = Array(tokens.dropFirst(index + 1))
        if scopedTokens.contains("simulator") {
            return false
        }

        if scopedTokens.isEmpty {
            return true
        }

        let hardwareScopeTokens: Set<String> = [
            "a",
            "an",
            "any",
            "available",
            "connected",
            "current",
            "device",
            "devices",
            "detect",
            "detected",
            "family",
            "find",
            "found",
            "hardware",
            "identify",
            "identified",
            "ios",
            "iphone",
            "iphone12",
            "locate",
            "located",
            "observe",
            "observed",
            "on",
            "physical",
            "product",
            "signal",
            "the",
            "this",
            "to",
            "validate",
            "validated",
            "verify",
            "verified",
            "verified"
        ]

        return scopedTokens.allSatisfy { hardwareScopeTokens.contains($0) }
    }

    private func containsAny(
        _ needles: [String],
        in haystack: String
    ) -> Bool {
        needles.contains {
            haystack.contains($0)
        }
    }

    private func containsUnnegatedSimulatorClaim(_ normalizedSummary: String) -> Bool {
        let tokens = normalizedSummary
            .split { character in
                !(character.isLetter || character.isNumber || character == "'")
            }
            .map(String.init)

        for index in tokens.indices where tokens[index] == "simulator" || tokens[index] == "simulators" {
            let prefix = Array(tokens[max(tokens.startIndex, index - 4)..<index])
            guard prefix.contains("not") || prefix.contains("no") || prefix.contains("non") == true else {
                return true
            }
        }

        return false
    }

    public func referencesVerifiedHardwareSignal(
        _ acceptedSignals: Set<String>
    ) -> Bool {
        !verifiedHardwareSignalsReferenced(acceptedSignals).isEmpty
    }

    public func referencesProbeBatch(
        observedAt expectedProbeObservedAt: Date,
        tolerance: TimeInterval
    ) -> Bool {
        guard let probeBatchObservedAt else {
            return false
        }

        return abs(probeBatchObservedAt.timeIntervalSince(expectedProbeObservedAt)) <= tolerance
    }

    public func verifiedHardwareSignalsReferenced(
        _ acceptedSignals: Set<String>
    ) -> Set<String> {
        guard hasPhysicalIPhone12FamilyEvidence,
              !acceptedSignals.isEmpty else {
            return []
        }

        let normalizedAcceptedSignals = Set(acceptedSignals.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }.filter { !$0.isEmpty })

        guard !normalizedAcceptedSignals.isEmpty else {
            return []
        }

        let normalizedSummary = evidenceSummary
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return Set(normalizedAcceptedSignals.filter { signal in
            containsAffirmedBoundedHardwareSignal(signal, in: normalizedSummary)
        })
    }

    private func containsAffirmedBoundedHardwareSignal(
        _ signal: String,
        in normalizedSummary: String
    ) -> Bool {
        var searchRange = normalizedSummary.startIndex..<normalizedSummary.endIndex

        while let range = normalizedSummary.range(of: signal, range: searchRange) {
            if hasHardwareSignalBoundary(
                before: range.lowerBound,
                after: range.upperBound,
                in: normalizedSummary
            ),
               !continuesIntoLongerIPhone12MarketingName(
                   signal,
                   after: range.upperBound,
                   in: normalizedSummary
               ) {
                let prefixStart = normalizedSummary.index(
                    range.lowerBound,
                    offsetBy: -96,
                    limitedBy: normalizedSummary.startIndex
                ) ?? normalizedSummary.startIndex
                let prefix = String(normalizedSummary[prefixStart..<range.lowerBound])
                if !currentClauseHasVerifiedHardwareReferenceNegation(prefix) {
                    return true
                }
            }

            searchRange = range.upperBound..<normalizedSummary.endIndex
        }

        return false
    }

    private func containsBoundedHardwareSignal(
        _ signal: String,
        in normalizedSummary: String
    ) -> Bool {
        var searchRange = normalizedSummary.startIndex..<normalizedSummary.endIndex

        while let range = normalizedSummary.range(of: signal, range: searchRange) {
            if hasHardwareSignalBoundary(
                before: range.lowerBound,
                after: range.upperBound,
                in: normalizedSummary
            ),
               !continuesIntoLongerIPhone12MarketingName(
                   signal,
                   after: range.upperBound,
                   in: normalizedSummary
               ) {
                return true
            }

            searchRange = range.upperBound..<normalizedSummary.endIndex
        }

        return false
    }

    private func currentClauseHasVerifiedHardwareReferenceNegation(_ prefix: String) -> Bool {
        let currentClause = prefix
            .split(whereSeparator: { ".,;:\n|".contains($0) })
            .last
            .map(String.init)
            ?? prefix
        let tokens = currentClause
            .split { character in
                !(character.isLetter || character.isNumber || character == "'")
            }
            .map(String.init)
        let recentTokens = Array(tokens.suffix(8))

        guard !recentTokens.isEmpty else {
            return false
        }

        let singleTokenNegations: Set<String> = [
            "absent",
            "blocked",
            "can't",
            "cannot",
            "couldn't",
            "couldnt",
            "disconnected",
            "didn't",
            "didnt",
            "doesn't",
            "doesnt",
            "don't",
            "dont",
            "failed",
            "mismatch",
            "mismatched",
            "missing",
            "no",
            "none",
            "not",
            "offline",
            "unable",
            "unmatched",
            "unavailable",
            "unpaired",
            "unverified",
            "without",
            "wrong"
        ]
        let phraseNegations = [
            ["can", "not"],
            ["could", "not"],
            ["did", "not"],
            ["does", "not"],
            ["do", "not"],
            ["is", "not"],
            ["was", "not"],
            ["were", "not"],
            ["would", "not"]
        ]

        for index in recentTokens.indices {
            let token = recentTokens[index]
            if singleTokenNegations.contains(token),
               negationAtIndexTargetsVerifiedHardwareReference(index, in: recentTokens) {
                return true
            }

            for phrase in phraseNegations where recentTokens[index...].starts(with: phrase) {
                if negationAtIndexTargetsVerifiedHardwareReference(
                    index + phrase.count - 1,
                    in: recentTokens
                ) {
                    return true
                }
            }
        }

        return false
    }

    private func negationAtIndexTargetsVerifiedHardwareReference(
        _ index: Int,
        in tokens: [String]
    ) -> Bool {
        let scopedTokens = Array(tokens.dropFirst(index + 1))
        if scopedTokens.contains("simulator") || scopedTokens.contains("simulators") {
            return false
        }

        if scopedTokens.first == "only" {
            return false
        }

        if scopedTokens.isEmpty {
            return true
        }

        let hardwareReferenceScopeTokens: Set<String> = [
            "a",
            "an",
            "any",
            "available",
            "class",
            "connected",
            "current",
            "device",
            "evidence",
            "family",
            "hardware",
            "identified",
            "identify",
            "ios",
            "iphone",
            "match",
            "matched",
            "matching",
            "model",
            "on",
            "physical",
            "product",
            "probe",
            "reference",
            "referenced",
            "signal",
            "the",
            "this",
            "token",
            "validated",
            "verified",
            "verify"
        ]

        return scopedTokens.allSatisfy { hardwareReferenceScopeTokens.contains($0) }
    }

    private func hasHardwareSignalBoundary(
        before start: String.Index,
        after end: String.Index,
        in text: String
    ) -> Bool {
        let hasValidPrefix = start == text.startIndex
            || isHardwareSignalBoundary(text[text.index(before: start)])
        let hasValidSuffix = end == text.endIndex
            || isHardwareSignalBoundary(text[end])

        return hasValidPrefix && hasValidSuffix
    }

    private func continuesIntoLongerIPhone12MarketingName(
        _ signal: String,
        after end: String.Index,
        in text: String
    ) -> Bool {
        let longerSuffixesBySignal = [
            "iphone 12": ["mini", "pro", "pro max"],
            "iphone 12 pro": ["max"]
        ]

        guard let longerSuffixes = longerSuffixesBySignal[signal] else {
            return false
        }

        let remaining = String(text[end...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return longerSuffixes.contains { suffix in
            guard remaining.hasPrefix(suffix) else {
                return false
            }

            let suffixEnd = remaining.index(remaining.startIndex, offsetBy: suffix.count)
            return suffixEnd == remaining.endIndex
                || isHardwareSignalBoundary(remaining[suffixEnd])
        }
    }

    private func isHardwareSignalBoundary(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy {
            !CharacterSet.alphanumerics.contains($0)
        }
    }
}

public struct IOSStageOneRealDeviceManualFlowAudit: Equatable, Sendable {
    public let evidenceItems: [IOSStageOneRealDeviceFlowEvidence]
    public let generatedAt: Date?
    public let maximumEvidenceAge: TimeInterval

    public init(
        evidenceItems: [IOSStageOneRealDeviceFlowEvidence],
        generatedAt: Date? = nil,
        maximumEvidenceAge: TimeInterval = 3_600
    ) {
        self.evidenceItems = evidenceItems
        self.generatedAt = generatedAt
        self.maximumEvidenceAge = max(1, maximumEvidenceAge)
    }

    public var completedStepsWithEvidence: Set<IOSStageOneRealDeviceFlowStep> {
        Set(evidenceItems.filter(\.hasCompletionEvidence).map(\.step))
    }

    public var completedStepsWithPhysicalIPhone12FamilyEvidence: Set<IOSStageOneRealDeviceFlowStep> {
        Set(evidenceItems.filter(\.hasPhysicalIPhone12FamilyEvidence).map(\.step))
    }

    public var completedStepsWithCurrentEvidence: Set<IOSStageOneRealDeviceFlowStep> {
        Set(evidenceItems.filter(hasCurrentCompletionEvidence).map(\.step))
    }

    public var completedStepsWithStepSpecificFlowEvidence: Set<IOSStageOneRealDeviceFlowStep> {
        Set(evidenceItems.filter(\.hasStepSpecificFlowEvidence).map(\.step))
    }

    public var missingEvidenceSteps: Set<IOSStageOneRealDeviceFlowStep> {
        Set(IOSStageOneRealDeviceFlowStep.allCases).subtracting(completedStepsWithEvidence)
    }

    public var missingStepSpecificFlowEvidenceSteps: Set<IOSStageOneRealDeviceFlowStep> {
        Set(IOSStageOneRealDeviceFlowStep.allCases)
            .subtracting(completedStepsWithStepSpecificFlowEvidence)
    }

    public var missingPhysicalIPhone12FamilyEvidenceSteps: Set<IOSStageOneRealDeviceFlowStep> {
        Set(IOSStageOneRealDeviceFlowStep.allCases)
            .subtracting(completedStepsWithPhysicalIPhone12FamilyEvidence)
    }

    public var staleOrFutureEvidenceSteps: Set<IOSStageOneRealDeviceFlowStep> {
        completedStepsWithEvidence.subtracting(completedStepsWithCurrentEvidence)
    }

    public var hasEvidenceForEveryRequiredStep: Bool {
        missingEvidenceSteps.isEmpty
    }

    public var hasStepSpecificFlowEvidenceForEveryRequiredStep: Bool {
        missingStepSpecificFlowEvidenceSteps.isEmpty
    }

    public var hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep: Bool {
        missingPhysicalIPhone12FamilyEvidenceSteps.isEmpty
    }

    public var hasCurrentEvidenceForEveryRequiredStep: Bool {
        Set(IOSStageOneRealDeviceFlowStep.allCases).subtracting(completedStepsWithCurrentEvidence).isEmpty
    }

    private func hasCurrentCompletionEvidence(
        _ evidence: IOSStageOneRealDeviceFlowEvidence
    ) -> Bool {
        guard evidence.hasCompletionEvidence,
              let observedAt = evidence.observedAt else {
            return false
        }

        guard let generatedAt else {
            return true
        }

        let age = generatedAt.timeIntervalSince(observedAt)
        return age >= 0 && age <= maximumEvidenceAge
    }
}

public struct IOSStageOnePhysicalDeviceCandidate: Equatable, Sendable {
    public let name: String
    public let osVersion: String?
    public let identifier: String
    public let hardwareModel: String?
    public let isConnected: Bool
    public let isSimulator: Bool
    public let hasExplicitConnectionEvidence: Bool
    public let hasExplicitSimulatorEvidence: Bool

    public init(
        name: String,
        osVersion: String?,
        identifier: String,
        hardwareModel: String? = nil,
        isConnected: Bool,
        isSimulator: Bool,
        hasExplicitConnectionEvidence: Bool? = nil,
        hasExplicitSimulatorEvidence: Bool? = nil
    ) {
        self.name = name
        self.osVersion = osVersion
        self.identifier = identifier
        self.hardwareModel = hardwareModel
        self.isConnected = isConnected
        self.isSimulator = isSimulator
        self.hasExplicitConnectionEvidence = hasExplicitConnectionEvidence ?? true
        self.hasExplicitSimulatorEvidence = hasExplicitSimulatorEvidence ?? isSimulator
    }

    public var isIPhone12FamilyPhysicalDevice: Bool {
        !isSimulator && Self.isIPhone12FamilyIdentifier(deviceFamilyName)
    }

    public var isEligibleConnectedDevice: Bool {
        isConnected && hasExplicitConnectionEvidence && isIPhone12FamilyPhysicalDevice
    }

    public var hasVerifiedIPhone12FamilyHardwareEvidence: Bool {
        guard let hardwareModel = hardwareModel?.trimmingCharacters(in: .whitespacesAndNewlines),
              !hardwareModel.isEmpty else {
            return false
        }

        return !isSimulator && Self.hasSpecificIPhone12FamilyHardwareSignal(hardwareModel)
    }

    public var isVerifiedEligibleConnectedDevice: Bool {
        isConnected && hasExplicitConnectionEvidence && hasVerifiedIPhone12FamilyHardwareEvidence
    }

    public var manualEvidenceHardwareSignals: Set<String> {
        guard isVerifiedEligibleConnectedDevice,
              let hardwareModel = hardwareModel?.trimmingCharacters(in: .whitespacesAndNewlines),
              !hardwareModel.isEmpty else {
            return []
        }

        return Set(Self.normalizedIPhone12FamilyCandidates(from: hardwareModel).compactMap { candidate in
            let normalizedCandidate = candidate.lowercased()
            if Self.iPhone12FamilyHardwareIdentifiers.contains(normalizedCandidate) {
                return candidate.lowercased()
            }

            if Self.iPhone12FamilyMarketingNames.contains(normalizedCandidate),
               normalizedCandidate != "iphone 12" {
                return candidate.lowercased()
            }

            return nil
        })
    }

    public var eligibilityReason: IOSStageOnePhysicalDeviceEligibilityReason {
        if isSimulator {
            return .simulatorDestination
        }

        if !isConnected {
            return .disconnectedPhysicalDevice
        }

        if !hasExplicitConnectionEvidence {
            return .missingExplicitConnectionEvidence
        }

        if !isIPhone12FamilyPhysicalDevice {
            return .unsupportedHardwareFamily
        }

        return .eligibleIPhone12FamilyDevice
    }

    public var deviceFamilyName: String {
        hardwareModel?.isEmpty == false ? hardwareModel! : name
    }

    private static let iPhone12FamilyMarketingNames: Set<String> = [
        "iphone 12",
        "iphone 12 mini",
        "iphone 12 pro",
        "iphone 12 pro max"
    ]

    private static let iPhone12FamilyHardwareIdentifiers: Set<String> = [
        "iphone13,1",
        "iphone13,2",
        "iphone13,3",
        "iphone13,4"
    ]

    private static func isIPhone12FamilyIdentifier(_ value: String) -> Bool {
        guard !hasConflictingIPhoneIdentity(value) else {
            return false
        }

        return normalizedIPhone12FamilyCandidates(from: value).contains { candidate in
            let normalizedCandidate = candidate.lowercased()
            return iPhone12FamilyMarketingNames.contains(normalizedCandidate)
                || iPhone12FamilyHardwareIdentifiers.contains(normalizedCandidate)
        }
    }

    private static func hasSpecificIPhone12FamilyHardwareSignal(_ value: String) -> Bool {
        guard !hasConflictingIPhoneIdentity(value) else {
            return false
        }

        return normalizedIPhone12FamilyCandidates(from: value).contains { candidate in
            let normalizedCandidate = candidate.lowercased()
            return iPhone12FamilyHardwareIdentifiers.contains(normalizedCandidate)
                || (
                    iPhone12FamilyMarketingNames.contains(normalizedCandidate)
                        && normalizedCandidate != "iphone 12"
                )
        }
    }

    private static func normalizedIPhone12FamilyCandidates(from value: String) -> [String] {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        var candidates = [trimmed]
        appendCanonicalProductIdentifier(from: trimmed, to: &candidates)

        if trimmed.last == ")",
           let openIndex = trimmed.lastIndex(of: "(") {
            let marketingName = trimmed[..<openIndex]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let hardwareIdentifier = trimmed[trimmed.index(after: openIndex)..<trimmed.index(before: trimmed.endIndex)]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !marketingName.isEmpty {
                let candidate = String(marketingName)
                candidates.append(candidate)
                appendCanonicalProductIdentifier(from: candidate, to: &candidates)
            }
            if !hardwareIdentifier.isEmpty {
                let candidate = String(hardwareIdentifier)
                candidates.append(candidate)
                appendCanonicalProductIdentifier(from: candidate, to: &candidates)
            }
        }

        return candidates
    }

    private static func hasConflictingIPhoneIdentity(_ value: String) -> Bool {
        let supportStates = iPhoneIdentitySupportStates(in: value)
        return supportStates.contains(true) && supportStates.contains(false)
    }

    private static func iPhoneIdentitySupportStates(in value: String) -> [Bool] {
        productIdentifierSupportStates(in: value) + marketingNameSupportStates(in: value)
    }

    private static func productIdentifierSupportStates(in value: String) -> [Bool] {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty,
              let expression = try? NSRegularExpression(
                  pattern: #"(?<![a-z0-9])iphone[0-9]{1,3},[0-9]{1,3}(?:-[a-z0-9]+)?(?![a-z0-9])"#
              ) else {
            return []
        }

        let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        return expression.matches(in: normalized, range: range).compactMap { match in
            guard let tokenRange = Range(match.range, in: normalized) else {
                return nil
            }

            let baseIdentifier = normalized[tokenRange]
                .split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
                .first
                .map(String.init)
                ?? String(normalized[tokenRange])
            return iPhone12FamilyHardwareIdentifiers.contains(baseIdentifier)
        }
    }

    private static func marketingNameSupportStates(in value: String) -> [Bool] {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty,
              let expression = try? NSRegularExpression(
                  pattern: #"(?<![a-z0-9])iphone\s+([0-9]{1,3})(?:\s+(?:mini|plus|pro(?:\s+max)?|air))?(?![a-z0-9])"#
              ) else {
            return []
        }

        let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        return expression.matches(in: normalized, range: range).compactMap { match in
            guard let generationRange = Range(match.range(at: 1), in: normalized),
                  let generation = Int(normalized[generationRange]) else {
                return nil
            }

            return generation == 12
        }
    }

    private static func appendCanonicalProductIdentifier(
        from value: String,
        to candidates: inout [String]
    ) {
        guard let canonicalIdentifier = canonicalIPhone12FamilyProductIdentifier(from: value),
              !candidates.contains(where: { $0.caseInsensitiveCompare(canonicalIdentifier) == .orderedSame }) else {
            return
        }

        candidates.append(canonicalIdentifier)
    }

    private static func canonicalIPhone12FamilyProductIdentifier(from value: String) -> String? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = normalized.split(
            separator: "-",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )

        guard let basePart = parts.first else {
            return nil
        }

        let baseIdentifier = String(basePart)
        guard iPhone12FamilyHardwareIdentifiers.contains(baseIdentifier) else {
            return nil
        }

        if parts.count == 1 {
            return baseIdentifier
        }

        let suffix = String(parts[1])
        guard !suffix.isEmpty,
              suffix.allSatisfy({ $0.isLetter || $0.isNumber }) else {
            return nil
        }

        return baseIdentifier
    }
}

public struct IOSXctraceDeviceListParser: Equatable, Sendable {
    public init() {}

    public func parseCandidates(from output: String) -> [IOSStageOnePhysicalDeviceCandidate] {
        var section: DeviceSection?
        var candidates: [IOSStageOnePhysicalDeviceCandidate] = []

        for rawLine in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            switch line {
            case "== Devices ==":
                section = .devices
                continue
            case "== Devices Offline ==":
                section = .devicesOffline
                continue
            case "== Simulators ==":
                section = .simulators
                continue
            default:
                break
            }

            guard let section,
                  !line.isEmpty,
                  let parsed = parseDeviceLine(line, section: section) else {
                continue
            }

            candidates.append(parsed)
        }

        return candidates
    }

    private func parseDeviceLine(
        _ line: String,
        section: DeviceSection
    ) -> IOSStageOnePhysicalDeviceCandidate? {
        guard let identifierRange = lastParenthesizedRange(in: line) else {
            return nil
        }

        let identifier = String(line[identifierRange].dropFirst().dropLast())
        let nameAndVersion = line[..<identifierRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let parsedVersion: (name: String, version: String?)
        if let versionRange = lastParenthesizedRange(in: nameAndVersion) {
            let version = String(nameAndVersion[versionRange].dropFirst().dropLast())
            if isVersionLike(version) {
                let name = nameAndVersion[..<versionRange.lowerBound]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                parsedVersion = (String(name), version)
            } else {
                parsedVersion = (String(nameAndVersion), nil)
            }
        } else {
            parsedVersion = (String(nameAndVersion), nil)
        }

        guard !parsedVersion.name.isEmpty, !identifier.isEmpty else {
            return nil
        }

        return IOSStageOnePhysicalDeviceCandidate(
            name: parsedVersion.name,
            osVersion: parsedVersion.version,
            identifier: identifier,
            isConnected: section != .devicesOffline,
            isSimulator: section == .simulators,
            hasExplicitSimulatorEvidence: section == .simulators
        )
    }

    private func lastParenthesizedRange(in text: String) -> Range<String.Index>? {
        guard text.last == ")",
              let openIndex = text.lastIndex(of: "(") else {
            return nil
        }

        return openIndex..<text.endIndex
    }

    private func isVersionLike(_ text: String) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.")
        return !text.isEmpty
            && text.rangeOfCharacter(from: allowedCharacters.inverted) == nil
            && text.contains { $0.isNumber }
    }

    private enum DeviceSection {
        case devices
        case devicesOffline
        case simulators
    }
}

public struct IOSDevicectlDeviceListParser: Equatable, Sendable {
    public init() {}

    public func parseCandidates(from output: String) -> [IOSStageOnePhysicalDeviceCandidate] {
        let jsonCandidates = parseJSONCandidates(from: output)
        let tableCandidates = parseTableCandidates(from: output)

        switch (jsonCandidates.isEmpty, tableCandidates.isEmpty) {
        case (false, false):
            return merge(jsonCandidates: jsonCandidates, tableCandidates: tableCandidates)
        case (false, true):
            return jsonCandidates
        case (true, false):
            return tableCandidates
        case (true, true):
            return []
        }
    }

    private func parseJSONCandidates(from output: String) -> [IOSStageOnePhysicalDeviceCandidate] {
        guard let root = devicectlDeviceListJSONRoot(from: output),
              let result = root["result"] as? [String: Any],
              let devices = result["devices"] as? [[String: Any]] else {
            return []
        }

        return devices.compactMap(parseDevice)
    }

    private func devicectlDeviceListJSONRoot(from output: String) -> [String: Any]? {
        jsonObjectCandidates(from: output).lazy.compactMap { candidate -> [String: Any]? in
            guard let data = candidate.data(using: .utf8),
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let result = root["result"] as? [String: Any],
                  result["devices"] is [[String: Any]] else {
                return nil
            }

            return root
        }.first
    }

    private func jsonObjectCandidates(from output: String) -> [String] {
        var candidates: [String] = []
        var searchStart = output.startIndex

        while let openBrace = output[searchStart...].firstIndex(of: "{") {
            guard let closeBrace = matchingClosingBrace(in: output, from: openBrace) else {
                break
            }

            candidates.append(String(output[openBrace...closeBrace]))
            searchStart = output.index(after: closeBrace)
        }

        return candidates
    }

    private func matchingClosingBrace(in text: String, from openBrace: String.Index) -> String.Index? {
        var index = openBrace
        var depth = 0
        var isInsideString = false
        var isEscaped = false

        while index < text.endIndex {
            let character = text[index]

            if isInsideString {
                if isEscaped {
                    isEscaped = false
                } else if character == "\\" {
                    isEscaped = true
                } else if character == "\"" {
                    isInsideString = false
                }
            } else if character == "\"" {
                isInsideString = true
            } else if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
                if depth == 0 {
                    return index
                }
            }

            index = text.index(after: index)
        }

        return nil
    }

    private func parseTableCandidates(from output: String) -> [IOSStageOnePhysicalDeviceCandidate] {
        output
            .split(separator: "\n", omittingEmptySubsequences: false)
            .compactMap { parseTableLine(String($0)) }
    }

    private func merge(
        jsonCandidates: [IOSStageOnePhysicalDeviceCandidate],
        tableCandidates: [IOSStageOnePhysicalDeviceCandidate]
    ) -> [IOSStageOnePhysicalDeviceCandidate] {
        var consumedTableIdentifiers = Set<String>()
        let tableCandidatesByIdentifier = Dictionary(
            tableCandidates.map { ($0.identifier, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let mergedJSONCandidates = jsonCandidates.map { jsonCandidate in
            guard let tableCandidate = tableCandidatesByIdentifier[jsonCandidate.identifier] else {
                return jsonCandidate
            }

            consumedTableIdentifiers.insert(tableCandidate.identifier)
            return IOSStageOnePhysicalDeviceCandidate(
                name: jsonCandidate.name,
                osVersion: jsonCandidate.osVersion ?? tableCandidate.osVersion,
                identifier: jsonCandidate.identifier,
                hardwareModel: jsonCandidate.hardwareModel ?? tableCandidate.hardwareModel,
                isConnected: mergedConnectionState(jsonCandidate, tableCandidate),
                isSimulator: mergedSimulatorClassification(jsonCandidate, tableCandidate),
                hasExplicitConnectionEvidence: jsonCandidate.hasExplicitConnectionEvidence
                    || tableCandidate.hasExplicitConnectionEvidence,
                hasExplicitSimulatorEvidence: jsonCandidate.hasExplicitSimulatorEvidence
                    || tableCandidate.hasExplicitSimulatorEvidence
            )
        }

        return mergedJSONCandidates + tableCandidates.filter {
            !consumedTableIdentifiers.contains($0.identifier)
        }
    }

    private func mergedSimulatorClassification(
        _ lhs: IOSStageOnePhysicalDeviceCandidate,
        _ rhs: IOSStageOnePhysicalDeviceCandidate
    ) -> Bool {
        if lhs.isSimulator == rhs.isSimulator {
            return lhs.isSimulator
        }

        if lhs.hasExplicitSimulatorEvidence || rhs.hasExplicitSimulatorEvidence {
            return true
        }

        return false
    }

    private func mergedConnectionState(
        _ lhs: IOSStageOnePhysicalDeviceCandidate,
        _ rhs: IOSStageOnePhysicalDeviceCandidate
    ) -> Bool {
        if lhs.hasExplicitConnectionEvidence && rhs.hasExplicitConnectionEvidence {
            return lhs.isConnected && rhs.isConnected
        }

        if lhs.hasExplicitConnectionEvidence {
            return lhs.isConnected
        }

        if rhs.hasExplicitConnectionEvidence {
            return rhs.isConnected
        }

        return false
    }

    private func parseTableLine(_ line: String) -> IOSStageOnePhysicalDeviceCandidate? {
        let columns = splitDevicectlTableColumns(line)

        guard columns.count == 5,
              columns[0] != "Name",
              !columns[0].hasPrefix("-"),
              let name = nonEmptyString(columns[0]),
              let identifier = nonEmptyString(columns[2]),
              let rawState = nonEmptyString(columns[3]),
              let model = nonEmptyString(columns[4]),
              let state = normalizedTableState(rawState),
              Self.knownTableDeviceStates.contains(state) else {
            return nil
        }

        return IOSStageOnePhysicalDeviceCandidate(
            name: name,
            osVersion: nil,
            identifier: identifier,
            hardwareModel: hardwareIdentifier(fromTableModel: model),
            isConnected: tableStateIsConnected(rawState),
            isSimulator: model.localizedCaseInsensitiveContains("Simulator"),
            hasExplicitConnectionEvidence: true,
            hasExplicitSimulatorEvidence: model.localizedCaseInsensitiveContains("Simulator")
        )
    }

    private func splitDevicectlTableColumns(_ line: String) -> [String] {
        var columns: [String] = []
        var current = ""
        var pendingWhitespace = ""

        for character in line {
            if character.isWhitespace {
                pendingWhitespace.append(character)
                continue
            }

            if pendingWhitespace.count >= 2 {
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    columns.append(trimmed)
                }
                current = ""
            } else {
                current.append(contentsOf: pendingWhitespace)
            }

            pendingWhitespace = ""
            current.append(character)
        }

        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            columns.append(trimmed)
        }

        return columns
    }

    private static let knownTableDeviceStates: Set<String> = [
        "available",
        "unavailable"
    ]

    private func normalizedTableState(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseState = trimmed
            .split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map(String.init)
            ?? trimmed
        return baseState.isEmpty ? nil : baseState.lowercased()
    }

    private func tableStateIsConnected(_ value: String) -> Bool {
        let normalizedValue = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard normalizedTableState(normalizedValue) == "available" else {
            return false
        }

        let disconnectedQualifiers = [
            "disconnected",
            "not paired",
            "offline",
            "unpaired",
            "untrusted"
        ]

        return !disconnectedQualifiers.contains {
            normalizedValue.contains($0)
        }
    }

    private func parseDevice(_ device: [String: Any]) -> IOSStageOnePhysicalDeviceCandidate? {
        let deviceProperties = device["deviceProperties"] as? [String: Any]
        let hardwareProperties = device["hardwareProperties"] as? [String: Any]
        let connectionProperties = device["connectionProperties"] as? [String: Any]

        guard let name = firstNonEmptyString([
            deviceProperties?["name"],
            device["name"],
            device["deviceName"],
            device["displayName"]
        ]),
              let identifier = firstNonEmptyString([
                  device["identifier"],
                  device["id"],
                  device["udid"],
                  device["deviceIdentifier"],
                  deviceProperties?["identifier"],
                  deviceProperties?["udid"],
                  deviceProperties?["deviceIdentifier"],
                  connectionProperties?["identifier"],
                  connectionProperties?["udid"],
                  connectionProperties?["deviceIdentifier"]
              ]) else {
            return nil
        }

        let hardwareModel = firstNonEmptyString([
            hardwareProperties?["productType"],
            hardwareProperties?["thinningProductType"],
            hardwareProperties?["hardwareIdentifier"],
            hardwareProperties?["productIdentifier"],
            hardwareProperties?["modelIdentifier"],
            hardwareProperties?["modelCode"],
            hardwareProperties?["deviceClass"],
            hardwareProperties?["marketingName"],
            hardwareProperties?["hardwareModel"],
            hardwareProperties?["model"],
            hardwareProperties?["deviceType"]
        ])
        let reality = firstNonEmptyString([
            hardwareProperties?["reality"],
            hardwareProperties?["deviceReality"],
            hardwareProperties?["targetType"],
            hardwareProperties?["platformType"],
            deviceProperties?["reality"],
            deviceProperties?["deviceReality"]
        ]).flatMap(normalizedReality)
        let hasSimulatorEvidence = hasSimulatorEvidence(
            deviceProperties: deviceProperties,
            hardwareProperties: hardwareProperties,
            connectionProperties: connectionProperties
        )
        let hasExplicitSimulatorEvidence = hasSimulatorEvidence
            || (reality != nil && reality != "physical")
        let deviceState = nonEmptyString(device["state"])
            ?? nonEmptyString(device["availability"])
            ?? nonEmptyString(deviceProperties?["state"])
            ?? nonEmptyString(deviceProperties?["availability"])
            ?? nonEmptyString(connectionProperties?["state"])
            ?? nonEmptyString(connectionProperties?["availability"])
        let tunnelState = nonEmptyString(connectionProperties?["tunnelState"])
        let pairingState = nonEmptyString(connectionProperties?["pairingState"])
        let explicitConnectionFlag = firstBoolean([
            connectionProperties?["connected"],
            connectionProperties?["isConnected"],
            connectionProperties?["available"],
            connectionProperties?["isAvailable"],
            deviceProperties?["connected"],
            deviceProperties?["isConnected"],
            deviceProperties?["available"],
            deviceProperties?["isAvailable"],
            device["connected"],
            device["isConnected"],
            device["available"],
            device["isAvailable"]
        ])
        let hasExplicitConnectionEvidence = deviceState != nil
            || tunnelState != nil
            || pairingState != nil
            || explicitConnectionFlag != nil

        return IOSStageOnePhysicalDeviceCandidate(
            name: name,
            osVersion: normalizedOSVersion(from: firstPresentValue([
                deviceProperties?["osVersionNumber"],
                deviceProperties?["operatingSystemVersion"],
                deviceProperties?["osVersion"],
                deviceProperties?["productVersion"],
                deviceProperties?["buildVersion"],
                deviceProperties?["systemVersion"],
                device["osVersion"],
                device["operatingSystemVersion"]
            ])),
            identifier: identifier,
            hardwareModel: hardwareModel,
            isConnected: isConnected(
                deviceState: deviceState,
                tunnelState: tunnelState,
                pairingState: pairingState,
                explicitConnectionFlag: explicitConnectionFlag
            ),
            isSimulator: reality != "physical" || hasSimulatorEvidence,
            hasExplicitConnectionEvidence: hasExplicitConnectionEvidence,
            hasExplicitSimulatorEvidence: hasExplicitSimulatorEvidence
        )
    }

    private func hasSimulatorEvidence(
        deviceProperties: [String: Any]?,
        hardwareProperties: [String: Any]?,
        connectionProperties: [String: Any]?
    ) -> Bool {
        [
            hardwareProperties?["deviceType"],
            hardwareProperties?["platform"],
            hardwareProperties?["target"],
            hardwareProperties?["runtime"],
            deviceProperties?["deviceType"],
            deviceProperties?["platform"],
            connectionProperties?["transportType"]
        ].contains { value in
            normalizedSimulatorEvidence(from: value) != nil
        }
    }

    private func normalizedSimulatorEvidence(from value: Any?) -> String? {
        guard let string = nonEmptyString(value)?.lowercased() else {
            return nil
        }

        let simulatorMarkers = [
            "coresimulator",
            "core simulator",
            "ios simulator",
            "iphonesimulator",
            "simulator"
        ]

        return simulatorMarkers.first { string.contains($0) }
    }

    private func isConnected(
        deviceState: String?,
        tunnelState: String?,
        pairingState: String?,
        explicitConnectionFlag: Bool?
    ) -> Bool {
        if connectionStateHasDisconnectedQualifier(pairingState)
            || normalizedConnectionState(pairingState) == "unpaired" {
            return false
        }

        if connectionStateHasDisconnectedQualifier(deviceState) {
            return false
        }

        let normalizedDeviceState = normalizedConnectionState(deviceState)
        if let normalizedDeviceState, normalizedDeviceState != "available" {
            return false
        }

        if connectionStateHasDisconnectedQualifier(tunnelState) {
            return false
        }

        if let normalizedTunnelState = normalizedConnectionState(tunnelState) {
            return normalizedTunnelState == "connected"
        }

        if let explicitConnectionFlag {
            return explicitConnectionFlag
        }

        return normalizedDeviceState == "available"
    }

    private func connectionStateHasDisconnectedQualifier(_ value: String?) -> Bool {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !value.isEmpty else {
            return false
        }

        let disconnectedQualifiers = [
            "disconnected",
            "not paired",
            "offline",
            "unpaired",
            "untrusted"
        ]

        return disconnectedQualifiers.contains {
            value.contains($0)
        }
    }

    private func normalizedConnectionState(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseState = trimmed
            .split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            .first
            .map(String.init)
            ?? trimmed
        return baseState.isEmpty ? nil : baseState.lowercased()
    }

    private func normalizedOSVersion(from value: Any?) -> String? {
        if let version = nonEmptyString(value) {
            return version.split(separator: " ").first.map(String.init)
        }

        guard let dictionary = value as? [String: Any] else {
            return nil
        }

        let major = numericVersionComponent(dictionary["major"] ?? dictionary["majorVersion"])
        let minor = numericVersionComponent(dictionary["minor"] ?? dictionary["minorVersion"])
        let patch = numericVersionComponent(
            dictionary["patch"] ?? dictionary["patchVersion"] ?? dictionary["bugfixVersion"]
        )

        guard let major, let minor else {
            return nil
        }

        if let patch {
            return "\(major).\(minor).\(patch)"
        }

        return "\(major).\(minor)"
    }

    private func normalizedReality(from value: String?) -> String? {
        normalizedConnectionState(value)
    }

    private func hardwareIdentifier(fromTableModel model: String) -> String {
        guard model.last == ")",
              let openIndex = model.lastIndex(of: "(") else {
            return model
        }

        return String(model[model.index(after: openIndex)..<model.index(before: model.endIndex)])
    }

    private func nonEmptyString(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        if let number = value as? NSNumber {
            return number.stringValue
        }

        guard let dictionary = value as? [String: Any] else {
            return nil
        }

        return firstNonEmptyString([
            dictionary["stringValue"],
            dictionary["versionString"],
            dictionary["rawValue"],
            dictionary["value"],
            dictionary["name"],
            dictionary["status"],
            dictionary["state"]
        ])
    }

    private func numericVersionComponent(_ value: Any?) -> String? {
        if let number = value as? NSNumber {
            return number.stringValue
        }

        guard let string = nonEmptyString(value) else {
            return nil
        }

        return string.allSatisfy(\.isNumber) ? string : nil
    }

    private func firstNonEmptyString(_ values: [Any?]) -> String? {
        values.lazy.compactMap(nonEmptyString).first
    }

    private func firstBoolean(_ values: [Any?]) -> Bool? {
        values.lazy.compactMap(normalizedBoolean).first
    }

    private func normalizedBoolean(_ value: Any?) -> Bool? {
        if let bool = value as? Bool {
            return bool
        }

        if let number = value as? NSNumber {
            return number.boolValue
        }

        if let string = nonEmptyString(value)?.lowercased() {
            switch string {
            case "true", "yes", "1", "available", "connected":
                return true
            case "false", "no", "0", "unavailable", "disconnected":
                return false
            default:
                return nil
            }
        }

        guard let dictionary = value as? [String: Any] else {
            return nil
        }

        return firstBoolean([
            dictionary["boolValue"],
            dictionary["value"],
            dictionary["rawValue"],
            dictionary["state"],
            dictionary["status"]
        ])
    }

    private func firstPresentValue(_ values: [Any?]) -> Any? {
        values.first { value in
            guard let value, !(value is NSNull) else {
                return false
            }

            if let string = value as? String {
                return !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            if let dictionary = value as? [String: Any] {
                return !dictionary.isEmpty
            }

            return true
        } ?? nil
    }
}

public struct IOSStageOneDeviceProbeCandidateMerger: Equatable, Sendable {
    public init() {}

    public func merge(
        _ candidateLists: [[IOSStageOnePhysicalDeviceCandidate]]
    ) -> [IOSStageOnePhysicalDeviceCandidate] {
        var mergedCandidates: [IOSStageOnePhysicalDeviceCandidate] = []

        for candidate in candidateLists.flatMap({ $0 }) {
            guard let existingIndex = mergedCandidates.firstIndex(where: {
                representsSameDevice($0, candidate)
            }) else {
                mergedCandidates.append(candidate)
                continue
            }

            mergedCandidates[existingIndex] = merged(
                mergedCandidates[existingIndex],
                with: candidate
            )
        }

        return mergedCandidates
    }

    private func representsSameDevice(
        _ lhs: IOSStageOnePhysicalDeviceCandidate,
        _ rhs: IOSStageOnePhysicalDeviceCandidate
    ) -> Bool {
        if lhs.identifier == rhs.identifier {
            return true
        }

        return normalizedDeviceName(lhs.name) == normalizedDeviceName(rhs.name)
            && simulatorClassificationsCanRepresentSameDevice(lhs, rhs)
    }

    private func simulatorClassificationsCanRepresentSameDevice(
        _ lhs: IOSStageOnePhysicalDeviceCandidate,
        _ rhs: IOSStageOnePhysicalDeviceCandidate
    ) -> Bool {
        lhs.isSimulator == rhs.isSimulator
            || (!lhs.hasExplicitSimulatorEvidence && !rhs.hasExplicitSimulatorEvidence)
    }

    private func merged(
        _ existing: IOSStageOnePhysicalDeviceCandidate,
        with candidate: IOSStageOnePhysicalDeviceCandidate
    ) -> IOSStageOnePhysicalDeviceCandidate {
        IOSStageOnePhysicalDeviceCandidate(
            name: bestDisplayName(existing.name, candidate.name),
            osVersion: existing.osVersion ?? candidate.osVersion,
            identifier: existing.identifier,
            hardwareModel: mergedHardwareModel(existing.hardwareModel, candidate.hardwareModel),
            isConnected: mergedConnectionState(existing, candidate),
            isSimulator: mergedSimulatorClassification(existing, candidate),
            hasExplicitConnectionEvidence: existing.hasExplicitConnectionEvidence
                || candidate.hasExplicitConnectionEvidence,
            hasExplicitSimulatorEvidence: existing.hasExplicitSimulatorEvidence
                || candidate.hasExplicitSimulatorEvidence
        )
    }

    private func mergedConnectionState(
        _ existing: IOSStageOnePhysicalDeviceCandidate,
        _ candidate: IOSStageOnePhysicalDeviceCandidate
    ) -> Bool {
        if existing.hasExplicitConnectionEvidence && candidate.hasExplicitConnectionEvidence {
            return existing.isConnected && candidate.isConnected
        }

        if existing.hasExplicitConnectionEvidence {
            return existing.isConnected
        }

        if candidate.hasExplicitConnectionEvidence {
            return candidate.isConnected
        }

        return false
    }

    private func mergedSimulatorClassification(
        _ existing: IOSStageOnePhysicalDeviceCandidate,
        _ candidate: IOSStageOnePhysicalDeviceCandidate
    ) -> Bool {
        if existing.isSimulator == candidate.isSimulator {
            return existing.isSimulator
        }

        if existing.hasExplicitSimulatorEvidence || candidate.hasExplicitSimulatorEvidence {
            return true
        }

        return false
    }

    private func normalizedDeviceName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func bestDisplayName(_ existing: String, _ candidate: String) -> String {
        let existingTrimmed = existing.trimmingCharacters(in: .whitespacesAndNewlines)
        return existingTrimmed.isEmpty ? candidate : existing
    }

    private func mergedHardwareModel(_ existing: String?, _ candidate: String?) -> String? {
        let existingTrimmed = existing?.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidateTrimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (nonEmpty(existingTrimmed), nonEmpty(candidateTrimmed)) {
        case (.none, .none):
            return nil
        case (.some(let model), .none), (.none, .some(let model)):
            return model
        case (.some(let existingModel), .some(let candidateModel)):
            return hardwareModelsAreCompatible(existingModel, candidateModel) ? existingModel : nil
        }
    }

    private func hardwareModelsAreCompatible(_ lhs: String, _ rhs: String) -> Bool {
        let lhsSignals = hardwareIdentitySignals(from: lhs)
        let rhsSignals = hardwareIdentitySignals(from: rhs)

        return !lhsSignals.isDisjoint(with: rhsSignals)
    }

    private func hardwareIdentitySignals(from model: String) -> Set<String> {
        let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        var signals = Set<String>()
        appendHardwareIdentitySignal(trimmed, to: &signals)
        if trimmed.last == ")",
           let openIndex = trimmed.lastIndex(of: "(") {
            let marketingName = trimmed[..<openIndex]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let hardwareIdentifier = trimmed[trimmed.index(after: openIndex)..<trimmed.index(before: trimmed.endIndex)]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !marketingName.isEmpty {
                appendHardwareIdentitySignal(String(marketingName), to: &signals)
            }
            if !hardwareIdentifier.isEmpty {
                appendHardwareIdentitySignal(String(hardwareIdentifier), to: &signals)
            }
        }

        return signals
    }

    private func appendHardwareIdentitySignal(
        _ value: String,
        to signals: inout Set<String>
    ) {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else {
            return
        }

        signals.insert(normalized)
        if let canonicalIdentifier = canonicalAppleProductIdentifier(from: normalized) {
            signals.insert(canonicalIdentifier)
        }

        Self.iPhone12FamilyMarketingNameProductIdentifiers[normalized]?.forEach {
            signals.insert($0)
        }
    }

    private func canonicalAppleProductIdentifier(from value: String) -> String? {
        let parts = value.split(
            separator: "-",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )

        guard parts.count == 2,
              let basePart = parts.first,
              let suffix = parts.last,
              !suffix.isEmpty,
              suffix.allSatisfy({ $0.isLetter || $0.isNumber }),
              isAppleProductIdentifier(String(basePart)) else {
            return nil
        }

        return String(basePart)
    }

    private func isAppleProductIdentifier(_ value: String) -> Bool {
        let parts = value.split(
            separator: ",",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        guard parts.count == 2,
              let familyAndMajor = parts.first,
              let minor = parts.last,
              !familyAndMajor.isEmpty,
              !minor.isEmpty,
              minor.allSatisfy(\.isNumber) else {
            return false
        }

        var sawLetter = false
        var sawMajorDigit = false
        for character in familyAndMajor {
            if character.isLetter {
                guard !sawMajorDigit else {
                    return false
                }
                sawLetter = true
            } else if character.isNumber {
                sawMajorDigit = true
            } else {
                return false
            }
        }

        return sawLetter && sawMajorDigit
    }

    private static let iPhone12FamilyMarketingNameProductIdentifiers: [String: Set<String>] = [
        "iphone 12": ["iphone13,2"],
        "iphone 12 mini": ["iphone13,1"],
        "iphone 12 pro": ["iphone13,3"],
        "iphone 12 pro max": ["iphone13,4"]
    ]

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else {
            return nil
        }

        return value
    }
}

public struct IOSStageOneRealDeviceValidationReport: Equatable, Sendable {
    public let generatedAt: Date
    public let deviceProbeObservedAt: Date?
    public let deviceProbeMaximumAge: TimeInterval
    public let candidates: [IOSStageOnePhysicalDeviceCandidate]
    public let completedFlowSteps: Set<IOSStageOneRealDeviceFlowStep>
    public let manualFlowEvidence: [IOSStageOneRealDeviceFlowEvidence]
    public let manualFlowMaximumEvidenceAge: TimeInterval
    public let swiftPMTestPassed: Bool
    public let iPhone12SimulatorBuildPassed: Bool
    public let iPhone12SimulatorTestPassed: Bool
    public let probeCommand: String
    public let probeCommands: [String]
    public let probeCommandEvidence: [IOSStageOnePhysicalProbeCommandEvidence]
    public let manualFlowProbeBatchTolerance: TimeInterval
    public let requiredProbeCommandBatchTolerance: TimeInterval

    public init(
        generatedAt: Date,
        deviceProbeObservedAt: Date? = nil,
        deviceProbeMaximumAge: TimeInterval = 3_600,
        candidates: [IOSStageOnePhysicalDeviceCandidate],
        completedFlowSteps: Set<IOSStageOneRealDeviceFlowStep>,
        manualFlowEvidence: [IOSStageOneRealDeviceFlowEvidence] = [],
        manualFlowMaximumEvidenceAge: TimeInterval = 3_600,
        swiftPMTestPassed: Bool,
        iPhone12SimulatorBuildPassed: Bool,
        iPhone12SimulatorTestPassed: Bool,
        probeCommand: String = "xcrun xctrace list devices",
        probeCommands: [String]? = nil,
        probeCommandEvidence: [IOSStageOnePhysicalProbeCommandEvidence]? = nil,
        manualFlowProbeBatchTolerance: TimeInterval = 1,
        requiredProbeCommandBatchTolerance: TimeInterval = 120
    ) {
        let normalizedCommands = Self.normalizedProbeCommands(probeCommands ?? [probeCommand])

        self.generatedAt = generatedAt
        self.deviceProbeObservedAt = deviceProbeObservedAt
        self.deviceProbeMaximumAge = max(1, deviceProbeMaximumAge)
        self.candidates = candidates
        self.completedFlowSteps = completedFlowSteps
        self.manualFlowEvidence = manualFlowEvidence
        self.manualFlowMaximumEvidenceAge = max(1, manualFlowMaximumEvidenceAge)
        self.swiftPMTestPassed = swiftPMTestPassed
        self.iPhone12SimulatorBuildPassed = iPhone12SimulatorBuildPassed
        self.iPhone12SimulatorTestPassed = iPhone12SimulatorTestPassed
        self.probeCommand = probeCommand
        self.probeCommands = normalizedCommands
        self.probeCommandEvidence = Self.normalizedProbeCommandEvidence(
            probeCommandEvidence,
            fallbackCommands: normalizedCommands,
            fallbackObservedAt: deviceProbeObservedAt
        )
        self.manualFlowProbeBatchTolerance = max(0, manualFlowProbeBatchTolerance)
        self.requiredProbeCommandBatchTolerance = max(0, requiredProbeCommandBatchTolerance)
    }

    public var eligibleConnectedDevices: [IOSStageOnePhysicalDeviceCandidate] {
        candidates.filter(\.isEligibleConnectedDevice)
    }

    public var connectedUnsupportedPhysicalDevices: [IOSStageOnePhysicalDeviceCandidate] {
        connectedUnsupportedIOSPhysicalDeviceRecords
    }

    public var connectedUnsupportedIOSPhysicalDeviceRecords: [IOSStageOnePhysicalDeviceCandidate] {
        candidates.filter {
            $0.isConnected
                && !$0.isSimulator
                && !$0.isIPhone12FamilyPhysicalDevice
                && hasIOSPhysicalDeviceEvidence($0)
        }
    }

    public var iosPhysicalDeviceRecords: [IOSStageOnePhysicalDeviceCandidate] {
        candidates.filter {
            !$0.isSimulator && (
                $0.isIPhone12FamilyPhysicalDevice
                    || $0.hasVerifiedIPhone12FamilyHardwareEvidence
                    || hasIOSPhysicalDeviceEvidence($0)
            )
        }
    }

    public var unavailableIOSPhysicalDeviceRecords: [IOSStageOnePhysicalDeviceCandidate] {
        iosPhysicalDeviceRecords.filter { !$0.isConnected }
    }

    public var verifiedEligibleConnectedDevices: [IOSStageOnePhysicalDeviceCandidate] {
        candidates.filter(\.isVerifiedEligibleConnectedDevice)
    }

    public var connectedIPhone12FamilyDevicesMissingExplicitConnectionEvidence: [IOSStageOnePhysicalDeviceCandidate] {
        candidates.filter {
            $0.isConnected
                && !$0.isSimulator
                && !$0.hasExplicitConnectionEvidence
                && $0.isIPhone12FamilyPhysicalDevice
        }
    }

    public var missingFlowSteps: Set<IOSStageOneRealDeviceFlowStep> {
        Set(IOSStageOneRealDeviceFlowStep.allCases).subtracting(completedFlowSteps)
    }

    public var manualFlowAudit: IOSStageOneRealDeviceManualFlowAudit {
        IOSStageOneRealDeviceManualFlowAudit(
            evidenceItems: manualFlowEvidence,
            generatedAt: generatedAt,
            maximumEvidenceAge: manualFlowMaximumEvidenceAge
        )
    }

    public var simulatorPrerequisitesPassed: Bool {
        swiftPMTestPassed && iPhone12SimulatorBuildPassed && iPhone12SimulatorTestPassed
    }

    public var hasRequiredPhysicalProbeCommandCoverage: Bool {
        missingRequiredPhysicalProbeCommands.isEmpty
            && staleRequiredPhysicalProbeCommands.isEmpty
            && requiredProbeCommandsAreSameBatch
    }

    public var missingRequiredPhysicalProbeCommands: [String] {
        Self.requiredPhysicalProbeCommands.filter { !containsProbeCommand($0) }
    }

    public var staleRequiredPhysicalProbeCommands: [String] {
        Self.requiredPhysicalProbeCommands.filter { requiredCommand in
            guard containsProbeCommand(requiredCommand) else {
                return false
            }

            return !hasCurrentProbeCommandEvidence(for: requiredCommand)
        }
    }

    public var requiredProbeCommandBatchSkew: TimeInterval? {
        let observedDates = Self.requiredPhysicalProbeCommands.compactMap(probeCommandObservedAt)
        guard observedDates.count == Self.requiredPhysicalProbeCommands.count,
              let earliest = observedDates.min(),
              let latest = observedDates.max() else {
            return nil
        }

        return latest.timeIntervalSince(earliest)
    }

    public var requiredProbeCommandsAreSameBatch: Bool {
        guard let requiredProbeCommandBatchSkew else {
            return false
        }

        return requiredProbeCommandBatchSkew <= requiredProbeCommandBatchTolerance
    }

    public var physicalProbeCommandCoverageStatus: IOSStageOnePhysicalProbeCommandCoverageStatus {
        if !missingRequiredPhysicalProbeCommands.isEmpty {
            return .blockedMissingRequiredCommands
        }

        if !staleRequiredPhysicalProbeCommands.isEmpty || !requiredProbeCommandsAreSameBatch {
            return .blockedStaleRequiredCommands
        }

        return .satisfied
    }

    public var effectiveDeviceProbeObservedAt: Date? {
        latestRequiredProbeCommandObservedAt ?? deviceProbeObservedAt
    }

    public var requiredProbeCommandObservedAtValues: Set<Date> {
        Set(Self.requiredPhysicalProbeCommands.compactMap(probeCommandObservedAt))
    }

    public var hasCurrentDeviceProbeEvidence: Bool {
        guard let effectiveDeviceProbeObservedAt else {
            return false
        }

        let age = generatedAt.timeIntervalSince(effectiveDeviceProbeObservedAt)
        return age >= 0 && age <= deviceProbeMaximumAge
    }

    public var hasCurrentManualFlowEvidence: Bool {
        manualFlowAudit.hasCurrentEvidenceForEveryRequiredStep
    }

    public var verifiedConnectedHardwareEvidenceSignals: Set<String> {
        Set(verifiedEligibleConnectedDevices.flatMap(\.manualEvidenceHardwareSignals))
    }

    public var completedStepsWithConnectedVerifiedHardwareEvidence: Set<IOSStageOneRealDeviceFlowStep> {
        Set(manualFlowEvidence
            .filter {
                $0.referencesVerifiedHardwareSignal(verifiedConnectedHardwareEvidenceSignals)
            }
            .map(\.step))
    }

    public var hasManualFlowEvidenceForConnectedVerifiedHardware: Bool {
        Set(IOSStageOneRealDeviceFlowStep.allCases)
            .subtracting(completedStepsWithConnectedVerifiedHardwareEvidence)
            .isEmpty
    }

    public var verifiedHardwareSignalsByCompletedStep: [IOSStageOneRealDeviceFlowStep: Set<String>] {
        Dictionary(uniqueKeysWithValues: IOSStageOneRealDeviceFlowStep.allCases.map { step in
            let signals = Set(manualFlowEvidence
                .filter { $0.step == step && $0.hasCompletionEvidence }
                .flatMap {
                    $0.verifiedHardwareSignalsReferenced(verifiedConnectedHardwareEvidenceSignals)
                })
            return (step, signals)
        })
    }

    public var commonVerifiedHardwareSignalsForCompletedManualFlow: Set<String> {
        IOSStageOneRealDeviceFlowStep.allCases.reduce(nil as Set<String>?) { commonSignals, step in
            let stepSignals = verifiedHardwareSignalsByCompletedStep[step] ?? []
            guard !stepSignals.isEmpty else {
                return []
            }

            guard let commonSignals else {
                return stepSignals
            }

            return commonSignals.intersection(stepSignals)
        } ?? []
    }

    public var hasManualFlowEvidenceForSingleConnectedVerifiedHardware: Bool {
        !commonVerifiedHardwareSignalsForCompletedManualFlow.isEmpty
    }

    public var completedStepsWithPostProbeConnectedVerifiedHardwareEvidence: Set<IOSStageOneRealDeviceFlowStep> {
        guard let effectiveDeviceProbeObservedAt else {
            return []
        }

        return Set(manualFlowEvidence
            .filter { evidence in
                guard let observedAt = evidence.observedAt,
                      evidence.referencesVerifiedHardwareSignal(verifiedConnectedHardwareEvidenceSignals) else {
                    return false
                }

                return observedAt >= effectiveDeviceProbeObservedAt
            }
            .map(\.step))
    }

    public var completedStepsWithCurrentPostProbeConnectedVerifiedHardwareEvidence: Set<IOSStageOneRealDeviceFlowStep> {
        guard let effectiveDeviceProbeObservedAt else {
            return []
        }

        return Set(manualFlowEvidence
            .filter { evidence in
                guard let observedAt = evidence.observedAt,
                      manualFlowEvidenceIsCurrent(evidence),
                      evidence.referencesVerifiedHardwareSignal(verifiedConnectedHardwareEvidenceSignals) else {
                    return false
                }

                return observedAt >= effectiveDeviceProbeObservedAt
            }
            .map(\.step))
    }

    public var hasManualFlowEvidenceAfterCurrentDeviceProbe: Bool {
        Set(IOSStageOneRealDeviceFlowStep.allCases)
            .subtracting(completedStepsWithPostProbeConnectedVerifiedHardwareEvidence)
            .isEmpty
    }

    public var hasCurrentPostProbeManualFlowEvidenceForConnectedVerifiedHardware: Bool {
        Set(IOSStageOneRealDeviceFlowStep.allCases)
            .subtracting(completedStepsWithCurrentPostProbeConnectedVerifiedHardwareEvidence)
            .isEmpty
    }

    public var completedStepsWithCurrentProbeBatchManualFlowEvidence: Set<IOSStageOneRealDeviceFlowStep> {
        guard !currentProbeBatchObservedAtValues.isEmpty else {
            return []
        }

        return Set(manualFlowEvidence
            .filter { evidence in
                guard let observedAt = evidence.observedAt,
                      evidence.hasStepSpecificFlowEvidence,
                      manualFlowEvidenceIsCurrent(evidence),
                      evidence.referencesVerifiedHardwareSignal(verifiedConnectedHardwareEvidenceSignals),
                      let earliestCurrentProbeBatchObservedAt,
                      observedAt >= earliestCurrentProbeBatchObservedAt else {
                    return false
                }

                return manualFlowEvidenceReferencesCurrentProbeBatch(evidence)
            }
            .map(\.step))
    }

    public var hasManualFlowEvidenceForCurrentProbeBatch: Bool {
        Set(IOSStageOneRealDeviceFlowStep.allCases)
            .subtracting(completedStepsWithCurrentProbeBatchManualFlowEvidence)
            .isEmpty
    }

    public var status: IOSStageOneRealDeviceValidationStatus {
        guard hasCurrentDeviceProbeEvidence else {
            return .blockedStaleDeviceProbe
        }

        guard missingRequiredPhysicalProbeCommands.isEmpty else {
            return .blockedMissingRequiredProbeCommands
        }

        guard staleRequiredPhysicalProbeCommands.isEmpty,
              requiredProbeCommandsAreSameBatch else {
            return .blockedStaleRequiredProbeCommands
        }

        guard simulatorPrerequisitesPassed else {
            return .blockedMissingPrerequisiteValidation
        }

        guard !eligibleConnectedDevices.isEmpty else {
            if !connectedIPhone12FamilyDevicesMissingExplicitConnectionEvidence.isEmpty {
                return .blockedMissingExplicitConnectionEvidence
            }
            if !connectedUnsupportedPhysicalDevices.isEmpty {
                return .blockedConnectedUnsupportedPhysicalDevice
            }
            return .blockedNoConnectedIPhone12FamilyDevice
        }

        guard !verifiedEligibleConnectedDevices.isEmpty else {
            return .blockedMissingVerifiedHardwareEvidence
        }

        guard missingFlowSteps.isEmpty else {
            return .blockedIncompleteManualFlow
        }

        guard manualFlowAudit.hasEvidenceForEveryRequiredStep else {
            return .blockedIncompleteManualFlow
        }

        guard manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep else {
            return .blockedMissingStepSpecificManualFlowEvidence
        }

        guard manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep else {
            return .blockedMissingPhysicalManualFlowEvidence
        }

        guard hasManualFlowEvidenceForConnectedVerifiedHardware else {
            return .blockedMismatchedPhysicalManualFlowEvidence
        }

        guard hasManualFlowEvidenceForSingleConnectedVerifiedHardware else {
            return .blockedSplitPhysicalManualFlowEvidence
        }

        guard hasCurrentManualFlowEvidence else {
            return .blockedStaleManualFlowEvidence
        }

        guard hasManualFlowEvidenceAfterCurrentDeviceProbe else {
            return .blockedManualFlowBeforeDeviceProbe
        }

        guard hasCurrentPostProbeManualFlowEvidenceForConnectedVerifiedHardware else {
            return .blockedStaleManualFlowEvidence
        }

        guard hasManualFlowEvidenceForCurrentProbeBatch else {
            return .blockedMissingCurrentProbeBatchEvidence
        }

        return .passed
    }

    public var capturesRealDeviceGateEvidence: Bool {
        simulatorPrerequisitesPassed
            && hasRequiredPhysicalProbeCommandCoverage
            && hasCurrentDeviceProbeEvidence
            && (
                status == .passed
                    || status == .blockedNoConnectedIPhone12FamilyDevice
                    || status == .blockedMissingExplicitConnectionEvidence
                    || status == .blockedConnectedUnsupportedPhysicalDevice
                    || status == .blockedMissingVerifiedHardwareEvidence
            )
    }

    public var completesRequiredRealDeviceValidation: Bool {
        simulatorPrerequisitesPassed
            && hasRequiredPhysicalProbeCommandCoverage
            && status == .passed
    }

    public var blockerSummary: String {
        switch status {
        case .passed:
            return "none"
        case .blockedStaleDeviceProbe:
            return "The physical-device probe is missing, stale, or newer than the report timestamp; rerun \(probeCommandSummary) during validation."
        case .blockedMissingRequiredProbeCommands:
            return "The physical-device probe must record both required sources before the real-device gate can complete: \(Self.requiredPhysicalProbeCommands.joined(separator: "; "))."
        case .blockedStaleRequiredProbeCommands:
            if !requiredProbeCommandsAreSameBatch,
               let requiredProbeCommandBatchSkew {
                return "The physical-device probe recorded every required source, but required command observations are \(Int(requiredProbeCommandBatchSkew.rounded())) seconds apart; rerun \(probeCommandSummary) as one validation batch."
            }
            return "The physical-device probe recorded every required source, but one or more required command observations are stale or newer than the report timestamp: \(staleRequiredPhysicalProbeCommands.joined(separator: "; "))."
        case .blockedMissingPrerequisiteValidation:
            return "SwiftPM and iPhone 12 simulator build/test prerequisites must pass before the physical-device validation gate can complete."
        case .blockedNoConnectedIPhone12FamilyDevice:
            return "No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was reported by \(probeCommandSummary)."
        case .blockedMissingExplicitConnectionEvidence:
            return "An iPhone 12-family physical candidate was reported, but the current physical-device probe did not include an explicit connected/available signal."
        case .blockedConnectedUnsupportedPhysicalDevice:
            return "A connected physical iOS device was reported by \(probeCommandSummary), but it is not iPhone 12 / 12 mini / 12 Pro / 12 Pro Max hardware."
        case .blockedMissingVerifiedHardwareEvidence:
            return "A connected iPhone 12-family candidate was reported by name, but no verified iPhone 12-family hardware model or product identifier was reported by \(probeCommandSummary)."
        case .blockedIncompleteManualFlow:
            return "Connected iPhone 12-family hardware exists, but the full Stage 1 manual flow has not been completed."
        case .blockedMissingStepSpecificManualFlowEvidence:
            return "Manual flow evidence exists, but every required step must describe its specific Stage 1 action before the real-device gate can complete."
        case .blockedMissingPhysicalManualFlowEvidence:
            return "Manual flow evidence exists, but every required step must explicitly identify physical iPhone 12-family hardware before the real-device gate can complete."
        case .blockedMismatchedPhysicalManualFlowEvidence:
            return "Manual flow evidence identifies physical iPhone 12-family hardware, but it does not match the verified connected hardware signal reported by the current device probe."
        case .blockedSplitPhysicalManualFlowEvidence:
            return "Manual flow evidence matches verified iPhone 12-family hardware, but no single connected verified device is referenced by every required Stage 1 flow step."
        case .blockedManualFlowBeforeDeviceProbe:
            return "Manual flow evidence matches verified iPhone 12-family hardware, but every required step must be observed after the current physical-device probe."
        case .blockedStaleManualFlowEvidence:
            return "Manual flow evidence is stale or newer than the report timestamp; repeat the physical-device flow during validation."
        case .blockedMissingCurrentProbeBatchEvidence:
            return "Manual flow evidence matches verified iPhone 12-family hardware, but every required step must reference the current physical-device probe batch."
        }
    }

    public var markdown: String {
        let deviceRows = candidates.enumerated().map { index, candidate in
            [
                safeText(redactedDeviceEvidenceLabel(for: candidate, index: index)),
                safeText(candidate.hardwareModel ?? "unknown"),
                safeText(candidate.osVersion ?? "unknown"),
                candidate.isConnected ? "yes" : "no",
                candidate.isSimulator ? "yes" : "no",
                candidate.isEligibleConnectedDevice ? "yes" : "no",
                candidate.hasVerifiedIPhone12FamilyHardwareEvidence ? "yes" : "no",
                candidate.eligibilityReason.rawValue
            ].joined(separator: " | ")
        }.map { "| \($0) |" }
        let probeRows = Self.requiredPhysicalProbeCommands.map { command in
            [
                safeText(command),
                safeText(probeCommandStatus(for: command)),
                safeText(probeCommandObservedAt(for: command).map(iso8601String(from:)) ?? "missing")
            ].joined(separator: " | ")
        }.map { "| \($0) |" }

        let flowRows = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            "| \(step.displayName) | \(completedFlowSteps.contains(step) ? "PASS" : "OPEN") |"
        }
        let evidenceRows = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            let item = strongestManualFlowEvidence(for: step)
            let result: String
            if item == nil {
                result = "OPEN"
            } else if manualFlowAudit.completedStepsWithStepSpecificFlowEvidence.contains(step) == false {
                result = "FLOW-MISSING"
            } else if manualFlowAudit.completedStepsWithPhysicalIPhone12FamilyEvidence.contains(step) == false {
                result = "DEVICE-MISSING"
            } else if completedStepsWithConnectedVerifiedHardwareEvidence.contains(step) == false {
                result = "DEVICE-MISMATCH"
            } else if manualFlowAudit.completedStepsWithCurrentEvidence.contains(step) == false {
                result = "STALE"
            } else if completedStepsWithPostProbeConnectedVerifiedHardwareEvidence.contains(step) == false {
                result = "PRE-PROBE"
            } else if completedStepsWithCurrentPostProbeConnectedVerifiedHardwareEvidence.contains(step) == false {
                result = "STALE"
            } else if completedStepsWithCurrentProbeBatchManualFlowEvidence.contains(step) == false {
                result = "PROBE-BATCH-MISSING"
            } else {
                result = "PASS"
            }
            return "| \(step.displayName) | \(result) | \(safeText(item?.evidenceSummary ?? "missing")) |"
        }

        return ([
            "# Stage 1 iOS iPhone 12 Real-Device Validation Report",
            "",
            "- Generated: \(iso8601String(from: generatedAt))",
            "- Device probe observed: \(effectiveDeviceProbeObservedAt.map(iso8601String(from:)) ?? "missing")",
            "- Probe commands: \(safeText(probeCommandSummary))",
            "- Physical probe command coverage: \(hasRequiredPhysicalProbeCommandCoverage)",
            "- Physical probe command coverage status: \(physicalProbeCommandCoverageStatus.rawValue)",
            "- Missing physical probe commands: \(missingRequiredPhysicalProbeCommands.isEmpty ? "none" : safeText(missingRequiredPhysicalProbeCommands.joined(separator: "; ")))",
            "- Stale physical probe commands: \(staleRequiredPhysicalProbeCommands.isEmpty ? "none" : safeText(staleRequiredPhysicalProbeCommands.joined(separator: "; ")))",
            "- Required physical probe command batch skew seconds: \(requiredProbeCommandBatchSkew.map { String(format: "%.0f", $0) } ?? "missing")",
            "- Required physical probe commands same batch: \(requiredProbeCommandsAreSameBatch)",
            "- Device probe current: \(hasCurrentDeviceProbeEvidence)",
            "- Status: \(status.rawValue)",
            "- Simulator prerequisites passed: \(simulatorPrerequisitesPassed)",
            "- Real-device validation complete: \(completesRequiredRealDeviceValidation)",
            "- Manual flow evidence complete: \(manualFlowAudit.hasEvidenceForEveryRequiredStep)",
            "- Manual flow step-specific evidence complete: \(manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)",
            "- Manual flow physical iPhone 12-family evidence complete: \(manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)",
            "- Manual flow matches connected verified hardware: \(hasManualFlowEvidenceForConnectedVerifiedHardware)",
            "- Manual flow single verified hardware signal complete: \(hasManualFlowEvidenceForSingleConnectedVerifiedHardware)",
            "- Manual flow observed after current device probe: \(hasManualFlowEvidenceAfterCurrentDeviceProbe)",
            "- Manual flow evidence current: \(hasCurrentManualFlowEvidence)",
            "- Manual flow current post-probe connected hardware evidence complete: \(hasCurrentPostProbeManualFlowEvidenceForConnectedVerifiedHardware)",
            "- Manual flow references current probe batch: \(hasManualFlowEvidenceForCurrentProbeBatch)",
            "- Physical iPhone 12-family devices connected: \(eligibleConnectedDevices.count)",
            "- iOS physical device records discovered: \(iosPhysicalDeviceRecords.count)",
            "- Unavailable iOS physical device records: \(unavailableIOSPhysicalDeviceRecords.count)",
            "- Connected unsupported iOS physical device records: \(connectedUnsupportedIOSPhysicalDeviceRecords.count)",
            "- Connected unsupported physical devices: \(connectedUnsupportedPhysicalDevices.count)",
            "- Connected iPhone 12-family devices missing explicit connection evidence: \(connectedIPhone12FamilyDevicesMissingExplicitConnectionEvidence.count)",
            "- Verified iPhone 12-family hardware evidence connected: \(verifiedEligibleConnectedDevices.count)",
            "- Blocker: \(blockerSummary)",
            "",
            "| Required physical probe command | Status | Observed at |",
            "| --- | --- | --- |"
        ] + probeRows + [
            "",
            "| Device evidence label | Hardware model | OS | Connected | Simulator | Eligible iPhone 12-family physical device | Verified iPhone 12-family hardware evidence | Eligibility reason |",
            "| --- | --- | --- | --- | --- | --- | --- | --- |"
        ] + deviceRows + [
            "",
            "| Required real-device flow | Result |",
            "| --- | --- |"
        ] + flowRows + [
            "",
            "| Manual flow evidence | Result | Evidence |",
            "| --- | --- | --- |"
        ] + evidenceRows).joined(separator: "\n") + "\n"
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private var probeCommandSummary: String {
        probeCommands.joined(separator: "; ")
    }

    private func strongestManualFlowEvidence(
        for step: IOSStageOneRealDeviceFlowStep
    ) -> IOSStageOneRealDeviceFlowEvidence? {
        manualFlowEvidence
            .filter { $0.step == step && $0.hasCompletionEvidence }
            .max { lhs, rhs in
                manualFlowEvidenceIsWeaker(lhs, than: rhs)
            }
    }

    private func manualFlowEvidenceIsWeaker(
        _ lhs: IOSStageOneRealDeviceFlowEvidence,
        than rhs: IOSStageOneRealDeviceFlowEvidence
    ) -> Bool {
        let lhsRank = manualFlowEvidenceRank(lhs)
        let rhsRank = manualFlowEvidenceRank(rhs)
        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }

        let lhsObservedAt = lhs.observedAt?.timeIntervalSince1970 ?? -.infinity
        let rhsObservedAt = rhs.observedAt?.timeIntervalSince1970 ?? -.infinity
        if lhsObservedAt != rhsObservedAt {
            return lhsObservedAt < rhsObservedAt
        }

        return lhs.evidenceSummary < rhs.evidenceSummary
    }

    private func manualFlowEvidenceRank(
        _ evidence: IOSStageOneRealDeviceFlowEvidence
    ) -> Int {
        let connectedVerifiedHardwareRank = evidence.referencesVerifiedHardwareSignal(
            verifiedConnectedHardwareEvidenceSignals
        ) ? 32 : 0
        let currentProbeBatchRank = manualFlowEvidenceReferencesCurrentProbeBatch(evidence) ? 16 : 0
        let postProbeRank = manualFlowEvidenceIsPostProbe(evidence) ? 8 : 0
        let stepSpecificRank = evidence.hasStepSpecificFlowEvidence ? 4 : 0
        let physicalRank = evidence.hasPhysicalIPhone12FamilyEvidence ? 2 : 0
        let currentRank = manualFlowEvidenceIsCurrent(evidence) ? 1 : 0
        return connectedVerifiedHardwareRank
            + currentProbeBatchRank
            + postProbeRank
            + stepSpecificRank
            + physicalRank
            + currentRank
    }

    private func manualFlowEvidenceIsPostProbe(
        _ evidence: IOSStageOneRealDeviceFlowEvidence
    ) -> Bool {
        guard let effectiveDeviceProbeObservedAt,
              let observedAt = evidence.observedAt else {
            return false
        }

        return observedAt >= effectiveDeviceProbeObservedAt
    }

    private func manualFlowEvidenceReferencesCurrentProbeBatch(
        _ evidence: IOSStageOneRealDeviceFlowEvidence
    ) -> Bool {
        currentProbeBatchObservedAtValues.contains { probeObservedAt in
            evidence.referencesProbeBatch(
                observedAt: probeObservedAt,
                tolerance: manualFlowProbeBatchTolerance
            )
        }
    }

    private func manualFlowEvidenceIsCurrent(
        _ evidence: IOSStageOneRealDeviceFlowEvidence
    ) -> Bool {
        guard evidence.hasCompletionEvidence,
              let observedAt = evidence.observedAt else {
            return false
        }

        let age = generatedAt.timeIntervalSince(observedAt)
        return age >= 0 && age <= manualFlowMaximumEvidenceAge
    }

    private func probeCommandStatus(for command: String) -> String {
        guard containsProbeCommand(command) else {
            return "MISSING"
        }

        return hasCurrentProbeCommandEvidence(for: command) ? "PASS" : "STALE"
    }

    private func probeCommandObservedAt(for command: String) -> Date? {
        let normalizedCommand = Self.normalizedProbeCommandValue(command)
        return probeCommandEvidence
            .filter {
                Self.normalizedProbeCommandValue($0.command) == normalizedCommand
            }
            .compactMap(\.observedAt)
            .max()
    }

    private var latestRequiredProbeCommandObservedAt: Date? {
        guard missingRequiredPhysicalProbeCommands.isEmpty,
              staleRequiredPhysicalProbeCommands.isEmpty else {
            return nil
        }

        let observedDates = Self.requiredPhysicalProbeCommands.compactMap(probeCommandObservedAt)
        guard observedDates.count == Self.requiredPhysicalProbeCommands.count else {
            return nil
        }

        return observedDates.max()
    }

    private var currentProbeBatchObservedAtValues: Set<Date> {
        guard missingRequiredPhysicalProbeCommands.isEmpty,
              staleRequiredPhysicalProbeCommands.isEmpty,
              requiredProbeCommandsAreSameBatch,
              let latestRequiredProbeCommandObservedAt else {
            return effectiveDeviceProbeObservedAt.map { [$0] } ?? []
        }

        return [latestRequiredProbeCommandObservedAt]
    }

    private var earliestCurrentProbeBatchObservedAt: Date? {
        currentProbeBatchObservedAtValues.min()
    }

    private func redactedDeviceEvidenceLabel(
        for candidate: IOSStageOnePhysicalDeviceCandidate,
        index: Int
    ) -> String {
        let ordinal = index + 1

        if candidate.isSimulator {
            return "simulator-destination-\(ordinal)"
        }

        if !candidate.isConnected {
            return "disconnected-physical-device-\(ordinal)"
        }

        if !candidate.hasExplicitConnectionEvidence && candidate.isIPhone12FamilyPhysicalDevice {
            return "connection-unverified-iphone12-family-device-\(ordinal)"
        }

        if candidate.isVerifiedEligibleConnectedDevice {
            return "verified-iphone12-family-device-\(ordinal)"
        }

        if candidate.isEligibleConnectedDevice {
            return "unverified-iphone12-family-device-\(ordinal)"
        }

        return "connected-non-iphone12-device-\(ordinal)"
    }

    private static func normalizedProbeCommands(_ commands: [String]) -> [String] {
        let trimmedCommands = commands
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var seenCommands = Set<String>()
        var uniqueCommands: [String] = []
        for command in trimmedCommands {
            if seenCommands.insert(normalizedProbeCommandValue(command)).inserted {
                uniqueCommands.append(command)
            }
        }

        return uniqueCommands.isEmpty
            ? ["xcrun xctrace list devices"]
            : uniqueCommands
    }

    private static let requiredPhysicalProbeCommands = [
        "xcrun xctrace list devices",
        "xcrun devicectl list devices --json-output -"
    ]

    private static func normalizedProbeCommandEvidence(
        _ evidenceItems: [IOSStageOnePhysicalProbeCommandEvidence]?,
        fallbackCommands: [String],
        fallbackObservedAt: Date?
    ) -> [IOSStageOnePhysicalProbeCommandEvidence] {
        let sourceItems = evidenceItems ?? fallbackCommands.map {
            IOSStageOnePhysicalProbeCommandEvidence(command: $0, observedAt: fallbackObservedAt)
        }

        var normalizedItemsByCommand: [String: IOSStageOnePhysicalProbeCommandEvidence] = [:]
        var normalizedCommandOrder: [String] = []
        for item in sourceItems {
            let trimmedCommand = item.command.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedCommand.isEmpty else {
                continue
            }

            let normalizedCommand = normalizedProbeCommandValue(trimmedCommand)
            if normalizedItemsByCommand[normalizedCommand] == nil {
                normalizedCommandOrder.append(normalizedCommand)
            }

            if shouldReplaceProbeCommandEvidence(
                existing: normalizedItemsByCommand[normalizedCommand],
                with: item
            ) {
                normalizedItemsByCommand[normalizedCommand] =
                    IOSStageOnePhysicalProbeCommandEvidence(
                        command: trimmedCommand,
                        observedAt: item.observedAt
                    )
            }
        }

        return normalizedCommandOrder.compactMap { normalizedItemsByCommand[$0] }
    }

    private static func shouldReplaceProbeCommandEvidence(
        existing: IOSStageOnePhysicalProbeCommandEvidence?,
        with candidate: IOSStageOnePhysicalProbeCommandEvidence
    ) -> Bool {
        guard let existing else {
            return true
        }

        switch (existing.observedAt, candidate.observedAt) {
        case (.none, .none):
            return false
        case (.none, .some):
            return true
        case (.some, .none):
            return false
        case (.some(let existingDate), .some(let candidateDate)):
            return candidateDate > existingDate
        }
    }

    private func containsProbeCommand(_ requiredCommand: String) -> Bool {
        let normalizedRequiredCommand = Self.normalizedProbeCommandValue(requiredCommand)
        return probeCommands.contains {
            Self.normalizedProbeCommandValue($0) == normalizedRequiredCommand
        }
    }

    private func hasCurrentProbeCommandEvidence(for requiredCommand: String) -> Bool {
        let normalizedRequiredCommand = Self.normalizedProbeCommandValue(requiredCommand)
        return probeCommandEvidence.contains { evidence in
            guard Self.normalizedProbeCommandValue(evidence.command) == normalizedRequiredCommand,
                  let observedAt = evidence.observedAt else {
                return false
            }

            let age = generatedAt.timeIntervalSince(observedAt)
            return age >= 0 && age <= deviceProbeMaximumAge
        }
    }

    private static func normalizedProbeCommandValue(_ command: String) -> String {
        command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .lowercased()
    }

    private func hasIOSPhysicalDeviceEvidence(_ candidate: IOSStageOnePhysicalDeviceCandidate) -> Bool {
        if containsIOSDeviceFamilyToken(candidate.hardwareModel) {
            return true
        }

        return containsExplicitNameOnlyIOSDeviceModel(candidate.name)
    }

    private func containsIOSDeviceFamilyToken(_ value: String?) -> Bool {
        guard let normalizedValue = value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !normalizedValue.isEmpty else {
            return false
        }

        return [
            "iphone",
            "ipad",
            "ipod"
        ].contains { normalizedValue.contains($0) }
    }

    private func containsExplicitNameOnlyIOSDeviceModel(_ name: String) -> Bool {
        let normalizedName = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalizedName.isEmpty else {
            return false
        }

        if normalizedName.contains("ipad") || normalizedName.contains("ipod") {
            return true
        }

        let unsupportedIPhoneMarketingSignals = [
            "iphone 3g",
            "iphone 3gs",
            "iphone 4",
            "iphone 4s",
            "iphone 5",
            "iphone 5c",
            "iphone 5s",
            "iphone 6",
            "iphone 6 plus",
            "iphone 6s",
            "iphone 6s plus",
            "iphone 7",
            "iphone 7 plus",
            "iphone 8",
            "iphone 8 plus",
            "iphone se",
            "iphone x",
            "iphone xr",
            "iphone xs",
            "iphone 11",
            "iphone 13",
            "iphone 14",
            "iphone 15",
            "iphone 16",
            "iphone 17"
        ]

        return unsupportedIPhoneMarketingSignals.contains { signal in
            containsBoundedNameOnlyDeviceSignal(signal, in: normalizedName)
        } || containsUnsupportedNumericIPhoneMarketingSignal(in: normalizedName)
    }

    private func containsUnsupportedNumericIPhoneMarketingSignal(in normalizedName: String) -> Bool {
        let pattern = #"(?<![a-z0-9])iphone\s+([0-9]{1,3})(?:\s+(?:mini|plus|pro(?:\s+max)?|air))?(?![a-z0-9])"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return false
        }

        let range = NSRange(normalizedName.startIndex..<normalizedName.endIndex, in: normalizedName)
        return expression
            .matches(in: normalizedName, range: range)
            .contains { match in
                guard let generationRange = Range(match.range(at: 1), in: normalizedName),
                      let generation = Int(normalizedName[generationRange]) else {
                    return false
                }

                return generation != 12
            }
    }

    private func containsBoundedNameOnlyDeviceSignal(
        _ signal: String,
        in normalizedName: String
    ) -> Bool {
        var searchRange = normalizedName.startIndex..<normalizedName.endIndex

        while let range = normalizedName.range(of: signal, range: searchRange) {
            let hasValidPrefix = range.lowerBound == normalizedName.startIndex
                || isNameOnlyDeviceSignalBoundary(normalizedName[normalizedName.index(before: range.lowerBound)])
            let hasValidSuffix = range.upperBound == normalizedName.endIndex
                || isNameOnlyDeviceSignalBoundary(normalizedName[range.upperBound])

            if hasValidPrefix && hasValidSuffix {
                return true
            }

            searchRange = range.upperBound..<normalizedName.endIndex
        }

        return false
    }

    private func isNameOnlyDeviceSignalBoundary(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy {
            !CharacterSet.alphanumerics.contains($0)
        }
    }

    private func safeText(_ text: String) -> String {
        redactedSensitiveReportText(text)
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "/")
    }

    private func redactedSensitiveReportText(_ text: String) -> String {
        let redactions = [
            (#"\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\b"#, "[redacted-uuid]"),
            (#"\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}\b"#, "[redacted-device-id]"),
            (#"(?i)\b[^\s|/]+\.coredevice\.local\b"#, "[redacted-coredevice-host]"),
            (#"(?i)\bserial(?:number)?\s*[:=]?\s*[A-Z0-9]{8,16}\b"#, "[redacted-serial-number]"),
            (#"(?i)\becid\s*[:=]?\s*[0-9]{10,20}\b"#, "[redacted-ecid]")
        ]

        return redactions.reduce(text) { current, redaction in
            guard let expression = try? NSRegularExpression(pattern: redaction.0) else {
                return current
            }

            let range = NSRange(current.startIndex..<current.endIndex, in: current)
            return expression.stringByReplacingMatches(
                in: current,
                range: range,
                withTemplate: redaction.1
            )
        }
    }
}

public enum IOSMemoryStressFixtureKind: String, CaseIterable, Equatable, Sendable {
    case hugeTable
    case hugeCodeBlock
    case hugeImageMetadata
    case largeDocument
}

public struct IOSMemoryStressFixtureResult: Equatable, Sendable {
    public let kind: IOSMemoryStressFixtureKind
    public let sourceByteCount: Int
    public let parsedBlockCount: Int
    public let renderedBlockCount: Int
    public let containsBoundedLocalImageDecodePolicy: Bool
    public let containsPageLevelHorizontalOverflow: Bool

    public init(
        kind: IOSMemoryStressFixtureKind,
        sourceByteCount: Int,
        parsedBlockCount: Int,
        renderedBlockCount: Int,
        containsBoundedLocalImageDecodePolicy: Bool = false,
        containsPageLevelHorizontalOverflow: Bool = false
    ) {
        self.kind = kind
        self.sourceByteCount = max(0, sourceByteCount)
        self.parsedBlockCount = max(0, parsedBlockCount)
        self.renderedBlockCount = max(0, renderedBlockCount)
        self.containsBoundedLocalImageDecodePolicy = containsBoundedLocalImageDecodePolicy
        self.containsPageLevelHorizontalOverflow = containsPageLevelHorizontalOverflow
    }

    public var parsedAndRendered: Bool {
        sourceByteCount > 0
            && parsedBlockCount > 0
            && renderedBlockCount == parsedBlockCount
    }
}

public struct IOSMemoryStressAutomationAudit: Equatable, Sendable {
    public let results: [IOSMemoryStressFixtureResult]

    public init(results: [IOSMemoryStressFixtureResult]) {
        self.results = results
    }

    public var coversRequiredStressFixtures: Bool {
        Set(results.map(\.kind)) == Set(IOSMemoryStressFixtureKind.allCases)
    }

    public var allFixturesParseAndRender: Bool {
        results.allSatisfy(\.parsedAndRendered)
    }

    public var imageMetadataUsesBoundedDecodePolicy: Bool {
        results.contains {
            $0.kind == .hugeImageMetadata && $0.containsBoundedLocalImageDecodePolicy
        }
    }

    public var noPageLevelHorizontalOverflow: Bool {
        results.allSatisfy { !$0.containsPageLevelHorizontalOverflow }
    }

    public var satisfiesStageOneMemoryStressTests: Bool {
        coversRequiredStressFixtures
            && allFixturesParseAndRender
            && imageMetadataUsesBoundedDecodePolicy
            && noPageLevelHorizontalOverflow
    }
}

public struct IOSAccessibilitySmokeAutomationAudit: Equatable, Sendable {
    public let stateAudits: [IOSReaderAccessibilityAudit]
    public let dynamicTypeAudit: IOSDynamicTypeFontTierAudit

    public init(
        stateAudits: [IOSReaderAccessibilityAudit],
        dynamicTypeAudit: IOSDynamicTypeFontTierAudit
    ) {
        self.stateAudits = stateAudits
        self.dynamicTypeAudit = dynamicTypeAudit
    }

    public var labelsEveryIconOnlyControl: Bool {
        !stateAudits.isEmpty
            && stateAudits.allSatisfy(\.hasLabelsForAllIconOnlyControls)
    }

    public var voiceOverOrderMatchesVisualOrder: Bool {
        !stateAudits.isEmpty
            && stateAudits.allSatisfy(\.voiceOverOrderMatchesVisualOrder)
    }

    public var includesSearchAnnouncement: Bool {
        stateAudits.contains { $0.searchAnnouncement?.isEmpty == false }
    }

    public var includesDirtyEditAlert: Bool {
        stateAudits.contains { $0.hasAccessibleDirtyEditAlert }
    }

    public var validatesDynamicTypeForAllTiers: Bool {
        dynamicTypeAudit.validatesAllFourTiers
            && dynamicTypeAudit.allMetricsComposeWithDynamicType
    }

    public var satisfiesStageOneAccessibilitySmokeTests: Bool {
        labelsEveryIconOnlyControl
            && voiceOverOrderMatchesVisualOrder
            && includesSearchAnnouncement
            && includesDirtyEditAlert
            && validatesDynamicTypeForAllTiers
    }
}

public struct IOSProcessRecoveryAutomationAudit: Equatable, Sendable {
    public let captureResult: IOSDirtyEditDraftStoreResult
    public let recoveryOffer: IOSDirtyEditRecoveryOffer
    public let restoredSession: IOSReaderEditSession?
    public let expiredRecoveryOffer: IOSDirtyEditRecoveryOffer
    public let restoredSnapshot: IOSReaderRuntimeRestorationSnapshot

    public init(
        captureResult: IOSDirtyEditDraftStoreResult,
        recoveryOffer: IOSDirtyEditRecoveryOffer,
        restoredSession: IOSReaderEditSession?,
        expiredRecoveryOffer: IOSDirtyEditRecoveryOffer,
        restoredSnapshot: IOSReaderRuntimeRestorationSnapshot
    ) {
        self.captureResult = captureResult
        self.recoveryOffer = recoveryOffer
        self.restoredSession = restoredSession
        self.expiredRecoveryOffer = expiredRecoveryOffer
        self.restoredSnapshot = restoredSnapshot
    }

    public var storesDirtyDraftForRecovery: Bool {
        if case .stored(let draft) = captureResult {
            return !draft.currentSource.isEmpty
        }
        return false
    }

    public var offersUnexpiredDraft: Bool {
        if case .restoreDraft(let draft) = recoveryOffer {
            return !draft.currentSource.isEmpty
        }
        return false
    }

    public var restoresDirtyEditSession: Bool {
        restoredSession?.isDirty == true
    }

    public var clearsExpiredDraft: Bool {
        expiredRecoveryOffer == .noDraft
    }

    public var avoidsPersistentDocumentContentInRotationSnapshot: Bool {
        restoredSnapshot.storesDocumentContentPersistently == false
    }

    public var satisfiesStageOneProcessRecoveryTests: Bool {
        storesDirtyDraftForRecovery
            && offersUnexpiredDraft
            && restoresDirtyEditSession
            && clearsExpiredDraft
            && avoidsPersistentDocumentContentInRotationSnapshot
    }
}

public enum IOSReadmeRequiredCommand: String, CaseIterable, Equatable, Sendable {
    case swiftPMTest = "swift test"
    case conditionalRendererGate = "swift test --filter FastMDMobileCoreTests/testIOSL11"
    case validationReportGate = "swift test --filter FastMDMobileCoreTests/testIOSL12"
    case readmeAuditGate = "swift test --filter FastMDMobileCoreTests/testIOSL13ReadmeDocumentsFinalBuildTestCommands"
    case diffCheck = "git -C .. diff --check -- ios"
    case iPhone12SimulatorBuild = "xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build"
    case iPhone12SimulatorTest = "xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test"
    case simulatorInventory = "xcrun simctl list devices available | rg 'iPhone 12'"
    case xctracePhysicalProbe = "xcrun xctrace list devices"
    case devicectlPhysicalProbe = "xcrun devicectl list devices --json-output -"
}

public struct IOSReadmeCommandAudit: Equatable, Sendable {
    public let readmeText: String
    public let requiredCommands: [IOSReadmeRequiredCommand]

    public init(
        readmeText: String,
        requiredCommands: [IOSReadmeRequiredCommand] = IOSReadmeRequiredCommand.allCases
    ) {
        self.readmeText = readmeText
        self.requiredCommands = requiredCommands
    }

    public var missingRequiredCommands: [IOSReadmeRequiredCommand] {
        requiredCommands.filter { !readmeText.contains($0.rawValue) }
    }

    public var documentsSwiftPMValidation: Bool {
        contains(.swiftPMTest)
            && contains(.conditionalRendererGate)
            && contains(.validationReportGate)
            && contains(.readmeAuditGate)
    }

    public var documentsIPhone12SimulatorValidation: Bool {
        contains(.simulatorInventory)
            && contains(.iPhone12SimulatorBuild)
            && contains(.iPhone12SimulatorTest)
    }

    public var documentsPhysicalDeviceProbeWithoutCompletionClaim: Bool {
        contains(.xctracePhysicalProbe)
            && contains(.devicectlPhysicalProbe)
            && readmeText.contains("These probes do not complete the physical-device gate by themselves.")
            && readmeText.contains("connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max")
    }

    public var documentsIOSOnlyDiffCheck: Bool {
        contains(.diffCheck)
    }

    public var recordsReportLocationAndReconciliationBoundary: Bool {
        readmeText.contains("ios/docs/reports/")
            && readmeText.contains("The supervising session reconciles those reports")
    }

    public var satisfiesStageOneIOSReadmeBuildTestCommands: Bool {
        missingRequiredCommands.isEmpty
            && documentsSwiftPMValidation
            && documentsIPhone12SimulatorValidation
            && documentsPhysicalDeviceProbeWithoutCompletionClaim
            && documentsIOSOnlyDiffCheck
            && recordsReportLocationAndReconciliationBoundary
    }

    private func contains(_ command: IOSReadmeRequiredCommand) -> Bool {
        readmeText.contains(command.rawValue)
    }
}

public enum IOSStageOneReconciliationChecklistItem: String, CaseIterable, Equatable, Sendable {
    case localRendererPackagingOfflineTests = "Add local renderer packaging/offline tests if JS renderer assets are used."
    case wkWebViewRequestBlockingTests = "Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used."
    case rendererAssetManifestHashTests = "Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored."
    case iPhone12SimulatorBuild = "Run iOS iPhone 12 simulator build."
    case iPhone12SimulatorTests = "Run iOS iPhone 12 simulator tests."
    case iPhone12RealDeviceValidation = "Run iOS iPhone 12-class real-device validation before parity-complete release claim."
    case iOSPerformanceReport = "Capture iOS performance report."
    case iOSSecurityAuditReport = "Capture iOS security audit report."
    case richFixtureRenderReport = "Capture rich fixture render report."
    case iOSReadmeCommands = "Update ios/README.md with final build/test commands after iOS skeleton lands."
    case iOSValidationReports = "Record validation reports under ios/docs/reports/."
}

public struct IOSStageOneReconciliationChecklistEvidence: Equatable, Sendable {
    public struct Item: Equatable, Sendable {
        public let checklistItem: IOSStageOneReconciliationChecklistItem
        public let canMarkComplete: Bool
        public let evidencePath: String
        public let evidenceSummary: String

        public init(
            checklistItem: IOSStageOneReconciliationChecklistItem,
            canMarkComplete: Bool,
            evidencePath: String,
            evidenceSummary: String
        ) {
            self.checklistItem = checklistItem
            self.canMarkComplete = canMarkComplete
            self.evidencePath = evidencePath
            self.evidenceSummary = evidenceSummary
        }
    }

    public let generatedAt: Date
    public let conditionalRendererEvidence: IOSConditionalRendererChecklistEvidence
    public let simulatorReport: IOSStageOneSimulatorValidationReport
    public let realDeviceReport: IOSStageOneRealDeviceValidationReport
    public let performanceReport: IOSStageOnePerformanceReport
    public let securityReport: IOSStageOneSecurityAuditReport
    public let richFixtureReport: IOSRichFixtureRenderReport
    public let readmeAudit: IOSReadmeCommandAudit
    public let reportPaths: [String]
    public let reportPathsByChecklistItem: [IOSStageOneReconciliationChecklistItem: String]

    public init(
        generatedAt: Date,
        conditionalRendererEvidence: IOSConditionalRendererChecklistEvidence,
        simulatorReport: IOSStageOneSimulatorValidationReport,
        realDeviceReport: IOSStageOneRealDeviceValidationReport,
        performanceReport: IOSStageOnePerformanceReport,
        securityReport: IOSStageOneSecurityAuditReport,
        richFixtureReport: IOSRichFixtureRenderReport,
        readmeAudit: IOSReadmeCommandAudit,
        reportPaths: [String],
        reportPathsByChecklistItem: [IOSStageOneReconciliationChecklistItem: String] = [:]
    ) {
        self.generatedAt = generatedAt
        self.conditionalRendererEvidence = conditionalRendererEvidence
        self.simulatorReport = simulatorReport
        self.realDeviceReport = realDeviceReport
        self.performanceReport = performanceReport
        self.securityReport = securityReport
        self.richFixtureReport = richFixtureReport
        self.readmeAudit = readmeAudit
        self.reportPaths = Array(Set(reportPaths)).sorted()
        self.reportPathsByChecklistItem = Dictionary(
            uniqueKeysWithValues: reportPathsByChecklistItem.map {
                ($0.key, $0.value.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        )
    }

    public var pathsStayIOSLocalReports: Bool {
        !allEvidencePaths.isEmpty
            && allEvidencePaths.allSatisfy(isIOSLocalMarkdownReportPath)
    }

    public var hasItemSpecificEvidenceForEveryCompletableIOSChecklistItem: Bool {
        let completableItems: Set<IOSStageOneReconciliationChecklistItem> = [
            .localRendererPackagingOfflineTests,
            .wkWebViewRequestBlockingTests,
            .rendererAssetManifestHashTests,
            .iPhone12SimulatorBuild,
            .iPhone12SimulatorTests,
            .iOSPerformanceReport,
            .iOSSecurityAuditReport,
            .richFixtureRenderReport,
            .iOSReadmeCommands,
            .iOSValidationReports
        ]

        return completableItems.allSatisfy { item in
            guard let path = reportPathsByChecklistItem[item] else {
                return false
            }
            return isIOSLocalMarkdownReportPath(path)
        }
    }

    public var hasEvidenceForEveryCompletableIOSChecklistItem: Bool {
        let completableItems: Set<IOSStageOneReconciliationChecklistItem> = [
            .localRendererPackagingOfflineTests,
            .wkWebViewRequestBlockingTests,
            .rendererAssetManifestHashTests,
            .iPhone12SimulatorBuild,
            .iPhone12SimulatorTests,
            .iOSPerformanceReport,
            .iOSSecurityAuditReport,
            .richFixtureRenderReport,
            .iOSReadmeCommands,
            .iOSValidationReports
        ]
        return completableItems.isSubset(of: Set(itemsToMarkComplete.map(\.checklistItem)))
    }

    public var itemsToMarkComplete: [Item] {
        items.filter(\.canMarkComplete)
    }

    public var itemsToKeepOpen: [Item] {
        items.filter { !$0.canMarkComplete }
    }

    public var capturesSupervisorReconciliationEvidence: Bool {
        pathsStayIOSLocalReports
            && hasItemSpecificEvidenceForEveryCompletableIOSChecklistItem
            && hasEvidenceForEveryCompletableIOSChecklistItem
            && itemsToKeepOpen.map(\.checklistItem) == [.iPhone12RealDeviceValidation]
            && realDeviceReport.hasRequiredPhysicalProbeCommandCoverage
            && realDeviceReport.capturesRealDeviceGateEvidence
            && !realDeviceReport.completesRequiredRealDeviceValidation
    }

    public var items: [Item] {
        [
            Item(
                checklistItem: .localRendererPackagingOfflineTests,
                canMarkComplete: conditionalRendererEvidence.localRendererPackagingOfflineGateSatisfied,
                evidencePath: evidencePath(for: .localRendererPackagingOfflineTests),
                evidenceSummary: conditionalRendererEvidence.checklistItems[0].evidenceSummary
            ),
            Item(
                checklistItem: .wkWebViewRequestBlockingTests,
                canMarkComplete: conditionalRendererEvidence.wkWebViewRequestBlockingGateSatisfied,
                evidencePath: evidencePath(for: .wkWebViewRequestBlockingTests),
                evidenceSummary: conditionalRendererEvidence.checklistItems[1].evidenceSummary
            ),
            Item(
                checklistItem: .rendererAssetManifestHashTests,
                canMarkComplete: conditionalRendererEvidence.rendererAssetManifestHashGateSatisfied,
                evidencePath: evidencePath(for: .rendererAssetManifestHashTests),
                evidenceSummary: conditionalRendererEvidence.checklistItems[2].evidenceSummary
            ),
            Item(
                checklistItem: .iPhone12SimulatorBuild,
                canMarkComplete: simulatorReport.capturesIPhone12SimulatorBuildGate,
                evidencePath: evidencePath(for: .iPhone12SimulatorBuild),
                evidenceSummary: simulatorReport.buildCommand
            ),
            Item(
                checklistItem: .iPhone12SimulatorTests,
                canMarkComplete: simulatorReport.capturesIPhone12SimulatorTestGate,
                evidencePath: evidencePath(for: .iPhone12SimulatorTests),
                evidenceSummary: simulatorReport.testCommand
            ),
            Item(
                checklistItem: .iPhone12RealDeviceValidation,
                canMarkComplete: realDeviceReport.completesRequiredRealDeviceValidation,
                evidencePath: evidencePath(for: .iPhone12RealDeviceValidation),
                evidenceSummary: realDeviceReport.completesRequiredRealDeviceValidation
                    ? "Connected physical iPhone 12-family validation completed."
                    : realDeviceReport.blockerSummary
            ),
            Item(
                checklistItem: .iOSPerformanceReport,
                canMarkComplete: performanceReport.capturesRequiredIOSPerformanceReport,
                evidencePath: evidencePath(for: .iOSPerformanceReport),
                evidenceSummary: "Performance report captures parse, render, search, font tier switch, save, and redacted iOS diagnostics."
            ),
            Item(
                checklistItem: .iOSSecurityAuditReport,
                canMarkComplete: securityReport.capturesRequiredIOSSecurityAuditReport,
                evidencePath: evidencePath(for: .iOSSecurityAuditReport),
                evidenceSummary: "Security report captures release posture, malicious fixtures, remote image privacy, and conditional renderer posture."
            ),
            Item(
                checklistItem: .richFixtureRenderReport,
                canMarkComplete: richFixtureReport.capturesRequiredRichFixtureRenderReport,
                evidencePath: evidencePath(for: .richFixtureRenderReport),
                evidenceSummary: "Rich fixture render report covers \(richFixtureReport.audit.coveredCategories.count)/\(IOSRichFixtureRenderCategory.allCases.count) categories and the snapshot matrix."
            ),
            Item(
                checklistItem: .iOSReadmeCommands,
                canMarkComplete: readmeAudit.satisfiesStageOneIOSReadmeBuildTestCommands,
                evidencePath: evidencePath(for: .iOSReadmeCommands),
                evidenceSummary: "iOS README documents SwiftPM, iPhone 12 simulator, physical-device probes, diff check, and report reconciliation."
            ),
            Item(
                checklistItem: .iOSValidationReports,
                canMarkComplete: pathsStayIOSLocalReports,
                evidencePath: evidencePath(for: .iOSValidationReports),
                evidenceSummary: "Validation evidence is recorded under ios/docs/reports/."
            )
        ]
    }

    public var markdown: String {
        let completeRows = items.map { item in
            "| \(safeText(item.checklistItem.rawValue)) | \(item.canMarkComplete ? "COMPLETE" : "OPEN") | \(safeText(item.evidencePath)) | \(safeText(item.evidenceSummary)) |"
        }

        return ([
            "# Stage 1 iOS Reconciliation Evidence",
            "",
            "- Generated: \(iso8601String(from: generatedAt))",
            "- Report paths are iOS-local: \(pathsStayIOSLocalReports)",
            "- Item-specific evidence paths captured: \(hasItemSpecificEvidenceForEveryCompletableIOSChecklistItem)",
            "- Real-device physical probe command coverage: \(realDeviceReport.hasRequiredPhysicalProbeCommandCoverage)",
            "- Supervisor evidence captured: \(capturesSupervisorReconciliationEvidence)",
            "- Items to mark complete: \(itemsToMarkComplete.count)",
            "- Items to keep open: \(itemsToKeepOpen.map { $0.checklistItem.rawValue }.joined(separator: "; "))",
            "",
            "| Checklist item | Status | Evidence path | Evidence summary |",
            "| --- | --- | --- | --- |"
        ] + completeRows).joined(separator: "\n") + "\n"
    }

    private var primaryEvidencePath: String {
        reportPaths.first ?? "ios/docs/reports/missing-stage1-ios-reconciliation-evidence.md"
    }

    private var allEvidencePaths: [String] {
        Array(Set(reportPaths + Array(reportPathsByChecklistItem.values))).sorted()
    }

    private func evidencePath(for item: IOSStageOneReconciliationChecklistItem) -> String {
        reportPathsByChecklistItem[item] ?? primaryEvidencePath
    }

    private func isIOSLocalMarkdownReportPath(_ path: String) -> Bool {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        return path == trimmedPath
            && path.hasPrefix("ios/docs/reports/")
            && path.hasSuffix(".md")
            && !path.contains("://")
            && !path.contains("..")
            && !path.contains("\\")
            && !path.contains { $0.isWhitespace }
    }

    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private func safeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "|", with: "/")
    }
}
