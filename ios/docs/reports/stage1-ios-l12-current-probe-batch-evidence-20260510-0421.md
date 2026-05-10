# Stage 1 iOS L12 Current Probe Batch Evidence

Date: 2026-05-10 04:21 Asia/Shanghai

## Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Ownership: `ios/**` only.
- Batch type: bounded implementation hardening plus validation refresh.

## Summary

This batch keeps the physical iPhone 12-family validation gate open, but hardens the iOS completion model so a future pass cannot be assembled from manual flow rows that merely happened after a fresh hardware probe. A passing real-device report now requires every required Stage 1 flow row to carry evidence tied to the current physical-device probe batch, and that same row must also be current, post-probe, step-specific, and matched to the verified connected iPhone 12-family hardware signal.

No Android files, root `Docs/**` files, `.cron/**` files, renderer assets, WebKit renderer surfaces, entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior were edited.

## Files Changed

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-current-probe-batch-evidence-20260510-0421.md`

## Implementation Notes

- Added `blockedMissingCurrentProbeBatchEvidence` to the iOS L12 real-device validation status.
- Added `probeBatchObservedAt` to `IOSStageOneRealDeviceFlowEvidence`.
- Added `referencesProbeBatch(observedAt:tolerance:)` to compare manual evidence with the effective current probe timestamp.
- Added `completedStepsWithCurrentProbeBatchManualFlowEvidence` and `hasManualFlowEvidenceForCurrentProbeBatch` to `IOSStageOneRealDeviceValidationReport`.
- The current-probe-batch row now requires the same evidence item to be:
  - step-specific for the Stage 1 action,
  - current,
  - observed after the current physical-device probe,
  - matched to verified connected iPhone 12-family hardware,
  - explicitly tied to the current probe batch timestamp.
- The generated markdown report now emits `Manual flow references current probe batch` and reports missing rows as `PROBE-BATCH-MISSING`.
- Added `testIOSL12RealDeviceValidationRequiresManualEvidenceForCurrentProbeBatch`.
- Updated real-device test fixtures that intentionally model completed physical validation to include matching probe-batch evidence.

## Validation Commands

| Command | Working directory | Result | Notes |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRequiresManualEvidenceForCurrentProbeBatch` | `ios/` | PASS | 1 XCTest case, 0 failures. Validates the new current-probe-batch blocker and accepted current-batch path. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidation` | `ios/` | PASS | 37 XCTest cases, 0 failures. Covers the L12 real-device evidence model after the new gate. |
| `swift test` | `ios/` | PASS | 245 XCTest cases, 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Exact `iPhone 12` simulator destination is available in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 and listed the Mac host, offline physical iOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained an unavailable iPhone 15 Pro-class record and a paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
| `git diff --check -- ios` | repository root | PASS | No whitespace errors reported. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local network details, and full local paths are intentionally omitted from this report. Retained hardware class information is limited to what is needed to explain why the L12 physical gate remains blocked.

## Current L12 Physical-Device Status

- SwiftPM validation: pass.
- Focused L12 real-device gate validation: pass.
- iPhone 12 simulator inventory: available.
- Required physical probe commands: both executed in this batch.
- Physical iPhone 12-family validation: open.
- Current blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max is available, so the manual open, render, search, full source edit, block source edit, save, and rotate flow could not run on required hardware.

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Checklist Guidance

Can mark complete from this batch:

- None.

Keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch is implementation and blocker-refresh evidence for the still-open physical-device gate. It does not replace the required connected physical iPhone 12-family manual validation flow and should not be used for a parity-complete release claim.
