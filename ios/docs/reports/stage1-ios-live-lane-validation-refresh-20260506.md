# Stage 1 iOS Live Lane Validation Refresh - 2026-05-06

## Scope

Ran one bounded iOS-owned validation batch for the earliest open iOS checklist cluster that can be advanced without Android or root Docs edits:

- L11 conditional local renderer gates.
- L12 iPhone 12 simulator build and test gates.
- L12 iPhone 12-family real-device gate probe.

No product source changes were needed in this batch. Existing native Swift implementation and XCTest coverage already model the L11 conditional renderer gates, L12 simulator reports, L12 performance/security/rich fixture reports, and L12 real-device completion guard.

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-live-lane-validation-refresh-20260506.md`

Existing implementation and automated evidence remain in:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Current Renderer Posture

The iOS renderer remains native Swift/SwiftUI/UIKit presentation-contract code. Mermaid and math blocks render as native safe-card fallbacks. Unsafe HTML, remote images, and links are represented through native sanitized or blocked/confirm policy payloads.

No JS/CSS/font/HTML renderer assets were discovered under `ios/`. No WKWebView rich renderer surface is active. The L11 conditional gates are therefore satisfied as not applicable for the current native fallback runtime, with future vendored-asset and unsafe-path coverage already enforced by XCTest.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 26 focused L11 tests with 0 failures. Covered conditional renderer native fallback gates, future vendored asset gates, renderer asset inventory, manifest/hash verification, WKWebView-not-applicable evidence, parser/source-range/snapshot/layout, file/save/security, performance, memory, accessibility, log redaction, and recovery gates. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 18 focused L12 tests with 0 failures. Covered performance, simulator, security, rich fixture render, xctrace/devicectl parsing, real-device eligibility, current probe freshness, SwiftPM/simulator prerequisites, and manual flow evidence requirements. |
| `swift test` from `ios/` | PASS | Executed 135 XCTest cases with 0 failures. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|Stage1\|iPhone 15\|iPhone"` from `ios/` | PASS | Listed an available `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` simulator. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built the SwiftPM `FastMDMobile` scheme for `arm64-apple-ios14.0-simulator` with iPhoneSimulator26.4 SDK. Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination and executed 135 XCTest cases with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_01-04-48-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Connected physical devices list contains `Mac` only. Offline physical iOS devices are present, and the `iPhone 12` entry is listed under simulators, not connected physical devices. |

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
- `ios/docs/reports/stage1-ios-live-lane-validation-refresh-20260506.md`
- Xcode result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_01-04-48-+0800.xcresult`

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available during this batch. Simulator validation passed, but the real-device gate still requires eligible hardware plus timestamped manual evidence for open, render, search, full source edit, block source edit, save writable document, and rotate reader.
