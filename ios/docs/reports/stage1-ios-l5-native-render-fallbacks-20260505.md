# Stage 1 iOS L5 Native Fallback Render Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L5 native Markdown rendering batch after parser, inline, and block payload work. Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l5-native-render-fallbacks-20260505.md`

## Implementation Notes

- Added typed native presentation payloads for rich fallback cards, image placeholders, horizontal rules, footnotes, and sanitized HTML fallback cards.
- Mermaid code fences now render as safe native diagram-source cards. No WebKit, JavaScript, CDN, network rendering, remote runtime, or vendored renderer dependency was introduced.
- Block math now renders as a readable safe native math card. Inline math now remains readable through native inline runs tagged with `.inlineMath`.
- Local Markdown image blocks now emit native image payloads that require bounded local decode before UI display.
- Remote Markdown image blocks now emit manual-open placeholders and do not load automatically.
- Video HTML renders as a safe native media placeholder.
- Details/summary HTML renders as a native disclosure fallback with extracted summary text.
- Generic HTML blocks render as sanitized text/card fallbacks that strip tags and remove blocked `script`/`iframe` content.
- Escaped marker characters are preserved in native inline text and do not trigger styling or link parsing.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 41 tests with 0 failures. New tests covered Mermaid safe cards, block math cards, inline math fallback runs, local image bounded-decode payloads, remote image manual-open placeholders, horizontal rules, footnotes, escaped marker preservation, video placeholders, details disclosure fallback, and generic sanitized HTML fallback. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available iOS simulator destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family simulators, iPhone 17 family simulators, iPhone Air, iPhone 16e/17e, and iPhone SE, but no `iPhone 12`. |

## Checklist Evidence

Supervisor can mark complete:

- L5: `Render Mermaid blocks as safe diagram-source cards.`
- L5: `Render inline and block math as readable safe fallback.`
- L5: `Render local images with bounded decode.`
- L5: `Render remote images as placeholders with manual open action.`
- L5: `Render video HTML as safe media placeholder.`
- L5: `Render horizontal rules.`
- L5: `Render footnotes.`
- L5: `Render details/summary HTML as native disclosure fallback.`
- L5: `Render generic HTML blocks as sanitized text/card fallback.`
- L5: `Preserve escaped marker characters.`

Evidence:

- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l5-native-render-fallbacks-20260505.md`
- `swift test` passed.

Keep open:

- L5: `Use vendored local JS renderer assets for Mermaid/math only if native fallback is insufficient.`
- L5: `Ensure JS renderer assets are packaged locally and never loaded from CDN.`
- L5: `Block network and external navigation from any local render surface.`
- L6: Visual SwiftUI reader integration for the native presentation payloads.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 build/test gates cannot run in this environment yet.
