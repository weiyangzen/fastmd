package com.fastmd.mobile.session

import com.fastmd.mobile.core.document.DocumentOrigin
import com.fastmd.mobile.core.document.DocumentHandleId
import com.fastmd.mobile.core.document.DocumentPermissionGrant
import com.fastmd.mobile.core.document.DocumentReferenceKind
import com.fastmd.mobile.core.document.DocumentWriteCapability
import com.fastmd.mobile.core.document.MarkdownEncoding
import com.fastmd.mobile.core.document.MarkdownDocument
import com.fastmd.mobile.core.document.MarkdownFileMetadata
import com.fastmd.mobile.core.document.MarkdownLineEnding
import com.fastmd.mobile.core.document.PlatformDocumentReference
import com.fastmd.mobile.core.document.RecentDocumentMetadata
import com.fastmd.mobile.core.diagnostics.DiagnosticsFileSizeBucket
import com.fastmd.mobile.core.error.FastMdErrorCategory
import com.fastmd.mobile.core.error.FastMdErrorCode
import com.fastmd.mobile.core.reader.FontTier
import com.fastmd.mobile.core.reader.ReaderUiState
import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.render.MarkdownBlockKind
import com.fastmd.mobile.core.render.MarkdownRenderBlock
import com.fastmd.mobile.core.render.MarkdownRenderModel
import com.fastmd.mobile.core.render.SourceRange
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class FastMdReaderSessionViewModelTest {
    @Test
    fun backFromSearchRestoresReadyReaderWithoutDroppingScrollOrFontTier() {
        val session = FastMdReaderSessionViewModel()
        val ready = readyState(fontTier = FontTier.Reader, scrollBlockId = MarkdownBlockId("paragraph-1"))

        session.readerState.value = ReaderUiState.Searching(
            ready = ready,
            query = "body",
            resultCount = 1,
            activeResultIndex = 0,
        )

        assertTrue(session.handleBackNavigation())

        val restored = session.readerState.value as ReaderUiState.Ready
        assertSame(ready.document, restored.document)
        assertEquals(ready.renderModel, restored.renderModel)
        assertEquals(FontTier.Reader, restored.fontTier)
        assertEquals(MarkdownBlockId("paragraph-1"), restored.scrollBlockId)
    }

    @Test
    fun backFromReaderReturnsToRecentDocumentsSurface() {
        val session = FastMdReaderSessionViewModel()
        session.readerState.value = readyState()

        assertTrue(session.handleBackNavigation())

        assertEquals(ReaderUiState.Empty, session.readerState.value)
    }

    @Test
    fun backFromEmptyRecentDocumentsAllowsSystemBackToProceedWithoutDroppingRecents() {
        val session = FastMdReaderSessionViewModel()
        val recent = recentDocument()
        session.recentDocumentsState.value = listOf(recent)

        assertFalse(session.handleBackNavigation())

        assertEquals(ReaderUiState.Empty, session.readerState.value)
        assertEquals(listOf(recent), session.recentDocumentsState.value)
        assertFalse(session.showDiscardEditDialogState.value)
    }

    @Test
    fun backFromReadOnlyReturnsToReadyReader() {
        val session = FastMdReaderSessionViewModel()
        val ready = readyState(fontTier = FontTier.Compact)
        session.readerState.value = ReaderUiState.ReadOnly(
            ready = ready,
            reason = "Opened read-only",
        )

        assertTrue(session.handleBackNavigation())

        val restored = session.readerState.value as ReaderUiState.Ready
        assertSame(ready.document, restored.document)
        assertEquals(FontTier.Compact, restored.fontTier)
        assertFalse(session.showDiscardEditDialogState.value)
    }

    @Test
    fun cleanSourceBackReturnsToReaderWithoutDiscardDialog() {
        val session = FastMdReaderSessionViewModel()
        val document = markdownDocument()
        session.readerState.value = ReaderUiState.EditingSource(
            document = document,
            draftSource = document.source,
            fontTier = FontTier.Reader,
            isDirty = false,
        )

        assertTrue(session.handleBackNavigation())

        val ready = session.readerState.value as ReaderUiState.Ready
        assertEquals(document.source, ready.document.source)
        assertEquals(FontTier.Reader, ready.fontTier)
        assertFalse(session.showDiscardEditDialogState.value)
    }

    @Test
    fun dirtySourceBackShowsDiscardDialogAndKeepsDraftBuffer() {
        val session = FastMdReaderSessionViewModel()
        val document = markdownDocument()
        session.readerState.value = ReaderUiState.EditingSource(
            document = document,
            draftSource = "# Title\n\nEdited body",
            fontTier = FontTier.Large,
            isDirty = true,
        )

        assertTrue(session.handleBackNavigation())

        val editing = session.readerState.value as ReaderUiState.EditingSource
        assertEquals("# Title\n\nEdited body", editing.draftSource)
        assertEquals(FontTier.Large, editing.fontTier)
        assertTrue(editing.isDirty)
        assertTrue(session.showDiscardEditDialogState.value)
    }

    @Test
    fun dirtyBlockBackShowsDiscardDialogAndKeepsDraftBuffer() {
        val session = FastMdReaderSessionViewModel()
        val blockId = MarkdownBlockId("paragraph-1")
        session.readerState.value = ReaderUiState.EditingBlock(
            document = markdownDocument(),
            blockId = blockId,
            originalSourceRange = SourceRange(9, 13, 3, 3),
            originalBlockSource = "Body",
            draftSource = "Edited body",
            fontTier = FontTier.Large,
            isDirty = true,
        )

        assertTrue(session.handleBackNavigation())

        val editing = session.readerState.value as ReaderUiState.EditingBlock
        assertEquals(blockId, editing.blockId)
        assertEquals("Edited body", editing.draftSource)
        assertEquals(FontTier.Large, editing.fontTier)
        assertTrue(editing.isDirty)
        assertTrue(session.showDiscardEditDialogState.value)
    }

    @Test
    fun cleanBlockBackReturnsToReaderWithoutDiscardDialog() {
        val session = FastMdReaderSessionViewModel()
        session.readerState.value = ReaderUiState.EditingBlock(
            document = markdownDocument(),
            blockId = MarkdownBlockId("paragraph-1"),
            originalSourceRange = SourceRange(9, 13, 3, 3),
            originalBlockSource = "Body",
            draftSource = "Body",
            fontTier = FontTier.Default,
            isDirty = false,
        )

        assertTrue(session.handleBackNavigation())

        val ready = session.readerState.value as ReaderUiState.Ready
        assertEquals(FontTier.Default, ready.fontTier)
        assertFalse(session.showDiscardEditDialogState.value)
    }

    @Test
    fun keepEditingDismissesDirtyDialogWithoutLosingSourceDraft() {
        val session = FastMdReaderSessionViewModel()
        session.readerState.value = ReaderUiState.EditingSource(
            document = markdownDocument(),
            draftSource = "# Title\n\nEdited body",
            fontTier = FontTier.Default,
            isDirty = true,
        )
        session.handleBackNavigation()

        session.keepEditing()

        val editing = session.readerState.value as ReaderUiState.EditingSource
        assertEquals("# Title\n\nEdited body", editing.draftSource)
        assertFalse(session.showDiscardEditDialogState.value)
    }

    @Test
    fun discardDirtyBlockEditReturnsToReaderAndClearsDialog() {
        val session = FastMdReaderSessionViewModel()
        val blockId = MarkdownBlockId("paragraph-1")
        session.readerState.value = ReaderUiState.EditingBlock(
            document = markdownDocument(),
            blockId = blockId,
            originalSourceRange = SourceRange(9, 13, 3, 3),
            originalBlockSource = "Body",
            draftSource = "Edited body",
            fontTier = FontTier.Compact,
            isDirty = true,
        )
        session.handleBackNavigation()

        session.discardEdits()

        val ready = session.readerState.value as ReaderUiState.Ready
        assertEquals(FontTier.Compact, ready.fontTier)
        assertFalse(session.showDiscardEditDialogState.value)
    }

    @Test
    fun discardDirtySourceEditReturnsToReaderAndClearsDialog() {
        val session = FastMdReaderSessionViewModel()
        session.readerState.value = ReaderUiState.EditingSource(
            document = markdownDocument(),
            draftSource = "# Title\n\nEdited body",
            fontTier = FontTier.Reader,
            isDirty = true,
        )
        session.handleBackNavigation()

        session.discardEdits()

        val ready = session.readerState.value as ReaderUiState.Ready
        assertEquals("# Title\n\nBody", ready.document.source)
        assertEquals(FontTier.Reader, ready.fontTier)
        assertFalse(session.showDiscardEditDialogState.value)
    }

    @Test
    fun retainedViewModelStateKeepsRotationCriticalReaderState() {
        val session = FastMdReaderSessionViewModel()
        val ready = readyState(fontTier = FontTier.Large)
        session.readerState.value = ReaderUiState.Searching(
            ready = ready,
            query = "Title",
            resultCount = 1,
            activeResultIndex = 0,
        )

        session.updateVisibleBlock(MarkdownBlockId("paragraph-1"))

        val searching = session.readerState.value as ReaderUiState.Searching
        assertEquals("Title", searching.query)
        assertEquals(1, searching.resultCount)
        assertEquals(0, searching.activeResultIndex)
        assertEquals(FontTier.Large, searching.ready.fontTier)
        assertEquals(MarkdownBlockId("paragraph-1"), searching.ready.scrollBlockId)
    }

    @Test
    fun retainedViewModelStateKeepsDirtySourceDraftForRotation() {
        val session = FastMdReaderSessionViewModel()
        session.readerState.value = ReaderUiState.EditingSource(
            document = markdownDocument(),
            draftSource = "# Title\n\nBody",
            fontTier = FontTier.Large,
            isDirty = false,
        )

        session.updateSourceDraft("# Title\n\nEdited body")

        val editing = session.readerState.value as ReaderUiState.EditingSource
        assertEquals("# Title\n\nEdited body", editing.draftSource)
        assertEquals(FontTier.Large, editing.fontTier)
        assertTrue(editing.isDirty)
    }

    @Test
    fun backFromTransientReaderStatesReturnsToRecentDocumentsSurface() {
        val session = FastMdReaderSessionViewModel()
        val document = markdownDocument()
        val states = listOf(
            ReaderUiState.Loading("note.md"),
            ReaderUiState.Rendering(document, FontTier.Default),
            ReaderUiState.Saving(document, "# Title\n\nEdited body"),
            ReaderUiState.Error(FastMdErrorCode.ReadIoFailure, "Read failed.", recoverable = true),
            ReaderUiState.PermissionLost("note.md"),
        )

        states.forEach { state ->
            session.readerState.value = state

            assertTrue(session.handleBackNavigation())
            assertEquals(ReaderUiState.Empty, session.readerState.value)
        }
    }

    @Test
    fun updateSourceDraftTracksDirtyStateConsistently() {
        val session = FastMdReaderSessionViewModel()
        val document = markdownDocument()
        session.readerState.value = ReaderUiState.EditingSource(
            document = document,
            draftSource = document.source,
            fontTier = FontTier.Default,
            isDirty = false,
        )

        session.updateSourceDraft("# Title\n\nEdited body")
        assertTrue((session.readerState.value as ReaderUiState.EditingSource).isDirty)

        session.updateSourceDraft(document.source)
        assertFalse((session.readerState.value as ReaderUiState.EditingSource).isDirty)
    }

    private fun readyState(
        fontTier: FontTier = FontTier.Default,
        scrollBlockId: MarkdownBlockId? = null,
    ): ReaderUiState.Ready =
        ReaderUiState.Ready(
            document = markdownDocument(),
            renderModel = renderModel(),
            fontTier = fontTier,
            scrollBlockId = scrollBlockId,
        )

    private fun markdownDocument(): MarkdownDocument =
        MarkdownDocument(
            title = "note.md",
            source = "# Title\n\nBody",
            origin = DocumentOrigin.SharedText,
            isWritable = true,
        )

    private fun renderModel(): MarkdownRenderModel =
        MarkdownRenderModel(
            sourceRevision = 1L,
            blocks = listOf(
                MarkdownRenderBlock(
                    id = MarkdownBlockId("heading-0"),
                    kind = MarkdownBlockKind.Heading,
                    sourceRange = SourceRange(0, 7, 1, 1),
                    ordinal = 0,
                    plainText = "Title",
                    attributes = mapOf("level" to "1"),
                ),
                MarkdownRenderBlock(
                    id = MarkdownBlockId("paragraph-1"),
                    kind = MarkdownBlockKind.Paragraph,
                    sourceRange = SourceRange(9, 13, 3, 3),
                    ordinal = 1,
                    plainText = "Body",
                ),
            ),
        )

    private fun recentDocument(): RecentDocumentMetadata =
        RecentDocumentMetadata(
            handleId = DocumentHandleId("recent-1"),
            reference = PlatformDocumentReference(
                kind = DocumentReferenceKind.AndroidContentUri,
                rawReference = "content://fastmd.example/recent-1.md",
                scheme = "content",
                authority = "fastmd.example",
            ),
            displayName = "recent-1.md",
            permissionGrant = DocumentPermissionGrant.PersistedRead,
            lastKnownSizeBytes = 42L,
            lastKnownModifiedEpochMillis = 1_700_000_000_000L,
            lastOpenedEpochMillis = 1_700_000_010_000L,
            writeCapability = DocumentWriteCapability.ReadOnly,
        )
}
