# Stage 1 iOS L12 Real-Device Live Probe

- Generated: 2026-05-06 20:52 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family gate; local SwiftPM and iPhone 12 simulator build/test validation pass.

## Batch Summary

The earliest still-open iOS-owned checklist item is the physical iPhone 12-family real-device validation gate. This batch reran the local iOS validation and device probes without changing Android or root Docs files.

No Swift implementation change was needed for this batch because the current iOS real-device validation model already fails closed unless all of the following are true:

- SwiftPM tests pass.
- iPhone 12 simulator prerequisites pass.
- Both required physical-device probe sources are recorded.
- A connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max is detected.
- The Stage 1 open, render, search, edit, save, and rotate flow is completed on that same verified hardware after the current probe.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | 216 XCTest cases, 0 failures, 0 unexpected failures, 16.118 seconds. Swift Testing reported 0 tests in 0 suites passed. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | SwiftPM package scheme resolved and `FastMDMobileCore` built for `arm64-apple-ios14.0-simulator`; `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | 216 XCTest cases, 1 skipped, 0 failures, 0 unexpected failures; `** TEST SUCCEEDED **`. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS for simulator inventory only | Available iPhone 12 simulator destination found. This is not physical-device evidence. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family gate | Probe completed and reported the Mac host, offline physical devices, and available simulator destinations. The iPhone 12 entry is simulator-only evidence. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family gate | Probe completed with a provisioning-parameter warning and successful JSON/table output, but listed only unavailable non-iPhone-12-family physical hardware. |

## Device Probe Summary

Raw serial numbers, UDIDs, ECIDs, hostnames, personal identifiers, and local device names are omitted. The retained hardware details are the minimum needed to explain the gate state.

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `xctrace` | Mac host | connected | Mac | no |
| `xctrace` | iPhone | offline | non-iPhone-12-family physical device | no |
| `xctrace` | iPad | offline | iPad physical device | no |
| `xctrace` | iPhone 12 | available simulator | simulator destination only | no |
| `devicectl` | iPhone | unavailable | iPhone 15 Pro / `iPhone16,1` | no |
| `devicectl` | iPad | unavailable | iPad Pro 11-inch 4th generation / `iPad14,4` | no |

## Gate Status

- SwiftPM validation: PASS.
- iPhone 12 simulator build: PASS.
- iPhone 12 simulator tests: PASS.
- Required physical probe command coverage: PASS; both `xctrace` and `devicectl` probes were run.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical iPhone 12-family device is connected.
- Real-device validation complete: false.

## Supervisor Reconciliation Guidance

No new iOS blueprint checklist item can be marked complete from this batch.

The following checklist item must remain open:

- Run iOS iPhone 12-class real-device validation before parity-complete release claim.

Reason: the local machine currently has no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. Simulator validation and fresh physical probes are prerequisite evidence only; they do not satisfy the mandatory physical-device release gate.
