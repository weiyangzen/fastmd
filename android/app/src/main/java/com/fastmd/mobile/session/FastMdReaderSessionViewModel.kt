package com.fastmd.mobile.session

import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import com.fastmd.mobile.core.diagnostics.DiagnosticsOperation
import com.fastmd.mobile.core.diagnostics.DiagnosticsOperationStatus
import com.fastmd.mobile.core.diagnostics.LocalDiagnosticsReport
import com.fastmd.mobile.core.document.MarkdownFileMetadata
import com.fastmd.mobile.core.document.MarkdownDocument
import com.fastmd.mobile.core.document.MarkdownLoadResult
import com.fastmd.mobile.core.document.MobileDocumentHandle
import com.fastmd.mobile.core.document.MobilePlatform
import com.fastmd.mobile.core.document.RecentDocumentMetadata
import com.fastmd.mobile.core.error.FastMdErrorCode
import com.fastmd.mobile.core.markdown.StructuredMarkdownParser
import com.fastmd.mobile.core.performance.AndroidPerformanceProfile
import com.fastmd.mobile.core.reader.FontTier
import com.fastmd.mobile.core.reader.ReaderThemeMode
import com.fastmd.mobile.core.reader.ReaderUiState
import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.recovery.AndroidRecoveryDraft
import com.fastmd.mobile.recovery.AndroidRecoveryDraftBase
import com.fastmd.mobile.recovery.AndroidRecoveryDraftMode
import com.fastmd.mobile.recovery.AndroidRecoveryDraftSummary

class FastMdReaderSessionViewModel : ViewModel() {
    val readerState = mutableStateOf<ReaderUiState>(ReaderUiState.Empty)
    val recentDocumentsState = mutableStateOf<List<RecentDocumentMetadata>>(emptyList())
    val fontTierState = mutableStateOf(FontTier.initial)
    val themeModeState = mutableStateOf(ReaderThemeMode.initial)
    val performanceProfileState = mutableStateOf(AndroidPerformanceProfile.ModernStandard)
    val showDiscardEditDialogState = mutableStateOf(false)
    val recoveryDraftSummaryState = mutableStateOf<AndroidRecoveryDraftSummary?>(null)
    val diagnosticsReportState = mutableStateOf(
        LocalDiagnosticsReport.initial(
            platform = MobilePlatform.Android,
            deviceClass = AndroidPerformanceProfile.ModernStandard,
        ),
    )

    var activeHandle: MobileDocumentHandle? = null
        private set
    var activeMetadata: MarkdownFileMetadata? = null
        private set

    fun setActiveDocumentContext(result: MarkdownLoadResult.Loaded) {
        activeHandle = result.handle
        activeMetadata = result.metadata
    }

    fun clearActiveDocumentContext() {
        activeHandle = null
        activeMetadata = null
    }

    fun updateActiveMetadata(metadata: MarkdownFileMetadata) {
        activeMetadata = metadata
    }

    fun setPerformanceProfile(profile: AndroidPerformanceProfile) {
        performanceProfileState.value = profile
        diagnosticsReportState.value = diagnosticsReportState.value.copy(deviceClass = profile)
    }

    fun recordLoadedDocument(result: MarkdownLoadResult.Loaded) {
        diagnosticsReportState.value = diagnosticsReportState.value.withDocument(
            metadata = result.metadata,
            origin = result.origin,
            writable = result.document.isWritable,
        )
    }

    fun recordFailure(code: FastMdErrorCode) {
        diagnosticsReportState.value = diagnosticsReportState.value.withoutDocument(
            errorCategory = code.category,
        )
    }

    fun recordParseSuccess(durationMillis: Long, blockCount: Int) {
        diagnosticsReportState.value = diagnosticsReportState.value.copy(
            parse = DiagnosticsOperation(
                status = DiagnosticsOperationStatus.Pass,
                durationMillis = durationMillis,
                itemCount = blockCount,
            ),
            render = DiagnosticsOperation(
                status = DiagnosticsOperationStatus.Pass,
                itemCount = blockCount,
            ),
            lastErrorCategory = null,
        )
    }

