# Stage 1 iOS L12 Performance Report Format And Validation - 2026-05-06

## Scope

Ran one bounded iOS-owned L12 implementation and validation batch.

Changes are limited to `ios/**`. This batch did not edit Android files, shared `Docs/**` files, `.cron/**`, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-performance-report-format-validation-20260506.md`

## Implementation Notes

- Tightened `IOSStageOnePerformanceReport.markdown` so every generated operation row closes with a final Markdown table pipe.
- Normalized the failing-row branch to emit `FAIL` before the shared row terminator instead of embedding the final pipe only in that branch.
- Added focused L12 XCTest assertions for closed `parse`, `fontTierSwitch`, and `save` rows.

The change is report-format-only and does not alter parser, renderer, file IO, editor, security, or lifecycle behavior.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12PerformanceReportCapturesRedactedIPhone12ProfileEvidence` from `ios/` | PASS | Built successfully and executed 1 focused L12 performance-report test with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 145 XCTest cases with 0 failures. Includes the L1 canonical fixture matrix, L11 conditional renderer gates, L12 performance/security/rich-render report models, iPhone 12 simulator report model, and real-device blocker model tests. |
| `xcodebuild -list` from `ios/` | PASS WITH WARNING | SwiftPM workspace exposes scheme `FastMDMobile`. Xcode logs `Supported platforms for the buildables in the current scheme is empty`, but the scheme resolves for explicit simulator build/test commands. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone"` from repository root | PASS | An available `iPhone 12` simulator is present. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS WITH WARNING | Built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` using the iPhone Simulator 26.4 SDK. Xcode ended with `** BUILD SUCCEEDED **` and emitted the existing SwiftPM supported-platform warning. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS WITH WARNING | Ran on the exact `iPhone 12` simulator destination, executed 145 XCTest cases with 0 failures, and ended with `** TEST SUCCEEDED **`. Xcode emitted the same SwiftPM supported-platform warning. |
| `xcrun devicectl list devices` from repository root | BLOCKED for real-device completion | Command returned the local CoreDevice table, but only unavailable physical iOS-family devices were listed: an iPhone 15 Pro-class device and an iPad-class device. No connected physical iPhone 12-family hardware was available. Device identifiers are omitted from this report. |
| `system_profiler SPUSBDataType \| rg -n "iPhone\|iPad\|Model Identifier\|Serial Number\|Product ID\|Vendor ID\|Apple Mobile\|USB"` from repository root | BLOCKED for real-device completion | No connected USB iPhone or iPad evidence was returned by the filtered probe. |
| `find ios -path 'ios/.build' -prune -o -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) -print \| sort` from repository root | PASS | Empty output. No vendored JS/CSS/font/HTML renderer assets were found under `ios/` outside SwiftPM build output. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L12: `Capture iOS performance report.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-performance-report-format-validation-20260506.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- This batch validated the iPhone 12 simulator build/test path only.
- The current machine did not expose a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max device.
- The real-device gate still requires the Stage 1 open, render, search, edit, save, and rotate flow on eligible physical hardware.
