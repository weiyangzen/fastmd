# Stage 1 iOS L11/L12 Live Validation Batch - 2026-05-06 08:41 CST

## Scope

Ran one bounded iOS-only live-lane batch against the earliest still-open iOS-owned checklist surface:

- L11 conditional renderer gates:
  - Add local renderer packaging/offline tests if JS renderer assets are used.
  - Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12 iOS simulator validation:
  - Run iOS iPhone 12 simulator build.
  - Run iOS iPhone 12 simulator tests.
- L12 physical-device validation:
  - Probe, but keep open, iOS iPhone 12-class real-device validation before parity-complete release claim.

This batch only wrote this platform-local iOS report. It did not edit `android/**`, shared `Docs/**`, `.cron/**`, Swift sources, XCTest sources, renderer assets, WebKit surfaces, entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

- `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0841.md`

## Current Renderer Runtime Evidence

The active iOS Stage 1 renderer remains native Swift:

- Ordinary Markdown renders through `MarkdownParserAdapter` and `MarkdownNativeRenderer`.
- Mermaid and math render as native safe-card/readable fallback blocks.
- No production JS/CSS/font/HTML/HTM renderer asset files are present under active iOS paths.
- No production WKWebView rich-renderer surface is active.
- Existing XCTest coverage still includes future-mode gates for vendored local renderer assets, manifest/hash verification, bundle-resource declaration, and WKWebView request blocking before any local web renderer mode can satisfy Stage 1.

Renderer asset inventory command from repository root:

```sh
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print | sort
```

Result: PASS. No production renderer asset files were printed.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 188 tests with 0 failures. Includes L1 fixture matrix, L11 conditional renderer tests, L12 simulator/report/security/rich-fixture tests, real-device blocker tests, and L13 reconciliation evidence tests. |
| `xcrun simctl list devices available \| rg 'iPhone 12\|Stage1\|iPhone 15'` from `ios/` | PASS | Available simulator set includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)`. |
| `xcodebuild -list` from `ios/` | PASS | Xcode resolved SwiftPM package `FastMDMobile` and listed scheme `FastMDMobile`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built `FastMDMobileCore` for iPhone Simulator SDK 26.4 with iOS deployment target 14.0. Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the local `iPhone 12` simulator. Executed 188 tests with 0 failures. Xcode wrote result bundle `Test-FastMDMobile-2026.05.06_08-40-29-+0800.xcresult` and ended with `** TEST SUCCEEDED **`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKER for physical-device gate | Listed connected Mac, offline `Turbulence (26.1)`, and offline `王威扬的iPad (26.3.1)`. No connected iPhone 12-family physical device was available. |
| `xcrun devicectl list devices` from `ios/` | BLOCKER for physical-device gate | Listed unavailable physical devices only: `Turbulence`, model `iPhone 15 Pro (iPhone16,1)`, and `王威扬的iPad`, model `iPad Pro (11-inch) (4th generation) (iPad14,4)`. No available iPhone 12-family hardware was present. Command also emitted `No provider was found`, then printed the unavailable-device table. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0841.md`
- `ios/docs/reports/stage1-ios-l12-performance-report-20260505.md`
- `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Current blocker:

- No connected and available iPhone 12-family physical device was detected by `xctrace` or `devicectl` in this batch. Simulator validation is complete, but the physical-device gate must remain open until the full open/render/search/edit/save/rotate flow runs on eligible iPhone 12-family hardware and records evidence under `ios/docs/reports/**`.