    fun recordSearchSuccess(durationMillis: Long, resultCount: Int) {
        diagnosticsReportState.value = diagnosticsReportState.value.copy(
            search = DiagnosticsOperation(
                status = DiagnosticsOperationStatus.Pass,
                durationMillis = durationMillis,
                itemCount = resultCount,
            ),
            lastErrorCategory = null,
        )
    }

    fun recordSaveSuccess(durationMillis: Long, metadata: MarkdownFileMetadata) {
        diagnosticsReportState.value = diagnosticsReportState.value.copy(
            fileSizeBucket = com.fastmd.mobile.core.diagnostics.DiagnosticsFileSizeBucket.fromBytes(metadata.sizeBytes),
            save = DiagnosticsOperation(
                status = DiagnosticsOperationStatus.Pass,
                durationMillis = durationMillis,
            ),
            lastErrorCategory = null,
        )
    }

    fun recordSaveFailure(durationMillis: Long, code: FastMdErrorCode) {
        diagnosticsReportState.value = diagnosticsReportState.value.copy(
            save = DiagnosticsOperation(
                status = DiagnosticsOperationStatus.Failed,
                durationMillis = durationMillis,
            ),
            lastErrorCategory = code.category,
        )
    }

    fun updateVisibleBlock(blockId: MarkdownBlockId) {
        readerState.value = when (val state = readerState.value) {
            is ReaderUiState.Ready -> state.copy(scrollBlockId = blockId)
            is ReaderUiState.Searching -> state.copy(ready = state.ready.copy(scrollBlockId = blockId))
            is ReaderUiState.ReadOnly -> state.copy(ready = state.ready.copy(scrollBlockId = blockId))
            else -> state
        }
    }

    fun handleBackNavigation(): Boolean {
        readerState.value = when (val state = readerState.value) {
            ReaderUiState.Empty -> return false
            is ReaderUiState.Searching -> state.ready
            is ReaderUiState.EditingBlock -> if (state.isDirty) {
                showDiscardEditDialogState.value = true
                state
            } else {
                state.toReady()
            }
            is ReaderUiState.EditingSource -> if (state.isDirty) {
                showDiscardEditDialogState.value = true
                state
            } else {
                state.toReady()
            }
            is ReaderUiState.ReadOnly -> state.ready
            is ReaderUiState.Ready,
            is ReaderUiState.Error,
            is ReaderUiState.Loading,
            is ReaderUiState.PermissionLost,
            is ReaderUiState.Rendering,
            is ReaderUiState.Saving,
            -> ReaderUiState.Empty
        }
        return true
    }

    fun beginSourceEdit() {
        val ready = when (val state = readerState.value) {
            is ReaderUiState.Ready -> state
            is ReaderUiState.Searching -> state.ready
            is ReaderUiState.ReadOnly -> state.ready
            else -> return
        }
        readerState.value = ReaderUiState.EditingSource(
            document = ready.document,
            draftSource = ready.document.source,
            fontTier = ready.fontTier,
            isDirty = false,
        )
    }

    fun beginBlockEdit(blockId: MarkdownBlockId) {
        val ready = when (val state = readerState.value) {
            is ReaderUiState.Ready -> state
            is ReaderUiState.Searching -> state.ready
            is ReaderUiState.ReadOnly -> state.ready
            else -> return
        }
        val block = ready.renderModel.blocks.firstOrNull { it.id == blockId } ?: return
        val range = block.sourceRange
        if (range.endOffsetExclusive > ready.document.source.length) {
            return
        }
        val blockSource = ready.document.source.substring(range.startOffset, range.endOffsetExclusive)
        readerState.value = ReaderUiState.EditingBlock(
            document = ready.document,
            blockId = block.id,
            originalSourceRange = range,
            originalBlockSource = blockSource,
            draftSource = blockSource,
            fontTier = ready.fontTier,
            isDirty = false,
        )
    }

    fun updateSourceDraft(draftSource: String) {
        val editing = readerState.value as? ReaderUiState.EditingSource ?: return
        readerState.value = editing.copy(
            draftSource = draftSource,
            isDirty = draftSource != editing.document.source,
        )
    }

    fun updateBlockDraft(draftSource: String) {
        val editing = readerState.value as? ReaderUiState.EditingBlock ?: return
        readerState.value = editing.copy(
            draftSource = draftSource,
            isDirty = draftSource != editing.originalBlockSource,
        )
    }

