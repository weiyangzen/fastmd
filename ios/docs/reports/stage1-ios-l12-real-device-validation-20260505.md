# Stage 1 iOS L12 Real-Device Validation Readiness - 2026-05-05

## Scope

Advanced one bounded iOS-owned L12 validation-readiness batch for the remaining iPhone 12-family physical-device gate:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-validation-20260505.md`

## Implementation Notes

- Added `IOSStageOneRealDeviceValidationReport`, a native Swift evidence model for the L12 physical iPhone 12-family validation gate.
- Added `IOSStageOnePhysicalDeviceCandidate` to distinguish connected physical devices from simulators and offline devices.
- Added `IOSStageOneRealDeviceFlowStep` for the required real-device manual flow: open Markdown, render rich fixture, search, full-source edit, block-source edit, save writable document, and rotate reader.
- Added tests proving that an iPhone 12 simulator does not satisfy the physical-device gate and that the gate passes only when connected iPhone 12-family hardware completes every required flow step.
- Added `IOSXctraceDeviceListParser` so `xcrun xctrace list devices` output is classified into connected devices, offline devices, and simulators before building the validation report.
- Added tests proving the parser preserves names with parentheses, treats offline devices as disconnected, and prevents an available `iPhone 12` simulator from satisfying the physical-device gate.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Current Local Device Probe

Command:

```bash
xcrun xctrace list devices
```

Result:

- Connected devices: Mac only.
- Offline devices: two iOS-family devices were listed offline.
- Simulators: an `iPhone 12` simulator is available.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max devices: `0`.
- Machine-parsed evidence: `IOSXctraceDeviceListParser` classifies the local `iPhone 12` entry as `isSimulator == true`, so `IOSStageOneRealDeviceValidationReport.eligibleConnectedDevices` remains empty.

The real-device validation gate remains blocked because no connected physical iPhone 12-family device is available in this lane.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 7 focused L12 tests with 0 failures, including the real-device validation report and new `xctrace` parser tests. |
| `swift test` from `ios/` | PASS | Executed 118 tests with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg -n "iPhone 12"` from repository root | PASS | Local CoreSimulator lists an available `iPhone 12` simulator destination. |
| `xcrun xctrace list devices` from repository root | BLOCKED for real device | No connected physical iPhone 12-family device was reported. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` against the iPhone Simulator 26.4 SDK. Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 113 `FastMDMobileCoreTests` tests with 0 failures on the `iPhone 12` simulator destination. Xcode ended with `** TEST SUCCEEDED **`. |

Xcode test result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.05_22-18-05-+0800.xcresult
```

## Checklist Evidence

Supervisor can mark complete from earlier simulator evidence if not already reconciled:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Current batch adds validation-hardening evidence but does not complete a new physical-device checklist item. Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-validation-20260505.md`
- `swift test --filter FastMDMobileCoreTests/testIOSL12` passed.
- `swift test` passed.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed.

Remaining blocker:

- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max device was available, so the required real-device open/render/search/edit/save/rotate flow was not executed and must not be marked complete.
