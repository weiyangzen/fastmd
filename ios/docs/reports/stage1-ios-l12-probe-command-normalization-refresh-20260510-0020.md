# Stage 1 iOS L12 Probe Command Normalization Refresh

- Generated: 2026-05-10 00:20 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`

## Scope

The daily snapshot leaves one iOS-owned item open: physical iPhone 12-family
real-device validation. This batch keeps that gate fail-closed and tightens the
iOS local evidence model for repeated physical probe command strings.

The real-device report already normalized command strings when checking command
coverage and command observation timestamps. This batch applies the same
normalization to the displayed `probeCommands` list so casing and whitespace
variants of the same required command do not duplicate blocker summaries or
reconciliation evidence.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-probe-command-normalization-refresh-20260510-0020.md`

## Implementation Evidence

- Updated `IOSStageOneRealDeviceValidationReport.normalizedProbeCommands` to
  deduplicate by normalized command value instead of raw command text.
- Preserved the first canonical spelling of each command so report output stays
  stable and readable.
- Added
  `testIOSL12RealDeviceValidationNormalizesDuplicateProbeCommandStrings`,
  covering mixed-case and extra-whitespace duplicates for both required
  physical probe commands.

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationNormalizesDuplicateProbeCommandStrings` | `ios/` | PASS | Focused regression passed: 1 XCTest case, 0 failures. |
| `swift test` | `ios/` | PASS | 229 XCTest cases executed with 0 failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported for iOS changes. |
| `xcodebuild -list` | `ios/` | PASS | SwiftPM package graph resolved and listed scheme `FastMDMobile`. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found available simulator destination `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. This is simulator evidence only. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical records were iPhone 15 Pro class / `iPhone16,1` with unavailable tunnel state and iPad Pro 11-inch 4th generation class / `iPad14,4`. No physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

## Current Physical Gate Status

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation, exposes the `FastMDMobile`
scheme, and has an iPhone 12 simulator destination. The blueprint still requires
a connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro
Max before any parity-complete release claim.

Because the required physical hardware was absent during this batch, no
physical-device install/test or manual open/render/search/edit/save/rotate flow
was claimed.

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
- L12 iOS physical probe command normalization hardening.
- L12 iPhone 12 simulator readiness remains available.

Can mark complete from this batch:

- None. This batch improves the iOS physical-device evidence model and refreshes
  validation, but it does not complete physical iPhone 12-family validation.
