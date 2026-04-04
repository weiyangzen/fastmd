import Foundation
import Testing
@testable import FastMD

private func repoRootURL() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

private func loadFixture(at relativePath: String) throws -> String {
    let fixtureURL = repoRootURL().appendingPathComponent(relativePath)
    return try String(contentsOf: fixtureURL, encoding: .utf8)
}

private func normalizedFixtureText(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\r\n", with: "\n")
        .trimmingCharacters(in: .newlines)
}

@Test
func markdownRendererEmbedsPreviewChromeAndFeatureScripts() async throws {
    let markdown = """
    # Title

    Some `inline` code.

    ```swift
    print("hi")
    ```
    """

    let html = MarkdownRenderer.renderHTML(from: markdown, title: "Test")

    #expect(html.contains("FastMD Preview"))
    #expect(html.contains("id=\"width-label\""))
    #expect(html.contains("←/→ 宽度 · Tab 明暗"))
    #expect(html.contains("window.FastMD"))
    #expect(!html.contains("cdn.jsdelivr.net"))
    #expect(html.contains("window.markdownit"))
    #expect(html.contains("window.mermaid"))
    #expect(html.contains("window.renderMathInElement"))
    #expect(html.contains("hljs"))
}

@Test
func markdownFixtureIsSerializedIntoPreviewPayload() throws {
    let markdown = try loadFixture(at: "Tests/Fixtures/Markdown/basic.md")
    let rendered = MarkdownRenderer.renderHTML(from: markdown, title: "basic.md")

    #expect(rendered.contains("\"title\":\"basic.md\""))
    #expect(rendered.contains("FastMD Smoke Fixture"))
    #expect(rendered.contains("inline code"))
    #expect(rendered.contains("print(\\\"FastMD\\\")"))
}

@Test
func markdownRendererIncludesRichFixtureCapabilities() throws {
    let markdown = try loadFixture(at: "Tests/Fixtures/Markdown/rich-preview.md")
    let rendered = MarkdownRenderer.renderHTML(from: markdown, title: "rich-preview.md", selectedWidthTierIndex: 3)

    #expect(rendered.contains("\"selectedWidthTierIndex\":3"))
    #expect(rendered.contains("sequenceDiagram"))
    #expect(rendered.contains("$$\\n\\\\nabla \\\\cdot \\\\vec{E}"))
    #expect(rendered.contains("<details open>"))
    #expect(rendered.contains("Double-clicked block returns to raw Markdown."))
}

@Test
func markdownRendererPreservesCJKFixtureText() throws {
    let markdown = try loadFixture(at: "Tests/Fixtures/Markdown/cjk.md")
    let rendered = MarkdownRenderer.renderHTML(from: markdown, title: "cjk.md")

    #expect(rendered.contains("中文预览"))
    #expect(rendered.contains("UTF-8 Markdown 内容"))
    #expect(rendered.contains("\"widthTiers\":[560,960,1440,1920]"))
}
