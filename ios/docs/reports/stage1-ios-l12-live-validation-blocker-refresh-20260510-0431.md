# Stage 1 iOS L12 Live Validation Blocker Refresh

Date: 2026-05-10 04:31 Asia/Shanghai

## Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Ownership: `ios/**` only.
- Batch type: bounded validation refresh and blocker evidence report.

## Summary

The iOS SwiftPM validation suite passes on the current SwiftPM skeleton, and an exact `iPhone 12` simulator destination is installed. The required physical iPhone 12-family validation remains open because the local device probes did not find a connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max.

No Android files, root `Docs/**` files, `.cron/**` files, source files, renderer assets, entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior were edited.

## Files Changed

- `ios/docs/reports/stage1-ios-l12-live-validation-blocker-refresh-20260510-0431.md`

## Validation Commands

| Command | Working directory | Result | Notes |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | Build completed and 245 XCTest cases passed with 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Exact `iPhone 12` simulator destination is available in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 and listed the Mac host, offline physical iOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained an unavailable iPhone 15 Pro-class record and an available paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12-family hardware was present. |

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

This report is fresh blocker evidence for the still-open physical-device gate. It does not replace the required connected physical iPhone 12-family manual validation flow and should not be used for a parity-complete release claim.