    fun cancelSourceEdit() {
        val editing = readerState.value as? ReaderUiState.EditingSource ?: return
        if (editing.isDirty) {
            showDiscardEditDialogState.value = true
        } else {
            readerState.value = editing.toReady()
        }
    }

    fun cancelBlockEdit() {
        val editing = readerState.value as? ReaderUiState.EditingBlock ?: return
        if (editing.isDirty) {
            showDiscardEditDialogState.value = true
        } else {
            readerState.value = editing.toReady()
        }
    }

    fun keepEditing() {
        showDiscardEditDialogState.value = false
    }

    fun discardEdits() {
        showDiscardEditDialogState.value = false
        readerState.value = when (val state = readerState.value) {
            is ReaderUiState.EditingBlock -> state.toReady()
            is ReaderUiState.EditingSource -> state.toReady()
            else -> state
        }
    }

    fun restoreFailedSourceSave(
        document: MarkdownDocument,
        draftSource: String,
        fontTier: FontTier,
        errorMessage: String,
    ) {
        readerState.value = ReaderUiState.EditingSource(
            document = document,
            draftSource = draftSource,
            fontTier = fontTier,
            isDirty = draftSource != document.source,
            saveErrorMessage = errorMessage,
        )
    }

    fun restoreFailedBlockSave(
        editing: ReaderUiState.EditingBlock,
        errorMessage: String,
    ) {
        readerState.value = editing.copy(
            isDirty = editing.draftSource != editing.originalBlockSource,
            saveErrorMessage = errorMessage,
        )
    }

    fun createRecoveryDraft(): AndroidRecoveryDraft? {
        val handle = activeHandle ?: return null
        val metadata = activeMetadata ?: return null
        if (!handle.canRecoverAfterProcessDeath) {
            return null
        }
        val state = readerState.value
        val base = when (state) {
            is ReaderUiState.EditingSource -> {
                if (!state.isDirty) {
                    return null
                }
                AndroidRecoveryDraftBase(
                    mode = AndroidRecoveryDraftMode.Source,
                    savedAtEpochMillis = System.currentTimeMillis(),
                    title = state.document.title,
                    origin = state.document.origin,
                    fontTier = state.fontTier,
                    handle = handle,
                    metadata = metadata,
                    draftSource = state.draftSource,
                )
            }

            is ReaderUiState.EditingBlock -> {
                if (!state.isDirty) {
                    return null
                }
                AndroidRecoveryDraftBase(
                    mode = AndroidRecoveryDraftMode.Block,
                    savedAtEpochMillis = System.currentTimeMillis(),
                    title = state.document.title,
                    origin = state.document.origin,
                    fontTier = state.fontTier,
                    handle = handle,
                    metadata = metadata,
                    draftSource = state.draftSource,
                )
            }

            else -> return null
        }

        return when (state) {
            is ReaderUiState.EditingSource -> AndroidRecoveryDraft.Source(base)
            is ReaderUiState.EditingBlock -> AndroidRecoveryDraft.Block(
                base = base,
                blockId = state.blockId,
                originalSourceRange = state.originalSourceRange,
                originalBlockSource = state.originalBlockSource,
            )

            else -> null
        }
    }

    private fun ReaderUiState.EditingSource.toReady(): ReaderUiState.Ready =
        ready(
            document = document,
            fontTier = fontTier,
        )

    private fun ReaderUiState.EditingBlock.toReady(): ReaderUiState.Ready =
        ready(
            document = document,
            fontTier = fontTier,
        )

    private fun ready(
        document: MarkdownDocument,
        fontTier: FontTier,
    ): ReaderUiState.Ready =
        ReaderUiState.Ready(
            document = document,
            renderModel = StructuredMarkdownParser.parse(document.source),
            fontTier = fontTier,
        )

    private val MobileDocumentHandle.canRecoverAfterProcessDeath: Boolean
        get() = reference.kind == com.fastmd.mobile.core.document.DocumentReferenceKind.AndroidContentUri ||
            reference.kind == com.fastmd.mobile.core.document.DocumentReferenceKind.AndroidFileUri
}
