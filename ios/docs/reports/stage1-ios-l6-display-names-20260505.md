# Stage 1 iOS L6 Display Names Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L6 reader UX batch after the existing iOS reader, font/theme, and search evidence.
Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSReaderScreen.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l6-display-names-20260505.md`

## Implementation Notes

- Added native `IOSDisplayNamePolicy` for reader document names and recent-document names.
- The policy trims whitespace, collapses multiline/tabbed names, reduces path-like strings to the leaf filename, and falls back to `Untitled Markdown` when no usable display name exists.
- Very long names are capped to a bounded display length while preserving short filename extensions such as `.md` and `.markdown`.
- Unicode document names remain readable, including CJK, Japanese, Korean, and emoji names.
- Wired the policy into `IOSReaderScreenState`, `IOSRecentDocumentSummary`, and the SwiftUI reader display-name helper so launcher, recent, loading/rendering, ready, read-only, search, and error states share the same graceful naming behavior.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, or network renderer was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 58 tests with 0 failures. New tests covered missing names, whitespace-only names, path-like names, long names with preserved extensions, CJK/Japanese/Korean/emoji names, recent-document summaries, and ready-state titles. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for tracked iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available iOS simulator destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, and iPads, but no `iPhone 12`. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' test` from `ios/` | PASS | Ran on available `Stage1 iPhone 15 Pro` simulator, OS 18.6. Executed 58 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |

## Checklist Evidence

Supervisor can mark complete:

- L6: `Ensure long filenames, CJK names, emoji names, and missing display names render gracefully.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSReaderScreen.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l6-display-names-20260505.md`
- `swift test` passed.
- Available-simulator `xcodebuild test` passed.

Keep open:

- L6: `Implement Back/navigation behavior for search, block edit, source edit, reader, and recent documents.`
- L6: `Preserve active document, scroll, font tier, search query, and dirty edit buffer through rotation.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 build/test gates remain blocked in this environment.
