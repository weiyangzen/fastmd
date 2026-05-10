# Stage 1 iOS L12 Probe Evidence Dedup And Current Validation

- Generated: 2026-05-10 00:10 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`

## Scope

The daily snapshot leaves one iOS-owned item open: physical iPhone 12-family
real-device validation. This batch keeps that gate fail-closed and hardens the
iOS local evidence model for repeated physical probe command observations.

When a validation run records duplicate observations for the same normalized
probe command, the report now keeps the freshest timestamp instead of the first
timestamp. This prevents an older stale observation from masking a newer current
`xcrun devicectl list devices --json-output -` or
`xcrun xctrace list devices` probe in the same report input.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-probe-evidence-dedup-and-current-validation-20260510-0010.md`

## Implementation Evidence

- Updated `IOSStageOneRealDeviceValidationReport.normalizedProbeCommandEvidence`
  to group evidence by normalized command value and preserve the newest
  `observedAt` per command.
- Added `shouldReplaceProbeCommandEvidence(existing:with:)` so nil timestamps
  remain weaker than dated observations and older dated observations remain
  weaker than newer ones.
- Added
  `testIOSL12RealDeviceValidationKeepsFreshestDuplicatePerCommandEvidence`,
  covering a stale `devicectl` observation followed by a fresher whitespace
  variant of the same command.

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationKeepsFreshestDuplicatePerCommandEvidence` | `ios/` | PASS | Focused regression passed after implementation. An earlier in-batch attempt failed until manual-flow evidence timestamps were aligned after the device probe. |
| `swift test` | `ios/` | PASS | 228 XCTest cases executed with 0 failures. |
| `xcodebuild -list` | `ios/` | PASS | SwiftPM exposes scheme `FastMDMobile`; no checked-in `.xcodeproj` or `.xcworkspace` is required for this local Xcode validation path. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found available simulator destination `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'id=1B6FEADC-308B-4069-B734-3C9C207E633F' test` | `ios/` | PASS | Executed 228 XCTest cases on the iPhone 12 simulator with 1 skip and 0 failures. Xcode ended with `** TEST SUCCEEDED **`. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical records were unavailable non-iPhone-12-family hardware: iPhone 15 Pro class / `iPhone16,1` and iPad Pro 11-inch 4th generation class / `iPad14,4`. No connected physical iPhone 12-family device was present. |

## Current Physical Gate Status

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation and iPhone 12 simulator
testing, but the blueprint requires a connected physical iPhone 12, iPhone 12
mini, iPhone 12 Pro, or iPhone 12 Pro Max before any parity-complete release
claim. No connected physical iPhone 12-family device was available during this
batch.

Because the required physical device was absent, no physical-device install/test
or manual open/render/search/edit/save/rotate flow was claimed.

## Required Physical Flow Still Open

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

Items this batch can support as evidence, but not newly close:

- L12 current iOS blocker evidence for the physical real-device gate.
- L12 iOS physical probe evidence dedup hardening.
- L12 iPhone 12 simulator readiness remains passing.

Can mark complete from this batch:

- None. This batch improves evidence handling and refreshes validation, but it
  does not complete physical iPhone 12-family validation.
