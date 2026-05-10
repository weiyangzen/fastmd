package com.fastmd.mobile.core.contracts

import com.fastmd.mobile.core.document.DocumentHandleId
import com.fastmd.mobile.core.document.DocumentOrigin
import com.fastmd.mobile.core.document.DocumentPermissionGrant
import com.fastmd.mobile.core.document.DocumentWriteCapability
import com.fastmd.mobile.core.diagnostics.DiagnosticsFileSizeBucket
import com.fastmd.mobile.core.diagnostics.DiagnosticsOperation
import com.fastmd.mobile.core.diagnostics.DiagnosticsOperationStatus
import com.fastmd.mobile.core.diagnostics.DiagnosticsRedactionPolicy
import com.fastmd.mobile.core.diagnostics.LocalDiagnosticsReport
import com.fastmd.mobile.core.document.MarkdownDocument
import com.fastmd.mobile.core.document.MarkdownEncoding
import com.fastmd.mobile.core.document.MarkdownFileMetadata
import com.fastmd.mobile.core.document.MarkdownLineEnding
import com.fastmd.mobile.core.document.MarkdownLoadResult
import com.fastmd.mobile.core.document.MobileDocumentHandle
import com.fastmd.mobile.core.document.MobilePlatform
import com.fastmd.mobile.core.document.PlatformDocumentReference
import com.fastmd.mobile.core.document.RecentDocumentMetadata
import com.fastmd.mobile.core.error.FastMdErrorCategory
import com.fastmd.mobile.core.error.FastMdErrorCode
import com.fastmd.mobile.core.link.LinkPolicy
import com.fastmd.mobile.core.link.LinkPolicyDecision
import com.fastmd.mobile.core.link.LinkTarget
import com.fastmd.mobile.core.performance.AndroidDeviceProfileInputs
import com.fastmd.mobile.core.performance.AndroidPerformanceProfile
import com.fastmd.mobile.core.performance.AndroidPerformanceProfileSelector
import com.fastmd.mobile.core.reader.FontTier
import com.fastmd.mobile.core.reader.ReaderUiState
import com.fastmd.mobile.core.reader.ReaderThemeMode
import com.fastmd.mobile.core.render.LocalRendererAsset
import com.fastmd.mobile.core.render.LocalRendererAssetPath
import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.render.MarkdownBlockKind
import com.fastmd.mobile.core.render.MarkdownRenderBlock
import com.fastmd.mobile.core.render.MarkdownRenderModel
import com.fastmd.mobile.core.render.RichRendererAssetKind
import com.fastmd.mobile.core.render.RichRendererAssetPolicy
import com.fastmd.mobile.core.render.RichRendererSurface
import com.fastmd.mobile.core.render.SourceRange
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CoreContractsTest {
    @Test
    fun documentHandleCapturesAndroidReferenceAndWriteGrant() {
        val handle = MobileDocumentHandle(
            id = DocumentHandleId("content:downloads:note-md"),
            platform = MobilePlatform.Android,
            reference = PlatformDocumentReference.androidContentUri(
                uriString = "content://downloads/document/note.md",
                authority = "downloads",
            ),
            displayName = "note.md",
            permissionGrant = DocumentPermissionGrant.PersistedReadWrite,
            lastKnownSizeBytes = 42L,
            lastKnownModifiedEpochMillis = 1_714_000_000_000L,
        )

        assertTrue(handle.isWritable)
        assertFalse(handle.isPermissionLost)
        assertEquals("content", handle.reference.scheme)
    }

    @Test
    fun recentDocumentMetadataStoresHandleMetadataWithoutDocumentContent() {
        val recent = RecentDocumentMetadata(
            handleId = DocumentHandleId("content:downloads:note-md"),
            reference = PlatformDocumentReference.androidContentUri(
                uriString = "content://downloads/document/note.md",
                authority = "downloads",
            ),
            displayName = "note.md",
            permissionGrant = DocumentPermissionGrant.PersistedRead,
            lastKnownSizeBytes = 128L,
            lastKnownModifiedEpochMillis = null,
            lastOpenedEpochMillis = 1_714_000_000_000L,
            writeCapability = DocumentWriteCapability.ReadOnly,
        )

        assertTrue(recent.canAttemptReopen)
        assertEquals("note.md", recent.displayName)
        assertFalse(recent.reference.rawReference.contains("# Title"))
    }

    @Test
    fun markdownLoadResultCarriesMetadataAndWriteCapability() {
        val document = MarkdownDocument(
            title = "note.md",
            source = "# Title\nBody",
            origin = DocumentOrigin.StorageAccessFramework,
            isWritable = true,
        )
        val handle = MobileDocumentHandle(
            id = DocumentHandleId("content:note"),
            platform = MobilePlatform.Android,
            reference = PlatformDocumentReference.androidContentUri("content://provider/note"),
            displayName = "note.md",
            permissionGrant = DocumentPermissionGrant.TransientReadWrite,
        )
        val metadata = MarkdownFileMetadata(
            displayName = "note.md",
            mimeType = "text/markdown",
            sizeBytes = 12L,
            lastModifiedEpochMillis = null,
            encoding = MarkdownEncoding.Utf8,
            lineEnding = MarkdownLineEnding.Lf,
        )

        val result = MarkdownLoadResult.Loaded(
            document = document,
            handle = handle,
            metadata = metadata,
            writeCapability = DocumentWriteCapability.Writable,
            origin = DocumentOrigin.StorageAccessFramework,
        )

        assertEquals(metadata, result.metadata)
        assertEquals(DocumentWriteCapability.Writable, result.writeCapability)
    }

    @Test
    fun renderModelRequiresStableUniqueBlockIdsAndContiguousOrdinals() {
        val renderModel = MarkdownRenderModel(
            sourceRevision = 1L,
            blocks = listOf(
                MarkdownRenderBlock(
                    id = MarkdownBlockId("block-0"),
                    kind = MarkdownBlockKind.Heading,
                    sourceRange = SourceRange(
                        startOffset = 0,
                        endOffsetExclusive = 7,
                        startLine = 1,
                        endLineInclusive = 1,
                    ),
                    ordinal = 0,
                    plainText = "Title",
                    attributes = mapOf("level" to "1"),
                ),
                MarkdownRenderBlock(
                    id = MarkdownBlockId("block-1"),
                    kind = MarkdownBlockKind.Paragraph,
                    sourceRange = SourceRange(
                        startOffset = 8,
                        endOffsetExclusive = 12,
                        startLine = 2,
                        endLineInclusive = 2,
                    ),
                    ordinal = 1,
                    plainText = "Body",
                ),
            ),
        )

        assertEquals(listOf("block-0", "block-1"), renderModel.blocks.map { it.id.value })
    }

    @Test
    fun fontTierContractMatchesStageOneFourTierModel() {
        assertEquals(listOf(14, 16, 18, 21), FontTier.entries.map { it.bodySp })
        assertEquals(FontTier.Default, FontTier.initial)
        assertTrue(FontTier.Reader.lineHeightMultiplier > FontTier.Compact.lineHeightMultiplier)
    }

    @Test
    fun fontTierContractKeepsSystemFontScaleComposable() {
        val sampledAndroidFontScales = listOf(0.85f, 1.0f, 1.3f, 2.0f)

        FontTier.entries.forEach { tier ->
            sampledAndroidFontScales.forEach { fontScale ->
                val scaledBodySp = tier.bodySp * fontScale
                val scaledCodeSp = tier.codeSp * fontScale

                assertTrue(scaledBodySp > 0f)
                assertTrue(scaledCodeSp > 0f)
                assertTrue(scaledCodeSp <= scaledBodySp)
                assertTrue(scaledBodySp * tier.lineHeightMultiplier > scaledBodySp)
                assertTrue(scaledCodeSp * tier.lineHeightMultiplier > scaledCodeSp)
            }
        }
    }

    @Test
    fun readerThemeModeContractMatchesStageOneLightDarkModel() {
        assertEquals(listOf(ReaderThemeMode.Light, ReaderThemeMode.Dark), ReaderThemeMode.entries.toList())
        assertEquals(ReaderThemeMode.Light, ReaderThemeMode.initial)
    }

    @Test
    fun readerUiStateCoversRequiredStageOneStates() {
        val document = MarkdownDocument(
            title = "note.md",
            source = "Body",
            origin = DocumentOrigin.SharedText,
            isWritable = false,
        )
        val ready = ReaderUiState.Ready(
            document = document,
            renderModel = MarkdownRenderModel(
                sourceRevision = 0L,
                blocks = listOf(
                    MarkdownRenderBlock(
                        id = MarkdownBlockId("paragraph-0"),
                        kind = MarkdownBlockKind.Paragraph,
                        sourceRange = SourceRange(0, 4, 1, 1),
                        ordinal = 0,
                        plainText = "Body",
                    ),
                ),
            ),
            fontTier = FontTier.Default,
        )

        val states = listOf(
            ReaderUiState.Empty,
            ReaderUiState.Loading("note.md"),
            ReaderUiState.Rendering(document, FontTier.Default),
            ready,
            ReaderUiState.Searching(ready, query = "Body", resultCount = 1, activeResultIndex = 0),
            ReaderUiState.EditingSource(document, draftSource = "Body edit", FontTier.Default, isDirty = true),
            ReaderUiState.EditingBlock(
                document = document,
                blockId = MarkdownBlockId("paragraph-0"),
                originalSourceRange = SourceRange(0, 4, 1, 1),
                originalBlockSource = "Body",
                draftSource = "Body edit",
                fontTier = FontTier.Default,
                isDirty = true,
            ),
            ReaderUiState.Saving(document, draftSource = "Body edit"),
            ReaderUiState.ReadOnly(ready, reason = "Shared text has no writable URI."),
            ReaderUiState.PermissionLost(displayName = "note.md"),
            ReaderUiState.Error(FastMdErrorCode.ReadIoFailure, message = "Read failed.", recoverable = true),
        )

        assertEquals(11, states.size)
    }

    @Test
    fun errorCodesCoverAllRequiredFailureCategories() {
        val categories = FastMdErrorCode.entries.map { it.category }.toSet()

        assertEquals(FastMdErrorCategory.entries.toSet(), categories)
    }

    @Test
    fun linkPolicySeparatesAllowedConfirmAndBlockedDecisions() {
        val policy = LinkPolicy()

        assertTrue(policy.decide(LinkTarget("#section")) is LinkPolicyDecision.Allowed)
        assertTrue(policy.decide(LinkTarget("https://example.com")) is LinkPolicyDecision.Confirm)

        val blocked = policy.decide(LinkTarget("javascript:alert(1)"))

        assertTrue(blocked is LinkPolicyDecision.Blocked)
        assertEquals(FastMdErrorCode.LinkBlockedScheme, (blocked as LinkPolicyDecision.Blocked).code)
    }

    @Test
    fun linkPolicyBlocksAndroidDangerousSchemesByDefault() {
        val policy = LinkPolicy()
        val dangerousTargets = listOf(
            "javascript:alert(1)",
            "JaVaScRiPt:alert(1)",
            "data:text/html,<script>alert(1)</script>",
            "file:///sdcard/Download/private.md",
            "content://com.example.provider/private.md",
            "intent://scan/#Intent;scheme=zxing;end",
            "android-app://com.example/https/example.com",
            "vbscript:msgbox(1)",
        )

        dangerousTargets.forEach { rawTarget ->
            val decision = policy.decide(LinkTarget(rawTarget))

            assertTrue("$rawTarget should be blocked", decision is LinkPolicyDecision.Blocked)
            assertEquals(
                FastMdErrorCode.LinkBlockedScheme,
                (decision as LinkPolicyDecision.Blocked).code,
            )
        }
    }

    @Test
    fun androidPerformanceProfileSelectorCoversStageOneDeviceClasses() {
        val watch = AndroidDeviceProfileInputs(
            apiLevel = 27,
            isLowRamDevice = true,
            smallestScreenWidthDp = 240,
            screenWidthDp = 240,
            screenHeightDp = 240,
            memoryClassMb = 128,
        )
        val legacyPhone = AndroidDeviceProfileInputs(
            apiLevel = 28,
            isLowRamDevice = false,
            smallestScreenWidthDp = 360,
            screenWidthDp = 360,
            screenHeightDp = 640,
            memoryClassMb = 256,
        )
        val modernPhone = AndroidDeviceProfileInputs(
            apiLevel = 35,
            isLowRamDevice = false,
            smallestScreenWidthDp = 393,
            screenWidthDp = 393,
            screenHeightDp = 851,
        )
        val tablet = AndroidDeviceProfileInputs(
            apiLevel = 35,
            isLowRamDevice = false,
            smallestScreenWidthDp = 840,
            screenWidthDp = 1280,
            screenHeightDp = 800,
        )

        assertEquals(AndroidPerformanceProfile.WatchCompact, AndroidPerformanceProfileSelector.select(watch))
        assertEquals(AndroidPerformanceProfile.LegacyEfficient, AndroidPerformanceProfileSelector.select(legacyPhone))
        assertEquals(AndroidPerformanceProfile.ModernStandard, AndroidPerformanceProfileSelector.select(modernPhone))
        assertEquals(AndroidPerformanceProfile.LargeScreen, AndroidPerformanceProfileSelector.select(tablet))
        assertTrue(AndroidPerformanceProfile.WatchCompact.disableExpensiveAnimations)
        assertTrue(AndroidPerformanceProfile.LegacyEfficient.disableExpensiveAnimations)
        assertFalse(AndroidPerformanceProfile.ModernStandard.disableExpensiveAnimations)
        assertFalse(AndroidPerformanceProfile.LargeScreen.disableExpensiveAnimations)
        assertFalse(AndroidPerformanceProfile.ModernStandard.remoteMediaEnabledByDefault)
    }

    @Test
    fun richRendererAssetPolicyRequiresLocalOfflineAssetsAndBlockedSurfaceCapabilities() {
        val nativeFallback = RichRendererAssetPolicy.nativeFallback(RichRendererSurface.Mermaid)
        val vendoredMath = RichRendererAssetPolicy(
            surface = RichRendererSurface.Math,
            assets = listOf(
                LocalRendererAsset(
                    kind = RichRendererAssetKind.JavaScript,
                    path = LocalRendererAssetPath("fastmd-renderers/math/mathjax-lite.js"),
                    sha256 = "0".repeat(64),
                ),
                LocalRendererAsset(
                    kind = RichRendererAssetKind.StyleSheet,
                    path = LocalRendererAssetPath("fastmd-renderers/math/math.css"),
                    sha256 = "1".repeat(64),
                ),
            ),
        )

        assertFalse(nativeFallback.usesVendoredAssets)
        assertTrue(vendoredMath.usesVendoredAssets)
        assertTrue(vendoredMath.networkRequestsBlocked)
        assertTrue(vendoredMath.externalNavigationBlocked)
        assertTrue(vendoredMath.javascriptUrlsBlocked)
        assertTrue(vendoredMath.dataUrlsBlocked)
        assertTrue(vendoredMath.iframesBlocked)
        assertTrue(vendoredMath.remoteSubresourcesBlocked)
    }

    @Test
    fun localDiagnosticsReportIncludesOperationalFieldsWithoutSensitiveContent() {
        val metadata = MarkdownFileMetadata(
            displayName = "private-note.md",
            mimeType = "text/markdown",
            sizeBytes = 128_000L,
            lastModifiedEpochMillis = null,
            encoding = MarkdownEncoding.Utf8,
            lineEnding = MarkdownLineEnding.Lf,
        )
        val report = LocalDiagnosticsReport
            .initial(
                platform = MobilePlatform.Android,
                deviceClass = AndroidPerformanceProfile.LegacyEfficient,
            )
            .withDocument(
                metadata = metadata,
                origin = DocumentOrigin.StorageAccessFramework,
                writable = true,
            )
            .copy(
                parse = DiagnosticsOperation(
                    status = DiagnosticsOperationStatus.Pass,
                    durationMillis = 12L,
                    itemCount = 4,
                ),
                render = DiagnosticsOperation(
                    status = DiagnosticsOperationStatus.Pass,
                    itemCount = 4,
                ),
                search = DiagnosticsOperation(
                    status = DiagnosticsOperationStatus.Pass,
                    durationMillis = 3L,
                    itemCount = 2,
                ),
                save = DiagnosticsOperation(
                    status = DiagnosticsOperationStatus.Failed,
                    durationMillis = 9L,
                ),
                lastErrorCategory = FastMdErrorCategory.Save,
            )

        val redacted = report.toRedactedText()

        assertEquals(DiagnosticsFileSizeBucket.Small, report.fileSizeBucket)
        assertTrue(redacted.contains("deviceClass=LegacyEfficient"))
        assertTrue(redacted.contains("rendererProfile=NativeCompose"))
        assertTrue(redacted.contains("fileSizeBucket=100 KB-1 MB"))
        assertTrue(redacted.contains("parse=Pass durationMs=12 count=4"))
        assertTrue(redacted.contains("render=Pass count=4"))
        assertTrue(redacted.contains("search=Pass durationMs=3 count=2"))
        assertTrue(redacted.contains("save=Failed durationMs=9"))
        assertTrue(redacted.contains("lastErrorCategory=Save"))
        assertFalse(redacted.contains("private-note.md"))
        assertFalse(redacted.contains("content://"))
        assertFalse(redacted.contains("/Users/"))
        assertFalse(redacted.contains("secret query"))
        assertFalse(redacted.contains("# private markdown body"))
    }

    @Test
    fun diagnosticsRedactionPolicyRejectsSensitiveFragments() {
        assertEquals(
            "platform=Android\nfileSizeBucket=100 KB-1 MB",
            DiagnosticsRedactionPolicy.requireRedacted("platform=Android\nfileSizeBucket=100 KB-1 MB"),
        )

        listOf(
            "uri=content://provider/private-note.md",
            "path=/Users/alice/private-note.md",
            "query=secret",
            "clipboard=# private markdown body",
            "source=# private markdown body",
            "rawReference=content://provider/private-note.md",
        ).forEach { sensitiveText ->
            try {
                DiagnosticsRedactionPolicy.requireRedacted(sensitiveText)
                throw AssertionError("Expected diagnostics redaction to reject: $sensitiveText")
            } catch (expected: IllegalArgumentException) {
                assertTrue(expected.message?.contains("sensitive fragment marker") == true)
            }
        }
    }
}
