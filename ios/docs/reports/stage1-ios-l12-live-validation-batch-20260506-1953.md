# Stage 1 iOS L12 Live Validation Batch - 2026-05-06 19:53 CST

## Scope

One bounded iOS-only live-lane batch for the remaining iOS-owned L12 validation surface.

Authoritative inputs read:

- `Docs/Stage1_Mobile_Blueprint.md`
- `Docs/todos_20260506.md`

Files changed by this batch:

- `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260506-1953.md`

No Android files, shared Docs checklists, or cron files were edited.

## Batch Selection

The daily todo snapshot shows the iOS implementation clusters through L11 complete, with only this iOS-owned L12 item still open:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch revalidated the SwiftPM gate and refreshed the physical-device inventory probes. The physical iPhone 12-family validation gate remains blocked because no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 216 XCTest cases with 0 failures and 0 unexpected failures in 15.289 seconds. Includes the canonical fixture matrix, native renderer coverage, L11 validation gates, and L12 real-device guard tests. Swift Testing reported 0 tests in 0 suites passed. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family completion | Command outcome was success after the local provisioning-parameter warning. The inventory contained only unavailable non-iPhone-12-family physical devices: one `iPhone16,1` and one `iPad14,4`. Device names, hostnames, serials, ECIDs, UDIDs, and local identifiers are intentionally omitted. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family completion | Connected devices listed the Mac host only. Physical iOS-family devices were offline and not iPhone 12-family hardware. The available `iPhone 12` entry appeared under simulators only. |
| `xcrun simctl list devices 'iOS' available` from repo root | PASS for simulator inventory only | Current CoreSimulator inventory includes an available `iPhone 12` simulator under iOS 26.4. This is prerequisite/simulator evidence only and does not satisfy the physical-device release gate. |

## Device Probe Summary

Raw device names and unique identifiers are redacted. The retained hardware details are only the minimum needed to explain the L12 gate state.

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `devicectl` | iPhone | unavailable | `iPhone16,1` / iPhone 15 Pro | no |
| `devicectl` | iPad | unavailable | `iPad14,4` / iPad Pro 11-inch 4th generation | no |
| `xctrace` | Mac host | connected | Mac | no |
| `xctrace` | iPhone | offline | non-iPhone-12-family physical device | no |
| `xctrace` | iPad | offline | iPad physical device | no |
| `xctrace` | iPhone 12 | available simulator | simulator only | no |

## Real-Device Gate Status

The L12 physical-device gate remains open.

Reasons:

- No connected physical `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` hardware signal was available in `devicectl`.
- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max appeared in `xctrace`.
- The available `iPhone 12` is a simulator destination and cannot satisfy the blueprint's real-device validation requirement.
- The required manual Stage 1 flow was not run on physical iPhone 12-family hardware in this batch: open Markdown, render canonical rich fixture, search, full source edit, block source edit, save writable document, and rotate reader.

## Checklist Evidence

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Evidence path: `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260506-1953.md`
  - Blocker: no connected eligible physical iPhone 12-family device is available to run the full Stage 1 manual validation flow.

No newly open iOS checklist item can be marked complete from this batch.
