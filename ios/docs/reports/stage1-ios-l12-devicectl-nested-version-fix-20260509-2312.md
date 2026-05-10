# Stage 1 iOS L12 Devicectl Nested Version Fix - 2026-05-09 23:12 +0800

## Batch Scope

- Worker lane: Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Authoritative blueprint read-only source: `Docs/Stage1_Mobile_Blueprint.md`.
- Daily todo read-only source: `Docs/todos_20260506.md`.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Files changed in this batch:
  - `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
  - `ios/docs/reports/stage1-ios-l12-devicectl-nested-version-fix-20260509-2312.md`

The todo snapshot shows L1 through L11 complete for the iOS lane and keeps the
physical iPhone 12-family real-device validation gate open. This batch advanced
that L12 gate's local device-probe parser and refreshed validation evidence.
It did not edit Android files, root `Docs/**`, `.cron/**`, app entitlements,
privacy manifests, renderer assets, or WebKit surfaces.

## Implementation

- Fixed `IOSDevicectlDeviceListParser` so OS-version parsing preserves nested
  devicectl dictionaries such as `operatingSystemVersion: { major, minor,
  patch }` and `osVersion: { versionString }` instead of collapsing them before
  `normalizedOSVersion(from:)` can inspect the structure.
- Added a small `firstPresentValue` helper for OS-version field selection while
  keeping string/number extraction behavior unchanged for hardware, connection,
  state, and reality fields.
- Preserved the fail-closed physical-device gate semantics: a candidate still
  requires physical reality evidence, connected/available state, and verified
  iPhone 12-family hardware before it can satisfy the L12 real-device gate.

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test` before the fix | `ios/` | FAIL | Executed 225 XCTest cases with 2 failures in `testIOSL12DevicectlJSONParserAcceptsNestedStateAndVersionFields`; nested OS versions parsed as `nil` instead of `18.6.1` and `18.4`. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` after the fix | `ios/` | PASS | Built the SwiftPM package and executed 50 focused L12 XCTest cases with 0 failures and 0 unexpected failures. |
| `swift test` after the fix | `ios/` | PASS | Executed 225 XCTest cases with 0 failures and 0 unexpected failures. XCTest execution time was 16.209 seconds; the full suite completed in 16.228 seconds. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. The physical inventory contained unavailable non-iPhone-12-family hardware only: iPhone 15 Pro class / `iPhone16,1` and iPad Pro 11-inch 4th generation class / `iPad14,4`. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local user paths, and
simulator identifiers are intentionally omitted. Retained hardware signals are
limited to model classes needed to explain the L12 blocker.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation and iPhone 12 simulator
inventory checks, but the blueprint requires a connected physical iPhone 12,
iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max before any parity-complete
release claim. No connected physical iPhone 12-family device was available
during this batch.

Because the required physical device was absent, no physical-device install/test
run and no manual open-render-search-edit-save-rotate validation flow was
attempted in this batch.

## Manual Flow Rows

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Reconciliation

Checklist items this report supports as still blocked:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Checklist items that can be newly marked complete from this batch:

- None. This batch fixes and validates iOS physical-device probe parsing and
  refreshes current blocked hardware evidence, but it does not complete physical
  iPhone 12-family validation.
