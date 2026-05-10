# Stage 1 iOS L12 Negated Connected Hardware Signal Hardening

- Generated local: 2026-05-10 10:25:42 CST
- Generated UTC: 2026-05-10T02:25:43Z
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Authoritative blueprint read but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot read but not edited: `Docs/todos_20260506.md`

## Batch Selection

The authoritative blueprint and daily todo snapshot show no earlier open
iOS-owned implementation row. L1 iOS canonical fixtures, L2 core contracts, L4
iOS document entry, L5-L7, L9-L11, iPhone 12 simulator build/test, iOS
performance report, iOS security audit report, and rich fixture render report
are already complete.

The first still-open iOS-owned row remains:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch hardens that L12 physical real-device gate. It does not complete the
physical-device validation gate because no connected physical iPhone 12-family
hardware was available.

## Implementation Evidence

- Hardened `IOSStageOneRealDeviceFlowEvidence.verifiedHardwareSignalsReferenced(_:)` so a connected verified hardware token only counts when the token is affirmed in the manual evidence clause.
- Added `containsAffirmedBoundedHardwareSignal` and verified-hardware-reference negation checks for wording such as `did not match connected verified hardware iPhone13,3`.
- Kept positive physical evidence valid when the negated clause targets simulator-only evidence, such as `not simulator only; ... iPhone13,3`.
- Added `testIOSL12RealDeviceValidationRejectsNegatedConnectedHardwareSignalMatch` covering both the blocked negated-token case and the positive simulator-negation case.

Changed files:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-negated-connected-hardware-signal-hardening-20260510-1025.md`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 90 selected XCTest cases executed, 0 failures, 0 unexpected failures. Includes new negated connected hardware signal coverage. |
| `swift test` | `ios/` | PASS | 265 XCTest cases executed, 0 failures, 0 unexpected failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS simulator inventory only | Exact `iPhone 12` simulator destination present in `Shutdown` state. This is not physical-device evidence. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | `ios/` | PASS | SwiftPM-generated `FastMDMobile` scheme built on the iPhone 12 simulator destination; `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | `** TEST SUCCEEDED **`; 265 XCTest cases executed, 1 skipped, 0 failures, 0 unexpected failures. |
| `xcrun xctrace list devices` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0 and listed the Mac host, two offline physical iOS/iPadOS records, and simulator destinations. The exact `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained unavailable iPhone 15 Pro-class and unavailable iPad Pro 11-inch 4th generation-class records, but no connected physical iPhone 12-family device. |

## Current Physical Probe Summary

| Sanitized physical record | Connection | Eligibility |
| --- | --- | --- |
| iPhone 15 Pro-class iOS hardware (`iPhone16,1`) | unavailable/offline | not iPhone 12-family and not connected |
| iPad Pro 11-inch 4th generation-class iPadOS hardware (`iPad14,4`) | unavailable/offline | not iPhone 12-family and not connected |

No connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12
Pro Max was available during this batch. Therefore no physical-device install,
manual open-render-search-edit-save-rotate flow, or physical real-device
performance evidence was attempted or claimed.

## Required Physical Flow Still Open

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

This report records only device classes, product identifiers, connection
status, and validation outcomes needed for L12 reconciliation. It intentionally
omits device names, hostnames, serial numbers, UDIDs, ECIDs, local network
identifiers, full probe JSON, document content, query strings, and clipboard
content.

## Supervisor Reconciliation Recommendation

Keep this checklist item open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

The supervisor can use this report as evidence that the iOS L12 real-device
gate is stricter against negated connected-hardware manual evidence, while the
physical iPhone 12-family validation remains blocked by lack of connected
eligible hardware.

Evidence path:

- `ios/docs/reports/stage1-ios-l12-negated-connected-hardware-signal-hardening-20260510-1025.md`
