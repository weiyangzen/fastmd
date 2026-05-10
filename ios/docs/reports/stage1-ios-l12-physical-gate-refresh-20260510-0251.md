# Stage 1 iOS L12 Physical Gate Refresh

- Generated: 2026-05-10 02:51:09 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Ownership: `ios/**` only
- Authoritative blueprint reviewed but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot reviewed but not edited: `Docs/todos_20260506.md`
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Scope

The blueprint and daily todo snapshot show all earlier iOS-owned Stage 1 rows
complete. This bounded batch refreshed the remaining iOS L12 physical-device
gate evidence and reran the minimum SwiftPM validation required for the current
SwiftPM skeleton.

The physical-device gate remains open. No connected physical iPhone 12, iPhone
12 mini, iPhone 12 Pro, or iPhone 12 Pro Max was available during this batch, so
no physical install/test run and no manual open-render-search-edit-save-rotate
flow was attempted or claimed.

## Files Changed

- `ios/docs/reports/stage1-ios-l12-physical-gate-refresh-20260510-0251.md`

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | SwiftPM built `FastMDMobileCore` and executed 236 XCTest cases with 0 failures and 0 unexpected failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found an available exact `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, offline physical iOS records, and simulator destinations. The exact `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical inventory contained one unavailable iPhone 15 Pro-class record and one available paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local network
identifiers, user-specific labels, and raw JSON payloads are intentionally
omitted. Hardware signals are limited to the model classes needed to explain why
the L12 physical gate remains blocked.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

Current local validation supports the SwiftPM gate and the iPhone 12 simulator
inventory prerequisite. The blueprint still requires a connected physical iPhone
12-family device before any parity-complete release claim.

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Checklist Recommendation

Keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Can mark complete from this batch:

- None. This batch provides fresh blocker evidence, but it does not complete the
  required physical iPhone 12-family validation.
