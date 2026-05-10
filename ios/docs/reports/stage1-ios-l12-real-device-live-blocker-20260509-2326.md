# Stage 1 iOS L12 Real-Device Live Blocker - 2026-05-09 23:26 +0800

## Batch Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Repository: `/Users/wangweiyang/GitHub/fastmd`.
- Ownership respected: only `ios/**` was written.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Evidence file: `ios/docs/reports/stage1-ios-l12-real-device-live-blocker-20260509-2326.md`.

The daily todo snapshot shows all earlier iOS-owned L1-L11 items complete and
the only iOS-owned open row is physical iPhone 12-family real-device validation.
This batch refreshed local SwiftPM validation, iPhone 12 simulator inventory,
and the required physical-device probes. It does not claim physical
iPhone 12-family validation complete.

## Validation Results

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | Built the SwiftPM package and executed 225 XCTest cases with 0 failures and 0 unexpected failures. Test suite finished at 2026-05-09 23:25:45 +0800 after 16.302 seconds. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | repo root | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination in `Shutdown` state: `1B6FEADC-308B-4069-B734-3C9C207E633F`. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | repo root | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | repo root | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. The physical inventory contained unavailable non-iPhone-12-family hardware only: iPhone 15 Pro class / `iPhone16,1` and iPad Pro 11-inch 4th generation class / `iPad14,4`. |

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment currently supports SwiftPM validation and iPhone 12
simulator inventory checks, but the blueprint requires a connected physical
iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max before any
parity-complete release claim. No connected physical iPhone 12-family device
was available during this batch.

Because the required physical device was absent, no physical-device install/test
run and no manual open-render-search-edit-save-rotate validation flow was
performed in this batch.

## Required Physical Flow Status

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

Recommended checklist change:

- Keep L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` OPEN.

No blueprint checklist item should be newly marked complete from this batch.
The batch provides current blocker evidence and confirms the iOS SwiftPM test
gate is still passing.
