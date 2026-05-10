# Stage 1 iOS L11/L12 Validation Refresh - 2026-05-06 02:16 CST

## Scope

Ran one bounded iOS-owned validation batch against the earliest still-open iOS checklist cluster from `Docs/Stage1_Mobile_Blueprint.md` and `Docs/todos_20260505.md`.

This batch only writes iOS-local evidence under `ios/docs/reports/`. It did not edit `android/**`, root `Docs/**`, `.cron/**`, Swift sources, XCTest sources, renderer assets, entitlements, privacy manifests, background modes, or any WebKit/network renderer behavior.

## Current Renderer Posture

FastMD iOS remains on the native Swift renderer path. Rich Markdown fallbacks such as Mermaid, math, and generic HTML are represented by native safe-card or sanitized native fallback presentation contracts.

Current local evidence:

- No JS/CSS/font/HTML renderer assets are present under `ios/`.
- No WKWebView rich renderer surface is active in the package.
- The existing XCTest suite includes native-fallback evidence plus future vendored-asset and unsafe WKWebView request-blocking cases.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Built successfully and executed 144 tests with 0 failures. This includes `testCanonicalMarkdownFixtureMatrixExistsAndIsSeeded`, L11 conditional renderer tests, L12 simulator report tests, iOS performance/security/rich fixture report tests, and real-device blocker model tests. |
| `find ios -path 'ios/.build' -prune -o -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) -print \| sort` from repo root | PASS | Empty output. No vendored JS/CSS/font/HTML renderer asset files were found under `ios/` outside SwiftPM build output. |
| `xcrun simctl list devices available \| rg 'iPhone 12\|iPhone 15\|Stage1'` from repo root | PASS | Available simulator inventory includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built the SwiftPM `FastMDMobile` scheme for `arm64-apple-ios14.0-simulator`; Xcode ended with `** BUILD SUCCEEDED **`. Xcode still logs `Supported platforms for the buildables in the current scheme is empty`, but it resolves and builds the scheme for the requested simulator destination. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination and executed 144 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_02-16-01-+0800.xcresult`. |
| `xcrun xctrace list devices` from repo root | BLOCKED for physical iPhone 12 gate | Connected devices list includes the Mac only. Two physical devices are listed offline: an iPhone 15 Pro and an iPad. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max is available. |
| `xcrun devicectl list devices --json-output -` from repo root | BLOCKED for physical iPhone 12 gate | Command outcome is success, but the only physical devices reported are unavailable non-iPhone-12-family devices: iPhone 15 Pro (`iPhone16,1`) and iPad Pro (`iPad14,4`). No connected eligible iPhone 12-family hardware is available for manual flow validation. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-live-lane-l11-l12-validation-refresh-20260506-0216.md`
- Xcode result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_02-16-01-+0800.xcresult`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected physical iPhone 12-family device was available. Simulator build/test passed, but the real-device gate remains open until a connected iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 open, render, search, edit, save, and rotate flow with manual evidence.
