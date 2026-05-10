package com.fastmd.mobile.feature.reader

import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.render.MarkdownRenderModel
import com.fastmd.mobile.core.search.ReaderSearchEngine

internal object ReaderSearchHighlightPlanner {
    fun blockMatchOffsets(
        renderModel: MarkdownRenderModel,
        query: String,
    ): Map<MarkdownBlockId, Int> {
        val normalizedQuery = query.trim()
        if (normalizedQuery.isBlank()) {
            return renderModel.blocks.associate { block -> block.id to 0 }
        }

        var runningTotal = 0
        return renderModel.blocks.associate { block ->
            val offset = runningTotal
            runningTotal += ReaderSearchEngine.countMatches(block.plainText, normalizedQuery)
            block.id to offset
        }
    }

    fun matchCountBeforeOffset(
        text: String,
        query: String,
        offset: Int,
    ): Int {
        val boundedOffset = offset.coerceIn(0, text.length)
        return ReaderSearchEngine.countMatches(text.take(boundedOffset), query)
    }
}
