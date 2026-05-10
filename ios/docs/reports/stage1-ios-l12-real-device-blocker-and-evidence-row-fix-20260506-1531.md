# Stage 1 iOS L12 Real-Device Validation Batch

- Generated: 2026-05-06T07:31:37Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Blueprint item: L12 - Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- Result: BLOCKED for the physical iPhone 12-family gate; simulator and SwiftPM prerequisites pass.

## Implementation

This batch fixed the iOS L12 real-device report evidence-row precedence in
`ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`.

Before the fix, stale or future-dated manual-flow evidence that also predated the
current device probe could be rendered as `PRE-PROBE` in the report table. The
gate status already blocked as stale, but the row-level evidence was ambiguous.
The report now renders stale/future evidence as `STALE` before applying the
post-probe check, so the row output matches the blocking reason.

## Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRequiresCurrentManualFlowEvidence` from `ios/` | PASS | 1 selected test, 0 failures. |
| `swift test` from `ios/` after the fix | PASS | 213 tests, 0 failures. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`; SwiftPM package built for the iPhone 12 simulator destination. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` after serial rerun | PASS | `** TEST SUCCEEDED **`; 213 tests, 1 skipped, 0 failures on iPhone 12 simulator destination. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS for simulator inventory | Exact iPhone 12 simulator destination exists and is shutdown. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical gate | Command outcome was success, but listed only unavailable physical devices: iPhone 15 Pro / `iPhone16,1` and iPad Pro 11-inch 4th generation / `iPad14,4`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical gate | Listed the Mac host, offline non-iPhone-12 physical devices, and an available iPhone 12 simulator; no connected physical iPhone 12-family hardware. |
| `git -C . diff --check -- ios` from repo root | PASS | No whitespace errors in iOS-owned changes. |

## Device Probe Summary

Raw device identifiers and personal device names are intentionally omitted.

| Probe source | Physical device class | Connection state | Hardware family | Eligible for iPhone 12 real-device gate |
| --- | --- | --- | --- | --- |
| `devicectl` | iPhone | unavailable | iPhone 15 Pro / `iPhone16,1` | no |
| `devicectl` | iPad | unavailable | iPad Pro 11-inch 4th generation / `iPad14,4` | no |
| `xctrace` | Mac host | connected | Mac | no |
| `xctrace` | iPhone | offline | non-iPhone-12-family physical device | no |
| `xctrace` | iPad | offline | iPad physical device | no |
| `xctrace` | iPhone 12 simulator | available simulator | simulator only | no |

## Gate Status

- SwiftPM validation: PASS.
- iPhone 12 simulator build: PASS.
- iPhone 12 simulator tests: PASS.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max: none found.
- Manual real-device Stage 1 flow evidence: not run because no eligible physical iPhone 12-family device is connected.
- Real-device validation complete: false.

## Supervisor Reconciliation Guidance

The following existing checklist items remain evidenced as complete by this batch:

- Run iOS iPhone 12 simulator build.
- Run iOS iPhone 12 simulator tests.

The following checklist item must remain open:

- Run iOS iPhone 12-class real-device validation before parity-complete release claim.

Reason: the local machine currently has no connected physical iPhone 12 / 12 mini
/ 12 Pro / 12 Pro Max. The simulator is useful prerequisite evidence, but it does
not satisfy the physical-device release gate.
