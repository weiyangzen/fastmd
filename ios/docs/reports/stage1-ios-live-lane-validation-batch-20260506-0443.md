# Stage 1 iOS Live Lane Validation Batch - 2026-05-06 04:43 +0800

## Scope

Ran one bounded iOS-owned validation/evidence batch against the current `ios/` tree.

The earliest still-open iOS-owned cluster in the current blueprint remains the L11 conditional renderer gates followed by L12 iOS validation. The implementation remains native Swift/SwiftUI/UIKit with native fallback cards for rich Markdown surfaces, and the local machine currently provides an iPhone 12 simulator but no connected physical iPhone 12-family device.

This batch did not edit Android files, top-level `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, app entitlements, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-live-lane-validation-batch-20260506-0443.md`

Implementation and tests used as evidence, unchanged in this batch:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/Tests/Fixtures/Markdown/rich-preview.md`
- `ios/docs/screenshots/golden/*.snapshot.txt`

## Renderer Posture

- Ordinary Markdown rendering remains native.
- Mermaid and math blocks render as native safe fallback cards.
- HTML/details/video/generic fallback surfaces render as sanitized native fallback blocks.
- Remote images remain manual-open placeholders and do not auto-fetch.
- No JS/CSS/font/HTML renderer assets were found under `ios/`.
- No WKWebView rich renderer surface is active in `ios/Sources`.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 159 tests with 0 failures. Coverage includes L1 canonical fixture matrix, L11 conditional renderer gates, renderer asset inventory/hash audits, WKWebView request-blocking policy tests, rich fixture renderer snapshots, L12 performance/security/rich-fixture report models, and real-device blocker/report contracts. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|Stage1\|iPhone"` from repo root | PASS | Available simulator inventory includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` plus newer iPhone simulators. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build resolved the SwiftPM `FastMDMobile` scheme for iPhone 12 simulator and ended with `** BUILD SUCCEEDED **`. Xcode logged `Supported platforms for the buildables in the current scheme is empty`, but the destination built successfully. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 159 tests with 0 failures on the iPhone 12 simulator and ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_04-43-43-+0800.xcresult`. |
| `find ios -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repo root | PASS | Empty output. No local JS/CSS/font/HTML renderer assets are present under `ios/`, so L11 packaging/offline and manifest/hash gates are not applicable for the current native fallback renderer mode. |
| `git diff --check -- ios` from repo root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun xctrace list devices` from repo root | BLOCKED for physical real-device gate | Connected physical devices list contained only `Mac`. Offline devices included an iPhone 15 Pro and an iPad. The iPhone 12 entry appeared only under simulators. |
| `xcrun devicectl list devices --json-output /tmp/fastmd-ios-devices-20260506-live-lane-0443.json` from repo root | BLOCKED for physical real-device gate | Command completed with CoreDevice warning `No provider was found.` and listed `Turbulence` as unavailable `iPhone 15 Pro (iPhone16,1)` plus an unavailable iPad. No connected, available physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L12: `Capture iOS performance report.`
- L12: `Capture iOS security audit report.`
- L12: `Capture rich fixture render report.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-live-lane-validation-batch-20260506-0443.md`
- `ios/docs/reports/stage1-ios-l12-performance-report-20260505.md`
- `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md`
- `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_04-43-43-+0800.xcresult`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected, available physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. Simulator build/test passed, but the real-device gate remains open until physical iPhone 12-family hardware completes the Stage 1 open, render, search, edit, save, and rotate flow with manual evidence.
