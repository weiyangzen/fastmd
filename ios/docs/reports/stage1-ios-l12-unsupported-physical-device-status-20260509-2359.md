# Stage 1 iOS L12 Unsupported Physical Device Status

- Generated: 2026-05-09 23:59:17 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`

## Scope

The daily snapshot leaves one iOS-owned item open: physical iPhone 12-family
real-device validation. This batch keeps the gate fail-closed and improves the
iOS local evidence model so the real-device report can distinguish:

- no connected iPhone 12-family physical device in the probe output
- connected physical iOS hardware exists, but it is not iPhone 12 / 12 mini /
  12 Pro / 12 Pro Max hardware
- connected iPhone 12-family hardware exists but lacks verified model evidence

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-unsupported-physical-device-status-20260509-2359.md`

## Implementation Evidence

- Added `IOSStageOneRealDeviceValidationStatus.blockedConnectedUnsupportedPhysicalDevice`.
- Added `IOSStageOneRealDeviceValidationReport.connectedUnsupportedPhysicalDevices`.
- The new unsupported-device status requires a connected, non-simulator physical
  iOS hardware-model signal such as `iPhone`, `iPad`, or `iPod`; the Mac host
  from `xcrun xctrace list devices` does not trigger this status.
- `capturesRealDeviceGateEvidence` now accepts the unsupported physical iOS
  device blocker as valid blocker evidence, without completing the real-device
  gate.
- The report markdown now includes `Connected unsupported physical devices`.
- XCTest coverage was updated for a connected non-iPhone-12 physical iOS
  hardware identifier (`iPhone14,2`) and preserves existing no-device behavior
  for Mac-only / simulator-only probe output.

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 52 XCTest cases executed with 0 failures after the status refinement. An earlier run in this batch failed 5 assertions while the new status incorrectly counted the Mac host; the implementation was tightened and rerun successfully. |
| `swift test` | `ios/` | PASS | 227 XCTest cases executed with 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found available simulator destination: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. This is simulator evidence only and does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical records were unavailable non-iPhone-12-family hardware: iPhone 15 Pro class / `iPhone16,1` and iPad Pro 11-inch 4th generation class / `iPad14,4`. No connected physical iPhone 12-family device was present. |

## Current Physical Gate Status

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation and iPhone 12 simulator
inventory checks, but the blueprint requires a connected physical iPhone 12,
iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max before any parity-complete
release claim. No connected physical iPhone 12-family device was available
during this batch.

Because the required physical device was absent, no physical-device install/test
or manual open/render/search/edit/save/rotate flow was claimed.

## Required Physical Flow Still Open

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Checklist Recommendation

Keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Items this batch can support as evidence, but not newly close:

- L12 current iOS blocker evidence for the physical real-device gate.
- L12 iOS physical-device probe reporting hardening for connected unsupported
  iOS hardware.

Can mark complete from this batch:

- None. This batch improves the local iOS physical-device blocker model and
  refreshes current validation evidence, but it does not complete physical
  iPhone 12-family validation.
