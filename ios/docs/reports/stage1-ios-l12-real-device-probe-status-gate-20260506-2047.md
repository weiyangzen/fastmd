# Stage 1 iOS L12 Real-Device Probe Status Gate

- Generated: 2026-05-06 20:47 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family gate; implementation and SwiftPM validation pass.

## Implementation

This batch tightened the iOS L12 real-device validation model in:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

`IOSStageOneRealDeviceValidationReport.status` now fails closed with
`blockedMissingRequiredProbeCommands` when a current real-device report does not
record both required physical-device probe sources:

- `xcrun xctrace list devices`
- `xcrun devicectl list devices --json-output -`

Before this batch, `completesRequiredRealDeviceValidation` already required both
commands, but the top-level `status` could still report `passed` for synthetic
full-flow evidence with only partial probe command coverage. The status and
blocker summary now match the checklist gate.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | 41 selected XCTest cases, 0 failures, 0 unexpected failures, 3.007 seconds. |
| `swift test` from `ios/` | PASS | 216 XCTest cases, 0 failures, 0 unexpected failures, 15.324 seconds. Swift Testing reported 0 tests in 0 suites passed. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family gate | Command outcome was success after a provisioning-parameter warning, but listed only unavailable non-iPhone-12-family physical hardware. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family gate | Listed the Mac host, offline physical devices, and an available iPhone 12 simulator destination. The iPhone 12 entry is simulator-only evidence. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors reported for iOS-owned changes. |

## Device Probe Summary

Raw device identifiers, serial numbers, ECIDs, personal device names, and UDIDs
are omitted. The retained hardware details are the minimum needed to explain why
the physical-device gate remains open.

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `devicectl` | iPhone | unavailable | iPhone 15 Pro / `iPhone16,1` | no |
| `devicectl` | iPad | unavailable | iPad Pro 11-inch 4th generation / `iPad14,4` | no |
| `xctrace` | Mac host | connected | Mac | no |
| `xctrace` | iPhone | offline | non-iPhone-12-family physical device | no |
| `xctrace` | iPad | offline | iPad physical device | no |
| `xctrace` | iPhone 12 | available simulator | simulator destination only | no |

## Gate Status

- SwiftPM validation: PASS.
- L12 real-device evidence model tests: PASS.
- Required physical probe command coverage: PASS for this batch; both `xctrace` and `devicectl` probes were run.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical iPhone 12-family device is connected.
- Real-device validation complete: false.

## Supervisor Reconciliation Guidance

No new iOS blueprint checklist item can be marked complete from this batch.

The following checklist item must remain open:

- Run iOS iPhone 12-class real-device validation before parity-complete release claim.

Reason: the local machine currently has no connected physical iPhone 12 /
12 mini / 12 Pro / 12 Pro Max. Simulator validation and fresh physical probes
are prerequisite evidence only; they do not satisfy the mandatory physical-device
release gate.
