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
func markdownRendererRendersHeadingsAndCode() async throws {
    let markdown = """
    # Title

    Some `inline` code.

    ```swift
    print("hi")
    ```
    """

    let html = MarkdownRenderer.renderHTML(from: markdown, title: "Test")

    #expect(html.contains("<h1>Title</h1>"))
    #expect(html.contains("<code>inline</code>"))
    #expect(html.contains("<pre><code>print(&quot;hi&quot;)</code></pre>"))
}

@Test
func markdownFixtureRendersExpectedBasicHTML() throws {
    let markdown = try loadFixture(at: "Tests/Fixtures/Markdown/basic.md")
    let expected = try loadFixture(at: "Tests/Fixtures/RenderedHTML/basic.html")

    let rendered = MarkdownRenderer.renderHTML(from: markdown, title: "basic.md")

    #expect(normalizedFixtureText(rendered) == normalizedFixtureText(expected))
}

@Test
func markdownFixtureRendersExpectedCJKHTML() throws {
    let markdown = try loadFixture(at: "Tests/Fixtures/Markdown/cjk.md")
    let expected = try loadFixture(at: "Tests/Fixtures/RenderedHTML/cjk.html")

    let rendered = MarkdownRenderer.renderHTML(from: markdown, title: "cjk.md")

    #expect(normalizedFixtureText(rendered) == normalizedFixtureText(expected))
}
