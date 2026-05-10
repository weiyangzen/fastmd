# Stage 1 iOS L12 Real-Device Prerequisite Guard - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation and validation batch for the remaining iOS-owned L12 real-device gate:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Implementation

Tightened the native Swift real-device validation model so the physical iPhone 12-family report now fails closed when prerequisite validation is missing.

- Added `IOSStageOneRealDeviceValidationStatus.blockedMissingPrerequisiteValidation`.
- Updated `IOSStageOneRealDeviceValidationReport.status` to require all prerequisite checks before it can report `passed`:
  - SwiftPM tests passed.
  - iPhone 12 simulator build passed.
  - iPhone 12 simulator tests passed.
- Updated the report blocker text to explain prerequisite failures directly.
- Added XCTest coverage proving a connected iPhone 12-family candidate plus complete manual flow evidence still cannot satisfy the real-device gate when iPhone 12 simulator tests are false.

This keeps the L12 real-device status aligned with the actual completion boolean and prevents a misleading `passed` status when simulator prerequisites are incomplete.

## Current Device Probe

Command:

```text
xcrun xctrace list devices
```

Result:

- Connected physical devices: `Mac` only.
- Offline physical iOS-family devices: one iPhone-like entry named `Turbulence (26.1)` and one iPad.
- Simulators include `iPhone 12 (26.4.1)`.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max devices: `0`.

The available `iPhone 12` entry is under `== Simulators ==`, not `== Devices ==`. It cannot satisfy the blueprint's physical iPhone 12-family real-device gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 13 focused L12 tests with 0 failures. New coverage includes `testIOSL12RealDeviceValidationRequiresSwiftPMAndSimulatorPrerequisites`. |
| `swift test` from `ios/` | PASS | Executed 130 XCTest cases with 0 failures. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination, executed 130 tests with 0 failures, and ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_00-29-56-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed. The local iPhone 12 is a simulator only. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Supervisor Can Mark Complete

No new blueprint checklist item should be marked complete from this batch.

The batch advances evidence quality for:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

but this gate remains open because no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max is available.

## Remaining Blocker

No L12 real-device completion claim should be made from this batch. Completion still requires:

- a connected physical iPhone 12-family device,
- a fresh `xcrun xctrace list devices` probe captured during validation,
- passing SwiftPM and iPhone 12 simulator prerequisites,
- timestamped manual evidence for the full Stage 1 open, render, search, full source edit, block source edit, save writable document, and rotate reader flow.
