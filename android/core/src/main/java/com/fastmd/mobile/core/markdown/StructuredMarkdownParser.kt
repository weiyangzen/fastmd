package com.fastmd.mobile.core.markdown

import com.fastmd.mobile.core.render.MarkdownBlockId
import com.fastmd.mobile.core.render.MarkdownBlockKind
import com.fastmd.mobile.core.render.MarkdownInlineSpan
import com.fastmd.mobile.core.render.MarkdownRenderBlock
import com.fastmd.mobile.core.render.MarkdownRenderModel
import com.fastmd.mobile.core.render.SourceRange
import java.util.Locale
import java.util.zip.CRC32

object StructuredMarkdownParser {
    fun parse(
        source: String,
        sourceRevision: Long = source.stableRevision(),
        documentBaseUri: String? = null,
    ): MarkdownRenderModel {
        val lines = source.toSourceLines()
        val blocks = mutableListOf<MarkdownRenderBlock>()
        var index = 0

        while (index < lines.size) {
            val line = lines[index]
            if (line.text.isBlank()) {
                index += 1
                continue
            }

            val parsed = when {
                isCodeFenceStart(line.text) -> parseCodeFence(lines, index)
                isMathBlockStart(line.text) -> parseMathBlock(lines, index)
                isAtxHeading(line.text) -> parseHeading(lines, index)
                isHorizontalRule(line.text) -> parseHorizontalRule(lines, index)
                isTableStart(lines, index) -> parseTable(lines, index)
                isBlockquoteStart(line.text) -> parseBlockquote(lines, index)
                isListStart(line.text) -> parseList(lines, index)
                isFootnoteStart(line.text) -> parseFootnote(lines, index)
                isImageOnly(line.text) -> parseImage(lines, index, documentBaseUri)
                isDetailsStart(line.text) -> parseDetails(lines, index)
                isVideoHtml(line.text) -> parseVideoHtml(lines, index)
                isHtmlStart(line.text) -> parseHtmlFallback(lines, index, MarkdownBlockKind.HtmlFallback)
                else -> parseParagraph(lines, index)
            }

            blocks += parsed.block.copy(ordinal = blocks.size)
            index = parsed.nextIndex
        }

        return MarkdownRenderModel(
            sourceRevision = sourceRevision,
            blocks = blocks,
        )
    }

