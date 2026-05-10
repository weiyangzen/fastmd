# Stage 1 iOS L12 Effective Probe Evidence

- Generated: 2026-05-10 02:22 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Scope

The authoritative checklist and daily snapshot leave no earlier open iOS-owned
implementation row ahead of L12. This bounded batch hardens the iOS L12
real-device validation model so reports can derive the current physical-device
probe timestamp from fresh per-command evidence when the legacy aggregate
`deviceProbeObservedAt` field is absent.

This avoids a false stale-probe blocker only when both required physical probe
commands have current observations. Completion remains fail-closed: manual flow
evidence must still be current, must reference connected verified iPhone
12-family hardware, and must be observed after the effective probe timestamp.

No Android files, root `Docs/**` files, `.cron/**` files, renderer assets,
entitlements, privacy manifests, or WebKit surfaces were edited.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-effective-probe-evidence-20260510-0222.md`

## Implementation Evidence

- Added `IOSStageOneRealDeviceValidationReport.effectiveDeviceProbeObservedAt`.
- `hasCurrentDeviceProbeEvidence` now uses the effective timestamp.
- Manual-flow post-probe validation now compares evidence against the effective
  timestamp.
- The generated real-device report now displays the effective timestamp.
- Added a focused L12 XCTest covering current per-command probe evidence with
  `deviceProbeObservedAt == nil`.
- Adjusted the duplicate-probe-evidence fixture so its manual flow remains
  post-probe under the stricter effective timestamp rule.

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS after fixture correction | Final focused L12 run executed 61 XCTest cases with 0 failures and 0 unexpected failures. The first run after the model change failed because one pre-existing completion fixture placed manual-flow evidence before the newly effective freshest probe timestamp; that fixture was corrected and the focused gate was rerun successfully. |
| `swift test` | `ios/` | PASS | SwiftPM executed 236 XCTest cases with 0 failures and 0 unexpected failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported for iOS-local changes. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | repository root | PASS for simulator inventory only | Found an exact `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | repository root | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, offline physical iOS records, and simulator destinations. The exact `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | repository root | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning: `No provider was found.` The physical inventory contained an unavailable iPhone 15 Pro-class record and an available paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local user paths,
simulator identifiers, DerivedData paths, and test result bundle paths are
intentionally omitted from this report. Retained hardware signals are limited to
model classes needed to explain the L12 blocker.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

Current local validation supports the SwiftPM gate and the iPhone 12 simulator
inventory prerequisite, and the iOS validation model now handles current
per-command physical probe evidence without requiring the legacy aggregate probe
timestamp.

The blueprint still requires a connected physical iPhone 12, iPhone 12 mini,
iPhone 12 Pro, or iPhone 12 Pro Max before any parity-complete release claim.
Because the required physical iPhone 12-family hardware was absent during this
batch, no physical-device install/test run and no manual
open-render-search-edit-save-rotate validation flow was attempted or claimed.

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

Can mark complete from this batch:

- None. This batch advances and validates the L12 evidence model, but it does
  not complete physical iPhone 12-family validation.
