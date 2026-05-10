package com.fastmd.mobile.core.search

import com.fastmd.mobile.core.markdown.StructuredMarkdownParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ReaderSearchEngineTest {
    @Test
    fun summarizesCaseInsensitiveMatchesAcrossRenderedBlocks() {
        val renderModel = StructuredMarkdownParser.parse("# Alpha\n\nalpha beta\n\nNo match")

        val summary = ReaderSearchEngine.summarize(renderModel, "ALPHA")

        requireNotNull(summary)
        assertEquals("ALPHA", summary.query)
        assertEquals(2, summary.resultCount)
        assertEquals(0, summary.activeResultIndex)
    }

    @Test
    fun returnsNullForBlankSearchQuery() {
        val renderModel = StructuredMarkdownParser.parse("Body")

        assertNull(ReaderSearchEngine.summarize(renderModel, " "))
    }

    @Test
    fun nextAndPreviousWrapAroundAvailableResults() {
        val renderModel = StructuredMarkdownParser.parse("one two one two one")
        val summary = requireNotNull(
            ReaderSearchEngine.summarize(
                renderModel = renderModel,
                query = "one",
                preferredActiveResultIndex = 2,
            ),
        )

        assertEquals(0, ReaderSearchEngine.next(summary).activeResultIndex)
        assertEquals(1, ReaderSearchEngine.previous(summary).activeResultIndex)
    }

    @Test
    fun unmatchedSearchHasNoActiveResult() {
        val renderModel = StructuredMarkdownParser.parse("Body")

        val summary = ReaderSearchEngine.summarize(renderModel, "missing")

        requireNotNull(summary)
        assertEquals(0, summary.resultCount)
        assertNull(summary.activeResultIndex)
    }
}
