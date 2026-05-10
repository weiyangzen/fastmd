# Stage 1 iOS L12 Live Validation Batch - 2026-05-06 21:23 CST

## Scope

One bounded iOS-only live-lane batch for the remaining iOS-owned L12
validation surface.

- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`
- Owned paths touched: `ios/docs/reports/**`
- Android touched: no
- Root Docs touched: no

The current open iOS-owned blueprint item is:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch refreshed the local SwiftPM, iPhone 12 simulator, and physical-device
probe evidence. Simulator validation passes. The physical iPhone 12-family gate
remains blocked because no connected physical iPhone 12 / 12 mini / 12 Pro /
12 Pro Max device was available.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Built the SwiftPM package and executed 216 XCTest cases with 0 failures and 0 unexpected failures in 15.614 seconds. Swift Testing reported 0 tests in 0 suites passed. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Xcode resolved the SwiftPM package and reported `** BUILD SUCCEEDED **` for the iPhone 12 simulator destination. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Xcode ran the iPhone 12 simulator test bundle and reported `** TEST SUCCEEDED **`; 216 XCTest cases executed with 1 skipped and 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12' \|\| true` from `ios/` | PASS for simulator inventory only | Found an available `iPhone 12` simulator in Shutdown state. This is simulator evidence only and does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family completion | Probe completed. It listed the Mac host, offline physical devices, and simulator destinations including iPhone 12. The iPhone 12 entry was under simulators only. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family completion | Command exited 0 after the local provisioning-parameter warning. The physical inventory contained only unavailable non-iPhone-12-family hardware: iPhone 15 Pro class and iPad Pro 11-inch 4th generation class. |

## Redacted Device Inventory Summary

Raw device names, hostnames, serials, ECIDs, UDIDs, and local identifiers are
intentionally omitted. The retained hardware details are only the minimum needed
to explain the L12 gate state.

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `simctl` | iPhone 12 | available simulator inventory | simulator destination only | no |
| `xctrace` | Mac host | connected | host Mac, not iOS device | no |
| `xctrace` | iPhone physical | offline | not iPhone 12 family | no |
| `xctrace` | iPad physical | offline | iPad, not iPhone 12 family | no |
| `xctrace` | iPhone 12 | available simulator | simulator destination only | no |
| `devicectl` | iPhone 15 Pro class | unavailable | `iPhone16,1` / D83AP class | no |
| `devicectl` | iPad Pro 11-inch 4th generation class | unavailable | `iPad14,4` / J618AP class | no |

## Gate State

- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical
  iPhone 12-family device is connected.
- Real-device validation complete: false.
- Simulator build/test prerequisites: pass.
- SwiftPM validation: pass.

The L12 physical-device gate remains open. This report is completion evidence
for a refreshed validation attempt and blocker record only; it is not evidence
that the real-device validation item can be closed.

## Supervisor Reconciliation Recommendation

Do not mark the following blueprint item complete from this batch:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason: the local machine currently has no connected physical iPhone 12 /
12 mini / 12 Pro / 12 Pro Max, so the required real-device open, render, search,
full source edit, block source edit, save, and rotate flow could not be run.

