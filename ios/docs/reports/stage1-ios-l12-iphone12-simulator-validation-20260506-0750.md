# Stage 1 iOS L12 iPhone 12 Simulator Validation - 2026-05-06 07:50 CST

## Scope

Bounded live-lane batch for the iOS-owned L12 platform validation gates.

This batch did not modify Android or the shared Stage 1 blueprint/todo files. It records fresh local validation evidence under `ios/docs/reports/` for supervisor reconciliation.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- iOS package root: `/Users/wangweiyang/GitHub/fastmd/ios`
- Xcode: `Xcode 26.4.1`, build `17E202`
- SwiftPM manifest: `ios/Package.swift`
- SwiftPM scheme discovered by Xcode: `FastMDMobile`
- iPhone 12 simulator discovered: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)`, iOS `26.4`, shutdown before validation
- Package deployment target observed in Xcode build logs: `arm64-apple-ios14.0-simulator`

## Validation Results

| Gate | Command | Result | Evidence |
| --- | --- | --- | --- |
| SwiftPM unit tests | `swift test` from `ios/` | PASS | `Executed 184 tests, with 0 failures (0 unexpected)` |
| Xcode package scheme discovery | `xcodebuild -list` from `ios/` | PASS | Workspace `ios` exposes scheme `FastMDMobile` |
| iPhone 12 simulator build | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **` |
| iPhone 12 simulator tests | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `Executed 184 tests, with 0 failures (0 unexpected)` and `** TEST SUCCEEDED **` |

## Command Details

### `swift test`

- Working directory: `/Users/wangweiyang/GitHub/fastmd/ios`
- Result: PASS
- Summary: `Test Suite 'All tests' passed`; `Executed 184 tests, with 0 failures (0 unexpected) in 8.236 seconds`.

### `xcrun simctl list devices available`

- Working directory: `/Users/wangweiyang/GitHub/fastmd`
- Result: PASS
- Relevant simulator: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` under iOS `26.4`.

### `xcodebuild -list`

- Working directory: `/Users/wangweiyang/GitHub/fastmd/ios`
- Result: PASS
- Relevant output: Xcode resolved the SwiftPM package and listed scheme `FastMDMobile`.

### `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build`

- Working directory: `/Users/wangweiyang/GitHub/fastmd/ios`
- Result: PASS
- Relevant output: `** BUILD SUCCEEDED **`.
- Build target triple observed: `arm64-apple-ios14.0-simulator`.
- SDK observed: `iPhoneSimulator26.4.sdk`.

### `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test`

- Working directory: `/Users/wangweiyang/GitHub/fastmd/ios`
- Result: PASS
- Relevant output: `Test Suite 'All tests' passed`; `Executed 184 tests, with 0 failures (0 unexpected) in 3.702 seconds`; `** TEST SUCCEEDED **`.
- Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_07-50-14-+0800.xcresult`

## Real Device Probe

Command:

```sh
xcrun devicectl list devices
```

Result: BLOCKED for real-device validation.

Observed devices:

- `Turbulence`, model `iPhone 15 Pro (iPhone16,1)`, state `unavailable`
- `王威扬的iPad`, model `iPad Pro (11-inch) (4th generation) (iPad14,4)`, state `unavailable`

Additional tool output:

```text
Failed to load provisioning paramter list due to error: Error Domain=com.apple.dt.CoreDeviceError Code=1002 "No provider was found."
```

No connected, available iPhone 12-class physical device was visible to `devicectl`, so the real-device validation gate remains open.

## Supervisor Checklist Recommendation

The supervisor can mark these iOS-owned L12 checklist items complete:

- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`

Keep this checklist item open:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence path:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-validation-20260506-0750.md`
