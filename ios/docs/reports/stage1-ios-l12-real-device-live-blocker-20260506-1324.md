# Stage 1 iOS L12 Real-Device Live Blocker Report

Generated: 2026-05-06T05:24:07Z

Scope: one bounded iOS-only live-lane validation batch for the remaining iOS-owned L12 item:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No Android files, root `Docs/**` checklist files, or `.cron/**` files were edited. This report is fresh blocker evidence only; it is not completion evidence for the real-device gate.

## Selection Rationale

`Docs/todos_20260506.md` shows L1, L4, L9, L10, L11, and iOS-owned L13 report recording complete, with the remaining iOS-owned open work concentrated in L12 physical iPhone 12-family validation. The iOS canonical fixture matrix is already covered by the existing SwiftPM fixture tests and passed again in this batch.

Because no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available, the batch could not run the required manual real-device open, rich fixture render, search, full source edit, block source edit, save, and rotate flow.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 205 XCTest cases with 0 failures. This includes `testCanonicalMarkdownFixtureMatrixExistsAndIsSeeded`, `testRichPreviewFixtureMatchesSharedCanonicalFixture`, L11 automated gates, and L12/L13 reconciliation tests. |
| `xcrun xctrace list devices` from `ios/` | PASS command, real-device gate BLOCKED | Connected physical-device section listed only `Mac`. Offline physical iOS-family devices were present, and `iPhone 12` appeared only under the simulator section. Simulator evidence does not satisfy the physical-device gate. |
| `xcrun devicectl list devices --json-output -` from `ios/` | PASS command, real-device gate BLOCKED | Command outcome was success after a provisioning-parameter warning. CoreDevice listed unavailable physical devices only: an iPhone 15 Pro-class device (`iPhone16,1`) and an iPad Pro-class device (`iPad14,4`). No connected `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` hardware was present. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS command, simulator-only evidence | `iPhone 12` simulator is available and shutdown. This is useful simulator inventory evidence but cannot close the physical real-device item. |

Private identifiers, serial numbers, UDIDs, ECIDs, hostnames, and full CoreDevice JSON are intentionally omitted from this report. The blocker is hardware availability, not missing identifiers.

## Gate Status

| Blueprint checklist item | Status | Evidence path | Evidence summary |
| --- | --- | --- | --- |
| `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` | OPEN / BLOCKED | `ios/docs/reports/stage1-ios-l12-real-device-live-blocker-20260506-1324.md` | No connected physical iPhone 12-family device was reported by `xcrun xctrace list devices` or `xcrun devicectl list devices --json-output -`; the only iPhone 12 evidence in this batch is simulator-only. |

## Supervisor Guidance

Keep the L12 physical real-device validation item open.

The item should close only after a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 flow with current evidence:

- Open Markdown.
- Render `rich-preview.md`.
- Search document.
- Full source edit.
- Block source edit.
- Save writable document.
- Rotate reader.

