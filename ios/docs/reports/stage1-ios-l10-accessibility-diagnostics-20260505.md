# Stage 1 iOS L10 Accessibility And Diagnostics Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L10 accessibility and diagnostics batch after existing L7 editing/save and L9 performance/security evidence.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAccessibilityDiagnostics.swift`
- `ios/Sources/FastMDMobileCore/IOSReaderPreferences.swift`
- `ios/Sources/FastMDMobileCore/IOSReaderScreen.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l10-accessibility-diagnostics-20260505.md`

## Implementation Notes

- Added `IOSReaderAccessibilityPolicy` with explicit labels for every current iOS icon-only control: open, search, edit source, font size, previous/next search result, clear search, copy code, source edit save/cancel, and block edit save/cancel.
- Added testable VoiceOver ordering metadata that keeps toolbar, search, rendered blocks, editor warnings, editor, progress, errors, and recent documents in the same order as the visual reader composition.
- Added search-result accessibility announcement strings for zero-result and selected-result states.
- Added dirty-edit warning audit metadata that marks unsaved editor warnings as alert surfaces.
- Updated the SwiftUI reader to consume the shared label policy for icon-only controls and expose search count live-update metadata through accessibility values.
- Added Dynamic Type contract fields to native Markdown typography metrics so all four iOS font tiers can be validated as Dynamic Type-composable rather than fixed-only point sizes.
- Added `IOSDiagnosticsBuilder` and `IOSDiagnosticsSnapshot` for local diagnostics reports that include parse, render, search, save, device class, renderer profile, file size bucket, and last error category while excluding document content, full paths, full URIs, query strings, and clipboard data.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 91 tests with 0 failures. New tests covered iOS icon-only control labels, VoiceOver visual-order matching, search-result announcements, dirty-edit accessible alerts, Dynamic Type composition across all four font tiers, and redacted local diagnostics snapshots. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. The requested iPhone 12 simulator is not installed. |
| `xcodebuild -scheme FastMDMobile -destination 'id=63DAFAF1-789A-4206-8B3C-6B87048AFDF1' test` from `ios/` | PASS | Ran on available `Stage1 iPhone 15 Pro` simulator, iOS 18.6. Executed 91 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |

## Checklist Evidence

Supervisor can mark complete:

- L10: `Add iOS accessibility labels for all icon-only controls.`
- L10: `Ensure VoiceOver reader order matches visual order.`
- L10: `Announce search result count changes accessibly.`
- L10: `Make dirty edit warnings accessible alerts.`
- L10: `Validate iOS Dynamic Type with all four font tiers.`
- L10: `Add local diagnostics report excluding document content, full path, full URI, query strings, and clipboard.`
- L10: `Include parse, render, search, save, device class, renderer profile, file size bucket, and last error category in diagnostics.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAccessibilityDiagnostics.swift`
- `ios/Sources/FastMDMobileCore/IOSReaderPreferences.swift`
- `ios/Sources/FastMDMobileCore/IOSReaderScreen.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l10-accessibility-diagnostics-20260505.md`
- `swift test` passed.
- Available-simulator `xcodebuild test` passed.

Keep open:

- L10 Android-owned accessibility/font-scale items.
- L11 automated golden/snapshot/layout/file-access/performance/memory/accessibility smoke gates not directly covered by this batch.
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 build/test gates remain blocked in this environment.
