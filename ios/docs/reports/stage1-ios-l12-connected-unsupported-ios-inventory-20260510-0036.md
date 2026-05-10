# Stage 1 iOS L12 Connected Unsupported iOS Inventory

- Generated: 2026-05-10 00:36 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Scope

The daily snapshot keeps one iOS-owned row open: physical iPhone 12-family
real-device validation. This batch keeps that gate fail-closed and tightens the
iOS L12 blocker report so connected unsupported physical iOS hardware is
reported explicitly, separate from unavailable iOS records and non-iOS host
records.

No Android files, root `Docs/**` files, `.cron/**` files, renderer assets,
entitlements, privacy manifests, or WebKit surfaces were edited.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-connected-unsupported-ios-inventory-20260510-0036.md`

## Implementation Evidence

- Added `IOSStageOneRealDeviceValidationReport.connectedUnsupportedIOSPhysicalDeviceRecords`.
- Kept `connectedUnsupportedPhysicalDevices` as a compatibility alias for the same fail-closed iOS-only subset.
- Added a generated report summary line: `Connected unsupported iOS physical device records`.
- Extended the existing unavailable physical inventory regression to assert the new count remains zero when all physical iOS records are unavailable.
- Added `testIOSL12RealDeviceValidationSummarizesConnectedUnsupportedIOSPhysicalInventory` to cover the current blocker shape: host Mac record, connected non-iPhone-12 iOS hardware, and an iPhone 12 simulator destination.

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationSummarizesConnectedUnsupportedIOSPhysicalInventory` | `ios/` | PASS | Built the SwiftPM package and executed 1 focused XCTest with 0 failures. |
| `swift test` | `ios/` | PASS | Executed 231 XCTest cases with 0 failures and 0 unexpected failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found an available iPhone 12 simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. The physical inventory contained one unavailable iPhone 15 Pro-class record and one connected/paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local user paths, and
simulator identifiers are intentionally omitted from this report. Retained
hardware signals are limited to model classes needed to explain the L12
blocker.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation and iPhone 12 simulator
inventory checks. It also currently exposes connected unsupported physical iOS
hardware, but the blueprint requires a connected physical iPhone 12, iPhone 12
mini, iPhone 12 Pro, or iPhone 12 Pro Max before any parity-complete release
claim.

Because the required physical iPhone 12-family hardware was absent during this
batch, no physical-device install/test run and no manual open-render-search-
edit-save-rotate validation flow was attempted or claimed.

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
- L12 iOS physical inventory report hardening for connected unsupported iOS hardware.

Can mark complete from this batch:

- None. This batch improves validation evidence and report precision, but it
  does not complete physical iPhone 12-family validation.
