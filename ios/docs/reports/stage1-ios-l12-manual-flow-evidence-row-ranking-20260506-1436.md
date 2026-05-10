# Stage 1 iOS L12 Manual Flow Evidence Row Ranking - 2026-05-06 14:36 CST

## Scope

- Worker ownership: `ios/**`
- Blueprint item advanced: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Shared Docs edited: no
- Android edited: no

## Implementation

- Hardened `IOSStageOneRealDeviceValidationReport` manual-flow evidence rendering.
- When duplicate manual evidence rows exist for the same required physical-device step, the generated report now selects the strongest row for display:
  - current physical iPhone 12-family evidence,
  - then stale physical iPhone 12-family evidence,
  - then current generic evidence,
  - then other completion evidence.
- Added focused XCTest coverage proving a generic duplicate row cannot hide the physical iPhone 12-family evidence row in the report table.

This does not change the fail-closed L12 completion gate. It improves the supervisor evidence path so a passing or blocked physical-device report displays the actual strongest evidence row for each open/render/search/edit/save/rotate step.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceReportPrefersPhysicalManualFlowEvidenceRows` from `ios/` | PASS | Executed 1 focused XCTest case with 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 35 focused L12 XCTest cases with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 210 XCTest cases with 0 failures. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Available iPhone 12 simulator destination was listed. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family validation | Connected device section listed the Mac only. Physical iOS-family entries were offline, and the iPhone 12 entry appeared under simulators, not physical devices. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation | Command outcome was `success`, but discovered physical iOS-family devices were unavailable and not iPhone 12-family hardware: one unavailable iPhone 15 Pro-class device and one unavailable iPad Pro-class device. Device names, identifiers, serials, ECIDs, hostnames, and full local paths are intentionally omitted. |

## Current L12 Result

The L12 physical-device validation gate remains open.

The local environment can validate SwiftPM and can see an iPhone 12 simulator destination, but the blueprint requires a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completing the Stage 1 open, render, search, edit, save, and rotate flow. No connected physical iPhone 12-family device was available in this batch.

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

- None from the remaining iOS L12 open row. This batch hardens real-device report evidence rendering and records fresh validation evidence, but it does not complete physical iPhone 12-family validation.

Keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence path:

- `ios/docs/reports/stage1-ios-l12-manual-flow-evidence-row-ranking-20260506-1436.md`
