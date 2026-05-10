# Stage 1 iOS L12 Real-Device Marketing Prefix Hardening - 2026-05-06 22:33 CST

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

## Implementation

This batch hardened `IOSStageOneRealDeviceFlowEvidence` hardware-signal matching
for real-device manual-flow evidence.

Before this batch, a verified marketing-name signal such as `iPhone 12 Pro`
could match manual evidence that referenced `iPhone 12 Pro Max`, because the
matcher only required a non-alphanumeric boundary after `Pro`. The report now
rejects that prefix continuation and only accepts the exact verified marketing
model or hardware identifier for the connected iPhone 12-family candidate.

Regression coverage was added for:

- connected verified `iPhone 12 Pro` marketing-name evidence;
- manual evidence that incorrectly references `iPhone 12 Pro Max`;
- exact `iPhone 12 Pro` manual evidence still passing when all other L12 gates
  are satisfied.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Built the SwiftPM package and executed 44 selected XCTest cases with 0 failures and 0 unexpected failures in 2.927 seconds of test execution time. |
| `swift test` from `ios/` | PASS | Built the SwiftPM package and executed 219 XCTest cases with 0 failures and 0 unexpected failures in 15.638 seconds of test execution time. Swift Testing reported 0 tests in 0 suites passed. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination. This is simulator evidence only and does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family completion | Probe completed. It listed the Mac host, offline physical iPhone/iPad devices, and simulator destinations including an iPhone 12 simulator. No connected physical iPhone 12-family device was present. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family completion | Command exited 0 after a local provisioning-parameter warning. The physical inventory contained unavailable non-iPhone-12-family hardware only: iPhone 15 Pro / `iPhone16,1` and iPad Pro 11-inch 4th generation / `iPad14,4`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors were reported for tracked iOS diffs. Note: the local repository currently reports `ios/` as untracked, so this command cannot inspect untracked iOS file content. |

## Redacted Device Inventory Summary

Private device identifiers, serial numbers, ECIDs, local device names, hostnames,
and simulator UUIDs are intentionally omitted. The retained fields are limited
to the hardware signal needed for L12 gate status.

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
- L12 real-device validation contract tests: PASS.
- Required physical probe command coverage: PASS; both `xcrun xctrace list devices`
  and `xcrun devicectl list devices --json-output -` were run.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical
  iPhone 12-family device is connected.
- Real-device validation complete: false.

The L12 physical-device gate remains open. This report is evidence for
implementation hardening plus a fresh blocked validation attempt and current
device availability only; it is not evidence that the real-device validation
item can be closed.

## Supervisor Reconciliation Recommendation

No new iOS blueprint checklist item can be marked complete from this batch.

Keep this blueprint checklist item open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason: the local machine currently has no connected physical iPhone 12 /
12 mini / 12 Pro / 12 Pro Max, so the required real-device open, render, search,
full source edit, block source edit, save, and rotate flow could not be run.
