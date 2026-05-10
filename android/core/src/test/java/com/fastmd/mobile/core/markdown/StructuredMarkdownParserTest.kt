package com.fastmd.mobile.core.markdown

import com.fastmd.mobile.core.render.MarkdownBlockKind
import com.fastmd.mobile.core.render.MarkdownInlineStyle
import com.fastmd.mobile.core.render.MarkdownLinkDecision
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class StructuredMarkdownParserTest {
    @Test
    fun parsesHeadingsParagraphsAndHorizontalRulesWithSourceRanges() {
        val source = "# Title\n\nBody line one\nBody line two\n\n---\n"

        val model = StructuredMarkdownParser.parse(source)

        assertEquals(
            listOf(
                MarkdownBlockKind.Heading,
                MarkdownBlockKind.Paragraph,
                MarkdownBlockKind.HorizontalRule,
            ),
            model.blocks.map { it.kind },
        )
        assertEquals("Title", model.blocks[0].plainText)
        assertEquals("1", model.blocks[0].attributes["level"])
        assertEquals(0, model.blocks[0].sourceRange.startOffset)
        assertEquals(8, model.blocks[0].sourceRange.endOffsetExclusive)
        assertEquals(1, model.blocks[0].sourceRange.startLine)
        assertEquals(1, model.blocks[0].sourceRange.endLineInclusive)
        assertEquals("Body line one\nBody line two", model.blocks[1].plainText)
        assertEquals(3, model.blocks[1].sourceRange.startLine)
        assertEquals(4, model.blocks[1].sourceRange.endLineInclusive)
        assertEquals(listOf(0, 1, 2), model.blocks.map { it.ordinal })
    }

    @Test
    fun emitsStableUniqueIdsAcrossParses() {
        val source = "## Same\n\n## Same\n"

        val first = StructuredMarkdownParser.parse(source)
        val second = StructuredMarkdownParser.parse(source)

        assertEquals(first.blocks.map { it.id }, second.blocks.map { it.id })
        assertNotEquals(first.blocks[0].id, first.blocks[1].id)
    }

    @Test
    fun parsesNativeBlockKindsNeededByEarlyRichMarkdownRenderer() {
        val source = """
            |```kotlin
            |val value = 1
            |```
            |
            |```mermaid
            |graph TD
            |```
            |
            |> Quote
            |
            |- [x] Task
            |- Item
            |
            |1. Ordered
            |
            || Name | Value |
            || --- | --- |
            || A | B |
            |
            |${'$'}${'$'}
            |E = mc^2
            |${'$'}${'$'}
            |
            |![Alt](image.png)
            |
            |[^one]: Footnote text
            |
            |<details>
            |<summary>More</summary>
            |</details>
            |
            |<video src="movie.mp4"></video>
        """.trimMargin()

        val model = StructuredMarkdownParser.parse(source)

        assertEquals(
            listOf(
                MarkdownBlockKind.CodeFence,
                MarkdownBlockKind.Mermaid,
                MarkdownBlockKind.Blockquote,
                MarkdownBlockKind.TaskList,
                MarkdownBlockKind.OrderedList,
                MarkdownBlockKind.Table,
                MarkdownBlockKind.MathBlock,
                MarkdownBlockKind.Image,
                MarkdownBlockKind.Footnote,
                MarkdownBlockKind.Details,
                MarkdownBlockKind.VideoHtml,
            ),
            model.blocks.map { it.kind },
        )
        assertEquals("kotlin", model.blocks[0].attributes["language"])
        assertEquals("val value = 1", model.blocks[0].plainText)
        assertEquals("E = mc^2", model.blocks[6].plainText)
        assertEquals("Alt", model.blocks[7].attributes["alt"])
        assertEquals("image.png", model.blocks[7].attributes["src"])
        assertEquals("one", model.blocks[8].attributes["label"])
        assertTrue(model.blocks.all { it.sourceRange.startOffset < it.sourceRange.endOffsetExclusive })
    }

    @Test
    fun parsesMathImagesFootnotesAndSafeHtmlFallbackAttributes() {
        val source = """
            |Inline math ${'$'}E = mc^2${'$'} remains readable.
            |
            |${'$'}${'$'}
            |\int_0^1 x dx
            |${'$'}${'$'}
            |
            |![Remote](https://example.com/tracker.png)
            |
            |<video controls>
            |  <source src="file:///tmp/movie.mp4" type="video/mp4">
            |</video>
            |
            |<details open>
            |<summary>More</summary>
            |<p>Safe text</p>
            |</details>
            |
            |<script>alert("no")</script>
        """.trimMargin()

        val model = StructuredMarkdownParser.parse(source)

        assertEquals(
            listOf(
                MarkdownBlockKind.Paragraph,
                MarkdownBlockKind.MathBlock,
                MarkdownBlockKind.Image,
                MarkdownBlockKind.VideoHtml,
                MarkdownBlockKind.Details,
                MarkdownBlockKind.HtmlFallback,
            ),
            model.blocks.map { it.kind },
        )
        assertSpan(model.blocks[0], "E = mc^2", MarkdownInlineStyle.Math)
        assertEquals("""\int_0^1 x dx""", model.blocks[1].plainText)
        assertEquals("remote", model.blocks[2].attributes["sourceKind"])
        assertEquals("local", model.blocks[3].attributes["sourceKind"])
        assertEquals("More", model.blocks[4].attributes["summary"])
        assertEquals("true", model.blocks[4].attributes["open"])
        assertEquals("HTML block omitted", model.blocks[5].plainText)
    }

    @Test
    fun carriesDocumentBaseForLocalImageResolutionWithoutFetchingRemoteImages() {
        val source = """
            |![Local diagram](./images/local-diagram.png)
            |
            |![Remote](https://example.com/tracker.png)
        """.trimMargin()

        val model = StructuredMarkdownParser.parse(
            source = source,
            documentBaseUri = "file:///storage/emulated/0/Notes/local-image.md",
        )

        assertEquals(listOf(MarkdownBlockKind.Image, MarkdownBlockKind.Image), model.blocks.map { it.kind })
        assertEquals("./images/local-diagram.png", model.blocks[0].attributes["src"])
        assertEquals("local", model.blocks[0].attributes["sourceKind"])
        assertEquals(
            "file:///storage/emulated/0/Notes/local-image.md",
            model.blocks[0].attributes["documentBaseUri"],
        )
        assertEquals("remote", model.blocks[1].attributes["sourceKind"])
    }

    @Test
    fun preservesBlockSourceTextNeededByNativeBlockRenderers() {
        val source = """
            |> Outer quote
            |> > Nested quote
            |
            |- **Bold** item
            |  - Child item
            |- [x] Done
            |
            || Name | Value |
            || --- | --- |
            || A | `B` |
        """.trimMargin()

        val model = StructuredMarkdownParser.parse(source)

        assertEquals(
            listOf(
                MarkdownBlockKind.Blockquote,
                MarkdownBlockKind.TaskList,
                MarkdownBlockKind.Table,
            ),
            model.blocks.map { it.kind },
        )
        assertEquals("Outer quote\n> Nested quote", model.blocks[0].plainText)
        assertEquals("- Bold item\n  - Child item\n- [x] Done", model.blocks[1].plainText)
        assertSpan(model.blocks[1], "Bold", MarkdownInlineStyle.Bold)
        assertEquals("| Name | Value |\n| --- | --- |\n| A | `B` |", model.blocks[2].plainText)
    }

    @Test
    fun preservesCrLfOffsetsInSourceRanges() {
        val source = "# Title\r\n\r\nParagraph\r\n"

        val model = StructuredMarkdownParser.parse(source)

        assertEquals(0, model.blocks[0].sourceRange.startOffset)
        assertEquals(9, model.blocks[0].sourceRange.endOffsetExclusive)
        assertEquals(11, model.blocks[1].sourceRange.startOffset)
        assertEquals(22, model.blocks[1].sourceRange.endOffsetExclusive)
    }

    @Test
    fun parserContractKeepsStableOrderedRangesForRichBlockSurface() {
        val source = """
            |# Title
            |
            |Paragraph with **bold** text.
            |
            |> Quote
            |
            |- Item
            |
            |1. Ordered
            |
            |- [ ] Task
            |
            || Name | Value |
            || --- | --- |
            || A | B |
            |
            |```kotlin
            |val answer = 42
            |```
            |
            |```mermaid
            |graph TD
            |```
            |
            |${'$'}${'$'}
            |E = mc^2
            |${'$'}${'$'}
            |
            |![Alt](./image.png)
            |
            |<video src="movie.mp4"></video>
            |
            |---
            |
            |[^one]: Footnote
            |
            |<details>
            |<summary>More</summary>
            |Body
            |</details>
            |
            |<aside>Generic HTML</aside>
        """.trimMargin()

        val first = StructuredMarkdownParser.parse(source)
        val second = StructuredMarkdownParser.parse(source)

        assertEquals(
            listOf(
                MarkdownBlockKind.Heading,
                MarkdownBlockKind.Paragraph,
                MarkdownBlockKind.Blockquote,
                MarkdownBlockKind.UnorderedList,
                MarkdownBlockKind.OrderedList,
                MarkdownBlockKind.TaskList,
                MarkdownBlockKind.Table,
                MarkdownBlockKind.CodeFence,
                MarkdownBlockKind.Mermaid,
                MarkdownBlockKind.MathBlock,
                MarkdownBlockKind.Image,
                MarkdownBlockKind.VideoHtml,
                MarkdownBlockKind.HorizontalRule,
                MarkdownBlockKind.Footnote,
                MarkdownBlockKind.Details,
                MarkdownBlockKind.HtmlFallback,
            ),
            first.blocks.map { it.kind },
        )
        assertEquals(first.blocks.map { it.id }, second.blocks.map { it.id })
        assertEquals(first.blocks.indices.toList(), first.blocks.map { it.ordinal })
        assertEquals(first.blocks.map { it.id }.toSet().size, first.blocks.size)
        assertTrue(first.sourceRevision > 0L)

        first.blocks.zipWithNext().forEach { (previous, next) ->
            assertTrue(previous.sourceRange.endOffsetExclusive <= next.sourceRange.startOffset)
            assertTrue(previous.sourceRange.endLineInclusive <= next.sourceRange.startLine)
        }
        first.blocks.forEach { block ->
            val range = block.sourceRange

            assertTrue(range.startOffset < range.endOffsetExclusive)
            assertTrue(range.endOffsetExclusive <= source.length)
            assertTrue(source.substring(range.startOffset, range.endOffsetExclusive).isNotBlank())
        }
    }

    @Test
    fun sourceRangesMapBackToExactEditableSourceSlices() {
        val source = "# Title\r\n\r\nParagraph **one**\r\ncontinues here\r\n\r\n```kotlin\r\nval x = 1\r\n```\r\n\r\n> Quote\r\n> continued\r\n"

        val model = StructuredMarkdownParser.parse(source)

        assertEquals(
            listOf(
                MarkdownBlockKind.Heading,
                MarkdownBlockKind.Paragraph,
                MarkdownBlockKind.CodeFence,
                MarkdownBlockKind.Blockquote,
            ),
            model.blocks.map { it.kind },
        )
        assertEquals("# Title\r\n", source.sliceForBlock(model.blocks[0]))
        assertEquals("Paragraph **one**\r\ncontinues here\r\n", source.sliceForBlock(model.blocks[1]))
        assertEquals("```kotlin\r\nval x = 1\r\n```\r\n", source.sliceForBlock(model.blocks[2]))
        assertEquals("> Quote\r\n> continued\r\n", source.sliceForBlock(model.blocks[3]))
    }

    @Test
    fun parsesInlineEmphasisCodeMarkSubscriptAndSuperscriptAsNativeSpans() {
        val source =
            "This is **bold**, *italic*, ***both***, ~~gone~~, `code`, ==mark==, " +
                "<mark>tag mark</mark>, H~2~O, water H<sub>2</sub>O, x^2^, and y<sup>3</sup>."

        val block = StructuredMarkdownParser.parse(source).blocks.single()

        assertEquals(
            "This is bold, italic, both, gone, code, mark, tag mark, H2O, water H2O, x2, and y3.",
            block.plainText,
        )
        assertSpan(block, "bold", MarkdownInlineStyle.Bold)
        assertSpan(block, "italic", MarkdownInlineStyle.Italic)
        assertSpan(block, "both", MarkdownInlineStyle.Bold, MarkdownInlineStyle.Italic)
        assertSpan(block, "gone", MarkdownInlineStyle.Strikethrough)
        assertSpan(block, "code", MarkdownInlineStyle.InlineCode)
        assertSpan(block, "mark", MarkdownInlineStyle.Highlight)
        assertSpan(block, "tag mark", MarkdownInlineStyle.Highlight)
        assertSpanAt(block, block.plainText.indexOf("H2O") + 1, "2", MarkdownInlineStyle.Subscript)
        assertSpanAt(block, block.plainText.indexOf("water H2O") + "water H".length, "2", MarkdownInlineStyle.Subscript)
        assertSpanAt(block, block.plainText.indexOf("x2") + 1, "2", MarkdownInlineStyle.Superscript)
        assertSpanAt(block, block.plainText.indexOf("y3") + 1, "3", MarkdownInlineStyle.Superscript)
    }

    @Test
    fun parsesMarkdownAutolinksAndEmailLinksThroughSafePolicy() {
        val source = "[site](https://example.com), <http://example.com>, <dev@example.com>, [bad](javascript:alert(1))"

        val block = StructuredMarkdownParser.parse(source).blocks.single()

        assertEquals("site, http://example.com, dev@example.com, bad", block.plainText)
        assertEquals(
            listOf(
                "https://example.com" to MarkdownLinkDecision.Confirm,
                "http://example.com" to MarkdownLinkDecision.Confirm,
                "mailto:dev@example.com" to MarkdownLinkDecision.Confirm,
                "javascript:alert(1)" to MarkdownLinkDecision.Blocked,
            ),
            block.inlineSpans.filter { it.linkTarget != null }.map { it.linkTarget to it.linkDecision },
        )
    }

    @Test
    fun preservesEscapedInlineMarkersAsLiteralText() {
        val source = """\**not bold\** and \`not code\`"""

        val block = StructuredMarkdownParser.parse(source).blocks.single()

        assertEquals("**not bold** and `not code`", block.plainText)
        assertTrue(block.inlineSpans.isEmpty())
    }

    private fun assertSpan(
        block: com.fastmd.mobile.core.render.MarkdownRenderBlock,
        text: String,
        vararg expectedStyles: MarkdownInlineStyle,
    ) {
        val start = block.plainText.indexOf(text)
        assertTrue("Expected text '$text' in '${block.plainText}'.", start >= 0)
        val span = block.inlineSpans.firstOrNull {
            it.startOffset == start &&
                it.endOffsetExclusive == start + text.length &&
                it.styles.containsAll(expectedStyles.toSet())
        }
        assertTrue("Expected span for '$text' with ${expectedStyles.toList()}.", span != null)
    }

    private fun assertSpanAt(
        block: com.fastmd.mobile.core.render.MarkdownRenderBlock,
        start: Int,
        text: String,
        vararg expectedStyles: MarkdownInlineStyle,
    ) {
        val span = block.inlineSpans.firstOrNull {
            it.startOffset == start &&
                it.endOffsetExclusive == start + text.length &&
                it.styles.containsAll(expectedStyles.toSet())
        }
        assertTrue("Expected span for '$text' at $start with ${expectedStyles.toList()}.", span != null)
    }

    private fun String.sliceForBlock(block: com.fastmd.mobile.core.render.MarkdownRenderBlock): String =
        substring(block.sourceRange.startOffset, block.sourceRange.endOffsetExclusive)
}
