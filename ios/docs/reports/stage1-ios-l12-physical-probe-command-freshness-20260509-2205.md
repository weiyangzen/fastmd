# Stage 1 iOS L12 Physical Probe Command Freshness - 2026-05-09 22:05 +0800

## Batch Scope

- Worker lane: Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Authoritative blueprint read-only source: `Docs/Stage1_Mobile_Blueprint.md`.
- Daily todo read-only source: `Docs/todos_20260506.md`.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Files changed in this batch:
  - `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
  - `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - `ios/docs/reports/stage1-ios-l12-physical-probe-command-freshness-20260509-2205.md`

The todo snapshot shows L1 through L11 complete for the iOS lane and keeps the
physical iPhone 12-family real-device validation gate open. This batch advanced
the L12 evidence model only; it did not edit Android files, root `Docs/**`,
`.cron/**`, app entitlements, privacy manifests, renderer assets, or WebKit
surfaces.

## Implementation

- Added `IOSStageOnePhysicalProbeCommandEvidence` so the real-device validation
  report can track an observation timestamp per physical probe command.
- Added `blockedStaleRequiredCommands` coverage status and
  `blockedStaleRequiredProbeCommands` report status.
- Kept backward compatibility for existing aggregate reports by defaulting each
  command's timestamp to `deviceProbeObservedAt` when per-command evidence is
  not supplied.
- Hardened completion semantics so L12 physical validation cannot complete when
  either required probe command is missing, stale, future-dated, or observed
  outside the current report window.
- Added markdown report output for stale physical probe commands.
- Added focused tests for the aggregate timestamp compatibility path and for a
  stale `devicectl` command while `xctrace` remains current.

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | Built the SwiftPM package and executed 49 focused L12 XCTest cases with 0 failures and 0 unexpected failures. |
| `swift test` | `ios/` | PASS | Executed 224 XCTest cases with 0 failures and 0 unexpected failures. XCTest execution time was 15.918 seconds; the full suite completed in 15.938 seconds. Swift Testing reported 0 tests in 0 suites passed. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | repo root | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | repo root | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | repo root | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. The physical inventory contained unavailable non-iPhone-12-family hardware only: iPhone 15 Pro class / `iPhone16,1` and iPad Pro 11-inch 4th generation class / `iPad14,4`. |

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

- None. This batch improves and validates local iOS physical-device evidence
  freshness handling, but it does not complete physical iPhone 12-family
  validation.
