# Stage 1 iOS L12 Physical Evidence Hardening

- Generated: 2026-05-10T01:26:53Z
- Lane: iOS live lane
- Ownership: `ios/**` only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Daily snapshot source: `Docs/todos_20260506.md`

## Batch Scope

The only still-open iOS-owned checklist item in the daily snapshot is:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch does not claim physical validation completion. It hardens the iOS
L12 manual evidence classifier so blocker phrasing such as "could not verify
physical iPhone 12-family hardware" or "failed to detect current physical
iPhone 12-family hardware" cannot satisfy the physical manual-flow evidence
requirement.

## Implementation Evidence

- Hardened `IOSStageOneRealDeviceFlowEvidence.hasPhysicalIPhone12FamilyEvidence`
  in `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`.
- Expanded physical-hardware negation detection to cover common blocker
  verbs and contractions around verify/detect/find/identify/observe wording.
- Added focused L12 tests in
  `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`:
  - `testIOSL12RealDeviceValidationRejectsUnverifiedHardwareClaimAsPhysicalManualEvidence`
  - `testIOSL12RealDeviceValidationRejectsMissingHardwareDetectionAsPhysicalManualEvidence`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRejectsUnverifiedHardwareClaimAsPhysicalManualEvidence` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 88 selected XCTest cases, 0 failures. |
| `swift test` | `ios/` | PASS | 263 XCTest cases, 0 failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS simulator inventory | Found exact `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | PASS command, BLOCKED physical gate | Probe listed the Mac host, two offline physical iOS/iPadOS records, and the exact `iPhone 12` only under simulators. |
| `xcrun devicectl list devices --json-output -` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained unavailable iPhone 15 Pro-class and unavailable iPad Pro 11-inch 4th generation-class records. |

## Current Physical Probe Summary

| Sanitized physical record | Connection | Eligibility |
| --- | --- | --- |
| iPhone 15 Pro-class iOS hardware (`iPhone16,1`) | unavailable | not iPhone 12-family and not connected |
| iPad Pro 11-inch 4th generation-class iPadOS hardware (`iPad14,4`) | unavailable | not iPhone 12-family and not connected |

No connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12
Pro Max was available during this batch. Therefore no physical install/test
run and no manual open-render-search-edit-save-rotate flow were performed.

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

## Privacy / Redaction Note

This report records only device classes, hardware family identifiers, connection
state, command status, and validation status needed for L12 reconciliation. It
does not include full device UUIDs, serial numbers, ECIDs, document content,
full file paths, query strings, or clipboard content.

## Supervisor Reconciliation Recommendation

- Keep L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` open.
- Use this report as additional evidence that the iOS real-device completion
  gate rejects negated/unverified physical-hardware manual evidence.
- Evidence path:
  `ios/docs/reports/stage1-ios-l12-physical-evidence-hardening-20260510-0926.md`

