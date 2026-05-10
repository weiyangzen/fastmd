# Stage 1 iOS L12 Real-Device Validation Batch

Date: 2026-05-06 20:00 Asia/Shanghai

## Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family release gate; SwiftPM and iPhone 12 simulator validation passed.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | 216 XCTest cases executed, 0 failures, 0 unexpected failures, 15.024 seconds. Swift Testing reported 0 tests in 0 suites passed. |
| `xcodebuild -list` from `ios/` | PASS | SwiftPM exposed generated workspace `ios` with scheme `FastMDMobile`. The command emitted `Supported platforms for the buildables in the current scheme is empty`, but exited successfully. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build used `iPhoneSimulator26.4.sdk`, target triple `arm64-apple-ios14.0-simulator`, and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | 216 XCTest cases executed on the iPhone 12 simulator destination, 1 skipped, 0 failures, 0 unexpected failures, and ended with `** TEST SUCCEEDED **`. Result bundle: `~/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_19-58-38-+0800.xcresult`. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family gate | Command outcome was success after a provisioning-parameter warning, but listed only unavailable physical non-iPhone-12-family hardware: one iPhone 15 Pro and one iPad Pro. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family gate | Listed the Mac host, two offline physical devices, and an iPhone 12 simulator. The available iPhone 12 entry is simulator evidence only and does not satisfy the real-device release gate. |

## Device Probe Summary

| Probe source | Device class | Connection state | Hardware signal | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `devicectl` | iPhone | unavailable | physical iPhone 15 Pro / `iPhone16,1` | no |
| `devicectl` | iPad | unavailable | physical iPad Pro / `iPad14,4` | no |
| `xctrace` | iPhone | offline | physical non-iPhone-12-family device | no |
| `xctrace` | iPad | offline | physical iPad device | no |
| `xctrace` | iPhone 12 | simulator | iPhone 12 simulator destination | no |

## Gate Decision

- SwiftPM validation prerequisite: PASS.
- iPhone 12 simulator build prerequisite: PASS.
- iPhone 12 simulator test prerequisite: PASS.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual Stage 1 real-device flow evidence: not run because no connected eligible physical iPhone 12-family device is available.

The L12 real-device checklist item must remain open:

- Run iOS iPhone 12-class real-device validation before parity-complete release claim.

Reason: the local machine currently has no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. Simulator validation is useful prerequisite evidence but does not satisfy the mandatory physical-device release gate.

## Supervisor Reconciliation

No new open iOS blueprint checklist item can be marked complete from this batch. This report refreshes evidence for the current blocker and confirms that the iOS simulator and SwiftPM gates remain passing while the physical iPhone 12-family validation gate is blocked by unavailable hardware.
