# Stage 1 iOS L9 Off-Main Work And Lazy Rendering Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L9 performance batch after existing L6/L7 reader, editor, and save-integrity evidence.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSDocumentEntry.swift`
- `ios/Sources/FastMDMobileCore/IOSReaderScreen.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l9-off-main-lazy-rendering-20260505.md`

## Implementation Notes

- Added `IOSOffMainActorExecutionMetadata` and `IOSOffMainActorWorkResult` as testable native Swift contracts for work scheduled away from the main actor.
- Added `IOSDocumentFileIO.loadDocumentOffMainActor(...)` for Markdown document reads through a detached user-initiated task.
- Added `IOSDocumentFileIO.saveDocumentOffMainActor(...)` for save-integrity writes through a detached user-initiated task while preserving the existing security-scoped save path.
- Added `IOSReaderScreenEngine.renderDocumentOffMainActor(...)` so Markdown parse and native render work are scheduled away from the main actor before the ready state is produced.
- Added `IOSReaderSearchEngine.searchOffMainActor(...)` and `IOSReaderScreenEngine.searchingStateOffMainActor(...)` so document search can be executed away from the main actor while preserving the existing search state contract.
- Added `IOSReaderLazyRenderingPolicy` to make the existing SwiftUI `LazyVStack` reader behavior testable as a Stage 1 lazy block rendering contract with stable `MarkdownBlockID` identity and table/code block-local horizontal overflow.
- Used `pthread_main_np()` diagnostics instead of `Thread.isMainThread` inside async contexts to avoid Swift 6 migration warnings.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, or network renderer was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 81 tests with 0 failures. New tests covered off-main document load, off-main document save, off-main parse/render, off-main search, and the lazy `LazyVStack` rendering policy contract. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available iOS simulator destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, and iPads, but no iPhone 12. |

## Checklist Evidence

Supervisor can mark complete:

- L9: `Keep iOS file IO off the main actor.`
- L9: `Keep iOS parse/search work off the main actor.`
- L9: `Use lazy block rendering on iOS.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSDocumentEntry.swift`
- `ios/Sources/FastMDMobileCore/IOSReaderScreen.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l9-off-main-lazy-rendering-20260505.md`
- `swift test` passed.

Keep open:

- L9: UIKit/TextKit editor fallback decision, ImageIO local-image downsampling, stale bookmark/security audit items, ATS/privacy/background-mode audits, and WKWebView-specific gate if a future local renderer is introduced.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 simulator gates remain blocked in this environment.
