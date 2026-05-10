# Stage 1 iOS L6 Navigation And Restoration Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L6 reader UX batch after the existing iOS fixture, core contract, document entry, native render, font/theme, search, and display-name evidence.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSReaderNavigation.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l6-navigation-restoration-20260505.md`

## Implementation Notes

- Added `IOSReaderNavigationEngine` with native Swift back-action decisions for search, block editor, source editor, reader, recent documents, loading/rendering, saving, empty, error, and permission-lost states.
- Back navigation now closes search before leaving the reader, closes clean block/source editors, requests discard confirmation for dirty block/source editors, and returns reader/error/permission-lost states to the recent-documents surface.
- Added `IOSReaderEditSession` to carry source or block edit mode, original/current buffers, source range/block identity for block edits, return reader state, and dirty-state derivation.
- Added `IOSReaderScrollPosition` and `IOSReaderRuntimeRestorationSnapshot` for in-memory rotation preservation of active document, rendered blocks, scroll anchor, selected font tier, theme, search query, and dirty edit buffer.
- The runtime restoration snapshot explicitly reports `storesDocumentContentPersistently = false`; it is an in-memory rotation contract and is not a recovery-draft persistence claim.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, or network renderer was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 62 tests with 0 failures. New tests covered search-first back behavior, clean/dirty block and source editor back handling, reader-to-recent navigation, and rotation snapshot preservation of active document, rendered blocks, scroll, font tier, theme, search query, and dirty edit buffer. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. Available iOS simulator destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, and iPads, but no `iPhone 12`. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' test` from `ios/` | PASS | Ran on available `Stage1 iPhone 15 Pro` simulator, iOS 18.6. Executed 62 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |

## Checklist Evidence

Supervisor can mark complete:

- L6: `Implement Back/navigation behavior for search, block edit, source edit, reader, and recent documents.`
- L6: `Preserve active document, scroll, font tier, search query, and dirty edit buffer through rotation.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSReaderNavigation.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l6-navigation-restoration-20260505.md`
- `swift test` passed.
- Available-simulator `xcodebuild test` passed.

Keep open:

- L7: Full source editor implementation, block source editor implementation, save integrity, app-background dirty buffer preservation, and process-death recovery are not claimed by this L6 navigation/restoration batch.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 build/test gates remain blocked in this environment.
