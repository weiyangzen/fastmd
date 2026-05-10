# Stage 1 iOS L12 Step-Specific Real-Device Evidence Batch

- Generated: 2026-05-10 03:36 CST
- Generated UTC: 2026-05-09T19:36Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Ownership: `ios/**` only
- Authoritative blueprint reviewed but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot reviewed but not edited: `Docs/todos_20260506.md`
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Scope

This bounded batch hardens the still-open iOS L12 real-device validation gate.
The gate already required current probe evidence, connected verified iPhone
12-family hardware evidence, and current post-probe manual evidence for every
Stage 1 flow step. This batch adds one more fail-closed check: every manual
evidence row must describe the specific Stage 1 action it claims to validate.

This prevents a false pass where repeated generic text such as "validated
current physical iPhone 12-family hardware" could satisfy all flow rows without
actually documenting open, render, search, full source edit, block edit, save,
and rotation.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-step-specific-real-device-evidence-20260510-0336.md`

## Implementation Evidence

- Added `blockedMissingStepSpecificManualFlowEvidence` to the L12 real-device
  validation status.
- Added `IOSStageOneRealDeviceFlowEvidence.hasStepSpecificFlowEvidence`.
- Added `completedStepsWithStepSpecificFlowEvidence` and
  `hasStepSpecificFlowEvidenceForEveryRequiredStep` to the manual flow audit.
- Updated final real-device status ordering so generic manual evidence blocks
  before device-specific or timestamp-specific checks can pass the report.
- Added markdown output for:
  - `Manual flow step-specific evidence complete: ...`
  - manual evidence row result `FLOW-MISSING`

## Test Evidence

Added focused XCTest coverage:

- `testIOSL12RealDeviceValidationRequiresStepSpecificManualEvidence`
- `testIOSL12RealDeviceValidationAcceptsStepSpecificManualEvidence`

Updated the existing newest-evidence tie-break test so its custom open-flow row
also names the Markdown document action required by the stricter evidence
contract.

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRequiresStepSpecificManualEvidence` | `ios/` | PASS | 1 XCTest case, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationAcceptsStepSpecificManualEvidence` | `ios/` | PASS | 1 XCTest case, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 68 XCTest cases, 0 failures. |
| `swift test` | `ios/` | PASS | 243 XCTest cases, 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Exact `iPhone 12` simulator destination available in `Shutdown` state. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | 243 XCTest cases, 1 simulator-only skip, 0 failures; `.xcresult` at `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.10_03-36-01-+0800.xcresult`. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0. It listed the Mac host, offline physical iOS device records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical inventory contained an unavailable iPhone 15 Pro-class record and an available paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
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
