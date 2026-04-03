import Testing
@testable import FastMD

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
