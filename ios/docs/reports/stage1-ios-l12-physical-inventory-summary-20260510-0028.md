# Stage 1 iOS L12 Physical Inventory Summary

- Generated: 2026-05-10 00:28 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`

## Scope

The daily snapshot leaves one iOS-owned item open: physical iPhone 12-family
real-device validation. This batch keeps that gate fail-closed and improves the
iOS local L12 real-device report with explicit physical iOS inventory counts.

The report now distinguishes:

- physical iOS device records discovered by the probe
- unavailable physical iOS device records
- connected unsupported physical iOS devices
- connected physical iPhone 12-family devices

This prevents a blocker report from being ambiguous when the local host and
simulators are present, but the only physical iOS devices are unavailable or
not iPhone 12-family hardware.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-physical-inventory-summary-20260510-0028.md`

## Implementation Evidence

- Added `IOSStageOneRealDeviceValidationReport.iosPhysicalDeviceRecords`.
- Added `IOSStageOneRealDeviceValidationReport.unavailableIOSPhysicalDeviceRecords`.
- Added report summary lines:
  - `iOS physical device records discovered`
  - `Unavailable iOS physical device records`
- Added `testIOSL12RealDeviceValidationSummarizesUnavailableIOSPhysicalInventory`.
- The regression covers the observed blocker shape: Mac host, unavailable
  non-target physical iOS records, and an iPhone 12 simulator destination.

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationSummarizesUnavailableIOSPhysicalInventory` | `ios/` | PASS | 1 XCTest executed, 0 failures. |
| `swift test` | `ios/` | PASS | 230 XCTest cases executed, 0 failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported for iOS changes. |
| `xcodebuild -list` | `ios/` | PASS | SwiftPM package resolved and exposed scheme `FastMDMobile`. Xcode also emitted `Supported platforms for the buildables in the current scheme is empty`, but scheme discovery succeeded. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical records were `iPhone16,1` / iPhone 15 Pro with unavailable tunnel state and `iPad14,4` / iPad Pro 11-inch 4th generation with available paired state. No physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

## Current Physical Gate Status

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation, exposes the `FastMDMobile`
scheme, and has an iPhone 12 simulator destination. The blueprint still requires
a connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro
Max before any parity-complete release claim.

Because the required physical hardware was absent during this batch, no
physical-device install/test or manual open/render/search/edit/save/rotate flow
was claimed.

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
- L12 iOS physical inventory report hardening.
- L12 iPhone 12 simulator readiness remains available.

Can mark complete from this batch:

- None. This batch improves evidence clarity and refreshes validation, but it
  does not complete physical iPhone 12-family validation.
