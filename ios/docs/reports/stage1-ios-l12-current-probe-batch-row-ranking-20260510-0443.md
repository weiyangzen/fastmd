# Stage 1 iOS L12 Current Probe Batch Row Ranking

Date: 2026-05-10 04:43 Asia/Shanghai

## Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Ownership: `ios/**` only.
- Batch type: bounded implementation hardening plus validation refresh.

## Summary

This batch keeps the physical iPhone 12-family validation gate open, but tightens the iOS L12 real-device report evidence selection. When multiple manual evidence rows exist for the same required Stage 1 flow step, the report now prefers a row that explicitly references the current physical-device probe batch over an otherwise valid row from an older probe batch. This keeps the displayed report row aligned with the completion gate that already requires current-probe-batch evidence for every required physical iPhone 12-family flow step.

No Android files, root `Docs/**` files, `.cron/**` files, renderer assets, WebKit renderer surfaces, entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior were edited.

## Files Changed

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-current-probe-batch-row-ranking-20260510-0443.md`

## Implementation Notes

- Updated `IOSStageOneRealDeviceValidationReport` manual evidence ranking so report row selection gives positive weight to evidence that references the effective current physical-device probe batch.
- Preserved the existing pass/fail gate semantics: the real-device gate still requires current probe evidence, required probe command coverage, simulator prerequisites, connected verified physical iPhone 12-family hardware, complete step-specific manual flow evidence, post-probe observation, current evidence, and current-probe-batch evidence.
- Added `manualFlowEvidenceReferencesCurrentProbeBatch(_:)` to keep ranking logic consistent with the existing current-batch comparison.
- Added `testIOSL12RealDeviceReportPrefersCurrentProbeBatchEvidenceRows` to prove a newer stale-batch row does not displace a current-probe-batch row for the same flow step.

## Validation Commands

| Command | Working directory | Result | Notes |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceReportPrefersCurrentProbeBatchEvidenceRows` | `ios/` | PASS | 1 XCTest case, 0 failures. Validates report row selection prefers current-probe-batch manual evidence. |
| `swift test` | `ios/` | PASS | 246 XCTest cases, 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory | Exact `iPhone 12` simulator destination is installed and was listed in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | `ios/` | PASS | SwiftPM-generated Xcode scheme built `FastMDMobileCore` for the iPhone 12 simulator destination. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | SwiftPM-generated Xcode scheme ran 246 XCTest cases on the iPhone 12 simulator destination with 1 skip and 0 failures. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 and listed the Mac host, offline physical iOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained an unavailable iPhone 15 Pro-class record and an available paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
| `git diff --check -- ios` | repository root | PASS | No whitespace errors reported. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local network details, and full local paths are intentionally omitted from this report. Retained hardware class information is limited to what is needed to explain why the L12 physical gate remains blocked.

## Current L12 Physical-Device Status

- SwiftPM validation: pass.
- iPhone 12 simulator inventory: available.
- iPhone 12 simulator build/test: pass through SwiftPM-generated Xcode scheme.
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

- `ios/docs/reports/stage1-ios-l12-current-probe-batch-row-ranking-20260510-0443.md`

This batch is implementation hardening and fresh blocker evidence for the still-open physical-device gate. It does not replace the required connected physical iPhone 12-family manual validation flow and should not be used for a parity-complete release claim.
