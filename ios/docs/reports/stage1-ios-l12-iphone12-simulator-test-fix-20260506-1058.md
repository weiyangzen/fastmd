# Stage 1 iOS L12 iPhone 12 Simulator Test Fix - 2026-05-06 10:58 CST

## Scope

One bounded iOS-owned live-lane batch.

Selected earliest actionable iOS-owned open work from the current Stage 1 checklist:

- L12: Run iOS iPhone 12 simulator build.
- L12: Run iOS iPhone 12 simulator tests.
- L13: Record validation reports under `ios/docs/reports/`.

No Android files, top-level Docs checklist files, `.cron` files, WebKit renderer, JS/CSS/font assets, remote renderer, network renderer, Info.plist, entitlement, privacy manifest, or background mode were introduced.

## Changed Files

Implementation/test hardening:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Evidence report:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-test-fix-20260506-1058.md`

## Implementation Notes

- The iPhone 12 simulator is available locally:
  - `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)`.
- The iPhone 12 simulator build gate passed before code changes.
- The first iPhone 12 simulator test attempt failed because `testIOSL11RendererAssetInventoryMatchesDocumentedCommandForCurrentTree` compiled into an iOS Simulator XCTest bundle and referenced `Process`.
- `Process` is valid for the macOS SwiftPM test host, where the shell-command parity assertion belongs, but it is unavailable in iOS Simulator test bundles.
- The test now keeps the `Process` command execution under `#if os(macOS)` and skips that one command-spawning parity check under `#if os(iOS)`.
- The same inventory model still runs on iOS Simulator through the surrounding L11 conditional renderer inventory tests.
- The macOS SwiftPM run still executes the command parity test and passed after the change.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 201 XCTest cases with 0 failures. This validates the macOS SwiftPM path, including the `Process`-based renderer inventory command parity test. |
| `xcrun simctl list devices available \| rg 'iPhone 12\|Stage1 iPhone 15 Pro'` | PASS | Reported `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1)`. |
| `xcodebuild -scheme FastMDMobile -destination 'id=1B6FEADC-308B-4069-B734-3C9C207E633F' build` from `ios/` | PASS | Xcode ended with `** BUILD SUCCEEDED **`. Target used `arm64-apple-ios14.0-simulator`. |
| `xcodebuild -scheme FastMDMobile -destination 'id=1B6FEADC-308B-4069-B734-3C9C207E633F' test` from `ios/` before fix | FAIL | Initial concurrent run failed with Xcode build database lock. Sequential rerun then exposed the real compile issue: `cannot find 'Process' in scope` for iOS Simulator tests. |
| `xcodebuild -scheme FastMDMobile -destination 'id=1B6FEADC-308B-4069-B734-3C9C207E633F' test` from `ios/` after fix | PASS | Executed 201 XCTest cases on iPhone 12 simulator with 1 expected skip and 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` | PASS | No JS/CSS/font/HTML renderer asset files found in the current iOS source/package surface. |
| `rg -n "^import WebKit$|WKWebView|WKNavigationDelegate|WKURLSchemeHandler|loadHTMLString|evaluateJavaScript" ios/Sources` | PASS | No active WebKit import or WKWebView construction found. Matches are policy/model references only. |
| `git diff --check -- ios` | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: this report, plus `xcodebuild -scheme FastMDMobile -destination 'id=1B6FEADC-308B-4069-B734-3C9C207E633F' build` passed.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: this report, plus `xcodebuild -scheme FastMDMobile -destination 'id=1B6FEADC-308B-4069-B734-3C9C207E633F' test` passed after the platform-aware XCTest fix.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: `ios/docs/reports/stage1-ios-l12-iphone12-simulator-test-fix-20260506-1058.md`.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Reason: this batch validated an iPhone 12 simulator only. It did not run a connected physical iPhone 12-family device manual flow.
