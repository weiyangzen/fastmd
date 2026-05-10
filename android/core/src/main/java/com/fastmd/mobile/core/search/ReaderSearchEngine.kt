package com.fastmd.mobile.core.search

import com.fastmd.mobile.core.render.MarkdownRenderModel

data class ReaderSearchSummary(
    val query: String,
    val resultCount: Int,
    val activeResultIndex: Int?,
) {
    init {
        require(query.isNotBlank()) { "Search query cannot be blank." }
        require(resultCount >= 0) { "Search result count cannot be negative." }
        require(activeResultIndex == null || activeResultIndex in 0 until resultCount) {
            "Active search result index must reference an existing result."
        }
    }
}

object ReaderSearchEngine {
    fun summarize(
        renderModel: MarkdownRenderModel,
        query: String,
        preferredActiveResultIndex: Int? = 0,
    ): ReaderSearchSummary? {
        val normalizedQuery = query.trim()
        if (normalizedQuery.isBlank()) {
            return null
        }

        val resultCount = renderModel.blocks.sumOf { block ->
            countMatches(block.plainText, normalizedQuery)
        }
        val activeResultIndex = if (resultCount == 0) {
            null
        } else {
            preferredActiveResultIndex
                ?.coerceIn(0, resultCount - 1)
                ?: 0
        }

        return ReaderSearchSummary(
            query = normalizedQuery,
            resultCount = resultCount,
            activeResultIndex = activeResultIndex,
        )
    }

    fun next(summary: ReaderSearchSummary): ReaderSearchSummary =
        summary.copy(activeResultIndex = summary.activeResultIndex.nextIn(summary.resultCount))

    fun previous(summary: ReaderSearchSummary): ReaderSearchSummary =
        summary.copy(activeResultIndex = summary.activeResultIndex.previousIn(summary.resultCount))

    fun countMatches(
        text: String,
        query: String,
    ): Int {
        val normalizedQuery = query.trim()
        if (text.isEmpty() || normalizedQuery.isBlank()) {
            return 0
        }

        var count = 0
        var index = 0
        while (index <= text.length - normalizedQuery.length) {
            val matches = text.regionMatches(
                thisOffset = index,
                other = normalizedQuery,
                otherOffset = 0,
                length = normalizedQuery.length,
                ignoreCase = true,
            )
            if (matches) {
                count += 1
                index += normalizedQuery.length
            } else {
                index += 1
            }
        }
        return count
    }

    private fun Int?.nextIn(resultCount: Int): Int? =
        if (this == null || resultCount == 0) {
            null
        } else {
            (this + 1) % resultCount
        }

    private fun Int?.previousIn(resultCount: Int): Int? =
        if (this == null || resultCount == 0) {
            null
        } else {
            (this - 1 + resultCount) % resultCount
        }
}
