# Stage 1 iOS L12 Real-Device Live Probe

- Date: 2026-05-06 21:34 CST
- Worker: FastMD Stage 1 Mobile iOS live lane
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family gate; SwiftPM validation passes, but fresh probes found no connected eligible physical iPhone 12-family device.

## Scope

The earliest still-open iOS-owned checklist item remains the physical iPhone
12-family real-device validation gate. This bounded batch reran the smallest
real iOS validation supported by the current SwiftPM skeleton and refreshed
the local simulator, `xctrace`, and `devicectl` device probes.

No Swift source change was needed in this batch. The existing iOS validation
contracts already fail closed for simulator-only evidence, stale or unavailable
physical devices, non-iPhone-12-family hardware, missing probe commands, and
missing manual Stage 1 flow evidence.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Build completed and 216 XCTest cases passed with 0 failures and 0 unexpected failures in 16.091 seconds of test execution time. |
| `xcrun simctl list devices available` from `ios/` | PASS for simulator inventory only | Available iPhone 12 simulator destination found under iOS 26.4 in Shutdown state. This is simulator evidence only and does not satisfy the physical real-device gate. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family gate | Probe completed and listed the Mac host, offline physical iPhone/iPad devices, and simulator destinations including an iPhone 12 simulator. No connected physical iPhone 12-family device was present. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family gate | Probe completed with a provisioning-parameter warning and successful JSON/table output, but listed only unavailable physical devices: iPhone 15 Pro / `iPhone16,1` and iPad Pro 11-inch 4th generation / `iPad14,4`. |
| `find . -maxdepth 2 \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -print` from `ios/` | BLOCKED for Xcode project/scheme validation in this SwiftPM skeleton | No Xcode project or workspace was found under `ios/`; this batch therefore used SwiftPM validation and device probes only. Existing reconciled simulator build/test evidence remains separate from this physical-device gate. |

## Device Probe Summary

Private device identifiers, serial numbers, hostnames, user device names, ECIDs,
and simulator UUIDs are intentionally not copied into this report. The gate
decision uses only device class, connection state, simulator/physical reality,
and bounded hardware-family signals.

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `simctl` | iPhone 12 | available simulator inventory | simulator destination only | no |
| `xctrace` | iPhone | offline physical device | physical device, not connected for validation | no |
| `xctrace` | iPad | offline physical device | physical device, not connected for validation | no |
| `xctrace` | iPhone 12 | available simulator | simulator destination only | no |
| `devicectl` | iPhone | unavailable physical device | iPhone 15 Pro / `iPhone16,1` | no |
| `devicectl` | iPad | unavailable physical device | iPad Pro 11-inch 4th generation / `iPad14,4` | no |

## Gate Decision

- SwiftPM validation: PASS.
- Required physical probe command coverage: PASS; both `xcrun xctrace list devices` and `xcrun devicectl list devices --json-output -` were run.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical iPhone 12-family device is connected.
- Real-device validation complete: false.

## Supervisor Checklist Recommendation

No new iOS blueprint checklist item can be marked complete from this batch.

Keep this blueprint checklist item open:

- Run iOS iPhone 12-class real-device validation before parity-complete release claim.

Reason: the local machine currently has no connected physical iPhone 12 /
12 mini / 12 Pro / 12 Pro Max. Simulator inventory and fresh physical-device
probes are prerequisite evidence only; they do not satisfy the mandatory
physical-device release gate.
