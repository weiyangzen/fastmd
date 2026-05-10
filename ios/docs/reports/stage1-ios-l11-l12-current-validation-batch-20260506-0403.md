# Stage 1 iOS L11/L12 Current Validation Batch - 2026-05-06 04:03 +0800

## Scope

Ran one bounded iOS-owned validation/evidence batch against the current `ios/` tree.

The earliest still-open iOS-owned checklist cluster in the daily snapshot is the conditional L11 renderer group. The current implementation remains native Swift/SwiftUI/UIKit with native safe-card fallbacks for Mermaid/math/HTML surfaces, so the conditional renderer gates are satisfied as not applicable unless future JS/CSS/font/HTML renderer assets or WKWebView rich surfaces are introduced.

This batch also refreshed the adjacent iPhone 12 simulator gates because the local simulator set currently exposes an `iPhone 12` destination.

No Android files, top-level `Docs/**`, `.cron/**`, app entitlements, Info.plist files, privacy manifests, WebKit renderer code, JS/CSS/font/HTML renderer assets, CDN dependencies, or network renderer behavior were changed.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l11-l12-current-validation-batch-20260506-0403.md`

Implementation and tests used as evidence, unchanged in this batch:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/Tests/Fixtures/Markdown/rich-preview.md`

## Current Renderer Posture

- Ordinary Markdown rendering is native Swift model rendering with SwiftUI/UIKit presentation contracts.
- Mermaid and math blocks render as native safe fallback cards.
- Generic HTML, details/summary, and hostile HTML render as sanitized native fallback blocks.
- Remote images are manual-open placeholders and do not auto-fetch.
- No JS/CSS/font/HTML renderer assets are present under `ios/`.
- No WKWebView rich renderer source is active in `ios/Sources`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 23 focused L12 tests with 0 failures. Coverage included performance report, security audit report, rich fixture render report, iPhone 12 simulator report modeling, and physical-device blocker/report modeling. |
| `swift test` from `ios/` | PASS | Executed 153 tests with 0 failures. This includes the L1 canonical fixture matrix, L11 conditional renderer gates, asset inventory/hash audits, WKWebView request-blocking policy tests, L12 report tests, and core reader/file/security/editor tests. |
| `find ios -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg "iPhone 12\|Stage1\|iPhone 15"` from repository root | PASS | Available simulator inventory includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build resolved the SwiftPM `FastMDMobile` scheme for the iPhone 12 simulator destination and ended with `** BUILD SUCCEEDED **`. Xcode logged `Supported platforms for the buildables in the current scheme is empty`, but the destination still built successfully. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination and executed 153 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_04-02-56-+0800.xcresult`. |
| `xcrun devicectl list devices` from repository root | BLOCKED for real-device gate | Listed `Turbulence` as unavailable `iPhone 15 Pro (iPhone16,1)` and an unavailable iPad Pro. No connected, available physical iPhone 12-family device was present. Command also printed CoreDevice provider warning: `No provider was found.` |
| `xcrun xctrace list devices` from repository root | BLOCKED for real-device gate | Listed Mac as the only connected device. Offline devices were an iPhone 15 Pro and an iPad. The iPhone 12 entry appeared only under simulators, not connected physical devices. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-l12-current-validation-batch-20260506-0403.md`
- Xcode result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_04-02-56-+0800.xcresult`

Already-present adjacent L12 report evidence was also revalidated by the focused and full test runs:

- L12: `Capture iOS performance report.`
- L12: `Capture iOS security audit report.`
- L12: `Capture rich fixture render report.`

Evidence paths:

- `ios/docs/reports/stage1-ios-l12-performance-report-20260505.md`
- `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected, available physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. Simulator build/test passed, but the real-device gate remains open until a physical iPhone 12-family device completes the Stage 1 open, render, search, edit, save, and rotate flow with manual evidence.
