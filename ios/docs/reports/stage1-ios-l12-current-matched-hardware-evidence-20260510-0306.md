# Stage 1 iOS L12 Current Matched Hardware Evidence Batch

- Generated: 2026-05-09T19:06:16Z
- Local time: 2026-05-10 03:06:16 +0800
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only

## Batch Summary

This batch keeps the open L12 real-device validation item open, but hardens the iOS real-device completion gate so a physical validation pass cannot be assembled from separate partial evidence rows.

The real-device report now requires every required manual flow step to have one evidence row that is all of:

- current relative to the report timestamp
- observed after the effective current physical-device probe
- matched to the connected verified iPhone 12-family hardware signal

This prevents a false pass where stale or future-dated matched hardware rows plus separate current generic rows could satisfy the aggregate checks.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-current-matched-hardware-evidence-20260510-0306.md`

## Implementation Evidence

- Added `completedStepsWithCurrentPostProbeConnectedVerifiedHardwareEvidence`.
- Added `hasCurrentPostProbeManualFlowEvidenceForConnectedVerifiedHardware`.
- Added the final status guard before `.passed` so stale or future matched hardware evidence blocks with `blockedStaleManualFlowEvidence`.
- Added markdown output row:
  - `Manual flow current post-probe connected hardware evidence complete: ...`
- Added manual evidence row status handling so a row that is post-probe but not current is reported as `STALE`.

## Test Evidence

Added two focused XCTest cases:

- `testIOSL12RealDeviceValidationRequiresCurrentMatchedHardwareEvidenceRows`
- `testIOSL12RealDeviceValidationRequiresFreshMatchedHardwareEvidenceRows`

Both tests verify the real-device gate remains blocked when current generic evidence exists but the matched connected iPhone 12-family hardware evidence is future-dated or stale.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRequiresCurrentMatchedHardwareEvidenceRows` | PASS | 1 test, 0 failures |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRequiresFreshMatchedHardwareEvidenceRows` | PASS | 1 test, 0 failures |
| `swift test` | PASS | 238 XCTest cases, 0 failures |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS | iPhone 12 simulator available, shutdown |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | SwiftPM-discovered package build succeeded |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | 238 XCTest cases, 1 skipped, 0 failures; `.xcresult` at `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.10_03-05-35-+0800.xcresult` |
| `xcrun xctrace list devices` | BLOCKED for real-device completion | No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max reported |
| `xcrun devicectl list devices --json-output -` | BLOCKED for real-device completion | Observed physical iPhone 15 Pro (`iPhone16,1`) unavailable and physical iPad Pro (`iPad14,4`) not iPhone 12-family |
| `git diff --check -- ios` | PASS | No whitespace errors reported |

## Current L12 Physical-Device Status

- SwiftPM validation: pass.
- iPhone 12 simulator validation: pass.
- Physical probe command coverage: both required commands were run in this batch.
- Real-device validation complete: false.
- Blocker: no connected physical iPhone 12-family device was available in the fresh physical probes, and no post-probe physical iPhone 12-family manual flow evidence was collected.

## Supervisor Checklist Recommendation

The supervisor should keep this item open:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No new authoritative blueprint checklist item should be marked complete from this batch, because this batch hardens and refreshes evidence for the still-open L12 real-device gate rather than completing that gate.
