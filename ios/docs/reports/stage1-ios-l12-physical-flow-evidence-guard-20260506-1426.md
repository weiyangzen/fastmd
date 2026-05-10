# Stage 1 iOS L12 Physical Flow Evidence Guard - 2026-05-06 14:26 CST

## Scope

- Worker ownership: `ios/**`
- Blueprint item advanced: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Shared Docs edited: no
- Android edited: no

## Implementation

- Added a fail-closed manual-flow evidence guard to `IOSStageOneRealDeviceFlowEvidence`.
- A real-device validation step now requires current manual evidence that explicitly identifies physical iPhone 12-family hardware or an iPhone 12-family product identifier.
- Manual evidence mentioning an iPhone 12 simulator is rejected for the physical-device gate.
- The real-device validation report now exposes `blockedMissingPhysicalManualFlowEvidence`, reports whether physical iPhone 12-family manual evidence is complete, and marks generic flow evidence rows as `DEVICE-MISSING`.

This prevents a completed open/render/search/edit/save/rotate checklist from satisfying the physical L12 gate when the flow notes are generic or simulator-derived.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 34 focused L12 tests with 0 failures. New coverage: `testIOSL12RealDeviceValidationRequiresPhysicalIPhone12FamilyManualEvidence`. |
| `swift test` from `ios/` | PASS | Executed 209 XCTest cases with 0 failures. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors reported. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Available iPhone 12 simulator destination was listed. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family validation | Connected device section listed the Mac only. The iPhone 12 entry appeared under simulators, not physical devices. Existing physical iOS devices were offline. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation | Command outcome was `success`, but discovered physical iOS devices were unavailable and not iPhone 12-family hardware: one unavailable iPhone 15 Pro-class device and one unavailable iPad Pro-class device. Device names, identifiers, serials, ECIDs, hostnames, and full local paths are intentionally omitted. |

## Current L12 Result

The L12 physical-device validation gate remains open.

The local environment has a usable iPhone 12 simulator destination and passes the SwiftPM validation suite, but the blueprint requires a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completing the Stage 1 open, render, search, edit, save, and rotate flow. No connected physical iPhone 12-family device was available in this batch.

## Required Manual Physical-Device Flow Still Open

| Required real-device flow | Result |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Reconciliation Guidance

Can mark complete:

- None from the remaining iOS L12 open row. This batch hardens the physical-device evidence model and records fresh validation evidence, but it does not complete physical iPhone 12-family validation.

Keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence path:

- `ios/docs/reports/stage1-ios-l12-physical-flow-evidence-guard-20260506-1426.md`
