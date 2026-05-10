package com.fastmd.mobile.core.reader

import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.render.SourceRange

data class BlockSourceEditSnapshot(
    val blockId: MarkdownBlockId,
    val sourceRange: SourceRange,
    val originalSource: String,
) {
    init {
        require(originalSource.isNotEmpty()) { "Block source snapshot cannot be empty." }
    }
}

sealed interface BlockSourceEditResult {
    data class Applied(
        val fullSource: String,
    ) : BlockSourceEditResult

    data class RangeMismatch(
        val message: String,
    ) : BlockSourceEditResult {
        init {
            require(message.isNotBlank()) { "Range mismatch message cannot be blank." }
        }
    }
}

object BlockSourceEdit {
    fun apply(
        currentSource: String,
        snapshot: BlockSourceEditSnapshot,
        draftBlockSource: String,
    ): BlockSourceEditResult {
        val range = snapshot.sourceRange
        if (range.endOffsetExclusive > currentSource.length) {
            return BlockSourceEditResult.RangeMismatch(
                "The mapped block range is outside the current document.",
            )
        }

        val currentBlockSource = currentSource.substring(range.startOffset, range.endOffsetExclusive)
        if (currentBlockSource != snapshot.originalSource) {
            return BlockSourceEditResult.RangeMismatch(
                "The mapped block source changed before save. Reopen block edit and try again.",
            )
        }

        return BlockSourceEditResult.Applied(
            fullSource = buildString(
                currentSource.length - snapshot.originalSource.length + draftBlockSource.length,
            ) {
                append(currentSource, 0, range.startOffset)
                append(draftBlockSource)
                append(currentSource, range.endOffsetExclusive, currentSource.length)
            },
        )
    }
}
