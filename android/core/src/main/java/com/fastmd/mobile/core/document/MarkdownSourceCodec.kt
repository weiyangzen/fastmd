package com.fastmd.mobile.core.document

import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.nio.charset.StandardCharsets

data class DecodedMarkdownSource(
    val source: String,
    val encoding: MarkdownEncoding,
)

data class PreparedMarkdownSave(
    val source: String,
    val bytes: ByteArray,
    val lineEnding: MarkdownLineEnding,
) {
    init {
        require(source.doesNotStartWithUtf8Bom()) { "Prepared Markdown source must not contain a leading BOM." }
    }
}

object MarkdownSourceCodec {
    fun decodeUtf8(bytes: ByteArray): DecodedMarkdownSource {
        val hasBom = bytes.size >= UTF8_BOM.size && UTF8_BOM.indices.all { bytes[it] == UTF8_BOM[it] }
        val startIndex = if (hasBom) UTF8_BOM.size else 0
        val decoder = StandardCharsets.UTF_8
            .newDecoder()
            .onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT)
        val source = decoder.decode(ByteBuffer.wrap(bytes, startIndex, bytes.size - startIndex)).toString()

        return DecodedMarkdownSource(
            source = source,
            encoding = if (hasBom) MarkdownEncoding.Utf8Bom else MarkdownEncoding.Utf8,
        )
    }

    fun prepareForSave(
        draftSource: String,
        encoding: MarkdownEncoding,
        lineEnding: MarkdownLineEnding,
    ): PreparedMarkdownSave {
        val normalizedSource = draftSource
            .trimLeadingUtf8Bom()
            .normalizeLineEndings(lineEnding)
        val body = normalizedSource.toByteArray(StandardCharsets.UTF_8)
        val bytes = when (encoding) {
            MarkdownEncoding.Utf8 -> body
            MarkdownEncoding.Utf8Bom -> UTF8_BOM + body
        }

        return PreparedMarkdownSave(
            source = normalizedSource,
            bytes = bytes,
            lineEnding = normalizedSource.detectLineEnding(),
        )
    }

    fun detectLineEnding(source: String): MarkdownLineEnding {
        val crlf = source.windowed(size = 2).count { it == "\r\n" }
        val loneLf = source.indices.count { index ->
            source[index] == '\n' && (index == 0 || source[index - 1] != '\r')
        }

        return when {
            crlf > 0 && loneLf > 0 -> MarkdownLineEnding.Mixed
            crlf > 0 -> MarkdownLineEnding.Crlf
            loneLf > 0 -> MarkdownLineEnding.Lf
            else -> MarkdownLineEnding.Unknown
        }
    }

    private val UTF8_BOM = byteArrayOf(0xEF.toByte(), 0xBB.toByte(), 0xBF.toByte())
}

private fun String.normalizeLineEndings(lineEnding: MarkdownLineEnding): String =
    when (lineEnding) {
        MarkdownLineEnding.Crlf -> replace("\r\n", "\n").replace("\r", "\n").replace("\n", "\r\n")
        MarkdownLineEnding.Lf -> replace("\r\n", "\n").replace("\r", "\n")
        MarkdownLineEnding.Mixed,
        MarkdownLineEnding.Unknown,
        -> this
    }

private fun String.trimLeadingUtf8Bom(): String =
    if (startsWith('\uFEFF')) drop(1) else this

private fun String.doesNotStartWithUtf8Bom(): Boolean =
    !startsWith('\uFEFF')

private fun String.detectLineEnding(): MarkdownLineEnding =
    MarkdownSourceCodec.detectLineEnding(this)
