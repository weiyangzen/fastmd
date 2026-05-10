# Stage 1 iOS L12 Real-Device Verified Hardware Guard - 2026-05-06 13:51 CST

## Scope

This bounded iOS live-lane batch targeted the earliest remaining iOS-owned open checklist item:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No Android files, root `Docs/**` checklist files, or `.cron/**` files were edited.

## Implementation

- Hardened `IOSStageOneRealDeviceValidationReport` so a real-device completion claim now requires verified iPhone 12-family hardware evidence from a hardware model or product identifier, not only a device display name observed by `xcrun xctrace list devices`.
- Added `blockedMissingVerifiedHardwareEvidence` as a distinct L12 blocker state for name-only connected iPhone 12-family candidates.
- Added `verifiedEligibleConnectedDevices` and `hasVerifiedIPhone12FamilyHardwareEvidence` so reports distinguish:
  - connected candidates that look like iPhone 12-family devices by name, and
  - connected candidates verified by hardware model/product identifier such as `iPhone13,1` through `iPhone13,4` or exact iPhone 12-family marketing names from device-control metadata.
- Expanded the generated real-device report table with a `Verified iPhone 12-family hardware evidence` column.
- Added XCTest coverage proving name-only xctrace candidates stay blocked even when SwiftPM, simulator prerequisites, and manual flow evidence are otherwise complete.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-verified-hardware-guard-20260506-1351.md`

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 32 selected L12 XCTest cases with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 207 XCTest cases with 0 failures. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | SwiftPM-generated Xcode scheme built `FastMDMobileCore` for the iPhone 12 simulator destination. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | The local simulator inventory includes an available `iPhone 12` simulator destination. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family validation | Connected physical devices listed: local Mac only. Physical iOS devices were listed under the offline section; no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max hardware was present. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation | Command outcome was `success`, but discovered physical iOS devices were unavailable and were not iPhone 12-family hardware. No connected verified `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` device was available for the required manual flow. |

## Blocker

The L12 physical-device validation gate remains open.

The local environment has an iPhone 12 simulator destination and the SwiftPM validation suite passes, but the blueprint requires a connected physical iPhone 12-family device before any parity-complete release claim. This batch strengthens that gate by preventing a name-only xctrace device candidate from completing the checklist without verified hardware evidence from device-control metadata.

Required physical-device flow still open:

- Open Markdown.
- Render the rich fixture.
- Search the document.
- Edit full source.
- Edit block source.
- Save a writable document.
- Rotate the reader.

## Checklist Reconciliation

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Supervisor can mark newly complete from this batch:

- None. This batch adds implementation hardening and current validation evidence, but it does not complete the physical iPhone 12-family validation row.

Evidence path:

- `ios/docs/reports/stage1-ios-l12-real-device-verified-hardware-guard-20260506-1351.md`
