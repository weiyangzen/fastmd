# Stage 1 iOS L12 Real-Device Manual Flow Freshness - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation and validation batch for the remaining iOS-owned L12 physical-device gate:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Implementation

Added freshness enforcement for the manual physical-device flow evidence in the native Swift L12 real-device validation model:

- `IOSStageOneRealDeviceValidationStatus` now has `blockedStaleManualFlowEvidence`.
- `IOSStageOneRealDeviceManualFlowAudit` now tracks report time and maximum evidence age.
- The audit now exposes `completedStepsWithCurrentEvidence`, `staleOrFutureEvidenceSteps`, and `hasCurrentEvidenceForEveryRequiredStep`.
- `IOSStageOneRealDeviceValidationReport` now records `manualFlowMaximumEvidenceAge`, exposes `hasCurrentManualFlowEvidence`, and refuses to pass when manual evidence is stale or newer than the report timestamp.
- Real-device validation Markdown now reports `Manual flow evidence current`.
- Manual evidence rows now distinguish `PASS`, `OPEN`, and `STALE`, so stale notes cannot look equivalent to fresh physical-device validation.

This does not complete the physical-device gate. It tightens the completion contract so future real-device evidence must be captured during the validation window, not replayed from stale notes.

## Current Device Probe

Command:

```text
xcrun xctrace list devices
```

Result:

- Connected physical devices: `Mac` only.
- Offline physical iOS-family devices: `Turbulence (26.1)` and an iPad.
- Simulators include `iPhone 12 (26.4.1)`.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max devices: `0`.

Additional command:

```text
xcrun devicectl list devices
```

Result:

- `Turbulence` is listed as `unavailable` with model `iPhone 15 Pro (iPhone16,1)`.
- The iPad is listed as `unavailable` with model `iPad Pro (11-inch) (4th generation) (iPad14,4)`.
- No connected physical iPhone 12-family hardware is available.

The available `iPhone 12` entry is under simulators, not physical devices. It cannot satisfy the blueprint's physical iPhone 12-family real-device gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 13 focused real-device tests with 0 failures. New coverage includes `testIOSL12RealDeviceValidationRequiresCurrentManualFlowEvidence`. |
| `swift test` from `ios/` | PASS | Executed 146 XCTest cases with 0 failures. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination, executed 146 tests with 0 failures, and ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_02-41-25-+0800.xcresult`. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed. The local iPhone 12 is a simulator only. |
| `xcrun devicectl list devices` from `ios/` | BLOCKED for real-device completion | Listed no connected physical iPhone 12-family device. |
| `awk '/[ \t]$/ { print FILENAME ":" FNR ": trailing whitespace"; found=1 } END { exit found ? 1 : 0 }' ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift ios/docs/reports/stage1-ios-l12-real-device-manual-flow-freshness-20260506.md` from repository root | PASS | No trailing whitespace was reported in the changed iOS files. |

## Supervisor Can Mark Complete

No new blueprint checklist item should be marked complete from this batch.

The batch advances evidence quality for:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

but this gate remains open because no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max is available.

## Remaining Blocker

No L12 real-device completion claim should be made from this batch. Completion still requires:

- a connected physical iPhone 12-family device,
- fresh `xcrun xctrace list devices` or `xcrun devicectl list devices` evidence captured during validation,
- passing SwiftPM and iPhone 12 simulator prerequisites,
- current timestamped manual evidence for the full Stage 1 open, render, search, full source edit, block source edit, save writable document, and rotate reader flow.

## Evidence Paths

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-manual-flow-freshness-20260506.md`
