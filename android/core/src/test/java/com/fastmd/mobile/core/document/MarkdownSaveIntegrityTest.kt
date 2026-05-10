package com.fastmd.mobile.core.document

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class MarkdownSaveIntegrityTest {
    @Test
    fun utf8BomSaveDoesNotDuplicateLeadingBom() {
        val prepared = MarkdownSourceCodec.prepareForSave(
            draftSource = "\uFEFF# Title\n\nBody\n",
            encoding = MarkdownEncoding.Utf8Bom,
            lineEnding = MarkdownLineEnding.Lf,
        )

        assertEquals("# Title\n\nBody\n", prepared.source)
        assertEquals(MarkdownLineEnding.Lf, prepared.lineEnding)
        assertFalse(prepared.bytes.drop(3).take(3) == utf8Bom.toList())
        assertArrayEquals(utf8Bom, prepared.bytes.take(3).toByteArray())
    }

    @Test
    fun utf8SaveStripsAccidentalLeadingBom() {
        val prepared = MarkdownSourceCodec.prepareForSave(
            draftSource = "\uFEFF# Title\n",
            encoding = MarkdownEncoding.Utf8,
            lineEnding = MarkdownLineEnding.Lf,
        )

        assertEquals("# Title\n", prepared.source)
        assertFalse(prepared.bytes.take(3) == utf8Bom.toList())
    }

    @Test
    fun savePreservesLoadedCrlfLineEndings() {
        val prepared = MarkdownSourceCodec.prepareForSave(
            draftSource = "# Title\n\nBody\r\nTail\rLoose",
            encoding = MarkdownEncoding.Utf8,
            lineEnding = MarkdownLineEnding.Crlf,
        )

        assertEquals("# Title\r\n\r\nBody\r\nTail\r\nLoose", prepared.source)
        assertEquals(MarkdownLineEnding.Crlf, prepared.lineEnding)
    }

    @Test
    fun savePreservesLoadedLfLineEndings() {
        val prepared = MarkdownSourceCodec.prepareForSave(
            draftSource = "# Title\r\n\r\nBody\rTail\n",
            encoding = MarkdownEncoding.Utf8,
            lineEnding = MarkdownLineEnding.Lf,
        )

        assertEquals("# Title\n\nBody\nTail\n", prepared.source)
        assertEquals(MarkdownLineEnding.Lf, prepared.lineEnding)
    }

    @Test
    fun saveLeavesMixedLineEndingsUnchanged() {
        val draft = "# Title\r\n\nBody\n"

        val prepared = MarkdownSourceCodec.prepareForSave(
            draftSource = draft,
            encoding = MarkdownEncoding.Utf8,
            lineEnding = MarkdownLineEnding.Mixed,
        )

        assertEquals(draft, prepared.source)
        assertEquals(MarkdownLineEnding.Mixed, prepared.lineEnding)
    }

    @Test
    fun decodeUtf8ReportsBomAndStripsItFromSource() {
        val decoded = MarkdownSourceCodec.decodeUtf8(utf8Bom + "# Title\n".toByteArray())

        assertEquals("# Title\n", decoded.source)
        assertEquals(MarkdownEncoding.Utf8Bom, decoded.encoding)
    }

    private companion object {
        val utf8Bom = byteArrayOf(0xEF.toByte(), 0xBB.toByte(), 0xBF.toByte())
    }
}
