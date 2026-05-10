# Stage 1 iOS L12 Probe Batch Timestamp Hardening

Date: 2026-05-10 05:08 Asia/Shanghai

## Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Ownership: `ios/**` only.
- Batch type: bounded L12 real-device gate hardening plus fresh validation/blocker evidence.

## Summary

This batch keeps the physical iPhone 12-family validation gate open, but tightens the iOS L12 current-probe-batch evidence model. The real-device gate already requires both physical probe commands, `xcrun xctrace list devices` and `xcrun devicectl list devices --json-output -`. Manual flow evidence can now reference either current required probe timestamp from the same batch, instead of only the latest required probe timestamp. This avoids a false negative when both probes are current but the manual evidence records the earlier probe timestamp from the same physical-device batch.

No Android files, root `Docs/**` files, `.cron/**` files, renderer assets, WebKit renderer surfaces, entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior were edited.

## Files Changed

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-probe-batch-timestamp-hardening-20260510-0508.md`

## Implementation Notes

- Added `requiredProbeCommandObservedAtValues` to expose the set of current required physical probe command timestamps used by the L12 gate.
- Updated `completedStepsWithCurrentProbeBatchManualFlowEvidence` so step evidence must still be current, step-specific, physical, matched to verified connected hardware, and observed after the earliest current required probe command, but may reference any required probe timestamp in the current batch.
- Updated manual evidence ranking to use the same current-batch timestamp set when choosing the report row for each Stage 1 physical flow step.
- Added `testIOSL12RealDeviceValidationAcceptsEitherRequiredProbeTimestampForCurrentBatch` to prove an evidence row tied to the earlier `xctrace` timestamp still completes the gate when `devicectl` ran a few seconds later in the same required probe batch.

## Validation Commands

| Command | Working directory | Result | Notes |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationAcceptsEitherRequiredProbeTimestampForCurrentBatch` | `ios/` | PASS | 1 XCTest case, 0 failures. Finished at 2026-05-10 05:07:08 +0800. |
| `swift test` | `ios/` | PASS | 248 XCTest cases, 0 failures. Finished at 2026-05-10 05:07:36 +0800. |
| `xcrun simctl list devices available \| rg 'iPhone 12' \|\| true` | `ios/` | PASS for simulator inventory | Exact `iPhone 12` simulator destination is installed and was listed in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 and listed the Mac host, offline physical iOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory included an unavailable iPhone 15 Pro-class record and a paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
| `git diff --check -- ios` | repository root | PASS | No whitespace errors reported. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local network details, and full local paths are intentionally omitted from this report. Retained hardware class information is limited to what is needed to explain why the L12 physical gate remains blocked.

## Current L12 Physical-Device Status

- SwiftPM validation: pass.
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

Evidence path:

- `ios/docs/reports/stage1-ios-l12-probe-batch-timestamp-hardening-20260510-0508.md`

This batch is implementation hardening and fresh blocker evidence for the still-open physical-device gate. It does not replace the required connected physical iPhone 12-family manual validation flow and should not be used for a parity-complete release claim.
