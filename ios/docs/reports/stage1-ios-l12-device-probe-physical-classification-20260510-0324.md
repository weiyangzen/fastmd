# Stage 1 iOS L12 Device Probe Physical Classification Batch

- Generated: 2026-05-10 03:24 CST
- Generated UTC: 2026-05-09T19:24Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Ownership: `ios/**` only
- Authoritative blueprint reviewed but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot reviewed but not edited: `Docs/todos_20260506.md`
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Scope

This bounded batch tightened the iOS L12 physical-device evidence model. The
real-device gate already requires both `xcrun xctrace list devices` and
`xcrun devicectl list devices --json-output -`; this patch improves how those
two probe sources are merged.

The change keeps standalone `devicectl` JSON records fail-closed when they lack
explicit physical reality evidence, but allows matching `xctrace` physical
section evidence or `devicectl` table model evidence to supply the missing
physical classification when the JSON row has no explicit simulator marker.
Explicit simulator evidence still wins and is not merged away by a same-name
physical row.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-device-probe-physical-classification-20260510-0324.md`

## Implementation Evidence

- Added `hasExplicitSimulatorEvidence` to `IOSStageOnePhysicalDeviceCandidate`.
- Marked simulator-section `xctrace` rows, simulator-looking `devicectl` table
  rows, and explicit virtual/simulator JSON rows as explicit simulator evidence.
- Updated `IOSDevicectlDeviceListParser` merge behavior so a table row can
  preserve physical classification for a matching JSON row that has no
  explicit simulator marker.
- Updated `IOSStageOneDeviceProbeCandidateMerger` so name-only cross-probe
  rows can merge when the simulator classification conflict is only caused by
  missing JSON reality evidence.
- Preserved fail-closed behavior for standalone JSON without physical reality
  evidence and for explicit simulator evidence.

## Test Evidence

Added three focused XCTest cases:

- `testIOSL12DevicectlParserUsesTablePhysicalEvidenceWhenJSONRealityIsMissing`
- `testIOSL12DeviceProbeCandidateMergerKeepsXctracePhysicalClassificationWhenDevicectlRealityIsMissing`
- `testIOSL12DeviceProbeCandidateMergerDoesNotMergeExplicitSimulatorEvidenceByName`

The existing fail-closed test remains passing:

- `testIOSL12DevicectlJSONParserFailsClosedWithoutPhysicalRealityEvidence`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 66 XCTest cases, 0 failures. |
| `swift test` | `ios/` | PASS | 241 XCTest cases, 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Exact `iPhone 12` simulator destination was available in `Shutdown` state. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | 241 XCTest cases, 1 simulator-only skip, 0 failures; `.xcresult` at `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.10_03-22-48-+0800.xcresult`. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 and listed the Mac host, offline physical iOS device records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical inventory contained one unavailable iPhone 15 Pro-class record and one available paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
| `git diff --check -- ios` | repository root | PASS | No whitespace errors reported. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local network
identifiers, user-specific labels, and raw JSON payloads are intentionally
omitted. Hardware signals are limited to the model classes needed to explain why
the L12 physical gate remains blocked.

## Current L12 Physical-Device Status

- SwiftPM validation: pass.
- iPhone 12 simulator validation: pass.
- Physical probe command coverage: both required commands were run in this batch.
- Real-device validation complete: false.
- Blocker: no connected physical iPhone 12-family device was available in the
  fresh physical probes, and no post-probe physical iPhone 12-family manual
  open-render-search-edit-save-rotate flow was collected.

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

- None. This batch provides implementation hardening plus fresh validation and
  blocker evidence, but it does not complete the required physical iPhone
  12-family validation.
