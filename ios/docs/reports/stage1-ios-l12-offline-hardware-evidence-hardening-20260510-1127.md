# Stage 1 iOS L12 Offline Hardware Evidence Hardening

- Generated local: 2026-05-10 11:27:06 CST
- Generated UTC: 2026-05-10T03:27:06Z
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

This batch does not complete that physical-device gate. It hardens the L12
manual evidence classifier so stale inventory wording such as disconnected,
offline, unavailable, or unpaired iPhone 12-family hardware cannot satisfy
physical manual-flow evidence or connected verified hardware matching.

## Implementation Evidence

- Updated `IOSStageOneRealDeviceFlowEvidence` hardware absence and verified
  hardware-reference negation handling to treat `disconnected`, `offline`,
  `unavailable`, and `unpaired` hardware language as non-completing evidence.
- Added `signal` and `product` to the scoped physical-hardware negation tokens
  so phrases such as `offline connected verified hardware signal iPhone13,3`
  are rejected rather than treated as positive current hardware evidence.
- Added focused XCTest coverage for disconnected physical iPhone 12-family
  manual evidence and offline verified hardware signal references.

Changed implementation files:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRejectsDisconnectedHardwareManualEvidence` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRejectsOfflineVerifiedHardwareReference` | `ios/` | PASS | 1 selected XCTest, 0 failures after hardening the negation scope. |
| `swift test` | `ios/` | PASS | 268 XCTest cases executed, 0 failures, 0 unexpected failures, 45.569s test time. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS simulator inventory only | Exact `iPhone 12` simulator destination present in `Shutdown` state. This is not physical-device evidence. |
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

This report records only hardware classes, product identifiers, connection
status, and validation outcomes needed for L12 reconciliation. It intentionally
omits device names, hostnames, serial numbers, UDIDs, ECIDs, local network
identifiers, full probe JSON, document content, query strings, and clipboard
content.

## Supervisor Reconciliation Recommendation

Keep this checklist item open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

The supervisor can use this report as current evidence that the iOS SwiftPM
gate passes after the L12 evidence classifier hardening, and that the physical
iPhone 12-family gate is still blocked by lack of connected eligible hardware.

Evidence path:

- `ios/docs/reports/stage1-ios-l12-offline-hardware-evidence-hardening-20260510-1127.md`
