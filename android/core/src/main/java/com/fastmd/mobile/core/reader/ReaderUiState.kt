package com.fastmd.mobile.core.reader

import com.fastmd.mobile.core.document.MarkdownDocument
import com.fastmd.mobile.core.error.FastMdErrorCode
import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.render.MarkdownRenderModel
import com.fastmd.mobile.core.render.SourceRange

sealed interface ReaderUiState {
    data object Empty : ReaderUiState

    data class Loading(
        val displayName: String?,
    ) : ReaderUiState

    data class Rendering(
        val document: MarkdownDocument,
        val fontTier: FontTier,
    ) : ReaderUiState

    data class Ready(
        val document: MarkdownDocument,
        val renderModel: MarkdownRenderModel,
        val fontTier: FontTier,
        val scrollBlockId: MarkdownBlockId? = null,
        val isDirty: Boolean = false,
    ) : ReaderUiState

    data class Searching(
        val ready: Ready,
        val query: String,
        val resultCount: Int,
        val activeResultIndex: Int?,
    ) : ReaderUiState {
        init {
            require(query.isNotBlank()) { "Search query cannot be blank in Searching state." }
            require(resultCount >= 0) { "Search result count cannot be negative." }
            require(activeResultIndex == null || activeResultIndex in 0 until resultCount) {
                "Active result index must point to an existing result."
            }
        }
    }

    data class EditingSource(
        val document: MarkdownDocument,
        val draftSource: String,
        val fontTier: FontTier,
        val isDirty: Boolean,
        val saveErrorMessage: String? = null,
    ) : ReaderUiState

    data class EditingBlock(
        val document: MarkdownDocument,
        val blockId: MarkdownBlockId,
        val originalSourceRange: SourceRange,
        val originalBlockSource: String,
        val draftSource: String,
        val fontTier: FontTier,
        val isDirty: Boolean,
        val saveErrorMessage: String? = null,
    ) : ReaderUiState

    data class Saving(
        val document: MarkdownDocument,
        val draftSource: String,
    ) : ReaderUiState

    data class ReadOnly(
        val ready: Ready,
        val reason: String,
    ) : ReaderUiState {
        init {
            require(reason.isNotBlank()) { "Read-only reason cannot be blank." }
        }
    }

    data class PermissionLost(
        val displayName: String?,
        val code: FastMdErrorCode = FastMdErrorCode.PermissionLost,
    ) : ReaderUiState

    data class Error(
        val code: FastMdErrorCode,
        val message: String,
        val recoverable: Boolean,
    ) : ReaderUiState {
        init {
            require(message.isNotBlank()) { "Error message cannot be blank." }
        }
    }
}
