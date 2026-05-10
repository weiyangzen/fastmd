# Stage 1 iOS L11 Native Fallback Report Rows - 2026-05-06 08:54 CST

## Scope

Ran one bounded iOS-only implementation batch against the earliest still-open iOS-owned checklist surface in the current snapshot:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

This batch did not edit `android/**`, shared `Docs/**`, `.cron/**`, renderer assets, entitlements, privacy manifests, background modes, or any web runtime surface.

## Implementation

Added `testIOSL11CurrentRepositoryConditionalRendererReportClosesNativeFallbackRows` in `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`.

The test builds current repository evidence through `IOSConditionalRendererGateEvidenceBuilder` and verifies:

- The current iOS renderer satisfies `IOSConditionalRendererGateEvidenceBundle.satisfiesStageOneConditionalRendererChecklist`.
- All three conditional renderer checklist rows are present.
- All three rows report `notApplicableNativeFallback`.
- All three rows are checklist-satisfied.
- The generated markdown report includes the corresponding supervisor-facing table rows.
- The generated markdown report records the native fallback reason.

## Current Renderer Runtime Evidence

The active iOS Stage 1 renderer remains native Swift/SwiftUI/UIKit:

- Ordinary Markdown renders through `MarkdownParserAdapter` and `MarkdownNativeRenderer`.
- Mermaid and math render as native safe-card/readable fallback blocks.
- No production JS/CSS/font/HTML/HTM renderer asset files are present under active iOS paths.
- No production WKWebView rich-renderer source is active.
- Existing future-mode tests still cover vendored local renderer packaging, SwiftPM bundle-resource declarations, manifest/hash verification, and WKWebView forbidden-request blocking before any local web renderer can satisfy Stage 1.

Renderer asset inventory command from repository root:

```sh
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print | sort
```

Result: PASS. No production renderer asset files were printed.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Built and executed 189 tests with 0 failures. The new test `testIOSL11CurrentRepositoryConditionalRendererReportClosesNativeFallbackRows` passed. |
| `find ios ... renderer asset inventory ...` from repository root | PASS | Printed no active production renderer asset paths after pruning `.build`, `.swiftpm`, `Tests`, `docs/reports`, and `docs/screenshots`. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Local simulator inventory includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -list` from `ios/` | PASS with informational warning | Xcode resolved SwiftPM package `FastMDMobile` and listed scheme `FastMDMobile`. It also printed `Supported platforms for the buildables in the current scheme is empty.` |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence paths:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/docs/reports/stage1-ios-l11-native-fallback-report-rows-20260506-0854.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch did not run or claim physical-device validation.
