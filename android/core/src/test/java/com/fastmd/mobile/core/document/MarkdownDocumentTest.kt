package com.fastmd.mobile.core.document

import org.junit.Assert.assertEquals
import org.junit.Test

class MarkdownDocumentTest {
    @Test
    fun lineCountCountsRepresentativeMarkdownLines() {
        val document = MarkdownDocument(
            title = "basic.md",
            source = "# FastMD\n\nBody",
            origin = DocumentOrigin.AppCreated,
            isWritable = true,
        )

        assertEquals(3, document.lineCount)
    }
}
