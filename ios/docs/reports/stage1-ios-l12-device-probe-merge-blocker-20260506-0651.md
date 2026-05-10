# Stage 1 iOS L12 Device Probe Merge And Real-Device Blocker - 2026-05-06 06:51 +0800

## Scope

Ran one bounded iOS-owned implementation batch for the first still-open iOS validation gate:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch stayed under `ios/**`. It did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-device-probe-merge-blocker-20260506-0651.md`

## Implementation

Added native Swift real-device probe evidence support:

- `IOSStageOneDeviceProbeCandidateMerger`

The merger combines parsed `xcrun xctrace list devices` and `xcrun devicectl list devices --json-output -` candidates so L12 reports can keep OS/version evidence from `xctrace` and hardware model evidence from `devicectl` without duplicate device rows.

Merge rules:

- preserve probe order;
- merge exact identifier matches;
- merge same-name candidates only when simulator/physical status matches;
- preserve the first display name and identifier;
- fill missing OS version and hardware model from later probes;
- treat a device as connected if any merged probe reports it connected.

Added XCTest coverage:

- `testIOSL12DeviceProbeCandidateMergerCombinesXctraceAndDevicectlEvidence`

## Current Physical Device Probe

Commands run from the repository root:

| Command | Result | Evidence |
| --- | --- | --- |
| `xcrun xctrace list devices` | PASS command | Connected physical device list contained only `Mac`; `Turbulence (26.1)` and `王威扬的iPad (26.3.1)` appeared under offline devices; `iPhone 12 (26.4.1)` appeared only under simulators. |
| `xcrun devicectl list devices --json-output -` | PASS command with non-fatal provisioning warning | Listed `Turbulence` as unavailable `iPhone 15 Pro (iPhone16,1)` and `王威扬的iPad` as unavailable `iPad Pro (11-inch) (4th generation) (iPad14,4)`. |

Identifiers, UDIDs, ECIDs, and serial numbers are intentionally omitted from this report. The completion blocker is device class and connection state, not preservation of private hardware identifiers.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DeviceProbeCandidateMerger` from `ios/` | PASS | Built successfully and executed 1 selected XCTest with 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 15 selected real-device validation/report XTests with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 177 XCTest cases with 0 failures. |

## Checklist Evidence

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- The current machine exposes no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max device.
- The available iPhone 12 simulator has prior passing validation evidence, but simulator validation cannot complete the physical real-device gate.

Supervisor can use this report as fresh blocker evidence and as implementation evidence for more reliable L12 physical-device probe reporting, not as completion evidence for the real-device validation gate.
