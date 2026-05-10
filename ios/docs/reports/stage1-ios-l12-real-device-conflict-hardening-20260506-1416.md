# Stage 1 iOS L12 Real-Device Conflict Hardening - 2026-05-06 14:16 CST

## Scope

- Worker ownership: `ios/**`
- Blueprint item advanced: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Shared Docs edited: no
- Android edited: no

## Implementation

- Hardened `IOSStageOneDeviceProbeCandidateMerger` so merged evidence for the same physical device fails closed when probe sources disagree on connection state.
- Added focused XCTest coverage proving a same-identifier iPhone 12-family candidate with conflicting connected/unavailable evidence remains disconnected and cannot satisfy the physical iPhone 12-family gate.

This protects the remaining L12 gate from a false completion if `xcrun xctrace list devices` and `xcrun devicectl list devices --json-output -` report contradictory connection states for the same device during a validation batch.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DeviceProbeCandidateMerger` from `ios/` | PASS | Executed 2 focused L12 merger tests with 0 failures, including the new connection-conflict fail-closed case. |
| `swift test` from `ios/` | PASS | Executed 208 XCTest cases with 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | An available `iPhone 12` simulator destination was listed. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family validation | Connected device section listed the Mac only. Physical iOS devices were listed only in the offline section, and the `iPhone 12` entry was under simulators. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation | Command outcome was `success`, but discovered physical iOS devices were unavailable and not iPhone 12-family hardware: one unavailable iPhone 15 Pro-class device and one unavailable iPad Pro-class device. Device names, identifiers, serials, ECIDs, hostnames, and full local paths are intentionally omitted. |

## Current L12 Result

The L12 physical-device validation gate remains open.

The local environment can validate the SwiftPM test gate and can see an iPhone 12 simulator destination, but the blueprint requires a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completing the Stage 1 open, render, search, edit, save, and rotate flow before any parity-complete release claim.

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

- None from the remaining iOS L12 open row. This batch hardens the physical-device evidence path and records current validation evidence, but it does not complete physical iPhone 12-family validation.

Keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence path:

- `ios/docs/reports/stage1-ios-l12-real-device-conflict-hardening-20260506-1416.md`