    private fun parseHeading(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        val line = lines[startIndex]
        val match = AtxHeadingRegex.matchEntire(line.text.trim()) ?: error("Expected heading.")
        val level = match.groupValues[1].length
        val inline = MarkdownInlineParser.parse(
            match.groupValues[2].trim().replace(ClosingHeadingMarkerRegex, ""),
        )

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = startIndex,
            kind = MarkdownBlockKind.Heading,
            plainText = inline.plainText,
            inlineSpans = inline.spans,
            attributes = mapOf("level" to level.toString()),
        )
    }

    private fun parseHorizontalRule(lines: List<SourceLine>, startIndex: Int): ParsedBlock =
        parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = startIndex,
            kind = MarkdownBlockKind.HorizontalRule,
            plainText = "",
        )

    private fun parseCodeFence(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        val opening = lines[startIndex].text.trimStart()
        val fenceMarker = opening.takeWhile { it == opening.first() }
        val language = opening.drop(fenceMarker.length).trim().substringBefore(' ').trim()
        var endIndex = startIndex
        var cursor = startIndex + 1

        while (cursor < lines.size) {
            if (lines[cursor].text.trimStart().startsWith(fenceMarker)) {
                endIndex = cursor
                cursor = lines.size
            } else {
                endIndex = cursor
                cursor += 1
            }
        }

        val contentLines = if (endIndex > startIndex) {
            val contentEnd = if (lines[endIndex].text.trimStart().startsWith(fenceMarker)) {
                endIndex
            } else {
                endIndex + 1
            }
            lines.subList(startIndex + 1, contentEnd).joinToString("\n") { it.text }
        } else {
            ""
        }
        val normalizedLanguage = language.lowercase(Locale.ROOT)
        val kind = if (normalizedLanguage == "mermaid") {
            MarkdownBlockKind.Mermaid
        } else {
            MarkdownBlockKind.CodeFence
        }

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = kind,
            plainText = contentLines,
            attributes = buildMap {
                if (language.isNotBlank()) {
                    put("language", language)
                }
                put("fence", fenceMarker)
            },
        )
    }

    private fun parseMathBlock(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        var endIndex = startIndex
        var cursor = startIndex + 1

        while (cursor < lines.size) {
            if (isMathBlockStart(lines[cursor].text)) {
                endIndex = cursor
                cursor = lines.size
            } else {
                endIndex = cursor
                cursor += 1
            }
        }

        val contentEnd = if (endIndex > startIndex && isMathBlockStart(lines[endIndex].text)) {
            endIndex
        } else {
            endIndex + 1
        }
        val content = lines.subList(startIndex + 1, contentEnd).joinToString("\n") { it.text }.trim()

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = MarkdownBlockKind.MathBlock,
            plainText = content,
            attributes = mapOf("display" to "true"),
        )
    }

    private fun parseTable(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        var endIndex = startIndex + 1
        var cursor = startIndex + 2

        while (cursor < lines.size && lines[cursor].text.isNotBlank() && lines[cursor].text.contains('|')) {
            endIndex = cursor
            cursor += 1
        }

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = MarkdownBlockKind.Table,
            plainText = lines.subList(startIndex, endIndex + 1).joinToString("\n") { it.text },
        )
    }

    private fun parseBlockquote(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        var endIndex = startIndex
        var cursor = startIndex + 1

        while (cursor < lines.size && (lines[cursor].text.isBlank() || isBlockquoteStart(lines[cursor].text))) {
            if (lines[cursor].text.isBlank() && cursor + 1 < lines.size && !isBlockquoteStart(lines[cursor + 1].text)) {
                break
            }
            endIndex = cursor
            cursor += 1
        }

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = MarkdownBlockKind.Blockquote,
            parsedInline = MarkdownInlineParser.parse(
                lines.subList(startIndex, endIndex + 1)
                    .joinToString("\n") { it.text.trimStart().removePrefix(">").trimStart() },
            ),
        )
    }

    private fun parseList(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        val firstLine = lines[startIndex].text
        val firstKind = when {
            isTaskListItem(firstLine) -> MarkdownBlockKind.TaskList
            isOrderedListItem(firstLine) -> MarkdownBlockKind.OrderedList
            else -> MarkdownBlockKind.UnorderedList
        }
        var endIndex = startIndex
        var cursor = startIndex + 1

        while (cursor < lines.size) {
            val text = lines[cursor].text
            val continues = text.isNotBlank() &&
                (isListStart(text) || text.startsWith("  ") || text.startsWith("\t"))
            if (!continues) {
                break
            }
            endIndex = cursor
            cursor += 1
        }

        val kind = if (lines.subList(startIndex, endIndex + 1).any { isTaskListItem(it.text) }) {
            MarkdownBlockKind.TaskList
        } else {
            firstKind
        }

        val sourceText = lines.subList(startIndex, endIndex + 1).joinToString("\n") { it.text }

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = kind,
            parsedInline = MarkdownInlineParser.parse(sourceText),
        )
    }

    private fun parseFootnote(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        var endIndex = startIndex
        var cursor = startIndex + 1

        while (cursor < lines.size && lines[cursor].text.startsWith("    ")) {
            endIndex = cursor
            cursor += 1
        }

        val first = FootnoteRegex.find(lines[startIndex].text)
        val label = first?.groupValues?.getOrNull(1).orEmpty()
        val content = first?.groupValues?.getOrNull(2).orEmpty()
        val continuation = if (endIndex > startIndex) {
            lines.subList(startIndex + 1, endIndex + 1)
                .joinToString("\n") { it.text.trim() }
                .trim()
        } else {
            ""
        }
        val plainText = listOf(content, continuation)
            .filter { it.isNotBlank() }
            .joinToString("\n")

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = MarkdownBlockKind.Footnote,
            plainText = plainText,
            attributes = mapOf("label" to label).filterValues { it.isNotBlank() },
        )
    }

    private fun parseImage(
        lines: List<SourceLine>,
        startIndex: Int,
        documentBaseUri: String?,
    ): ParsedBlock {
        val line = lines[startIndex]
        val match = ImageOnlyRegex.matchEntire(line.text.trim()) ?: error("Expected image.")
        val alt = match.groupValues[1].trim()
        val source = match.groupValues[2].trim()

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = startIndex,
            kind = MarkdownBlockKind.Image,
            plainText = alt.ifBlank { source },
            attributes = mapOf(
                "alt" to alt,
                "src" to source,
                "sourceKind" to source.toAssetSourceKind(),
                "documentBaseUri" to documentBaseUri.orEmpty(),
            ).filterValues { it.isNotBlank() },
        )
    }

    private fun parseDetails(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        var endIndex = startIndex
        var cursor = startIndex + 1

        while (cursor < lines.size) {
            endIndex = cursor
            if (lines[cursor].text.trim().equals("</details>", ignoreCase = true)) {
                cursor = lines.size
            } else {
                cursor += 1
            }
        }

        val raw = lines.subList(startIndex, endIndex + 1).joinToString("\n") { it.text }
        val summary = SummaryRegex.find(raw)?.groupValues?.getOrNull(1)?.stripHtmlTags()?.trim().orEmpty()
        val body = raw
            .replace(DetailsTagRegex, "")
            .replace(SummaryRegex, "")
            .stripHtmlTags()
            .lines()
            .map { it.trim() }
            .filter { it.isNotBlank() }
            .joinToString("\n")

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = MarkdownBlockKind.Details,
            plainText = body,
            attributes = mapOf(
                "summary" to summary.ifBlank { "Details" },
                "open" to raw.contains("<details open", ignoreCase = true).toString(),
            ),
        )
    }

    private fun parseVideoHtml(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        val isVideo = lines[startIndex].text.trimStart().startsWith("<video", ignoreCase = true)
        var endIndex = startIndex
        var cursor = startIndex + 1

        if (isVideo && !lines[startIndex].text.contains("</video>", ignoreCase = true)) {
            while (cursor < lines.size) {
                endIndex = cursor
                if (lines[cursor].text.trim().equals("</video>", ignoreCase = true)) {
                    cursor = lines.size
                } else {
                    cursor += 1
                }
            }
        }

        val raw = lines.subList(startIndex, endIndex + 1).joinToString("\n") { it.text }
        val source = SrcAttributeRegex.find(raw)?.groupValues?.getOrNull(2).orEmpty()
        val label = if (isVideo) "Video" else "Embedded frame"

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = MarkdownBlockKind.VideoHtml,
            plainText = raw.stripHtmlTags().trim().ifBlank { "$label placeholder" },
            attributes = mapOf(
                "label" to label,
                "src" to source,
                "sourceKind" to source.toAssetSourceKind(),
            ).filterValues { it.isNotBlank() },
        )
    }

    private fun parseHtmlFallback(
        lines: List<SourceLine>,
        startIndex: Int,
        kind: MarkdownBlockKind,
    ): ParsedBlock {
        var endIndex = startIndex
        var cursor = startIndex + 1

        val tagName = HtmlStartTagRegex.find(lines[startIndex].text.trim())?.groupValues?.getOrNull(1)

        while (cursor < lines.size && lines[cursor].text.isNotBlank()) {
            endIndex = cursor
            if (tagName != null && lines[cursor].text.contains("</$tagName>", ignoreCase = true)) {
                cursor = lines.size
            } else {
                cursor += 1
            }
        }
        val raw = lines.subList(startIndex, endIndex + 1).joinToString("\n") { it.text }
        val sanitized = raw.stripHtmlTags()
            .lines()
            .map { it.trim() }
            .filter { it.isNotBlank() }
            .joinToString("\n")

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = kind,
            plainText = sanitized.ifBlank { "HTML block omitted" },
            attributes = mapOf("rawTag" to (tagName ?: "html")),
        )
    }

    private fun parseParagraph(lines: List<SourceLine>, startIndex: Int): ParsedBlock {
        var endIndex = startIndex
        var cursor = startIndex + 1

        while (cursor < lines.size && lines[cursor].text.isNotBlank()) {
            if (isTableStart(lines, cursor) || isContainerBlockStart(lines[cursor].text)) {
                break
            }
            endIndex = cursor
            cursor += 1
        }

        val inline = MarkdownInlineParser.parse(
            lines.subList(startIndex, endIndex + 1).joinToString("\n") { it.text.trim() },
        )

        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndex,
            kind = MarkdownBlockKind.Paragraph,
            plainText = inline.plainText,
            inlineSpans = inline.spans,
        )
    }

    private fun parsed(
        lines: List<SourceLine>,
        startIndex: Int,
        endIndexInclusive: Int,
        kind: MarkdownBlockKind,
        plainText: String,
        inlineSpans: List<MarkdownInlineSpan> = emptyList(),
        attributes: Map<String, String> = emptyMap(),
    ): ParsedBlock {
        return parsed(
            lines = lines,
            startIndex = startIndex,
            endIndexInclusive = endIndexInclusive,
            kind = kind,
            parsedInline = ParsedInlineMarkdown(plainText = plainText, spans = inlineSpans),
            attributes = attributes,
        )
    }

    private fun parsed(
        lines: List<SourceLine>,
        startIndex: Int,
        endIndexInclusive: Int,
        kind: MarkdownBlockKind,
        parsedInline: ParsedInlineMarkdown,
        attributes: Map<String, String> = emptyMap(),
    ): ParsedBlock {
        val start = lines[startIndex]
        val end = lines[endIndexInclusive]
        val sourceSlice = lines.subList(startIndex, endIndexInclusive + 1).joinToString("") { it.sourceSlice }
        val block = MarkdownRenderBlock(
            id = MarkdownBlockId("${kind.name.lowercase(Locale.ROOT)}-${start.lineNumber}-${sourceSlice.crc32Hex()}"),
            kind = kind,
            sourceRange = SourceRange(
                startOffset = start.startOffset,
                endOffsetExclusive = end.endOffsetExclusive,
                startLine = start.lineNumber,
                endLineInclusive = end.lineNumber,
            ),
            ordinal = 0,
            plainText = parsedInline.plainText,
            inlineSpans = parsedInline.spans,
            attributes = attributes,
        )

        return ParsedBlock(
            block = block,
            nextIndex = endIndexInclusive + 1,
        )
    }

    private fun isContainerBlockStart(text: String): Boolean =
        isCodeFenceStart(text) ||
            isAtxHeading(text) ||
            isHorizontalRule(text) ||
            isMathBlockStart(text) ||
            isBlockquoteStart(text) ||
            isListStart(text) ||
            isFootnoteStart(text) ||
            isImageOnly(text) ||
            isHtmlStart(text)

    private fun isTableStart(lines: List<SourceLine>, index: Int): Boolean =
        index + 1 < lines.size &&
            lines[index].text.contains('|') &&
            TableDividerRegex.matches(lines[index + 1].text.trim())

    private fun isCodeFenceStart(text: String): Boolean {
        val trimmed = text.trimStart()
        return trimmed.startsWith("```") || trimmed.startsWith("~~~")
    }

    private fun isMathBlockStart(text: String): Boolean = text.trim() == "$$"

    private fun isAtxHeading(text: String): Boolean = AtxHeadingRegex.matches(text.trim())

    private fun isHorizontalRule(text: String): Boolean =
        HorizontalRuleRegex.matches(text.trim().replace(" ", ""))

    private fun isBlockquoteStart(text: String): Boolean = text.trimStart().startsWith(">")

    private fun isListStart(text: String): Boolean =
        isUnorderedListItem(text) || isOrderedListItem(text)

    private fun isUnorderedListItem(text: String): Boolean = UnorderedListRegex.containsMatchIn(text)

    private fun isOrderedListItem(text: String): Boolean = OrderedListRegex.containsMatchIn(text)

    private fun isTaskListItem(text: String): Boolean = TaskListRegex.containsMatchIn(text)

    private fun isFootnoteStart(text: String): Boolean = FootnoteRegex.containsMatchIn(text)

    private fun isImageOnly(text: String): Boolean = ImageOnlyRegex.matches(text.trim())

    private fun isDetailsStart(text: String): Boolean =
        text.trimStart().startsWith("<details", ignoreCase = true)

    private fun isVideoHtml(text: String): Boolean =
        text.trimStart().startsWith("<video", ignoreCase = true) ||
            text.trimStart().startsWith("<iframe", ignoreCase = true)

    private fun isHtmlStart(text: String): Boolean =
        text.trimStart().startsWith("<") && text.trimEnd().endsWith(">")

    private data class ParsedBlock(
        val block: MarkdownRenderBlock,
        val nextIndex: Int,
    )

    private val AtxHeadingRegex = Regex("""^(#{1,6})(?:\s+|$)(.*)$""")
    private val ClosingHeadingMarkerRegex = Regex("""\s+#+\s*$""")
    private val HorizontalRuleRegex = Regex("""^(?:\*{3,}|-{3,}|_{3,})$""")
    private val TableDividerRegex = Regex("""^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?$""")
    private val UnorderedListRegex = Regex("""^\s{0,3}[-+*]\s+.+$""")
    private val OrderedListRegex = Regex("""^\s{0,3}\d+[.)]\s+.+$""")
    private val TaskListRegex = Regex("""^\s{0,3}[-+*]\s+\[[ xX]\]\s+.+$""")
    private val FootnoteRegex = Regex("""^\[\^([^\]]+)]:\s*(.*)$""")
    private val ImageOnlyRegex = Regex("""^!\[([^\]]*)]\(([^)\s]+)(?:\s+["'][^"']*["'])?\)\s*$""")
    private val DetailsTagRegex = Regex("""</?details[^>]*>""", RegexOption.IGNORE_CASE)
    private val SummaryRegex = Regex("""<summary[^>]*>(.*?)</summary>""", setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL))
    private val SrcAttributeRegex = Regex("""\bsrc\s*=\s*(["'])(.*?)\1""", RegexOption.IGNORE_CASE)
    private val HtmlStartTagRegex = Regex("""^<([A-Za-z][A-Za-z0-9-]*)\b""")
}

