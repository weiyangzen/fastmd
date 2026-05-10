package com.fastmd.mobile.core.render

@JvmInline
value class MarkdownBlockId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "MarkdownBlockId cannot be blank." }
    }
}

data class SourceRange(
    val startOffset: Int,
    val endOffsetExclusive: Int,
    val startLine: Int,
    val endLineInclusive: Int,
) {
    init {
        require(startOffset >= 0) { "Source range start offset cannot be negative." }
        require(endOffsetExclusive >= startOffset) { "Source range end offset cannot precede start." }
        require(startLine >= 1) { "Source range start line is one-based." }
        require(endLineInclusive >= startLine) { "Source range end line cannot precede start line." }
    }
}

enum class MarkdownBlockKind {
    Heading,
    Paragraph,
    Blockquote,
    UnorderedList,
    OrderedList,
    TaskList,
    Table,
    CodeFence,
    Mermaid,
    MathBlock,
    Image,
    VideoHtml,
    HorizontalRule,
    Footnote,
    Details,
    HtmlFallback,
}

enum class MarkdownInlineStyle {
    Bold,
    Italic,
    Strikethrough,
    InlineCode,
    Highlight,
    Subscript,
    Superscript,
    Math,
}

enum class MarkdownLinkDecision {
    Allowed,
    Confirm,
    Blocked,
}

data class MarkdownInlineSpan(
    val startOffset: Int,
    val endOffsetExclusive: Int,
    val styles: Set<MarkdownInlineStyle> = emptySet(),
    val linkTarget: String? = null,
    val linkDecision: MarkdownLinkDecision? = null,
) {
    init {
        require(startOffset >= 0) { "Inline span start offset cannot be negative." }
        require(endOffsetExclusive >= startOffset) { "Inline span end offset cannot precede start." }
        require(styles.isNotEmpty() || linkTarget != null) {
            "Inline span must carry at least one style or link target."
        }
        require(linkTarget?.isNotBlank() != false) { "Inline span link target cannot be blank." }
        require((linkTarget == null) == (linkDecision == null)) {
            "Inline span link target and policy decision must be present together."
        }
    }
}

data class MarkdownRenderBlock(
    val id: MarkdownBlockId,
    val kind: MarkdownBlockKind,
    val sourceRange: SourceRange,
    val ordinal: Int,
    val plainText: String,
    val inlineSpans: List<MarkdownInlineSpan> = emptyList(),
    val attributes: Map<String, String> = emptyMap(),
) {
    init {
        require(ordinal >= 0) { "Block ordinal cannot be negative." }
        inlineSpans.forEach { span ->
            require(span.endOffsetExclusive <= plainText.length) {
                "Inline span range must stay inside rendered plain text."
            }
        }
    }
}

data class MarkdownRenderModel(
    val sourceRevision: Long,
    val blocks: List<MarkdownRenderBlock>,
) {
    init {
        require(sourceRevision >= 0L) { "Source revision cannot be negative." }
        require(blocks.map { it.id }.toSet().size == blocks.size) {
            "Render block ids must be stable and unique within a render model."
        }
        require(blocks.map { it.ordinal } == blocks.indices.toList()) {
            "Render block ordinals must be contiguous and match list order."
        }
    }
}
