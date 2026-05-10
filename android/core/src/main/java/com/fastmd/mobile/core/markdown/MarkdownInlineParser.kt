package com.fastmd.mobile.core.markdown

import com.fastmd.mobile.core.link.LinkPolicy
import com.fastmd.mobile.core.link.LinkPolicyDecision
import com.fastmd.mobile.core.link.LinkTarget
import com.fastmd.mobile.core.render.MarkdownInlineSpan
import com.fastmd.mobile.core.render.MarkdownInlineStyle
import com.fastmd.mobile.core.render.MarkdownLinkDecision

data class ParsedInlineMarkdown(
    val plainText: String,
    val spans: List<MarkdownInlineSpan>,
)

object MarkdownInlineParser {
    fun parse(
        source: String,
        linkPolicy: LinkPolicy = LinkPolicy(),
    ): ParsedInlineMarkdown {
        val builder = InlineBuilder(linkPolicy)
        builder.appendParsed(source, emptySet())
        return builder.toParsed()
    }
}

private class InlineBuilder(
    private val linkPolicy: LinkPolicy,
) {
    private val text = StringBuilder()
    private val spans = mutableListOf<MarkdownInlineSpan>()

    fun appendParsed(
        source: String,
        activeStyles: Set<MarkdownInlineStyle>,
    ) {
        var index = 0

        while (index < source.length) {
            val escaped = source.escapedTextAt(index)
            if (escaped != null) {
                text.append(escaped)
                index += escaped.length + 1
                continue
            }

            val link = source.markdownLinkAt(index)
            if (link != null) {
                appendLink(link.label, link.target, activeStyles)
                index = link.endIndexExclusive
                continue
            }

            val autoLink = source.autoLinkAt(index)
            if (autoLink != null) {
                appendLink(autoLink.label, autoLink.target, activeStyles)
                index = autoLink.endIndexExclusive
                continue
            }

            val htmlStyleTag = source.htmlStyleTagAt(index)
            if (htmlStyleTag != null) {
                appendStyled(
                    source = htmlStyleTag.body,
                    styles = activeStyles + htmlStyleTag.style,
                )
                index = htmlStyleTag.endIndexExclusive
                continue
            }

            val delimiter = source.delimiterAt(index)
            if (delimiter != null) {
                val closing = source.findUnescaped(delimiter.marker, index + delimiter.marker.length)
                if (closing >= 0) {
                    appendStyled(
                        source = source.substring(index + delimiter.marker.length, closing),
                        styles = activeStyles + delimiter.styles,
                    )
                    index = closing + delimiter.marker.length
                    continue
                }
            }

            text.append(source[index])
            index += 1
        }
    }

    fun toParsed(): ParsedInlineMarkdown =
        ParsedInlineMarkdown(
            plainText = text.toString(),
            spans = spans.filter { it.startOffset < it.endOffsetExclusive },
        )

    private fun appendStyled(
        source: String,
        styles: Set<MarkdownInlineStyle>,
    ) {
        val start = text.length
        if (MarkdownInlineStyle.InlineCode in styles || MarkdownInlineStyle.Math in styles) {
            text.append(source)
        } else {
            appendParsed(source, styles)
        }
        val end = text.length

        if (start < end) {
            spans += MarkdownInlineSpan(
                startOffset = start,
                endOffsetExclusive = end,
                styles = styles,
            )
        }
    }

    private fun appendLink(
        label: String,
        target: String,
        activeStyles: Set<MarkdownInlineStyle>,
    ) {
        val start = text.length
        appendParsed(label, activeStyles)
        val end = text.length
        if (start >= end) {
            return
        }

        val decision = linkPolicy.decide(LinkTarget(target, displayText = label))
        spans += MarkdownInlineSpan(
            startOffset = start,
            endOffsetExclusive = end,
            styles = emptySet(),
            linkTarget = target,
            linkDecision = when (decision) {
                is LinkPolicyDecision.Allowed -> MarkdownLinkDecision.Allowed
                is LinkPolicyDecision.Confirm -> MarkdownLinkDecision.Confirm
                is LinkPolicyDecision.Blocked -> MarkdownLinkDecision.Blocked
            },
        )
    }
}

private data class InlineDelimiter(
    val marker: String,
    val styles: Set<MarkdownInlineStyle>,
)

private data class InlineLink(
    val label: String,
    val target: String,
    val endIndexExclusive: Int,
)

private data class InlineHtmlStyleTag(
    val body: String,
    val style: MarkdownInlineStyle,
    val endIndexExclusive: Int,
)

private val InlineDelimiters = listOf(
    InlineDelimiter("***", setOf(MarkdownInlineStyle.Bold, MarkdownInlineStyle.Italic)),
    InlineDelimiter("___", setOf(MarkdownInlineStyle.Bold, MarkdownInlineStyle.Italic)),
    InlineDelimiter("**", setOf(MarkdownInlineStyle.Bold)),
    InlineDelimiter("__", setOf(MarkdownInlineStyle.Bold)),
    InlineDelimiter("~~", setOf(MarkdownInlineStyle.Strikethrough)),
    InlineDelimiter("==", setOf(MarkdownInlineStyle.Highlight)),
    InlineDelimiter("`", setOf(MarkdownInlineStyle.InlineCode)),
    InlineDelimiter("$", setOf(MarkdownInlineStyle.Math)),
    InlineDelimiter("*", setOf(MarkdownInlineStyle.Italic)),
    InlineDelimiter("_", setOf(MarkdownInlineStyle.Italic)),
    InlineDelimiter("~", setOf(MarkdownInlineStyle.Subscript)),
    InlineDelimiter("^", setOf(MarkdownInlineStyle.Superscript)),
)

