# Stage 1 iOS L12 Devicectl Reality Fail-Closed Batch

- Generated: 2026-05-06 19:35 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family gate; implementation and SwiftPM validation pass.

## Implementation

This batch hardened the iOS real-device validation probe parser in
`ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`.

`IOSDevicectlDeviceListParser` now treats devicectl JSON device records as
physical-device evidence only when `hardwareProperties.reality` explicitly
normalizes to `physical`. Missing or virtual reality values fail closed as
simulator/non-physical candidates even if the record contains an iPhone 12-family
`productType`.

The test suite now covers the fail-closed path with
`testIOSL12DevicectlJSONParserFailsClosedWithoutPhysicalRealityEvidence`.

## Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | 41 selected L12 XCTest cases, 0 failures. |
| `swift test` from `ios/` | PASS | 216 XCTest cases, 0 failures, 0 unexpected failures, 16.122 seconds. Swift Testing reported 0 tests in 0 suites passed. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical gate | Command outcome was success after a provisioning-parameter warning, but listed only unavailable non-iPhone-12 physical devices. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical gate | Listed the Mac host, offline non-iPhone-12 physical devices, and an available iPhone 12 simulator. No connected physical iPhone 12-family hardware was available. |
| `git -C /Users/wangweiyang/GitHub/fastmd diff --check -- ios` | PASS | No whitespace errors in iOS-owned tracked changes. |

## Device Probe Summary

Raw device identifiers, serial numbers, ECIDs, and personal device names are
omitted. The retained hardware details are only the minimum needed to explain
the real-device gate state.

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `devicectl` | iPhone | unavailable | iPhone 15 Pro / `iPhone16,1` | no |
| `devicectl` | iPad | unavailable | iPad Pro 11-inch 4th generation / `iPad14,4` | no |
| `xctrace` | Mac host | connected | Mac | no |
| `xctrace` | iPhone | offline | non-iPhone-12-family physical device | no |
| `xctrace` | iPad | offline | iPad physical device | no |
| `xctrace` | iPhone 12 | available simulator | simulator only | no |

## Gate Status

- SwiftPM validation: PASS.
- Devicectl JSON parser reality fail-closed guard: PASS.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical
  iPhone 12-family device is connected.
- Real-device validation complete: false.

## Supervisor Reconciliation Guidance

The following checklist item must remain open:

- Run iOS iPhone 12-class real-device validation before parity-complete release claim.

Reason: the local machine currently has no connected physical iPhone 12 /
12 mini / 12 Pro / 12 Pro Max. The iPhone 12 simulator is prerequisite evidence
only and does not satisfy the physical-device release gate.
