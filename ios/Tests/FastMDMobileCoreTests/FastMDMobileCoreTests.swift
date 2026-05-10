import Foundation
import XCTest
@testable import FastMDMobileCore

final class FastMDMobileCoreTests: XCTestCase {
    private static let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static let canonicalMarkdownFixtureNames = [
        "basic.md",
        "cjk.md",
        "encoding-utf8-bom.md",
        "external-change-before-save.md",
        "huge-code-block.md",
        "huge-table.md",
        "large-5mb.md",
        "line-endings-crlf.md",
        "local-image.md",
        "long-1mb.md",
        "long-filename.md",
        "malformed-markdown.md",
        "malicious-html.md",
        "malicious-links.md",
        "readonly-document.md",
        "remote-image.md",
        "rich-preview.md",
        "rtl-and-emoji.md"
    ]
    private static let requiredPhysicalProbeCommands = [
        "xcrun xctrace list devices",
        "xcrun devicectl list devices --json-output -"
    ]

    func testMobileFontTierBodyPointSizes() {
        XCTAssertEqual(MobileFontTier.compact.bodyPointSize, 14)
        XCTAssertEqual(MobileFontTier.default.bodyPointSize, 16)
        XCTAssertEqual(MobileFontTier.large.bodyPointSize, 18)
        XCTAssertEqual(MobileFontTier.reader.bodyPointSize, 21)
    }

    func testMobileFontTierLineHeightsMatchBlueprint() {
        XCTAssertEqual(MobileFontTier.compact.lineHeightMultiple, 1.48)
        XCTAssertEqual(MobileFontTier.default.lineHeightMultiple, 1.52)
        XCTAssertEqual(MobileFontTier.large.lineHeightMultiple, 1.56)
        XCTAssertEqual(MobileFontTier.reader.lineHeightMultiple, 1.60)

        XCTAssertEqual(MobileFontTier.compact.monospacePointSize, 13)
        XCTAssertEqual(MobileFontTier.default.monospacePointSize, 15)
        XCTAssertEqual(MobileFontTier.large.monospacePointSize, 17)
        XCTAssertEqual(MobileFontTier.reader.monospacePointSize, 20)
    }

    func testReaderStateIncludesStageOneStates() {
        XCTAssertEqual(
            ReaderState.allCases,
            [
                .empty,
                .loading,
                .rendering,
                .ready,
                .searching,
                .editingSource,
                .editingBlock,
                .saving,
                .readOnly,
                .permissionLost,
                .error
            ]
        )
    }

    func testMobileDocumentHandleStoresDocumentMetadata() {
        let handle = MobileDocumentHandle(
            identifier: "recent:readonly-document",
            displayName: "readonly-document.md",
            origin: .documentPicker,
            access: .readOnly,
            bookmarkData: Data([0x01, 0x02])
        )

        XCTAssertEqual(handle.identifier, "recent:readonly-document")
        XCTAssertEqual(handle.displayName, "readonly-document.md")
        XCTAssertEqual(handle.origin, .documentPicker)
        XCTAssertEqual(handle.access, .readOnly)
        XCTAssertFalse(handle.canWrite)
        XCTAssertEqual(handle.bookmarkData, Data([0x01, 0x02]))
    }

    func testMarkdownLoadResultCarriesMetadataOriginAndSource() {
        let loadedAt = Date(timeIntervalSince1970: 1_777_777_777)
        let handle = MobileDocumentHandle(
            identifier: "share:text:temporary",
            displayName: "Shared Markdown",
            origin: .shareText,
            access: .readOnly
        )
        let metadata = MobileFileMetadata(
            displayName: "Shared Markdown",
            byteCount: 18,
            contentTypeIdentifier: "net.daringfireball.markdown",
            modifiedAt: nil
        )

        let result = MarkdownLoadResult(
            handle: handle,
            metadata: metadata,
            source: "# Shared\n\nBody text",
            encoding: .utf8,
            lineEnding: .lf,
            loadedAt: loadedAt
        )

        XCTAssertEqual(result.handle.origin, .shareText)
        XCTAssertEqual(result.metadata.byteCount, 18)
        XCTAssertEqual(result.source, "# Shared\n\nBody text")
        XCTAssertEqual(result.encoding, .utf8)
        XCTAssertEqual(result.lineEnding, .lf)
        XCTAssertEqual(result.loadedAt, loadedAt)
    }

    func testRenderBlockIDsAreStableFromKindSourceRangeAndOrdinal() {
        let range = MarkdownSourceRange(
            startUTF8Offset: 0,
            endUTF8Offset: 12,
            startLine: 1,
            endLine: 1
        )
        let first = MarkdownRenderBlock(
            kind: .heading,
            sourceRange: range,
            ordinal: 0,
            textPreview: "Title"
        )
        let same = MarkdownRenderBlock(
            kind: .heading,
            sourceRange: range,
            ordinal: 0,
            textPreview: "Title changed after inline styling"
        )
        let next = MarkdownRenderBlock(
            kind: .heading,
            sourceRange: range,
            ordinal: 1,
            textPreview: "Title"
        )
        let document = MarkdownRenderDocument(
            blocks: [first, next],
            sourceByteCount: 128
        )

        XCTAssertTrue(range.isValid)
        XCTAssertEqual(first.id, same.id)
        XCTAssertNotEqual(first.id, next.id)
        XCTAssertEqual(first.id.rawValue, "heading:0:12:1:1:0")
        XCTAssertEqual(document.block(id: first.id), first)
        XCTAssertEqual(document.sourceByteCount, 128)
    }

    func testMarkdownParserAdapterBuildsRenderBlocksWithSourceRanges() {
        let source = """
        # Title

        Paragraph one
        continues.

        - [x] Done
        - [ ] Todo

        | A | B |
        | --- | --- |
        | 1 | 2 |

        ```swift
        let value = 1
        ```

        ```mermaid
        flowchart TD
        ```

        <details>
        <summary>More</summary>
        </details>
        """

        let document = MarkdownParserAdapter().parse(source)

        XCTAssertEqual(
            document.blocks.map(\.kind),
            [
                .heading,
                .paragraph,
                .taskList,
                .table,
                .codeFence,
                .richFallback,
                .htmlFallback
            ]
        )
        XCTAssertEqual(document.sourceByteCount, source.utf8.count)
        XCTAssertTrue(document.blocks.allSatisfy { $0.sourceRange.isValid })
        XCTAssertEqual(document.blocks[0].sourceRange.startLine, 1)
        XCTAssertEqual(document.blocks[0].sourceRange.endLine, 1)
        XCTAssertEqual(document.blocks[1].sourceRange.startLine, 3)
        XCTAssertEqual(document.blocks[1].sourceRange.endLine, 4)
        XCTAssertEqual(document.blocks[5].textPreview, "```mermaid flowchart TD ```")

        let reparsed = MarkdownParserAdapter().parse(source)
        XCTAssertEqual(document.blocks.map(\.id), reparsed.blocks.map(\.id))
    }

    func testMarkdownParserAdapterClassifiesCanonicalRichFixtureSurface() throws {
        let fixtureURL = Self.packageRoot
            .appendingPathComponent("Tests")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Markdown")
            .appendingPathComponent("rich-preview.md")
        let source = try String(contentsOf: fixtureURL, encoding: .utf8)

        let document = MarkdownParserAdapter().parse(source)
        let kinds = Set(document.blocks.map(\.kind))

        XCTAssertEqual(document.sourceByteCount, source.utf8.count)
        XCTAssertTrue(document.blocks.allSatisfy { $0.sourceRange.isValid })
        XCTAssertTrue(document.blocks.allSatisfy { !$0.textPreview.isEmpty })
        XCTAssertTrue(kinds.isSuperset(of: [
            .heading,
            .paragraph,
            .blockquote,
            .unorderedList,
            .orderedList,
            .taskList,
            .table,
            .codeFence,
            .richFallback,
            .image,
            .horizontalRule,
            .footnote,
            .htmlFallback
        ]))
        XCTAssertTrue(
            document.blocks.contains {
                $0.kind == .richFallback && $0.textPreview.contains("```mermaid")
            }
        )
        XCTAssertTrue(
            document.blocks.contains {
                $0.kind == .richFallback && $0.textPreview.contains("$$")
            }
        )
    }

    func testFastMDErrorCodesCoverStageOneCategories() {
        let categories = Set(FastMDErrorCode.allCases.map(\.category))

        XCTAssertEqual(categories, Set(FastMDErrorCategory.allCases))
        XCTAssertEqual(FastMDErrorCode.openFailed.category, .open)
        XCTAssertEqual(FastMDErrorCode.unsupportedEncoding.category, .read)
        XCTAssertEqual(FastMDErrorCode.parseFailed.category, .parse)
        XCTAssertEqual(FastMDErrorCode.renderFailed.category, .render)
        XCTAssertEqual(FastMDErrorCode.searchFailed.category, .search)
        XCTAssertEqual(FastMDErrorCode.editConflict.category, .edit)
        XCTAssertEqual(FastMDErrorCode.externalMutation.category, .save)
        XCTAssertEqual(FastMDErrorCode.linkBlocked.category, .link)
        XCTAssertEqual(FastMDErrorCode.permissionLost.category, .permission)
        XCTAssertEqual(FastMDErrorCode.securityBlocked.category, .security)
    }

    func testMobileLinkPolicyAllowsConfirmsAndBlocksByScheme() {
        let policy = MobileLinkPolicy()

        XCTAssertEqual(
            policy.decision(for: "mailto:reader@example.com"),
            MobileLinkPolicyDecision(
                kind: .allowed,
                normalizedURLString: "mailto:reader@example.com"
            )
        )
        XCTAssertEqual(
            policy.decision(for: "https://example.com/doc.md"),
            MobileLinkPolicyDecision(
                kind: .confirm,
                normalizedURLString: "https://example.com/doc.md"
            )
        )
        XCTAssertEqual(
            policy.decision(for: "javascript:alert(1)"),
            MobileLinkPolicyDecision(
                kind: .blocked,
                normalizedURLString: "javascript:alert(1)",
                reason: .dangerousScheme
            )
        )
        XCTAssertEqual(
            policy.decision(for: "data:text/html;base64,PHNjcmlwdD4="),
            MobileLinkPolicyDecision(
                kind: .blocked,
                normalizedURLString: "data:text/html;base64,PHNjcmlwdD4=",
                reason: .dangerousScheme
            )
        )
        XCTAssertEqual(
            policy.decision(for: "fastmd-local-anchor"),
            MobileLinkPolicyDecision(
                kind: .blocked,
                normalizedURLString: "fastmd-local-anchor",
                reason: .missingScheme
            )
        )
    }

    func testMobileLinkPolicyBlocksRemoteResourcesByDefault() {
        let policy = MobileLinkPolicy()

        XCTAssertEqual(
            policy.decision(for: "https://example.com/image.png", isRemoteResource: true),
            MobileLinkPolicyDecision(
                kind: .blocked,
                normalizedURLString: "https://example.com/image.png",
                reason: .remoteResourceDisabled
            )
        )
    }

    func testIOSSecurityPostureContractsDefaultToStageOneClosedState() {
        let imagePolicy = IOSLocalImageDownsamplePolicy()
        let accessAudit = IOSSecurityScopedAccessAudit(
            startedAccessCount: 3,
            stoppedAccessCount: 3
        )
        let releasePosture = IOSReleaseSecurityPosture()

        XCTAssertEqual(imagePolicy.implementation, .imageIO)
        XCTAssertEqual(imagePolicy.maximumPixelDimension, 2048)
        XCTAssertTrue(imagePolicy.createsThumbnailFromImageIfAbsent)
        XCTAssertTrue(imagePolicy.createsThumbnailWithTransform)
        XCTAssertFalse(imagePolicy.cachesFullSizeImageImmediately)
        XCTAssertFalse(imagePolicy.decodesRemoteImages)
        XCTAssertTrue(imagePolicy.satisfiesStageOneLocalImageRule)

        XCTAssertTrue(accessAudit.balancesEveryStartedAccess)
        XCTAssertTrue(accessAudit.unresolvedStaleBookmarksReturnPermissionLost)
        XCTAssertEqual(accessAudit.status, .satisfied)
        XCTAssertEqual(
            IOSSecurityScopedAccessAudit(
                startedAccessCount: 2,
                stoppedAccessCount: 1
            ).status,
            .blocked
        )

        XCTAssertFalse(releasePosture.appTransportSecurityAllowsArbitraryLoads)
        XCTAssertFalse(releasePosture.privacyManifestTracksUsers)
        XCTAssertTrue(releasePosture.backgroundModes.isEmpty)
        XCTAssertFalse(releasePosture.usesWKWebViewRichRendering)
        XCTAssertEqual(releasePosture.localRendererPolicy.mode, .nativeFallbackOnly)
        XCTAssertEqual(releasePosture.appTransportSecurityStatus, .satisfied)
        XCTAssertEqual(releasePosture.privacyManifestStatus, .satisfied)
        XCTAssertEqual(releasePosture.backgroundModeStatus, .satisfied)
        XCTAssertEqual(releasePosture.richRendererStatus, .satisfied)
        XCTAssertTrue(releasePosture.satisfiesStageOneReleasePosture)
    }

    func testIOSReleaseSecurityPostureBlocksBroadATSPrivacyBackgroundAndUnsafeWKWebView() {
        let broadATS = IOSReleaseSecurityPosture(appTransportSecurityAllowsArbitraryLoads: true)
        let tracking = IOSReleaseSecurityPosture(privacyManifestTracksUsers: true)
        let backgroundMode = IOSReleaseSecurityPosture(backgroundModes: ["fetch"])
        let unsafeWKWebView = IOSReleaseSecurityPosture(
            usesWKWebViewRichRendering: true,
            localRendererPolicy: .nativeFallbackOnly
        )
        let safeWKWebView = IOSReleaseSecurityPosture(
            usesWKWebViewRichRendering: true,
            localRendererPolicy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers")
        )

        XCTAssertEqual(broadATS.appTransportSecurityStatus, .blocked)
        XCTAssertFalse(broadATS.satisfiesStageOneReleasePosture)
        XCTAssertEqual(tracking.privacyManifestStatus, .blocked)
        XCTAssertFalse(tracking.satisfiesStageOneReleasePosture)
        XCTAssertEqual(backgroundMode.backgroundModeStatus, .blocked)
        XCTAssertFalse(backgroundMode.satisfiesStageOneReleasePosture)
        XCTAssertEqual(unsafeWKWebView.richRendererStatus, .blocked)
        XCTAssertFalse(unsafeWKWebView.satisfiesStageOneReleasePosture)

        XCTAssertEqual(safeWKWebView.richRendererStatus, .satisfied)
        XCTAssertTrue(safeWKWebView.satisfiesStageOneReleasePosture)
    }

    func testMobilePerformanceProfilesCoverAndroidAndIOSContracts() {
        let profiles: [MobilePerformanceProfile] = [
            .androidLegacyEfficient,
            .iOSPhone12Standard,
            .iOSMemoryConstrained
        ]

        XCTAssertEqual(Set(profiles.map(\.platform)), [.android, .iOS])
        XCTAssertTrue(profiles.allSatisfy(\.keepsFileIOOffMainActor))
        XCTAssertTrue(profiles.allSatisfy(\.keepsParseAndSearchOffMainActor))
        XCTAssertTrue(profiles.allSatisfy(\.usesLazyBlockRendering))
        XCTAssertTrue(profiles.allSatisfy(\.boundsLocalImageDecode))
        XCTAssertFalse(MobilePerformanceProfile.iOSPhone12Standard.disablesExpensiveAnimations)
        XCTAssertTrue(MobilePerformanceProfile.iOSMemoryConstrained.disablesExpensiveAnimations)
    }

    func testLocalRichRendererAssetPolicyDefaultsToOfflineNativeFallback() {
        let policy = LocalRichRendererAssetPolicy.nativeFallbackOnly

        XCTAssertEqual(policy.mode, .nativeFallbackOnly)
        XCTAssertEqual(policy.allowedBlockKinds, [.mermaid, .inlineMath, .blockMath])
        XCTAssertTrue(policy.allowedDependencyKinds.isEmpty)
        XCTAssertNil(policy.bundleResourceRoot)
        XCTAssertFalse(policy.allowsNetworkRequests)
        XCTAssertFalse(policy.allowsCDNResources)
        XCTAssertFalse(policy.allowsExternalNavigation)
        XCTAssertFalse(policy.allowsDataURLs)
        XCTAssertFalse(policy.allowsIFrames)
    }

    func testVendoredRichRendererPolicyStillBlocksNetworkSurfaces() {
        let policy = LocalRichRendererAssetPolicy.vendoredLocalBundle(
            bundleResourceRoot: "RichRendererAssets"
        )

        XCTAssertEqual(policy.mode, .vendoredLocalBundle)
        XCTAssertEqual(policy.allowedDependencyKinds, [.javascript, .css, .font])
        XCTAssertEqual(policy.bundleResourceRoot, "RichRendererAssets")
        XCTAssertFalse(policy.allowsNetworkRequests)
        XCTAssertFalse(policy.allowsCDNResources)
        XCTAssertFalse(policy.allowsExternalNavigation)
        XCTAssertFalse(policy.allowsDataURLs)
        XCTAssertFalse(policy.allowsIFrames)
    }

    func testNativeRichRendererRuntimeAuditRequiresNoBundledAssets() {
        let audit = LocalRichRendererRuntimeAudit()

        XCTAssertTrue(audit.usesNativeFallbackOnly)
        XCTAssertFalse(audit.requiresVendoredAssetPackaging)
        XCTAssertEqual(audit.packagingStatus, .notRequiredNativeFallback)
        XCTAssertTrue(audit.blocksAllNetworkAndNavigationSurfaces)
        XCTAssertTrue(audit.canRenderStageOneRichBlocksOffline)
        XCTAssertTrue(audit.declaredAssetNames.isEmpty)
    }

    func testVendoredRichRendererRuntimeAuditRequiresLocalAssets() {
        let incomplete = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers")
        )
        let complete = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: [
                "mermaid.min.js",
                "katex.min.css",
                "katex-main.woff2"
            ]
        )

        XCTAssertTrue(incomplete.requiresVendoredAssetPackaging)
        XCTAssertEqual(incomplete.packagingStatus, .missingLocalAssets)
        XCTAssertFalse(incomplete.canRenderStageOneRichBlocksOffline)

        XCTAssertTrue(complete.declaredAssetNamesAreLocalBundleReferences)
        XCTAssertEqual(complete.packagingStatus, .packagedLocalAssets)
        XCTAssertTrue(complete.blocksAllNetworkAndNavigationSurfaces)
        XCTAssertTrue(complete.canRenderStageOneRichBlocksOffline)
    }

    func testVendoredRichRendererRuntimeAuditRejectsDuplicateDeclaredAssets() {
        let duplicate = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: [
                "mermaid/mermaid.min.mjs",
                "math/katex.min.css",
                "mermaid/mermaid.min.mjs"
            ]
        )
        let unique = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: [
                "mermaid/mermaid.min.mjs",
                "math/katex.min.css",
                "math/fonts/katex-main.woff2"
            ]
        )

        XCTAssertFalse(duplicate.declaredAssetNamesAreUnique)
        XCTAssertTrue(duplicate.declaredAssetNamesAreLocalBundleReferences)
        XCTAssertEqual(duplicate.packagingStatus, .missingLocalAssets)
        XCTAssertFalse(duplicate.canRenderStageOneRichBlocksOffline)

        XCTAssertTrue(unique.declaredAssetNamesAreUnique)
        XCTAssertTrue(unique.declaredAssetNamesAreLocalBundleReferences)
        XCTAssertEqual(unique.packagingStatus, .packagedLocalAssets)
        XCTAssertTrue(unique.canRenderStageOneRichBlocksOffline)
    }

    func testVendoredRichRendererRuntimeAuditRejectsUnsafeDeclaredAssetNames() {
        let unsafeAssetNameSets = [
            ["https://cdn.example.com/mermaid.js"],
            ["javascript:alert(1)"],
            ["data:text/javascript;base64,ZXhwb3J0IGRlZmF1bHQge30="],
            ["/FastMDRenderers/renderer.js"],
            ["../renderer.js"],
            ["fonts/../renderer.js"],
            ["fonts\\katex-main.woff2"],
            [" renderer.js"],
            ["renderer.js?cache=1"],
            ["renderer.css#hash"],
            ["config.json"]
        ]

        let validNestedAssets = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: [
                "mermaid/mermaid.min.mjs",
                "math/katex.min.css",
                "math/fonts/katex-main.woff2",
                "details/details-renderer.htm"
            ]
        )

        XCTAssertTrue(validNestedAssets.declaredAssetNamesAreLocalBundleReferences)
        XCTAssertEqual(validNestedAssets.packagingStatus, .packagedLocalAssets)

        for assetNames in unsafeAssetNameSets {
            let audit = LocalRichRendererRuntimeAudit(
                policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
                declaredAssetNames: assetNames
            )

            XCTAssertFalse(
                audit.declaredAssetNamesAreLocalBundleReferences,
                "Expected unsafe declared renderer asset names to be rejected: \(assetNames)"
            )
            XCTAssertEqual(audit.packagingStatus, .missingLocalAssets)
            XCTAssertFalse(audit.canRenderStageOneRichBlocksOffline)
        }
    }

    func testIOSRichRendererRequestBlockingPolicyAllowsOnlyBundledRendererFiles() {
        let rendererRoot = URL(fileURLWithPath: "/App/FastMD.app/FastMDRenderers")
        let policy = IOSRichRendererRequestBlockingPolicy(bundledRendererRoot: rendererRoot)

        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("index.html"),
                context: .mainDocument
            ),
            IOSRichRendererRequestDecision(
                kind: .allowed,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/index.html"
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("mermaid.min.js"),
                context: .script
            ),
            IOSRichRendererRequestDecision(
                kind: .allowed,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/mermaid.min.js"
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("fonts/katex-main.woff2"),
                context: .font
            ),
            IOSRichRendererRequestDecision(
                kind: .allowed,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/fonts/katex-main.woff2"
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("renderer.css"),
                context: .stylesheet
            ),
            IOSRichRendererRequestDecision(
                kind: .allowed,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/renderer.css"
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("images/local.webp"),
                context: .image
            ),
            IOSRichRendererRequestDecision(
                kind: .allowed,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/images/local.webp"
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: URL(fileURLWithPath: "/tmp/renderer.js"),
                context: .script
            ),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "file:///tmp/renderer.js",
                reason: .nonBundledFile
            )
        )
        XCTAssertEqual(
            policy.decision(for: rendererRoot, context: .mainDocument),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers",
                reason: .nonBundledFile
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("../Secrets/renderer.js"),
                context: .script
            ),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/../Secrets/renderer.js",
                reason: .nonBundledFile
            )
        )
    }

    func testIOSRichRendererRequestBlockingPolicyBlocksContextMismatchesAndUnknownBundledFiles() {
        let rendererRoot = URL(fileURLWithPath: "/App/FastMD.app/FastMDRenderers")
        let policy = IOSRichRendererRequestBlockingPolicy(bundledRendererRoot: rendererRoot)

        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("config.json"),
                context: .script
            ),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/config.json",
                reason: .unsupportedRendererAssetType
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("mermaid.min.js"),
                context: .stylesheet
            ),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/mermaid.min.js",
                reason: .unsupportedRendererAssetType
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("index.html"),
                context: .script
            ),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/index.html",
                reason: .unsupportedRendererAssetType
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("fonts/katex-main.woff2"),
                context: .mainDocument
            ),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/fonts/katex-main.woff2",
                reason: .unsupportedRendererAssetType
            )
        )
        XCTAssertEqual(
            policy.decision(
                for: rendererRoot.appendingPathComponent("images/active.svg"),
                context: .image
            ),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/images/active.svg",
                reason: .unsupportedRendererAssetType
            )
        )
    }

    func testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames() throws {
        let rendererRoot = URL(fileURLWithPath: "/App/FastMD.app/FastMDRenderers")
        let policy = IOSRichRendererRequestBlockingPolicy(bundledRendererRoot: rendererRoot)
        let remoteURL = try XCTUnwrap(URL(string: "https://cdn.example.com/mermaid.js"))
        let externalURL = try XCTUnwrap(URL(string: "https://example.com/out"))
        let javascriptURL = try XCTUnwrap(URL(string: "javascript:alert(1)"))
        let dataURL = try XCTUnwrap(URL(string: "data:text/html;base64,PGgxPkJsb2NrPC9oMT4="))
        let iframeURL = rendererRoot.appendingPathComponent("frame.html")

        XCTAssertTrue(
            policy.blocksAllStageOneForbiddenRequests(
                sampleRemoteURL: remoteURL,
                sampleExternalNavigationURL: externalURL,
                sampleJavaScriptURL: javascriptURL,
                sampleDataURL: dataURL,
                sampleIframeURL: iframeURL
            )
        )
        XCTAssertEqual(
            policy.decision(for: remoteURL, context: .script),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "https://cdn.example.com/mermaid.js",
                reason: .remoteSubresource
            )
        )
        XCTAssertEqual(
            policy.decision(for: externalURL, context: .externalNavigation),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "https://example.com/out",
                reason: .externalNavigation
            )
        )
        XCTAssertEqual(
            policy.decision(for: javascriptURL, context: .mainDocument),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "javascript:alert(1)",
                reason: .dangerousScheme
            )
        )
        XCTAssertEqual(
            policy.decision(for: dataURL, context: .image),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "data:text/html;base64,PGgxPkJsb2NrPC9oMT4=",
                reason: .dangerousScheme
            )
        )
        XCTAssertEqual(
            policy.decision(for: iframeURL, context: .iframe),
            IOSRichRendererRequestDecision(
                kind: .blocked,
                normalizedURLString: "file:///App/FastMD.app/FastMDRenderers/frame.html",
                reason: .iframe
            )
        )
    }

    func testIOSDocumentEntryCoordinatorRoutesLauncherAndDocumentPicker() throws {
        let coordinator = IOSDocumentEntryCoordinator()
        let documentURL = URL(fileURLWithPath: "/tmp/notes.markdown")

        XCTAssertEqual(
            try coordinator.action(for: IOSDocumentEntryRequest(entryPoint: .launcher)),
            .showLauncher
        )
        XCTAssertEqual(
            try coordinator.action(
                for: IOSDocumentEntryRequest(
                    entryPoint: .documentPicker,
                    url: documentURL,
                    isUserSelected: true
                )
            ),
            .openDocumentURL(documentURL, origin: .documentPicker, persistBookmark: true)
        )
    }

    func testIOSDocumentEntryCoordinatorRoutesFilesAndShareDocumentURLsWithoutBookmarks() throws {
        let coordinator = IOSDocumentEntryCoordinator()
        let filesURL = URL(fileURLWithPath: "/tmp/from-files.md")
        let sharedURL = URL(fileURLWithPath: "/tmp/shared.mkd")

        XCTAssertEqual(
            try coordinator.action(
                for: IOSDocumentEntryRequest(entryPoint: .filesAppOpen, url: filesURL)
            ),
            .openDocumentURL(filesURL, origin: .filesAppOpen, persistBookmark: false)
        )
        XCTAssertEqual(
            try coordinator.action(
                for: IOSDocumentEntryRequest(entryPoint: .shareDocumentURL, url: sharedURL)
            ),
            .openDocumentURL(sharedURL, origin: .shareDocumentURL, persistBookmark: false)
        )
    }

    func testIOSDocumentEntryCoordinatorRejectsUnsupportedDocumentURL() {
        let coordinator = IOSDocumentEntryCoordinator()
        let unsupportedURL = URL(fileURLWithPath: "/tmp/image.png")

        XCTAssertThrowsError(
            try coordinator.action(
                for: IOSDocumentEntryRequest(entryPoint: .documentPicker, url: unsupportedURL)
            )
        ) { error in
            XCTAssertEqual(error as? IOSDocumentEntryError, .unsupportedDocumentType)
        }
    }

    func testIOSShareTextEntryProducesTemporaryReadOnlyLoadResult() throws {
        let coordinator = IOSDocumentEntryCoordinator()
        let loadedAt = Date(timeIntervalSince1970: 1_777_800_000)

        let result = try coordinator.makeTemporarySharedTextLoadResult(
            text: "  # Shared\r\n\r\nBody\n  ",
            displayName: "Shared Note",
            loadedAt: loadedAt
        )

        XCTAssertEqual(result.handle.displayName, "Shared Note")
        XCTAssertEqual(result.handle.origin, .shareText)
        XCTAssertEqual(result.handle.access, .readOnly)
        XCTAssertNil(result.handle.bookmarkData)
        XCTAssertEqual(result.metadata.displayName, "Shared Note")
        XCTAssertEqual(result.metadata.byteCount, result.source.utf8.count)
        XCTAssertEqual(result.source, "# Shared\r\n\r\nBody")
        XCTAssertEqual(result.lineEnding, .crlf)
        XCTAssertEqual(result.loadedAt, loadedAt)
    }

    func testIOSShareTextEntryRejectsEmptyText() {
        let coordinator = IOSDocumentEntryCoordinator()

        XCTAssertThrowsError(
            try coordinator.action(
                for: IOSDocumentEntryRequest(entryPoint: .shareText, sharedText: " \n\t ")
            )
        ) { error in
            XCTAssertEqual(error as? IOSDocumentEntryError, .emptySharedText)
        }
    }

    func testIOSRecentDocumentStoreKeepsBookmarkMetadataWithoutDocumentContent() throws {
        var store = IOSRecentDocumentStore()
        let openedAt = Date(timeIntervalSince1970: 1_777_800_100)
        let url = URL(fileURLWithPath: "/tmp/secret-note.md")

        try store.upsertUserSelectedDocument(
            url: url,
            bookmarkData: Data([0xF0, 0x0D]),
            contentTypeIdentifier: "net.daringfireball.markdown",
            openedAt: openedAt,
            byteCount: 4096
        )

        let record = try XCTUnwrap(store.record(identifier: "ios:bookmark:/tmp/secret-note.md"))

        XCTAssertEqual(record.displayName, "secret-note.md")
        XCTAssertEqual(record.bookmarkData, Data([0xF0, 0x0D]))
        XCTAssertEqual(record.contentTypeIdentifier, "net.daringfireball.markdown")
        XCTAssertEqual(record.lastOpenedAt, openedAt)
        XCTAssertEqual(record.byteCount, 4096)
        XCTAssertEqual(record.handle.origin, .recentBookmark)
        XCTAssertEqual(record.handle.bookmarkData, Data([0xF0, 0x0D]))
        XCTAssertFalse(String(describing: record).contains("# Secret"))
    }

    func testIOSRecentDocumentStoreRequiresBookmarkData() {
        var store = IOSRecentDocumentStore()

        XCTAssertThrowsError(
            try store.upsertUserSelectedDocument(
                url: URL(fileURLWithPath: "/tmp/note.md"),
                bookmarkData: Data(),
                contentTypeIdentifier: nil
            )
        ) { error in
            XCTAssertEqual(error as? IOSDocumentEntryError, .bookmarkCreationFailed)
        }
    }

    func testIOSBookmarkResolverMapsStaleBookmarksToPermissionLost() {
        let record = IOSRecentDocumentRecord(
            identifier: "ios:bookmark:/tmp/stale.md",
            displayName: "stale.md",
            bookmarkData: Data([0x01]),
            contentTypeIdentifier: "net.daringfireball.markdown",
            lastOpenedAt: Date(timeIntervalSince1970: 1_777_800_200)
        )
        let resolver = IOSBookmarkResolver()
        let resolvedURL = URL(fileURLWithPath: "/tmp/stale.md")

        XCTAssertEqual(
            resolver.resolve(record: record, resolvedURL: resolvedURL, isStale: false),
            .resolved(resolvedURL, handle: record.handle)
        )
        XCTAssertEqual(
            resolver.resolve(record: record, resolvedURL: resolvedURL, isStale: true),
            .permissionLost
        )
        XCTAssertEqual(
            resolver.resolve(record: record, resolvedURL: nil, isStale: false),
            .permissionLost
        )
    }

    func testIOSSecurityScopedAccessBalancesStartAndStopAroundOperation() throws {
        let url = URL(fileURLWithPath: "/tmp/non-security-scoped.md")
        var observedAccess: IOSSecurityScopedAccess?

        let value = IOSSecurityScopedAccess.withAccess(to: url) { access in
            observedAccess = access
            return "loaded"
        }

        XCTAssertEqual(value, "loaded")
        XCTAssertEqual(observedAccess?.url, url)
        XCTAssertNotNil(observedAccess?.didStartAccessing)
    }

    func testIOSDocumentFileIOLoadsMarkdownThroughSecurityScopedAccess() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("loaded.md")
        try Data([0xEF, 0xBB, 0xBF] + Array("# Loaded\r\n\r\nBody".utf8)).write(to: url)

        let loadedAt = Date(timeIntervalSince1970: 1_777_800_300)
        let result = try IOSDocumentFileIO().loadDocument(
            at: url,
            origin: .documentPicker,
            access: .readWrite,
            bookmarkData: Data([0xAB]),
            loadedAt: loadedAt
        )

        XCTAssertEqual(result.handle.identifier, "ios:url:\(url.path)")
        XCTAssertEqual(result.handle.displayName, "loaded.md")
        XCTAssertEqual(result.handle.origin, .documentPicker)
        XCTAssertEqual(result.handle.access, .readWrite)
        XCTAssertEqual(result.handle.bookmarkData, Data([0xAB]))
        XCTAssertEqual(result.metadata.displayName, "loaded.md")
        XCTAssertEqual(result.metadata.byteCount, 19)
        XCTAssertEqual(result.source, "# Loaded\r\n\r\nBody")
        XCTAssertEqual(result.encoding, .utf8WithBOM)
        XCTAssertEqual(result.lineEnding, .crlf)
        XCTAssertEqual(result.loadedAt, loadedAt)
    }

    func testIOSDocumentFileIOLoadsMarkdownOffMainActor() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("background-load.md")
        try "# Background\n\nLoad".data(using: .utf8)?.write(to: url)

        let result = try await IOSDocumentFileIO().loadDocumentOffMainActor(
            at: url,
            origin: .documentPicker
        )

        XCTAssertEqual(result.value.source, "# Background\n\nLoad")
        XCTAssertEqual(result.value.handle.origin, .documentPicker)
        XCTAssertTrue(result.execution.scheduledWithDetachedTask)
        XCTAssertTrue(result.execution.stayedOffMainThread)
    }

    func testIOSDocumentFileIOSavesMarkdownThroughSecurityScopedAccess() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("saved.md")

        try IOSDocumentFileIO().saveDocument(source: "# Saved\n\nBody", to: url)

        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "# Saved\n\nBody")
    }

    func testIOSDocumentSavePlannerPreservesBOMAndCRLFWithoutDuplicateBOM() throws {
        let loadResult = makeLoadedDocument(
            displayName: "bom-crlf.md",
            source: "# Original\r\n\r\nBody",
            encoding: .utf8WithBOM,
            lineEnding: .crlf
        )

        let plan = try IOSDocumentSavePlanner().makePlan(
            editedSource: "\u{FEFF}# Changed\n\nBody",
            for: loadResult
        )

        XCTAssertTrue(plan.writesCompleteOutput)
        XCTAssertEqual(plan.encoding, .utf8WithBOM)
        XCTAssertEqual(plan.lineEnding, .crlf)
        XCTAssertEqual(plan.normalizedSource, "# Changed\r\n\r\nBody")
        XCTAssertEqual(
            plan.completeOutput,
            Data([0xEF, 0xBB, 0xBF] + Array("# Changed\r\n\r\nBody".utf8))
        )
        XCTAssertFalse(plan.completeOutput.dropFirst(3).starts(with: [0xEF, 0xBB, 0xBF]))
    }

    func testIOSDocumentSavePlannerFailsClosedForReadOnlyAndUnsupportedEncoding() {
        let readOnly = makeLoadedDocument(
            displayName: "readonly.md",
            source: "# Readonly",
            access: .readOnly
        )
        let unsupported = makeLoadedDocument(
            displayName: "legacy.md",
            source: "# Legacy",
            encoding: .unsupported
        )
        let planner = IOSDocumentSavePlanner()

        XCTAssertThrowsError(
            try planner.makePlan(editedSource: "# Changed", for: readOnly)
        ) { error in
            XCTAssertEqual(error as? IOSDocumentSaveError, .readOnlyDocument)
        }

        XCTAssertThrowsError(
            try planner.makePlan(editedSource: "# Changed", for: unsupported)
        ) { error in
            XCTAssertEqual(error as? IOSDocumentSaveError, .unsupportedEncoding)
        }
    }

    func testIOSDocumentFileIOSaveUsesCompleteOutputWithPreservedEncodingAndLineEnding() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("preserved.md")
        let loadResult = makeLoadedDocument(
            displayName: "preserved.md",
            source: "# Original\r\n\r\nBody",
            encoding: .utf8WithBOM,
            lineEnding: .crlf
        )
        try Data([0xEF, 0xBB, 0xBF] + Array("# Original\r\n\r\nBody".utf8)).write(to: url)

        let result = try IOSDocumentFileIO().saveDocument(
            editedSource: "# Saved\n\nBody",
            for: loadResult,
            to: url
        )

        XCTAssertEqual(
            try Data(contentsOf: url),
            Data([0xEF, 0xBB, 0xBF] + Array("# Saved\r\n\r\nBody".utf8))
        )
        XCTAssertEqual(result.savedSource, "# Saved\r\n\r\nBody")
        XCTAssertEqual(result.encoding, .utf8WithBOM)
        XCTAssertEqual(result.lineEnding, .crlf)
        XCTAssertEqual(result.byteCount, 18)
        XCTAssertNil(result.retainedDirtyBufferAfterFailure)
    }

    func testIOSDocumentFileIOSavesMarkdownOffMainActor() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("background-save.md")
        let loadResult = makeLoadedDocument(
            displayName: "background-save.md",
            source: "# Original\n\nBody"
        )
        try "# Original\n\nBody".data(using: .utf8)?.write(to: url)

        let result = try await IOSDocumentFileIO().saveDocumentOffMainActor(
            editedSource: "# Saved\n\nBody",
            for: loadResult,
            to: url
        )

        XCTAssertEqual(result.value.savedSource, "# Saved\n\nBody")
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "# Saved\n\nBody")
        XCTAssertTrue(result.execution.scheduledWithDetachedTask)
        XCTAssertTrue(result.execution.stayedOffMainThread)
    }

    func testIOSDocumentFileIOSaveDetectsExternalMutationBeforeWrite() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("external-change.md")
        let loadResult = makeLoadedDocument(
            displayName: "external-change.md",
            source: "# Original\n\nBody"
        )
        try "# Changed elsewhere\n\nBody".data(using: .utf8)?.write(to: url)

        XCTAssertThrowsError(
            try IOSDocumentFileIO().saveDocument(
                editedSource: "# User edit\n\nBody",
                for: loadResult,
                to: url
            )
        ) { error in
            XCTAssertEqual(
                error as? IOSDocumentSaveError,
                .externalMutation(retainedDirtyBuffer: "# User edit\n\nBody")
            )
        }
        XCTAssertEqual(
            try String(contentsOf: url, encoding: .utf8),
            "# Changed elsewhere\n\nBody"
        )
    }

    func testIOSValidationTargetDefaultsToStageOneDeviceAndOS() {
        let target = IOSValidationTarget()

        XCTAssertEqual(target.iPhone12, "iPhone 12 / 12 mini / 12 Pro / 12 Pro Max")
        XCTAssertEqual(target.iOS141, "iOS 14.1")
    }

    func testNativeRendererPresentsHeadingLevelsOneThroughSix() {
        let source = """
        # H1
        ## H2
        ### H3
        #### H4
        ##### H5
        ###### H6
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)

        XCTAssertEqual(rendered.map(\.role), Array(repeating: .heading, count: 6))
        XCTAssertEqual(rendered.map(\.headingLevel), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(rendered.map(\.plainText), ["H1", "H2", "H3", "H4", "H5", "H6"])
        XCTAssertEqual(rendered.map(\.sourceRange), document.blocks.map(\.sourceRange))
    }

    func testNativeRendererPresentsParagraphsAndInlineStyles() throws {
        let source = """
        普通段落可以混合 **粗体**、*斜体*、***粗斜体***、~~删除线~~、`inline code`、<mark>高亮</mark>、<sub>下标</sub>、<sup>上标</sup>。
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = try XCTUnwrap(
            MarkdownNativeRenderer().render(document: document, source: source).first
        )

        XCTAssertEqual(rendered.role, .paragraph)
        XCTAssertEqual(rendered.plainText, "普通段落可以混合 粗体、斜体、粗斜体、删除线、inline code、高亮、下标、上标。")
        XCTAssertTrue(rendered.inlineRuns.contains { $0.text == "粗体" && $0.styles.contains(.bold) })
        XCTAssertTrue(rendered.inlineRuns.contains { $0.text == "斜体" && $0.styles.contains(.italic) })
        XCTAssertTrue(
            rendered.inlineRuns.contains {
                $0.text == "粗斜体"
                    && $0.styles.contains(.bold)
                    && $0.styles.contains(.italic)
            }
        )
        XCTAssertTrue(rendered.inlineRuns.contains { $0.text == "删除线" && $0.styles.contains(.strikethrough) })
        XCTAssertTrue(rendered.inlineRuns.contains { $0.text == "inline code" && $0.styles.contains(.inlineCode) })
        XCTAssertTrue(rendered.inlineRuns.contains { $0.text == "高亮" && $0.styles.contains(.highlight) })
        XCTAssertTrue(rendered.inlineRuns.contains { $0.text == "下标" && $0.styles.contains(.subscriptText) })
        XCTAssertTrue(rendered.inlineRuns.contains { $0.text == "上标" && $0.styles.contains(.superscriptText) })
    }

    func testNativeRendererRoutesMarkdownLinksAutolinksAndEmailThroughLinkPolicy() throws {
        let source = """
        Links: [OpenAI](https://openai.com), <https://github.com>, <hello@example.com>, [bad](javascript:alert(1)).
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = try XCTUnwrap(
            MarkdownNativeRenderer().render(document: document, source: source).first
        )

        let openAI = try XCTUnwrap(rendered.inlineRuns.first { $0.text == "OpenAI" })
        XCTAssertEqual(openAI.linkDecision?.kind, .confirm)
        XCTAssertEqual(openAI.linkDecision?.normalizedURLString, "https://openai.com")

        let github = try XCTUnwrap(rendered.inlineRuns.first { $0.text == "https://github.com" })
        XCTAssertEqual(github.linkDecision?.kind, .confirm)
        XCTAssertEqual(github.linkDecision?.normalizedURLString, "https://github.com")

        let email = try XCTUnwrap(rendered.inlineRuns.first { $0.text == "hello@example.com" })
        XCTAssertEqual(email.linkDecision?.kind, .allowed)
        XCTAssertEqual(email.linkDecision?.normalizedURLString, "mailto:hello@example.com")

        let blocked = try XCTUnwrap(rendered.inlineRuns.first { $0.text == "bad" })
        XCTAssertEqual(blocked.linkDecision?.kind, .blocked)
        XCTAssertEqual(blocked.linkDecision?.reason, .dangerousScheme)
    }

    func testNativeRendererPresentsNestedBlockquotes() throws {
        let source = """
        > Quote **one**
        >> Nested quote
        > Back to first level
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = try XCTUnwrap(
            MarkdownNativeRenderer().render(document: document, source: source).first
        )

        XCTAssertEqual(rendered.role, .blockquote)
        XCTAssertEqual(rendered.blockquoteLines.map(\.depth), [1, 2, 1])
        XCTAssertEqual(rendered.blockquoteLines.map(\.plainText), ["Quote one", "Nested quote", "Back to first level"])
        XCTAssertTrue(rendered.blockquoteLines[0].inlineRuns.contains { $0.text == "one" && $0.styles.contains(.bold) })
        XCTAssertEqual(rendered.sourceRange, document.blocks[0].sourceRange)
    }

    func testNativeRendererPresentsUnorderedOrderedAndTaskLists() throws {
        let source = """
        - Root **item**
          - Nested item

        1. First
        2. Second

        - [x] Done
        - [ ] Todo
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)

        let unordered = try XCTUnwrap(rendered.first { $0.role == .unorderedList })
        XCTAssertEqual(unordered.listItems.map(\.nestingLevel), [0, 1])
        XCTAssertEqual(unordered.listItems.map(\.marker), ["-", "-"])
        XCTAssertEqual(unordered.listItems.map(\.plainText), ["Root item", "Nested item"])
        XCTAssertTrue(unordered.listItems[0].inlineRuns.contains { $0.text == "item" && $0.styles.contains(.bold) })

        let ordered = try XCTUnwrap(rendered.first { $0.role == .orderedList })
        XCTAssertEqual(ordered.listItems.map(\.marker), ["1.", "2."])
        XCTAssertEqual(ordered.listItems.map(\.plainText), ["First", "Second"])

        let task = try XCTUnwrap(rendered.first { $0.role == .taskList })
        XCTAssertEqual(task.listItems.map(\.checked), [true, false])
        XCTAssertEqual(task.listItems.map(\.plainText), ["Done", "Todo"])
    }

    func testNativeRendererPresentsTablesAsBlockLocalHorizontalScrollPayload() throws {
        let source = """
        | Name | Value | Notes |
        | --- | ---: | --- |
        | Alpha | 1 | Long cell |
        | Beta | 2 | More |
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = try XCTUnwrap(
            MarkdownNativeRenderer().render(document: document, source: source).first
        )

        XCTAssertEqual(rendered.role, .table)
        XCTAssertEqual(rendered.table?.columnCount, 3)
        XCTAssertEqual(rendered.table?.rows, [
            ["Name", "Value", "Notes"],
            ["Alpha", "1", "Long cell"],
            ["Beta", "2", "More"]
        ])
        XCTAssertEqual(rendered.table?.scrollsHorizontallyWithinBlock, true)
        XCTAssertEqual(rendered.sourceRange, document.blocks[0].sourceRange)
    }

    func testNativeRendererPresentsCodeFencesWithCopyAndPlainFallbackHighlighting() throws {
        let source = """
        ```swift
        let value = 1
        print(value)
        ```
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = try XCTUnwrap(
            MarkdownNativeRenderer().render(document: document, source: source).first
        )

        XCTAssertEqual(rendered.role, .codeFence)
        XCTAssertEqual(rendered.codeBlock?.language, "swift")
        XCTAssertEqual(rendered.codeBlock?.code, "let value = 1\nprint(value)")
        XCTAssertEqual(rendered.codeBlock?.supportsCopyAction, true)
        XCTAssertEqual(rendered.codeBlock?.highlighting, .plainFallback)
        XCTAssertEqual(rendered.codeBlock?.scrollsHorizontallyWithinBlock, true)
        XCTAssertEqual(rendered.plainText, "let value = 1\nprint(value)")
    }

    func testNativeRendererPresentsMermaidAndBlockMathAsSafeNativeCards() throws {
        let source = """
        ```mermaid
        flowchart TD
            A --> B
        ```

        $$
        E = mc^2
        $$
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)

        let mermaid = try XCTUnwrap(rendered.first { $0.richFallback?.kind == .mermaidDiagramSource })
        XCTAssertEqual(mermaid.role, .richFallback)
        XCTAssertEqual(mermaid.richFallback?.title, "Mermaid diagram source")
        XCTAssertEqual(mermaid.richFallback?.source, "flowchart TD\n    A --> B")
        XCTAssertEqual(mermaid.richFallback?.surface, .nativeSafeCard)
        XCTAssertEqual(mermaid.richFallback?.rendersAsNativeSafeCard, true)
        XCTAssertEqual(mermaid.richFallback?.requiresVendoredRendererAssets, false)
        XCTAssertEqual(mermaid.richFallback?.allowsNetworkRequests, false)
        XCTAssertEqual(mermaid.richFallback?.allowsExternalNavigation, false)
        XCTAssertEqual(mermaid.richFallback?.allowsRemoteSubresources, false)

        let math = try XCTUnwrap(rendered.first { $0.richFallback?.kind == .blockMath })
        XCTAssertEqual(math.role, .richFallback)
        XCTAssertEqual(math.richFallback?.title, "Math formula")
        XCTAssertEqual(math.richFallback?.source, "E = mc^2")
        XCTAssertEqual(math.richFallback?.surface, .nativeSafeCard)
        XCTAssertEqual(math.richFallback?.requiresVendoredRendererAssets, false)
        XCTAssertEqual(math.richFallback?.allowsNetworkRequests, false)
        XCTAssertEqual(math.richFallback?.allowsExternalNavigation, false)
        XCTAssertEqual(math.richFallback?.allowsRemoteSubresources, false)
    }

    func testNativeRendererPresentsInlineMathAsReadableNativeFallback() throws {
        let source = "Inline math $a^2 + b^2 = c^2$ stays readable."
        let document = MarkdownParserAdapter().parse(source)
        let rendered = try XCTUnwrap(
            MarkdownNativeRenderer().render(document: document, source: source).first
        )

        XCTAssertEqual(rendered.role, .paragraph)
        XCTAssertEqual(rendered.plainText, "Inline math a^2 + b^2 = c^2 stays readable.")
        XCTAssertTrue(
            rendered.inlineRuns.contains {
                $0.text == "a^2 + b^2 = c^2" && $0.styles.contains(.inlineMath)
            }
        )
    }

    func testNativeRendererPresentsLocalAndRemoteImagesWithPrivacyPolicy() throws {
        let source = """
        ![Local Diagram](assets/diagram.png)

        ![Remote Diagram](https://example.com/remote.png)
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)

        let local = try XCTUnwrap(rendered.first { $0.image?.altText == "Local Diagram" })
        XCTAssertEqual(local.role, .image)
        XCTAssertEqual(local.image?.source, "assets/diagram.png")
        XCTAssertEqual(local.image?.isRemote, false)
        XCTAssertEqual(local.image?.loadsAutomatically, true)
        XCTAssertEqual(local.image?.requiresBoundedLocalDecode, true)
        XCTAssertEqual(local.image?.downsamplePolicy?.implementation, .imageIO)
        XCTAssertTrue(local.image?.downsamplePolicy?.satisfiesStageOneLocalImageRule == true)
        XCTAssertEqual(local.image?.requiresManualOpenAction, false)
        XCTAssertEqual(local.image?.linkDecision.kind, .allowed)

        let remote = try XCTUnwrap(rendered.first { $0.image?.altText == "Remote Diagram" })
        XCTAssertEqual(remote.image?.source, "https://example.com/remote.png")
        XCTAssertEqual(remote.image?.isRemote, true)
        XCTAssertEqual(remote.image?.loadsAutomatically, false)
        XCTAssertEqual(remote.image?.requiresBoundedLocalDecode, false)
        XCTAssertNil(remote.image?.downsamplePolicy)
        XCTAssertEqual(remote.image?.requiresManualOpenAction, true)
        XCTAssertEqual(remote.image?.linkDecision.kind, .blocked)
        XCTAssertEqual(remote.image?.linkDecision.reason, .remoteResourceDisabled)
    }

    func testNativeRendererPresentsHorizontalRuleFootnoteAndEscapedMarkers() throws {
        let source = """
        \\*not italic\\* and \\[not link\\](target)

        ---

        [^note]: Footnote **content**.
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)

        let paragraph = try XCTUnwrap(rendered.first { $0.role == .paragraph })
        XCTAssertEqual(paragraph.plainText, "*not italic* and [not link](target)")
        XCTAssertFalse(paragraph.inlineRuns.contains { $0.styles.contains(.italic) })
        XCTAssertFalse(paragraph.inlineRuns.contains { $0.linkDecision != nil })

        let rule = try XCTUnwrap(rendered.first { $0.role == .horizontalRule })
        XCTAssertTrue(rule.inlineRuns.isEmpty)

        let footnote = try XCTUnwrap(rendered.first { $0.role == .footnote })
        XCTAssertEqual(footnote.plainText, "Footnote content.")
        XCTAssertTrue(footnote.inlineRuns.contains { $0.text == "content" && $0.styles.contains(.bold) })
    }

    func testNativeRendererPresentsVideoDetailsAndGenericHTMLAsSanitizedFallbacks() throws {
        let source = """
        <video controls>
          <source src="https://example.com/video.mp4" type="video/mp4">
        </video>

        <details open>
          <summary>More</summary>
          <p>Hidden <strong>body</strong></p>
        </details>

        <div onclick="alert(1)">Raw <script>alert(1)</script> HTML</div>
        """

        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)

        let video = try XCTUnwrap(rendered.first { $0.htmlFallback?.kind == .videoPlaceholder })
        XCTAssertEqual(video.role, .htmlFallback)
        XCTAssertEqual(video.htmlFallback?.blocksExternalNavigation, true)
        XCTAssertEqual(video.htmlFallback?.blocksRemoteSubresources, true)
        XCTAssertTrue(video.htmlFallback?.sanitizedText.contains("alert") == false)

        let details = try XCTUnwrap(rendered.first { $0.htmlFallback?.kind == .detailsDisclosure })
        XCTAssertEqual(details.htmlFallback?.summary, "More")
        XCTAssertTrue(details.htmlFallback?.sanitizedText.contains("Hidden body") == true)

        let generic = try XCTUnwrap(rendered.last { $0.htmlFallback?.kind == .genericSanitizedText })
        XCTAssertEqual(generic.role, .htmlFallback)
        XCTAssertTrue(generic.htmlFallback?.sanitizedText.contains("Raw") == true)
        XCTAssertTrue(generic.htmlFallback?.blocksExternalNavigation == true)
        XCTAssertTrue(generic.htmlFallback?.blocksRemoteSubresources == true)
    }

    func testNativeRendererCoversCanonicalRichFixtureHeadingAndInlineParagraphSurface() throws {
        let fixtureURL = Self.packageRoot
            .appendingPathComponent("Tests")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Markdown")
            .appendingPathComponent("rich-preview.md")
        let source = try String(contentsOf: fixtureURL, encoding: .utf8)
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)

        XCTAssertEqual(
            Set(rendered.compactMap(\.headingLevel)),
            Set([1, 2, 3, 4, 5, 6])
        )
        XCTAssertTrue(
            rendered.contains {
                $0.role == .paragraph
                    && $0.plainText.contains("普通段落可以混合 粗体、斜体、粗斜体")
                    && $0.inlineRuns.contains { $0.text == "粗体" && $0.styles.contains(.bold) }
                    && $0.inlineRuns.contains { $0.text == "inline code" && $0.styles.contains(.inlineCode) }
                    && $0.inlineRuns.contains { $0.text == "高亮" && $0.styles.contains(.highlight) }
            }
        )
    }

    func testCanonicalMarkdownFixtureMatrixExistsAndIsSeeded() throws {
        let fixtureDirectory = Self.packageRoot
            .appendingPathComponent("Tests")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Markdown")

        var isDirectory: ObjCBool = false
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: fixtureDirectory.path, isDirectory: &isDirectory),
            "Expected iOS Markdown fixture directory at \(fixtureDirectory.path)"
        )
        XCTAssertTrue(isDirectory.boolValue)

        for fixtureName in Self.canonicalMarkdownFixtureNames {
            let fixtureURL = fixtureDirectory.appendingPathComponent(fixtureName)
            let attributes = try FileManager.default.attributesOfItem(atPath: fixtureURL.path)
            let fileSize = try XCTUnwrap(attributes[.size] as? NSNumber)

            XCTAssertGreaterThan(
                fileSize.intValue,
                0,
                "\(fixtureName) should be present and non-empty"
            )
        }
    }

    func testRichPreviewFixtureMatchesSharedCanonicalFixture() throws {
        let iosFixtureURL = Self.packageRoot
            .appendingPathComponent("Tests")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Markdown")
            .appendingPathComponent("rich-preview.md")
        let sharedFixtureURL = Self.packageRoot
            .deletingLastPathComponent()
            .appendingPathComponent("Tests")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Markdown")
            .appendingPathComponent("rich-preview.md")

        XCTAssertEqual(
            try Data(contentsOf: iosFixtureURL),
            try Data(contentsOf: sharedFixtureURL),
            "iOS rich-preview.md should remain a platform-local copy of the shared canonical fixture"
        )
    }

    func testIOSReaderScreenEmptyStateCarriesOpenActionAndRecentDocuments() {
        let openedAt = Date(timeIntervalSince1970: 1_777_801_000)
        let recent = IOSRecentDocumentSummary(
            identifier: "ios:bookmark:/tmp/recent.md",
            displayName: "recent.md",
            contentTypeIdentifier: "net.daringfireball.markdown",
            byteCount: 512,
            lastOpenedAt: openedAt
        )

        let state = IOSReaderScreenEngine().emptyState(
            recentDocuments: [recent],
            selectedFontTier: .large
        )

        XCTAssertEqual(state.readerState, .empty)
        XCTAssertTrue(state.isEmpty)
        XCTAssertEqual(state.title, "FastMD")
        XCTAssertEqual(state.subtitle, "Recent documents")
        XCTAssertEqual(state.selectedFontTier, .large)
        XCTAssertEqual(state.recentDocuments, [recent])
        XCTAssertTrue(state.isOpenActionAvailable)
        XCTAssertFalse(state.isSearchAvailable)
        XCTAssertFalse(state.isProgressVisible)
        XCTAssertTrue(state.renderedBlocks.isEmpty)
    }

    func testIOSReaderScreenEngineEmitsNonBlockingLoadRenderReadyStates() async {
        let loadedAt = Date(timeIntervalSince1970: 1_777_801_100)
        let handle = MobileDocumentHandle(
            identifier: "ios:url:/tmp/note.md",
            displayName: "note.md",
            origin: .documentPicker,
            access: .readWrite
        )
        let metadata = MobileFileMetadata(
            displayName: "note.md",
            byteCount: 25,
            contentTypeIdentifier: "net.daringfireball.markdown"
        )
        let loadResult = MarkdownLoadResult(
            handle: handle,
            metadata: metadata,
            source: "# Title\n\nBody with **bold**",
            encoding: .utf8,
            lineEnding: .lf,
            loadedAt: loadedAt
        )

        let states = await IOSReaderScreenEngine().renderLoadedDocumentStates(
            loadResult,
            selectedFontTier: .reader
        )

        XCTAssertEqual(states.map(\.readerState), [.loading, .rendering, .ready])
        XCTAssertEqual(states[0].progress?.title, "Opening")
        XCTAssertEqual(states[1].progress?.title, "Rendering")
        XCTAssertTrue(states[0].isProgressVisible)
        XCTAssertTrue(states[1].isProgressVisible)

        let ready = states[2]
        XCTAssertEqual(ready.title, "note.md")
        XCTAssertEqual(ready.subtitle, "Writable · 25 bytes")
        XCTAssertEqual(ready.selectedFontTier, .reader)
        XCTAssertTrue(ready.isReadyForReading)
        XCTAssertTrue(ready.isSearchAvailable)
        XCTAssertEqual(ready.renderedBlocks.map(\.role), [.heading, .paragraph])
        XCTAssertEqual(ready.renderedBlocks.first?.plainText, "Title")
        XCTAssertTrue(
            ready.renderedBlocks[1].inlineRuns.contains {
                $0.text == "bold" && $0.styles.contains(.bold)
            }
        )
    }

    func testIOSReaderScreenEngineParsesAndRendersOffMainActor() async {
        let loadResult = makeReaderLoadResult(
            displayName: "background-render.md",
            source: "# Title\n\nBody with **bold**\n\n- Item"
        )

        let result = await IOSReaderScreenEngine().renderDocumentOffMainActor(loadResult)

        XCTAssertEqual(result.document.blocks.map(\.kind), [.heading, .paragraph, .unorderedList])
        XCTAssertEqual(result.renderedBlocks.map(\.role), [.heading, .paragraph, .unorderedList])
        XCTAssertEqual(result.renderedBlocks[0].plainText, "Title")
        XCTAssertTrue(result.execution.scheduledWithDetachedTask)
        XCTAssertTrue(result.execution.stayedOffMainThread)
    }

    func testIOSReaderScreenEngineSearchesOffMainActor() async {
        let loadResult = makeReaderLoadResult(
            displayName: "background-search.md",
            source: "# Alpha\n\nAlpha beta alpha"
        )
        let engine = IOSReaderScreenEngine()
        let rendered = await engine.renderDocumentOffMainActor(loadResult)
        let ready = engine.readyState(
            loadResult: loadResult,
            renderedBlocks: rendered.renderedBlocks
        )

        let result = await engine.searchingStateOffMainActor(from: ready, query: "alpha")

        XCTAssertEqual(result.value.readerState, .searching)
        XCTAssertEqual(result.value.searchState?.resultCount, 3)
        XCTAssertEqual(result.value.searchState?.matches.map(\.blockOrdinal), [0, 1, 1])
        XCTAssertEqual(result.value.renderedBlocks, ready.renderedBlocks)
        XCTAssertTrue(result.execution.scheduledWithDetachedTask)
        XCTAssertTrue(result.execution.stayedOffMainThread)
    }

    func testIOSReaderLazyRenderingPolicyMatchesSwiftUILazyVStackContract() {
        let policy = IOSReaderScreenEngine().lazyRenderingPolicy

        XCTAssertEqual(policy.containerName, "LazyVStack")
        XCTAssertEqual(policy.stableIdentityKey, "MarkdownBlockID")
        XCTAssertEqual(policy.maxContentWidth, 760)
        XCTAssertTrue(policy.rendersOnlyVisibleBlocksInitially)
        XCTAssertTrue(policy.horizontalOverflowContainedRoles.isSuperset(of: [.table, .codeFence]))
        XCTAssertTrue(policy.satisfiesStageOneLazyBlockRendering)
    }

    func testIOSReaderReadyStateUsesReadOnlyModeForNonWritableDocuments() {
        let handle = MobileDocumentHandle(
            identifier: "ios:share-text:temporary",
            displayName: "Shared Markdown",
            origin: .shareText,
            access: .readOnly
        )
        let metadata = MobileFileMetadata(
            displayName: "Shared Markdown",
            byteCount: 14,
            contentTypeIdentifier: "net.daringfireball.markdown"
        )
        let loadResult = MarkdownLoadResult(
            handle: handle,
            metadata: metadata,
            source: "# Shared",
            encoding: .utf8,
            lineEnding: .none,
            loadedAt: Date(timeIntervalSince1970: 1_777_801_200)
        )
        let document = MarkdownParserAdapter().parse(loadResult.source)
        let blocks = MarkdownNativeRenderer().render(document: document, source: loadResult.source)

        let state = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: blocks
        )

        XCTAssertEqual(state.readerState, .readOnly)
        XCTAssertTrue(state.isReadyForReading)
        XCTAssertEqual(state.subtitle, "Read-only · 14 bytes")
        XCTAssertTrue(state.isOpenActionAvailable)
        XCTAssertTrue(state.isSearchAvailable)
    }

    func testIOSReaderPreferencesPersistFontTierAndThemeScheme() throws {
        let suiteName = "FastMDMobileCoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = IOSReaderPreferencesStore()
        XCTAssertEqual(store.load(from: defaults), IOSReaderPreferences())

        store.save(
            IOSReaderPreferences(fontTier: .reader, themeScheme: .dark),
            to: defaults
        )

        XCTAssertEqual(
            store.load(from: defaults),
            IOSReaderPreferences(fontTier: .reader, themeScheme: .dark)
        )

        store.saveFontTier(.compact, to: defaults)
        store.saveThemeScheme(.light, to: defaults)
        XCTAssertEqual(
            store.load(from: defaults),
            IOSReaderPreferences(fontTier: .compact, themeScheme: .light)
        )
    }

    func testNativeMarkdownTypographyMapsEveryTextSurfaceAcrossFourFontTiers() {
        for tier in MobileFontTier.allCases {
            let typography = NativeMarkdownTypography(fontTier: tier)

            for surface in NativeMarkdownTextSurface.allCases {
                let metrics = typography.metrics(for: surface)
                XCTAssertGreaterThan(metrics.pointSize, 0)
                XCTAssertEqual(metrics.lineHeightMultiple, tier.lineHeightMultiple)
            }

            XCTAssertEqual(typography.metrics(for: .paragraph).pointSize, tier.bodyPointSize)
            XCTAssertEqual(typography.metrics(for: .blockquote).pointSize, tier.bodyPointSize)
            XCTAssertEqual(typography.metrics(for: .listItem).pointSize, tier.bodyPointSize)
            XCTAssertEqual(typography.metrics(for: .tableCell).pointSize, tier.bodyPointSize)
            XCTAssertEqual(typography.metrics(for: .richFallback).pointSize, tier.bodyPointSize)
            XCTAssertEqual(typography.metrics(for: .imageFallback).pointSize, tier.bodyPointSize)
            XCTAssertEqual(typography.metrics(for: .footnote).pointSize, tier.bodyPointSize)
            XCTAssertEqual(typography.metrics(for: .htmlFallback).pointSize, tier.bodyPointSize)
            XCTAssertEqual(typography.metrics(for: .code).pointSize, tier.monospacePointSize)
            XCTAssertTrue(typography.metrics(for: .code).usesMonospace)
            XCTAssertTrue(typography.metrics(for: .heading1).isHeader)
            XCTAssertGreaterThan(
                typography.metrics(for: .heading1).pointSize,
                typography.metrics(for: .heading6).pointSize
            )
        }
    }

    func testNativeMarkdownTypographyMapsRenderedBlocksToTextSurfaces() {
        let range = MarkdownSourceRange(
            startUTF8Offset: 0,
            endUTF8Offset: 1,
            startLine: 1,
            endLine: 1
        )
        let typography = NativeMarkdownTypography(fontTier: .default)

        func block(
            role: NativeMarkdownBlockRole,
            headingLevel: Int? = nil
        ) -> NativeMarkdownBlockPresentation {
            NativeMarkdownBlockPresentation(
                id: MarkdownBlockID(
                    kind: .paragraph,
                    sourceRange: range,
                    ordinal: role.rawValue.hashValue
                ),
                role: role,
                sourceRange: range,
                headingLevel: headingLevel,
                inlineRuns: [NativeMarkdownInlineRun(text: role.rawValue)]
            )
        }

        XCTAssertEqual(typography.surface(for: block(role: .heading, headingLevel: 3)), .heading3)
        XCTAssertEqual(typography.surface(for: block(role: .paragraph)), .paragraph)
        XCTAssertEqual(typography.surface(for: block(role: .blockquote)), .blockquote)
        XCTAssertEqual(typography.surface(for: block(role: .unorderedList)), .listItem)
        XCTAssertEqual(typography.surface(for: block(role: .orderedList)), .listItem)
        XCTAssertEqual(typography.surface(for: block(role: .taskList)), .listItem)
        XCTAssertEqual(typography.surface(for: block(role: .table)), .tableCell)
        XCTAssertEqual(typography.surface(for: block(role: .codeFence)), .code)
        XCTAssertEqual(typography.surface(for: block(role: .richFallback)), .richFallback)
        XCTAssertEqual(typography.surface(for: block(role: .image)), .imageFallback)
        XCTAssertEqual(typography.surface(for: block(role: .footnote)), .footnote)
        XCTAssertEqual(typography.surface(for: block(role: .htmlFallback)), .htmlFallback)
        XCTAssertNil(typography.surface(for: block(role: .horizontalRule)))
    }

    func testIOSReaderThemeTokensCoverLightAndDarkSchemes() {
        let light = IOSReaderSemanticColorTokens.tokens(for: .light)
        let dark = IOSReaderSemanticColorTokens.tokens(for: .dark)

        XCTAssertNotEqual(light, dark)
        XCTAssertTrue(light.background.hasSuffix(".light"))
        XCTAssertTrue(dark.background.hasSuffix(".dark"))

        for tokens in [light, dark] {
            XCTAssertFalse(tokens.background.isEmpty)
            XCTAssertFalse(tokens.primaryText.isEmpty)
            XCTAssertFalse(tokens.secondaryText.isEmpty)
            XCTAssertFalse(tokens.accent.isEmpty)
            XCTAssertFalse(tokens.separator.isEmpty)
            XCTAssertFalse(tokens.blockSurface.isEmpty)
            XCTAssertFalse(tokens.quoteBar.isEmpty)
            XCTAssertFalse(tokens.warning.isEmpty)
        }
    }

    func testIOSReaderScreenStatesCarryPersistedThemePreference() async {
        let handle = MobileDocumentHandle(
            identifier: "ios:url:/tmp/themed.md",
            displayName: "themed.md",
            origin: .documentPicker,
            access: .readWrite
        )
        let loadResult = MarkdownLoadResult(
            handle: handle,
            metadata: MobileFileMetadata(displayName: "themed.md", byteCount: 8),
            source: "# Themed",
            encoding: .utf8,
            lineEnding: .none,
            loadedAt: Date(timeIntervalSince1970: 1_777_801_300)
        )

        let states = await IOSReaderScreenEngine().renderLoadedDocumentStates(
            loadResult,
            selectedFontTier: .large,
            themeScheme: .dark
        )

        XCTAssertEqual(states.map(\.selectedFontTier), [.large, .large, .large])
        XCTAssertEqual(states.map(\.themeScheme), [.dark, .dark, .dark])
    }

    func testIOSReaderSearchEngineFindsCaseInsensitiveMatchesWithRangesAndCount() {
        let source = """
        # Alpha

        Alpha beta alpha

        ```text
        alpha code
        ```
        """
        let document = MarkdownParserAdapter().parse(source)
        let blocks = MarkdownNativeRenderer().render(document: document, source: source)

        let searchState = IOSReaderSearchEngine().search(query: "alpha", in: blocks)

        XCTAssertEqual(searchState.query, "alpha")
        XCTAssertEqual(searchState.resultCount, 4)
        XCTAssertEqual(searchState.selectedMatchIndex, 0)
        XCTAssertEqual(searchState.resultSummary, "1 of 4")
        XCTAssertEqual(searchState.matches.map(\.preview), ["Alpha", "Alpha", "alpha", "alpha"])
        XCTAssertEqual(searchState.matches.map(\.blockOrdinal), [0, 1, 1, 2])
        XCTAssertEqual(
            searchState.matches.map(\.range),
            [
                IOSReaderSearchTextRange(startUTF16Offset: 0, lengthUTF16: 5),
                IOSReaderSearchTextRange(startUTF16Offset: 0, lengthUTF16: 5),
                IOSReaderSearchTextRange(startUTF16Offset: 11, lengthUTF16: 5),
                IOSReaderSearchTextRange(startUTF16Offset: 0, lengthUTF16: 5)
            ]
        )
    }

    func testIOSReaderSearchEngineNavigatesPreviousNextAndEmptyQueries() {
        let source = "# Title\n\nneedle one needle two"
        let document = MarkdownParserAdapter().parse(source)
        let blocks = MarkdownNativeRenderer().render(document: document, source: source)
        let engine = IOSReaderSearchEngine()

        let initial = engine.search(query: "needle", in: blocks)
        let second = engine.next(in: initial)
        let wrappedForward = engine.next(in: second)
        let wrappedBackward = engine.previous(in: initial)
        let empty = engine.search(query: "   ", in: blocks)
        let missing = engine.search(query: "absent", in: blocks)

        XCTAssertEqual(initial.resultSummary, "1 of 2")
        XCTAssertEqual(second.selectedMatchIndex, 1)
        XCTAssertEqual(second.resultSummary, "2 of 2")
        XCTAssertEqual(wrappedForward.selectedMatchIndex, 0)
        XCTAssertEqual(wrappedBackward.selectedMatchIndex, 1)
        XCTAssertEqual(empty.query, "")
        XCTAssertEqual(empty.resultCount, 0)
        XCTAssertNil(empty.selectedMatchIndex)
        XCTAssertEqual(empty.resultSummary, "0 of 0")
        XCTAssertEqual(missing.query, "absent")
        XCTAssertEqual(missing.resultCount, 0)
        XCTAssertNil(missing.selectedMatch)
    }

    func testIOSReaderScreenSearchStateSupportsHighlightCountPreviousNextAndClear() {
        let handle = MobileDocumentHandle(
            identifier: "ios:url:/tmp/search.md",
            displayName: "search.md",
            origin: .documentPicker,
            access: .readWrite
        )
        let loadResult = MarkdownLoadResult(
            handle: handle,
            metadata: MobileFileMetadata(displayName: "search.md", byteCount: 31),
            source: "# Search\n\nFind this and find that",
            encoding: .utf8,
            lineEnding: .lf,
            loadedAt: Date(timeIntervalSince1970: 1_777_801_400)
        )
        let engine = IOSReaderScreenEngine()
        let document = MarkdownParserAdapter().parse(loadResult.source)
        let blocks = MarkdownNativeRenderer().render(document: document, source: loadResult.source)
        let ready = engine.readyState(loadResult: loadResult, renderedBlocks: blocks)

        let searching = engine.searchingState(from: ready, query: "find")
        let next = engine.nextSearchMatch(from: searching)
        let previous = engine.previousSearchMatch(from: next)
        let cleared = engine.clearSearch(from: searching)

        XCTAssertEqual(searching.readerState, .searching)
        XCTAssertTrue(searching.isSearchVisible)
        XCTAssertEqual(searching.searchState?.resultCount, 2)
        XCTAssertEqual(searching.searchState?.resultSummary, "1 of 2")
        XCTAssertEqual(searching.searchState?.matches.map(\.preview), ["Find", "find"])
        XCTAssertEqual(next.searchState?.resultSummary, "2 of 2")
        XCTAssertEqual(previous.searchState?.resultSummary, "1 of 2")
        XCTAssertEqual(cleared.readerState, .ready)
        XCTAssertNil(cleared.searchState)
        XCTAssertFalse(cleared.isSearchVisible)
        XCTAssertEqual(cleared.renderedBlocks, ready.renderedBlocks)
    }

    func testIOSReaderScreenClearSearchRestoresReadOnlyMode() {
        let handle = MobileDocumentHandle(
            identifier: "ios:share-text:readonly",
            displayName: "readonly.md",
            origin: .shareText,
            access: .readOnly
        )
        let loadResult = MarkdownLoadResult(
            handle: handle,
            metadata: MobileFileMetadata(displayName: "readonly.md", byteCount: 17),
            source: "Read-only search",
            encoding: .utf8,
            lineEnding: .none,
            loadedAt: Date(timeIntervalSince1970: 1_777_801_500)
        )
        let engine = IOSReaderScreenEngine()
        let document = MarkdownParserAdapter().parse(loadResult.source)
        let blocks = MarkdownNativeRenderer().render(document: document, source: loadResult.source)
        let readOnly = engine.readyState(loadResult: loadResult, renderedBlocks: blocks)
        let searching = engine.searchingState(from: readOnly, query: "search")

        let cleared = engine.clearSearch(from: searching)

        XCTAssertEqual(readOnly.readerState, .readOnly)
        XCTAssertEqual(searching.readerState, .searching)
        XCTAssertEqual(cleared.readerState, .readOnly)
        XCTAssertNil(cleared.searchState)
    }

    func testIOSDisplayNamePolicyHandlesMissingPathLikeLongCJKAndEmojiNames() {
        let policy = IOSDisplayNamePolicy(maximumCharacterCount: 32)

        XCTAssertEqual(policy.displayName(for: nil), "Untitled Markdown")
        XCTAssertEqual(policy.displayName(for: " \n\t "), "Untitled Markdown")
        XCTAssertEqual(
            policy.displayName(for: "/private/tmp/folder/meeting-notes.md"),
            "meeting-notes.md"
        )
        XCTAssertEqual(
            policy.displayName(for: "C:\\Users\\Reader\\draft.markdown"),
            "draft.markdown"
        )
        XCTAssertEqual(
            policy.displayName(for: "  会议记录 📄 日本語 한국어.md  "),
            "会议记录 📄 日本語 한국어.md"
        )

        let longName = "FastMD-\(String(repeating: "very-long-", count: 8))document.markdown"
        let displayName = policy.displayName(for: longName)

        XCTAssertLessThanOrEqual(displayName.count, 32)
        XCTAssertTrue(displayName.hasSuffix(".markdown"))
        XCTAssertTrue(displayName.contains("..."))
    }

    func testIOSReaderScreenNormalizesDocumentAndRecentDisplayNames() {
        let recent = IOSRecentDocumentSummary(
            identifier: "ios:bookmark:/tmp/recent.md",
            displayName: " /tmp/最近のメモ 📄.md ",
            contentTypeIdentifier: "net.daringfireball.markdown"
        )
        let state = IOSReaderScreenState(
            readerState: .ready,
            title: " \n ",
            recentDocuments: [recent],
            isSearchAvailable: true
        )

        XCTAssertEqual(state.title, "Untitled Markdown")
        XCTAssertEqual(state.recentDocuments.first?.displayName, "最近のメモ 📄.md")
        XCTAssertTrue(state.isSearchAvailable)
    }

    func testIOSReaderScreenReadyStateUsesGracefulDisplayNamePolicy() {
        let longName = "FastMD-\(String(repeating: "reader-name-", count: 12))fixture.md"
        let handle = MobileDocumentHandle(
            identifier: "ios:url:/tmp/\(longName)",
            displayName: longName,
            origin: .documentPicker,
            access: .readWrite
        )
        let loadResult = MarkdownLoadResult(
            handle: handle,
            metadata: MobileFileMetadata(displayName: longName, byteCount: 7),
            source: "# Title",
            encoding: .utf8,
            lineEnding: .none,
            loadedAt: Date(timeIntervalSince1970: 1_777_801_600)
        )
        let document = MarkdownParserAdapter().parse(loadResult.source)
        let blocks = MarkdownNativeRenderer().render(document: document, source: loadResult.source)

        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: blocks
        )

        XCTAssertLessThanOrEqual(ready.title.count, 96)
        XCTAssertTrue(ready.title.hasSuffix(".md"))
        XCTAssertTrue(ready.title.contains("..."))
        XCTAssertEqual(ready.subtitle, "Writable · 7 bytes")
        XCTAssertTrue(ready.isReadyForReading)
    }

    func testIOSReaderNavigationBackClosesSearchBeforeLeavingReader() {
        let engine = IOSReaderScreenEngine()
        let loadResult = makeReaderLoadResult(source: "# Search\n\nFind find")
        let document = MarkdownParserAdapter().parse(loadResult.source)
        let blocks = MarkdownNativeRenderer().render(document: document, source: loadResult.source)
        let ready = engine.readyState(
            loadResult: loadResult,
            renderedBlocks: blocks,
            selectedFontTier: .large,
            themeScheme: .dark
        )
        let searching = engine.searchingState(from: ready, query: "find")

        let action = IOSReaderNavigationEngine().backAction(
            for: IOSReaderNavigationContext(state: searching)
        )

        guard case .closeSearch(let restored) = action else {
            return XCTFail("Expected search to close before reader navigation")
        }
        XCTAssertEqual(restored.readerState, .ready)
        XCTAssertNil(restored.searchState)
        XCTAssertEqual(restored.renderedBlocks, ready.renderedBlocks)
        XCTAssertEqual(restored.selectedFontTier, .large)
        XCTAssertEqual(restored.themeScheme, .dark)
    }

    func testIOSReaderNavigationBackHandlesCleanAndDirtyEditors() {
        let range = MarkdownSourceRange(
            startUTF8Offset: 0,
            endUTF8Offset: 7,
            startLine: 1,
            endLine: 1
        )
        let blockID = MarkdownBlockID(kind: .paragraph, sourceRange: range, ordinal: 0)
        let editingBlock = IOSReaderScreenState(
            readerState: .editingBlock,
            title: "note.md",
            subtitle: "Writable · 7 bytes",
            renderedBlocks: [],
            isSearchAvailable: true
        )
        let cleanBlockSession = IOSReaderEditSession(
            mode: .block,
            originalSource: "# Title",
            currentSource: "# Title",
            blockID: blockID,
            sourceRange: range
        )
        let dirtyBlockSession = IOSReaderEditSession(
            mode: .block,
            originalSource: "# Title",
            currentSource: "# Changed",
            blockID: blockID,
            sourceRange: range
        )
        let editingSource = IOSReaderScreenState(
            readerState: .editingSource,
            title: "note.md",
            subtitle: "Read-only · 7 bytes",
            renderedBlocks: [],
            isSearchAvailable: true
        )
        let cleanReadOnlySourceSession = IOSReaderEditSession(
            mode: .source,
            originalSource: "# Title",
            currentSource: "# Title",
            returnReaderState: .readOnly
        )

        let navigation = IOSReaderNavigationEngine()
        let closeBlock = navigation.backAction(
            for: IOSReaderNavigationContext(
                state: editingBlock,
                editSession: cleanBlockSession
            )
        )
        let confirmBlock = navigation.backAction(
            for: IOSReaderNavigationContext(
                state: editingBlock,
                editSession: dirtyBlockSession
            )
        )
        let closeSource = navigation.backAction(
            for: IOSReaderNavigationContext(
                state: editingSource,
                editSession: cleanReadOnlySourceSession
            )
        )

        guard case .closeEditor(let restoredBlock) = closeBlock else {
            return XCTFail("Expected clean block editor to close")
        }
        XCTAssertEqual(restoredBlock.readerState, .ready)
        XCTAssertNil(restoredBlock.searchState)

        XCTAssertEqual(confirmBlock, .requestDiscardConfirmation(.block))

        guard case .closeEditor(let restoredSource) = closeSource else {
            return XCTFail("Expected clean source editor to close")
        }
        XCTAssertEqual(restoredSource.readerState, .readOnly)
        XCTAssertEqual(restoredSource.subtitle, "Read-only · 7 bytes")
    }

    func testIOSReaderNavigationBackFromReaderShowsRecentDocuments() {
        let recent = IOSRecentDocumentSummary(
            identifier: "ios:bookmark:/tmp/recent.md",
            displayName: "recent.md",
            contentTypeIdentifier: "net.daringfireball.markdown"
        )
        let ready = IOSReaderScreenState(
            readerState: .ready,
            title: "active.md",
            subtitle: "Writable · 10 bytes",
            selectedFontTier: .reader,
            themeScheme: .dark,
            recentDocuments: [recent],
            renderedBlocks: [],
            isOpenActionAvailable: true,
            isSearchAvailable: true
        )

        let action = IOSReaderNavigationEngine().backAction(
            for: IOSReaderNavigationContext(state: ready)
        )

        guard case .showRecentDocuments(let recentsState) = action else {
            return XCTFail("Expected reader back action to show recent documents")
        }
        XCTAssertEqual(recentsState.readerState, .empty)
        XCTAssertEqual(recentsState.title, "FastMD")
        XCTAssertEqual(recentsState.subtitle, "Recent documents")
        XCTAssertEqual(recentsState.selectedFontTier, .reader)
        XCTAssertEqual(recentsState.themeScheme, .dark)
        XCTAssertEqual(recentsState.recentDocuments, [recent])
        XCTAssertTrue(recentsState.isOpenActionAvailable)
        XCTAssertFalse(recentsState.isSearchAvailable)
    }

    func testIOSReaderRuntimeRestorationPreservesRotationStateWithoutPersistentContentStorage() {
        let engine = IOSReaderScreenEngine()
        let loadResult = makeReaderLoadResult(
            displayName: "rotation.md",
            source: "# Rotation\n\nFind dirty buffer"
        )
        let document = MarkdownParserAdapter().parse(loadResult.source)
        let blocks = MarkdownNativeRenderer().render(document: document, source: loadResult.source)
        let ready = engine.readyState(
            loadResult: loadResult,
            renderedBlocks: blocks,
            selectedFontTier: .reader,
            themeScheme: .dark
        )
        let searching = engine.searchingState(from: ready, query: "dirty")
        let scrollPosition = IOSReaderScrollPosition(
            anchorBlockID: blocks.last?.id,
            yOffsetWithinBlock: 42
        )
        let editSession = IOSReaderEditSession(
            mode: .source,
            originalSource: loadResult.source,
            currentSource: "# Rotation\n\nFind dirty buffer\n\nUnsaved",
            returnReaderState: .ready
        )

        let coordinator = IOSReaderRuntimeRestorationCoordinator()
        let snapshot = coordinator.capture(
            state: searching,
            activeDocument: loadResult,
            scrollPosition: scrollPosition,
            editSession: editSession
        )
        let restored = coordinator.restore(snapshot)

        XCTAssertEqual(snapshot.activeDocument, loadResult)
        XCTAssertEqual(snapshot.screenState.readerState, .searching)
        XCTAssertEqual(snapshot.screenState.renderedBlocks, blocks)
        XCTAssertEqual(snapshot.scrollPosition, scrollPosition)
        XCTAssertEqual(snapshot.selectedFontTier, .reader)
        XCTAssertEqual(snapshot.screenState.themeScheme, .dark)
        XCTAssertEqual(snapshot.searchQuery, "dirty")
        XCTAssertEqual(snapshot.dirtyEditBuffer, editSession.currentSource)
        XCTAssertFalse(snapshot.storesDocumentContentPersistently)
        XCTAssertEqual(restored.state, searching)
        XCTAssertEqual(restored.editSession, editSession)
    }

    func testIOSSourceEditorBeginsAndUpdatesFullSourceSession() {
        let loadResult = makeReaderLoadResult(
            displayName: "edit.md",
            source: "# Title\n\nBody"
        )
        let blocks = MarkdownNativeRenderer().render(
            document: MarkdownParserAdapter().parse(loadResult.source),
            source: loadResult.source
        )
        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: blocks,
            selectedFontTier: .large,
            themeScheme: .dark
        )
        let editor = IOSSourceEditorEngine()

        let editing = editor.beginFullSourceEditing(loadResult: loadResult, from: ready)
        let updated = editor.updateSource(
            in: editing,
            currentSource: "# Title\n\nChanged body"
        )

        XCTAssertEqual(editing.state.readerState, .editingSource)
        XCTAssertEqual(editing.state.selectedFontTier, .large)
        XCTAssertEqual(editing.state.themeScheme, .dark)
        XCTAssertFalse(editing.state.isOpenActionAvailable)
        XCTAssertFalse(editing.state.isSearchAvailable)
        XCTAssertEqual(editing.editSession?.mode, .source)
        XCTAssertEqual(editing.editSession?.originalSource, loadResult.source)
        XCTAssertEqual(editing.editSession?.currentSource, loadResult.source)
        XCTAssertFalse(editing.state.isDirtyEditing)

        let editorState = editor.editorState(for: updated)
        XCTAssertEqual(updated.state.readerState, .editingSource)
        XCTAssertTrue(updated.state.isDirtyEditing)
        XCTAssertEqual(updated.state.subtitle, "Editing source · Unsaved")
        XCTAssertEqual(updated.editSession?.currentSource, "# Title\n\nChanged body")
        XCTAssertEqual(editorState?.currentSource, "# Title\n\nChanged body")
        XCTAssertEqual(editorState?.isDirty, true)
        XCTAssertEqual(editorState?.canSave, true)
        XCTAssertEqual(editorState?.canCancel, true)
        XCTAssertEqual(editorState?.isReadOnly, false)
    }

    func testIOSSourceEditorAllowsReadOnlyTemporaryEditingButHidesSave() {
        let handle = MobileDocumentHandle(
            identifier: "ios:share-text:readonly",
            displayName: "readonly.md",
            origin: .shareText,
            access: .readOnly
        )
        let loadResult = MarkdownLoadResult(
            handle: handle,
            metadata: MobileFileMetadata(displayName: "readonly.md", byteCount: 11),
            source: "# Readonly",
            encoding: .utf8,
            lineEnding: .none,
            loadedAt: Date(timeIntervalSince1970: 1_777_801_800)
        )
        let blocks = MarkdownNativeRenderer().render(
            document: MarkdownParserAdapter().parse(loadResult.source),
            source: loadResult.source
        )
        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: blocks
        )
        let editor = IOSSourceEditorEngine()

        let editing = editor.beginFullSourceEditing(loadResult: loadResult, from: ready)
        let updated = editor.updateSource(in: editing, currentSource: "# Changed")
        let editorState = editor.editorState(for: updated)

        XCTAssertEqual(ready.readerState, .readOnly)
        XCTAssertEqual(updated.editSession?.returnReaderState, .readOnly)
        XCTAssertTrue(updated.state.isDirtyEditing)
        XCTAssertEqual(editorState?.isReadOnly, true)
        XCTAssertEqual(editorState?.canSave, false)
        XCTAssertEqual(editorState?.canCancel, true)
    }

    func testIOSSourceEditorRuntimePolicyKeepsSwiftUIForStableSmallSource() {
        let policy = IOSSourceEditorRuntimePolicy(
            largeSourceByteThreshold: 1_024,
            unstableInputLatencyMilliseconds: 80,
            unstableDroppedInputFrameThreshold: 3
        )

        let surface = policy.surface(
            for: IOSSourceEditorRuntimeProfile(
                sourceUTF8ByteCount: 512,
                observedSwiftUIInputLatencyMilliseconds: 24,
                observedDroppedInputFrameCount: 0
            )
        )

        XCTAssertEqual(surface, .swiftUITextEditor)
    }

    func testIOSSourceEditorRuntimePolicyFallsBackToTextKitForLargeOrUnstableSource() {
        let policy = IOSSourceEditorRuntimePolicy(
            largeSourceByteThreshold: 1_024,
            unstableInputLatencyMilliseconds: 80,
            unstableDroppedInputFrameThreshold: 3
        )

        XCTAssertEqual(
            policy.surface(
                for: IOSSourceEditorRuntimeProfile(sourceUTF8ByteCount: 1_024)
            ),
            .uiKitTextKitTextView
        )
        XCTAssertEqual(
            policy.surface(
                for: IOSSourceEditorRuntimeProfile(
                    sourceUTF8ByteCount: 512,
                    observedSwiftUIInputLatencyMilliseconds: 96
                )
            ),
            .uiKitTextKitTextView
        )
        XCTAssertEqual(
            policy.surface(
                for: IOSSourceEditorRuntimeProfile(
                    sourceUTF8ByteCount: 512,
                    observedDroppedInputFrameCount: 3
                )
            ),
            .uiKitTextKitTextView
        )
        XCTAssertEqual(
            policy.surface(
                for: IOSSourceEditorRuntimeProfile(
                    sourceUTF8ByteCount: 512,
                    isUserForcedTextKitFallback: true
                )
            ),
            .uiKitTextKitTextView
        )
    }

    func testIOSSourceAndBlockEditorStatesExposeSelectedEditorSurface() {
        let largeSource = String(repeating: "a", count: 1_048_576)
        let sourceState = IOSSourceEditorState(
            title: "large.md",
            currentSource: largeSource,
            isDirty: true,
            canSave: true,
            canCancel: true,
            isReadOnly: false
        )

        let range = MarkdownSourceRange(
            startUTF8Offset: 0,
            endUTF8Offset: largeSource.utf8.count,
            startLine: 1,
            endLine: 1
        )
        let blockState = IOSBlockSourceEditorState(
            title: "large.md",
            currentSource: largeSource,
            isDirty: true,
            canApply: true,
            canCancel: true,
            isReadOnly: false,
            blockID: MarkdownBlockID(kind: .paragraph, sourceRange: range, ordinal: 0),
            sourceRange: range
        )

        XCTAssertEqual(sourceState.editorSurface, .uiKitTextKitTextView)
        XCTAssertEqual(blockState.editorSurface, .uiKitTextKitTextView)
    }

    func testIOSBlockSourceEditorBeginsUpdatesAndAppliesMappedBlock() throws {
        let loadResult = makeReaderLoadResult(
            displayName: "block-edit.md",
            source: "# Title\n\nParagraph one\ncontinues.\n\nTail"
        )
        let blocks = MarkdownNativeRenderer().render(
            document: MarkdownParserAdapter().parse(loadResult.source),
            source: loadResult.source
        )
        let paragraph = try XCTUnwrap(blocks.first { $0.role == .paragraph })
        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: blocks,
            selectedFontTier: .reader,
            themeScheme: .dark
        )
        let editor = IOSSourceEditorEngine()

        let editing = try editor.beginBlockSourceEditing(
            loadResult: loadResult,
            block: paragraph,
            from: ready
        )
        let updated = editor.updateBlockSource(
            in: editing,
            currentSource: "Changed block"
        )
        let editorState = try XCTUnwrap(editor.blockEditorState(for: updated))
        let applied = try editor.applyBlockEdit(from: updated, to: loadResult)

        XCTAssertEqual(editing.state.readerState, .editingBlock)
        XCTAssertEqual(editing.state.selectedFontTier, .reader)
        XCTAssertEqual(editing.state.themeScheme, .dark)
        XCTAssertEqual(editing.editSession?.mode, .block)
        XCTAssertEqual(editing.editSession?.blockID, paragraph.id)
        XCTAssertEqual(editing.editSession?.sourceRange, paragraph.sourceRange)
        XCTAssertEqual(editing.editSession?.originalSource, "Paragraph one\ncontinues.")
        XCTAssertEqual(updated.state.subtitle, "Editing block · Unsaved")
        XCTAssertEqual(editorState.currentSource, "Changed block")
        XCTAssertEqual(editorState.blockID, paragraph.id)
        XCTAssertEqual(editorState.sourceRangeDescription, "Lines 3-4")
        XCTAssertTrue(editorState.isDirty)
        XCTAssertTrue(editorState.canApply)
        XCTAssertFalse(editorState.isReadOnly)
        XCTAssertEqual(applied.source, "# Title\n\nChanged block\n\nTail")
        XCTAssertEqual(applied.lineEnding, .lf)
        XCTAssertTrue(applied.didChange)
    }

    func testIOSBlockSourceEditorFailsClosedWhenMappedRangeNoLongerMatches() throws {
        let loadResult = makeReaderLoadResult(
            displayName: "block-conflict.md",
            source: "# Title\n\nOriginal block\n\nTail"
        )
        let blocks = MarkdownNativeRenderer().render(
            document: MarkdownParserAdapter().parse(loadResult.source),
            source: loadResult.source
        )
        let paragraph = try XCTUnwrap(blocks.first { $0.role == .paragraph })
        let ready = IOSReaderScreenEngine().readyState(loadResult: loadResult, renderedBlocks: blocks)
        let editor = IOSSourceEditorEngine()
        let editing = try editor.beginBlockSourceEditing(
            loadResult: loadResult,
            block: paragraph,
            from: ready
        )
        let updated = editor.updateBlockSource(
            in: editing,
            currentSource: "Edited block"
        )
        let externallyMutated = MarkdownLoadResult(
            handle: loadResult.handle,
            metadata: loadResult.metadata,
            source: "# Title\n\nExternal edit\n\nTail",
            encoding: loadResult.encoding,
            lineEnding: loadResult.lineEnding,
            loadedAt: loadResult.loadedAt
        )

        XCTAssertThrowsError(
            try editor.applyBlockEdit(from: updated, to: externallyMutated)
        ) { error in
            XCTAssertEqual(error as? IOSBlockSourceEditError, .sourceRangeMismatch)
        }
    }

    func testIOSBlockSourceEditorAllowsReadOnlyTemporaryEditingButHidesApply() throws {
        let handle = MobileDocumentHandle(
            identifier: "ios:share-text:block-readonly",
            displayName: "block-readonly.md",
            origin: .shareText,
            access: .readOnly
        )
        let loadResult = MarkdownLoadResult(
            handle: handle,
            metadata: MobileFileMetadata(displayName: "block-readonly.md", byteCount: 18),
            source: "# Readonly\n\nBody",
            encoding: .utf8,
            lineEnding: .lf,
            loadedAt: Date(timeIntervalSince1970: 1_777_802_100)
        )
        let blocks = MarkdownNativeRenderer().render(
            document: MarkdownParserAdapter().parse(loadResult.source),
            source: loadResult.source
        )
        let paragraph = try XCTUnwrap(blocks.first { $0.role == .paragraph })
        let ready = IOSReaderScreenEngine().readyState(loadResult: loadResult, renderedBlocks: blocks)
        let editor = IOSSourceEditorEngine()

        let editing = try editor.beginBlockSourceEditing(
            loadResult: loadResult,
            block: paragraph,
            from: ready
        )
        let updated = editor.updateBlockSource(in: editing, currentSource: "Temporary body")
        let editorState = try XCTUnwrap(editor.blockEditorState(for: updated))

        XCTAssertEqual(ready.readerState, .readOnly)
        XCTAssertEqual(updated.editSession?.returnReaderState, .readOnly)
        XCTAssertTrue(updated.state.isDirtyEditing)
        XCTAssertTrue(editorState.isReadOnly)
        XCTAssertFalse(editorState.canApply)
        XCTAssertTrue(editorState.canCancel)
    }

    func testIOSAccessibilityPolicyLabelsIconOnlyControlsAndVoiceOverOrder() {
        let loadResult = makeReaderLoadResult(
            displayName: "accessibility.md",
            source: "# Title\n\nBody\n\n```swift\nlet value = 1\n```"
        )
        let blocks = MarkdownNativeRenderer().render(
            document: MarkdownParserAdapter().parse(loadResult.source),
            source: loadResult.source
        )
        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: blocks
        )
        let policy = IOSReaderAccessibilityPolicy()
        let audit = policy.audit(for: ready)

        XCTAssertTrue(audit.hasLabelsForAllIconOnlyControls)
        XCTAssertEqual(audit.iconOnlyControlLabels[.openMarkdown], "Open Markdown")
        XCTAssertEqual(audit.iconOnlyControlLabels[.searchDocument], "Search Document")
        XCTAssertEqual(audit.iconOnlyControlLabels[.editSource], "Edit Source")
        XCTAssertEqual(audit.iconOnlyControlLabels[.fontSize], "Font Size")
        XCTAssertEqual(audit.iconOnlyControlLabels[.copyCode], "Copy Code")
        XCTAssertTrue(audit.voiceOverOrderMatchesVisualOrder)
        XCTAssertEqual(audit.elements.first?.kind, .toolbar)
        XCTAssertEqual(
            audit.elements.filter { $0.kind == .readerBlock }.map(\.label),
            blocks.map(\.plainText)
        )
    }

    func testIOSAccessibilityPolicyAnnouncesSearchResultChanges() {
        let loadResult = makeReaderLoadResult(
            displayName: "search-a11y.md",
            source: "# Search\n\nneedle one\n\nneedle two"
        )
        let blocks = MarkdownNativeRenderer().render(
            document: MarkdownParserAdapter().parse(loadResult.source),
            source: loadResult.source
        )
        let ready = IOSReaderScreenEngine().readyState(loadResult: loadResult, renderedBlocks: blocks)
        let searching = IOSReaderScreenEngine().searchingState(from: ready, query: "needle")
        let emptySearch = IOSReaderScreenEngine().searchingState(from: ready, query: "missing")
        let policy = IOSReaderAccessibilityPolicy()

        XCTAssertEqual(
            policy.audit(for: searching).searchAnnouncement,
            "Search result 1 of 2"
        )
        XCTAssertEqual(
            policy.audit(for: emptySearch).searchAnnouncement,
            "No search results"
        )
    }

    func testIOSAccessibilityPolicyExposesDirtyEditWarningAsAlert() {
        let loadResult = makeReaderLoadResult(
            displayName: "dirty-alert.md",
            source: "# Dirty\n\nOriginal"
        )
        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: []
        )
        let editor = IOSSourceEditorEngine()
        let editing = editor.beginFullSourceEditing(loadResult: loadResult, from: ready)
        let dirty = editor.updateSource(
            in: editing,
            currentSource: "# Dirty\n\nUnsaved"
        )
        let audit = IOSReaderAccessibilityPolicy().audit(for: dirty.state)

        XCTAssertTrue(audit.hasAccessibleDirtyEditAlert)
        XCTAssertEqual(audit.dirtyEditAlert?.kind, .editorWarning)
        XCTAssertEqual(audit.dirtyEditAlert?.label, "Unsaved changes")
        XCTAssertEqual(audit.elements.map(\.kind), [.toolbar, .editorWarning, .editor])
        XCTAssertTrue(audit.voiceOverOrderMatchesVisualOrder)
    }

    func testIOSDynamicTypeAuditCoversAllFourFontTiers() throws {
        let audit = IOSReaderAccessibilityPolicy().dynamicTypeAudit()

        XCTAssertTrue(audit.validatesAllFourTiers)
        XCTAssertTrue(audit.allMetricsComposeWithDynamicType)

        for tier in MobileFontTier.allCases {
            let metrics = try XCTUnwrap(audit.metricsByTier[tier])
            XCTAssertEqual(metrics[.paragraph]?.pointSize, tier.bodyPointSize)
            XCTAssertEqual(metrics[.paragraph]?.dynamicTypeTextStyle, "body")
            XCTAssertEqual(metrics[.code]?.usesMonospace, true)
            XCTAssertEqual(metrics[.code]?.usesDynamicTypeTextStyle, true)
            XCTAssertEqual(metrics[.heading1]?.dynamicTypeTextStyle, "headline")
        }
    }

    func testIOSDiagnosticsSnapshotRedactsPrivateDocumentData() {
        let diagnostics = IOSDiagnosticsBuilder().snapshot(
            parseMilliseconds: 3.4,
            renderMilliseconds: 12.5,
            searchMilliseconds: 1.2,
            saveMilliseconds: 8.8,
            deviceClass: .iOSPhone12Standard,
            rendererProfile: "native-swiftui-uikit",
            byteCount: 245_000,
            lastErrorCode: .externalMutation
        )

        XCTAssertEqual(diagnostics.parseMilliseconds, 3.4)
        XCTAssertEqual(diagnostics.renderMilliseconds, 12.5)
        XCTAssertEqual(diagnostics.searchMilliseconds, 1.2)
        XCTAssertEqual(diagnostics.saveMilliseconds, 8.8)
        XCTAssertEqual(diagnostics.deviceClass, .iOSPhone12Standard)
        XCTAssertEqual(diagnostics.rendererProfile, "native-swiftui-uikit")
        XCTAssertEqual(diagnostics.fileSizeBucket, .medium)
        XCTAssertEqual(diagnostics.lastErrorCategory, .save)
        XCTAssertTrue(diagnostics.isRedactedForLocalExport)
        XCTAssertFalse(diagnostics.includesDocumentContent)
        XCTAssertFalse(diagnostics.includesFullPath)
        XCTAssertFalse(diagnostics.includesFullURI)
        XCTAssertFalse(diagnostics.includesQueryStrings)
        XCTAssertFalse(diagnostics.includesClipboard)
    }

    func testIOSDirtyDraftStoreCapturesBackgroundDirtyBufferAndSkipsCleanSessions() throws {
        let suiteName = "FastMDMobileCoreTests.DirtyDraft.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let loadResult = makeReaderLoadResult(
            displayName: "draft.md",
            source: "# Draft\n\nOriginal"
        )
        let cleanSession = IOSReaderEditSession(
            mode: .source,
            originalSource: loadResult.source,
            currentSource: loadResult.source
        )
        let dirtySession = cleanSession.replacingCurrentSource("# Draft\n\nUnsaved")
        let now = Date(timeIntervalSince1970: 1_777_801_900)
        let store = IOSDirtyEditDraftStore(
            storageKey: "draft.\(UUID().uuidString)",
            timeToLive: 60
        )

        XCTAssertEqual(
            store.captureForBackground(
                activeDocument: loadResult,
                editSession: cleanSession,
                now: now,
                defaults: defaults
            ),
            .skippedCleanSession
        )
        XCTAssertNil(store.load(now: now, defaults: defaults))

        let result = store.captureForBackground(
            activeDocument: loadResult,
            editSession: dirtySession,
            now: now,
            defaults: defaults
        )
        guard case .stored(let draft) = result else {
            return XCTFail("Expected dirty source edit to be captured")
        }

        XCTAssertEqual(draft.documentIdentifier, loadResult.handle.identifier)
        XCTAssertEqual(draft.displayName, "draft.md")
        XCTAssertEqual(draft.editorMode, .source)
        XCTAssertEqual(draft.originalSourceHash, loadResult.source.hashValue)
        XCTAssertEqual(draft.currentSource, "# Draft\n\nUnsaved")
        XCTAssertEqual(draft.capturedAt, now)
        XCTAssertEqual(draft.expiresAt, now.addingTimeInterval(60))
        XCTAssertEqual(store.load(now: now.addingTimeInterval(30), defaults: defaults), draft)
        XCTAssertNil(store.load(now: now.addingTimeInterval(60), defaults: defaults))
    }

    func testIOSDirtyDraftRecoveryOffersAndRestoresProcessRecoverySession() throws {
        let suiteName = "FastMDMobileCoreTests.Recovery.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let loadResult = makeReaderLoadResult(
            displayName: "recover.md",
            source: "# Recover\n\nOriginal"
        )
        let dirtySession = IOSReaderEditSession(
            mode: .source,
            originalSource: loadResult.source,
            currentSource: "# Recover\n\nRestored"
        )
        let now = Date(timeIntervalSince1970: 1_777_802_000)
        let store = IOSDirtyEditDraftStore(
            storageKey: "recovery.\(UUID().uuidString)",
            timeToLive: 300
        )
        let coordinator = IOSDirtyEditRecoveryCoordinator(store: store)

        XCTAssertEqual(coordinator.recoveryOffer(now: now, defaults: defaults), .noDraft)
        store.captureForBackground(
            activeDocument: loadResult,
            editSession: dirtySession,
            now: now,
            defaults: defaults
        )

        guard case .restoreDraft(let draft) = coordinator.recoveryOffer(
            now: now.addingTimeInterval(10),
            defaults: defaults
        ) else {
            return XCTFail("Expected recovery draft offer")
        }

        let restoredSession = coordinator.makeRestoredEditSession(
            draft: draft,
            activeDocument: loadResult
        )
        XCTAssertEqual(restoredSession.mode, .source)
        XCTAssertEqual(restoredSession.originalSource, loadResult.source)
        XCTAssertEqual(restoredSession.currentSource, "# Recover\n\nRestored")
        XCTAssertEqual(restoredSession.returnReaderState, .ready)
        XCTAssertTrue(restoredSession.isDirty)
    }

    func testIOSSourceEditorSuccessfulSaveClearsDirtySessionWithNormalizedSource() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("source-save.md")
        let loadResult = makeReaderLoadResult(
            displayName: "source-save.md",
            source: "# Original\n\nBody"
        )
        try "# Original\n\nBody".data(using: .utf8)?.write(to: url)
        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: []
        )
        let editor = IOSSourceEditorEngine()
        let editing = editor.beginFullSourceEditing(loadResult: loadResult, from: ready)
        let updated = editor.updateSource(
            in: editing,
            currentSource: "# Saved\r\n\r\nBody"
        )

        let save = editor.saveFullSourceEdit(
            from: updated,
            activeDocument: loadResult,
            destinationURL: url
        )
        let editorState = try XCTUnwrap(editor.editorState(for: save.context))

        XCTAssertNil(save.error)
        XCTAssertEqual(save.saveResult?.savedSource, "# Saved\n\nBody")
        XCTAssertEqual(try String(contentsOf: url, encoding: .utf8), "# Saved\n\nBody")
        XCTAssertEqual(save.context.editSession?.originalSource, "# Saved\n\nBody")
        XCTAssertEqual(save.context.editSession?.currentSource, "# Saved\n\nBody")
        XCTAssertFalse(editorState.isDirty)
        XCTAssertFalse(editorState.canSave)
    }

    func testIOSSourceEditorSaveFailureKeepsDirtyBufferAndEditorOpen() throws {
        let missingDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let destinationURL = missingDirectory.appendingPathComponent("missing.md")
        let loadResult = makeReaderLoadResult(
            displayName: "failed-save.md",
            source: "# Original\n\nBody"
        )
        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: []
        )
        let editor = IOSSourceEditorEngine()
        let editing = editor.beginFullSourceEditing(loadResult: loadResult, from: ready)
        let updated = editor.updateSource(
            in: editing,
            currentSource: "# Unsaved\n\nStill here"
        )

        let save = editor.saveFullSourceEdit(
            from: updated,
            activeDocument: loadResult,
            destinationURL: destinationURL
        )
        let editorState = try XCTUnwrap(editor.editorState(for: save.context))

        XCTAssertEqual(
            save.error,
            .writeFailed(retainedDirtyBuffer: "# Unsaved\n\nStill here")
        )
        XCTAssertNil(save.saveResult)
        XCTAssertEqual(save.context.state.readerState, .editingSource)
        XCTAssertEqual(save.context.state.subtitle, "Save failed · Unsaved")
        XCTAssertEqual(save.context.state.errorCode, .saveFailed)
        XCTAssertEqual(save.context.editSession?.currentSource, "# Unsaved\n\nStill here")
        XCTAssertTrue(editorState.isDirty)
        XCTAssertTrue(editorState.canSave)
        XCTAssertEqual(editorState.lastSaveError, .saveFailed)
    }

    func testIOSSourceEditorExternalMutationBlocksBlindOverwriteAndKeepsDirtyBuffer() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let destinationURL = directory.appendingPathComponent("external-source-save.md")
        let loadResult = makeReaderLoadResult(
            displayName: "external-source-save.md",
            source: "# Original\n\nBody"
        )
        try "# Changed elsewhere\n\nBody".data(using: .utf8)?.write(to: destinationURL)
        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: []
        )
        let editor = IOSSourceEditorEngine()
        let editing = editor.beginFullSourceEditing(loadResult: loadResult, from: ready)
        let updated = editor.updateSource(
            in: editing,
            currentSource: "# User edit\n\nBody"
        )

        let save = editor.saveFullSourceEdit(
            from: updated,
            activeDocument: loadResult,
            destinationURL: destinationURL
        )
        let editorState = try XCTUnwrap(editor.editorState(for: save.context))

        XCTAssertEqual(
            save.error,
            .externalMutation(retainedDirtyBuffer: "# User edit\n\nBody")
        )
        XCTAssertNil(save.saveResult)
        XCTAssertEqual(save.context.state.readerState, .editingSource)
        XCTAssertEqual(save.context.state.subtitle, "External change detected · Unsaved")
        XCTAssertEqual(save.context.state.errorCode, .externalMutation)
        XCTAssertEqual(save.context.editSession?.currentSource, "# User edit\n\nBody")
        XCTAssertEqual(
            try String(contentsOf: destinationURL, encoding: .utf8),
            "# Changed elsewhere\n\nBody"
        )
        XCTAssertTrue(editorState.isDirty)
        XCTAssertTrue(editorState.canSave)
        XCTAssertEqual(editorState.lastSaveError, .externalMutation)
    }

    func testIOSL11ParserContractGateAuditsCanonicalRichFixture() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let audit = IOSParserContractAudit(document: document, source: source)

        XCTAssertTrue(audit.satisfiesStageOneParserContract)
        XCTAssertTrue(audit.containsOnlyValidRanges)
        XCTAssertTrue(audit.sourceRangesAreMonotonic)
        XCTAssertTrue(audit.blockIDsAreUnique)
        XCTAssertTrue(
            audit.includesRequiredKinds([
                .heading,
                .paragraph,
                .blockquote,
                .unorderedList,
                .orderedList,
                .taskList,
                .table,
                .codeFence,
                .richFallback,
                .image,
                .horizontalRule,
                .footnote,
                .htmlFallback
            ])
        )
    }

    func testIOSL11SourceRangeMappingGateAuditsCanonicalRichFixture() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let audit = IOSSourceRangeMappingAudit(source: source, blocks: document.blocks)

        XCTAssertTrue(audit.satisfiesStageOneSourceRangeMapping)
        XCTAssertTrue(audit.everyRangeMapsToNonEmptySourceSlice)
        XCTAssertTrue(audit.everyMappedSliceMatchesRangeByteLength)

        for block in document.blocks {
            XCTAssertNotNil(
                audit.sourceSlice(for: block),
                "Expected source slice for \(block.id.rawValue)"
            )
        }
    }

    func testIOSL11RichRendererSnapshotGateMatchesLightAndDarkGoldenSignatures() throws {
        let source = try richPreviewFixtureSource()
        let builder = IOSRendererSnapshotSignatureBuilder()

        for theme in IOSReaderThemeScheme.allCases {
            for tier in MobileFontTier.allCases {
                let signature = builder.signature(
                    source: source,
                    themeScheme: theme,
                    fontTier: tier
                )
                let goldenURL = goldenSnapshotURL(theme: theme, tier: tier)

                XCTAssertEqual(signature.lineCount, 17)
                XCTAssertEqual(
                    signature.text,
                    try String(contentsOf: goldenURL, encoding: .utf8),
                    "Snapshot signature mismatch for \(theme.rawValue)-\(tier.rawValue)"
                )
            }
        }
    }

    func testIOSL11LayoutSafetyGateAuditsOverflowTappableControlsAndOverlapRisk() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let audit = IOSLayoutSafetyAudit(
            lazyRenderingPolicy: IOSReaderScreenEngine().lazyRenderingPolicy,
            iconOnlyControlLabels: IOSReaderAccessibilityPolicy().iconOnlyControlLabels,
            renderedBlocks: rendered
        )

        XCTAssertTrue(audit.satisfiesStageOneLayoutSafety)
        XCTAssertTrue(audit.hasRequiredTappableControlSize)
        XCTAssertTrue(audit.hasNoPageLevelHorizontalOverflow)
        XCTAssertTrue(audit.hasNoKnownOverlapRisk)
        XCTAssertTrue(audit.iconOnlyControlsAreLabelled)
        XCTAssertTrue(audit.blocksWithPageLevelHorizontalOverflow.isEmpty)
    }

    func testIOSL11FileAccessGateAuditsOpenReadOnlyPermissionLostAndOffMainIO() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("file-access.md")
        try "# File Access\n\nBody".data(using: .utf8)?.write(to: url)

        let loaded = try await IOSDocumentFileIO().loadDocumentOffMainActor(
            at: url,
            origin: .documentPicker,
            access: .readWrite
        )
        let readOnly = makeLoadedDocument(
            displayName: "readonly-document.md",
            source: try fixtureSource(named: "readonly-document.md"),
            access: .readOnly
        )
        let readOnlyError = capturedSavePlannerError {
            _ = try IOSDocumentSavePlanner().makePlan(
                editedSource: "# Changed",
                for: readOnly
            )
        }
        var store = IOSRecentDocumentStore()
        try store.upsertUserSelectedDocument(
            url: url,
            bookmarkData: Data([0xF0, 0x0D]),
            contentTypeIdentifier: "net.daringfireball.markdown",
            byteCount: loaded.value.metadata.byteCount
        )
        let recentRecord = try XCTUnwrap(store.record(identifier: "ios:bookmark:\(url.path)"))
        let staleResolution = IOSBookmarkResolver().resolve(
            record: recentRecord,
            resolvedURL: url,
            isStale: true
        )
        let audit = IOSFileAccessAutomationAudit(
            loadedDocument: loaded.value,
            readOnlySaveError: readOnlyError,
            staleBookmarkResolution: staleResolution,
            recentDocumentRecord: recentRecord,
            offMainExecution: loaded.execution
        )

        XCTAssertTrue(audit.satisfiesStageOneFileAccessTests)
        XCTAssertTrue(audit.opensReadableMarkdownDocument)
        XCTAssertTrue(audit.readOnlySaveFailsClosed)
        XCTAssertTrue(audit.staleBookmarkMapsToPermissionLost)
        XCTAssertTrue(audit.recentDocumentStoresMetadataOnly)
        XCTAssertTrue(audit.fileIOExecutesOffMainActor)
    }

    func testIOSL11SaveIntegrityGateAuditsEncodingFailuresMutationAndDirtyRetention() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let planner = IOSDocumentSavePlanner()
        let bomLoaded = makeLoadedDocument(
            displayName: "encoding-utf8-bom.md",
            source: "# UTF-8 BOM\r\n\r\nBody",
            encoding: .utf8WithBOM,
            lineEnding: .crlf
        )
        let crlfLoaded = makeLoadedDocument(
            displayName: "line-endings-crlf.md",
            source: "# CRLF\r\n\r\nLine one.\r\nLine two.",
            lineEnding: .crlf
        )
        let readOnly = makeLoadedDocument(
            displayName: "readonly-document.md",
            source: "# Readonly",
            access: .readOnly
        )
        let unsupported = makeLoadedDocument(
            displayName: "legacy.md",
            source: "# Legacy",
            encoding: .unsupported
        )
        let successfulURL = directory.appendingPathComponent("successful.md")
        let successfulLoaded = makeLoadedDocument(
            displayName: "successful.md",
            source: "# Original\n\nBody"
        )
        try "# Original\n\nBody".data(using: .utf8)?.write(to: successfulURL)
        let missingURL = directory
            .appendingPathComponent("missing", isDirectory: true)
            .appendingPathComponent("write.md")
        let externalURL = directory.appendingPathComponent("external.md")
        let externalLoaded = makeLoadedDocument(
            displayName: "external.md",
            source: "# Original\n\nBody"
        )
        try "# Changed elsewhere\n\nBody".data(using: .utf8)?.write(to: externalURL)

        let successfulResult = try IOSDocumentFileIO().saveDocument(
            editedSource: "# Saved\n\nBody",
            for: successfulLoaded,
            to: successfulURL
        )
        let failedSaveError = capturedSaveError {
            _ = try IOSDocumentFileIO().saveDocument(
                editedSource: "# Unsaved\n\nBody",
                for: successfulLoaded,
                to: missingURL
            )
        }
        let externalMutationError = capturedSaveError {
            _ = try IOSDocumentFileIO().saveDocument(
                editedSource: "# User edit\n\nBody",
                for: externalLoaded,
                to: externalURL
            )
        }
        let audit = IOSSaveIntegrityAutomationAudit(
            bomPlan: try planner.makePlan(
                editedSource: "\u{FEFF}# Changed\n\nBody",
                for: bomLoaded
            ),
            crlfPlan: try planner.makePlan(
                editedSource: "# Changed\n\nLine one.\nLine two.",
                for: crlfLoaded
            ),
            readOnlySaveError: capturedSavePlannerError {
                _ = try planner.makePlan(editedSource: "# Changed", for: readOnly)
            },
            unsupportedEncodingError: capturedSavePlannerError {
                _ = try planner.makePlan(editedSource: "# Changed", for: unsupported)
            },
            failedSaveError: failedSaveError,
            externalMutationError: externalMutationError,
            successfulSaveResult: successfulResult
        )

        XCTAssertTrue(audit.satisfiesStageOneSaveIntegrityTests)
        XCTAssertTrue(audit.preservesUTF8BOMWithoutDuplicateBOM)
        XCTAssertTrue(audit.preservesCRLFLineEndings)
        XCTAssertTrue(audit.rejectsReadOnlyAndUnsupportedEncoding)
        XCTAssertTrue(audit.writesCompleteOutputBeforeDestinationWrite)
        XCTAssertTrue(audit.keepsDirtyBufferAfterFailedSave)
        XCTAssertTrue(audit.detectsAndBlocksExternalMutation)
        XCTAssertEqual(try String(contentsOf: externalURL, encoding: .utf8), "# Changed elsewhere\n\nBody")
    }

    func testIOSL11MaliciousHTMLFixtureGateAuditsSanitizedNativeFallbacks() throws {
        let source = try fixtureSource(named: "malicious-html.md")
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let audit = IOSHostileMarkdownFixtureAudit(renderedBlocks: rendered)

        XCTAssertTrue(audit.satisfiesStageOneMaliciousHTMLFixtureTests)
        XCTAssertTrue(audit.htmlFallbacksBlockUnsafeSurfaces)
        XCTAssertTrue(audit.sanitizedHTMLHasNoExecutableFragments)
    }

    func testIOSL11MaliciousLinkFixtureGateAuditsDangerousLinkBlocking() throws {
        let source = try fixtureSource(named: "malicious-links.md")
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let audit = IOSHostileMarkdownFixtureAudit(renderedBlocks: rendered)

        XCTAssertTrue(audit.satisfiesStageOneMaliciousLinkFixtureTests)
        XCTAssertTrue(audit.dangerousLinksAreBlocked)
        XCTAssertTrue(audit.safeWebLinksRequireConfirmation)
    }

    func testIOSL11RemoteImagePrivacyGateAuditsManualOpenPlaceholders() throws {
        let source = try fixtureSource(named: "remote-image.md")
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let audit = IOSRemoteImagePrivacyAudit(renderedBlocks: rendered)

        XCTAssertTrue(audit.satisfiesStageOneRemoteImagePrivacyTests)
        XCTAssertTrue(audit.remoteImagesAreManualOpenPlaceholders)
        XCTAssertTrue(audit.remoteImageLinksAreBlockedAsResources)
        XCTAssertEqual(audit.remoteImages.count, 1)
    }

    func testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let inventory = rendererAssetInventory()
        let audit = IOSLocalRendererConditionalGateAudit(
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: inventory.discoveredRendererAssetPaths
        )

        XCTAssertTrue(inventory.provesNativeFallbackInventory)
        XCTAssertTrue(audit.satisfiesStageOneConditionalRendererGates)
        XCTAssertTrue(audit.richFallbacksStayNativeSafeCards)
        XCTAssertFalse(audit.usesVendoredRendererAssets)
        XCTAssertFalse(audit.usesWKWebViewRichSurface)
        XCTAssertEqual(audit.discoveredRendererAssetPaths, [])
        XCTAssertEqual(audit.localRendererPackagingGateStatus, .notApplicableNativeFallback)
        XCTAssertEqual(audit.wkWebViewRequestBlockingGateStatus, .notApplicableNativeFallback)
        XCTAssertEqual(audit.rendererAssetManifestHashGateStatus, .notApplicableNativeFallback)
    }

    func testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs() {
        let inventory = rendererAssetInventory()

        XCTAssertTrue(inventory.provesNativeFallbackInventory)
        XCTAssertGreaterThan(inventory.scannedSwiftFileCount, 0)
        XCTAssertEqual(inventory.discoveredRendererAssetPaths, [])
        XCTAssertEqual(inventory.discoveredRendererAssets, [])
        XCTAssertEqual(inventory.declaredBundledRendererResourceRoots, [])
        XCTAssertFalse(inventory.importsWebKitRichRendererCode)
        XCTAssertEqual(
            IOSRendererAssetInventory.defaultInventoryCommand,
            "find ios \\( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \\) -prune -o -type f \\( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \\) -print | sort"
        )
    }

    func testIOSL11RendererAssetInventoryMatchesDocumentedCommandForCurrentTree() throws {
        #if os(iOS)
        throw XCTSkip("Process-based shell command parity is validated by SwiftPM on macOS; iOS Simulator bundles validate the same inventory model without spawning /bin/sh.")
        #else
        let inventory = rendererAssetInventory()
        let commandPaths = try documentedRendererAssetInventoryCommandPaths()
        let audit = IOSRendererAssetInventoryCommandParityAudit(
            inventory: inventory,
            documentedCommandPaths: commandPaths
        )

        XCTAssertTrue(audit.documentedCommandMatchesInventoryContract)
        XCTAssertEqual(commandPaths, inventory.discoveredRendererAssetPaths)
        XCTAssertTrue(audit.commandPathsExactlyMatchSwiftDiscovery)
        XCTAssertTrue(audit.commandPathsStayIOSLocal)
        XCTAssertTrue(audit.commandPathsExcludeIgnoredValidationArtifacts)
        XCTAssertTrue(audit.satisfiesStageOneInventoryCommandParity)
        #endif
    }

    func testIOSL11RendererAssetInventoryCommandParityRejectsUnsafeOrStaleCommandOutput() {
        let inventory = IOSRendererAssetInventory()
        let audit = IOSRendererAssetInventoryCommandParityAudit(
            inventory: inventory,
            documentedCommandPaths: [
                "android/app/src/main/assets/fastmd-renderers/renderer.js",
                "ios/docs/reports/generated-renderer.js",
                "ios/Resources/FastMDRenderers/renderer.js?cache=1"
            ]
        )

        XCTAssertFalse(audit.commandPathsExactlyMatchSwiftDiscovery)
        XCTAssertFalse(audit.commandPathsStayIOSLocal)
        XCTAssertFalse(audit.commandPathsExcludeIgnoredValidationArtifacts)
        XCTAssertFalse(audit.satisfiesStageOneInventoryCommandParity)
    }

    func testIOSL11RendererAssetInventoryCommandMatchesCaseInsensitiveDiscovery() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let assetRoot = root
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("FastMDRenderers", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: assetRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: sourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        try Data("console.log('uppercase renderer')".utf8)
            .write(to: assetRoot.appendingPathComponent("Renderer.JS"))
        try Data(".math { display: inline; }".utf8)
            .write(to: assetRoot.appendingPathComponent("Math.CSS"))
        try Data("<!doctype html><title>FastMD</title>".utf8)
            .write(to: assetRoot.appendingPathComponent("Index.HTML"))
        try Data("font bytes".utf8)
            .write(to: assetRoot.appendingPathComponent("KaTeX.WOFF2"))
        try """
        import Foundation

        struct UppercaseRendererAssetProbe {}
        """.write(
            to: sourceRoot.appendingPathComponent("UppercaseRendererAssetProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)
        let manifestAudit = IOSRendererAssetManifestHashAudit(
            discoveredAssets: inventory.discoveredRendererAssets,
            manifestEntries: inventory.discoveredRendererAssets
        )

        XCTAssertTrue(IOSRendererAssetInventory.defaultInventoryCommand.contains("-iname '*.js'"))
        XCTAssertTrue(IOSRendererAssetInventory.defaultInventoryCommand.contains("-iname '*.woff2'"))
        XCTAssertEqual(inventory.discoveredRendererAssetPaths, [
            "ios/Resources/FastMDRenderers/Index.HTML",
            "ios/Resources/FastMDRenderers/KaTeX.WOFF2",
            "ios/Resources/FastMDRenderers/Math.CSS",
            "ios/Resources/FastMDRenderers/Renderer.JS"
        ])
        XCTAssertEqual(inventory.discoveredRendererAssets.count, 4)
        XCTAssertTrue(inventory.discoveredRendererAssets.allSatisfy(\.isBundledRendererResourcePath))
        XCTAssertTrue(manifestAudit.satisfiesStageOneManifestHashVerification)
    }

    func testIOSL11RendererAssetInventoryIgnoresLooseRendererLikeValidationArtifacts() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let buildRoot = root
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("debug", isDirectory: true)
        let swiftPMRoot = root
            .appendingPathComponent(".swiftpm", isDirectory: true)
            .appendingPathComponent("configuration", isDirectory: true)
        let testsRoot = root
            .appendingPathComponent("Tests", isDirectory: true)
            .appendingPathComponent("Fixtures", isDirectory: true)
            .appendingPathComponent("RendererAssets", isDirectory: true)
        let reportRoot = root
            .appendingPathComponent("docs", isDirectory: true)
            .appendingPathComponent("reports", isDirectory: true)
        let screenshotRoot = root
            .appendingPathComponent("docs", isDirectory: true)
            .appendingPathComponent("screenshots", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: buildRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: swiftPMRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: testsRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: reportRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: screenshotRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: sourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        try "<html><body>validation report</body></html>".write(
            to: reportRoot.appendingPathComponent("stage1-renderer-report.html"),
            atomically: true,
            encoding: .utf8
        )
        try "console.log('golden placeholder')".write(
            to: screenshotRoot.appendingPathComponent("renderer-placeholder.js"),
            atomically: true,
            encoding: .utf8
        )
        try "console.log('swiftpm build output')".write(
            to: buildRoot.appendingPathComponent("generated-renderer.mjs"),
            atomically: true,
            encoding: .utf8
        )
        try "body { color: red; }".write(
            to: swiftPMRoot.appendingPathComponent("workspace-renderer.css"),
            atomically: true,
            encoding: .utf8
        )
        try "<!doctype html><title>Test fixture only</title>".write(
            to: testsRoot.appendingPathComponent("renderer-fixture.html"),
            atomically: true,
            encoding: .utf8
        )
        try "@font-face { font-family: fixture; }".write(
            to: testsRoot.appendingPathComponent("fixture-font.css"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import Foundation

        struct NativeFallbackProbe {}
        """.write(
            to: sourceRoot.appendingPathComponent("NativeFallbackProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)

        XCTAssertEqual(inventory.discoveredRendererAssetPaths, [])
        XCTAssertEqual(inventory.discoveredRendererAssets, [])
        XCTAssertEqual(inventory.declaredBundledRendererResourceRoots, [])
        XCTAssertEqual(inventory.scannedSwiftFileCount, 1)
        XCTAssertFalse(inventory.importsWebKitRichRendererCode)
        XCTAssertTrue(inventory.provesNativeFallbackInventory)
        XCTAssertTrue(IOSRendererAssetInventory.ignoredInventoryDirectoryPathPrefixes.contains("ios/.build"))
        XCTAssertTrue(IOSRendererAssetInventory.ignoredInventoryDirectoryPathPrefixes.contains("ios/.swiftpm"))
        XCTAssertTrue(IOSRendererAssetInventory.ignoredInventoryDirectoryPathPrefixes.contains("ios/Tests"))
        XCTAssertTrue(IOSRendererAssetInventory.ignoredInventoryDirectoryPathPrefixes.contains("ios/docs/reports"))
        XCTAssertTrue(IOSRendererAssetInventory.ignoredInventoryDirectoryPathPrefixes.contains("ios/docs/screenshots"))
    }

    func testIOSL11ConditionalRendererEvidenceBuilderKeepsGeneratedArtifactsOutOfCurrentGateInputs() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let buildRoot = root
            .appendingPathComponent(".build", isDirectory: true)
            .appendingPathComponent("debug", isDirectory: true)
        let swiftPMRoot = root
            .appendingPathComponent(".swiftpm", isDirectory: true)
            .appendingPathComponent("workspace-state", isDirectory: true)
        let reportRoot = root
            .appendingPathComponent("docs", isDirectory: true)
            .appendingPathComponent("reports", isDirectory: true)
        let screenshotRoot = root
            .appendingPathComponent("docs", isDirectory: true)
            .appendingPathComponent("screenshots", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: buildRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: swiftPMRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: reportRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: screenshotRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: sourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        try "console.log('generated asset outside app bundle')".write(
            to: buildRoot.appendingPathComponent("generated-renderer.js"),
            atomically: true,
            encoding: .utf8
        )
        try "<!doctype html><title>SwiftPM Artifact</title>".write(
            to: swiftPMRoot.appendingPathComponent("workspace-renderer.html"),
            atomically: true,
            encoding: .utf8
        )
        try "<!doctype html><title>Report Artifact</title>".write(
            to: reportRoot.appendingPathComponent("renderer-report.htm"),
            atomically: true,
            encoding: .utf8
        )
        try "@font-face { font-family: report; }".write(
            to: screenshotRoot.appendingPathComponent("renderer-placeholder.css"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import Foundation

        struct NativeFallbackCurrentGateProbe {}
        """.write(
            to: sourceRoot.appendingPathComponent("NativeFallbackCurrentGateProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let rendered = [
            makeRichFallbackBlock(
                surface: .nativeSafeCard,
                rendersAsNativeSafeCard: true,
                requiresVendoredRendererAssets: false,
                allowsNetworkRequests: false,
                allowsExternalNavigation: false,
                allowsRemoteSubresources: false
            )
        ]
        let bundle = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: root,
            generatedAt: Date(timeIntervalSince1970: 1_777_806_600)
        ).makeEvidence(renderedBlocks: rendered)

        XCTAssertTrue(bundle.satisfiesStageOneConditionalRendererChecklist)
        XCTAssertTrue(bundle.inventory.provesNativeFallbackInventory)
        XCTAssertEqual(bundle.inventory.discoveredRendererAssetPaths, [])
        XCTAssertEqual(bundle.audit.localRendererPackagingGateStatus, .notApplicableNativeFallback)
        XCTAssertEqual(bundle.audit.wkWebViewRequestBlockingGateStatus, .notApplicableNativeFallback)
        XCTAssertEqual(bundle.audit.rendererAssetManifestHashGateStatus, .notApplicableNativeFallback)
        XCTAssertTrue(bundle.report.markdown.contains("Discovered renderer asset paths: none"))
        XCTAssertTrue(bundle.report.markdown.contains("local renderer packaging/offline | notApplicableNativeFallback | true"))
        XCTAssertTrue(bundle.report.markdown.contains("WKWebView request blocking | notApplicableNativeFallback | true"))
        XCTAssertTrue(bundle.report.markdown.contains("renderer asset manifest/hash | notApplicableNativeFallback | true"))
    }

    func testIOSL11ConditionalRendererEvidenceBuilderAuditsCurrentSourceTreeFromMarkdownSource() throws {
        let bundle = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_807_000)
        ).makeEvidence(source: try richPreviewFixtureSource())

        XCTAssertTrue(bundle.satisfiesStageOneConditionalRendererChecklist)
        XCTAssertTrue(bundle.inventory.provesNativeFallbackInventory)
        XCTAssertEqual(bundle.inventory.discoveredRendererAssetPaths, [])
        XCTAssertEqual(bundle.audit.discoveredRendererAssetPaths, [])
        XCTAssertFalse(bundle.inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(bundle.audit.usesVendoredRendererAssets)
        XCTAssertFalse(bundle.audit.usesWKWebViewRichSurface)
        XCTAssertTrue(bundle.audit.richFallbacksStayNativeSafeCards)
        XCTAssertEqual(bundle.audit.localRendererPackagingGateStatus, .notApplicableNativeFallback)
        XCTAssertEqual(bundle.audit.wkWebViewRequestBlockingGateStatus, .notApplicableNativeFallback)
        XCTAssertEqual(bundle.audit.rendererAssetManifestHashGateStatus, .notApplicableNativeFallback)
        XCTAssertTrue(bundle.report.capturesConditionalRendererGateEvidence)
        XCTAssertEqual(bundle.report.evidence.supervisorCompletionRecommendations.count, 3)
        XCTAssertTrue(bundle.report.markdown.contains("Native fallback reason: iOS renders rich Markdown fallback blocks as native safe cards"))
    }

    func testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems() throws {
        let bundle = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_808_400)
        ).makeEvidence(source: try richPreviewFixtureSource())
        let expectedChecklistItems = [
            IOSStageOneReconciliationChecklistItem.localRendererPackagingOfflineTests.rawValue,
            IOSStageOneReconciliationChecklistItem.wkWebViewRequestBlockingTests.rawValue,
            IOSStageOneReconciliationChecklistItem.rendererAssetManifestHashTests.rawValue
        ]

        XCTAssertTrue(bundle.satisfiesStageOneConditionalRendererChecklist)
        XCTAssertTrue(bundle.inventory.provesNativeFallbackInventory)
        XCTAssertEqual(bundle.inventory.discoveredRendererAssetPaths, [])
        XCTAssertFalse(bundle.inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(bundle.audit.usesVendoredRendererAssets)
        XCTAssertFalse(bundle.audit.usesWKWebViewRichSurface)
        XCTAssertEqual(
            bundle.audit.checklistEvidence.supervisorCompletionRecommendations,
            expectedChecklistItems
        )
        XCTAssertEqual(
            bundle.audit.checklistEvidence.checklistItems.map(\.blueprintChecklistText),
            expectedChecklistItems
        )
        XCTAssertTrue(bundle.audit.checklistEvidence.checklistItems.allSatisfy(\.checklistSatisfied))
        XCTAssertTrue(bundle.report.capturesConditionalRendererGateEvidence)

        for checklistItem in expectedChecklistItems {
            XCTAssertTrue(bundle.report.markdown.contains("- \(checklistItem)"))
            XCTAssertTrue(bundle.report.markdown.contains("| \(checklistItem) | notApplicableNativeFallback | true |"))
        }
    }

    func testIOSL11ConditionalRendererEvidenceBuilderAcceptsRequestBlockedWKWebViewMode() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let assetRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("FastMDRenderers", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: assetRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: sourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        try """
        // swift-tools-version: 5.7

        import PackageDescription

        let package = Package(
            name: "FastMDMobile",
            targets: [
                .target(
                    name: "FastMDMobileCore",
                    resources: [.process("Resources/FastMDRenderers")]
                )
            ]
        )
        """.write(
            to: root.appendingPathComponent("Package.swift"),
            atomically: true,
            encoding: .utf8
        )
        try "export function render() { return 'safe'; }".write(
            to: assetRoot.appendingPathComponent("renderer.js"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import Foundation
        import WebKit

        struct LocalRichRendererSurface {
            func makeView() {
                _ = WKWebView(frame: .zero)
            }
        }
        """.write(
            to: sourceRoot.appendingPathComponent("LocalRichRendererSurface.swift"),
            atomically: true,
            encoding: .utf8
        )

        let rendered = [
            makeRichFallbackBlock(
                surface: .localWKWebView,
                rendersAsNativeSafeCard: false,
                requiresVendoredRendererAssets: true,
                allowsNetworkRequests: false,
                allowsExternalNavigation: false,
                allowsRemoteSubresources: false
            )
        ]
        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)
        let manifestAudit = IOSRendererAssetManifestHashAudit(
            discoveredAssets: inventory.discoveredRendererAssets,
            manifestEntries: inventory.discoveredRendererAssets
        )
        let bundle = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: root,
            generatedAt: Date(timeIntervalSince1970: 1_777_807_100)
        ).makeEvidence(
            renderedBlocks: rendered,
            runtimeAudit: LocalRichRendererRuntimeAudit(
                policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
                declaredAssetNames: ["renderer.js"]
            ),
            releasePosture: IOSReleaseSecurityPosture(
                usesWKWebViewRichRendering: true,
                localRendererPolicy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers")
            ),
            rendererAssetManifestHashAudit: manifestAudit,
            wkWebViewRequestBlockingPolicy: wkWebViewRequestBlockingPolicy()
        )

        XCTAssertTrue(bundle.satisfiesStageOneConditionalRendererChecklist)
        XCTAssertTrue(bundle.inventory.importsWebKitRichRendererCode)
        XCTAssertEqual(
            bundle.inventory.discoveredRendererAssetPaths,
            ["ios/Sources/FastMDMobileCore/Resources/FastMDRenderers/renderer.js"]
        )
        XCTAssertTrue(bundle.audit.usesVendoredRendererAssets)
        XCTAssertTrue(bundle.audit.usesWKWebViewRichSurface)
        XCTAssertEqual(bundle.audit.localRendererPackagingGateStatus, .requiredAndSatisfied)
        XCTAssertEqual(bundle.audit.wkWebViewRequestBlockingGateStatus, .requiredAndSatisfied)
        XCTAssertEqual(bundle.audit.rendererAssetManifestHashGateStatus, .requiredAndSatisfied)
        XCTAssertTrue(bundle.report.markdown.contains("WKWebView request blocking | requiredAndSatisfied | true"))
    }

    func testIOSL11RendererAssetInventoryDetectsLooseProductionRendererAssets() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let looseAssetRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
            .appendingPathComponent("LooseRenderers", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: looseAssetRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        let scriptData = Data("console.log('loose-production-renderer')".utf8)
        let htmlData = Data("<!doctype html><title>Loose Renderer</title>".utf8)
        try scriptData.write(to: looseAssetRoot.appendingPathComponent("renderer.js"))
        try htmlData.write(to: looseAssetRoot.appendingPathComponent("renderer.html"))
        try """
        import Foundation

        struct LooseRendererAssetProbe {}
        """.write(
            to: sourceRoot.appendingPathComponent("LooseRendererAssetProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)
        let manifestAudit = IOSRendererAssetManifestHashAudit(
            discoveredAssets: inventory.discoveredRendererAssets,
            manifestEntries: inventory.discoveredRendererAssets
        )
        let conditionalAudit = IOSLocalRendererConditionalGateAudit(
            renderedBlocks: [],
            discoveredRendererAssetPaths: inventory.discoveredRendererAssetPaths,
            rendererAssetManifestHashAudit: manifestAudit
        )

        XCTAssertEqual(inventory.discoveredRendererAssetPaths, [
            "ios/Sources/FastMDMobileCore/LooseRenderers/renderer.html",
            "ios/Sources/FastMDMobileCore/LooseRenderers/renderer.js"
        ])
        XCTAssertEqual(inventory.discoveredRendererAssets.count, 2)
        XCTAssertTrue(inventory.discoveredRendererAssets.allSatisfy(\.isPlatformLocalIOSPath))
        XCTAssertFalse(inventory.discoveredRendererAssets.allSatisfy(\.isBundledRendererResourcePath))
        XCTAssertEqual(inventory.scannedSwiftFileCount, 1)
        XCTAssertFalse(inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(inventory.provesNativeFallbackInventory)
        XCTAssertFalse(manifestAudit.allAssetsUseBundledRendererResourcePaths)
        XCTAssertFalse(manifestAudit.satisfiesStageOneManifestHashVerification)
        XCTAssertEqual(conditionalAudit.localRendererPackagingGateStatus, .requiredButMissing)
        XCTAssertEqual(conditionalAudit.rendererAssetManifestHashGateStatus, .requiredButMissing)
        XCTAssertFalse(conditionalAudit.satisfiesStageOneConditionalRendererGates)
    }

    func testIOSL11RendererAssetInventoryDetectsBundleAssetsAndWebKitSource() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let assetRoot = root
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("FastMDRenderers", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: assetRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: sourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        let scriptData = Data("console.log('offline-renderer')".utf8)
        let styleData = Data(".math { display: inline; }".utf8)
        try scriptData.write(to: assetRoot.appendingPathComponent("renderer.js"))
        try styleData.write(to: assetRoot.appendingPathComponent("style.css"))
        try """
        import Foundation
        import WebKit

        struct LocalRendererProbe {}
        """.write(
            to: sourceRoot.appendingPathComponent("Probe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)

        XCTAssertEqual(inventory.discoveredRendererAssetPaths, [
            "ios/Resources/FastMDRenderers/renderer.js",
            "ios/Resources/FastMDRenderers/style.css"
        ])
        XCTAssertEqual(inventory.discoveredRendererAssets.count, 2)
        XCTAssertTrue(inventory.discoveredRendererAssets.allSatisfy(\.isPlatformLocalIOSPath))
        XCTAssertTrue(inventory.discoveredRendererAssets.allSatisfy(\.isBundledRendererResourcePath))
        XCTAssertEqual(inventory.scannedSwiftFileCount, 1)
        XCTAssertTrue(inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(inventory.provesNativeFallbackInventory)
    }

    func testIOSL11RendererAssetInventoryDetectsWhitespaceTolerantWebKitSource() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: sourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        try """
        import Foundation

        let rendererGateLabel = "WKWebView request blocking"
        """.write(
            to: sourceRoot.appendingPathComponent("ReportStringOnly.swift"),
            atomically: true,
            encoding: .utf8
        )
        XCTAssertFalse(IOSRendererAssetInventory.discover(iosRoot: root).importsWebKitRichRendererCode)

        try """
        import   WebKit

        struct WhitespaceRendererProbe {
            func makeView() {
                _ = WKWebView (frame: .zero)
            }
        }
        """.write(
            to: sourceRoot.appendingPathComponent("WhitespaceWebRenderer.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)

        XCTAssertEqual(inventory.scannedSwiftFileCount, 2)
        XCTAssertTrue(inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(inventory.provesNativeFallbackInventory)
    }

    func testIOSL11RendererAssetInventoryDetectsQualifiedAndAttributedWebKitImports() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: sourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        try """
        import Foundation
        @_implementationOnly import class WebKit.WKWebView

        struct QualifiedWebRendererProbe {}
        """.write(
            to: sourceRoot.appendingPathComponent("QualifiedWebRenderer.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)

        XCTAssertEqual(inventory.scannedSwiftFileCount, 1)
        XCTAssertTrue(inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(inventory.provesNativeFallbackInventory)
    }

    func testIOSL11RendererAssetInventoryFindsDeepBundledRendererAssets() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let deepAssetRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("FastMDRenderers", isDirectory: true)
            .appendingPathComponent("math", isDirectory: true)
            .appendingPathComponent("fonts", isDirectory: true)
            .appendingPathComponent("katex", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: deepAssetRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        try Data("font-bytes".utf8).write(
            to: deepAssetRoot.appendingPathComponent("katex-main.woff2")
        )
        try """
        import Foundation

        struct DeepRendererAssetProbe {}
        """.write(
            to: sourceRoot.appendingPathComponent("DeepRendererAssetProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)

        XCTAssertEqual(inventory.discoveredRendererAssetPaths, [
            "ios/Sources/FastMDMobileCore/Resources/FastMDRenderers/math/fonts/katex/katex-main.woff2"
        ])
        XCTAssertEqual(inventory.discoveredRendererAssets.count, 1)
        XCTAssertTrue(inventory.discoveredRendererAssets.allSatisfy(\.isBundledRendererResourcePath))
        XCTAssertEqual(inventory.scannedSwiftFileCount, 1)
        XCTAssertFalse(inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(inventory.provesNativeFallbackInventory)
    }

    func testIOSL11RendererAssetInventoryScansAllIOSTargetSourcesByDefault() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appSourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobile", isDirectory: true)
            .appendingPathComponent("Features", isDirectory: true)
            .appendingPathComponent("Reader", isDirectory: true)
        let coreSourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: appSourceRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: coreSourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        try """
        import Foundation

        struct CoreProbe {}
        """.write(
            to: coreSourceRoot.appendingPathComponent("CoreProbe.swift"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import SwiftUI
        import WebKit

        struct ReaderRichRendererProbe {}
        """.write(
            to: appSourceRoot.appendingPathComponent("ReaderRichRendererProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)

        XCTAssertEqual(inventory.scannedSwiftFileCount, 2)
        XCTAssertTrue(inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(inventory.provesNativeFallbackInventory)
    }

    func testIOSL11RendererAssetManifestEntriesRequireBundledResourcePaths() {
        let data = Data("renderer".utf8)
        let resourceAsset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let appTargetResourceAsset = IOSRendererAssetManifestEntry(
            path: "ios/Sources/FastMDMobile/Resources/FastMDRenderers/mermaid.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let targetResourceAsset = IOSRendererAssetManifestEntry(
            path: "ios/Sources/FastMDMobileCore/Resources/FastMDRenderers/math.css",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let looseAsset = IOSRendererAssetManifestEntry(
            path: "ios/docs/reports/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let queryAsset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js?cache=1",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let fragmentAsset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js#hash",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let whitespaceAsset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer .js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )

        XCTAssertTrue(resourceAsset.isPlatformLocalIOSPath)
        XCTAssertTrue(resourceAsset.isBundledRendererResourcePath)
        XCTAssertTrue(appTargetResourceAsset.isPlatformLocalIOSPath)
        XCTAssertTrue(appTargetResourceAsset.isBundledRendererResourcePath)
        XCTAssertTrue(targetResourceAsset.isPlatformLocalIOSPath)
        XCTAssertTrue(targetResourceAsset.isBundledRendererResourcePath)
        XCTAssertTrue(looseAsset.isPlatformLocalIOSPath)
        XCTAssertFalse(looseAsset.isBundledRendererResourcePath)
        XCTAssertFalse(queryAsset.isPlatformLocalIOSPath)
        XCTAssertFalse(queryAsset.isBundledRendererResourcePath)
        XCTAssertFalse(fragmentAsset.isPlatformLocalIOSPath)
        XCTAssertFalse(fragmentAsset.isBundledRendererResourcePath)
        XCTAssertFalse(whitespaceAsset.isPlatformLocalIOSPath)
        XCTAssertFalse(whitespaceAsset.isBundledRendererResourcePath)
    }

    func testIOSL11RendererAssetInventoryAcceptsAppTargetBundledRendererAssets() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appAssetRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobile", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("FastMDRenderers", isDirectory: true)
            .appendingPathComponent("mermaid", isDirectory: true)
        let appSourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobile", isDirectory: true)
        try FileManager.default.createDirectory(
            at: appAssetRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        let rendererData = Data("console.log('fastmd-app-target-renderer')".utf8)
        try rendererData.write(to: appAssetRoot.appendingPathComponent("mermaid.js"))
        try """
        import SwiftUI

        struct AppTargetRendererResourceProbe {}
        """.write(
            to: appSourceRoot.appendingPathComponent("AppTargetRendererResourceProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)
        let discoveredAsset = try XCTUnwrap(inventory.discoveredRendererAssets.first)
        let manifestAudit = IOSRendererAssetManifestHashAudit(
            discoveredAssets: inventory.discoveredRendererAssets,
            manifestEntries: inventory.discoveredRendererAssets
        )

        XCTAssertEqual(inventory.discoveredRendererAssetPaths, [
            "ios/Sources/FastMDMobile/Resources/FastMDRenderers/mermaid/mermaid.js"
        ])
        XCTAssertEqual(discoveredAsset.byteCount, rendererData.count)
        XCTAssertTrue(discoveredAsset.isPlatformLocalIOSPath)
        XCTAssertTrue(discoveredAsset.isBundledRendererResourcePath)
        XCTAssertFalse(inventory.importsWebKitRichRendererCode)
        XCTAssertEqual(inventory.scannedSwiftFileCount, 1)
        XCTAssertTrue(manifestAudit.satisfiesStageOneManifestHashVerification)
    }

    func testIOSL11RendererAssetInventoryTreatsJavaScriptModulesAsRendererAssets() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let assetRoot = root
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("FastMDRenderers", isDirectory: true)
            .appendingPathComponent("math", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: assetRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: sourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        let moduleData = Data("export const renderMath = () => 'fastmd';".utf8)
        try moduleData.write(to: assetRoot.appendingPathComponent("math-renderer.mjs"))
        try """
        import Foundation

        struct JavaScriptModuleAssetProbe {}
        """.write(
            to: sourceRoot.appendingPathComponent("JavaScriptModuleAssetProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)
        let discoveredAsset = try XCTUnwrap(inventory.discoveredRendererAssets.first)
        let manifestAudit = IOSRendererAssetManifestHashAudit(
            discoveredAssets: inventory.discoveredRendererAssets,
            manifestEntries: inventory.discoveredRendererAssets
        )

        XCTAssertTrue(IOSRendererAssetInventory.rendererAssetFileExtensions.contains("mjs"))
        XCTAssertTrue(IOSRendererAssetInventory.defaultInventoryCommand.contains("*.mjs"))
        XCTAssertEqual(inventory.discoveredRendererAssetPaths, [
            "ios/Resources/FastMDRenderers/math/math-renderer.mjs"
        ])
        XCTAssertEqual(discoveredAsset.byteCount, moduleData.count)
        XCTAssertEqual(discoveredAsset.sha256Hex, IOSRendererAssetInventory.sha256Hex(for: moduleData))
        XCTAssertTrue(discoveredAsset.isBundledRendererResourcePath)
        XCTAssertTrue(manifestAudit.satisfiesStageOneManifestHashVerification)
    }

    func testIOSL11RendererAssetInventoryTreatsHTMDocumentsAsRendererAssets() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let assetRoot = root
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("FastMDRenderers", isDirectory: true)
            .appendingPathComponent("details", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try FileManager.default.createDirectory(
            at: assetRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: sourceRoot,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        let htmlData = Data("<!doctype html><title>FastMD local renderer</title>".utf8)
        try htmlData.write(to: assetRoot.appendingPathComponent("details-renderer.htm"))
        try """
        import Foundation

        struct HTMRendererAssetProbe {}
        """.write(
            to: sourceRoot.appendingPathComponent("HTMRendererAssetProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)
        let discoveredAsset = try XCTUnwrap(inventory.discoveredRendererAssets.first)
        let manifestAudit = IOSRendererAssetManifestHashAudit(
            discoveredAssets: inventory.discoveredRendererAssets,
            manifestEntries: inventory.discoveredRendererAssets
        )

        XCTAssertTrue(IOSRendererAssetInventory.rendererAssetFileExtensions.contains("htm"))
        XCTAssertTrue(IOSRendererAssetInventory.defaultInventoryCommand.contains("*.htm"))
        XCTAssertEqual(inventory.discoveredRendererAssetPaths, [
            "ios/Resources/FastMDRenderers/details/details-renderer.htm"
        ])
        XCTAssertEqual(discoveredAsset.byteCount, htmlData.count)
        XCTAssertEqual(discoveredAsset.sha256Hex, IOSRendererAssetInventory.sha256Hex(for: htmlData))
        XCTAssertTrue(discoveredAsset.isPlatformLocalIOSPath)
        XCTAssertTrue(discoveredAsset.isBundledRendererResourcePath)
        XCTAssertTrue(manifestAudit.satisfiesStageOneManifestHashVerification)
    }

    func testIOSL11ConditionalRendererAuditRejectsUnsafeRawAssetPaths() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let validAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["ios/Resources/FastMDRenderers/renderer.js"],
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [
                    IOSRendererAssetManifestEntry(
                        path: "ios/Resources/FastMDRenderers/renderer.js",
                        byteCount: 8,
                        sha256Hex: String(repeating: "a", count: 64)
                    )
                ],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )
        let traversalAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["ios/Resources/FastMDRenderers/../renderer.js"]
        )
        let remoteAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["https://cdn.example.com/renderer.js"]
        )
        let backslashAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["ios\\Resources\\FastMDRenderers\\renderer.js"]
        )
        let queryAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["ios/Resources/FastMDRenderers/renderer.js?cache=1"]
        )
        let fragmentAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["ios/Resources/FastMDRenderers/renderer.js#hash"]
        )
        let whitespaceAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["ios/Resources/FastMDRenderers/renderer .js"]
        )
        let percentEscapedTraversalAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["ios/Resources/FastMDRenderers/%2e%2e/renderer.js"]
        )
        let colonAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["ios/Resources/FastMDRenderers/file:renderer.js"]
        )
        let controlCharacterAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: ["ios/Resources/FastMDRenderers/renderer\u{0000}.js"]
        )

        XCTAssertTrue(validAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertTrue(validAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(validAudit.localRendererPackagingGateStatus, .requiredAndSatisfied)

        XCTAssertFalse(traversalAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertTrue(traversalAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(traversalAudit.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertFalse(remoteAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertFalse(remoteAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(remoteAudit.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertFalse(backslashAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertFalse(backslashAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(backslashAudit.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertFalse(queryAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertTrue(queryAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(queryAudit.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertFalse(fragmentAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertTrue(fragmentAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(fragmentAudit.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertFalse(whitespaceAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertTrue(whitespaceAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(whitespaceAudit.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertFalse(percentEscapedTraversalAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertTrue(percentEscapedTraversalAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(percentEscapedTraversalAudit.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertFalse(colonAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertTrue(colonAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(colonAudit.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertFalse(controlCharacterAudit.rendererAssetPathsArePlatformLocal)
        XCTAssertTrue(controlCharacterAudit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(controlCharacterAudit.localRendererPackagingGateStatus, .requiredButMissing)
    }

    func testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest() {
        let scriptData = Data("console.log('fastmd-local-renderer')".utf8)
        let styleData = Data(".math { display: inline; }".utf8)
        let discoveredAssets = [
            IOSRendererAssetManifestEntry(
                path: "ios/Resources/FastMDRenderers/math.css",
                byteCount: styleData.count,
                sha256Hex: IOSRendererAssetInventory.sha256Hex(for: styleData)
            ),
            IOSRendererAssetManifestEntry(
                path: "ios/Resources/FastMDRenderers/mermaid.js",
                byteCount: scriptData.count,
                sha256Hex: IOSRendererAssetInventory.sha256Hex(for: scriptData)
            )
        ]
        let audit = IOSRendererAssetManifestHashAudit(
            discoveredAssets: discoveredAssets,
            manifestEntries: discoveredAssets.reversed()
        )

        XCTAssertTrue(audit.hasDiscoveredRendererAssets)
        XCTAssertTrue(audit.manifestHasNoDuplicatePaths)
        XCTAssertTrue(audit.manifestPathsExactlyMatchDiscoveredAssets)
        XCTAssertTrue(audit.allAssetsStayPlatformLocal)
        XCTAssertTrue(audit.allAssetsUseBundledRendererResourcePaths)
        XCTAssertTrue(audit.allManifestEntriesHaveValidHashesAndByteCounts)
        XCTAssertTrue(audit.manifestHashesMatchDiscoveredAssets)
        XCTAssertEqual(audit.failureReasons, [])
        XCTAssertTrue(audit.satisfiesStageOneManifestHashVerification)
    }

    func testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries() {
        let data = Data("renderer".utf8)
        let discoveredAsset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let missingManifest = IOSRendererAssetManifestHashAudit(
            discoveredAssets: [discoveredAsset],
            manifestEntries: []
        )
        let tamperedManifest = IOSRendererAssetManifestHashAudit(
            discoveredAssets: [discoveredAsset],
            manifestEntries: [
                IOSRendererAssetManifestEntry(
                    path: discoveredAsset.path,
                    byteCount: discoveredAsset.byteCount,
                    sha256Hex: String(repeating: "0", count: 64)
                )
            ]
        )
        let remoteManifest = IOSRendererAssetManifestHashAudit(
            discoveredAssets: [
                IOSRendererAssetManifestEntry(
                    path: "https://cdn.example.com/renderer.js",
                    byteCount: data.count,
                    sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
                )
            ],
            manifestEntries: [
                IOSRendererAssetManifestEntry(
                    path: "https://cdn.example.com/renderer.js",
                    byteCount: data.count,
                    sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
                )
            ]
        )

        XCTAssertFalse(missingManifest.satisfiesStageOneManifestHashVerification)
        XCTAssertFalse(tamperedManifest.satisfiesStageOneManifestHashVerification)
        XCTAssertEqual(
            tamperedManifest.failureReasons,
            ["manifest hashes or byte counts do not match discovered assets"]
        )
        XCTAssertFalse(remoteManifest.allAssetsStayPlatformLocal)
        XCTAssertFalse(remoteManifest.allAssetsUseBundledRendererResourcePaths)
        XCTAssertEqual(
            remoteManifest.failureReasons,
            [
                "asset paths are not iOS-local",
                "assets are outside bundled FastMDRenderers resources"
            ]
        )
        XCTAssertFalse(remoteManifest.satisfiesStageOneManifestHashVerification)
    }

    func testIOSL11RendererAssetManifestHashAuditRejectsDuplicateManifestPaths() {
        let data = Data("renderer".utf8)
        let discoveredAsset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let audit = IOSRendererAssetManifestHashAudit(
            discoveredAssets: [discoveredAsset],
            manifestEntries: [discoveredAsset, discoveredAsset]
        )

        XCTAssertFalse(audit.manifestHasNoDuplicatePaths)
        XCTAssertTrue(audit.allAssetsStayPlatformLocal)
        XCTAssertTrue(audit.allAssetsUseBundledRendererResourcePaths)
        XCTAssertTrue(audit.allManifestEntriesHaveValidHashesAndByteCounts)
        XCTAssertEqual(
            audit.failureReasons,
            [
                "duplicate manifest paths",
                "manifest paths do not exactly match discovered assets",
                "manifest hashes or byte counts do not match discovered assets"
            ]
        )
        XCTAssertFalse(audit.satisfiesStageOneManifestHashVerification)
    }

    func testIOSL11RendererAssetManifestHashAuditRejectsLooseLocalAssetPaths() {
        let data = Data("renderer".utf8)
        let looseAsset = IOSRendererAssetManifestEntry(
            path: "ios/docs/reports/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let audit = IOSRendererAssetManifestHashAudit(
            discoveredAssets: [looseAsset],
            manifestEntries: [looseAsset]
        )

        XCTAssertTrue(audit.allAssetsStayPlatformLocal)
        XCTAssertFalse(audit.allAssetsUseBundledRendererResourcePaths)
        XCTAssertFalse(audit.satisfiesStageOneManifestHashVerification)
    }

    func testIOSL11RendererAssetManifestHashAuditRejectsQueryFragmentAndWhitespacePaths() {
        let data = Data("renderer".utf8)
        let unsafeAssets = [
            IOSRendererAssetManifestEntry(
                path: "ios/Resources/FastMDRenderers/renderer.js?cache=1",
                byteCount: data.count,
                sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
            ),
            IOSRendererAssetManifestEntry(
                path: "ios/Resources/FastMDRenderers/renderer.js#hash",
                byteCount: data.count,
                sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
            ),
            IOSRendererAssetManifestEntry(
                path: "ios/Resources/FastMDRenderers/renderer .js",
                byteCount: data.count,
                sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
            ),
            IOSRendererAssetManifestEntry(
                path: " ios/Resources/FastMDRenderers/renderer.js",
                byteCount: data.count,
                sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
            )
        ]

        for unsafeAsset in unsafeAssets {
            let audit = IOSRendererAssetManifestHashAudit(
                discoveredAssets: [unsafeAsset],
                manifestEntries: [unsafeAsset]
            )

            XCTAssertFalse(
                unsafeAsset.isPlatformLocalIOSPath,
                "Expected unsafe manifest path to fail platform-local validation: \(unsafeAsset.path)"
            )
            XCTAssertFalse(
                unsafeAsset.isBundledRendererResourcePath,
                "Expected unsafe manifest path to fail bundled-resource validation: \(unsafeAsset.path)"
            )
            XCTAssertFalse(audit.allAssetsStayPlatformLocal)
            XCTAssertFalse(audit.allAssetsUseBundledRendererResourcePaths)
            XCTAssertTrue(audit.failureReasons.contains("asset paths are not iOS-local"))
            XCTAssertTrue(audit.failureReasons.contains("assets are outside bundled FastMDRenderers resources"))
            XCTAssertFalse(audit.satisfiesStageOneManifestHashVerification)
        }
    }

    func testIOSL11RendererBundleResourceDeclarationAuditRequiresPackageResourceCoverage() {
        let data = Data("renderer".utf8)
        let rootAsset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let appTargetAsset = IOSRendererAssetManifestEntry(
            path: "ios/Sources/FastMDMobile/Resources/FastMDRenderers/mermaid/mermaid.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let undeclared = IOSRendererBundleResourceDeclarationAudit(
            discoveredAssets: [rootAsset],
            declaredBundledRendererResourceRoots: []
        )
        let exactRootDeclared = IOSRendererBundleResourceDeclarationAudit(
            discoveredAssets: [rootAsset],
            declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
        )
        let appTargetRootDeclared = IOSRendererBundleResourceDeclarationAudit(
            discoveredAssets: [appTargetAsset],
            declaredBundledRendererResourceRoots: ["ios/Sources/FastMDMobile/Resources/FastMDRenderers"]
        )

        XCTAssertEqual(undeclared.requiredBundledRendererResourceRoots, ["ios/Resources/FastMDRenderers"])
        XCTAssertFalse(undeclared.declaredRootsCoverDiscoveredAssets)
        XCTAssertFalse(undeclared.satisfiesStageOneBundleResourceDeclaration)
        XCTAssertTrue(
            undeclared.failureReasons.contains(
                "Package.swift resource declarations do not cover discovered renderer assets"
            )
        )

        XCTAssertTrue(exactRootDeclared.declaredRootsCoverDiscoveredAssets)
        XCTAssertTrue(exactRootDeclared.satisfiesStageOneBundleResourceDeclaration)
        XCTAssertEqual(
            appTargetRootDeclared.requiredBundledRendererResourceRoots,
            ["ios/Sources/FastMDMobile/Resources/FastMDRenderers"]
        )
        XCTAssertTrue(appTargetRootDeclared.satisfiesStageOneBundleResourceDeclaration)
    }

    func testIOSL11RendererAssetInventoryReadsSwiftPMRendererResourceDeclarations() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("FastMDRendererResourceDeclarations-\(UUID().uuidString)")
        let rendererRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("FastMDRenderers", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        try fileManager.createDirectory(at: rendererRoot, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        try """
        // swift-tools-version: 5.7

        import PackageDescription

        let package = Package(
            name: "FastMDMobile",
            targets: [
                .target(
                    name: "FastMDMobileCore",
                    resources: [.process("Resources/FastMDRenderers")]
                )
            ]
        )
        """.write(
            to: root.appendingPathComponent("Package.swift"),
            atomically: true,
            encoding: .utf8
        )
        try "console.log('renderer')".write(
            to: rendererRoot.appendingPathComponent("renderer.js"),
            atomically: true,
            encoding: .utf8
        )
        try "struct NativeFallbackProbe {}".write(
            to: sourceRoot.appendingPathComponent("NativeFallbackProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)
        let declarationAudit = IOSRendererBundleResourceDeclarationAudit(
            discoveredAssets: inventory.discoveredRendererAssets,
            declaredBundledRendererResourceRoots: inventory.declaredBundledRendererResourceRoots
        )

        XCTAssertEqual(
            inventory.discoveredRendererAssetPaths,
            ["ios/Sources/FastMDMobileCore/Resources/FastMDRenderers/renderer.js"]
        )
        XCTAssertEqual(
            inventory.declaredBundledRendererResourceRoots,
            [
                "ios/Sources/FastMDMobile/Resources/FastMDRenderers",
                "ios/Sources/FastMDMobileCore/Resources/FastMDRenderers"
            ]
        )
        XCTAssertTrue(declarationAudit.satisfiesStageOneBundleResourceDeclaration)
    }

    func testIOSL11RendererAssetInventoryIgnoresCommentedSwiftPMRendererResourceDeclarations() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("FastMDRendererCommentedResourceDeclarations-\(UUID().uuidString)")
        let rendererRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("FastMDRenderers", isDirectory: true)
        let sourceRoot = root
            .appendingPathComponent("Sources", isDirectory: true)
            .appendingPathComponent("FastMDMobileCore", isDirectory: true)
        let packageURL = root.appendingPathComponent("Package.swift")
        try fileManager.createDirectory(at: rendererRoot, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        try """
        // swift-tools-version: 5.7

        import PackageDescription

        let package = Package(
            name: "FastMDMobile",
            targets: [
                .target(
                    name: "FastMDMobileCore"
                    // resources: [.process("Resources/FastMDRenderers")]
                    /*
                    resources: [.copy("Resources/FastMDRenderers")]
                    */
                )
            ]
        )
        """.write(to: packageURL, atomically: true, encoding: .utf8)
        try "console.log('renderer')".write(
            to: rendererRoot.appendingPathComponent("renderer.js"),
            atomically: true,
            encoding: .utf8
        )
        try "struct NativeFallbackProbe {}".write(
            to: sourceRoot.appendingPathComponent("NativeFallbackProbe.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(iosRoot: root)
        let declarationAudit = IOSRendererBundleResourceDeclarationAudit(
            discoveredAssets: inventory.discoveredRendererAssets,
            declaredBundledRendererResourceRoots: inventory.declaredBundledRendererResourceRoots
        )

        XCTAssertEqual(inventory.declaredBundledRendererResourceRoots, [])
        XCTAssertFalse(declarationAudit.satisfiesStageOneBundleResourceDeclaration)
        XCTAssertTrue(
            declarationAudit.failureReasons.contains(
                "Package.swift resource declarations do not cover discovered renderer assets"
            )
        )

        try """
        // swift-tools-version: 5.7

        import PackageDescription

        let package = Package(
            name: "FastMDMobile",
            targets: [
                .target(
                    name: "FastMDMobileCore",
                    resources: [.process("Resources/FastMDRenderers")]
                )
            ]
        )
        """.write(to: packageURL, atomically: true, encoding: .utf8)

        let declaredInventory = IOSRendererAssetInventory.discover(iosRoot: root)
        let declaredAudit = IOSRendererBundleResourceDeclarationAudit(
            discoveredAssets: declaredInventory.discoveredRendererAssets,
            declaredBundledRendererResourceRoots: declaredInventory.declaredBundledRendererResourceRoots
        )

        XCTAssertTrue(
            declaredInventory.declaredBundledRendererResourceRoots.contains(
                "ios/Sources/FastMDMobileCore/Resources/FastMDRenderers"
            )
        )
        XCTAssertTrue(declaredAudit.satisfiesStageOneBundleResourceDeclaration)
    }

    func testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let data = Data("renderer".utf8)
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let missingHashAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: [asset.path],
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )
        let verifiedHashAudit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )

        XCTAssertEqual(missingHashAudit.localRendererPackagingGateStatus, .requiredAndSatisfied)
        XCTAssertEqual(missingHashAudit.rendererAssetManifestHashGateStatus, .requiredButMissing)
        XCTAssertFalse(missingHashAudit.satisfiesStageOneConditionalRendererGates)

        XCTAssertEqual(verifiedHashAudit.localRendererPackagingGateStatus, .requiredAndSatisfied)
        XCTAssertEqual(verifiedHashAudit.rendererAssetManifestHashGateStatus, .requiredAndSatisfied)
        XCTAssertTrue(verifiedHashAudit.satisfiesStageOneConditionalRendererGates)
    }

    func testIOSL11ConditionalRendererPackagingGateRejectsLooseLocalAssets() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let data = Data("renderer".utf8)
        let looseAsset = IOSRendererAssetManifestEntry(
            path: "ios/docs/reports/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: [looseAsset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [looseAsset],
                manifestEntries: [looseAsset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [looseAsset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )

        XCTAssertTrue(audit.rendererAssetPathsArePlatformLocal)
        XCTAssertFalse(audit.rendererAssetPathsAreBundledResources)
        XCTAssertEqual(audit.localRendererPackagingGateStatus, .requiredButMissing)
        XCTAssertEqual(audit.rendererAssetManifestHashGateStatus, .requiredButMissing)
        XCTAssertFalse(audit.satisfiesStageOneConditionalRendererGates)
    }

    func testIOSL11ConditionalRendererPackagingGateRequiresDeclaredAssetsToMatchDiscoveredBundleAssets() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let data = Data("renderer".utf8)
        let scriptAsset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let styleAsset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.css",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )

        let missingDeclaredScript = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: LocalRichRendererRuntimeAudit(
                policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
                declaredAssetNames: ["renderer.css"]
            ),
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: [scriptAsset.path, styleAsset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [scriptAsset, styleAsset],
                manifestEntries: [scriptAsset, styleAsset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [scriptAsset, styleAsset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )
        let declaredButUndiscoveredStyle = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: LocalRichRendererRuntimeAudit(
                policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
                declaredAssetNames: ["renderer.js", "renderer.css"]
            ),
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: [scriptAsset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [scriptAsset],
                manifestEntries: [scriptAsset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [scriptAsset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )
        let matchingDeclarations = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: LocalRichRendererRuntimeAudit(
                policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
                declaredAssetNames: ["renderer.js", "renderer.css"]
            ),
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: [scriptAsset.path, styleAsset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [scriptAsset, styleAsset],
                manifestEntries: [scriptAsset, styleAsset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [scriptAsset, styleAsset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )

        XCTAssertFalse(missingDeclaredScript.declaredRendererAssetNamesMatchDiscoveredBundledAssets)
        XCTAssertEqual(missingDeclaredScript.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertFalse(declaredButUndiscoveredStyle.declaredRendererAssetNamesMatchDiscoveredBundledAssets)
        XCTAssertEqual(declaredButUndiscoveredStyle.localRendererPackagingGateStatus, .requiredButMissing)

        XCTAssertTrue(matchingDeclarations.declaredRendererAssetNamesMatchDiscoveredBundledAssets)
        XCTAssertEqual(matchingDeclarations.localRendererPackagingGateStatus, .requiredAndSatisfied)
        XCTAssertEqual(matchingDeclarations.rendererAssetManifestHashGateStatus, .requiredAndSatisfied)
        XCTAssertTrue(matchingDeclarations.satisfiesStageOneConditionalRendererGates)
    }

    func testIOSL11ConditionalRendererPackagingGateRequiresSwiftPMBundleResourceDeclaration() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let data = Data("renderer".utf8)
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let undeclaredBundleResource = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: []
            )
        )
        let declaredBundleResource = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )

        XCTAssertFalse(undeclaredBundleResource.rendererAssetsAreDeclaredBundleResources)
        XCTAssertEqual(undeclaredBundleResource.localRendererPackagingGateStatus, .requiredButMissing)
        XCTAssertFalse(undeclaredBundleResource.satisfiesStageOneConditionalRendererGates)

        XCTAssertTrue(declaredBundleResource.rendererAssetsAreDeclaredBundleResources)
        XCTAssertEqual(declaredBundleResource.localRendererPackagingGateStatus, .requiredAndSatisfied)
        XCTAssertTrue(declaredBundleResource.satisfiesStageOneConditionalRendererGates)
    }

    func testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces() {
        let unsafeWKWebViewBlock = makeRichFallbackBlock(
            surface: .localWKWebView,
            rendersAsNativeSafeCard: false,
            requiresVendoredRendererAssets: true,
            allowsNetworkRequests: true,
            allowsExternalNavigation: false,
            allowsRemoteSubresources: true
        )
        let releasePosture = IOSReleaseSecurityPosture(
            usesWKWebViewRichRendering: true,
            localRendererPolicy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers")
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            releasePosture: releasePosture,
            renderedBlocks: [unsafeWKWebViewBlock],
            discoveredRendererAssetPaths: ["ios/Resources/FastMDRenderers/renderer.js"]
        )

        XCTAssertTrue(audit.usesWKWebViewRichSurface)
        XCTAssertFalse(audit.wkWebViewRichSurfacesAreRequestBlocked)
        XCTAssertFalse(audit.wkWebViewRequestPolicyBlocksForbiddenRequests)
        XCTAssertFalse(audit.richFallbackSurfacesSatisfyRendererPolicy)
        XCTAssertEqual(audit.wkWebViewRequestBlockingGateStatus, .blockedUnsafeWKWebView)
        XCTAssertFalse(audit.satisfiesStageOneConditionalRendererGates)
    }

    func testIOSL11ConditionalRendererWKWebViewGateRequiresExplicitRequestPolicy() {
        let data = Data("renderer".utf8)
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let safeWKWebViewBlock = makeRichFallbackBlock(
            surface: .localWKWebView,
            rendersAsNativeSafeCard: false,
            requiresVendoredRendererAssets: true,
            allowsNetworkRequests: false,
            allowsExternalNavigation: false,
            allowsRemoteSubresources: false
        )
        let releasePosture = IOSReleaseSecurityPosture(
            usesWKWebViewRichRendering: true,
            localRendererPolicy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers")
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            releasePosture: releasePosture,
            renderedBlocks: [safeWKWebViewBlock],
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            )
        )

        XCTAssertTrue(audit.usesWKWebViewRichSurface)
        XCTAssertTrue(audit.wkWebViewRichSurfacesAreRequestBlocked)
        XCTAssertFalse(audit.wkWebViewRequestPolicyBlocksForbiddenRequests)
        XCTAssertFalse(audit.richFallbackSurfacesSatisfyRendererPolicy)
        XCTAssertEqual(audit.wkWebViewRequestBlockingGateStatus, .blockedUnsafeWKWebView)
        XCTAssertFalse(audit.satisfiesStageOneConditionalRendererGates)
    }

    func testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface() {
        let data = Data("renderer".utf8)
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let safeWKWebViewBlock = makeRichFallbackBlock(
            surface: .localWKWebView,
            rendersAsNativeSafeCard: false,
            requiresVendoredRendererAssets: true,
            allowsNetworkRequests: false,
            allowsExternalNavigation: false,
            allowsRemoteSubresources: false
        )
        let releasePosture = IOSReleaseSecurityPosture(
            usesWKWebViewRichRendering: true,
            localRendererPolicy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers")
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            releasePosture: releasePosture,
            renderedBlocks: [safeWKWebViewBlock],
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            ),
            wkWebViewRequestBlockingPolicy: wkWebViewRequestBlockingPolicy()
        )

        XCTAssertTrue(audit.usesWKWebViewRichSurface)
        XCTAssertTrue(audit.wkWebViewRichSurfacesAreRequestBlocked)
        XCTAssertTrue(audit.wkWebViewRequestPolicyBlocksForbiddenRequests)
        XCTAssertTrue(audit.richFallbackSurfacesSatisfyRendererPolicy)
        XCTAssertEqual(audit.localRendererPackagingGateStatus, .requiredAndSatisfied)
        XCTAssertEqual(audit.wkWebViewRequestBlockingGateStatus, .requiredAndSatisfied)
        XCTAssertEqual(audit.rendererAssetManifestHashGateStatus, .requiredAndSatisfied)
        XCTAssertTrue(audit.satisfiesStageOneConditionalRendererGates)
    }

    func testIOSL11ConditionalRendererReportCapturesSatisfiedVendoredAssetMode() {
        let data = Data("renderer".utf8)
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: [],
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )
        let inventory = IOSRendererAssetInventory(
            discoveredRendererAssets: [asset],
            declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"],
            scannedSwiftFileCount: 1,
            importsWebKitRichRendererCode: false
        )
        let report = IOSConditionalRendererGateReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_350),
            evidence: audit.checklistEvidence,
            inventory: inventory
        )

        XCTAssertTrue(audit.satisfiesStageOneConditionalRendererGates)
        XCTAssertNil(audit.checklistEvidence.nativeFallbackNotApplicableReason)
        XCTAssertTrue(audit.checklistEvidence.capturesSatisfiedRendererModeEvidence)
        XCTAssertTrue(report.capturesConditionalRendererGateEvidence)
        XCTAssertTrue(report.markdown.contains("Uses vendored renderer assets: true"))
        XCTAssertTrue(report.markdown.contains("Uses WKWebView rich surface: false"))
        XCTAssertTrue(report.markdown.contains("renderer asset manifest/hash | requiredAndSatisfied | true"))
    }

    func testIOSL11ConditionalRendererReportCapturesSatisfiedWKWebViewMode() {
        let data = Data("renderer".utf8)
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let safeWKWebViewBlock = makeRichFallbackBlock(
            surface: .localWKWebView,
            rendersAsNativeSafeCard: false,
            requiresVendoredRendererAssets: true,
            allowsNetworkRequests: false,
            allowsExternalNavigation: false,
            allowsRemoteSubresources: false
        )
        let releasePosture = IOSReleaseSecurityPosture(
            usesWKWebViewRichRendering: true,
            localRendererPolicy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers")
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            releasePosture: releasePosture,
            renderedBlocks: [safeWKWebViewBlock],
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            ),
            wkWebViewRequestBlockingPolicy: wkWebViewRequestBlockingPolicy()
        )
        let inventory = IOSRendererAssetInventory(
            discoveredRendererAssets: [asset],
            declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"],
            scannedSwiftFileCount: 1,
            importsWebKitRichRendererCode: true
        )
        let report = IOSConditionalRendererGateReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_360),
            evidence: audit.checklistEvidence,
            inventory: inventory
        )

        XCTAssertTrue(audit.satisfiesStageOneConditionalRendererGates)
        XCTAssertTrue(audit.checklistEvidence.capturesSatisfiedRendererModeEvidence)
        XCTAssertTrue(report.capturesConditionalRendererGateEvidence)
        XCTAssertTrue(report.importsWebKitRichRendererCode)
        XCTAssertTrue(report.markdown.contains("Uses vendored renderer assets: true"))
        XCTAssertTrue(report.markdown.contains("Uses WKWebView rich surface: true"))
        XCTAssertTrue(report.markdown.contains("WKWebView request blocking | requiredAndSatisfied | true"))
    }

    func testIOSL11ConditionalRendererReportCapturesNativeFallbackEvidence() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let inventory = rendererAssetInventory()
        let audit = IOSLocalRendererConditionalGateAudit(
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: inventory.discoveredRendererAssetPaths
        )
        let report = IOSConditionalRendererGateReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_804_500),
            evidence: audit.checklistEvidence,
            inventory: inventory
        )

        XCTAssertTrue(report.capturesConditionalRendererGateEvidence)
        XCTAssertTrue(audit.checklistEvidence.allConditionalRendererGatesSatisfied)
        XCTAssertFalse(report.importsWebKitRichRendererCode)
        XCTAssertGreaterThan(report.scannedSwiftFileCount, 0)
        XCTAssertEqual(audit.checklistEvidence.discoveredRendererAssetPaths, [])
        XCTAssertEqual(
            audit.checklistEvidence.nativeFallbackNotApplicableReason,
            "iOS renders rich Markdown fallback blocks as native safe cards; no JS/CSS/font assets or WKWebView rich surface are present."
        )
        XCTAssertTrue(report.markdown.contains("local renderer packaging/offline | notApplicableNativeFallback | true"))
        XCTAssertTrue(report.markdown.contains("WKWebView request blocking | notApplicableNativeFallback | true"))
        XCTAssertTrue(report.markdown.contains("renderer asset manifest/hash | notApplicableNativeFallback | true"))
        XCTAssertTrue(report.markdown.contains("Discovered renderer asset paths: none"))
        XCTAssertTrue(report.markdown.contains("Scanned Swift source files: \(report.scannedSwiftFileCount)"))
        XCTAssertTrue(report.markdown.contains("## Supervisor Completion Recommendations"))
        XCTAssertEqual(
            audit.checklistEvidence.supervisorCompletionRecommendations,
            [
                "Add local renderer packaging/offline tests if JS renderer assets are used.",
                "Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.",
                "Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored."
            ]
        )
        XCTAssertFalse(report.markdown.contains("http://"))
        XCTAssertFalse(report.markdown.contains("https://cdn"))
    }

    func testIOSL11ConditionalRendererReportRejectsNativeFallbackClaimWhenWebKitSourceIsDetected() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let inventory = IOSRendererAssetInventory(
            scannedSwiftFileCount: 1,
            importsWebKitRichRendererCode: true
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: inventory.discoveredRendererAssetPaths
        )
        let report = IOSConditionalRendererGateReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            evidence: audit.checklistEvidence,
            inventory: inventory
        )

        XCTAssertTrue(audit.satisfiesStageOneConditionalRendererGates)
        XCTAssertFalse(report.capturesConditionalRendererGateEvidence)
        XCTAssertTrue(report.markdown.contains("Imports WebKit rich renderer code: true"))
    }

    func testIOSL11RendererInventoryIgnoresWebKitNamesInsideCommentsAndStrings() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("FastMDInventoryFalsePositive-\(UUID().uuidString)")
        let sourceRoot = root.appendingPathComponent("Sources")
        try fileManager.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        let source = """
        // import WebKit
        /*
         let view = WKWebView()
         nested marker: /* WKWebView() */
        */
        let commentText = "import WebKit"
        let typeText = "WKWebView()"
        let multiline = \"\"\"
        import WebKit
        WKWebView()
        \"\"\"
        struct NativeOnlyRenderer {}
        """
        try source.write(
            to: sourceRoot.appendingPathComponent("NativeOnlyRenderer.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(
            iosRoot: root,
            sourceRoot: sourceRoot,
            fileManager: fileManager
        )

        XCTAssertEqual(inventory.scannedSwiftFileCount, 1)
        XCTAssertFalse(inventory.importsWebKitRichRendererCode)
        XCTAssertTrue(inventory.provesNativeFallbackInventory)
    }

    func testIOSL11RendererInventoryIgnoresWebKitNamesInsideRawStrings() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("FastMDInventoryRawStringFalsePositive-\(UUID().uuidString)")
        let sourceRoot = root.appendingPathComponent("Sources")
        try fileManager.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        let source = ###"""
        let rawImportMention = #"documentation " import WebKit stays literal"#
        let rawViewMention = #"documentation " WKWebView() stays literal"#
        let rawMultilineMention = ##"""
        " import WebKit
        " WKWebView()
        """##
        struct NativeOnlyRawStringRenderer {}
        """###
        try source.write(
            to: sourceRoot.appendingPathComponent("NativeOnlyRawStringRenderer.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(
            iosRoot: root,
            sourceRoot: sourceRoot,
            fileManager: fileManager
        )

        XCTAssertEqual(inventory.scannedSwiftFileCount, 1)
        XCTAssertFalse(inventory.importsWebKitRichRendererCode)
        XCTAssertTrue(inventory.provesNativeFallbackInventory)
    }

    func testIOSL11RendererInventoryDetectsRealWebKitImportAndWKWebViewConstruction() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("FastMDInventoryWebKit-\(UUID().uuidString)")
        let sourceRoot = root.appendingPathComponent("Sources")
        try fileManager.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        let source = """
        import Foundation
        import WebKit

        final class RichRendererHost {
            func makeView() {
                _ = WKWebView()
            }
        }
        """
        try source.write(
            to: sourceRoot.appendingPathComponent("RichRendererHost.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(
            iosRoot: root,
            sourceRoot: sourceRoot,
            fileManager: fileManager
        )

        XCTAssertEqual(inventory.scannedSwiftFileCount, 1)
        XCTAssertTrue(inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(inventory.provesNativeFallbackInventory)
    }

    func testIOSL11RendererInventoryDetectsAttributedAndScopedWebKitImports() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory
            .appendingPathComponent("FastMDInventoryScopedWebKit-\(UUID().uuidString)")
        let sourceRoot = root.appendingPathComponent("Sources")
        try fileManager.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        let attributedImportSource = """
        @_implementationOnly import WebKit

        final class AttributedRichRendererHost {}
        """
        let scopedImportSource = """
        import struct WebKit.WKWebView

        final class ScopedRichRendererHost {}
        """
        try attributedImportSource.write(
            to: sourceRoot.appendingPathComponent("AttributedRichRendererHost.swift"),
            atomically: true,
            encoding: .utf8
        )
        try scopedImportSource.write(
            to: sourceRoot.appendingPathComponent("ScopedRichRendererHost.swift"),
            atomically: true,
            encoding: .utf8
        )

        let inventory = IOSRendererAssetInventory.discover(
            iosRoot: root,
            sourceRoot: sourceRoot,
            fileManager: fileManager
        )

        XCTAssertEqual(inventory.scannedSwiftFileCount, 2)
        XCTAssertTrue(inventory.importsWebKitRichRendererCode)
        XCTAssertFalse(inventory.provesNativeFallbackInventory)
    }

    func testIOSL11ConditionalRendererEvidenceBuilderProducesReproducibleNativeFallbackReport() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let evidence = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_805_100)
        ).makeEvidence(renderedBlocks: rendered)

        XCTAssertTrue(evidence.satisfiesStageOneConditionalRendererChecklist)
        XCTAssertTrue(evidence.inventory.provesNativeFallbackInventory)
        XCTAssertTrue(evidence.audit.richFallbacksStayNativeSafeCards)
        XCTAssertEqual(evidence.audit.localRendererPackagingGateStatus, .notApplicableNativeFallback)
        XCTAssertEqual(evidence.audit.wkWebViewRequestBlockingGateStatus, .notApplicableNativeFallback)
        XCTAssertEqual(evidence.audit.rendererAssetManifestHashGateStatus, .notApplicableNativeFallback)
        XCTAssertTrue(evidence.report.markdown.contains("Native fallback reason: iOS renders rich Markdown fallback blocks as native safe cards"))
        XCTAssertTrue(evidence.report.markdown.contains("Renderer asset inventory command: find ios"))
        XCTAssertTrue(evidence.report.markdown.contains("-prune"))
        XCTAssertTrue(evidence.report.markdown.contains("Discovered renderer asset paths: none"))
    }

    func testIOSL11ConditionalRendererEvidenceBundleAcceptsSatisfiedBundledWKWebViewMode() {
        let data = Data("renderer".utf8)
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let safeWKWebViewBlock = makeRichFallbackBlock(
            surface: .localWKWebView,
            rendersAsNativeSafeCard: false,
            requiresVendoredRendererAssets: true,
            allowsNetworkRequests: false,
            allowsExternalNavigation: false,
            allowsRemoteSubresources: false
        )
        let releasePosture = IOSReleaseSecurityPosture(
            usesWKWebViewRichRendering: true,
            localRendererPolicy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers")
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            releasePosture: releasePosture,
            renderedBlocks: [safeWKWebViewBlock],
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            ),
            wkWebViewRequestBlockingPolicy: wkWebViewRequestBlockingPolicy()
        )
        let inventory = IOSRendererAssetInventory(
            discoveredRendererAssets: [asset],
            declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"],
            scannedSwiftFileCount: 2,
            importsWebKitRichRendererCode: true
        )
        let report = IOSConditionalRendererGateReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_390),
            evidence: audit.checklistEvidence,
            inventory: inventory
        )
        let bundle = IOSConditionalRendererGateEvidenceBundle(
            inventory: inventory,
            audit: audit,
            report: report
        )

        XCTAssertTrue(bundle.inventoryMatchesAudit)
        XCTAssertTrue(bundle.satisfiesStageOneConditionalRendererChecklist)
        XCTAssertTrue(bundle.report.markdown.contains("Uses WKWebView rich surface: true"))
        XCTAssertTrue(bundle.report.markdown.contains("renderer asset manifest/hash | requiredAndSatisfied | true"))
    }

    func testIOSL11ConditionalRendererEvidenceBundleRejectsInventoryAuditMismatch() {
        let data = Data("renderer".utf8)
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: [],
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )
        let mismatchedInventory = IOSRendererAssetInventory(
            scannedSwiftFileCount: 2,
            importsWebKitRichRendererCode: false
        )
        let mismatchedReport = IOSConditionalRendererGateReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_400),
            evidence: audit.checklistEvidence,
            inventory: mismatchedInventory
        )
        let bundle = IOSConditionalRendererGateEvidenceBundle(
            inventory: mismatchedInventory,
            audit: audit,
            report: mismatchedReport
        )

        XCTAssertTrue(audit.satisfiesStageOneConditionalRendererGates)
        XCTAssertFalse(bundle.inventoryMatchesAudit)
        XCTAssertFalse(bundle.satisfiesStageOneConditionalRendererChecklist)
    }

    func testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let inventory = rendererAssetInventory()
        let audit = IOSLocalRendererConditionalGateAudit(
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: inventory.discoveredRendererAssetPaths
        )
        let items = audit.checklistEvidence.checklistItems

        XCTAssertEqual(
            items.map(\.blueprintChecklistText),
            [
                "Add local renderer packaging/offline tests if JS renderer assets are used.",
                "Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.",
                "Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored."
            ]
        )
        XCTAssertEqual(items.map(\.status), Array(repeating: .notApplicableNativeFallback, count: 3))
        XCTAssertTrue(items.allSatisfy(\.checklistSatisfied))
        XCTAssertTrue(items[0].evidenceSummary.contains("No JS/CSS/font/HTML renderer assets"))
        XCTAssertTrue(items[1].evidenceSummary.contains("No WKWebView rich surface"))
        XCTAssertTrue(items[2].evidenceSummary.contains("no asset manifest/hash lock"))

        let report = IOSConditionalRendererGateReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_804_800),
            evidence: audit.checklistEvidence,
            inventory: inventory
        )

        XCTAssertTrue(report.markdown.contains("| Blueprint checklist item | Status | Checklist satisfied | Evidence |"))
        XCTAssertTrue(report.markdown.contains("Add local renderer packaging/offline tests if JS renderer assets are used."))
        XCTAssertTrue(report.markdown.contains("Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used."))
        XCTAssertTrue(report.markdown.contains("Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored."))
    }

    func testIOSL11CurrentRepositoryConditionalRendererGatesAreSupervisorReady() throws {
        let source = try richPreviewFixtureSource()
        let evidence = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_808_000)
        ).makeEvidence(source: source)
        let checklist = evidence.audit.checklistEvidence

        XCTAssertTrue(evidence.satisfiesStageOneConditionalRendererChecklist)
        XCTAssertTrue(evidence.inventory.provesNativeFallbackInventory)
        XCTAssertTrue(evidence.audit.richFallbacksStayNativeSafeCards)
        XCTAssertFalse(checklist.usesVendoredRendererAssets)
        XCTAssertFalse(checklist.usesWKWebViewRichSurface)
        XCTAssertEqual(checklist.discoveredRendererAssetPaths, [])
        XCTAssertEqual(
            checklist.supervisorCompletionRecommendations,
            [
                "Add local renderer packaging/offline tests if JS renderer assets are used.",
                "Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.",
                "Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored."
            ]
        )
        XCTAssertTrue(evidence.report.capturesConditionalRendererGateEvidence)
        XCTAssertTrue(evidence.report.markdown.contains("Uses vendored renderer assets: false"))
        XCTAssertTrue(evidence.report.markdown.contains("Uses WKWebView rich surface: false"))
        XCTAssertTrue(evidence.report.markdown.contains("Imports WebKit rich renderer code: false"))
        XCTAssertTrue(evidence.report.markdown.contains("Discovered renderer asset paths: none"))
    }

    func testIOSL11CurrentRepositoryConditionalRendererReportClosesNativeFallbackRows() throws {
        let source = try richPreviewFixtureSource()
        let evidence = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_811_200)
        ).makeEvidence(source: source)
        let checklistItems = evidence.audit.checklistEvidence.checklistItems
        let reportMarkdown = evidence.report.markdown

        XCTAssertTrue(evidence.satisfiesStageOneConditionalRendererChecklist)
        XCTAssertEqual(checklistItems.count, 3)
        XCTAssertEqual(checklistItems.map(\.status), Array(repeating: .notApplicableNativeFallback, count: 3))
        XCTAssertTrue(checklistItems.allSatisfy(\.checklistSatisfied))
        XCTAssertTrue(checklistItems.allSatisfy { item in
            reportMarkdown.contains("| \(item.blueprintChecklistText) | \(item.status.rawValue) | true |")
        })
        XCTAssertTrue(reportMarkdown.contains("- Native fallback reason: iOS renders rich Markdown fallback blocks as native safe cards"))
        XCTAssertTrue(reportMarkdown.contains("| local renderer packaging/offline | notApplicableNativeFallback | true |"))
        XCTAssertTrue(reportMarkdown.contains("| WKWebView request blocking | notApplicableNativeFallback | true |"))
        XCTAssertTrue(reportMarkdown.contains("| renderer asset manifest/hash | notApplicableNativeFallback | true |"))
    }

    func testIOSL11CurrentSourceConditionalRendererCloseoutReportCapturesValidationCommands() throws {
        let evidence = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_812_400)
        ).makeEvidence(source: try richPreviewFixtureSource())
        let report = IOSCurrentSourceConditionalRendererCloseoutReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_812_400),
            evidenceBundle: evidence
        )

        XCTAssertTrue(report.closesAllCurrentSourceConditionalRendererRows)
        XCTAssertTrue(report.conditionalRendererChecklistItemsMatchBlueprint)
        XCTAssertTrue(report.validationCommandsDocumentCurrentGateChecks)
        XCTAssertEqual(report.expectedConditionalRendererChecklistItems, [
            IOSStageOneReconciliationChecklistItem.localRendererPackagingOfflineTests.rawValue,
            IOSStageOneReconciliationChecklistItem.wkWebViewRequestBlockingTests.rawValue,
            IOSStageOneReconciliationChecklistItem.rendererAssetManifestHashTests.rawValue
        ])
        XCTAssertEqual(report.supervisorCompletionRecommendations, [
            IOSStageOneReconciliationChecklistItem.localRendererPackagingOfflineTests.rawValue,
            IOSStageOneReconciliationChecklistItem.wkWebViewRequestBlockingTests.rawValue,
            IOSStageOneReconciliationChecklistItem.rendererAssetManifestHashTests.rawValue
        ])
        XCTAssertTrue(report.markdown.contains("Can mark all conditional L11 renderer rows complete: true"))
        XCTAssertTrue(report.markdown.contains("Checklist items match blueprint: true"))
        XCTAssertTrue(report.markdown.contains("Validation commands document current gate checks: true"))
        XCTAssertTrue(report.markdown.contains("SwiftPM: swift test"))
        XCTAssertTrue(report.markdown.contains("Focused L11: swift test --filter FastMDMobileCoreTests/testIOSL11"))
        XCTAssertTrue(report.markdown.contains("Renderer asset inventory: find ios"))
        XCTAssertTrue(report.markdown.contains("WebKit source scan: rg -n"))
        XCTAssertTrue(report.markdown.contains("WebKit source scan expected result: no matches"))
        XCTAssertTrue(report.markdown.contains("Discovered renderer asset paths: none"))
        XCTAssertTrue(report.markdown.contains("Uses WKWebView rich surface: false"))
        XCTAssertTrue(report.markdown.contains("Imports WebKit rich renderer code: false"))
    }

    func testIOSL11CurrentSourceConditionalRendererCloseoutRejectsVendoredAssets() {
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: 8,
            sha256Hex: String(repeating: "a", count: 64)
        )
        let inventory = IOSRendererAssetInventory(
            discoveredRendererAssets: [asset],
            declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"],
            scannedSwiftFileCount: 1
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: LocalRichRendererRuntimeAudit(
                policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
                declaredAssetNames: ["renderer.js"]
            ),
            renderedBlocks: [],
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )
        let gateReport = IOSConditionalRendererGateReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_812_500),
            evidence: audit.checklistEvidence,
            inventory: inventory
        )
        let closeout = IOSCurrentSourceConditionalRendererCloseoutReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_812_500),
            evidenceBundle: IOSConditionalRendererGateEvidenceBundle(
                inventory: inventory,
                audit: audit,
                report: gateReport
            )
        )

        XCTAssertFalse(closeout.closesAllCurrentSourceConditionalRendererRows)
        XCTAssertTrue(closeout.supervisorCompletionRecommendations.isEmpty)
        XCTAssertTrue(closeout.markdown.contains("Can mark all conditional L11 renderer rows complete: false"))
        XCTAssertTrue(closeout.markdown.contains("Uses vendored renderer assets: true"))
    }

    func testIOSL11CurrentSourceConditionalRendererCloseoutRejectsMissingGateCommands() throws {
        let evidence = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_812_520)
        ).makeEvidence(source: try richPreviewFixtureSource())
        let closeout = IOSCurrentSourceConditionalRendererCloseoutReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_812_520),
            evidenceBundle: evidence,
            swiftPMValidationCommand: "swift test",
            focusedL11ValidationCommand: "swift test --filter FastMDMobileCoreTests/testIOSL11",
            inventoryValidationCommand: "find ios -type f -name '*.js'",
            webKitSourceScanCommand: "rg WebKit ios/Sources",
            webKitSourceScanExpectedResult: "manual review only"
        )

        XCTAssertTrue(closeout.conditionalRendererChecklistItemsMatchBlueprint)
        XCTAssertFalse(closeout.validationCommandsDocumentCurrentGateChecks)
        XCTAssertFalse(closeout.closesAllCurrentSourceConditionalRendererRows)
        XCTAssertTrue(closeout.supervisorCompletionRecommendations.isEmpty)
        XCTAssertTrue(closeout.markdown.contains("Validation commands document current gate checks: false"))
    }

    func testIOSL11CurrentSourceConditionalRendererCompletionEvidenceRequiresIOSReportPath() throws {
        let evidenceBundle = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_814_400)
        ).makeEvidence(source: try richPreviewFixtureSource())
        let closeout = IOSCurrentSourceConditionalRendererCloseoutReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_814_400),
            evidenceBundle: evidenceBundle
        )
        let completionEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-conditional-renderer-supervisor-closeout-20260506.md"
        )
        let nonIOSCompletionEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "Docs/stage1-ios-l11-conditional-renderer-supervisor-closeout.md"
        )

        XCTAssertTrue(completionEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(completionEvidence.validationResultsAllPassed)
        XCTAssertFalse(completionEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertTrue(completionEvidence.markdown.contains("Can mark conditional renderer rows complete: false"))
        XCTAssertTrue(completionEvidence.markdown.contains("Add local renderer packaging/offline tests if JS renderer assets are used. | OPEN"))
        XCTAssertTrue(completionEvidence.markdown.contains("Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | OPEN"))
        XCTAssertTrue(completionEvidence.markdown.contains("Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | OPEN"))

        XCTAssertFalse(nonIOSCompletionEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(nonIOSCompletionEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertTrue(nonIOSCompletionEvidence.markdown.contains("Evidence path is iOS-local report: false"))
    }

    func testIOSL11CurrentSourceConditionalRendererCompletionEvidenceRequiresMarkdownReportFile() throws {
        let evidenceBundle = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_814_420)
        ).makeEvidence(source: try richPreviewFixtureSource())
        let closeout = IOSCurrentSourceConditionalRendererCloseoutReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_814_420),
            evidenceBundle: evidenceBundle
        )
        let validEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-conditional-renderer-completion-20260506.md"
        )
        let directoryOnlyEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/"
        )
        let nonMarkdownEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-conditional-renderer-completion-20260506.txt"
        )
        let whitespaceEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1 ios l11 completion 20260506.md"
        )
        let queryEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-completion-20260506.md?cache=1"
        )
        let fragmentEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-completion-20260506.md#row"
        )
        let tableDelimiterEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-completion|20260506.md"
        )

        XCTAssertTrue(validEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(validEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertFalse(validEvidence.validationResultsAllPassed)
        XCTAssertFalse(directoryOnlyEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(directoryOnlyEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertFalse(nonMarkdownEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(nonMarkdownEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertFalse(whitespaceEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(whitespaceEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertFalse(queryEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(queryEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertFalse(fragmentEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(fragmentEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertFalse(tableDelimiterEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(tableDelimiterEvidence.canMarkConditionalRendererRowsComplete)
    }

    func testIOSL11CurrentSourceConditionalRendererCompletionEvidenceCapturesPassingValidationResults() throws {
        let evidenceBundle = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_814_430)
        ).makeEvidence(source: try richPreviewFixtureSource())
        let closeout = IOSCurrentSourceConditionalRendererCloseoutReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_814_430),
            evidenceBundle: evidenceBundle
        )
        let completionEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-conditional-renderer-completion-20260506.md",
            validationResults: [
                IOSValidationCommandResult(
                    label: "SwiftPM tests",
                    command: "swift test",
                    status: .passed,
                    detail: "201 tests, 0 failures"
                ),
                IOSValidationCommandResult(
                    label: "Focused L11 conditional renderer tests",
                    command: "swift test --filter FastMDMobileCoreTests/testIOSL11",
                    status: .passed,
                    detail: "Conditional renderer tests passed"
                ),
                IOSValidationCommandResult(
                    label: "Renderer asset inventory",
                    command: IOSRendererAssetInventory.defaultInventoryCommand,
                    status: .passed,
                    detail: "No JS/CSS/font/HTML renderer assets discovered"
                ),
                IOSValidationCommandResult(
                    label: "WebKit source scan",
                    command: closeout.webKitSourceScanCommand,
                    status: .passed,
                    detail: "No WebKit import or WKWebView construction found under ios/Sources"
                )
            ]
        )

        XCTAssertTrue(completionEvidence.validationResultsAllPassed)
        XCTAssertTrue(completionEvidence.validationResultsCoverCurrentGateChecks)
        XCTAssertTrue(completionEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertTrue(completionEvidence.markdown.contains("Validation results all passed: true"))
        XCTAssertTrue(completionEvidence.markdown.contains("Validation results cover current gate checks: true"))
        XCTAssertTrue(completionEvidence.markdown.contains("| SwiftPM tests | swift test | passed | 201 tests, 0 failures |"))
        XCTAssertTrue(completionEvidence.markdown.contains("| Focused L11 conditional renderer tests |"))
        XCTAssertTrue(completionEvidence.markdown.contains("| WebKit source scan |"))
    }

    func testIOSL11CurrentSourceConditionalRendererCompletionEvidenceRequiresEveryGateCommand() throws {
        let evidenceBundle = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_814_435)
        ).makeEvidence(source: try richPreviewFixtureSource())
        let closeout = IOSCurrentSourceConditionalRendererCloseoutReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_814_435),
            evidenceBundle: evidenceBundle
        )
        let completionEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-conditional-renderer-completion-20260506.md",
            validationResults: [
                IOSValidationCommandResult(
                    label: "SwiftPM tests",
                    command: "swift test",
                    status: .passed,
                    detail: "204 tests, 0 failures"
                ),
                IOSValidationCommandResult(
                    label: "Renderer asset inventory",
                    command: IOSRendererAssetInventory.defaultInventoryCommand,
                    status: .passed,
                    detail: "No JS/CSS/font/HTML renderer assets discovered"
                ),
                IOSValidationCommandResult(
                    label: "WebKit source scan",
                    command: closeout.webKitSourceScanCommand,
                    status: .passed,
                    detail: "No WebKit import or WKWebView construction found under ios/Sources"
                )
            ]
        )

        XCTAssertTrue(completionEvidence.validationResultsAllPassed)
        XCTAssertFalse(completionEvidence.validationResultsCoverCurrentGateChecks)
        XCTAssertFalse(completionEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertTrue(completionEvidence.markdown.contains("Validation results cover current gate checks: false"))
    }

    func testIOSL11CurrentSourceConditionalRendererCompletionEvidenceKeepsRowsOpenForBlockedValidationResult() throws {
        let evidenceBundle = IOSConditionalRendererGateEvidenceBuilder(
            iosRoot: Self.packageRoot,
            generatedAt: Date(timeIntervalSince1970: 1_777_814_440)
        ).makeEvidence(source: try richPreviewFixtureSource())
        let closeout = IOSCurrentSourceConditionalRendererCloseoutReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_814_440),
            evidenceBundle: evidenceBundle
        )
        let completionEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-conditional-renderer-completion-20260506.md",
            validationResults: [
                IOSValidationCommandResult(
                    label: "iPhone 12 simulator tests",
                    command: "xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test",
                    status: .blocked,
                    detail: "No simulator destination available"
                )
            ]
        )

        XCTAssertFalse(completionEvidence.validationResultsAllPassed)
        XCTAssertFalse(completionEvidence.validationResultsCoverCurrentGateChecks)
        XCTAssertFalse(completionEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertTrue(completionEvidence.markdown.contains("Can mark conditional renderer rows complete: false"))
        XCTAssertTrue(completionEvidence.markdown.contains("| iPhone 12 simulator tests |"))
        XCTAssertTrue(completionEvidence.markdown.contains("| blocked | No simulator destination available |"))
    }

    func testIOSL11CurrentSourceConditionalRendererCompletionEvidenceRejectsIncompleteCloseout() {
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: 8,
            sha256Hex: String(repeating: "a", count: 64)
        )
        let inventory = IOSRendererAssetInventory(
            discoveredRendererAssets: [asset],
            declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"],
            scannedSwiftFileCount: 1
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: LocalRichRendererRuntimeAudit(
                policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
                declaredAssetNames: ["renderer.js"]
            ),
            renderedBlocks: [],
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )
        let gateReport = IOSConditionalRendererGateReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_814_500),
            evidence: audit.checklistEvidence,
            inventory: inventory
        )
        let closeout = IOSCurrentSourceConditionalRendererCloseoutReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_814_500),
            evidenceBundle: IOSConditionalRendererGateEvidenceBundle(
                inventory: inventory,
                audit: audit,
                report: gateReport
            )
        )
        let completionEvidence = IOSCurrentSourceConditionalRendererCompletionEvidence(
            closeoutReport: closeout,
            evidencePath: "ios/docs/reports/stage1-ios-l11-conditional-renderer-supervisor-closeout-20260506.md"
        )

        XCTAssertTrue(completionEvidence.evidencePathIsIOSLocalReport)
        XCTAssertFalse(completionEvidence.canMarkConditionalRendererRowsComplete)
        XCTAssertTrue(completionEvidence.markdown.contains("Can mark conditional renderer rows complete: false"))
        XCTAssertTrue(completionEvidence.markdown.contains("| None | OPEN | ios/docs/reports/stage1-ios-l11-conditional-renderer-supervisor-closeout-20260506.md |"))
    }

    func testIOSL11ConditionalRendererChecklistItemsExposeFutureRequiredAssetGates() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let data = Data("renderer".utf8)
        let asset = IOSRendererAssetManifestEntry(
            path: "ios/Resources/FastMDRenderers/renderer.js",
            byteCount: data.count,
            sha256Hex: IOSRendererAssetInventory.sha256Hex(for: data)
        )
        let runtimeAudit = LocalRichRendererRuntimeAudit(
            policy: .vendoredLocalBundle(bundleResourceRoot: "FastMDRenderers"),
            declaredAssetNames: ["renderer.js"]
        )
        let audit = IOSLocalRendererConditionalGateAudit(
            runtimeAudit: runtimeAudit,
            renderedBlocks: rendered,
            discoveredRendererAssetPaths: [asset.path],
            rendererAssetManifestHashAudit: IOSRendererAssetManifestHashAudit(
                discoveredAssets: [asset],
                manifestEntries: [asset]
            ),
            rendererBundleResourceDeclarationAudit: IOSRendererBundleResourceDeclarationAudit(
                discoveredAssets: [asset],
                declaredBundledRendererResourceRoots: ["ios/Resources/FastMDRenderers"]
            )
        )
        let items = audit.checklistEvidence.checklistItems

        XCTAssertEqual(items.map(\.status), [
            .requiredAndSatisfied,
            .notApplicableNativeFallback,
            .requiredAndSatisfied
        ])
        XCTAssertTrue(items.allSatisfy(\.checklistSatisfied))
        XCTAssertTrue(items[0].evidenceSummary.contains("local packaging/offline validation"))
        XCTAssertTrue(items[1].evidenceSummary.contains("No WKWebView rich surface"))
        XCTAssertTrue(items[2].evidenceSummary.contains("SHA-256 verification"))
    }

    func testIOSL11LogRedactionGateExcludesPrivateDiagnosticFragments() {
        let input = IOSDiagnosticsLogRedactionInput(
            eventName: "save failed",
            displayName: "secret-note.md",
            fullPath: "/Users/alice/Documents/private/secret-note.md",
            fullURI: "file:///Users/alice/Documents/private/secret-note.md?token=abc123",
            documentContent: "# Secret\n\nPatient: Alice",
            searchQuery: "Patient Alice",
            clipboardText: "copied private block",
            diagnostics: IOSDiagnosticsBuilder().snapshot(
                parseMilliseconds: 4.2,
                renderMilliseconds: 9.5,
                searchMilliseconds: 1.1,
                saveMilliseconds: 18.0,
                deviceClass: .iOSPhone12Standard,
                rendererProfile: "native-swiftui-uikit",
                byteCount: 128_000,
                lastErrorCode: .saveFailed
            )
        )

        let redacted = IOSDiagnosticsLogRedactionPolicy().redactedLogLine(from: input)
        let audit = IOSDiagnosticsLogRedactionAudit(
            redactedLine: redacted,
            forbiddenFragments: [
                "/Users/alice",
                "file:///Users/alice",
                "token=abc123",
                "# Secret",
                "Patient: Alice",
                "Patient Alice",
                "copied private block"
            ]
        )

        XCTAssertTrue(audit.satisfiesStageOneLogRedactionTests)
        XCTAssertTrue(redacted.isRedactedForLocalExport)
        XCTAssertTrue(audit.excludesForbiddenFragments)
        XCTAssertTrue(redacted.text.contains("event=save-failed"))
        XCTAssertTrue(redacted.text.contains("displayName=secret-note.md"))
        XCTAssertTrue(redacted.text.contains("fileSizeBucket=medium"))
        XCTAssertTrue(redacted.text.contains("lastErrorCategory=save"))
        XCTAssertTrue(redacted.text.contains("hasSearchQuery=true"))
        XCTAssertTrue(redacted.text.contains("hasClipboard=true"))
    }

    func testIOSL11PerformanceGateAuditsParseRenderSearchFontTierSwitchAndSave() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let source = generatedLargeMarkdown(repeatedParagraphCount: 220)
        let loadResult = makeLoadedDocument(
            displayName: "performance.md",
            source: source
        )
        let destinationURL = directory.appendingPathComponent("performance.md")
        try source.data(using: .utf8)?.write(to: destinationURL)

        let renderResult = try await measuredAsync(
            operation: .render,
            thresholdMilliseconds: 3_000
        ) {
            await IOSReaderScreenEngine().renderDocumentOffMainActor(loadResult)
        }
        let searchResult = try await measuredAsync(
            operation: .search,
            thresholdMilliseconds: 1_500
        ) {
            await IOSReaderSearchEngine().searchOffMainActor(
                query: "needle",
                in: renderResult.value.renderedBlocks
            )
        }
        let saveResult = try await measuredAsync(
            operation: .save,
            thresholdMilliseconds: 3_000
        ) {
            try await IOSDocumentFileIO().saveDocumentOffMainActor(
                editedSource: source + "\nSaved needle",
                for: loadResult,
                to: destinationURL
            )
        }
        let parseMeasurement = IOSPerformanceAutomationMeasurement(
            operation: .parse,
            elapsedMilliseconds: renderResult.elapsedMilliseconds,
            thresholdMilliseconds: 3_000,
            execution: renderResult.value.execution
        )
        let fontTierMeasurement = measuredSync(
            operation: .fontTierSwitch,
            thresholdMilliseconds: 1_000
        ) {
            _ = MobileFontTier.allCases.map { tier in
                NativeMarkdownTypography(fontTier: tier)
            }
        }
        let audit = IOSPerformanceAutomationAudit(
            measurements: [
                parseMeasurement,
                IOSPerformanceAutomationMeasurement(
                    operation: .render,
                    elapsedMilliseconds: renderResult.elapsedMilliseconds,
                    thresholdMilliseconds: renderResult.thresholdMilliseconds,
                    execution: renderResult.value.execution
                ),
                IOSPerformanceAutomationMeasurement(
                    operation: .search,
                    elapsedMilliseconds: searchResult.elapsedMilliseconds,
                    thresholdMilliseconds: searchResult.thresholdMilliseconds,
                    execution: searchResult.value.execution
                ),
                fontTierMeasurement,
                IOSPerformanceAutomationMeasurement(
                    operation: .save,
                    elapsedMilliseconds: saveResult.elapsedMilliseconds,
                    thresholdMilliseconds: saveResult.thresholdMilliseconds,
                    execution: saveResult.value.execution
                )
            ],
            testedFontTiers: Set(MobileFontTier.allCases)
        )
        let performanceReport = IOSStageOnePerformanceReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_802_450),
            audit: audit,
            diagnostics: IOSDiagnosticsBuilder().snapshot(
                parseMilliseconds: parseMeasurement.elapsedMilliseconds,
                renderMilliseconds: renderResult.elapsedMilliseconds,
                searchMilliseconds: searchResult.elapsedMilliseconds,
                saveMilliseconds: saveResult.elapsedMilliseconds,
                byteCount: source.utf8.count,
                lastErrorCode: nil
            ),
            localValidationDeviceName: "SwiftPM XCTest host",
            requiredIPhone12SimulatorBlocker: "iPhone 12 simulator unavailable in local destination set"
        )

        XCTAssertTrue(audit.satisfiesStageOnePerformanceTests)
        XCTAssertTrue(audit.coversRequiredOperations)
        XCTAssertTrue(audit.allMeasurementsWithinThreshold)
        XCTAssertTrue(audit.coversAllFourFontTiers)
        XCTAssertTrue(audit.offMainOperationsStayedOffMainActor)
        XCTAssertTrue(performanceReport.capturesRequiredIOSPerformanceReport)
        XCTAssertTrue(performanceReport.markdown.contains("| save |"))
        XCTAssertFalse(searchResult.value.value.matches.isEmpty)
        XCTAssertGreaterThan(saveResult.value.value.byteCount, source.utf8.count)
    }

    func testIOSL12PerformanceReportCapturesRedactedIPhone12ProfileEvidence() {
        let offMainExecution = IOSOffMainActorExecutionMetadata(
            scheduledWithDetachedTask: true,
            startedOnMainThread: false,
            completedOnMainThread: false
        )
        let audit = IOSPerformanceAutomationAudit(
            measurements: [
                IOSPerformanceAutomationMeasurement(
                    operation: .parse,
                    elapsedMilliseconds: 38.2,
                    thresholdMilliseconds: 3_000,
                    execution: offMainExecution
                ),
                IOSPerformanceAutomationMeasurement(
                    operation: .render,
                    elapsedMilliseconds: 84.7,
                    thresholdMilliseconds: 3_000,
                    execution: offMainExecution
                ),
                IOSPerformanceAutomationMeasurement(
                    operation: .search,
                    elapsedMilliseconds: 12.4,
                    thresholdMilliseconds: 1_500,
                    execution: offMainExecution
                ),
                IOSPerformanceAutomationMeasurement(
                    operation: .fontTierSwitch,
                    elapsedMilliseconds: 1.1,
                    thresholdMilliseconds: 1_000
                ),
                IOSPerformanceAutomationMeasurement(
                    operation: .save,
                    elapsedMilliseconds: 21.9,
                    thresholdMilliseconds: 3_000,
                    execution: offMainExecution
                )
            ],
            testedFontTiers: Set(MobileFontTier.allCases)
        )
        let diagnostics = IOSDiagnosticsBuilder().snapshot(
            parseMilliseconds: 38.2,
            renderMilliseconds: 84.7,
            searchMilliseconds: 12.4,
            saveMilliseconds: 21.9,
            byteCount: 420_000,
            lastErrorCode: nil
        )
        let report = IOSStageOnePerformanceReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_802_500),
            audit: audit,
            diagnostics: diagnostics,
            localValidationDeviceName: "Stage1 iPhone 15 Pro",
            requiredIPhone12SimulatorBlocker: "Unable to find a device matching iPhone 12"
        )

        XCTAssertTrue(report.capturesRequiredIOSPerformanceReport)
        XCTAssertTrue(report.markdown.contains("Profile: iOSPhone12Standard"))
        XCTAssertTrue(report.markdown.contains("Local validation device: Stage1 iPhone 15 Pro"))
        XCTAssertTrue(report.markdown.contains("iPhone 12 simulator blocker: Unable to find a device matching iPhone 12"))
        XCTAssertTrue(report.markdown.contains("| parse | 38.20 | 3000.00 | yes | PASS |"))
        XCTAssertTrue(report.markdown.contains("| fontTierSwitch | 1.10 | 1000.00 | n/a | PASS |"))
        XCTAssertTrue(report.markdown.contains("| save | 21.90 | 3000.00 | yes | PASS |"))
        XCTAssertTrue(report.markdown.contains("Redacted for local export: true"))
        XCTAssertFalse(report.markdown.contains("/tmp/private-note.md"))
        XCTAssertFalse(report.markdown.contains("secret=token"))
        XCTAssertFalse(report.markdown.contains("# Private Document"))
    }

    func testIOSL12SimulatorValidationReportCapturesIPhone12BuildAndTestGates() {
        let report = IOSStageOneSimulatorValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_500),
            simulatorIdentifier: "1B6FEADC-308B-4069-B734-3C9C207E633F",
            swiftPMTestPassed: true,
            simulatorAvailable: true,
            xcodebuildBuildPassed: true,
            xcodebuildTestPassed: true,
            testCaseCount: 119,
            resultBundlePath: "/Users/alice/Library/Developer/Xcode/DerivedData/ios/Logs/Test/Test-FastMDMobile.xcresult"
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.capturesIPhone12SimulatorBuildGate)
        XCTAssertTrue(report.capturesIPhone12SimulatorTestGate)
        XCTAssertTrue(report.capturesRequiredIPhone12SimulatorValidation)
        XCTAssertTrue(report.markdown.contains("Status: passed"))
        XCTAssertTrue(report.markdown.contains("Destination: platform=iOS Simulator,name=iPhone 12"))
        XCTAssertTrue(report.markdown.contains("| iPhone 12 simulator build | PASS |"))
        XCTAssertTrue(report.markdown.contains("| iPhone 12 simulator tests | PASS |"))
        XCTAssertTrue(report.markdown.contains("XCTest case count: 119"))
        XCTAssertFalse(report.markdown.contains("# Private Document"))
        XCTAssertFalse(report.markdown.contains("secret=token"))
    }

    func testIOSL12SimulatorValidationReportKeepsGatesOpenWhenDestinationOrTestsFail() {
        let missingSimulator = IOSStageOneSimulatorValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_600),
            swiftPMTestPassed: true,
            simulatorAvailable: false,
            xcodebuildBuildPassed: false,
            xcodebuildTestPassed: false,
            testCaseCount: 0
        )
        let wrongDestination = IOSStageOneSimulatorValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_700),
            destination: "platform=iOS Simulator,name=iPhone 15 Pro",
            swiftPMTestPassed: true,
            simulatorAvailable: true,
            xcodebuildBuildPassed: true,
            xcodebuildTestPassed: true,
            testCaseCount: 119
        )
        let failedTests = IOSStageOneSimulatorValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_800),
            swiftPMTestPassed: true,
            simulatorAvailable: true,
            xcodebuildBuildPassed: true,
            xcodebuildTestPassed: false,
            testCaseCount: 119
        )

        XCTAssertEqual(missingSimulator.status, .blockedSimulatorUnavailable)
        XCTAssertFalse(missingSimulator.capturesIPhone12SimulatorBuildGate)
        XCTAssertFalse(missingSimulator.capturesIPhone12SimulatorTestGate)
        XCTAssertTrue(missingSimulator.markdown.contains("| iPhone 12 simulator available | BLOCKED |"))

        XCTAssertEqual(wrongDestination.status, .passed)
        XCTAssertFalse(wrongDestination.capturesIPhone12SimulatorBuildGate)
        XCTAssertFalse(wrongDestination.capturesRequiredIPhone12SimulatorValidation)
        XCTAssertTrue(wrongDestination.markdown.contains("| iPhone 12 simulator build | OPEN |"))

        XCTAssertEqual(failedTests.status, .failedTests)
        XCTAssertTrue(failedTests.capturesIPhone12SimulatorBuildGate)
        XCTAssertFalse(failedTests.capturesIPhone12SimulatorTestGate)
        XCTAssertTrue(failedTests.markdown.contains("| iPhone 12 simulator tests | OPEN |"))
    }

    func testIOSL12SimctlDeviceListParserFindsExactIPhone12SimulatorDestination() throws {
        let output = """
        == Devices ==
        -- iOS 26.4 --
            iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
            iPhone 16 Pro (99857F79-16BB-4B27-87B1-C566CE1F11CC) (Booted)
        -- tvOS 26.4 --
            Apple TV (C0F21F93-B98C-4E31-9D58-5C33B0884E3A) (Shutdown)
        """

        let parser = IOSSimctlDeviceListParser()
        let candidates = parser.parseCandidates(from: output)
        let iPhone12 = try XCTUnwrap(parser.iPhone12Simulator(from: output))

        XCTAssertTrue(parser.containsAvailableIPhone12Simulator(in: output))
        XCTAssertEqual(candidates.count, 2)
        XCTAssertEqual(iPhone12.name, "iPhone 12")
        XCTAssertEqual(iPhone12.osVersion, "26.4")
        XCTAssertEqual(iPhone12.identifier, "1B6FEADC-308B-4069-B734-3C9C207E633F")
        XCTAssertEqual(iPhone12.hardwareModel, "iPhone 12")
        XCTAssertTrue(iPhone12.isSimulator)
        XCTAssertTrue(iPhone12.isConnected)
        XCTAssertEqual(iPhone12.eligibilityReason, .simulatorDestination)
    }

    func testIOSL12SimctlDeviceListParserFailsClosedForUnavailableOrNonExactDestinations() {
        let output = """
        == Devices ==
        -- iOS 18.6 --
            iPhone 12 Pro Max (11111111-2222-3333-4444-555555555555) (Shutdown)
        -- iOS 26.4 --
            iPhone 12 (66666666-7777-8888-9999-AAAAAAAAAAAA) (Shutdown) (unavailable, runtime profile not found)
        """

        let parser = IOSSimctlDeviceListParser()
        let candidates = parser.parseCandidates(from: output)

        XCTAssertEqual(candidates.map(\.name), ["iPhone 12 Pro Max"])
        XCTAssertFalse(parser.containsAvailableIPhone12Simulator(in: output))
        XCTAssertNil(parser.iPhone12Simulator(from: output))
    }

    func testIOSL12SecurityAuditReportCapturesReleaseAndFixtureSecurityEvidence() throws {
        let parser = MarkdownParserAdapter()
        let renderer = MarkdownNativeRenderer()
        let maliciousHTMLSource = try fixtureSource(named: "malicious-html.md")
        let maliciousLinkSource = try fixtureSource(named: "malicious-links.md")
        let remoteImageSource = try fixtureSource(named: "remote-image.md")
        let richSource = try richPreviewFixtureSource()
        let hostileHTMLAudit = IOSHostileMarkdownFixtureAudit(
            renderedBlocks: renderer.render(
                document: parser.parse(maliciousHTMLSource),
                source: maliciousHTMLSource
            )
        )
        let hostileLinkAudit = IOSHostileMarkdownFixtureAudit(
            renderedBlocks: renderer.render(
                document: parser.parse(maliciousLinkSource),
                source: maliciousLinkSource
            )
        )
        let remoteImageAudit = IOSRemoteImagePrivacyAudit(
            renderedBlocks: renderer.render(
                document: parser.parse(remoteImageSource),
                source: remoteImageSource
            )
        )
        let richRendered = renderer.render(
            document: parser.parse(richSource),
            source: richSource
        )
        let conditionalRendererAudit = IOSLocalRendererConditionalGateAudit(
            renderedBlocks: richRendered,
            discoveredRendererAssetPaths: discoveredRendererAssetPaths()
        )
        let report = IOSStageOneSecurityAuditReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_805_000),
            localImageDownsamplePolicy: IOSLocalImageDownsamplePolicy(),
            securityScopedAccessAudit: IOSSecurityScopedAccessAudit(
                startedAccessCount: 8,
                stoppedAccessCount: 8
            ),
            releasePosture: IOSReleaseSecurityPosture(),
            hostileHTMLAudit: hostileHTMLAudit,
            hostileLinkAudit: hostileLinkAudit,
            remoteImageAudit: remoteImageAudit,
            conditionalRendererAudit: conditionalRendererAudit,
            diagnostics: IOSDiagnosticsBuilder().snapshot(
                parseMilliseconds: 21.0,
                renderMilliseconds: 44.0,
                searchMilliseconds: 7.0,
                saveMilliseconds: 16.0,
                byteCount: richSource.utf8.count,
                lastErrorCode: nil
            ),
            importsWebKitRichRendererCode: importsWebKitRichRendererCode(),
            rendererAssetInventoryCommand: IOSRendererAssetInventory.defaultInventoryCommand
        )

        XCTAssertTrue(report.capturesRequiredIOSSecurityAuditReport)
        XCTAssertTrue(report.markdown.contains("ImageIO local image downsample | satisfied"))
        XCTAssertTrue(report.markdown.contains("Security-scoped access balance | satisfied"))
        XCTAssertTrue(report.markdown.contains("ATS posture | satisfied"))
        XCTAssertTrue(report.markdown.contains("Privacy manifest posture | satisfied"))
        XCTAssertTrue(report.markdown.contains("Background modes | satisfied"))
        XCTAssertTrue(report.markdown.contains("Rich renderer network posture | satisfied"))
        XCTAssertTrue(report.markdown.contains("Malicious HTML fixture | satisfied"))
        XCTAssertTrue(report.markdown.contains("Malicious link fixture | satisfied"))
        XCTAssertTrue(report.markdown.contains("Remote image privacy | satisfied"))
        XCTAssertTrue(report.markdown.contains("Conditional local renderer gates | satisfied"))
        XCTAssertTrue(report.markdown.contains("Discovered renderer asset paths: none"))
        XCTAssertFalse(report.markdown.contains("/Users/alice"))
        XCTAssertFalse(report.markdown.contains("secret=token"))
        XCTAssertFalse(report.markdown.contains("# Private Document"))
    }

    func testIOSL12RichFixtureRenderReportCapturesAllBlueprintCategories() throws {
        let source = try richPreviewFixtureSource()
        let parser = MarkdownParserAdapter()
        let renderer = MarkdownNativeRenderer()
        let document = parser.parse(source)
        let rendered = renderer.render(document: document, source: source)
        let audit = IOSRichFixtureRenderAudit(
            sourceByteCount: source.utf8.count,
            renderedBlocks: rendered
        )
        let report = IOSRichFixtureRenderReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_805_100),
            audit: audit,
            parserAudit: IOSParserContractAudit(document: document, source: source),
            layoutSafetyAudit: IOSLayoutSafetyAudit(
                lazyRenderingPolicy: IOSReaderScreenEngine().lazyRenderingPolicy,
                iconOnlyControlLabels: IOSReaderAccessibilityPolicy().iconOnlyControlLabels,
                renderedBlocks: rendered
            ),
            conditionalRendererAudit: IOSLocalRendererConditionalGateAudit(
                renderedBlocks: rendered,
                discoveredRendererAssetPaths: discoveredRendererAssetPaths()
            ),
            snapshotSignatures: richFixtureSnapshotSignatures(source: source)
        )

        XCTAssertTrue(audit.satisfiesStageOneRichFixtureRenderReport)
        XCTAssertEqual(audit.missingCategories, [])
        XCTAssertEqual(audit.coveredCategories.count, IOSRichFixtureRenderCategory.allCases.count)
        XCTAssertTrue(report.capturesRequiredRichFixtureRenderReport)
        XCTAssertTrue(report.markdown.contains("Covered categories: 30/30"))
        XCTAssertTrue(report.hasCompleteSnapshotSignatureMatrix)
        XCTAssertEqual(report.coveredSnapshotSignaturePairs.count, 8)
        XCTAssertEqual(report.missingSnapshotSignaturePairs, [])
        XCTAssertTrue(report.markdown.contains("Snapshot signatures: 8/8"))
        XCTAssertTrue(report.markdown.contains("Missing snapshot signatures: none"))
        XCTAssertTrue(report.markdown.contains("| H1-H6 headings | PASS |"))
        XCTAssertTrue(report.markdown.contains("| Mermaid blocks | PASS |"))
        XCTAssertTrue(report.markdown.contains("| Remote image privacy |") == false)
        XCTAssertTrue(report.markdown.contains("| Generic HTML blocks | PASS |"))
        XCTAssertTrue(report.markdown.contains("| Escaped marker characters | PASS |"))
    }

    func testIOSL12RichFixtureRenderReportRequiresCompleteThemeAndFontSnapshotMatrix() throws {
        let source = try richPreviewFixtureSource()
        let parser = MarkdownParserAdapter()
        let renderer = MarkdownNativeRenderer()
        let document = parser.parse(source)
        let rendered = renderer.render(document: document, source: source)
        let signaturesMissingOneCombination = richFixtureSnapshotSignatures(source: source).filter {
            !($0.themeScheme == .dark && $0.fontTier == .reader)
        }
        let report = IOSRichFixtureRenderReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_805_101),
            audit: IOSRichFixtureRenderAudit(
                sourceByteCount: source.utf8.count,
                renderedBlocks: rendered
            ),
            parserAudit: IOSParserContractAudit(document: document, source: source),
            layoutSafetyAudit: IOSLayoutSafetyAudit(
                lazyRenderingPolicy: IOSReaderScreenEngine().lazyRenderingPolicy,
                iconOnlyControlLabels: IOSReaderAccessibilityPolicy().iconOnlyControlLabels,
                renderedBlocks: rendered
            ),
            conditionalRendererAudit: IOSLocalRendererConditionalGateAudit(
                renderedBlocks: rendered,
                discoveredRendererAssetPaths: discoveredRendererAssetPaths()
            ),
            snapshotSignatures: signaturesMissingOneCombination
        )

        XCTAssertFalse(report.hasCompleteSnapshotSignatureMatrix)
        XCTAssertFalse(report.capturesRequiredRichFixtureRenderReport)
        XCTAssertEqual(report.requiredSnapshotSignatureMatrixCount, 8)
        XCTAssertEqual(report.coveredSnapshotSignaturePairs.count, 7)
        XCTAssertEqual(report.missingSnapshotSignaturePairs, ["dark:reader"])
        XCTAssertTrue(report.markdown.contains("Snapshot signatures: 7/8"))
        XCTAssertTrue(report.markdown.contains("Missing snapshot signatures: dark:reader"))
    }

    func testIOSL12XctraceDeviceListParserClassifiesConnectedOfflineAndSimulatorDevices() {
        let output = """
        == Devices ==
        Mac (E61742AC-8496-56E3-9159-8DA00247F3E5)
        iPhone 12 Pro (18.6) (00008101-0011223344556677)

        == Devices Offline ==
        Turbulence (26.1) (00008130-001935383CBA001C)

        == Simulators ==
        iPad (10th generation) (18.3.1) (779F0B22-10EC-49C0-A2D3-52B38184CDD7)
        iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)
        iPhone 17 (26.4.1) + Apple Watch Ultra 3 (49mm) Simulator (26.4) (A39D73E8-BD97-42CB-9C8A-E82CEACBE18E)
        """

        let candidates = IOSXctraceDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 6)
        XCTAssertEqual(candidates[0].name, "Mac")
        XCTAssertNil(candidates[0].osVersion)
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertFalse(candidates[0].isSimulator)

        XCTAssertEqual(candidates[1].name, "iPhone 12 Pro")
        XCTAssertEqual(candidates[1].osVersion, "18.6")
        XCTAssertNil(candidates[1].hardwareModel)
        XCTAssertTrue(candidates[1].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[2].name, "Turbulence")
        XCTAssertEqual(candidates[2].osVersion, "26.1")
        XCTAssertFalse(candidates[2].isConnected)

        XCTAssertEqual(candidates[3].name, "iPad (10th generation)")
        XCTAssertEqual(candidates[3].osVersion, "18.3.1")
        XCTAssertTrue(candidates[3].isSimulator)

        XCTAssertEqual(candidates[4].name, "iPhone 12")
        XCTAssertTrue(candidates[4].isSimulator)
        XCTAssertFalse(candidates[4].isEligibleConnectedDevice)

        XCTAssertEqual(
            candidates[5].name,
            "iPhone 17 (26.4.1) + Apple Watch Ultra 3 (49mm) Simulator"
        )
        XCTAssertEqual(candidates[5].osVersion, "26.4")
    }

    func testIOSL12DevicectlDeviceListParserExtractsHardwareIdentifiersFromJSONOutput() {
        let output = """
        Name         Identifier                             State
        ----------   ------------------------------------   ------------------
        AlicePhone   connected-iphone-12                   available (paired)
        {
          "result" : {
            "devices" : [
              {
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "AlicePhone",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPhone 12 Pro",
                  "productType" : "iPhone13,3",
                  "reality" : "physical"
                },
                "identifier" : "connected-iphone-12"
              },
              {
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "unavailable"
                },
                "deviceProperties" : {
                  "name" : "Turbulence",
                  "osVersionNumber" : "26.1"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPhone 15 Pro",
                  "productType" : "iPhone16,1",
                  "reality" : "physical"
                },
                "identifier" : "offline-iphone-15"
              },
              {
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "disconnected"
                },
                "deviceProperties" : {
                  "name" : "Work iPad",
                  "osVersionNumber" : "26.3.1 (a)"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPad Pro (11-inch) (4th generation)",
                  "productType" : "iPad14,4",
                  "reality" : "physical"
                },
                "identifier" : "paired-ipad"
              },
              {
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "disconnected"
                },
                "deviceProperties" : {
                  "name" : "Disconnected iPhone 12",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPhone 12 Pro",
                  "productType" : "iPhone13,3",
                  "reality" : "physical"
                },
                "identifier" : "disconnected-iphone-12"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 4)
        XCTAssertEqual(candidates[0].name, "AlicePhone")
        XCTAssertEqual(candidates[0].osVersion, "18.6")
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,3")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertFalse(candidates[0].isSimulator)
        XCTAssertTrue(candidates[0].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[1].name, "Turbulence")
        XCTAssertEqual(candidates[1].hardwareModel, "iPhone16,1")
        XCTAssertFalse(candidates[1].isConnected)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[2].name, "Work iPad")
        XCTAssertEqual(candidates[2].osVersion, "26.3.1")
        XCTAssertEqual(candidates[2].hardwareModel, "iPad14,4")
        XCTAssertFalse(candidates[2].isConnected)
        XCTAssertFalse(candidates[2].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[3].name, "Disconnected iPhone 12")
        XCTAssertEqual(candidates[3].hardwareModel, "iPhone13,3")
        XCTAssertFalse(candidates[3].isConnected)
        XCTAssertFalse(candidates[3].isEligibleConnectedDevice)
    }

    func testIOSL12DevicectlParserDoesNotUpgradeDisconnectedJSONTunnelFromTableAvailability() {
        let output = """
        Failed to load provisioning paramter list due to error: Error Domain=com.apple.dt.CoreDeviceError Code=1002 "No provider was found."
        Name         Hostname                             Identifier                             State                Model
        ----------   ----------------------------------   ------------------------------------   ------------------   ----------------------------------------------
        Lab iPad     Lab-iPad.coredevice.local            shared-ipad-identifier                 available (paired)   iPad Pro (11-inch) (4th generation) (iPad14,4)
        {
          "result" : {
            "devices" : [
              {
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "disconnected"
                },
                "deviceProperties" : {
                  "name" : "Lab iPad",
                  "osVersionNumber" : "26.3.1 (a)"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPad Pro (11-inch) (4th generation)",
                  "productType" : "iPad14,4",
                  "reality" : "physical"
                },
                "identifier" : "shared-ipad-identifier"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_178),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_168),
            candidates: candidates,
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates[0].name, "Lab iPad")
        XCTAssertEqual(candidates[0].osVersion, "26.3.1")
        XCTAssertEqual(candidates[0].hardwareModel, "iPad14,4")
        XCTAssertFalse(candidates[0].isConnected)
        XCTAssertTrue(candidates[0].hasExplicitConnectionEvidence)
        XCTAssertFalse(candidates[0].isSimulator)
        XCTAssertFalse(candidates[0].isEligibleConnectedDevice)
        XCTAssertEqual(report.status, .blockedNoConnectedIPhone12FamilyDevice)
        XCTAssertEqual(report.unavailableIOSPhysicalDeviceRecords.count, 1)
        XCTAssertEqual(report.connectedUnsupportedIOSPhysicalDeviceRecords.count, 0)
        XCTAssertTrue(report.markdown.contains("Unavailable iOS physical device records: 1"))
        XCTAssertTrue(report.markdown.contains("Connected unsupported iOS physical device records: 0"))
    }

    func testIOSL12DevicectlParserSkipsDiagnosticBracesBeforeJSONPayload() {
        let output = """
        Failed to load provisioning paramter list due to error: Error Domain=com.apple.dt.CoreDeviceError Code=1002 "No provider was found." UserInfo={NSLocalizedDescription=No provider was found.}.
        `devicectl manage create` may support a reduced set of arguments.
        Name         Hostname                             Identifier                             State                Model
        ----------   ----------------------------------   ------------------------------------   ------------------   ----------------------------------------------
        Lab iPad     Lab-iPad.coredevice.local            shared-ipad-identifier                 available (paired)   iPad Pro (11-inch) (4th generation) (iPad14,4)
        {
          "info" : {
            "jsonVersion" : 3,
            "outcome" : "success"
          },
          "result" : {
            "devices" : [
              {
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "disconnected"
                },
                "deviceProperties" : {
                  "name" : "Lab iPad",
                  "osVersionNumber" : "26.3.1 (a)"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPad Pro (11-inch) (4th generation)",
                  "productType" : "iPad14,4",
                  "reality" : "physical"
                },
                "identifier" : "shared-ipad-identifier"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_188),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_178),
            candidates: candidates,
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates[0].name, "Lab iPad")
        XCTAssertEqual(candidates[0].osVersion, "26.3.1")
        XCTAssertEqual(candidates[0].hardwareModel, "iPad14,4")
        XCTAssertFalse(candidates[0].isConnected)
        XCTAssertTrue(candidates[0].hasExplicitConnectionEvidence)
        XCTAssertFalse(candidates[0].isSimulator)
        XCTAssertEqual(report.status, .blockedNoConnectedIPhone12FamilyDevice)
        XCTAssertEqual(report.unavailableIOSPhysicalDeviceRecords.count, 1)
        XCTAssertEqual(report.connectedUnsupportedIOSPhysicalDeviceRecords.count, 0)
    }

    func testIOSL12DevicectlParserUsesTablePhysicalEvidenceWhenJSONRealityIsMissing() {
        let output = """
        Name         Hostname                             Identifier                             State                Model
        ----------   ----------------------------------   ------------------------------------   ------------------   ----------------------------------------------
        AlicePhone   AlicePhone.coredevice.local          shared-iphone-12                       available (paired)   iPhone 12 Pro (iPhone13,3)
        {
          "result" : {
            "devices" : [
              {
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "AlicePhone",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,3"
                },
                "identifier" : "shared-iphone-12"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_179),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_169),
            candidates: candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_170
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates[0].name, "AlicePhone")
        XCTAssertEqual(candidates[0].osVersion, "18.6")
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,3")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertFalse(candidates[0].isSimulator)
        XCTAssertFalse(candidates[0].hasExplicitSimulatorEvidence)
        XCTAssertTrue(candidates[0].isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
    }

    func testIOSL12DevicectlJSONParserAcceptsAlternateHardwareAndOSKeys() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "paired"
                },
                "deviceProperties" : {
                  "name" : "Product Type Fallback",
                  "operatingSystemVersion" : "18.6 (22G86)"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPhone 12 Pro Max",
                  "thinningProductType" : "iPhone13,4",
                  "hardwareModel" : "D54pAP",
                  "reality" : "physical"
                },
                "identifier" : "alternate-product-type"
              },
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "paired"
                },
                "deviceProperties" : {
                  "name" : "Marketing Name Fallback",
                  "osVersion" : "18.5"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPhone 12 mini",
                  "hardwareModel" : "D52gAP",
                  "reality" : "physical"
                },
                "identifier" : "alternate-marketing-name"
              },
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "paired"
                },
                "deviceProperties" : {
                  "name" : "Hardware Model Fallback",
                  "osVersion" : "18.4"
                },
                "hardwareProperties" : {
                  "hardwareModel" : "iPhone13,3",
                  "deviceType" : "iPhone",
                  "reality" : "physical"
                },
                "identifier" : "alternate-hardware-model"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,4")
        XCTAssertEqual(candidates[0].osVersion, "18.6")
        XCTAssertTrue(candidates[0].isVerifiedEligibleConnectedDevice)

        XCTAssertEqual(candidates[1].hardwareModel, "iPhone 12 mini")
        XCTAssertEqual(candidates[1].osVersion, "18.5")
        XCTAssertTrue(candidates[1].isVerifiedEligibleConnectedDevice)

        XCTAssertEqual(candidates[2].hardwareModel, "iPhone13,3")
        XCTAssertEqual(candidates[2].osVersion, "18.4")
        XCTAssertTrue(candidates[2].isVerifiedEligibleConnectedDevice)
    }

    func testIOSL12DevicectlJSONParserAcceptsAdditionalCoreDeviceHardwareAndRealityKeys() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "deviceProperties" : {
                  "name" : "Hardware Identifier Phone",
                  "productVersion" : "18.6.1",
                  "deviceReality" : "physical"
                },
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "state" : "available"
                },
                "hardwareProperties" : {
                  "hardwareIdentifier" : "iPhone13,1"
                },
                "identifier" : "hardware-identifier-phone"
              },
              {
                "deviceProperties" : {
                  "name" : "Product Identifier Phone"
                },
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "availability" : "available"
                },
                "hardwareProperties" : {
                  "productIdentifier" : "iPhone13,2",
                  "deviceReality" : "physical"
                },
                "identifier" : "product-identifier-phone",
                "operatingSystemVersion" : {
                  "major" : 18,
                  "minor" : 5,
                  "patch" : 1
                }
              },
              {
                "deviceProperties" : {
                  "name" : "Model Identifier Phone",
                  "systemVersion" : "18.4 (22E240)"
                },
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "hardwareProperties" : {
                  "modelIdentifier" : "iPhone13,3",
                  "targetType" : "physical"
                },
                "identifier" : "model-identifier-phone"
              },
              {
                "state" : "available",
                "deviceProperties" : {
                  "name" : "Simulator Class Phone",
                  "platformType" : "physical"
                },
                "hardwareProperties" : {
                  "deviceClass" : "iPhone13,4",
                  "runtime" : "com.apple.CoreSimulator.SimRuntime.iOS-18-6"
                },
                "identifier" : "simulator-class-phone"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 4)

        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,1")
        XCTAssertEqual(candidates[0].osVersion, "18.6.1")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertFalse(candidates[0].isSimulator)
        XCTAssertTrue(candidates[0].isVerifiedEligibleConnectedDevice)

        XCTAssertEqual(candidates[1].hardwareModel, "iPhone13,2")
        XCTAssertEqual(candidates[1].osVersion, "18.5.1")
        XCTAssertTrue(candidates[1].isConnected)
        XCTAssertFalse(candidates[1].isSimulator)
        XCTAssertTrue(candidates[1].isVerifiedEligibleConnectedDevice)

        XCTAssertEqual(candidates[2].hardwareModel, "iPhone13,3")
        XCTAssertEqual(candidates[2].osVersion, "18.4")
        XCTAssertTrue(candidates[2].isConnected)
        XCTAssertFalse(candidates[2].isSimulator)
        XCTAssertTrue(candidates[2].isVerifiedEligibleConnectedDevice)

        XCTAssertEqual(candidates[3].hardwareModel, "iPhone13,4")
        XCTAssertTrue(candidates[3].isConnected)
        XCTAssertTrue(candidates[3].isSimulator)
        XCTAssertFalse(candidates[3].isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(candidates[3].eligibilityReason, .simulatorDestination)
    }

    func testIOSL12DevicectlJSONParserUsesAvailabilityStateAndFailsClosedWithoutConnectionEvidence() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "state" : "available",
                "deviceProperties" : {
                  "name" : "State Only iPhone 12",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,1",
                  "reality" : "physical"
                },
                "identifier" : "state-only-iphone-12"
              },
              {
                "state" : "unavailable",
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Unavailable iPhone 12",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,2",
                  "reality" : "physical"
                },
                "identifier" : "unavailable-iphone-12"
              },
              {
                "deviceProperties" : {
                  "name" : "Unknown Availability iPhone 12",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,3",
                  "reality" : "physical"
                },
                "identifier" : "unknown-availability-iphone-12"
              },
              {
                "state" : "Available (paired)",
                "connectionProperties" : {
                  "pairingState" : "Paired",
                  "tunnelState" : "Connected"
                },
                "deviceProperties" : {
                  "name" : "Mixed Case iPhone 12",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,4",
                  "reality" : "physical"
                },
                "identifier" : "mixed-case-iphone-12"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 4)
        XCTAssertEqual(candidates[0].name, "State Only iPhone 12")
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,1")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertTrue(candidates[0].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[1].name, "Unavailable iPhone 12")
        XCTAssertEqual(candidates[1].hardwareModel, "iPhone13,2")
        XCTAssertFalse(candidates[1].isConnected)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[2].name, "Unknown Availability iPhone 12")
        XCTAssertEqual(candidates[2].hardwareModel, "iPhone13,3")
        XCTAssertFalse(candidates[2].isConnected)
        XCTAssertFalse(candidates[2].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[3].name, "Mixed Case iPhone 12")
        XCTAssertEqual(candidates[3].hardwareModel, "iPhone13,4")
        XCTAssertTrue(candidates[3].isConnected)
        XCTAssertTrue(candidates[3].isEligibleConnectedDevice)
    }

    func testIOSL12DevicectlJSONParserRejectsDisconnectedAvailabilityQualifiers() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "state" : "available (unpaired)",
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Unpaired State Phone",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,3",
                  "reality" : "physical"
                },
                "identifier" : "unpaired-state-phone"
              },
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "available (not paired)",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Not Paired Phone",
                  "osVersionNumber" : "18.5"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,1",
                  "reality" : "physical"
                },
                "identifier" : "not-paired-phone"
              },
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Connected Phone",
                  "osVersionNumber" : "18.4"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,4",
                  "reality" : "physical"
                },
                "identifier" : "connected-phone"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_612),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_602),
            candidates: candidates,
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,3")
        XCTAssertFalse(candidates[0].isConnected)
        XCTAssertFalse(candidates[0].isEligibleConnectedDevice)
        XCTAssertEqual(candidates[0].eligibilityReason, .disconnectedPhysicalDevice)

        XCTAssertEqual(candidates[1].hardwareModel, "iPhone13,1")
        XCTAssertFalse(candidates[1].isConnected)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)
        XCTAssertEqual(candidates[1].eligibilityReason, .disconnectedPhysicalDevice)

        XCTAssertEqual(candidates[2].hardwareModel, "iPhone13,4")
        XCTAssertTrue(candidates[2].isConnected)
        XCTAssertTrue(candidates[2].isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(report.status, .blockedIncompleteManualFlow)
        XCTAssertEqual(report.verifiedEligibleConnectedDevices.count, 1)
    }

    func testIOSL12DevicectlJSONParserAcceptsNestedStateAndVersionFields() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "state" : {
                  "status" : "available (paired)"
                },
                "connectionProperties" : {
                  "pairingState" : {
                    "rawValue" : "paired"
                  },
                  "tunnelState" : {
                    "state" : "connected"
                  }
                },
                "deviceProperties" : {
                  "name" : "Nested State Phone",
                  "operatingSystemVersion" : {
                    "major" : 18,
                    "minor" : 6,
                    "patch" : 1
                  }
                },
                "hardwareProperties" : {
                  "productType" : {
                    "stringValue" : "iPhone13,3"
                  },
                  "reality" : {
                    "value" : "physical"
                  }
                },
                "identifier" : "nested-state-phone"
              },
              {
                "availability" : {
                  "state" : "unavailable"
                },
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Unavailable Nested Phone",
                  "osVersion" : {
                    "versionString" : "18.5 (22F76)"
                  }
                },
                "hardwareProperties" : {
                  "productType" : {
                    "rawValue" : "iPhone13,4"
                  },
                  "reality" : {
                    "name" : "physical"
                  }
                },
                "identifier" : "unavailable-nested-phone"
              },
              {
                "state" : {
                  "status" : "available"
                },
                "connectionProperties" : {
                  "pairingState" : {
                    "rawValue" : "unpaired"
                  },
                  "tunnelState" : {
                    "state" : "connected"
                  }
                },
                "deviceProperties" : {
                  "name" : "Unpaired Nested Phone",
                  "operatingSystemVersion" : {
                    "majorVersion" : 18,
                    "minorVersion" : 4
                  }
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,1",
                  "reality" : {
                    "status" : "physical"
                  }
                },
                "identifier" : "unpaired-nested-phone"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,3")
        XCTAssertEqual(candidates[0].osVersion, "18.6.1")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertFalse(candidates[0].isSimulator)
        XCTAssertTrue(candidates[0].isVerifiedEligibleConnectedDevice)

        XCTAssertEqual(candidates[1].hardwareModel, "iPhone13,4")
        XCTAssertEqual(candidates[1].osVersion, "18.5")
        XCTAssertFalse(candidates[1].isConnected)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[2].hardwareModel, "iPhone13,1")
        XCTAssertEqual(candidates[2].osVersion, "18.4")
        XCTAssertFalse(candidates[2].isConnected)
        XCTAssertFalse(candidates[2].isEligibleConnectedDevice)
    }

    func testIOSL12DevicectlJSONParserAcceptsRootIdentifierAndBooleanConnectionFields() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "available" : true,
                "deviceProperties" : {
                  "name" : "Root Identifier Phone",
                  "operatingSystemVersion" : {
                    "major" : 18,
                    "minor" : 6
                  }
                },
                "hardwareProperties" : {
                  "marketingName" : "iPhone 12 Pro",
                  "productType" : "iPhone13,3",
                  "reality" : "physical"
                },
                "udid" : "root-identifier-phone"
              },
              {
                "connected" : false,
                "deviceProperties" : {
                  "name" : "Disconnected Root Identifier Phone",
                  "osVersionNumber" : "18.5"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPhone 12 mini",
                  "productType" : "iPhone13,1",
                  "reality" : "physical"
                },
                "deviceIdentifier" : "disconnected-root-identifier-phone"
              },
              {
                "connectionProperties" : {
                  "isAvailable" : "yes"
                },
                "deviceProperties" : {
                  "name" : "Nested Boolean Phone",
                  "osVersionNumber" : "18.4"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,4",
                  "reality" : "physical"
                },
                "id" : "nested-boolean-phone"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 3)

        XCTAssertEqual(candidates[0].identifier, "root-identifier-phone")
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,3")
        XCTAssertEqual(candidates[0].osVersion, "18.6")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertTrue(candidates[0].hasExplicitConnectionEvidence)
        XCTAssertTrue(candidates[0].isVerifiedEligibleConnectedDevice)

        XCTAssertEqual(candidates[1].identifier, "disconnected-root-identifier-phone")
        XCTAssertEqual(candidates[1].hardwareModel, "iPhone13,1")
        XCTAssertFalse(candidates[1].isConnected)
        XCTAssertTrue(candidates[1].hasExplicitConnectionEvidence)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[2].identifier, "nested-boolean-phone")
        XCTAssertEqual(candidates[2].hardwareModel, "iPhone13,4")
        XCTAssertTrue(candidates[2].isConnected)
        XCTAssertTrue(candidates[2].hasExplicitConnectionEvidence)
        XCTAssertTrue(candidates[2].isVerifiedEligibleConnectedDevice)
    }

    func testIOSL12DevicectlJSONParserFailsClosedWithoutPhysicalRealityEvidence() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Missing Reality iPhone 12",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,2"
                },
                "identifier" : "missing-reality-iphone-12"
              },
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Virtual iPhone 12",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,2",
                  "reality" : "virtual"
                },
                "identifier" : "virtual-iphone-12"
              },
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Explicit Physical iPhone 12",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,2",
                  "reality" : "Physical"
                },
                "identifier" : "physical-iphone-12"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,2")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertTrue(candidates[0].isSimulator)
        XCTAssertFalse(candidates[0].isEligibleConnectedDevice)
        XCTAssertFalse(candidates[0].hasVerifiedIPhone12FamilyHardwareEvidence)
        XCTAssertEqual(candidates[0].eligibilityReason, .simulatorDestination)

        XCTAssertTrue(candidates[1].isSimulator)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)

        XCTAssertFalse(candidates[2].isSimulator)
        XCTAssertTrue(candidates[2].isEligibleConnectedDevice)
        XCTAssertTrue(candidates[2].hasVerifiedIPhone12FamilyHardwareEvidence)
    }

    func testIOSL12DevicectlJSONParserRejectsSimulatorMarkersDespitePhysicalReality() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected",
                  "transportType" : "CoreSimulator"
                },
                "deviceProperties" : {
                  "name" : "Simulator Named Like Phone",
                  "osVersionNumber" : "18.6",
                  "platform" : "com.apple.platform.iphonesimulator"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,3",
                  "deviceType" : "iOS Simulator",
                  "reality" : "physical"
                },
                "identifier" : "simulator-named-like-phone"
              },
              {
                "state" : "available",
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Physical Phone",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "productType" : "iPhone13,3",
                  "reality" : "physical"
                },
                "identifier" : "physical-phone"
              }
            ]
          }
        }
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 2)
        XCTAssertEqual(candidates[0].name, "Simulator Named Like Phone")
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,3")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertTrue(candidates[0].isSimulator)
        XCTAssertFalse(candidates[0].isEligibleConnectedDevice)
        XCTAssertFalse(candidates[0].hasVerifiedIPhone12FamilyHardwareEvidence)
        XCTAssertEqual(candidates[0].eligibilityReason, .simulatorDestination)

        XCTAssertEqual(candidates[1].name, "Physical Phone")
        XCTAssertFalse(candidates[1].isSimulator)
        XCTAssertTrue(candidates[1].isVerifiedEligibleConnectedDevice)
    }

    func testIOSL12DevicectlDeviceListParserExtractsHardwareIdentifiersFromTableOutput() {
        let output = """
        Failed to load provisioning paramter list due to error: Error Domain=com.apple.dt.CoreDeviceError Code=1002 "No provider was found."
        Name         Hostname                             Identifier                             State         Model
        ----------   ----------------------------------   ------------------------------------   -----------   ----------------------------------------------
        Turbulence   Turbulence.coredevice.local          0CBD6373-CEB0-5A7E-B47F-F6A136CFD179   unavailable   iPhone 15 Pro (iPhone16,1)
        王威扬的iPad     wangweiyangdeiPad.coredevice.local   99297749-FED4-550D-A57A-E741118B99E1   unavailable   iPad Pro (11-inch) (4th generation) (iPad14,4)
        AlicePhone   AlicePhone.coredevice.local          11111111-2222-3333-4444-555555555555   available     iPhone 12 Pro Max (iPhone13,4)
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].name, "Turbulence")
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone16,1")
        XCTAssertFalse(candidates[0].isConnected)
        XCTAssertFalse(candidates[0].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[1].name, "王威扬的iPad")
        XCTAssertEqual(candidates[1].hardwareModel, "iPad14,4")
        XCTAssertFalse(candidates[1].isConnected)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[2].name, "AlicePhone")
        XCTAssertEqual(candidates[2].hardwareModel, "iPhone13,4")
        XCTAssertTrue(candidates[2].isConnected)
        XCTAssertTrue(candidates[2].isEligibleConnectedDevice)
    }

    func testIOSL12DevicectlTableParserPreservesSpacesInsideDeviceAndModelNames() {
        let output = """
        Name              Hostname                               Identifier                             State         Model
        ---------------   ------------------------------------   ------------------------------------   -----------   ----------------------------------------------
        Alice iPhone 12   Alice-iPhone-12.coredevice.local       11111111-2222-3333-4444-555555555555   available     iPhone 12 mini (iPhone13,1)
        QA Lab Phone      QA-Lab-Phone.coredevice.local          22222222-3333-4444-5555-666666666666   available     iPhone 15 Pro Simulator (iPhone16,1)
        Bob Pro Max       Bob-Pro-Max.coredevice.local           33333333-4444-5555-6666-777777777777   unavailable   iPhone 12 Pro Max (iPhone13,4)
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].name, "Alice iPhone 12")
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,1")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertTrue(candidates[0].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[1].name, "QA Lab Phone")
        XCTAssertEqual(candidates[1].hardwareModel, "iPhone16,1")
        XCTAssertTrue(candidates[1].isSimulator)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[2].name, "Bob Pro Max")
        XCTAssertEqual(candidates[2].hardwareModel, "iPhone13,4")
        XCTAssertFalse(candidates[2].isConnected)
        XCTAssertFalse(candidates[2].isEligibleConnectedDevice)
    }

    func testIOSL12DevicectlTableParserNormalizesParenthesizedAvailabilityState() {
        let output = """
        Name              Hostname                               Identifier                             State                  Model
        ---------------   ------------------------------------   ------------------------------------   --------------------   ----------------------------------------------
        Alice iPhone 12   Alice-iPhone-12.coredevice.local       11111111-2222-3333-4444-555555555555   available (paired)    iPhone 12 Pro (iPhone13,3)
        Lab iPhone 12     Lab-iPhone-12.coredevice.local         22222222-3333-4444-5555-666666666666   unavailable (paired)  iPhone 12 mini (iPhone13,1)
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 2)
        XCTAssertEqual(candidates[0].name, "Alice iPhone 12")
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,3")
        XCTAssertTrue(candidates[0].isConnected)
        XCTAssertTrue(candidates[0].isEligibleConnectedDevice)

        XCTAssertEqual(candidates[1].name, "Lab iPhone 12")
        XCTAssertEqual(candidates[1].hardwareModel, "iPhone13,1")
        XCTAssertFalse(candidates[1].isConnected)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)
    }

    func testIOSL12DevicectlTableParserRejectsDisconnectedAvailabilityQualifiers() {
        let output = """
        Name              Hostname                               Identifier                             State                     Model
        ---------------   ------------------------------------   ------------------------------------   -----------------------   ----------------------------------------------
        Unpaired Phone    Unpaired.coredevice.local              11111111-2222-3333-4444-555555555555   available (unpaired)      iPhone 12 Pro (iPhone13,3)
        Offline Phone     Offline.coredevice.local               22222222-3333-4444-5555-666666666666   available (offline)       iPhone 12 mini (iPhone13,1)
        Trusted Phone     Trusted.coredevice.local               33333333-4444-5555-6666-777777777777   available (paired)        iPhone 12 Pro Max (iPhone13,4)
        """

        let candidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)

        XCTAssertEqual(candidates.count, 3)
        XCTAssertEqual(candidates[0].hardwareModel, "iPhone13,3")
        XCTAssertFalse(candidates[0].isConnected)
        XCTAssertFalse(candidates[0].isEligibleConnectedDevice)
        XCTAssertEqual(candidates[0].eligibilityReason, .disconnectedPhysicalDevice)

        XCTAssertEqual(candidates[1].hardwareModel, "iPhone13,1")
        XCTAssertFalse(candidates[1].isConnected)
        XCTAssertFalse(candidates[1].isEligibleConnectedDevice)
        XCTAssertEqual(candidates[1].eligibilityReason, .disconnectedPhysicalDevice)

        XCTAssertEqual(candidates[2].hardwareModel, "iPhone13,4")
        XCTAssertTrue(candidates[2].isConnected)
        XCTAssertTrue(candidates[2].isEligibleConnectedDevice)
    }

    func testIOSL12DeviceProbeCandidateMergerCombinesXctraceAndDevicectlEvidence() {
        let xctraceCandidates = [
            IOSStageOnePhysicalDeviceCandidate(
                name: "Mac",
                osVersion: nil,
                identifier: "mac-local",
                isConnected: true,
                isSimulator: false
            ),
            IOSStageOnePhysicalDeviceCandidate(
                name: "Turbulence",
                osVersion: "26.1",
                identifier: "00008130-001935383CBA001C",
                isConnected: false,
                isSimulator: false
            ),
            IOSStageOnePhysicalDeviceCandidate(
                name: "iPhone 12",
                osVersion: "26.4.1",
                identifier: "sim-iphone12",
                isConnected: true,
                isSimulator: true
            )
        ]
        let devicectlCandidates = [
            IOSStageOnePhysicalDeviceCandidate(
                name: "Turbulence",
                osVersion: nil,
                identifier: "0CBD6373-CEB0-5A7E-B47F-F6A136CFD179",
                hardwareModel: "iPhone16,1",
                isConnected: false,
                isSimulator: false
            ),
            IOSStageOnePhysicalDeviceCandidate(
                name: "Lab iPhone",
                osVersion: "18.6",
                identifier: "lab-iphone-12",
                hardwareModel: "iPhone13,3",
                isConnected: true,
                isSimulator: false
            )
        ]

        let merged = IOSStageOneDeviceProbeCandidateMerger().merge([
            xctraceCandidates,
            devicectlCandidates
        ])

        XCTAssertEqual(merged.count, 4)
        XCTAssertEqual(merged[1].name, "Turbulence")
        XCTAssertEqual(merged[1].osVersion, "26.1")
        XCTAssertEqual(merged[1].identifier, "00008130-001935383CBA001C")
        XCTAssertEqual(merged[1].hardwareModel, "iPhone16,1")
        XCTAssertFalse(merged[1].isConnected)
        XCTAssertEqual(merged[1].eligibilityReason, .disconnectedPhysicalDevice)

        XCTAssertEqual(merged[2].name, "iPhone 12")
        XCTAssertTrue(merged[2].isSimulator)
        XCTAssertEqual(merged[2].eligibilityReason, .simulatorDestination)

        XCTAssertEqual(merged[3].name, "Lab iPhone")
        XCTAssertEqual(merged[3].hardwareModel, "iPhone13,3")
        XCTAssertTrue(merged[3].isEligibleConnectedDevice)
    }

    func testIOSL12DeviceProbeCandidateMergerKeepsXctracePhysicalClassificationWhenDevicectlRealityIsMissing() {
        let merged = IOSStageOneDeviceProbeCandidateMerger().merge([
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "xctrace-physical-phone",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: nil,
                    identifier: "devicectl-physical-phone",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: true,
                    hasExplicitSimulatorEvidence: false
                )
            ]
        ])
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_183),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_173),
            candidates: merged,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_174
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].name, "QA iPhone 12 Pro")
        XCTAssertEqual(merged[0].osVersion, "18.6")
        XCTAssertEqual(merged[0].hardwareModel, "iPhone13,3")
        XCTAssertTrue(merged[0].isConnected)
        XCTAssertFalse(merged[0].isSimulator)
        XCTAssertFalse(merged[0].hasExplicitSimulatorEvidence)
        XCTAssertTrue(merged[0].isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
    }

    func testIOSL12DeviceProbeCandidateMergerKeepsExplicitConnectionWhenHardwareRowLacksConnectionEvidence() {
        let merged = IOSStageOneDeviceProbeCandidateMerger().merge([
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "xctrace-physical-phone",
                    isConnected: true,
                    isSimulator: false,
                    hasExplicitConnectionEvidence: true
                )
            ],
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: nil,
                    identifier: "devicectl-hardware-row",
                    hardwareModel: "iPhone13,3",
                    isConnected: false,
                    isSimulator: false,
                    hasExplicitConnectionEvidence: false
                )
            ]
        ])
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_183),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_173),
            candidates: merged,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_174
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].hardwareModel, "iPhone13,3")
        XCTAssertTrue(merged[0].isConnected)
        XCTAssertTrue(merged[0].hasExplicitConnectionEvidence)
        XCTAssertTrue(merged[0].isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresExplicitConnectionEvidenceForEligibleHardware() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_184),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_174),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "iphone-12-family-without-connection-source",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false,
                    hasExplicitConnectionEvidence: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_175
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertFalse(report.candidates[0].isEligibleConnectedDevice)
        XCTAssertFalse(report.candidates[0].isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(report.candidates[0].eligibilityReason, .missingExplicitConnectionEvidence)
        XCTAssertEqual(report.status, .blockedMissingExplicitConnectionEvidence)
        XCTAssertTrue(report.capturesRealDeviceGateEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertEqual(report.connectedIPhone12FamilyDevicesMissingExplicitConnectionEvidence.count, 1)
        XCTAssertTrue(
            report.markdown.contains(
                "Connected iPhone 12-family devices missing explicit connection evidence: 1"
            )
        )
        XCTAssertTrue(
            report.markdown.contains(
                "current physical-device probe did not include an explicit connected/available signal"
            )
        )
        XCTAssertTrue(
            report.markdown.contains(
                "| connection-unverified-iphone12-family-device-1 | iPhone13,3 | 18.6 | yes | no | no | yes | missingExplicitConnectionEvidence |"
            )
        )
    }

    func testIOSL12DeviceProbeCandidateMergerDoesNotMergeExplicitSimulatorEvidenceByName() {
        let merged = IOSStageOneDeviceProbeCandidateMerger().merge([
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "xctrace-physical-phone",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: nil,
                    identifier: "simulator-like-phone",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: true,
                    hasExplicitSimulatorEvidence: true
                )
            ]
        ])

        XCTAssertEqual(merged.count, 2)
        XCTAssertFalse(merged[0].isSimulator)
        XCTAssertTrue(merged[1].isSimulator)
        XCTAssertTrue(merged[1].hasExplicitSimulatorEvidence)
        XCTAssertFalse(merged[1].isEligibleConnectedDevice)
    }

    func testIOSL12DeviceProbeCandidateMergerFailsClosedOnConnectionConflicts() {
        let merged = IOSStageOneDeviceProbeCandidateMerger().merge([
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "shared-iphone-12",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: nil,
                    identifier: "shared-iphone-12",
                    hardwareModel: "iPhone13,3",
                    isConnected: false,
                    isSimulator: false
                )
            ]
        ])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].hardwareModel, "iPhone13,3")
        XCTAssertFalse(merged[0].isConnected)
        XCTAssertFalse(merged[0].isEligibleConnectedDevice)
        XCTAssertEqual(merged[0].eligibilityReason, .disconnectedPhysicalDevice)
    }

    func testIOSL12DeviceProbeCandidateMergerFailsClosedOnHardwareIdentityConflicts() {
        let merged = IOSStageOneDeviceProbeCandidateMerger().merge([
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "shared-physical-device",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: nil,
                    identifier: "shared-physical-device",
                    hardwareModel: "iPhone16,1",
                    isConnected: true,
                    isSimulator: false
                )
            ]
        ])

        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_182),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_172),
            candidates: merged,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_173
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(merged.count, 1)
        XCTAssertNil(merged[0].hardwareModel)
        XCTAssertTrue(merged[0].isConnected)
        XCTAssertFalse(merged[0].isEligibleConnectedDevice)
        XCTAssertFalse(merged[0].hasVerifiedIPhone12FamilyHardwareEvidence)
        XCTAssertEqual(report.status, .blockedNoConnectedIPhone12FamilyDevice)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Verified iPhone 12-family hardware evidence connected: 0"))
        XCTAssertTrue(
            report.markdown.contains("| connected-non-iphone12-device-1 | unknown | 18.6 | yes | no | no | no |")
        )
    }

    func testIOSL12DeviceProbeCandidateMergerKeepsCompatibleHardwareIdentitySignals() {
        let merged = IOSStageOneDeviceProbeCandidateMerger().merge([
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "shared-physical-device",
                    hardwareModel: "iPhone 12 Pro (iPhone13,3)",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: nil,
                    identifier: "shared-physical-device",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ]
        ])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].hardwareModel, "iPhone 12 Pro (iPhone13,3)")
        XCTAssertTrue(merged[0].isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(merged[0].manualEvidenceHardwareSignals, ["iphone13,3", "iphone 12 pro"])
    }

    func testIOSL12DeviceProbeCandidateMergerKeepsCompatibleThinnedProductIdentifiers() {
        let merged = IOSStageOneDeviceProbeCandidateMerger().merge([
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 mini",
                    osVersion: "18.6",
                    identifier: "shared-physical-device",
                    hardwareModel: "iPhone13,1-A",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 mini",
                    osVersion: nil,
                    identifier: "shared-physical-device",
                    hardwareModel: "iPhone13,1",
                    isConnected: true,
                    isSimulator: false
                )
            ]
        ])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].hardwareModel, "iPhone13,1-A")
        XCTAssertTrue(merged[0].isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(merged[0].manualEvidenceHardwareSignals, ["iphone13,1"])
    }

    func testIOSL12DeviceProbeCandidateMergerKeepsCompatibleMarketingNameAndProductIdentifier() {
        let merged = IOSStageOneDeviceProbeCandidateMerger().merge([
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro Max",
                    osVersion: "18.6",
                    identifier: "shared-physical-device",
                    hardwareModel: "iPhone 12 Pro Max",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro Max",
                    osVersion: nil,
                    identifier: "shared-physical-device",
                    hardwareModel: "iPhone13,4",
                    isConnected: true,
                    isSimulator: false
                )
            ]
        ])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].hardwareModel, "iPhone 12 Pro Max")
        XCTAssertTrue(merged[0].isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(merged[0].manualEvidenceHardwareSignals, ["iphone 12 pro max"])
    }

    func testIOSL12RealDeviceValidationReportCanUseParsedDevicectlHardwareEvidence() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "Custom Named Phone",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPhone 12",
                  "productType" : "iPhone13,2",
                  "reality" : "physical"
                },
                "identifier" : "iphone-12-family-device"
              }
            ]
          }
        }
        """
        let parsedCandidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_180),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_170),
            candidates: parsedCandidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,2",
                observedAtBase: 1_777_806_171
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertEqual(report.eligibleConnectedDevices.first?.deviceFamilyName, "iPhone13,2")
        XCTAssertTrue(
            report.markdown.contains("| verified-iphone12-family-device-1 | iPhone13,2 | 18.6 | yes | no | yes | yes |")
        )
        XCTAssertFalse(report.markdown.contains("Custom Named Phone"))
    }

    func testIOSL12RealDeviceValidationCanonicalizesThinnedProductIdentifiers() {
        let thinnedCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA iPhone 12 Pro",
            osVersion: "18.6",
            identifier: "thinned-iphone-12-pro",
            hardwareModel: "iPhone13,3-A",
            isConnected: true,
            isSimulator: false
        )
        let parenthesizedThinnedCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA iPhone 12 mini",
            osVersion: "18.6",
            identifier: "parenthesized-thinned-iphone-12-mini",
            hardwareModel: "iPhone 12 mini (iPhone13,1-A)",
            isConnected: true,
            isSimulator: false
        )
        let unsupportedThinnedCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "Unsupported iPhone",
            osVersion: "18.6",
            identifier: "unsupported-thinned-iphone",
            hardwareModel: "iPhone13,30-A",
            isConnected: true,
            isSimulator: false
        )
        let malformedThinnedCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "Malformed iPhone",
            osVersion: "18.6",
            identifier: "malformed-thinned-iphone",
            hardwareModel: "iPhone13,3-",
            isConnected: true,
            isSimulator: false
        )
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_181),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_171),
            candidates: [thinnedCandidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_172
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(thinnedCandidate.isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(thinnedCandidate.manualEvidenceHardwareSignals, ["iphone13,3"])
        XCTAssertTrue(parenthesizedThinnedCandidate.isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(parenthesizedThinnedCandidate.manualEvidenceHardwareSignals, [
            "iphone13,1",
            "iphone 12 mini"
        ])
        XCTAssertFalse(unsupportedThinnedCandidate.isEligibleConnectedDevice)
        XCTAssertFalse(unsupportedThinnedCandidate.hasVerifiedIPhone12FamilyHardwareEvidence)
        XCTAssertFalse(malformedThinnedCandidate.isEligibleConnectedDevice)
        XCTAssertFalse(malformedThinnedCandidate.hasVerifiedIPhone12FamilyHardwareEvidence)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(
            report.markdown.contains("| verified-iphone12-family-device-1 | iPhone13,3-A | 18.6 | yes | no | yes | yes |")
        )
    }

    func testIOSL12RealDeviceValidationAcceptsDevicectlMarketingNameWithHardwareSuffix() {
        let output = """
        {
          "result" : {
            "devices" : [
              {
                "connectionProperties" : {
                  "pairingState" : "paired",
                  "tunnelState" : "connected"
                },
                "deviceProperties" : {
                  "name" : "QA Physical Device",
                  "osVersionNumber" : "18.6"
                },
                "hardwareProperties" : {
                  "marketingName" : "iPhone 12 Pro Max (iPhone13,4)",
                  "reality" : "physical"
                },
                "identifier" : "qa-iphone-12-pro-max"
              }
            ]
          }
        }
        """
        let parsedCandidates = IOSDevicectlDeviceListParser().parseCandidates(from: output)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_185),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_175),
            candidates: parsedCandidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,4",
                observedAtBase: 1_777_806_176
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(parsedCandidates.first?.hardwareModel, "iPhone 12 Pro Max (iPhone13,4)")
        XCTAssertTrue(parsedCandidates.first?.isEligibleConnectedDevice == true)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(
            report.markdown.contains("| verified-iphone12-family-device-1 | iPhone 12 Pro Max (iPhone13,4) | 18.6 | yes | no | yes | yes |")
        )
        XCTAssertFalse(report.markdown.contains("QA Physical Device"))
    }

    func testIOSL12RealDeviceValidationRejectsConflictingMarketingNameAndProductIdentifier() {
        let conflictingCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA Conflicting Device",
            osVersion: "18.6",
            identifier: "physical-conflicting-device",
            hardwareModel: "iPhone 12 Pro (iPhone16,1)",
            isConnected: true,
            isSimulator: false
        )
        let matchingCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA iPhone 12 Pro",
            osVersion: "18.6",
            identifier: "physical-iphone-12-pro",
            hardwareModel: "iPhone 12 Pro (iPhone13,3)",
            isConnected: true,
            isSimulator: false
        )
        let conflictingReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_188),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_178),
            candidates: [conflictingCandidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_179
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertFalse(conflictingCandidate.isIPhone12FamilyPhysicalDevice)
        XCTAssertFalse(conflictingCandidate.hasVerifiedIPhone12FamilyHardwareEvidence)
        XCTAssertFalse(conflictingCandidate.isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(conflictingCandidate.manualEvidenceHardwareSignals, [])
        XCTAssertEqual(conflictingCandidate.eligibilityReason, .unsupportedHardwareFamily)
        XCTAssertEqual(conflictingReport.status, .blockedConnectedUnsupportedPhysicalDevice)
        XCTAssertFalse(conflictingReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(
            conflictingReport.markdown.contains(
                "| connected-non-iphone12-device-1 | iPhone 12 Pro (iPhone16,1) | 18.6 | yes | no | no | no | unsupportedHardwareFamily |"
            )
        )

        XCTAssertTrue(matchingCandidate.isVerifiedEligibleConnectedDevice)
        XCTAssertEqual(matchingCandidate.manualEvidenceHardwareSignals, [
            "iphone13,3",
            "iphone 12 pro"
        ])
    }

    func testIOSL12RealDeviceValidationAcceptsMixedCaseHardwareSignals() {
        let identifierCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA iPhone",
            osVersion: "18.6",
            identifier: "mixed-case-hardware-identifier",
            hardwareModel: "IPHONE13,3",
            isConnected: true,
            isSimulator: false
        )
        let marketingCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA iPhone Pro Max",
            osVersion: "18.6",
            identifier: "mixed-case-marketing-name",
            hardwareModel: "iphone 12 pro max",
            isConnected: true,
            isSimulator: false
        )
        let plainMarketingCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA Plain iPhone 12",
            osVersion: "18.6",
            identifier: "mixed-case-plain-marketing-name",
            hardwareModel: "IPHONE 12",
            isConnected: true,
            isSimulator: false
        )

        XCTAssertTrue(identifierCandidate.isEligibleConnectedDevice)
        XCTAssertTrue(identifierCandidate.hasVerifiedIPhone12FamilyHardwareEvidence)
        XCTAssertEqual(identifierCandidate.manualEvidenceHardwareSignals, ["iphone13,3"])

        XCTAssertTrue(marketingCandidate.isEligibleConnectedDevice)
        XCTAssertTrue(marketingCandidate.hasVerifiedIPhone12FamilyHardwareEvidence)
        XCTAssertEqual(marketingCandidate.manualEvidenceHardwareSignals, ["iphone 12 pro max"])

        XCTAssertTrue(plainMarketingCandidate.isEligibleConnectedDevice)
        XCTAssertFalse(plainMarketingCandidate.hasVerifiedIPhone12FamilyHardwareEvidence)
        XCTAssertEqual(plainMarketingCandidate.manualEvidenceHardwareSignals, [])
    }

    func testIOSL12RealDeviceValidationReportUsesParsedXctraceCandidates() {
        let output = """
        == Devices ==
        Mac (E61742AC-8496-56E3-9159-8DA00247F3E5)

        == Simulators ==
        iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)
        """
        let parsedCandidates = IOSXctraceDeviceListParser().parseCandidates(from: output)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_290),
            candidates: parsedCandidates,
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedNoConnectedIPhone12FamilyDevice)
        XCTAssertEqual(report.eligibleConnectedDevices, [])
        XCTAssertTrue(report.hasCurrentDeviceProbeEvidence)
        XCTAssertTrue(report.hasRequiredPhysicalProbeCommandCoverage)
        XCTAssertEqual(report.missingRequiredPhysicalProbeCommands, [])
        XCTAssertTrue(report.capturesRealDeviceGateEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Real-device validation complete: false"))
        XCTAssertTrue(report.markdown.contains("Device probe current: true"))
        XCTAssertTrue(report.markdown.contains("Missing physical probe commands: none"))
        XCTAssertTrue(report.markdown.contains("| connected-non-iphone12-device-1 | unknown | unknown | yes | no | no | no |"))
        XCTAssertTrue(report.markdown.contains("| simulator-destination-2 | unknown | 26.4.1 | yes | yes | no | no |"))
    }

    func testIOSL12RealDeviceValidationSummarizesUnavailableIOSPhysicalInventory() {
        let generatedAt = Date(timeIntervalSince1970: 1_777_806_302)
        let candidates = [
            IOSStageOnePhysicalDeviceCandidate(
                name: "Mac",
                osVersion: nil,
                identifier: "mac-host",
                isConnected: true,
                isSimulator: false
            ),
            IOSStageOnePhysicalDeviceCandidate(
                name: "Turbulence",
                osVersion: "26.1",
                identifier: "iphone-15-pro-record",
                hardwareModel: "iPhone16,1",
                isConnected: false,
                isSimulator: false
            ),
            IOSStageOnePhysicalDeviceCandidate(
                name: "Lab iPad",
                osVersion: "26.3.1",
                identifier: "ipad-pro-record",
                hardwareModel: "iPad14,4",
                isConnected: false,
                isSimulator: false
            ),
            IOSStageOnePhysicalDeviceCandidate(
                name: "iPhone 12",
                osVersion: "26.4.1",
                identifier: "iphone-12-simulator",
                hardwareModel: "iPhone13,2",
                isConnected: true,
                isSimulator: true
            )
        ]
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: generatedAt.addingTimeInterval(-10),
            candidates: candidates,
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedNoConnectedIPhone12FamilyDevice)
        XCTAssertEqual(report.iosPhysicalDeviceRecords.count, 2)
        XCTAssertEqual(report.unavailableIOSPhysicalDeviceRecords.count, 2)
        XCTAssertEqual(report.connectedUnsupportedIOSPhysicalDeviceRecords.count, 0)
        XCTAssertEqual(report.connectedUnsupportedPhysicalDevices.count, 0)
        XCTAssertEqual(report.eligibleConnectedDevices.count, 0)
        XCTAssertTrue(report.markdown.contains("iOS physical device records discovered: 2"))
        XCTAssertTrue(report.markdown.contains("Unavailable iOS physical device records: 2"))
        XCTAssertTrue(report.markdown.contains("Connected unsupported iOS physical device records: 0"))
        XCTAssertTrue(report.markdown.contains("Connected unsupported physical devices: 0"))
        XCTAssertFalse(report.markdown.contains("Mac | unknown | unknown | yes | no"))
    }

    func testIOSL12RealDeviceValidationSummarizesConnectedUnsupportedIOSPhysicalInventory() {
        let generatedAt = Date(timeIntervalSince1970: 1_777_806_303)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: generatedAt.addingTimeInterval(-10),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Mac",
                    osVersion: nil,
                    identifier: "mac-host",
                    isConnected: true,
                    isSimulator: false
                ),
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Lab iPad",
                    osVersion: "26.3.1",
                    identifier: "ipad-pro-record",
                    hardwareModel: "iPad14,4",
                    isConnected: true,
                    isSimulator: false
                ),
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12",
                    osVersion: "26.4.1",
                    identifier: "iphone-12-simulator",
                    hardwareModel: "iPhone13,2",
                    isConnected: true,
                    isSimulator: true
                )
            ],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedConnectedUnsupportedPhysicalDevice)
        XCTAssertEqual(report.iosPhysicalDeviceRecords.count, 1)
        XCTAssertEqual(report.unavailableIOSPhysicalDeviceRecords.count, 0)
        XCTAssertEqual(report.connectedUnsupportedIOSPhysicalDeviceRecords.count, 1)
        XCTAssertEqual(report.connectedUnsupportedPhysicalDevices.count, 1)
        XCTAssertEqual(report.connectedUnsupportedIOSPhysicalDeviceRecords.first?.hardwareModel, "iPad14,4")
        XCTAssertTrue(report.markdown.contains("iOS physical device records discovered: 1"))
        XCTAssertTrue(report.markdown.contains("Unavailable iOS physical device records: 0"))
        XCTAssertTrue(report.markdown.contains("Connected unsupported iOS physical device records: 1"))
        XCTAssertTrue(report.markdown.contains("Connected unsupported physical devices: 1"))
        XCTAssertFalse(report.markdown.contains("Mac | unknown | unknown | yes | no"))
    }

    func testIOSL12RealDeviceValidationClassifiesNameOnlyConnectedUnsupportedIOSHardware() {
        let generatedAt = Date(timeIntervalSince1970: 1_777_806_304)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: generatedAt.addingTimeInterval(-10),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Mac",
                    osVersion: nil,
                    identifier: "mac-host",
                    isConnected: true,
                    isSimulator: false
                ),
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 15 Pro",
                    osVersion: "18.6",
                    identifier: "xctrace-name-only-iphone-15-pro",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedConnectedUnsupportedPhysicalDevice)
        XCTAssertEqual(report.iosPhysicalDeviceRecords.count, 1)
        XCTAssertEqual(report.connectedUnsupportedIOSPhysicalDeviceRecords.count, 1)
        XCTAssertEqual(report.connectedUnsupportedPhysicalDevices.count, 1)
        XCTAssertEqual(report.connectedUnsupportedIOSPhysicalDeviceRecords.first?.name, "iPhone 15 Pro")
        XCTAssertTrue(report.capturesRealDeviceGateEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Status: blockedConnectedUnsupportedPhysicalDevice"))
        XCTAssertTrue(report.markdown.contains("Connected unsupported iOS physical device records: 1"))
        XCTAssertTrue(report.markdown.contains("| connected-non-iphone12-device-2 | unknown | 18.6 | yes | no | no | no | unsupportedHardwareFamily |"))
        XCTAssertFalse(report.markdown.contains("Mac | unknown | unknown | yes | no"))
        XCTAssertFalse(report.markdown.contains("iPhone 15 Pro | unknown"))
    }

    func testIOSL12RealDeviceValidationClassifiesFutureNameOnlyIPhoneHardwareAsUnsupported() {
        let generatedAt = Date(timeIntervalSince1970: 1_777_806_304)
        let futureIPhoneReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: generatedAt.addingTimeInterval(-10),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 18 Pro Max",
                    osVersion: "28.1",
                    identifier: "xctrace-name-only-future-iphone",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let iphone12NameOnlyReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: generatedAt.addingTimeInterval(-10),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "xctrace-name-only-iphone-12-pro",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(futureIPhoneReport.status, .blockedConnectedUnsupportedPhysicalDevice)
        XCTAssertEqual(futureIPhoneReport.iosPhysicalDeviceRecords.count, 1)
        XCTAssertEqual(futureIPhoneReport.connectedUnsupportedIOSPhysicalDeviceRecords.count, 1)
        XCTAssertEqual(futureIPhoneReport.connectedUnsupportedPhysicalDevices.count, 1)
        XCTAssertTrue(futureIPhoneReport.capturesRealDeviceGateEvidence)
        XCTAssertFalse(futureIPhoneReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(futureIPhoneReport.markdown.contains("Connected unsupported iOS physical device records: 1"))
        XCTAssertTrue(
            futureIPhoneReport.markdown.contains(
                "| connected-non-iphone12-device-1 | unknown | 28.1 | yes | no | no | no | unsupportedHardwareFamily |"
            )
        )

        XCTAssertEqual(iphone12NameOnlyReport.status, .blockedMissingVerifiedHardwareEvidence)
        XCTAssertEqual(iphone12NameOnlyReport.connectedUnsupportedIOSPhysicalDeviceRecords.count, 0)
        XCTAssertEqual(iphone12NameOnlyReport.eligibleConnectedDevices.count, 1)
        XCTAssertTrue(iphone12NameOnlyReport.verifiedEligibleConnectedDevices.isEmpty)
    }

    func testIOSL12RealDeviceValidationRequiresVerifiedHardwareEvidenceForCompletion() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_305),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_295),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "xctrace-name-only-iphone-12-pro",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(hardwareSignal: "iPhone13,2"),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: [
                "xcrun xctrace list devices",
                "xcrun devicectl list devices --json-output -"
            ]
        )

        XCTAssertEqual(report.status, .blockedMissingVerifiedHardwareEvidence)
        XCTAssertEqual(report.eligibleConnectedDevices.count, 1)
        XCTAssertTrue(report.verifiedEligibleConnectedDevices.isEmpty)
        XCTAssertTrue(report.capturesRealDeviceGateEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Verified iPhone 12-family hardware evidence connected: 0"))
        XCTAssertTrue(report.markdown.contains("no verified iPhone 12-family hardware model or product identifier"))
        XCTAssertTrue(report.markdown.contains("| unverified-iphone12-family-device-1 | unknown | 18.6 | yes | no | yes | no |"))
    }

    func testIOSL12RealDeviceValidationTreatsPlainIPhone12MarketingNameAsUnverifiedHardwareEvidence() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_306),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_296),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA Device",
                    osVersion: "18.6",
                    identifier: "marketing-name-only-iphone-12",
                    hardwareModel: "iPhone 12",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "physical iPhone 12"
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedMissingVerifiedHardwareEvidence)
        XCTAssertEqual(report.eligibleConnectedDevices.count, 1)
        XCTAssertTrue(report.verifiedEligibleConnectedDevices.isEmpty)
        XCTAssertTrue(report.capturesRealDeviceGateEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertEqual(report.verifiedConnectedHardwareEvidenceSignals, [])
        XCTAssertTrue(report.markdown.contains("Verified iPhone 12-family hardware evidence connected: 0"))
        XCTAssertTrue(
            report.markdown.contains("| unverified-iphone12-family-device-1 | iPhone 12 | 18.6 | yes | no | yes | no |")
        )
    }

    func testIOSL12RealDeviceValidationReportPreservesMultipleProbeCommands() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_310),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_300),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12",
                    osVersion: "26.4.1",
                    identifier: "sim-iphone-12",
                    isConnected: true,
                    isSimulator: true
                )
            ],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommand: "xcrun xctrace list devices",
            probeCommands: [
                "xcrun xctrace list devices",
                "xcrun devicectl list devices --json-output -",
                "xcrun simctl list devices available | rg 'iPhone 12'",
                "xcrun xctrace list devices"
            ]
        )

        XCTAssertEqual(report.status, .blockedNoConnectedIPhone12FamilyDevice)
        XCTAssertTrue(report.hasRequiredPhysicalProbeCommandCoverage)
        XCTAssertEqual(report.physicalProbeCommandCoverageStatus, .satisfied)
        XCTAssertEqual(report.missingRequiredPhysicalProbeCommands, [])
        XCTAssertEqual(
            report.probeCommands,
            [
                "xcrun xctrace list devices",
                "xcrun devicectl list devices --json-output -",
                "xcrun simctl list devices available | rg 'iPhone 12'"
            ]
        )
        XCTAssertTrue(
            report.markdown.contains(
                "- Probe commands: xcrun xctrace list devices; xcrun devicectl list devices --json-output -; xcrun simctl list devices available"
            )
        )
        XCTAssertTrue(report.markdown.contains("- Physical probe command coverage: true"))
        XCTAssertTrue(report.markdown.contains("- Physical probe command coverage status: satisfied"))
        XCTAssertTrue(report.markdown.contains("- Missing physical probe commands: none"))
        XCTAssertTrue(report.markdown.contains("| Required physical probe command | Status | Observed at |"))
        XCTAssertTrue(report.markdown.contains("| xcrun xctrace list devices | PASS | 2026-05-03T11:05:00Z |"))
        XCTAssertTrue(report.markdown.contains("| xcrun devicectl list devices --json-output - | PASS | 2026-05-03T11:05:00Z |"))
        XCTAssertTrue(
            report.markdown.contains(
                "No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was reported by xcrun xctrace list devices; xcrun devicectl list devices --json-output -; xcrun simctl list devices available"
            )
        )
    }

    func testIOSL12RealDeviceValidationNormalizesDuplicateProbeCommandStrings() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_312),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_302),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12",
                    osVersion: "26.4.1",
                    identifier: "sim-iphone-12",
                    isConnected: true,
                    isSimulator: true
                )
            ],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: [
                "xcrun xctrace list devices",
                "XCRUN    XCTRACE   LIST   DEVICES",
                "xcrun devicectl list devices --json-output -",
                "xcrun    devicectl    list    devices    --json-output    -"
            ]
        )

        XCTAssertEqual(
            report.probeCommands,
            [
                "xcrun xctrace list devices",
                "xcrun devicectl list devices --json-output -"
            ]
        )
        XCTAssertEqual(report.missingRequiredPhysicalProbeCommands, [])
        XCTAssertEqual(report.physicalProbeCommandCoverageStatus, .satisfied)
        XCTAssertEqual(report.status, .blockedNoConnectedIPhone12FamilyDevice)
        XCTAssertTrue(
            report.markdown.contains(
                "- Probe commands: xcrun xctrace list devices; xcrun devicectl list devices --json-output -"
            )
        )
        XCTAssertFalse(report.markdown.contains("XCRUN"))
        XCTAssertFalse(report.markdown.contains("xcrun    devicectl"))
    }

    func testIOSL12RealDeviceValidationReportDefaultsEmptyProbeCommandsToXctrace() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_315),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_305),
            candidates: [],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: [" ", "\n"]
        )

        XCTAssertEqual(report.probeCommand, "xcrun xctrace list devices")
        XCTAssertEqual(report.probeCommands, ["xcrun xctrace list devices"])
        XCTAssertFalse(report.hasRequiredPhysicalProbeCommandCoverage)
        XCTAssertEqual(report.physicalProbeCommandCoverageStatus, .blockedMissingRequiredCommands)
        XCTAssertEqual(report.status, .blockedMissingRequiredProbeCommands)
        XCTAssertEqual(
            report.missingRequiredPhysicalProbeCommands,
            ["xcrun devicectl list devices --json-output -"]
        )
        XCTAssertTrue(report.markdown.contains("- Probe commands: xcrun xctrace list devices"))
        XCTAssertTrue(report.markdown.contains("- Physical probe command coverage: false"))
        XCTAssertTrue(report.markdown.contains("- Physical probe command coverage status: blockedMissingRequiredCommands"))
        XCTAssertTrue(
            report.markdown.contains(
                "- Missing physical probe commands: xcrun devicectl list devices --json-output -"
            )
        )
        XCTAssertTrue(report.markdown.contains("| xcrun xctrace list devices | PASS | 2026-05-03T11:05:05Z |"))
        XCTAssertTrue(report.markdown.contains("| xcrun devicectl list devices --json-output - | MISSING | missing |"))
        XCTAssertTrue(report.markdown.contains("Status: blockedMissingRequiredProbeCommands"))
        XCTAssertTrue(report.markdown.contains("must record both required sources"))
    }

    func testIOSL12RealDeviceValidationReportKeepsGateBlockedWithoutConnectedIPhone12FamilyHardware() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_000),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_805_990),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Mac",
                    osVersion: nil,
                    identifier: "local-mac",
                    isConnected: true,
                    isSimulator: false
                ),
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12",
                    osVersion: "26.4.1",
                    identifier: "sim-iphone-12",
                    isConnected: true,
                    isSimulator: true
                ),
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Turbulence",
                    osVersion: "26.1",
                    identifier: "offline-phone",
                    isConnected: false,
                    isSimulator: false
                )
            ],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedNoConnectedIPhone12FamilyDevice)
        XCTAssertTrue(report.eligibleConnectedDevices.isEmpty)
        XCTAssertTrue(report.simulatorPrerequisitesPassed)
        XCTAssertTrue(report.hasCurrentDeviceProbeEvidence)
        XCTAssertTrue(report.capturesRealDeviceGateEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertEqual(report.missingFlowSteps, Set(IOSStageOneRealDeviceFlowStep.allCases))
        XCTAssertTrue(report.markdown.contains("Status: blockedNoConnectedIPhone12FamilyDevice"))
        XCTAssertTrue(report.markdown.contains("Simulator prerequisites passed: true"))
        XCTAssertTrue(report.markdown.contains("Real-device validation complete: false"))
        XCTAssertTrue(report.markdown.contains("Physical iPhone 12-family devices connected: 0"))
        XCTAssertTrue(report.markdown.contains("No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max"))
        XCTAssertTrue(report.markdown.contains("| simulator-destination-2 | unknown | 26.4.1 | yes | yes | no |"))
        XCTAssertTrue(report.markdown.contains("| Open Markdown | OPEN |"))
        XCTAssertTrue(report.markdown.contains("| Rotate reader | OPEN |"))
    }

    func testIOSL12RealDeviceValidationRequiresCurrentDeviceProbeEvidence() {
        let candidates = [
            IOSStageOnePhysicalDeviceCandidate(
                name: "iPhone 12 Pro",
                osVersion: "18.6",
                identifier: "physical-iphone-12-pro",
                hardwareModel: "iPhone13,3",
                isConnected: true,
                isSimulator: false
            )
        ]
        let generatedAt = Date(timeIntervalSince1970: 1_777_806_500)
        let staleReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_802_899),
            candidates: candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(hardwareSignal: "iPhone13,2"),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let futureReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_501),
            candidates: candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(hardwareSignal: "iPhone13,3"),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true
        )

        XCTAssertEqual(staleReport.status, .blockedStaleDeviceProbe)
        XCTAssertFalse(staleReport.hasCurrentDeviceProbeEvidence)
        XCTAssertFalse(staleReport.capturesRealDeviceGateEvidence)
        XCTAssertFalse(staleReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(staleReport.markdown.contains("Device probe current: false"))
        XCTAssertTrue(staleReport.markdown.contains("missing, stale, or newer than the report timestamp"))

        XCTAssertEqual(futureReport.status, .blockedStaleDeviceProbe)
        XCTAssertFalse(futureReport.hasCurrentDeviceProbeEvidence)
        XCTAssertFalse(futureReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresCurrentManualFlowEvidence() {
        let candidates = [
            IOSStageOnePhysicalDeviceCandidate(
                name: "iPhone 12 Pro",
                osVersion: "18.6",
                identifier: "physical-iphone-12-pro",
                hardwareModel: "iPhone13,3",
                isConnected: true,
                isSimulator: false
            )
        ]
        let generatedAt = Date(timeIntervalSince1970: 1_777_806_500)
        let staleEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_802_899),
                evidenceSummary: realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3")
            )
        }
        let futureEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_501),
                evidenceSummary: realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3")
            )
        }
        let staleReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_490),
            candidates: candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: staleEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let futureReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_490),
            candidates: candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: futureEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(staleReport.status, .blockedStaleManualFlowEvidence)
        XCTAssertTrue(staleReport.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertFalse(staleReport.hasCurrentManualFlowEvidence)
        XCTAssertFalse(staleReport.capturesRealDeviceGateEvidence)
        XCTAssertFalse(staleReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(staleReport.markdown.contains("Manual flow evidence current: false"))
        XCTAssertTrue(staleReport.markdown.contains("Manual flow evidence is stale or newer than the report timestamp"))
        XCTAssertTrue(staleReport.markdown.contains("| Open Markdown | STALE |"))

        XCTAssertEqual(futureReport.status, .blockedStaleManualFlowEvidence)
        XCTAssertFalse(futureReport.hasCurrentManualFlowEvidence)
        XCTAssertFalse(futureReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresSwiftPMAndSimulatorPrerequisites() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_520),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_510),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(hardwareSignal: "iPhone13,3"),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: false,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedMissingPrerequisiteValidation)
        XCTAssertFalse(report.simulatorPrerequisitesPassed)
        XCTAssertFalse(report.capturesRealDeviceGateEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Status: blockedMissingPrerequisiteValidation"))
        XCTAssertTrue(report.markdown.contains("Simulator prerequisites passed: false"))
        XCTAssertTrue(report.markdown.contains("SwiftPM and iPhone 12 simulator build/test prerequisites must pass"))
    }

    func testIOSL12RealDeviceValidationDefaultsPerCommandEvidenceToProbeObservedAt() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_530),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_520),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_521
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.probeCommandEvidence.count, 2)
        XCTAssertEqual(report.physicalProbeCommandCoverageStatus, .satisfied)
        XCTAssertEqual(report.staleRequiredPhysicalProbeCommands, [])
        XCTAssertTrue(report.hasRequiredPhysicalProbeCommandCoverage)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Stale physical probe commands: none"))
    }

    func testIOSL12RealDeviceValidationUsesPerCommandEvidenceAsEffectiveProbeTimestamp() {
        let generatedAt = Date(timeIntervalSince1970: 1_777_806_620)
        let xctraceObservedAt = generatedAt.addingTimeInterval(-30)
        let devicectlObservedAt = generatedAt.addingTimeInterval(-10)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: nil,
            deviceProbeMaximumAge: 60,
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_611
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands,
            probeCommandEvidence: [
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun xctrace list devices",
                    observedAt: xctraceObservedAt
                ),
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun devicectl list devices --json-output -",
                    observedAt: devicectlObservedAt
                )
            ]
        )

        XCTAssertNil(report.deviceProbeObservedAt)
        XCTAssertEqual(report.effectiveDeviceProbeObservedAt, devicectlObservedAt)
        XCTAssertTrue(report.hasCurrentDeviceProbeEvidence)
        XCTAssertTrue(report.hasRequiredPhysicalProbeCommandCoverage)
        XCTAssertTrue(report.hasManualFlowEvidenceAfterCurrentDeviceProbe)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Device probe observed: 2026-05-03T11:10:10Z"))
        XCTAssertTrue(report.markdown.contains("| xcrun xctrace list devices | PASS | 2026-05-03T11:09:50Z |"))
        XCTAssertTrue(report.markdown.contains("| xcrun devicectl list devices --json-output - | PASS | 2026-05-03T11:10:10Z |"))
    }

    func testIOSL12RealDeviceValidationBlocksStaleRequiredPerCommandEvidence() {
        let generatedAt = Date(timeIntervalSince1970: 1_777_806_540)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_530),
            deviceProbeMaximumAge: 60,
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_531
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands,
            probeCommandEvidence: [
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun    xctrace list devices",
                    observedAt: generatedAt.addingTimeInterval(-10)
                ),
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun devicectl list devices --json-output -",
                    observedAt: generatedAt.addingTimeInterval(-61)
                )
            ]
        )

        XCTAssertEqual(report.missingRequiredPhysicalProbeCommands, [])
        XCTAssertEqual(
            report.staleRequiredPhysicalProbeCommands,
            ["xcrun devicectl list devices --json-output -"]
        )
        XCTAssertEqual(report.physicalProbeCommandCoverageStatus, .blockedStaleRequiredCommands)
        XCTAssertFalse(report.hasRequiredPhysicalProbeCommandCoverage)
        XCTAssertEqual(report.status, .blockedStaleRequiredProbeCommands)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Physical probe command coverage status: blockedStaleRequiredCommands"))
        XCTAssertTrue(
            report.markdown.contains(
                "Stale physical probe commands: xcrun devicectl list devices --json-output -"
            )
        )
        XCTAssertTrue(report.markdown.contains("| xcrun xctrace list devices | PASS | 2026-05-03T11:08:50Z |"))
        XCTAssertTrue(report.markdown.contains("| xcrun devicectl list devices --json-output - | STALE | 2026-05-03T11:07:59Z |"))
        XCTAssertTrue(report.markdown.contains("Status: blockedStaleRequiredProbeCommands"))
    }

    func testIOSL12RealDeviceValidationKeepsFreshestDuplicatePerCommandEvidence() {
        let generatedAt = Date(timeIntervalSince1970: 1_777_806_580)
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: generatedAt.addingTimeInterval(-20),
            deviceProbeMaximumAge: 60,
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_573
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands,
            probeCommandEvidence: [
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun devicectl list devices --json-output -",
                    observedAt: generatedAt.addingTimeInterval(-90)
                ),
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun xctrace list devices",
                    observedAt: generatedAt.addingTimeInterval(-10)
                ),
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun    devicectl    list    devices    --json-output    -",
                    observedAt: generatedAt.addingTimeInterval(-8)
                )
            ]
        )

        XCTAssertEqual(report.probeCommandEvidence.count, 2)
        XCTAssertEqual(report.staleRequiredPhysicalProbeCommands, [])
        XCTAssertEqual(report.physicalProbeCommandCoverageStatus, .satisfied)
        XCTAssertTrue(report.hasRequiredPhysicalProbeCommandCoverage)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Stale physical probe commands: none"))
        XCTAssertTrue(report.markdown.contains("| xcrun devicectl list devices --json-output - | PASS | 2026-05-03T11:09:32Z |"))
    }

    func testIOSL12RealDeviceValidationAcceptsCustomNamedIPhone12FamilyHardwareModel() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_150),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_140),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Alice's iPhone",
                    osVersion: "18.6",
                    identifier: "physical-custom-name",
                    hardwareModel: "iPhone 12 Pro Max",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone 12 Pro Max",
                observedAtBase: 1_777_806_141
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertEqual(report.eligibleConnectedDevices.first?.deviceFamilyName, "iPhone 12 Pro Max")
        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertTrue(
            report.markdown.contains("| verified-iphone12-family-device-1 | iPhone 12 Pro Max | 18.6 | yes | no | yes | yes |")
        )
        XCTAssertFalse(report.markdown.contains("Alice's iPhone"))
        XCTAssertTrue(report.markdown.contains("Manual flow evidence complete: true"))
    }

    func testIOSL12RealDeviceValidationAcceptsIPhone12FamilyHardwareIdentifier() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_160),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_150),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Alice's iPhone",
                    osVersion: "18.6",
                    identifier: "physical-product-identifier",
                    hardwareModel: "iPhone13,2",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,2",
                observedAtBase: 1_777_806_151
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertEqual(report.eligibleConnectedDevices.first?.deviceFamilyName, "iPhone13,2")
        XCTAssertTrue(
            report.markdown.contains("| verified-iphone12-family-device-1 | iPhone13,2 | 18.6 | yes | no | yes | yes |")
        )
        XCTAssertFalse(report.markdown.contains("Alice's iPhone"))
    }

    func testIOSL12RealDeviceValidationRejectsNonIPhone12HardwareIdentifier() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_170),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_160),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Alice's iPhone",
                    osVersion: "18.6",
                    identifier: "physical-newer-iphone",
                    hardwareModel: "iPhone14,2",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedConnectedUnsupportedPhysicalDevice)
        XCTAssertTrue(report.eligibleConnectedDevices.isEmpty)
        XCTAssertEqual(report.connectedUnsupportedPhysicalDevices.count, 1)
        XCTAssertTrue(report.capturesRealDeviceGateEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Status: blockedConnectedUnsupportedPhysicalDevice"))
        XCTAssertTrue(report.markdown.contains("Connected unsupported physical devices: 1"))
        XCTAssertTrue(report.markdown.contains("but it is not iPhone 12 / 12 mini / 12 Pro / 12 Pro Max hardware"))
        XCTAssertTrue(
            report.markdown.contains("| connected-non-iphone12-device-1 | iPhone14,2 | 18.6 | yes | no | no | no |")
        )
        XCTAssertFalse(report.markdown.contains("Alice's iPhone"))
    }

    func testIOSL12RealDeviceReportExplainsCandidateEligibilityReasons() {
        let candidates = [
            IOSStageOnePhysicalDeviceCandidate(
                name: "iPhone 12",
                osVersion: "26.4.1",
                identifier: "sim-iphone-12",
                isConnected: true,
                isSimulator: true
            ),
            IOSStageOnePhysicalDeviceCandidate(
                name: "iPhone 12 Pro",
                osVersion: "18.6",
                identifier: "offline-iphone-12-pro",
                isConnected: false,
                isSimulator: false
            ),
            IOSStageOnePhysicalDeviceCandidate(
                name: "Mac",
                osVersion: nil,
                identifier: "local-mac",
                isConnected: true,
                isSimulator: false
            ),
            IOSStageOnePhysicalDeviceCandidate(
                name: "Alice's iPhone",
                osVersion: "18.6",
                identifier: "physical-iphone-12",
                hardwareModel: "iPhone13,2",
                isConnected: true,
                isSimulator: false
            )
        ]
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_180),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_170),
            candidates: candidates,
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(candidates[0].eligibilityReason, .simulatorDestination)
        XCTAssertEqual(candidates[1].eligibilityReason, .disconnectedPhysicalDevice)
        XCTAssertEqual(candidates[2].eligibilityReason, .unsupportedHardwareFamily)
        XCTAssertEqual(candidates[3].eligibilityReason, .eligibleIPhone12FamilyDevice)
        XCTAssertTrue(report.markdown.contains("Eligibility reason"))
        XCTAssertTrue(
            report.markdown.contains("| simulator-destination-1 | unknown | 26.4.1 | yes | yes | no | no | simulatorDestination |")
        )
        XCTAssertTrue(
            report.markdown.contains("| disconnected-physical-device-2 | unknown | 18.6 | no | no | no | no | disconnectedPhysicalDevice |")
        )
        XCTAssertTrue(
            report.markdown.contains("| connected-non-iphone12-device-3 | unknown | unknown | yes | no | no | no | unsupportedHardwareFamily |")
        )
        XCTAssertTrue(
            report.markdown.contains("| verified-iphone12-family-device-4 | iPhone13,2 | 18.6 | yes | no | yes | yes | eligibleIPhone12FamilyDevice |")
        )
        XCTAssertFalse(report.markdown.contains("Alice's iPhone"))
    }

    func testIOSL12RealDeviceReportSanitizesDeviceTableFields() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_190),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_180),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA | Phone\nInjected Row",
                    osVersion: "18.6 | beta",
                    identifier: "physical-device-with-markdown-name",
                    hardwareModel: "iPhone13,2",
                    isConnected: true,
                    isSimulator: false
                ),
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Unsupported Phone",
                    osVersion: "17.5",
                    identifier: "offline-device-with-markdown-model",
                    hardwareModel: "iPhone13,4 | Pro Max",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedIncompleteManualFlow)
        XCTAssertTrue(report.markdown.contains("| verified-iphone12-family-device-1 | iPhone13,2 | 18.6 / beta | yes | no | yes | yes | eligibleIPhone12FamilyDevice |"))
        XCTAssertTrue(report.markdown.contains("| connected-non-iphone12-device-2 | iPhone13,4 / Pro Max | 17.5 | yes | no | no | no | unsupportedHardwareFamily |"))
        XCTAssertFalse(report.markdown.contains("QA | Phone"))
        XCTAssertFalse(report.markdown.contains("Injected Row"))
        XCTAssertFalse(report.markdown.contains("Unsupported Phone"))
        XCTAssertFalse(report.markdown.contains("iPhone13,4 | Pro Max"))
    }

    func testIOSL12RealDeviceReportRedactsProbeIdentifiersFromManualEvidence() {
        let sensitiveEvidence = IOSStageOneRealDeviceFlowEvidence(
            step: .openMarkdown,
            observedAt: Date(timeIntervalSince1970: 1_777_806_401),
            evidenceSummary: "opened Markdown document on physical iPhone 12-family hardware iPhone13,3 from Alice-iPhone.coredevice.local using 11111111-2222-3333-4444-555555555555 and 00008101-0011223344556677",
            probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_400)
        )
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_420),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_400),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Alice iPhone",
                    osVersion: "18.6",
                    identifier: "11111111-2222-3333-4444-555555555555",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: [
                sensitiveEvidence
            ] + completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_402
            ).filter { $0.step != .openMarkdown },
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("[redacted-coredevice-host]"))
        XCTAssertTrue(report.markdown.contains("[redacted-uuid]"))
        XCTAssertTrue(report.markdown.contains("[redacted-device-id]"))
        XCTAssertFalse(report.markdown.contains("Alice-iPhone.coredevice.local"))
        XCTAssertFalse(report.markdown.contains("11111111-2222-3333-4444-555555555555"))
        XCTAssertFalse(report.markdown.contains("00008101-0011223344556677"))
    }

    func testIOSL12RealDeviceReportRedactsSerialAndECIDProbeTokensFromManualEvidence() {
        let sensitiveEvidence = IOSStageOneRealDeviceFlowEvidence(
            step: .openMarkdown,
            observedAt: Date(timeIntervalSince1970: 1_777_806_401),
            evidenceSummary: "opened Markdown document on physical iPhone 12-family hardware iPhone13,3 with serialNumber=CKQ9M219WW and ECID 7095390071029788",
            probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_400)
        )
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_420),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_400),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "serial-ecid-redaction-device",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: [
                sensitiveEvidence
            ] + completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_402
            ).filter { $0.step != .openMarkdown },
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("[redacted-serial-number]"))
        XCTAssertTrue(report.markdown.contains("[redacted-ecid]"))
        XCTAssertFalse(report.markdown.contains("CKQ9M219WW"))
        XCTAssertFalse(report.markdown.contains("7095390071029788"))
    }

    func testIOSL12RealDeviceValidationReportPassesOnlyAfterEligibleDeviceAndFullFlow() {
        let completedReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_100),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_090),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_091
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let incompleteReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_200),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_190),
            candidates: completedReport.candidates,
            completedFlowSteps: [.openMarkdown, .renderRichFixture],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(completedReport.status, .passed)
        XCTAssertTrue(completedReport.capturesRealDeviceGateEvidence)
        XCTAssertTrue(completedReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(completedReport.missingFlowSteps.isEmpty)
        XCTAssertTrue(completedReport.markdown.contains("Real-device validation complete: true"))
        XCTAssertTrue(completedReport.markdown.contains("Manual flow evidence complete: true"))
        XCTAssertTrue(completedReport.markdown.contains("Verified iPhone 12-family hardware evidence connected: 1"))
        XCTAssertTrue(completedReport.markdown.contains("| verified-iphone12-family-device-1 | iPhone13,3 | 18.6 | yes | no | yes | yes |"))
        XCTAssertTrue(completedReport.markdown.contains("| Save writable document | PASS |"))
        XCTAssertTrue(
            completedReport.markdown.contains(
                "| Save writable document | PASS | saved writable fixture and verified dirty state cleared on physical iPhone 12-family hardware iPhone13,3 |"
            )
        )

        XCTAssertEqual(incompleteReport.status, .blockedIncompleteManualFlow)
        XCTAssertFalse(incompleteReport.capturesRealDeviceGateEvidence)
        XCTAssertFalse(incompleteReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(incompleteReport.missingFlowSteps.contains(.saveWritableDocument))
        XCTAssertTrue(incompleteReport.markdown.contains("Real-device validation complete: false"))
        XCTAssertTrue(incompleteReport.markdown.contains("| Save writable document | OPEN |"))
    }

    func testIOSL12RealDeviceValidationRequiresManualEvidenceForEveryCompletedStep() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_250),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_240),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12",
                    hardwareModel: "iPhone13,2",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: [
                IOSStageOneRealDeviceFlowEvidence(
                    step: .openMarkdown,
                    observedAt: Date(timeIntervalSince1970: 1_777_806_251),
                    evidenceSummary: "opened fixture through Files document handoff"
                ),
                IOSStageOneRealDeviceFlowEvidence(
                    step: .renderRichFixture,
                    observedAt: nil,
                    evidenceSummary: "missing timestamp must not complete the step"
                ),
                IOSStageOneRealDeviceFlowEvidence(
                    step: .searchDocument,
                    observedAt: Date(timeIntervalSince1970: 1_777_806_252),
                    evidenceSummary: "   "
                )
            ],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedIncompleteManualFlow)
        XCTAssertTrue(report.missingFlowSteps.isEmpty)
        XCTAssertFalse(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertEqual(report.manualFlowAudit.completedStepsWithEvidence, [.openMarkdown])
        XCTAssertTrue(report.manualFlowAudit.missingEvidenceSteps.contains(.renderRichFixture))
        XCTAssertTrue(report.manualFlowAudit.missingEvidenceSteps.contains(.saveWritableDocument))
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Manual flow evidence complete: false"))
        XCTAssertTrue(report.markdown.contains("| Render rich fixture | OPEN | missing |"))
    }

    func testIOSL12RealDeviceValidationRequiresStepSpecificManualEvidence() {
        let genericHardwareEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_262),
                evidenceSummary: "validated current physical iPhone 12-family hardware iPhone13,3"
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_270),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_260),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: genericHardwareEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertTrue(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertEqual(report.status, .blockedMissingStepSpecificManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Manual flow step-specific evidence complete: false"))
        XCTAssertTrue(report.markdown.contains("| Open Markdown | FLOW-MISSING |"))
        XCTAssertTrue(report.markdown.contains("every required step must describe its specific Stage 1 action"))
    }

    func testIOSL12RealDeviceValidationAcceptsStepSpecificManualEvidence() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_280),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_270),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_271
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Manual flow step-specific evidence complete: true"))
    }

    func testIOSL12RealDeviceValidationRejectsNegatedStepActionManualEvidence() {
        let negatedStepEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_281 + Double(index)),
                evidenceSummary: negatedRealDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3"),
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_280)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: negatedStepEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertTrue(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertEqual(report.status, .blockedMissingStepSpecificManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Manual flow step-specific evidence complete: false"))
        XCTAssertTrue(report.markdown.contains("| Open Markdown | FLOW-MISSING |"))
        XCTAssertTrue(report.markdown.contains("every required step must describe its specific Stage 1 action"))
    }

    func testIOSL12RealDeviceValidationRejectsPostActionFailureManualEvidence() {
        let failedStepEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_281 + Double(index)),
                evidenceSummary: postActionFailureRealDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3"),
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_280)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: failedStepEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertEqual(report.status, .blockedMissingStepSpecificManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("| Open Markdown | FLOW-MISSING |"))
        XCTAssertTrue(report.markdown.contains("every required step must describe its specific Stage 1 action"))
    }

    func testIOSL12RealDeviceValidationAllowsPositiveStepActionWithSimulatorNegation() {
        let positivePhysicalEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_281 + Double(index)),
                evidenceSummary: "not simulator only; \(realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3"))",
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_280)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: positivePhysicalEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertTrue(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresPhysicalIPhone12FamilyManualEvidence() {
        let genericEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_270),
                evidenceSummary: "completed \(step.displayName) during validation run"
            )
        }
        let simulatorEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_275),
                evidenceSummary: "completed \(step.displayName) on iPhone 12 simulator"
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_280),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_270),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12",
                    hardwareModel: "iPhone13,2",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: genericEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let simulatorReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_280),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_270),
            candidates: report.candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: simulatorEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.capturesRealDeviceGateEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Manual flow physical iPhone 12-family evidence complete: false"))
        XCTAssertTrue(report.markdown.contains("| Open Markdown | DEVICE-MISSING |"))
        XCTAssertTrue(report.markdown.contains("every required step must explicitly identify physical iPhone 12-family hardware"))

        XCTAssertEqual(simulatorReport.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertFalse(simulatorReport.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertTrue(simulatorReport.markdown.contains("| Open Markdown | DEVICE-MISSING |"))
    }

    func testIOSL12RealDeviceValidationRejectsBlockerLanguageAsPhysicalManualEvidence() {
        let blockerEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_276),
                evidenceSummary: "blocked: no connected physical iPhone 12-family hardware / iPhone13,3 device was available for \(step.displayName)"
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_280),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_270),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: blockerEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("| Open Markdown | DEVICE-MISSING |"))
        XCTAssertTrue(report.markdown.contains("every required step must explicitly identify physical iPhone 12-family hardware"))
    }

    func testIOSL12RealDeviceValidationRejectsNegatedHardwareSignalAsPhysicalManualEvidence() {
        let negatedHardwareEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_281 + Double(index)),
                evidenceSummary: "\(realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3")); not on physical iPhone 12-family hardware iPhone13,3",
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_280)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: negatedHardwareEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertTrue(report.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("| Open Markdown | DEVICE-MISSING |"))
    }

    func testIOSL12RealDeviceValidationRejectsUnverifiedHardwareClaimAsPhysicalManualEvidence() {
        let unverifiedHardwareEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_281 + Double(index)),
                evidenceSummary: "\(realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3")); could not verify physical iPhone 12-family hardware iPhone13,3",
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_280)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: unverifiedHardwareEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertTrue(report.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("| Open Markdown | DEVICE-MISSING |"))
    }

    func testIOSL12RealDeviceValidationRejectsMissingHardwareDetectionAsPhysicalManualEvidence() {
        let missingDetectionEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_281 + Double(index)),
                evidenceSummary: "\(realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3")); failed to detect current physical iPhone 12-family hardware iPhone13,3",
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_280)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: missingDetectionEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertTrue(report.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("| Open Markdown | DEVICE-MISSING |"))
    }

    func testIOSL12RealDeviceValidationRejectsDisconnectedHardwareManualEvidence() {
        let disconnectedEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_281 + Double(index)),
                evidenceSummary: "\(realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3")); disconnected physical iPhone 12-family hardware iPhone13,3 was present in inventory only",
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_280)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: disconnectedEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertTrue(report.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("| Open Markdown | DEVICE-MISSING |"))
    }

    func testIOSL12RealDeviceValidationRejectsOfflineVerifiedHardwareReference() {
        let offlineEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_281 + Double(index)),
                evidenceSummary: "\(realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3")); offline connected verified hardware signal iPhone13,3",
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_280)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: offlineEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("| Open Markdown | DEVICE-MISSING |"))
    }

    func testIOSL12RealDeviceValidationAllowsPositivePhysicalEvidenceAfterSimulatorNegation() {
        let positivePhysicalEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_281 + Double(index)),
                evidenceSummary: "\(realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3")); not a simulator, physical iPhone 12-family hardware iPhone13,3",
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_280)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_300),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: positivePhysicalEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertTrue(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresManualEvidenceToMatchConnectedHardwareSignal() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_290),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(hardwareSignal: "iPhone13,2"),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let matchedReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_290),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_280),
            candidates: report.candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_281
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedMismatchedPhysicalManualFlowEvidence)
        XCTAssertTrue(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.verifiedConnectedHardwareEvidenceSignals, ["iphone13,3"])
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Manual flow matches connected verified hardware: false"))
        XCTAssertTrue(report.markdown.contains("| Open Markdown | DEVICE-MISMATCH |"))
        XCTAssertTrue(report.markdown.contains("does not match the verified connected hardware signal"))

        XCTAssertEqual(matchedReport.status, .passed)
        XCTAssertTrue(matchedReport.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertTrue(matchedReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRejectsNegatedConnectedHardwareSignalMatch() {
        let negatedMatchedHardwareEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_291 + Double(index)),
                evidenceSummary: "\(realDeviceEvidenceSummary(for: step, hardwareSignal: "physical iPhone 12-family hardware")); did not match connected verified hardware iPhone13,3",
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_290)
            )
        }
        let positiveSimulatorNegationEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_291 + Double(index)),
                evidenceSummary: "not simulator only; \(realDeviceEvidenceSummary(for: step, hardwareSignal: "iPhone13,3"))",
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_290)
            )
        }
        let candidates = [
            IOSStageOnePhysicalDeviceCandidate(
                name: "QA iPhone",
                osVersion: "18.6",
                identifier: "physical-iphone-12-pro",
                hardwareModel: "iPhone13,3",
                isConnected: true,
                isSimulator: false
            )
        ]
        let negatedReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_310),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_290),
            candidates: candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: negatedMatchedHardwareEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let positiveReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_310),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_290),
            candidates: candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: positiveSimulatorNegationEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(negatedReport.manualFlowAudit.hasEvidenceForEveryRequiredStep)
        XCTAssertTrue(negatedReport.manualFlowAudit.hasStepSpecificFlowEvidenceForEveryRequiredStep)
        XCTAssertTrue(negatedReport.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertFalse(negatedReport.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(negatedReport.status, .blockedMismatchedPhysicalManualFlowEvidence)
        XCTAssertFalse(negatedReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(negatedReport.markdown.contains("| Open Markdown | DEVICE-MISMATCH |"))

        XCTAssertTrue(positiveReport.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(positiveReport.status, .passed)
        XCTAssertTrue(positiveReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresBoundedHardwareSignalMatch() {
        let nearMissEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_300),
                evidenceSummary: realDeviceEvidenceSummary(
                    for: step,
                    hardwareSignal: "iPhone13,30"
                )
            )
        }
        let exactSignalEvidence = completeRealDeviceManualFlowEvidence(
            hardwareSignal: "iPhone13,3",
            observedAtBase: 1_777_806_301,
            probeBatchObservedAt: 1_777_806_295
        )
        let candidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA iPhone 12 Pro",
            osVersion: "18.6",
            identifier: "physical-iphone-12-pro",
            hardwareModel: "iPhone13,3",
            isConnected: true,
            isSimulator: false
        )
        let nearMissReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_320),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_295),
            candidates: [candidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: nearMissEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let exactReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_320),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_295),
            candidates: [candidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: exactSignalEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(nearMissReport.verifiedConnectedHardwareEvidenceSignals, ["iphone13,3"])
        XCTAssertTrue(nearMissReport.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertEqual(nearMissReport.status, .blockedMismatchedPhysicalManualFlowEvidence)
        XCTAssertFalse(nearMissReport.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertFalse(nearMissReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(nearMissReport.markdown.contains("| Open Markdown | DEVICE-MISMATCH |"))

        XCTAssertEqual(exactReport.status, .passed)
        XCTAssertTrue(exactReport.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertTrue(exactReport.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertTrue(exactReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresBoundedHardwareTokenForPhysicalManualEvidence() {
        let productTokenOnlyNearMissEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_300),
                evidenceSummary: realDeviceEvidenceSummary(
                    for: step,
                    prefix: "validated",
                    hardwareSignal: "iPhone13,30"
                )
            )
        }
        let exactProductTokenEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_301),
                evidenceSummary: realDeviceEvidenceSummary(
                    for: step,
                    prefix: "validated",
                    hardwareSignal: "iPhone13,3"
                ),
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_295)
            )
        }
        let candidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA iPhone 12 Pro",
            osVersion: "18.6",
            identifier: "physical-iphone-12-pro",
            hardwareModel: "iPhone13,3",
            isConnected: true,
            isSimulator: false
        )
        let nearMissReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_320),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_295),
            candidates: [candidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: productTokenOnlyNearMissEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let exactReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_320),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_295),
            candidates: [candidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: exactProductTokenEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertFalse(nearMissReport.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertEqual(nearMissReport.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertFalse(nearMissReport.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertFalse(nearMissReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(nearMissReport.markdown.contains("| Open Markdown | DEVICE-MISSING |"))

        XCTAssertTrue(exactReport.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertEqual(exactReport.status, .passed)
        XCTAssertTrue(exactReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationDoesNotPrefixMatchLongerMarketingModel() {
        let proCandidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA iPhone",
            osVersion: "18.6",
            identifier: "marketing-name-iphone-12-pro",
            hardwareModel: "iPhone 12 Pro",
            isConnected: true,
            isSimulator: false
        )
        let proMaxEvidence = completeRealDeviceManualFlowEvidence(
            hardwareSignal: "iPhone 12 Pro Max",
            observedAtBase: 1_777_806_331
        )
        let exactProEvidence = completeRealDeviceManualFlowEvidence(
            hardwareSignal: "iPhone 12 Pro",
            observedAtBase: 1_777_806_341,
            probeBatchObservedAt: 1_777_806_330
        )
        let proMaxReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_360),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_330),
            candidates: [proCandidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: proMaxEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let exactProReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_360),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_330),
            candidates: [proCandidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: exactProEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(proCandidate.manualEvidenceHardwareSignals, ["iphone 12 pro"])
        XCTAssertEqual(proMaxReport.status, .blockedMismatchedPhysicalManualFlowEvidence)
        XCTAssertFalse(proMaxReport.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertFalse(proMaxReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(proMaxReport.markdown.contains("| Open Markdown | DEVICE-MISMATCH |"))

        XCTAssertEqual(exactProReport.status, .passed)
        XCTAssertTrue(exactProReport.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertTrue(exactProReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationAcceptsIPhone12ClassHardwareManualEvidence() {
        let candidate = IOSStageOnePhysicalDeviceCandidate(
            name: "QA iPhone 12 Pro",
            osVersion: "18.6",
            identifier: "physical-iphone-12-pro",
            hardwareModel: "iPhone13,3",
            isConnected: true,
            isSimulator: false
        )
        let classHardwareEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_371 + Double(index)),
                evidenceSummary: realDeviceEvidenceSummary(
                    for: step,
                    prefix: "validated on physical",
                    hardwareSignal: "iPhone 12-class hardware iPhone13,3"
                ),
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_370)
            )
        }
        let absentClassHardwareEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_371 + Double(index)),
                evidenceSummary: realDeviceEvidenceSummary(
                    for: step,
                    prefix: "validated",
                    hardwareSignal: "without iPhone 12-class hardware iPhone13,3"
                ),
                probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_370)
            )
        }
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_390),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_370),
            candidates: [candidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: classHardwareEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let absentReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_390),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_370),
            candidates: [candidate],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: absentClassHardwareEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertTrue(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)

        XCTAssertFalse(absentReport.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertEqual(absentReport.status, .blockedMissingPhysicalManualFlowEvidence)
        XCTAssertFalse(absentReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresOneVerifiedHardwareSignalAcrossManualFlow() {
        let splitEvidence = IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_300 + Double(index)),
                evidenceSummary: realDeviceEvidenceSummary(
                    for: step,
                    hardwareSignal: index.isMultiple(of: 2) ? "iPhone13,2" : "iPhone13,3"
                )
            )
        }
        let splitReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_320),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_310),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12",
                    hardwareModel: "iPhone13,2",
                    isConnected: true,
                    isSimulator: false
                ),
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: splitEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let singleDeviceReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_320),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_310),
            candidates: splitReport.candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_311
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(splitReport.status, .blockedSplitPhysicalManualFlowEvidence)
        XCTAssertTrue(splitReport.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertFalse(splitReport.hasManualFlowEvidenceForSingleConnectedVerifiedHardware)
        XCTAssertEqual(splitReport.commonVerifiedHardwareSignalsForCompletedManualFlow, [])
        XCTAssertFalse(splitReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(splitReport.markdown.contains("Manual flow single verified hardware signal complete: false"))
        XCTAssertTrue(splitReport.markdown.contains("no single connected verified device is referenced by every required Stage 1 flow step"))

        XCTAssertEqual(singleDeviceReport.status, .passed)
        XCTAssertTrue(singleDeviceReport.hasManualFlowEvidenceForSingleConnectedVerifiedHardware)
        XCTAssertEqual(singleDeviceReport.commonVerifiedHardwareSignalsForCompletedManualFlow, ["iphone13,3"])
        XCTAssertTrue(singleDeviceReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresManualEvidenceAfterCurrentDeviceProbe() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_400),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_390),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_380
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let postProbeReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_400),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_390),
            candidates: report.candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_391
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .blockedManualFlowBeforeDeviceProbe)
        XCTAssertTrue(report.hasCurrentManualFlowEvidence)
        XCTAssertTrue(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertTrue(report.hasManualFlowEvidenceForSingleConnectedVerifiedHardware)
        XCTAssertFalse(report.hasManualFlowEvidenceAfterCurrentDeviceProbe)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Manual flow observed after current device probe: false"))
        XCTAssertTrue(report.markdown.contains("| Open Markdown | PRE-PROBE |"))
        XCTAssertTrue(report.markdown.contains("every required step must be observed after the current physical-device probe"))

        XCTAssertEqual(postProbeReport.status, .passed)
        XCTAssertTrue(postProbeReport.hasManualFlowEvidenceAfterCurrentDeviceProbe)
        XCTAssertTrue(postProbeReport.completesRequiredRealDeviceValidation)
    }

    func testIOSL12RealDeviceValidationRequiresManualEvidenceForCurrentProbeBatch() {
        let staleBatchEvidence = completeRealDeviceManualFlowEvidence(
            hardwareSignal: "iPhone13,3",
            observedAtBase: 1_777_806_501,
            probeBatchObservedAt: 1_777_806_450
        )
        let currentBatchEvidence = completeRealDeviceManualFlowEvidence(
            hardwareSignal: "iPhone13,3",
            observedAtBase: 1_777_806_511,
            probeBatchObservedAt: 1_777_806_500
        )
        let staleBatchReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_540),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_500),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: staleBatchEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )
        let currentBatchReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_540),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_500),
            candidates: staleBatchReport.candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: currentBatchEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(staleBatchReport.status, .blockedMissingCurrentProbeBatchEvidence)
        XCTAssertTrue(staleBatchReport.hasCurrentManualFlowEvidence)
        XCTAssertTrue(staleBatchReport.hasManualFlowEvidenceAfterCurrentDeviceProbe)
        XCTAssertTrue(staleBatchReport.hasCurrentPostProbeManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertFalse(staleBatchReport.hasManualFlowEvidenceForCurrentProbeBatch)
        XCTAssertFalse(staleBatchReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(staleBatchReport.markdown.contains("Manual flow references current probe batch: false"))
        XCTAssertTrue(staleBatchReport.markdown.contains("| Open Markdown | PROBE-BATCH-MISSING |"))
        XCTAssertTrue(staleBatchReport.markdown.contains("every required step must reference the current physical-device probe batch"))

        XCTAssertEqual(currentBatchReport.status, .passed)
        XCTAssertTrue(currentBatchReport.hasManualFlowEvidenceForCurrentProbeBatch)
        XCTAssertTrue(currentBatchReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(currentBatchReport.markdown.contains("Manual flow references current probe batch: true"))
    }

    func testIOSL12RealDeviceValidationRequiresLatestRequiredProbeTimestampForCurrentBatch() {
        let xctraceObservedAt = Date(timeIntervalSince1970: 1_777_806_500)
        let devicectlObservedAt = Date(timeIntervalSince1970: 1_777_806_505)
        let staleHalfBatchReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_540),
            deviceProbeObservedAt: xctraceObservedAt,
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_506,
                probeBatchObservedAt: xctraceObservedAt.timeIntervalSince1970
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands,
            probeCommandEvidence: [
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun xctrace list devices",
                    observedAt: xctraceObservedAt
                ),
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun devicectl list devices --json-output -",
                    observedAt: devicectlObservedAt
                )
            ]
        )
        let latestBatchReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_540),
            deviceProbeObservedAt: xctraceObservedAt,
            candidates: staleHalfBatchReport.candidates,
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_506,
                probeBatchObservedAt: devicectlObservedAt.timeIntervalSince1970
            ),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands,
            probeCommandEvidence: [
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun xctrace list devices",
                    observedAt: xctraceObservedAt
                ),
                IOSStageOnePhysicalProbeCommandEvidence(
                    command: "xcrun devicectl list devices --json-output -",
                    observedAt: devicectlObservedAt
                )
            ]
        )

        XCTAssertEqual(staleHalfBatchReport.effectiveDeviceProbeObservedAt, devicectlObservedAt)
        XCTAssertEqual(
            staleHalfBatchReport.requiredProbeCommandObservedAtValues,
            [xctraceObservedAt, devicectlObservedAt]
        )
        XCTAssertEqual(staleHalfBatchReport.status, .blockedMissingCurrentProbeBatchEvidence)
        XCTAssertFalse(staleHalfBatchReport.hasManualFlowEvidenceForCurrentProbeBatch)
        XCTAssertFalse(staleHalfBatchReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(staleHalfBatchReport.markdown.contains("Manual flow references current probe batch: false"))
        XCTAssertTrue(staleHalfBatchReport.markdown.contains("| Open Markdown | PROBE-BATCH-MISSING |"))

        XCTAssertEqual(latestBatchReport.status, .passed)
        XCTAssertTrue(latestBatchReport.hasManualFlowEvidenceForCurrentProbeBatch)
        XCTAssertTrue(latestBatchReport.completesRequiredRealDeviceValidation)
        XCTAssertTrue(latestBatchReport.markdown.contains("Manual flow references current probe batch: true"))
    }

    func testIOSL12RealDeviceValidationRequiresCurrentMatchedHardwareEvidenceRows() {
        let currentGenericEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_410),
                evidenceSummary: "current generic evidence for \(step.displayName)"
            )
        }
        let futureMatchedHardwareEvidence = completeRealDeviceManualFlowEvidence(
            hardwareSignal: "iPhone13,3",
            observedAtBase: 1_777_806_430
        )
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_420),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_400),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: currentGenericEvidence + futureMatchedHardwareEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.hasCurrentManualFlowEvidence)
        XCTAssertTrue(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertTrue(report.hasManualFlowEvidenceAfterCurrentDeviceProbe)
        XCTAssertFalse(report.hasCurrentPostProbeManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .blockedStaleManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Manual flow current post-probe connected hardware evidence complete: false"))
        XCTAssertTrue(report.markdown.contains("| Open Markdown | STALE |"))
    }

    func testIOSL12RealDeviceValidationRequiresFreshMatchedHardwareEvidenceRows() {
        let currentGenericEvidence = IOSStageOneRealDeviceFlowStep.allCases.map { step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: 1_777_806_595),
                evidenceSummary: "current generic evidence for \(step.displayName)"
            )
        }
        let staleMatchedHardwareEvidence = completeRealDeviceManualFlowEvidence(
            hardwareSignal: "iPhone13,3",
            observedAtBase: 1_777_806_401
        )
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_600),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_400),
            deviceProbeMaximumAge: 600,
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: currentGenericEvidence + staleMatchedHardwareEvidence,
            manualFlowMaximumEvidenceAge: 60,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertTrue(report.hasCurrentDeviceProbeEvidence)
        XCTAssertTrue(report.hasCurrentManualFlowEvidence)
        XCTAssertTrue(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertTrue(report.hasManualFlowEvidenceAfterCurrentDeviceProbe)
        XCTAssertFalse(report.hasCurrentPostProbeManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertEqual(report.status, .blockedStaleManualFlowEvidence)
        XCTAssertFalse(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(report.markdown.contains("Manual flow current post-probe connected hardware evidence complete: false"))
        XCTAssertTrue(report.markdown.contains("| Open Markdown | STALE |"))
    }

    func testIOSL12RealDeviceReportPrefersPhysicalManualFlowEvidenceRows() {
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_010),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_000),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12",
                    hardwareModel: "iPhone13,2",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: [
                IOSStageOneRealDeviceFlowEvidence(
                    step: .openMarkdown,
                    observedAt: Date(timeIntervalSince1970: 1_777_806_009),
                    evidenceSummary: "completed Open Markdown during validation run"
                )
            ] + completeRealDeviceManualFlowEvidence(),
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.manualFlowAudit.hasPhysicalIPhone12FamilyEvidenceForEveryRequiredStep)
        XCTAssertTrue(
            report.markdown.contains(
                "| Open Markdown | PASS | opened Markdown fixture through Files handoff on physical iPhone 12-family hardware iPhone13,2 |"
            )
        )
        XCTAssertFalse(
            report.markdown.contains(
                "| Open Markdown | PASS | completed Open Markdown during validation run |"
            )
        )
    }

    func testIOSL12RealDeviceReportPrefersMatchingPostProbeHardwareEvidenceRows() {
        let mismatchedCurrentEvidence = IOSStageOneRealDeviceFlowEvidence(
            step: .openMarkdown,
            observedAt: Date(timeIntervalSince1970: 1_777_806_411),
            evidenceSummary: realDeviceEvidenceSummary(
                for: .openMarkdown,
                hardwareSignal: "iPhone13,2"
            )
        )
        let matchingPostProbeEvidence = completeRealDeviceManualFlowEvidence(
            hardwareSignal: "iPhone13,3",
            observedAtBase: 1_777_806_402
        )
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_420),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_400),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: [mismatchedCurrentEvidence] + matchingPostProbeEvidence,
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.hasManualFlowEvidenceForConnectedVerifiedHardware)
        XCTAssertTrue(report.hasManualFlowEvidenceAfterCurrentDeviceProbe)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(
            report.markdown.contains(
                "| Open Markdown | PASS | opened Markdown fixture through Files handoff on physical iPhone 12-family hardware iPhone13,3 |"
            )
        )
        XCTAssertFalse(
            report.markdown.contains(
                "| Open Markdown | PASS | opened Markdown fixture through Files handoff on physical iPhone 12-family hardware iPhone13,2 |"
            )
        )
    }

    func testIOSL12RealDeviceReportPrefersCurrentProbeBatchEvidenceRows() {
        let currentBatchOpenEvidence = IOSStageOneRealDeviceFlowEvidence(
            step: .openMarkdown,
            observedAt: Date(timeIntervalSince1970: 1_777_806_405),
            evidenceSummary: "current-batch opened Markdown document on physical iPhone 12-family hardware iPhone13,3",
            probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_400)
        )
        let newerStaleBatchOpenEvidence = IOSStageOneRealDeviceFlowEvidence(
            step: .openMarkdown,
            observedAt: Date(timeIntervalSince1970: 1_777_806_415),
            evidenceSummary: "newer stale-batch opened Markdown document on physical iPhone 12-family hardware iPhone13,3",
            probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_390)
        )
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_420),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_400),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: [
                currentBatchOpenEvidence,
                newerStaleBatchOpenEvidence
            ] + completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_401,
                probeBatchObservedAt: 1_777_806_400
            ).filter { $0.step != .openMarkdown },
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.hasManualFlowEvidenceForCurrentProbeBatch)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(
            report.markdown.contains(
                "| Open Markdown | PASS | current-batch opened Markdown document on physical iPhone 12-family hardware iPhone13,3 |"
            )
        )
        XCTAssertFalse(
            report.markdown.contains(
                "| Open Markdown | PASS | newer stale-batch opened Markdown document on physical iPhone 12-family hardware iPhone13,3 |"
            )
        )
    }

    func testIOSL12RealDeviceReportPrefersNewestManualEvidenceWhenRankTies() {
        let olderMatchingEvidence = IOSStageOneRealDeviceFlowEvidence(
            step: .openMarkdown,
            observedAt: Date(timeIntervalSince1970: 1_777_806_405),
            evidenceSummary: "older open Markdown document evidence on physical iPhone 12-family hardware iPhone13,3",
            probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_400)
        )
        let newerMatchingEvidence = IOSStageOneRealDeviceFlowEvidence(
            step: .openMarkdown,
            observedAt: Date(timeIntervalSince1970: 1_777_806_415),
            evidenceSummary: "newer open Markdown document evidence on physical iPhone 12-family hardware iPhone13,3",
            probeBatchObservedAt: Date(timeIntervalSince1970: 1_777_806_400)
        )
        let report = IOSStageOneRealDeviceValidationReport(
            generatedAt: Date(timeIntervalSince1970: 1_777_806_420),
            deviceProbeObservedAt: Date(timeIntervalSince1970: 1_777_806_400),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "QA iPhone 12 Pro",
                    osVersion: "18.6",
                    identifier: "physical-iphone-12-pro",
                    hardwareModel: "iPhone13,3",
                    isConnected: true,
                    isSimulator: false
                )
            ],
            completedFlowSteps: Set(IOSStageOneRealDeviceFlowStep.allCases),
            manualFlowEvidence: [
                olderMatchingEvidence,
                newerMatchingEvidence
            ] + completeRealDeviceManualFlowEvidence(
                hardwareSignal: "iPhone13,3",
                observedAtBase: 1_777_806_401
            ).filter { $0.step != .openMarkdown },
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: Self.requiredPhysicalProbeCommands
        )

        XCTAssertEqual(report.status, .passed)
        XCTAssertTrue(report.completesRequiredRealDeviceValidation)
        XCTAssertTrue(
            report.markdown.contains(
                "| Open Markdown | PASS | newer open Markdown document evidence on physical iPhone 12-family hardware iPhone13,3 |"
            )
        )
        XCTAssertFalse(
            report.markdown.contains(
                "| Open Markdown | PASS | older open Markdown document evidence on physical iPhone 12-family hardware iPhone13,3 |"
            )
        )
    }

    func testIOSL11MemoryStressGateAuditsHugeTableCodeImageMetadataAndLargeDocument() {
        let fixtures: [(IOSMemoryStressFixtureKind, String)] = [
            (.hugeTable, generatedHugeTableMarkdown(rowCount: 420, columnCount: 10)),
            (.hugeCodeBlock, generatedHugeCodeBlockMarkdown(lineCount: 1_200)),
            (.hugeImageMetadata, generatedHugeImageMetadataMarkdown()),
            (.largeDocument, generatedLargeMarkdown(repeatedParagraphCount: 1_200))
        ]
        let parser = MarkdownParserAdapter()
        let renderer = MarkdownNativeRenderer()
        let results = fixtures.map { kind, source -> IOSMemoryStressFixtureResult in
            let document = parser.parse(source)
            let rendered = renderer.render(document: document, source: source)
            let layoutAudit = IOSLayoutSafetyAudit(
                lazyRenderingPolicy: IOSReaderScreenEngine().lazyRenderingPolicy,
                iconOnlyControlLabels: IOSReaderAccessibilityPolicy().iconOnlyControlLabels,
                renderedBlocks: rendered
            )

            return IOSMemoryStressFixtureResult(
                kind: kind,
                sourceByteCount: source.utf8.count,
                parsedBlockCount: document.blocks.count,
                renderedBlockCount: rendered.count,
                containsBoundedLocalImageDecodePolicy: rendered.contains {
                    $0.image?.downsamplePolicy?.satisfiesStageOneLocalImageRule == true
                },
                containsPageLevelHorizontalOverflow: !layoutAudit.hasNoPageLevelHorizontalOverflow
            )
        }
        let audit = IOSMemoryStressAutomationAudit(results: results)

        XCTAssertTrue(audit.satisfiesStageOneMemoryStressTests)
        XCTAssertTrue(audit.coversRequiredStressFixtures)
        XCTAssertTrue(audit.allFixturesParseAndRender)
        XCTAssertTrue(audit.imageMetadataUsesBoundedDecodePolicy)
        XCTAssertTrue(audit.noPageLevelHorizontalOverflow)
    }

    func testIOSL11AccessibilitySmokeGateAuditsReaderSearchEditorAndDynamicType() throws {
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let loadResult = makeLoadedDocument(
            displayName: "accessibility.md",
            source: source
        )
        let engine = IOSReaderScreenEngine()
        let ready = engine.readyState(
            loadResult: loadResult,
            renderedBlocks: rendered
        )
        let searching = engine.searchingState(
            from: ready,
            query: "Markdown"
        )
        let dirtyEditing = IOSSourceEditorEngine().updateSource(
            in: IOSSourceEditorEngine().beginFullSourceEditing(
                loadResult: loadResult,
                from: ready
            ),
            currentSource: source + "\nUnsaved"
        ).state
        let policy = IOSReaderAccessibilityPolicy()
        let audit = IOSAccessibilitySmokeAutomationAudit(
            stateAudits: [
                policy.audit(for: ready),
                policy.audit(for: searching),
                policy.audit(for: dirtyEditing)
            ],
            dynamicTypeAudit: policy.dynamicTypeAudit()
        )

        XCTAssertTrue(audit.satisfiesStageOneAccessibilitySmokeTests)
        XCTAssertTrue(audit.labelsEveryIconOnlyControl)
        XCTAssertTrue(audit.voiceOverOrderMatchesVisualOrder)
        XCTAssertTrue(audit.includesSearchAnnouncement)
        XCTAssertTrue(audit.includesDirtyEditAlert)
        XCTAssertTrue(audit.validatesDynamicTypeForAllTiers)
    }

    func testIOSL11ProcessRecoveryGateAuditsDirtyDraftAndRotationSnapshot() throws {
        let suiteName = "FastMDMobileCoreTests.L11ProcessRecovery.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let source = "# Recovery\n\nOriginal"
        let loadResult = makeLoadedDocument(
            displayName: "process-recovery.md",
            source: source
        )
        let ready = IOSReaderScreenEngine().readyState(
            loadResult: loadResult,
            renderedBlocks: MarkdownNativeRenderer().render(
                document: MarkdownParserAdapter().parse(source),
                source: source
            )
        )
        let dirtySession = IOSReaderEditSession(
            mode: .source,
            originalSource: source,
            currentSource: "# Recovery\n\nUnsaved"
        )
        let store = IOSDirtyEditDraftStore(
            storageKey: "l11.process.recovery.\(UUID().uuidString)",
            timeToLive: 60
        )
        let coordinator = IOSDirtyEditRecoveryCoordinator(store: store)
        let now = Date(timeIntervalSince1970: 1_777_804_000)
        let capture = store.captureForBackground(
            activeDocument: loadResult,
            editSession: dirtySession,
            now: now,
            defaults: defaults
        )
        let offer = coordinator.recoveryOffer(
            now: now.addingTimeInterval(5),
            defaults: defaults
        )
        let restoredSession: IOSReaderEditSession?
        if case .restoreDraft(let draft) = offer {
            restoredSession = coordinator.makeRestoredEditSession(
                draft: draft,
                activeDocument: loadResult
            )
        } else {
            restoredSession = nil
        }
        let expiredOffer = coordinator.recoveryOffer(
            now: now.addingTimeInterval(120),
            defaults: defaults
        )
        let snapshot = IOSReaderRuntimeRestorationCoordinator().capture(
            state: ready,
            activeDocument: loadResult,
            scrollPosition: IOSReaderScrollPosition(
                anchorBlockID: ready.renderedBlocks.first?.id,
                yOffsetWithinBlock: 12
            ),
            editSession: dirtySession
        )
        let audit = IOSProcessRecoveryAutomationAudit(
            captureResult: capture,
            recoveryOffer: offer,
            restoredSession: restoredSession,
            expiredRecoveryOffer: expiredOffer,
            restoredSnapshot: snapshot
        )

        XCTAssertTrue(audit.satisfiesStageOneProcessRecoveryTests)
        XCTAssertTrue(audit.storesDirtyDraftForRecovery)
        XCTAssertTrue(audit.offersUnexpiredDraft)
        XCTAssertTrue(audit.restoresDirtyEditSession)
        XCTAssertTrue(audit.clearsExpiredDraft)
        XCTAssertTrue(audit.avoidsPersistentDocumentContentInRotationSnapshot)
    }

    func testIOSL13ReadmeDocumentsFinalBuildTestCommands() throws {
        let readmeURL = Self.packageRoot.appendingPathComponent("README.md")
        let audit = IOSReadmeCommandAudit(
            readmeText: try String(contentsOf: readmeURL, encoding: .utf8)
        )

        XCTAssertTrue(audit.satisfiesStageOneIOSReadmeBuildTestCommands)
        XCTAssertEqual(audit.missingRequiredCommands, [])
        XCTAssertTrue(audit.documentsSwiftPMValidation)
        XCTAssertTrue(audit.documentsIPhone12SimulatorValidation)
        XCTAssertTrue(audit.documentsPhysicalDeviceProbeWithoutCompletionClaim)
        XCTAssertTrue(audit.documentsIOSOnlyDiffCheck)
        XCTAssertTrue(audit.recordsReportLocationAndReconciliationBoundary)
    }

    func testIOSL13ReadmeCommandAuditReportsMissingCommands() {
        let audit = IOSReadmeCommandAudit(readmeText: "swift test\n")

        XCTAssertFalse(audit.satisfiesStageOneIOSReadmeBuildTestCommands)
        XCTAssertFalse(audit.missingRequiredCommands.contains(.swiftPMTest))
        XCTAssertTrue(audit.missingRequiredCommands.contains(.iPhone12SimulatorBuild))
        XCTAssertTrue(audit.missingRequiredCommands.contains(.iPhone12SimulatorTest))
        XCTAssertTrue(audit.missingRequiredCommands.contains(.readmeAuditGate))
        XCTAssertFalse(audit.documentsIPhone12SimulatorValidation)
        XCTAssertFalse(audit.documentsPhysicalDeviceProbeWithoutCompletionClaim)
        XCTAssertFalse(audit.recordsReportLocationAndReconciliationBoundary)
    }

    func testIOSL13ReconciliationEvidenceMapsCurrentIOSChecklistCompletionAndRealDeviceBlocker() throws {
        let generatedAt = Date(timeIntervalSince1970: 1_777_807_000)
        let parser = MarkdownParserAdapter()
        let renderer = MarkdownNativeRenderer()
        let richSource = try richPreviewFixtureSource()
        let richDocument = parser.parse(richSource)
        let richRendered = renderer.render(document: richDocument, source: richSource)
        let conditionalRendererAudit = IOSLocalRendererConditionalGateAudit(
            renderedBlocks: richRendered,
            discoveredRendererAssetPaths: discoveredRendererAssetPaths()
        )
        let simulatorReport = IOSStageOneSimulatorValidationReport(
            generatedAt: generatedAt,
            simulatorIdentifier: "1B6FEADC-308B-4069-B734-3C9C207E633F",
            swiftPMTestPassed: true,
            simulatorAvailable: true,
            xcodebuildBuildPassed: true,
            xcodebuildTestPassed: true,
            testCaseCount: 167,
            resultBundlePath: "/Users/alice/Library/Developer/Xcode/DerivedData/ios/Logs/Test/Test-FastMDMobile.xcresult"
        )
        let realDeviceReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: generatedAt,
            deviceProbeObservedAt: generatedAt.addingTimeInterval(-120),
            candidates: [
                IOSStageOnePhysicalDeviceCandidate(
                    name: "Mac",
                    osVersion: nil,
                    identifier: "mac-local",
                    hardwareModel: nil,
                    isConnected: true,
                    isSimulator: false
                ),
                IOSStageOnePhysicalDeviceCandidate(
                    name: "iPhone 12",
                    osVersion: "26.4.1",
                    identifier: "sim-iphone12",
                    hardwareModel: "iPhone13,2",
                    isConnected: true,
                    isSimulator: true
                )
            ],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true,
            probeCommands: [
                "xcrun xctrace list devices",
                "xcrun devicectl list devices --json-output -"
            ]
        )
        let offMainExecution = IOSOffMainActorExecutionMetadata(
            scheduledWithDetachedTask: true,
            startedOnMainThread: false,
            completedOnMainThread: false
        )
        let diagnostics = IOSDiagnosticsBuilder().snapshot(
            parseMilliseconds: 31.0,
            renderMilliseconds: 66.0,
            searchMilliseconds: 8.0,
            saveMilliseconds: 19.0,
            byteCount: richSource.utf8.count,
            lastErrorCode: nil
        )
        let performanceReport = IOSStageOnePerformanceReport(
            generatedAt: generatedAt,
            audit: IOSPerformanceAutomationAudit(
                measurements: IOSPerformanceAutomationOperation.allCases.map { operation in
                    IOSPerformanceAutomationMeasurement(
                        operation: operation,
                        elapsedMilliseconds: operation == .fontTierSwitch ? 1.0 : 40.0,
                        thresholdMilliseconds: operation == .search ? 1_500 : 3_000,
                        execution: operation == .fontTierSwitch ? nil : offMainExecution
                    )
                },
                testedFontTiers: Set(MobileFontTier.allCases)
            ),
            diagnostics: diagnostics,
            localValidationDeviceName: "SwiftPM XCTest host"
        )
        let securityReport = IOSStageOneSecurityAuditReport(
            generatedAt: generatedAt,
            localImageDownsamplePolicy: IOSLocalImageDownsamplePolicy(),
            securityScopedAccessAudit: IOSSecurityScopedAccessAudit(
                startedAccessCount: 8,
                stoppedAccessCount: 8
            ),
            releasePosture: IOSReleaseSecurityPosture(),
            hostileHTMLAudit: IOSHostileMarkdownFixtureAudit(
                renderedBlocks: renderer.render(
                    document: parser.parse(try fixtureSource(named: "malicious-html.md")),
                    source: try fixtureSource(named: "malicious-html.md")
                )
            ),
            hostileLinkAudit: IOSHostileMarkdownFixtureAudit(
                renderedBlocks: renderer.render(
                    document: parser.parse(try fixtureSource(named: "malicious-links.md")),
                    source: try fixtureSource(named: "malicious-links.md")
                )
            ),
            remoteImageAudit: IOSRemoteImagePrivacyAudit(
                renderedBlocks: renderer.render(
                    document: parser.parse(try fixtureSource(named: "remote-image.md")),
                    source: try fixtureSource(named: "remote-image.md")
                )
            ),
            conditionalRendererAudit: conditionalRendererAudit,
            diagnostics: diagnostics,
            importsWebKitRichRendererCode: importsWebKitRichRendererCode(),
            rendererAssetInventoryCommand: IOSRendererAssetInventory.defaultInventoryCommand
        )
        let richFixtureReport = IOSRichFixtureRenderReport(
            generatedAt: generatedAt,
            audit: IOSRichFixtureRenderAudit(
                sourceByteCount: richSource.utf8.count,
                renderedBlocks: richRendered
            ),
            parserAudit: IOSParserContractAudit(document: richDocument, source: richSource),
            layoutSafetyAudit: IOSLayoutSafetyAudit(
                lazyRenderingPolicy: IOSReaderScreenEngine().lazyRenderingPolicy,
                iconOnlyControlLabels: IOSReaderAccessibilityPolicy().iconOnlyControlLabels,
                renderedBlocks: richRendered
            ),
            conditionalRendererAudit: conditionalRendererAudit,
            snapshotSignatures: richFixtureSnapshotSignatures(source: richSource)
        )
        let readmeAudit = IOSReadmeCommandAudit(
            readmeText: try String(
                contentsOf: Self.packageRoot.appendingPathComponent("README.md"),
                encoding: .utf8
            )
        )
        let reportPathsByChecklistItem: [IOSStageOneReconciliationChecklistItem: String] = [
            .localRendererPackagingOfflineTests: "ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md",
            .wkWebViewRequestBlockingTests: "ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md",
            .rendererAssetManifestHashTests: "ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md",
            .iPhone12SimulatorBuild: "ios/docs/reports/stage1-ios-l12-iphone12-simulator-live-validation-20260506.md",
            .iPhone12SimulatorTests: "ios/docs/reports/stage1-ios-l12-iphone12-simulator-live-validation-20260506.md",
            .iPhone12RealDeviceValidation: "ios/docs/reports/stage1-ios-l12-real-device-devicectl-probe-20260506.md",
            .iOSPerformanceReport: "ios/docs/reports/stage1-ios-l12-performance-report-20260505.md",
            .iOSSecurityAuditReport: "ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md",
            .richFixtureRenderReport: "ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md",
            .iOSReadmeCommands: "ios/docs/reports/stage1-ios-l13-readme-validation-refresh-20260506.md",
            .iOSValidationReports: "ios/docs/reports/stage1-ios-l13-reconciliation-evidence-20260506.md"
        ]
        let evidence = IOSStageOneReconciliationChecklistEvidence(
            generatedAt: generatedAt,
            conditionalRendererEvidence: conditionalRendererAudit.checklistEvidence,
            simulatorReport: simulatorReport,
            realDeviceReport: realDeviceReport,
            performanceReport: performanceReport,
            securityReport: securityReport,
            richFixtureReport: richFixtureReport,
            readmeAudit: readmeAudit,
            reportPaths: [
                "ios/docs/reports/stage1-ios-l13-reconciliation-evidence-20260506.md"
            ],
            reportPathsByChecklistItem: reportPathsByChecklistItem
        )

        XCTAssertTrue(evidence.capturesSupervisorReconciliationEvidence)
        XCTAssertTrue(evidence.pathsStayIOSLocalReports)
        XCTAssertTrue(evidence.hasItemSpecificEvidenceForEveryCompletableIOSChecklistItem)
        XCTAssertTrue(evidence.hasEvidenceForEveryCompletableIOSChecklistItem)
        let openItems = evidence.itemsToKeepOpen.map { $0.checklistItem }
        let completeItems = evidence.itemsToMarkComplete.map { $0.checklistItem }
        let evidencePathsByItem = Dictionary(
            uniqueKeysWithValues: evidence.items.map { ($0.checklistItem, $0.evidencePath) }
        )
        XCTAssertEqual(
            openItems,
            [IOSStageOneReconciliationChecklistItem.iPhone12RealDeviceValidation]
        )
        XCTAssertTrue(completeItems.contains(.iOSValidationReports))
        XCTAssertTrue(completeItems.contains(.richFixtureRenderReport))
        XCTAssertEqual(
            evidencePathsByItem[.iPhone12SimulatorBuild],
            "ios/docs/reports/stage1-ios-l12-iphone12-simulator-live-validation-20260506.md"
        )
        XCTAssertEqual(
            evidencePathsByItem[.iOSPerformanceReport],
            "ios/docs/reports/stage1-ios-l12-performance-report-20260505.md"
        )
        XCTAssertEqual(
            evidencePathsByItem[.iOSReadmeCommands],
            "ios/docs/reports/stage1-ios-l13-readme-validation-refresh-20260506.md"
        )
        XCTAssertTrue(evidence.markdown.contains("Supervisor evidence captured: true"))
        XCTAssertTrue(evidence.markdown.contains("Item-specific evidence paths captured: true"))
        XCTAssertTrue(evidence.markdown.contains("Real-device physical probe command coverage: true"))
        XCTAssertTrue(evidence.markdown.contains("Run iOS iPhone 12 simulator build. | COMPLETE"))
        XCTAssertTrue(evidence.markdown.contains("Run iOS iPhone 12 simulator build. | COMPLETE | ios/docs/reports/stage1-ios-l12-iphone12-simulator-live-validation-20260506.md"))
        XCTAssertTrue(evidence.markdown.contains("Run iOS iPhone 12-class real-device validation before parity-complete release claim. | OPEN"))
        XCTAssertTrue(evidence.markdown.contains("No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max"))
    }

    func testIOSL13ReconciliationEvidenceRejectsNonIOSReportPathsAndCompletionClaimWithoutDeviceEvidence() {
        let date = Date(timeIntervalSince1970: 1_777_807_100)
        let emptyBlocks: [NativeMarkdownBlockPresentation] = []
        let conditionalEvidence = IOSLocalRendererConditionalGateAudit(
            renderedBlocks: emptyBlocks
        ).checklistEvidence
        let simulatorReport = IOSStageOneSimulatorValidationReport(
            generatedAt: date,
            swiftPMTestPassed: true,
            simulatorAvailable: true,
            xcodebuildBuildPassed: true,
            xcodebuildTestPassed: true,
            testCaseCount: 1
        )
        let realDeviceReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: date,
            deviceProbeObservedAt: nil,
            candidates: [],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true
        )
        let performanceReport = IOSStageOnePerformanceReport(
            generatedAt: date,
            audit: IOSPerformanceAutomationAudit(measurements: [], testedFontTiers: []),
            diagnostics: IOSDiagnosticsBuilder().snapshot(
                parseMilliseconds: nil,
                renderMilliseconds: nil,
                searchMilliseconds: nil,
                saveMilliseconds: nil,
                byteCount: nil,
                lastErrorCode: nil
            ),
            localValidationDeviceName: "missing"
        )
        let securityReport = IOSStageOneSecurityAuditReport(
            generatedAt: date,
            localImageDownsamplePolicy: IOSLocalImageDownsamplePolicy(),
            securityScopedAccessAudit: IOSSecurityScopedAccessAudit(
                startedAccessCount: 1,
                stoppedAccessCount: 0
            ),
            releasePosture: IOSReleaseSecurityPosture(),
            hostileHTMLAudit: IOSHostileMarkdownFixtureAudit(renderedBlocks: []),
            hostileLinkAudit: IOSHostileMarkdownFixtureAudit(renderedBlocks: []),
            remoteImageAudit: IOSRemoteImagePrivacyAudit(renderedBlocks: []),
            conditionalRendererAudit: IOSLocalRendererConditionalGateAudit(renderedBlocks: []),
            diagnostics: IOSDiagnosticsBuilder().snapshot(
                parseMilliseconds: nil,
                renderMilliseconds: nil,
                searchMilliseconds: nil,
                saveMilliseconds: nil,
                byteCount: nil,
                lastErrorCode: nil
            ),
            importsWebKitRichRendererCode: false,
            rendererAssetInventoryCommand: IOSRendererAssetInventory.defaultInventoryCommand
        )
        let richFixtureReport = IOSRichFixtureRenderReport(
            generatedAt: date,
            audit: IOSRichFixtureRenderAudit(sourceByteCount: 0, renderedBlocks: []),
            parserAudit: IOSParserContractAudit(
                document: MarkdownRenderDocument(blocks: [], sourceByteCount: 0),
                source: ""
            ),
            layoutSafetyAudit: IOSLayoutSafetyAudit(
                lazyRenderingPolicy: IOSReaderScreenEngine().lazyRenderingPolicy,
                iconOnlyControlLabels: IOSReaderAccessibilityPolicy().iconOnlyControlLabels,
                renderedBlocks: []
            ),
            conditionalRendererAudit: IOSLocalRendererConditionalGateAudit(renderedBlocks: []),
            snapshotSignatures: []
        )
        let evidence = IOSStageOneReconciliationChecklistEvidence(
            generatedAt: date,
            conditionalRendererEvidence: conditionalEvidence,
            simulatorReport: simulatorReport,
            realDeviceReport: realDeviceReport,
            performanceReport: performanceReport,
            securityReport: securityReport,
            richFixtureReport: richFixtureReport,
            readmeAudit: IOSReadmeCommandAudit(readmeText: ""),
            reportPaths: ["Docs/not-ios-report.md"]
        )

        XCTAssertFalse(evidence.pathsStayIOSLocalReports)
        XCTAssertFalse(evidence.hasEvidenceForEveryCompletableIOSChecklistItem)
        XCTAssertFalse(evidence.capturesSupervisorReconciliationEvidence)
        XCTAssertFalse(evidence.itemsToKeepOpen.isEmpty)
        XCTAssertTrue(evidence.markdown.contains("Report paths are iOS-local: false"))
    }

    func testIOSL13ReconciliationEvidenceRequiresItemSpecificReportPaths() throws {
        let date = Date(timeIntervalSince1970: 1_777_807_200)
        let source = try richPreviewFixtureSource()
        let document = MarkdownParserAdapter().parse(source)
        let rendered = MarkdownNativeRenderer().render(document: document, source: source)
        let conditionalAudit = IOSLocalRendererConditionalGateAudit(
            renderedBlocks: rendered
        )
        let simulatorReport = IOSStageOneSimulatorValidationReport(
            generatedAt: date,
            simulatorIdentifier: "1B6FEADC-308B-4069-B734-3C9C207E633F",
            swiftPMTestPassed: true,
            simulatorAvailable: true,
            xcodebuildBuildPassed: true,
            xcodebuildTestPassed: true,
            testCaseCount: 169
        )
        let realDeviceReport = IOSStageOneRealDeviceValidationReport(
            generatedAt: date,
            deviceProbeObservedAt: date,
            candidates: [],
            completedFlowSteps: [],
            swiftPMTestPassed: true,
            iPhone12SimulatorBuildPassed: true,
            iPhone12SimulatorTestPassed: true
        )
        let performanceReport = IOSStageOnePerformanceReport(
            generatedAt: date,
            audit: IOSPerformanceAutomationAudit(
                measurements: IOSPerformanceAutomationOperation.allCases.map {
                    IOSPerformanceAutomationMeasurement(
                        operation: $0,
                        elapsedMilliseconds: 1,
                        thresholdMilliseconds: 1_000,
                        execution: $0 == .fontTierSwitch
                            ? nil
                            : IOSOffMainActorExecutionMetadata(
                                scheduledWithDetachedTask: true,
                                startedOnMainThread: false,
                                completedOnMainThread: false
                            )
                    )
                },
                testedFontTiers: Set(MobileFontTier.allCases)
            ),
            diagnostics: IOSDiagnosticsBuilder().snapshot(
                parseMilliseconds: 1,
                renderMilliseconds: 1,
                searchMilliseconds: 1,
                saveMilliseconds: 1,
                byteCount: source.utf8.count,
                lastErrorCode: nil
            ),
            localValidationDeviceName: "SwiftPM XCTest host"
        )
        let securityReport = IOSStageOneSecurityAuditReport(
            generatedAt: date,
            localImageDownsamplePolicy: IOSLocalImageDownsamplePolicy(),
            securityScopedAccessAudit: IOSSecurityScopedAccessAudit(
                startedAccessCount: 1,
                stoppedAccessCount: 1
            ),
            releasePosture: IOSReleaseSecurityPosture(),
            hostileHTMLAudit: IOSHostileMarkdownFixtureAudit(
                renderedBlocks: MarkdownNativeRenderer().render(
                    document: MarkdownParserAdapter().parse(try fixtureSource(named: "malicious-html.md")),
                    source: try fixtureSource(named: "malicious-html.md")
                )
            ),
            hostileLinkAudit: IOSHostileMarkdownFixtureAudit(
                renderedBlocks: MarkdownNativeRenderer().render(
                    document: MarkdownParserAdapter().parse(try fixtureSource(named: "malicious-links.md")),
                    source: try fixtureSource(named: "malicious-links.md")
                )
            ),
            remoteImageAudit: IOSRemoteImagePrivacyAudit(
                renderedBlocks: MarkdownNativeRenderer().render(
                    document: MarkdownParserAdapter().parse(try fixtureSource(named: "remote-image.md")),
                    source: try fixtureSource(named: "remote-image.md")
                )
            ),
            conditionalRendererAudit: conditionalAudit,
            diagnostics: IOSDiagnosticsBuilder().snapshot(
                parseMilliseconds: 1,
                renderMilliseconds: 1,
                searchMilliseconds: 1,
                saveMilliseconds: 1,
                byteCount: source.utf8.count,
                lastErrorCode: nil
            ),
            importsWebKitRichRendererCode: false,
            rendererAssetInventoryCommand: IOSRendererAssetInventory.defaultInventoryCommand
        )
        let richFixtureReport = IOSRichFixtureRenderReport(
            generatedAt: date,
            audit: IOSRichFixtureRenderAudit(
                sourceByteCount: source.utf8.count,
                renderedBlocks: rendered
            ),
            parserAudit: IOSParserContractAudit(document: document, source: source),
            layoutSafetyAudit: IOSLayoutSafetyAudit(
                lazyRenderingPolicy: IOSReaderScreenEngine().lazyRenderingPolicy,
                iconOnlyControlLabels: IOSReaderAccessibilityPolicy().iconOnlyControlLabels,
                renderedBlocks: rendered
            ),
            conditionalRendererAudit: conditionalAudit,
            snapshotSignatures: richFixtureSnapshotSignatures(source: source)
        )
        let readmeAudit = IOSReadmeCommandAudit(
            readmeText: try String(
                contentsOf: Self.packageRoot.appendingPathComponent("README.md"),
                encoding: .utf8
            )
        )
        var reportPathsByItem: [IOSStageOneReconciliationChecklistItem: String] = [
            .localRendererPackagingOfflineTests: "ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md",
            .wkWebViewRequestBlockingTests: "ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md",
            .rendererAssetManifestHashTests: "ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md",
            .iPhone12SimulatorBuild: "ios/docs/reports/stage1-ios-l12-iphone12-simulator-live-validation-20260506.md",
            .iPhone12SimulatorTests: "ios/docs/reports/stage1-ios-l12-iphone12-simulator-live-validation-20260506.md",
            .iPhone12RealDeviceValidation: "ios/docs/reports/stage1-ios-l12-real-device-devicectl-probe-20260506.md",
            .iOSPerformanceReport: "ios/docs/reports/stage1-ios-l12-performance-report-20260505.md",
            .iOSSecurityAuditReport: "ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md",
            .richFixtureRenderReport: "ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md",
            .iOSReadmeCommands: "ios/docs/reports/stage1-ios-l13-readme-validation-refresh-20260506.md",
            .iOSValidationReports: "ios/docs/reports/stage1-ios-l13-reconciliation-evidence-20260506.md"
        ]
        reportPathsByItem[.iOSPerformanceReport] = nil
        let evidence = IOSStageOneReconciliationChecklistEvidence(
            generatedAt: date,
            conditionalRendererEvidence: conditionalAudit.checklistEvidence,
            simulatorReport: simulatorReport,
            realDeviceReport: realDeviceReport,
            performanceReport: performanceReport,
            securityReport: securityReport,
            richFixtureReport: richFixtureReport,
            readmeAudit: readmeAudit,
            reportPaths: [
                "ios/docs/reports/stage1-ios-l13-reconciliation-evidence-20260506.md"
            ],
            reportPathsByChecklistItem: reportPathsByItem
        )

        XCTAssertTrue(evidence.pathsStayIOSLocalReports)
        XCTAssertFalse(evidence.hasItemSpecificEvidenceForEveryCompletableIOSChecklistItem)
        XCTAssertFalse(evidence.capturesSupervisorReconciliationEvidence)
        XCTAssertEqual(
            evidence.items.first { $0.checklistItem == .iOSPerformanceReport }?.evidencePath,
            "ios/docs/reports/stage1-ios-l13-reconciliation-evidence-20260506.md"
        )
        XCTAssertTrue(evidence.markdown.contains("Item-specific evidence paths captured: false"))
    }

    private func makeReaderLoadResult(
        displayName: String = "note.md",
        source: String
    ) -> MarkdownLoadResult {
        let handle = MobileDocumentHandle(
            identifier: "ios:url:/tmp/\(displayName)",
            displayName: displayName,
            origin: .documentPicker,
            access: .readWrite
        )
        return MarkdownLoadResult(
            handle: handle,
            metadata: MobileFileMetadata(
                displayName: displayName,
                byteCount: source.utf8.count,
                contentTypeIdentifier: "net.daringfireball.markdown"
            ),
            source: source,
            encoding: .utf8,
            lineEnding: MarkdownLineEnding.detect(in: source),
            loadedAt: Date(timeIntervalSince1970: 1_777_801_700)
        )
    }

    private func makeLoadedDocument(
        displayName: String,
        source: String,
        access: MobileDocumentAccess = .readWrite,
        encoding: MarkdownTextEncoding = .utf8,
        lineEnding: MarkdownLineEnding? = nil
    ) -> MarkdownLoadResult {
        let handle = MobileDocumentHandle(
            identifier: "ios:url:/tmp/\(displayName)",
            displayName: displayName,
            origin: .documentPicker,
            access: access
        )
        return MarkdownLoadResult(
            handle: handle,
            metadata: MobileFileMetadata(
                displayName: displayName,
                byteCount: encoding == .utf8WithBOM ? source.utf8.count + 3 : source.utf8.count,
                contentTypeIdentifier: "net.daringfireball.markdown"
            ),
            source: source,
            encoding: encoding,
            lineEnding: lineEnding ?? MarkdownLineEnding.detect(in: source),
            loadedAt: Date(timeIntervalSince1970: 1_777_802_200)
        )
    }

    private func richPreviewFixtureSource() throws -> String {
        try fixtureSource(named: "rich-preview.md")
    }

    private func richFixtureSnapshotSignatures(source: String) -> [IOSRendererSnapshotSignature] {
        let builder = IOSRendererSnapshotSignatureBuilder()
        return IOSReaderThemeScheme.allCases.flatMap { themeScheme in
            MobileFontTier.allCases.map { fontTier in
                builder.signature(
                    source: source,
                    themeScheme: themeScheme,
                    fontTier: fontTier
                )
            }
        }
    }

    private func fixtureSource(named fixtureName: String) throws -> String {
        let fixtureURL = Self.packageRoot
            .appendingPathComponent("Tests")
            .appendingPathComponent("Fixtures")
            .appendingPathComponent("Markdown")
            .appendingPathComponent(fixtureName)
        return try String(contentsOf: fixtureURL, encoding: .utf8)
    }

    private struct MeasuredValue<Value> {
        let value: Value
        let elapsedMilliseconds: Double
        let thresholdMilliseconds: Double
    }

    private func measuredAsync<Value>(
        operation: IOSPerformanceAutomationOperation,
        thresholdMilliseconds: Double,
        _ body: () async throws -> Value
    ) async throws -> MeasuredValue<Value> {
        let start = DispatchTime.now().uptimeNanoseconds
        let value = try await body()
        let end = DispatchTime.now().uptimeNanoseconds
        return MeasuredValue(
            value: value,
            elapsedMilliseconds: Double(end - start) / 1_000_000,
            thresholdMilliseconds: thresholdMilliseconds
        )
    }

    private func measuredSync(
        operation: IOSPerformanceAutomationOperation,
        thresholdMilliseconds: Double,
        _ body: () throws -> Void
    ) rethrows -> IOSPerformanceAutomationMeasurement {
        let start = DispatchTime.now().uptimeNanoseconds
        try body()
        let end = DispatchTime.now().uptimeNanoseconds
        return IOSPerformanceAutomationMeasurement(
            operation: operation,
            elapsedMilliseconds: Double(end - start) / 1_000_000,
            thresholdMilliseconds: thresholdMilliseconds
        )
    }

    private func generatedLargeMarkdown(repeatedParagraphCount: Int) -> String {
        var lines = ["# Large Document", ""]
        for index in 0..<repeatedParagraphCount {
            lines.append("## Section \(index)")
            lines.append("")
            lines.append(
                "Paragraph \(index) with **bold**, _italic_, `code`, [safe link](https://example.com/safe), and needle text."
            )
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private func generatedHugeTableMarkdown(rowCount: Int, columnCount: Int) -> String {
        let header = (0..<columnCount).map { "Column \($0)" }.joined(separator: " | ")
        let delimiter = Array(repeating: "---", count: columnCount).joined(separator: " | ")
        var lines = [
            "# Huge Table",
            "",
            "| \(header) |",
            "| \(delimiter) |"
        ]
        for row in 0..<rowCount {
            let cells = (0..<columnCount)
                .map { column in "R\(row)C\(column)-wide-content-\(row * max(1, column + 1))" }
                .joined(separator: " | ")
            lines.append("| \(cells) |")
        }
        return lines.joined(separator: "\n")
    }

    private func generatedHugeCodeBlockMarkdown(lineCount: Int) -> String {
        var lines = ["# Huge Code", "", "```swift"]
        for index in 0..<lineCount {
            lines.append("let generatedValue\(index) = \"needle-\(index)-wide-code-line\"")
        }
        lines.append("```")
        return lines.joined(separator: "\n")
    }

    private func generatedHugeImageMetadataMarkdown() -> String {
        let longAlt = Array(repeating: "local-image-alt", count: 80).joined(separator: "-")
        let longName = Array(repeating: "nested-folder", count: 30).joined(separator: "/")
        return """
        # Huge Image Metadata

        ![\(longAlt)](./\(longName)/image-with-long-local-metadata-name.png)
        """
    }

    private func capturedSavePlannerError(
        _ operation: () throws -> Void
    ) -> IOSDocumentSaveError? {
        do {
            try operation()
            return nil
        } catch let error as IOSDocumentSaveError {
            return error
        } catch {
            return nil
        }
    }

    private func capturedSaveError(
        _ operation: () throws -> Void
    ) -> IOSDocumentSaveError? {
        capturedSavePlannerError(operation)
    }

    private func goldenSnapshotURL(
        theme: IOSReaderThemeScheme,
        tier: MobileFontTier
    ) -> URL {
        Self.packageRoot
            .appendingPathComponent("docs")
            .appendingPathComponent("screenshots")
            .appendingPathComponent("golden")
            .appendingPathComponent("rich-preview-\(theme.rawValue)-\(tier.rawValue).snapshot.txt")
    }

    private func wkWebViewRequestBlockingPolicy() -> IOSRichRendererRequestBlockingPolicy {
        IOSRichRendererRequestBlockingPolicy(
            bundledRendererRoot: URL(fileURLWithPath: "/App/FastMD.app/FastMDRenderers")
        )
    }

    private func makeRichFallbackBlock(
        surface: NativeMarkdownRichFallbackSurface,
        rendersAsNativeSafeCard: Bool,
        requiresVendoredRendererAssets: Bool,
        allowsNetworkRequests: Bool,
        allowsExternalNavigation: Bool,
        allowsRemoteSubresources: Bool
    ) -> NativeMarkdownBlockPresentation {
        let range = MarkdownSourceRange(
            startUTF8Offset: 0,
            endUTF8Offset: 24,
            startLine: 1,
            endLine: 3
        )
        return NativeMarkdownBlockPresentation(
            id: MarkdownBlockID(rawValue: "rich-fallback:test"),
            role: .richFallback,
            sourceRange: range,
            inlineRuns: [],
            richFallback: NativeMarkdownRichFallback(
                kind: .mermaidDiagramSource,
                title: "Mermaid diagram source",
                source: "flowchart TD",
                surface: surface,
                rendersAsNativeSafeCard: rendersAsNativeSafeCard,
                requiresVendoredRendererAssets: requiresVendoredRendererAssets,
                allowsNetworkRequests: allowsNetworkRequests,
                allowsExternalNavigation: allowsExternalNavigation,
                allowsRemoteSubresources: allowsRemoteSubresources
            )
        )
    }

    private func rendererAssetInventory() -> IOSRendererAssetInventory {
        IOSRendererAssetInventory.discover(iosRoot: Self.packageRoot)
    }

    private func documentedRendererAssetInventoryCommandPaths() throws -> [String] {
        #if os(macOS)
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-lc", IOSRendererAssetInventory.defaultInventoryCommand]
        process.currentDirectoryURL = Self.packageRoot.deletingLastPathComponent()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let errorOutput = String(
            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "FastMDMobileCoreTests.RendererAssetInventoryCommand",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: errorOutput]
            )
        }

        return output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.isEmpty }
        #else
        throw XCTSkip("Process is unavailable in iOS Simulator test bundles.")
        #endif
    }

    private func discoveredRendererAssetPaths() -> [String] {
        rendererAssetInventory().discoveredRendererAssetPaths
    }

    private func importsWebKitRichRendererCode() -> Bool {
        rendererAssetInventory().importsWebKitRichRendererCode
    }

    private func completeRealDeviceManualFlowEvidence(
        hardwareSignal: String = "iPhone13,2",
        observedAtBase: TimeInterval = 1_777_806_000,
        probeBatchObservedAt: TimeInterval? = nil
    ) -> [IOSStageOneRealDeviceFlowEvidence] {
        IOSStageOneRealDeviceFlowStep.allCases.enumerated().map { index, step in
            IOSStageOneRealDeviceFlowEvidence(
                step: step,
                observedAt: Date(timeIntervalSince1970: observedAtBase + Double(index)),
                evidenceSummary: realDeviceEvidenceSummary(for: step, hardwareSignal: hardwareSignal),
                probeBatchObservedAt: Date(timeIntervalSince1970: probeBatchObservedAt ?? observedAtBase - 1)
            )
        }
    }

    private func realDeviceEvidenceSummary(
        for step: IOSStageOneRealDeviceFlowStep,
        hardwareSignal: String = "iPhone13,2"
    ) -> String {
        switch step {
        case .openMarkdown:
            return "opened Markdown fixture through Files handoff on physical iPhone 12-family hardware \(hardwareSignal)"
        case .renderRichFixture:
            return "rendered canonical rich fixture without page overflow on physical iPhone 12-family hardware \(hardwareSignal)"
        case .searchDocument:
            return "searched document and navigated between matches on physical iPhone 12-family hardware \(hardwareSignal)"
        case .fullSourceEdit:
            return "edited full Markdown source and preserved dirty state on physical iPhone 12-family hardware \(hardwareSignal)"
        case .blockSourceEdit:
            return "edited smallest mapped rendered block source on physical iPhone 12-family hardware \(hardwareSignal)"
        case .saveWritableDocument:
            return "saved writable fixture and verified dirty state cleared on physical iPhone 12-family hardware \(hardwareSignal)"
        case .rotateReader:
            return "rotated reader and preserved document state on physical iPhone 12-family hardware \(hardwareSignal)"
        }
    }

    private func realDeviceEvidenceSummary(
        for step: IOSStageOneRealDeviceFlowStep,
        prefix: String,
        hardwareSignal: String
    ) -> String {
        switch step {
        case .openMarkdown:
            return "\(prefix) opened Markdown fixture through Files handoff on \(hardwareSignal)"
        case .renderRichFixture:
            return "\(prefix) rendered canonical rich fixture without page overflow on \(hardwareSignal)"
        case .searchDocument:
            return "\(prefix) searched document and navigated between matches on \(hardwareSignal)"
        case .fullSourceEdit:
            return "\(prefix) edited full Markdown source and preserved dirty state on \(hardwareSignal)"
        case .blockSourceEdit:
            return "\(prefix) edited smallest mapped rendered block source on \(hardwareSignal)"
        case .saveWritableDocument:
            return "\(prefix) saved writable fixture and verified dirty state cleared on \(hardwareSignal)"
        case .rotateReader:
            return "\(prefix) rotated reader and preserved document state on \(hardwareSignal)"
        }
    }

    private func negatedRealDeviceEvidenceSummary(
        for step: IOSStageOneRealDeviceFlowStep,
        hardwareSignal: String
    ) -> String {
        switch step {
        case .openMarkdown:
            return "did not open Markdown fixture through Files handoff on physical iPhone 12-family hardware \(hardwareSignal)"
        case .renderRichFixture:
            return "couldn't render canonical rich fixture on physical iPhone 12-family hardware \(hardwareSignal)"
        case .searchDocument:
            return "failed search document matches on physical iPhone 12-family hardware \(hardwareSignal)"
        case .fullSourceEdit:
            return "unable edit full Markdown source on physical iPhone 12-family hardware \(hardwareSignal)"
        case .blockSourceEdit:
            return "without edited smallest mapped rendered block source on physical iPhone 12-family hardware \(hardwareSignal)"
        case .saveWritableDocument:
            return "didn't save writable fixture on physical iPhone 12-family hardware \(hardwareSignal)"
        case .rotateReader:
            return "never rotated reader layout on physical iPhone 12-family hardware \(hardwareSignal)"
        }
    }

    private func postActionFailureRealDeviceEvidenceSummary(
        for step: IOSStageOneRealDeviceFlowStep,
        hardwareSignal: String
    ) -> String {
        switch step {
        case .openMarkdown:
            return "opened Markdown fixture failed on physical iPhone 12-family hardware \(hardwareSignal)"
        case .renderRichFixture:
            return "rendered canonical rich fixture errored on physical iPhone 12-family hardware \(hardwareSignal)"
        case .searchDocument:
            return "searched document timed out on physical iPhone 12-family hardware \(hardwareSignal)"
        case .fullSourceEdit:
            return "edited full Markdown source unsuccessful on physical iPhone 12-family hardware \(hardwareSignal)"
        case .blockSourceEdit:
            return "edited smallest mapped rendered block source incomplete on physical iPhone 12-family hardware \(hardwareSignal)"
        case .saveWritableDocument:
            return "saved writable fixture failed on physical iPhone 12-family hardware \(hardwareSignal)"
        case .rotateReader:
            return "rotated reader layout crashed on physical iPhone 12-family hardware \(hardwareSignal)"
        }
    }
}
