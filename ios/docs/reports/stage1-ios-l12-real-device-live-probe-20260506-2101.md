# Stage 1 iOS L12 Real-Device Live Probe

- Generated: 2026-05-06 21:01 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family gate; SwiftPM validation passes and current probes found no connected eligible physical device.

## Batch Summary

The earliest still-open iOS-owned checklist item is the physical iPhone 12-family real-device validation gate. This batch reran the smallest local iOS validation plus current simulator and physical-device probes, then recorded the result under `ios/docs/reports/` without editing Android or root Docs files.

No native Swift implementation change was needed in this batch. The existing iOS validation model remains fail-closed: simulator evidence, unavailable devices, non-iPhone-12-family hardware, and missing manual flow evidence do not complete the physical gate.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Build completed, then 216 XCTest cases ran with 0 failures and 0 unexpected failures in 15.810 seconds. Swift Testing reported 0 tests in 0 suites passed. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS for simulator inventory only | Available iPhone 12 simulator destination found in Shutdown state. This is simulator inventory evidence only, not physical-device evidence. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family gate | Probe completed and reported the Mac host, two offline physical devices, and available simulator destinations. The iPhone 12 entry is a simulator destination only. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family gate | Probe completed with a provisioning-parameter warning and successful JSON/table output, but listed only unavailable non-iPhone-12-family physical hardware. |

## Device Probe Summary

Raw serial numbers, UDIDs, ECIDs, hostnames, local device names, and personal identifiers are omitted. The retained details are the minimum needed to explain the gate state.

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `simctl` | iPhone 12 | available simulator inventory | simulator destination only | no |
| `xctrace` | Mac host | connected | Mac | no |
| `xctrace` | iPhone | offline | non-iPhone-12-family physical device | no |
| `xctrace` | iPad | offline | iPad physical device | no |
| `xctrace` | iPhone 12 | available simulator | simulator destination only | no |
| `devicectl` | iPhone | unavailable | iPhone 15 Pro / `iPhone16,1` | no |
| `devicectl` | iPad | unavailable | iPad Pro 11-inch 4th generation / `iPad14,4` | no |

## Gate Status

- SwiftPM validation: PASS.
- Required physical probe command coverage: PASS; both `xcrun xctrace list devices` and `xcrun devicectl list devices --json-output -` were run.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical iPhone 12-family device is connected.
- Real-device validation complete: false.

## Supervisor Reconciliation Guidance

No new iOS blueprint checklist item can be marked complete from this batch.

The following checklist item must remain open:

- Run iOS iPhone 12-class real-device validation before parity-complete release claim.

Reason: the local machine currently has no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. Simulator inventory and fresh physical-device probes are prerequisite evidence only; they do not satisfy the mandatory physical-device release gate.
