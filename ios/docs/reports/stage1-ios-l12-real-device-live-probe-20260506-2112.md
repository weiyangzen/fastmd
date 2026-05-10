# Stage 1 iOS L12 Real-Device Live Probe

- Date: 2026-05-06 21:12 CST
- Worker: FastMD Stage 1 Mobile iOS live lane
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family gate; SwiftPM validation passes, but current probes found no connected eligible physical device.

## Scope

The earliest still-open iOS-owned checklist item remains the physical iPhone
12-family real-device validation gate. This bounded batch reran the smallest
required local iOS validation plus simulator and physical-device probes, then
recorded redacted evidence under `ios/docs/reports/` without editing Android or
root Docs files.

No native Swift source change was needed in this batch. The existing iOS
validation model remains fail-closed: simulator inventory, unavailable devices,
non-iPhone-12-family hardware, and missing manual flow evidence do not complete
the physical gate.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | 216 XCTest cases, 0 failures, 0 unexpected failures, 15.542 seconds total. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS for simulator inventory only | Available iPhone 12 simulator destination found in Shutdown state. This is simulator evidence only, not physical-device evidence. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family gate | Probe completed and listed the Mac host, offline physical iPhone/iPad hardware, and simulator destinations including iPhone 12. The iPhone 12 entry is a simulator destination only. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family gate | Probe completed with a provisioning-parameter warning and successful JSON/table output, but listed only unavailable non-iPhone-12-family physical hardware. |
| `find . -maxdepth 2 \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -print` from `ios/` | BLOCKED for Xcode project/scheme validation in this SwiftPM skeleton | No Xcode project or workspace was found under `ios/`; this batch therefore used SwiftPM validation and device probes only. Existing reconciled simulator build/test evidence remains separate from this physical-device gate. |

## Device Probe Summary

Private device identifiers, serial numbers, hostnames, user device names, and
ECIDs are intentionally not copied into this report. The gate decision is based
only on device class, connection state, simulator/physical reality, and hardware
family signal.

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `simctl` | iPhone 12 | available simulator inventory | simulator destination only | no |
| `xctrace` | iPhone | offline physical device | non-iPhone-12-family physical device | no |
| `xctrace` | iPad | offline physical device | iPad physical device | no |
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
