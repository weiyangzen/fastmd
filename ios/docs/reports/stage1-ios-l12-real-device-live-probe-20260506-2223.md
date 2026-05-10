# Stage 1 iOS L12 Real-Device Live Probe - 2026-05-06 22:23 CST

## Scope

One bounded iOS-only live-lane batch for the remaining iOS-owned L12 platform
validation item.

- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`
- Owned paths touched: `ios/**`
- Android touched: no
- Root `Docs/**` touched: no

The current iOS-owned open checklist item remains:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Batch Result

This batch ran the current iOS SwiftPM gate and refreshed local Apple device
inventory evidence. No Swift implementation change was required because the
current iOS validation contracts already fail closed when only simulator,
offline, unavailable, or non-iPhone-12-family physical devices are present.

The probes did not find a connected physical iPhone 12 / 12 mini / 12 Pro /
12 Pro Max. The real-device Stage 1 flow could not be run, so the L12
real-device checklist item cannot be closed from this batch.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Built the SwiftPM package and executed 218 XCTest cases with 0 failures and 0 unexpected failures in 16.326 seconds of test execution time. Swift Testing reported 0 tests in 0 suites passed. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination. This is simulator evidence only and does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family completion | Probe completed. It listed the Mac host, offline physical iPhone/iPad devices, and simulator destinations including an iPhone 12 simulator. No connected physical iPhone 12-family device was present. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family completion | Command exited 0 after a local provisioning-parameter warning. The physical inventory contained unavailable non-iPhone-12-family hardware only: iPhone 15 Pro / `iPhone16,1` and iPad Pro 11-inch 4th generation / `iPad14,4`. |

## Redacted Device Inventory Summary

Private device identifiers, serial numbers, ECIDs, hostnames, local device names,
and simulator UUIDs are intentionally omitted. The retained fields are limited to
the hardware signal needed for L12 gate status.

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `simctl` | iPhone 12 | available simulator inventory | simulator destination only | no |
| `xctrace` | iPhone | offline physical device | physical device, not connected for validation | no |
| `xctrace` | iPad | offline physical device | physical device, not connected for validation | no |
| `xctrace` | iPhone 12 | available simulator | simulator destination only | no |
| `devicectl` | iPhone | unavailable physical device | iPhone 15 Pro / `iPhone16,1` | no |
| `devicectl` | iPad | unavailable physical device | iPad Pro 11-inch 4th generation / `iPad14,4` | no |

## Gate State

- SwiftPM validation: PASS.
- Required physical probe command coverage: PASS; both `xcrun xctrace list devices`
  and `xcrun devicectl list devices --json-output -` were run.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical
  iPhone 12-family device is connected.
- Real-device validation complete: false.

The L12 physical-device gate remains open. This report is evidence for a fresh
blocked validation attempt and current device availability only; it is not
evidence that the real-device validation item can be closed.

## Supervisor Reconciliation Recommendation

No new iOS blueprint checklist item can be marked complete from this batch.

Keep this blueprint checklist item open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason: the local machine currently has no connected physical iPhone 12 /
12 mini / 12 Pro / 12 Pro Max, so the required real-device open, render, search,
full source edit, block source edit, save, and rotate flow could not be run.
