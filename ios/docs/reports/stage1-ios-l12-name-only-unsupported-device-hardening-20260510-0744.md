# Stage 1 iOS L12 Name-Only Unsupported Device Hardening

- Generated: 2026-05-10 07:44:57 +0800
- Generated UTC: 2026-05-09T23:44:57Z
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Authoritative source read but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily snapshot read but not edited: `Docs/todos_20260506.md`

## Batch Selection

The authoritative blueprint and daily todo snapshot show no earlier open
iOS-owned implementation item. L1 iOS canonical fixtures, L2 core contracts,
L4 document entry, L5-L7, L9-L11, iPhone 12 simulator build/test, iOS
performance report, iOS security audit report, and rich fixture render report
are already complete.

The first still-open iOS-owned row remains:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch advanced that L12 gate by hardening the physical-device blocker
classification. It does not claim the physical-device gate complete.

## Implementation

- Updated `IOSStageOneRealDeviceValidationReport` so connected unsupported
  physical iOS records can be identified from explicit name-only model evidence
  such as `iPhone 15 Pro`, even when a probe source does not provide a hardware
  model string.
- Kept generic custom host/device names such as `QA iPhone` and Mac host rows
  out of the unsupported iOS physical-device count unless there is a bounded
  model signal or hardware-model field evidence.
- Added bounded name-only matching so `iPhone 15 Pro` is treated as unsupported
  iOS hardware while unrelated custom names do not produce false blockers.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-name-only-unsupported-device-hardening-20260510-0744.md`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationClassifiesNameOnlyConnectedUnsupportedIOSHardware` | `ios/` | PASS | 1 XCTest case, 0 failures. Covers connected name-only unsupported iOS hardware classification and report redaction. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DeviceProbeCandidateMergerFailsClosedOnHardwareIdentityConflicts` | `ios/` | PASS | 1 XCTest case, 0 failures. Confirms generic custom-name hardware conflicts still fail closed and are not promoted by the new name-only fallback. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | Final run executed 78 XCTest cases with 0 failures. An earlier run in this batch failed after the first implementation attempt classified generic `QA iPhone` as connected unsupported hardware; the implementation was narrowed and the final L12 run passed. |
| `swift test` | `ios/` | PASS | 253 XCTest cases, 0 failures, 0 unexpected failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported. |
| `xcrun xctrace list devices` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0. It listed the Mac host, offline physical iOS/iPadOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0 with JSON `outcome` = `success` after a local CoreDevice provider warning. Physical inventory contained unavailable iPhone 15 Pro-class and unavailable iPad Pro 11-inch 4th generation-class records. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

## Current L12 Physical-Device Status

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Connected physical iPhone 12-family device detected | OPEN |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Privacy And Redaction

This report records only device classes and validation status needed for L12
reconciliation. It intentionally omits raw device names, hostnames, serial
numbers, UDIDs, ECIDs, local network identifiers, full paths outside `ios/`,
and full probe JSON.

## Supervisor Recommendation

No blueprint checklist item should be newly marked complete from this batch.

Keep the following blueprint checklist item open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence path for reconciliation:

- `ios/docs/reports/stage1-ios-l12-name-only-unsupported-device-hardening-20260510-0744.md`
