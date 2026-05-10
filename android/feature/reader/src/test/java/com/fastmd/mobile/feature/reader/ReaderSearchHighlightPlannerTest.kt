package com.fastmd.mobile.feature.reader

import com.fastmd.mobile.core.markdown.StructuredMarkdownParser
import org.junit.Assert.assertEquals
import org.junit.Test

class ReaderSearchHighlightPlannerTest {
    @Test
    fun blockMatchOffsetsAccumulateMatchesBeforeEachReaderBlock() {
        val renderModel = StructuredMarkdownParser.parse(
            """
            # Alpha alpha

            Alpha body

            No hit here

            alpha end alpha
            """.trimIndent(),
        )

        val offsets = ReaderSearchHighlightPlanner.blockMatchOffsets(renderModel, "ALPHA")

        assertEquals(0, offsets.getValue(renderModel.blocks[0].id))
        assertEquals(2, offsets.getValue(renderModel.blocks[1].id))
        assertEquals(3, offsets.getValue(renderModel.blocks[2].id))
        assertEquals(3, offsets.getValue(renderModel.blocks[3].id))
    }

    @Test
    fun blockMatchOffsetsReturnZeroesForBlankQuery() {
        val renderModel = StructuredMarkdownParser.parse("# Title\n\nBody")

        val offsets = ReaderSearchHighlightPlanner.blockMatchOffsets(renderModel, "   ")

        assertEquals(renderModel.blocks.map { it.id }.toSet(), offsets.keys)
        assertEquals(setOf(0), offsets.values.toSet())
    }

    @Test
    fun matchCountBeforeOffsetClampsToTextBounds() {
        val text = "alpha beta alpha"

        assertEquals(0, ReaderSearchHighlightPlanner.matchCountBeforeOffset(text, "alpha", -10))
        assertEquals(1, ReaderSearchHighlightPlanner.matchCountBeforeOffset(text, "alpha", 6))
        assertEquals(2, ReaderSearchHighlightPlanner.matchCountBeforeOffset(text, "alpha", 200))
    }
}
