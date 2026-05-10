# Stage 1 iOS L12 Live Lane Validation - 2026-05-06 05:13 +0800

## Scope

Ran one bounded iOS-only validation/evidence batch for the earliest still-open iOS-owned checklist items in the Stage 1 mobile blueprint:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L12: current blocker refresh for `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- L12/L13 evidence refresh for `Record validation reports under ios/docs/reports/.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- iOS package: `/Users/wangweiyang/GitHub/fastmd/ios`
- Xcode command-line tool: `/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild`
- SwiftPM workspace scheme discovered by `xcodebuild -list`: `FastMDMobile`
- Required simulator destination: `platform=iOS Simulator,name=iPhone 12`
- Available iPhone 12 simulator: `iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Built and ran `FastMDMobilePackageTests.xctest`; executed 165 tests with 0 failures. |
| `xcodebuild -list` from `ios/` | PASS | Resolved the SwiftPM workspace and listed scheme `FastMDMobile`. Xcode also logged `Supported platforms for the buildables in the current scheme is empty`, but the scheme resolved and the exact iPhone 12 build/test gates below passed. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|Booted\|Shutdown"` from repository root | PASS | Listed `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `find ios \( -path 'ios/.build' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer assets are present under production iOS paths. |
| `rg -n '^\s*import\s+WebKit\b\|\bWKWebView\s*(\|\.)' ios/Sources` from repository root | PASS | Exit 1 with no matches. No active WebKit rich-renderer source usage was found under iOS production sources. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran `FastMDMobileCoreTests` on the exact iPhone 12 simulator destination; executed 165 tests with 0 failures and ended with `** TEST SUCCEEDED **`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Command completed. Connected hardware listed only `Mac`; offline physical iOS-family devices were `Turbulence (26.1)` and `王威扬的iPad (26.3.1)`. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was listed. |
| `xcrun devicectl list devices --json-output /tmp/fastmd-ios-real-device-probe-20260506-0513.json` from `ios/` | BLOCKED for real-device completion | Command completed with a CoreDevice provider warning. Listed physical devices were unavailable; the unavailable iPhone-class device was `iPhone 15 Pro (iPhone16,1)`, not an iPhone 12-family device. |

## Xcode Result Bundle

`xcodebuild ... test` wrote:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_05-13-40-+0800.xcresult
```

## Supervisor-Reconcilable Items

The supervisor can mark these iOS-owned checklist items complete using this report as evidence:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

The following item must remain open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason: no connected physical iPhone 12-family device was available during this batch. Simulator validation passed, but simulator evidence does not satisfy the physical-device gate.

## Files Changed

- `ios/docs/reports/stage1-ios-l12-live-lane-validation-20260506-0513.md`
