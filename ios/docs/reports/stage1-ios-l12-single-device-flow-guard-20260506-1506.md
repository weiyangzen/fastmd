# Stage 1 iOS L12 Single-Device Flow Guard - 2026-05-06 15:06 CST

## Scope

Ran one bounded iOS-owned implementation and validation batch for the earliest remaining iOS-owned open checklist row:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-single-device-flow-guard-20260506-1506.md`

## Implementation Notes

- Hardened `IOSStageOneRealDeviceFlowEvidence` so manual flow rows can expose the exact verified iPhone 12-family hardware signals they reference.
- Hardened `IOSStageOneRealDeviceValidationReport` so a passing physical-device claim requires one common verified connected hardware signal across every required Stage 1 manual flow step.
- Added `blockedSplitPhysicalManualFlowEvidence` for the case where all steps reference connected verified iPhone 12-family hardware, but the steps are split across multiple devices instead of one complete physical-device flow.
- Added report markdown evidence for `Manual flow single verified hardware signal complete`.
- Added focused XCTest coverage proving split-device evidence is blocked while a full flow on one verified device still passes.

## Current Local Device Probe

Local probe summary from this batch:

- `xcrun simctl list devices available | rg 'iPhone 12'` lists an available `iPhone 12` simulator destination.
- `xcrun xctrace list devices` lists no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max device.
- `xcrun devicectl list devices --json-output -` returned `outcome: success`, but the physical devices reported were unavailable and not iPhone 12-family hardware.
- The discovered physical product types were `iPhone16,1` and `iPad14,4`; both had unavailable tunnel state.
- Device names, identifiers, serial numbers, ECIDs, hostnames, UDIDs, and full local paths are intentionally omitted from this report.

The available `iPhone 12` entry is a simulator. It cannot satisfy the physical-device validation gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 21 focused real-device validation tests with 0 failures. Includes new split-device guard coverage. |
| `swift test` from `ios/` | PASS | Executed 212 XCTest cases with 0 failures. Includes canonical fixture matrix coverage, L11/L12 validation models, and the new L12 single-device flow guard. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found an available `iPhone 12` simulator destination. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family validation | No connected physical iPhone 12-family device was listed; the iPhone 12 entry is under simulators. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation | Command outcome was success, but no connected `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` physical product type was present. |

## Current L12 Result

The L12 physical-device validation gate remains open.

The local environment can validate SwiftPM tests and can see an iPhone 12 simulator destination, but the blueprint requires a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completing the Stage 1 open, render, search, full source edit, block source edit, save, and rotate flow before any parity-complete release claim.

| Required real-device flow | Result |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Checklist Evidence

Supervisor should keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-single-device-flow-guard-20260506-1506.md`

## Completion Claim

None.

This batch advances and hardens the remaining iOS L12 physical-device evidence path, but it does not complete physical iPhone 12-family validation because no connected eligible physical device completed the full Stage 1 manual flow.
