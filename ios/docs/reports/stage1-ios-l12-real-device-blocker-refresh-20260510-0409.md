# Stage 1 iOS L12 Real-Device Blocker Refresh

## Scope

- Worker: FastMD Stage 1 Mobile iOS live lane.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Batch boundary: iOS-only validation evidence under `ios/**`.
- Root blueprint and daily todo snapshot were read for selection only and were not edited.

## Summary

This bounded batch refreshed the still-open physical iPhone 12-family validation gate with current local evidence.

The SwiftPM validation gate passed. The exact `iPhone 12` simulator destination is available. Both physical-device probe commands ran successfully enough to produce device inventory, but no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available. The real-device gate therefore remains open, and no parity-complete iOS release claim should be made from this batch.

## Validation Evidence

| Command | Working directory | Result | Notes |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | Build completed, then 244 XCTest cases passed with 0 failures. Test suite finished at 2026-05-10 04:08:53 +0800. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Exact `iPhone 12` simulator destination was present in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0. Inventory included the Mac host, two offline physical iOS device records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained one unavailable iPhone 15 Pro-class record and one paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

## Current L12 Physical-Device Status

- SwiftPM validation: pass.
- iPhone 12 simulator inventory: available.
- Required physical probe commands: both executed.
- Physical iPhone 12-family validation: open.
- Current blocker: no connected physical iPhone 12-family device is available, so the manual Stage 1 flow could not be run on required hardware.

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

Still open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No new authoritative blueprint checklist item should be marked complete from this batch. This report is blocker-refresh evidence only; it does not replace the required physical iPhone 12-family manual validation flow.
