import Foundation
import AppKit
import Testing
@testable import FastMD

private func repoRootURL() -> URL {
    var candidate = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()

    while candidate.path != "/" {
        let gitURL = candidate.appendingPathComponent(".git")
        if FileManager.default.fileExists(atPath: gitURL.path) {
            return candidate
        }
        candidate.deleteLastPathComponent()
    }

    fatalError("Could not locate repository root from \(#filePath)")
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

private func makeTempMarkdownURL(
    fileName: String = "preview.md",
    contents: String
) throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let fileURL = directory.appendingPathComponent(fileName)
    try contents.write(to: fileURL, atomically: true, encoding: .utf8)
    return fileURL
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
    #expect(html.contains("← 1/4 →"))
    #expect(html.contains("Tab"))
    #expect(!html.contains("PgUp/PgDn"))
    #expect(!html.contains("(⇧+) Space"))
    #expect(html.contains("window.FastMD"))
    #expect(!html.contains("cdn.jsdelivr.net"))
    #expect(html.contains("window.markdownit"))
    #expect(html.contains("window.mermaid"))
    #expect(html.contains("window.renderMathInElement"))
    #expect(html.contains("hljs"))
    #expect(html.contains("is-performance-critical"))
    #expect(html.contains("widthTransition"))
    #expect(html.contains("pageTransition"))
}

@Test
func markdownRendererInjectsBaseHrefForLocalMediaResolution() throws {
    let baseURL = URL(fileURLWithPath: "/Users/wangweiyang/GitHub/fastmd/Tests/Fixtures/Markdown", isDirectory: true)
    let html = MarkdownRenderer.renderHTML(from: "<video></video>", title: "media.md", contentBaseURL: baseURL)

    #expect(html.contains(#"<base href="file:///Users/wangweiyang/GitHub/fastmd/Tests/Fixtures/Markdown/">"#))
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
    #expect(rendered.contains("<video"))
    #expect(rendered.contains("<source src="))
    #expect(rendered.contains("file:///Users/wangweiyang/Downloads/%E8%BD%AC%E8%BA%AB.mp4"))
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

@Test
func finderSelectionSnapshotBlocksPreviewTriggersWhileFinderEditsText() {
    let blocked = FinderSelectionSnapshot(
        state: .markdown(url: URL(fileURLWithPath: "/tmp/rename-target.md")),
        finderPid: 42,
        isFinderEditingText: true,
        spaceTriggerEnabled: true,
        generation: 1
    )
    let allowed = FinderSelectionSnapshot(
        state: .markdown(url: URL(fileURLWithPath: "/tmp/rename-target.md")),
        finderPid: 42,
        isFinderEditingText: false,
        spaceTriggerEnabled: true,
        generation: 2
    )

    #expect(blocked.blocksPreviewTriggers)
    #expect(!allowed.blocksPreviewTriggers)
}

@Test
func warmedPreviewLoaderCapturesPreviewMetadataForWarmup() throws {
    let fileURL = try makeTempMarkdownURL(contents: "# Warmed\n\nBody")
    let snapshot = try WarmedPreviewLoader.load(
        fileURL: fileURL,
        selectedWidthTierIndex: 3,
        backgroundMode: .black
    )

    #expect(snapshot.fileURL.standardizedFileURL == fileURL.standardizedFileURL)
    #expect(snapshot.title == "preview.md")
    #expect(snapshot.markdown == "# Warmed\n\nBody")
    #expect(snapshot.contentBaseURL == fileURL.deletingLastPathComponent())
}

@Test
func warmedPreviewCacheDropsSnapshotsAfterTheSourceFileChanges() throws {
    let fileURL = try makeTempMarkdownURL(contents: "# Warmed\n\nBody")
    let cache = WarmedPreviewCache()
    let initialSnapshot = try WarmedPreviewLoader.load(
        fileURL: fileURL,
        selectedWidthTierIndex: 1,
        backgroundMode: .white
    )
    cache.store(initialSnapshot)

    let cachedBeforeChange = cache.snapshot(
        for: fileURL,
        selectedWidthTierIndex: 1,
        backgroundMode: .white
    )
    #expect(cachedBeforeChange?.markdown == "# Warmed\n\nBody")

    try "# Changed\n\nBody\n\nAgain".write(to: fileURL, atomically: true, encoding: .utf8)

    let cachedAfterChange = cache.snapshot(
        for: fileURL,
        selectedWidthTierIndex: 1,
        backgroundMode: .white
    )
    #expect(cachedAfterChange == nil)
}

@Test
func previewPanelTopChromeDragRegionTracksTheToolbarBand() {
    let windowSize = NSSize(width: 960, height: 720)
    let region = PreviewPanelController.topChromeDragRegion(windowSize: windowSize)

    #expect(region.origin.x == 0)
    #expect(region.origin.y == 662)
    #expect(region.width == 960)
    #expect(region.height == 58)
    #expect(
        PreviewPanelController.isPointInTopChromeDragRegion(
            NSPoint(x: 120, y: 710),
            windowSize: windowSize
        )
    )
    #expect(
        !PreviewPanelController.isPointInTopChromeDragRegion(
            NSPoint(x: 120, y: 650),
            windowSize: windowSize
        )
    )
}

@Test
func previewPanelTopChromeDragRegionClampsForShortWindows() {
    let windowSize = NSSize(width: 320, height: 40)
    let region = PreviewPanelController.topChromeDragRegion(windowSize: windowSize)

    #expect(region.origin.y == 0)
    #expect(region.height == 40)
    #expect(
        PreviewPanelController.isPointInTopChromeDragRegion(
            NSPoint(x: 10, y: 5),
            windowSize: windowSize
        )
    )
}
