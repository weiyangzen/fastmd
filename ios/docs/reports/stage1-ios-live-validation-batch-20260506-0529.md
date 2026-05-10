# Stage 1 iOS Live Validation Batch - 2026-05-06 05:29 CST

## Scope

Ran one bounded iOS-owned validation batch against the remaining open iOS Stage 1 checklist cluster. No Android files, root `Docs/**`, `.cron/**`, source code, renderer assets, entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior were changed.

This report is platform-local evidence only. The supervising session should reconcile the root blueprint and daily todo snapshot.

## Changed Files

- `ios/docs/reports/stage1-ios-live-validation-batch-20260506-0529.md`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 166 tests with 0 failures. This covers the iOS L1 fixture matrix, L11 conditional renderer gates, L12 performance/security/rich-fixture report models, and L13 README command audit tests. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|Stage1\|iPhone"` from repository root | PASS | Available simulator inventory includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -list` from `ios/` | PASS | SwiftPM exposes the `FastMDMobile` scheme. Xcode also emitted the known SwiftPM supported-platform warning, but scheme listing succeeded. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built `FastMDMobileCore` for iPhone 12 simulator with deployment target `arm64-apple-ios14.0-simulator`; ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran 166 XCTest cases on the iPhone 12 simulator destination with 0 failures; ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_05-28-24-+0800.xcresult`. |
| `find ios \( -path 'ios/.build' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No production-side JS/CSS/font/HTML renderer assets are present under `ios/`; generated reports/screenshots and SwiftPM build outputs are excluded from the production inventory. |
| `xcrun xctrace list devices` from repository root | PASS command, real-device gate BLOCKED | Connected physical devices list contained only `Mac`. Offline physical devices were present but unavailable. The simulator inventory included `iPhone 12`, which satisfies simulator validation only and does not satisfy the physical-device gate. |
| `xcrun devicectl list devices --json-output -` from repository root | PASS command, real-device gate BLOCKED | CoreDevice reported unavailable physical devices only: an unavailable iPhone 15 Pro-class device and an unavailable iPad Pro-class device. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available. Private serials, UDIDs, ECIDs, and full identifiers are intentionally omitted from this report. |

## Checklist Evidence For Supervisor

The supervising session can use this batch as fresh evidence for these iOS-owned checklist items:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: `swift test` passed; production renderer asset inventory is empty; iOS rich fallback remains native safe-card mode with no JS/CSS/font/HTML runtime assets.

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: `swift test` passed request-blocking policy and conditional renderer tests; no production WKWebView rich renderer source is active in this batch.

- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: `swift test` passed manifest/hash verification model tests; no production vendored renderer assets are present, so the current gate is satisfied as native-fallback/not-applicable.

- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.

- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 166 tests and 0 failures.

- L12: `Capture iOS performance report.`
  - Evidence: `swift test` passed the iOS L12 performance report contract and the full test suite; prior detailed report anchors under `ios/docs/reports/` remain valid.

- L12: `Capture iOS security audit report.`
  - Evidence: `swift test` passed the iOS L12 security audit report contract and the full test suite; no production renderer assets or WebKit rich renderer code were discovered by this batch.

- L12: `Capture rich fixture render report.`
  - Evidence: `swift test` passed the iOS L12 rich fixture render report contract and the full test suite, including complete rich fixture category and snapshot-signature coverage.

- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this report is platform-local under `ios/docs/reports/`.

## Still Open

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

The real-device validation gate remains blocked because no connected physical iPhone 12-family hardware was available during this batch. The machine has an available `iPhone 12` simulator, but simulator evidence is not physical-device evidence. This gate should close only after a real iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 manual flow: open Markdown, render rich fixture, search, full source edit, block source edit, save, and rotate.