private data class SourceLine(
    val lineNumber: Int,
    val startOffset: Int,
    val endOffsetExclusive: Int,
    val text: String,
    val sourceSlice: String,
)

private fun String.toSourceLines(): List<SourceLine> {
    if (isEmpty()) {
        return emptyList()
    }

    val lines = mutableListOf<SourceLine>()
    var offset = 0
    var lineNumber = 1

    while (offset < length) {
        val start = offset
        while (offset < length && this[offset] != '\r' && this[offset] != '\n') {
            offset += 1
        }
        val contentEnd = offset

        if (offset < length) {
            if (this[offset] == '\r' && offset + 1 < length && this[offset + 1] == '\n') {
                offset += 2
            } else {
                offset += 1
            }
        }

        lines += SourceLine(
            lineNumber = lineNumber,
            startOffset = start,
            endOffsetExclusive = offset,
            text = substring(start, contentEnd),
            sourceSlice = substring(start, offset),
        )
        lineNumber += 1
    }

    return lines
}

private fun String.stableRevision(): Long {
    val crc = CRC32()
    crc.update(toByteArray(Charsets.UTF_8))
    return crc.value
}

private fun String.crc32Hex(): String {
    val crc = CRC32()
    crc.update(toByteArray(Charsets.UTF_8))
    return crc.value.toString(16)
}

private fun String.stripHtmlTags(): String =
    replace(Regex("""<script\b[^>]*>.*?</script>""", setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL)), "")
        .replace(Regex("""<style\b[^>]*>.*?</style>""", setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL)), "")
        .replace(Regex("""<[^>]+>"""), " ")
        .replace(Regex("""[ \t]+"""), " ")

private fun String.toAssetSourceKind(): String =
    when {
        startsWith("http://", ignoreCase = true) || startsWith("https://", ignoreCase = true) -> "remote"
        startsWith("file://", ignoreCase = true) ||
            startsWith("content://", ignoreCase = true) ||
            startsWith("/") ||
            startsWith("./") ||
            startsWith("../") -> "local"
        isBlank() -> ""
        else -> "relative"
    }
