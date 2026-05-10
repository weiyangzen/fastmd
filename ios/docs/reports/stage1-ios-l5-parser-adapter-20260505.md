# Stage 1 iOS L5 Parser Adapter Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L5 rich Markdown rendering batch after the completed L1 fixture matrix, L2 core contracts, and L4 iOS document-entry evidence. Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l5-parser-adapter-20260505.md`

## Implementation Notes

- Added native Swift `MarkdownParserAdapter` as the initial structured Markdown parser adapter for iOS Stage 1.
- The adapter converts Markdown source into `MarkdownRenderDocument` and `MarkdownRenderBlock` values with stable block IDs, source byte ranges, source line ranges, ordinals, and short text previews.
- The parser currently classifies top-level block structure for headings, paragraphs, blockquotes, unordered lists, ordered lists, task lists, tables, fenced code blocks, Mermaid/math rich fallback blocks, images, horizontal rules, footnotes, and generic HTML fallback blocks.
- Source byte counts are computed from UTF-8, and line splitting handles LF and CRLF while keeping block ranges deterministic.
- Rich Markdown cases that need future renderer work, such as Mermaid and math, are routed to `.richFallback` rather than a web runtime.
- HTML, video, script, iframe, and image-like HTML starts are routed to `.htmlFallback` for later safe native fallback rendering.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 28 tests with 0 failures. New tests `testMarkdownParserAdapterBuildsRenderBlocksWithSourceRanges` and `testMarkdownParserAdapterClassifiesCanonicalRichFixtureSurface` passed. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available iOS simulators include `Stage1 iPhone 15 Pro`, iPhone 16 family simulators, iPads, and iPhone SE, but no `iPhone 12`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L5: `Implement structured Markdown parser adapter.`
- L5: `Preserve source range for every rendered block.`

Evidence:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l5-parser-adapter-20260505.md`
- `swift test` passed with parser adapter coverage against both a focused source sample and the canonical `ios/Tests/Fixtures/Markdown/rich-preview.md` fixture.

Keep open:

- L5 native UI rendering checklist items such as actual heading, paragraph, inline style, list, table, code, image, footnote, and HTML fallback rendering.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so the mandatory iPhone 12 build/test gates cannot run in this environment.
