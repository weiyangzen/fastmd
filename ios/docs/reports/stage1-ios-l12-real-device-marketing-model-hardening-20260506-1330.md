# Stage 1 iOS L12 Real-Device Marketing Model Hardening - 2026-05-06 13:30 CST

## Scope

One bounded iOS-owned implementation batch for the earliest remaining iOS-owned checklist row:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch stayed under `ios/**`. No Android files, root `Docs/**` checklist files, `.cron/**`, WebKit renderer code, JavaScript/CSS/font renderer assets, Info.plist files, entitlements, privacy manifests, background modes, CDN dependencies, or network renderer behavior were changed.

## Implementation

- Hardened `IOSStageOnePhysicalDeviceCandidate` iPhone 12-family eligibility matching for physical-device validation evidence.
- The L12 real-device model now accepts devicectl marketing model strings that include a parenthesized hardware identifier, for example `iPhone 12 Pro Max (iPhone13,4)`.
- Exact existing matches for iPhone 12-family marketing names and product identifiers remain supported.
- Simulator destinations remain ineligible for the physical-device gate.
- Disconnected or unavailable physical devices remain ineligible for the physical-device gate.
- Added focused XCTest coverage proving a connected physical devicectl candidate with `marketingName` set to `iPhone 12 Pro Max (iPhone13,4)` can satisfy the hardware-family portion of the gate when the full Stage 1 manual flow evidence is present.

## Current Physical-Device Result

The iPhone 12-family real-device validation gate remains blocked.

Current local probes show:

- An available `iPhone 12` simulator destination.
- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max.
- `xctrace` reported the local Mac as connected, two physical devices as offline, and an `iPhone 12` only under simulators.
- `devicectl` completed successfully but reported physical devices as unavailable, and those devices were not iPhone 12-family hardware.

Device identifiers, serial numbers, UDIDs, hostnames, and personal device names are intentionally omitted from this report.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 31 focused L12 XCTest cases with 0 failures, including `testIOSL12RealDeviceValidationAcceptsDevicectlMarketingNameWithHardwareSuffix`. |
| `swift test` from `ios/` | PASS | Executed 206 XCTest cases with 0 failures. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found an available `iPhone 12` simulator destination. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed; the available iPhone 12 entry is a simulator. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for real-device completion | Command outcome was `success`, but physical devices were unavailable and not connected iPhone 12-family hardware. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Evidence: this report at `ios/docs/reports/stage1-ios-l12-real-device-marketing-model-hardening-20260506-1330.md`.
  - Blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completed the Stage 1 open, render, search, edit, save, and rotate flow in this batch.

Supervisor can mark newly complete from this batch:

- None. This batch hardens the remaining physical-device evidence path and records a current blocker, but it does not complete the physical iPhone 12-family validation row.
