# Stage 1 iOS L12 Probe Merge Connection Evidence

Date: 2026-05-10 05:00 Asia/Shanghai

## Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Ownership: `ios/**` only.
- Batch type: bounded L12 real-device evidence hardening plus validation refresh.

## Summary

This batch keeps the physical iPhone 12-family validation gate open, but tightens the iOS L12 probe evidence model. When device inventory sources describe the same physical device, the merger now preserves explicit connection evidence from one source when the other source only contributes hardware identity and lacks explicit connection evidence. If both sources explicitly disagree on connection state, the gate still fails closed by treating the merged device as not connected.

No Android files, root `Docs/**` files, `.cron/**` files, renderer assets, WebKit renderer surfaces, entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior were edited.

## Files Changed

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-probe-merge-connection-evidence-20260510-0500.md`

## Implementation Notes

- Updated `IOSStageOneDeviceProbeCandidateMerger` to merge connection state using explicit-evidence semantics instead of unconditional `existing.isConnected && candidate.isConnected`.
- Preserved existing fail-closed behavior when both merged candidates provide explicit conflicting connection evidence.
- Added `testIOSL12DeviceProbeCandidateMergerKeepsExplicitConnectionWhenHardwareRowLacksConnectionEvidence` to cover the current risk: `xctrace` can provide connected physical-device evidence while a same-device hardware row only contributes the iPhone 12-family hardware identity.

## Validation Commands

| Command | Working directory | Result | Notes |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DeviceProbeCandidateMergerKeepsExplicitConnectionWhenHardwareRowLacksConnectionEvidence` | `ios/` | PASS | 1 XCTest case, 0 failures. Finished at 2026-05-10 04:58:47 +0800. |
| `swift test` | `ios/` | PASS | 247 XCTest cases, 0 failures. Finished at 2026-05-10 04:59:19 +0800. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory | Exact `iPhone 12` simulator destination is installed and was listed in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 and listed the Mac host, offline physical iOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory included an unavailable iPhone 15 Pro-class record and an iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
| `git diff --check -- ios` | repository root | PASS | No whitespace errors reported. |

## Current Physical Inventory Summary

Current probes did not report any connected physical iPhone 12-family hardware.

| Device class observed | Hardware signal | Connection state | Gate eligibility |
| --- | --- | --- | --- |
| iPhone 15 Pro-class physical record | `iPhone16,1` | unavailable | Not eligible: not iPhone 12 family. |
| iPad Pro 11-inch 4th generation-class physical record | `iPad14,4` | paired/available table signal with disconnected tunnel JSON signal | Not eligible: not iPhone 12 family. |
| iPhone 12 simulator destination | simulator device | available simulator inventory | Not eligible: simulator is not physical hardware. |

## Required Physical Flow

The required manual flow could not be executed because no eligible connected physical iPhone 12-family device was available.

| Required iPhone 12-family physical flow | Status |
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

- `ios/docs/reports/stage1-ios-l12-probe-merge-connection-evidence-20260510-0500.md`

This batch is implementation hardening and fresh blocker evidence for the still-open physical-device gate. It does not replace the required connected physical iPhone 12-family manual validation flow and should not be used for a parity-complete release claim.
