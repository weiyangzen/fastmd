# Stage 1 iOS L12 iPhone 12 Simulator Pass - 2026-05-06

## Scope

Ran one bounded iOS-only validation batch for the earliest remaining iOS-owned L12 gates:

- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`

No Android files, root `Docs/**`, `.cron/**`, Swift source, XCTest source, app manifests, entitlements, privacy manifests, renderer assets, WebKit rich-renderer surfaces, CDN dependencies, or network renderer behavior were changed.

## Changed Files

Report only:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-pass-20260506-live.md`

## Current Simulator Availability

`xcrun simctl list devices available` from `ios/` now lists:

- `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` under iOS 26.4.

This means the previous missing-destination blocker for `platform=iOS Simulator,name=iPhone 12` is no longer current on this machine.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 142 tests with 0 failures. |
| `xcodebuild -list` from `ios/` | PASS | Workspace `ios` exposes scheme `FastMDMobile`. |
| `xcrun simctl list devices available` from `ios/` | PASS | Available simulator list includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)` under iOS 26.4. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Xcode ended with `** BUILD SUCCEEDED **`; build used iPhone Simulator SDK 26.4 and target `arm64-apple-ios14.0-simulator`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Xcode ended with `** TEST SUCCEEDED **`; executed 142 tests with 0 failures on the iPhone 12 simulator destination. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_02-09-10-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device gate | No connected physical iPhone 12-family device is online. Connected devices list only `Mac`; iOS-family devices `Turbulence (26.1)` and `王威扬的iPad (26.3.1)` are listed offline. |

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence path:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-pass-20260506-live.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max is available to run the real-device Stage 1 flow. The available iPhone 12 entry is a simulator, not physical hardware.
