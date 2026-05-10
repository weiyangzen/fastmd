# Stage 1 iOS L12 Real-Device Hardware Conflict Hardening - 2026-05-06 23:16 CST

## Batch Scope

- Worker lane: Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Authoritative blueprint read-only source: `Docs/Stage1_Mobile_Blueprint.md`.
- Daily todo read-only source: `Docs/todos_20260506.md`.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

The daily todo snapshot shows all iOS-owned implementation and automated gates
complete except physical iPhone 12-family real-device validation. This batch
kept the physical-device gate open and hardened the iOS L12 evidence model so
contradictory duplicate probe rows for the same physical device cannot carry a
possibly wrong verified iPhone 12-family hardware signal into the completion
gate.

## Implementation Evidence

Changed iOS files:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-hardware-conflict-hardening-20260506-2316.md`

Implementation detail:

- `IOSStageOneDeviceProbeCandidateMerger` now merges hardware identity
  fail-closed. If duplicate candidate rows for the same device disagree on
  hardware identity, the merged candidate drops the hardware model instead of
  preserving one side's verified iPhone 12-family signal.
- Compatible hardware identity forms remain accepted. For example, `iPhone 12
  Pro (iPhone13,3)` and `iPhone13,3` still merge to a verified iPhone 12-family
  candidate.
- New XCTest coverage verifies both the conflicting-identity fail-closed path
  and the compatible-identity preservation path.

This avoids accidentally completing the L12 real-device gate from inconsistent
physical inventory evidence.

## Validation Commands

Commands were run from `ios/` unless otherwise noted.

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DeviceProbeCandidateMerger` | PASS | Built the SwiftPM package and executed 4 focused XCTest cases with 0 failures. |
| `swift test` | PASS | Executed 221 XCTest cases with 0 failures and 0 unexpected failures. XCTest execution time was 15.568 seconds; the full XCTest suite completed in 15.588 seconds. Swift Testing reported 0 tests in 0 suites passed. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination. This does not satisfy the physical-device gate. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | Xcode resolved the SwiftPM package and built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator`; `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | Xcode resolved the SwiftPM package and executed 221 XCTest cases with 1 skipped and 0 failures on the iPhone 12 simulator destination; `** TEST SUCCEEDED **`. |
| `xcrun xctrace list devices` | BLOCKED for physical iPhone 12-family validation | Probe completed. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. The physical inventory contained only unavailable non-iPhone-12-family hardware: iPhone 15 Pro class / `iPhone16,1` and iPad Pro 11-inch 4th generation class / `iPad14,4`. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local user paths, and
simulator identifiers are intentionally omitted. The retained hardware signals
are limited to model classes needed to explain why the L12 gate remains blocked.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment can run SwiftPM tests, build/test the package through
Xcode on an iPhone 12 simulator destination, and inventory physical devices.
The blueprint requires a connected physical iPhone 12, iPhone 12 mini, iPhone
12 Pro, or iPhone 12 Pro Max before any parity-complete release claim. No
connected physical iPhone 12-family device was available during this batch.

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

- None. This batch adds implementation hardening and refreshed validation
  evidence, but it does not complete physical iPhone 12-family validation.
