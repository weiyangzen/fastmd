# Stage 1 iOS L12 Real-Device Validation Probe

- Generated: 2026-05-06T07:57:50Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family gate; SwiftPM and iPhone 12 simulator prerequisites pass.

## Batch Summary

This bounded batch advanced the only open iOS-owned Stage 1 item by rerunning the
current local validation and physical-device availability probes.

No product code changed in this batch. The implementation surface is already
native Swift/SwiftUI/UIKit in `ios/**`; this batch records fresh platform gate
evidence only.

## Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | 214 tests, 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS for simulator inventory | Exact `iPhone 12` simulator destination exists and is shutdown. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`; SwiftPM package built for the iPhone 12 simulator destination. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; 214 tests, 1 skipped, 0 failures on the iPhone 12 simulator destination. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical gate | Command outcome was success, but listed only unavailable physical devices: a non-iPhone-12-family iPhone and an iPad. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical gate | Listed the Mac host, offline non-iPhone-12 physical devices, and an available iPhone 12 simulator; no connected physical iPhone 12-family hardware. |

## Device Probe Summary

Raw device identifiers, serial numbers, and personal device names are omitted.

| Probe source | Physical device class | Connection state | Hardware family | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `devicectl` | iPhone | unavailable | iPhone 15 Pro / `iPhone16,1` | no |
| `devicectl` | iPad | unavailable | iPad Pro 11-inch 4th generation / `iPad14,4` | no |
| `xctrace` | Mac host | connected | Mac | no |
| `xctrace` | iPhone | offline | non-iPhone-12-family physical device | no |
| `xctrace` | iPad | offline | iPad physical device | no |
| `xctrace` | iPhone 12 simulator | available simulator | simulator only | no |

## Gate Status

- SwiftPM validation: PASS.
- iPhone 12 simulator build: PASS.
- iPhone 12 simulator tests: PASS.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical iPhone 12-family device is connected.
- Real-device validation complete: false.

## Supervisor Reconciliation Guidance

The following existing checklist items remain evidenced as complete by this batch:

- Run iOS iPhone 12 simulator build.
- Run iOS iPhone 12 simulator tests.

The following checklist item must remain open:

- Run iOS iPhone 12-class real-device validation before parity-complete release claim.

Reason: the local machine currently has no connected physical iPhone 12 / 12 mini
/ 12 Pro / 12 Pro Max. The simulator is prerequisite evidence only and does not
satisfy the physical-device release gate.
