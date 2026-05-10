# Stage 1 iOS L12 Real-Device Validation Probe

- Generated: 2026-05-06 19:29 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family gate; SwiftPM and iPhone 12 simulator prerequisites pass.

## Batch Summary

This bounded batch refreshed the only open iOS-owned Stage 1 checklist item.
No product source changed. The current implementation remains the native
Swift/SwiftUI/UIKit SwiftPM package under `ios/**`.

The physical real-device release gate cannot be closed in this environment
because no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max is
available. Simulator validation remains supporting evidence only and does not
satisfy the real-device gate.

## Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Build completed; 215 XCTest cases executed, 0 failures, 0 unexpected failures, 15.187 seconds. Swift Testing reported 0 tests in 0 suites passed. |
| `xcodebuild -list` from `ios/` | PASS | SwiftPM workspace exposes the `FastMDMobile` scheme. Xcode also logged `Supported platforms for the buildables in the current scheme is empty`; the scheme still resolves and iPhone 12 simulator build/test gates run. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS for simulator inventory | Exact `iPhone 12` simulator destination exists and is shutdown. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`; package built for `arm64-apple-ios14.0-simulator` against the iPhone Simulator 26.4 SDK. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; 215 XCTest cases executed, 1 skipped, 0 failures on the iPhone 12 simulator destination. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical gate | Command outcome was success after a provisioning-parameter warning, but listed only unavailable non-iPhone-12 physical devices: iPhone 15 Pro / `iPhone16,1` and iPad Pro 11-inch 4th generation / `iPad14,4`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical gate | Listed the Mac host, offline non-iPhone-12 physical devices, and an available iPhone 12 simulator. No connected physical iPhone 12-family hardware was available. |

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
- iPhone 12 simulator inventory: PASS.
- iPhone 12 simulator build: PASS.
- iPhone 12 simulator tests: PASS.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical iPhone 12-family device is connected.
- Real-device validation complete: false.

## Supervisor Reconciliation Guidance

The following checklist items remain evidenced as complete by this batch:

- Run iOS iPhone 12 simulator build.
- Run iOS iPhone 12 simulator tests.

The following checklist item must remain open:

- Run iOS iPhone 12-class real-device validation before parity-complete release claim.

Reason: the local machine currently has no connected physical iPhone 12 /
12 mini / 12 Pro / 12 Pro Max. The iPhone 12 simulator is prerequisite evidence
only and does not satisfy the physical-device release gate.