private val InlineHtmlStyleTags = listOf(
    "mark" to MarkdownInlineStyle.Highlight,
    "sub" to MarkdownInlineStyle.Subscript,
    "sup" to MarkdownInlineStyle.Superscript,
)

private val EmailAddressRegex = Regex("""^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$""")
private val SchemeRegex = Regex("""^[A-Za-z][A-Za-z0-9+.-]*:.+""")

private fun String.escapedTextAt(index: Int): String? =
    if (this[index] == '\\' && index + 1 < length) {
        InlineDelimiters
            .firstOrNull { startsWith(it.marker, startIndex = index + 1) }
            ?.marker
            ?: this[index + 1].toString()
    } else {
        null
    }

private fun String.markdownLinkAt(index: Int): InlineLink? {
    if (this[index] != '[') {
        return null
    }

    val labelEnd = findUnescaped("]", index + 1)
    if (labelEnd < 0 || labelEnd + 1 >= length || this[labelEnd + 1] != '(') {
        return null
    }

    val targetEnd = findMarkdownLinkTargetEnd(labelEnd + 2)
    if (targetEnd < 0) {
        return null
    }

    val label = substring(index + 1, labelEnd)
    val target = substring(labelEnd + 2, targetEnd).trim()
    if (label.isBlank() || target.isBlank()) {
        return null
    }

    return InlineLink(
        label = label,
        target = target,
        endIndexExclusive = targetEnd + 1,
    )
}

private fun String.autoLinkAt(index: Int): InlineLink? {
    if (this[index] != '<') {
        return null
    }

    val end = findUnescaped(">", index + 1)
    if (end < 0) {
        return null
    }

    val body = substring(index + 1, end).trim()
    if (body.isBlank() || body.any { it.isWhitespace() }) {
        return null
    }

    val target = when {
        SchemeRegex.matches(body) -> body
        EmailAddressRegex.matches(body) -> "mailto:$body"
        else -> return null
    }

    return InlineLink(
        label = body,
        target = target,
        endIndexExclusive = end + 1,
    )
}

private fun String.delimiterAt(index: Int): InlineDelimiter? =
    InlineDelimiters.firstOrNull { delimiter ->
        startsWith(delimiter.marker, startIndex = index) &&
            !isEscaped(index)
    }?.let { delimiter ->
        if ((delimiter.marker == "*" || delimiter.marker == "_") &&
            isInsideWordDelimiter(index, delimiter.marker.first())
        ) {
            null
        } else {
            delimiter
        }
    }

private fun String.htmlStyleTagAt(index: Int): InlineHtmlStyleTag? {
    if (this[index] != '<') {
        return null
    }

    InlineHtmlStyleTags.forEach { (tag, style) ->
        if (!regionMatches(index, "<$tag", 0, tag.length + 1, ignoreCase = true)) {
            return@forEach
        }

        val afterName = getOrNull(index + tag.length + 1)
        if (afterName != '>' && afterName?.isWhitespace() != true) {
            return@forEach
        }

        val openingEnd = indexOf('>', startIndex = index + tag.length + 1)
        if (openingEnd < 0) {
            return@forEach
        }

        val closeStart = indexOfClosingHtmlTag(tag, openingEnd + 1)
        if (closeStart < 0) {
            return@forEach
        }

        val closeEnd = closeStart + tag.length + 3
        return InlineHtmlStyleTag(
            body = substring(openingEnd + 1, closeStart),
            style = style,
            endIndexExclusive = closeEnd,
        )
    }

    return null
}

private fun String.indexOfClosingHtmlTag(
    tag: String,
    startIndex: Int,
): Int {
    val close = "</$tag>"
    var cursor = startIndex
    while (cursor <= length - close.length) {
        if (regionMatches(cursor, close, 0, close.length, ignoreCase = true)) {
            return cursor
        }
        cursor += 1
    }
    return -1
}

private fun String.findUnescaped(needle: String, startIndex: Int): Int {
    var cursor = startIndex
    while (cursor <= length - needle.length) {
        if (startsWith(needle, cursor) && !isEscaped(cursor)) {
            return cursor
        }
        cursor += 1
    }
    return -1
}

private fun String.findMarkdownLinkTargetEnd(startIndex: Int): Int {
    var cursor = startIndex
    var nestedParentheses = 0
    while (cursor < length) {
        when {
            this[cursor] == '(' && !isEscaped(cursor) -> nestedParentheses += 1
            this[cursor] == ')' && !isEscaped(cursor) && nestedParentheses == 0 -> return cursor
            this[cursor] == ')' && !isEscaped(cursor) -> nestedParentheses -= 1
        }
        cursor += 1
    }
    return -1
}

private fun String.isEscaped(index: Int): Boolean {
    var slashCount = 0
    var cursor = index - 1
    while (cursor >= 0 && this[cursor] == '\\') {
        slashCount += 1
        cursor -= 1
    }
    return slashCount % 2 == 1
}

private fun String.isInsideWordDelimiter(index: Int, marker: Char): Boolean {
    val before = getOrNull(index - 1)
    val after = getOrNull(index + 1)
    return marker == '_' &&
        before?.isLetterOrDigit() == true &&
        after?.isLetterOrDigit() == true
}
