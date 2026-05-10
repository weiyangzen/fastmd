# Stage 1 iOS L12 Real-Device Blocker Refresh

## Scope

- Worker: FastMD Stage 1 Mobile iOS live lane.
- Batch: one bounded iOS-owned L12 validation refresh.
- Selected open iOS checklist item: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Ownership: changed only `ios/**`; root `Docs/**`, `android/**`, and `.cron/**` were not edited.

## Summary

The earliest still-open iOS-owned item is the physical iPhone 12-family validation gate. This batch refreshed the current local evidence for that gate.

SwiftPM validation passed, the focused L12 report-model tests passed, and the exact `iPhone 12` simulator destination is present. Both required physical-device probe commands ran and produced current inventory. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available, so the real-device Stage 1 manual flow could not be run and the L12 physical-device row must remain open.

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | Executed 246 XCTest cases with 0 failures. Finished at 2026-05-10 04:49:19 +0800. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | Executed 71 focused L12 XCTest cases with 0 failures. Finished at 2026-05-10 04:49:47 +0800. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | repo root | PASS for simulator inventory only | Exact `iPhone 12` simulator destination was listed in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | repo root | BLOCKED for physical iPhone 12-family validation | Command exited 0. Inventory listed the Mac host, offline physical iOS-family records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | repo root | BLOCKED for physical iPhone 12-family validation | Command exited 0 and JSON `outcome` was `success` after a CoreDevice provider warning. Physical inventory included an unavailable iPhone 15 Pro-class record and an iPad Pro-class record. No connected physical iPhone 12-family device was present. |
| `find ios -maxdepth 3 \( -name '*.xcodeproj' -o -name '*.xcworkspace' -o -name 'Package.resolved' \) -print` | repo root | PASS inventory | No Xcode project/workspace files or `Package.resolved` were present under `ios/`; this remains a SwiftPM skeleton. |
| `xcodebuild -list` | `ios/` | PASS inventory with warning | Resolved the SwiftPM package and listed workspace `ios` with scheme `FastMDMobile`; Xcode also printed `IDERunDestination: Supported platforms for the buildables in the current scheme is empty.` This command was not used to close any checklist row. |

## Current Physical Inventory Summary

Current probes did not report any connected physical iPhone 12-family hardware.

| Device class observed | Hardware signal | Connection state | Gate eligibility |
| --- | --- | --- | --- |
| iPhone 15 Pro-class physical record | `iPhone16,1` | unavailable | Not eligible: not iPhone 12 family. |
| iPad Pro 11-inch 4th generation-class physical record | `iPad14,4` | paired iPad record, not iPhone 12-family hardware | Not eligible: not iPhone 12 family. |
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

## Supervisor Reconciliation

Do not mark the physical iPhone 12-family validation row complete from this batch.

Still open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No new authoritative blueprint checklist item should be marked complete from this report. This is current blocker evidence only.

