package com.fastmd.mobile.core.reader

import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.render.SourceRange
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class BlockSourceEditTest {
    @Test
    fun replacesOnlyMappedBlockSource() {
        val source = "# Title\n\nBody\n\nTail\n"
        val snapshot = BlockSourceEditSnapshot(
            blockId = MarkdownBlockId("paragraph-3"),
            sourceRange = SourceRange(9, 14, 3, 3),
            originalSource = "Body\n",
        )

        val result = BlockSourceEdit.apply(
            currentSource = source,
            snapshot = snapshot,
            draftBlockSource = "Updated body\n",
        )

        assertTrue(result is BlockSourceEditResult.Applied)
        assertEquals("# Title\n\nUpdated body\n\nTail\n", (result as BlockSourceEditResult.Applied).fullSource)
    }

    @Test
    fun failsClosedWhenMappedBlockNoLongerMatchesSnapshot() {
        val source = "# Title\n\nBody changed\n\nTail\n"
        val snapshot = BlockSourceEditSnapshot(
            blockId = MarkdownBlockId("paragraph-3"),
            sourceRange = SourceRange(9, 14, 3, 3),
            originalSource = "Body\n",
        )

        val result = BlockSourceEdit.apply(
            currentSource = source,
            snapshot = snapshot,
            draftBlockSource = "Updated body\n",
        )

        assertTrue(result is BlockSourceEditResult.RangeMismatch)
    }
}
