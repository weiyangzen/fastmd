# Stage 1 iOS L12 Live Validation Batch - 2026-05-09 23:37 +0800

## Batch Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Authoritative blueprint read-only source: `Docs/Stage1_Mobile_Blueprint.md`.
- Daily todo read-only source: `Docs/todos_20260506.md`.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Batch type: bounded validation/evidence refresh.

The todo snapshot shows L1 through L11 complete for the iOS lane and keeps only
the physical iPhone 12-family validation item open for iOS. This batch therefore
ran the smallest supported real local validation, refreshed the physical-device
probes, and recorded the current blocker. It did not edit Android files, root
`Docs/**`, `.cron/**`, app entitlements, privacy manifests, renderer assets, or
WebKit surfaces.

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | Built the SwiftPM package and executed 225 XCTest cases with 0 failures and 0 unexpected failures. XCTest execution time was 16.708 seconds; full suite completed in 16.729 seconds. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. The physical inventory contained an unavailable iPhone 15 Pro-class device and an available paired iPad Pro-class device. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local paths, and simulator
identifiers are intentionally omitted from this report. Retained hardware
signals are limited to model classes needed to explain the L12 blocker.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation and iPhone 12 simulator
inventory checks, but the blueprint requires a connected physical iPhone 12,
iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max before any parity-complete
release claim. No connected physical iPhone 12-family device was available
during this batch.

Because the required physical device was absent, no physical-device install/test
run and no manual open-render-search-edit-save-rotate validation flow was
attempted in this batch.

## Manual Flow Rows

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

Checklist items this report supports as still blocked:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Checklist items that can be newly marked complete from this batch:

- None. This batch refreshes current validation evidence, but it does not
  complete physical iPhone 12-family validation.
