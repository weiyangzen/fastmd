# Stage 1 iOS L12 Live Validation Refresh

## Scope

- Worker: FastMD Stage 1 Mobile iOS live lane.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Batch boundary: iOS-only validation evidence under `ios/**`.
- Blueprint and daily todo files were read but not edited.

## Summary

This bounded batch refreshes the still-open physical iPhone 12-family validation
gate with current local evidence. The SwiftPM gate passed, the exact iPhone 12
simulator destination is available, and both physical-device probe commands ran.

The physical gate remains open because no connected physical iPhone 12 / 12 mini
/ 12 Pro / 12 Pro Max was present. Simulator inventory and disconnected or
unsupported physical devices do not satisfy the required manual open, render,
search, edit, save, and rotate flow on iPhone 12-family hardware.

## Changed Files

- `ios/docs/reports/stage1-ios-l12-live-validation-refresh-20260510-0402.md`

## Validation Evidence

| Command | Working directory | Result | Notes |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | 244 XCTest cases, 0 failures, completed at 2026-05-10 04:02:10 +0800. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Exact `iPhone 12` simulator destination was available in `Shutdown` state. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 and listed the Mac host, offline physical iOS device records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome = success`, after a local CoreDevice provider warning. Physical inventory contained one unavailable iPhone 15 Pro-class record and one paired iPad Pro 11-inch 4th generation-class record whose JSON tunnel was disconnected. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

## Current L12 Physical-Device Status

- SwiftPM validation: pass.
- iPhone 12 simulator inventory: available.
- Physical iPhone 12-family validation: open.
- Blocker: no connected physical iPhone 12-family device was available in the
  fresh physical probes, and no post-probe physical iPhone 12-family manual
  Stage 1 flow evidence was collected.

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

No new authoritative blueprint checklist item should be marked complete from
this batch. This report refreshes blocker evidence for the still-open
physical-device gate, but it does not complete the required physical iPhone
12-family manual validation flow.
