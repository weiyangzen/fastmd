# Stage 1 iOS L12 iPhone 12-Class Evidence Hardening

- Generated: 2026-05-10 09:41:04 +0800
- Generated UTC: 2026-05-10T01:41:04Z
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Authoritative source read but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily snapshot read but not edited: `Docs/todos_20260506.md`

## Batch Selection

The authoritative blueprint and daily todo snapshot show no earlier open
iOS-owned implementation row. L1 iOS canonical fixtures, L2 core contracts, L4
iOS document entry, L5-L7, L9-L11, iPhone 12 simulator build/test, iOS
performance report, iOS security audit report, and rich fixture render report
are already complete.

The first still-open iOS-owned row remains:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch does not complete that physical-device gate. It tightens the iOS L12
manual evidence classifier so reports using the blueprint's own `iPhone
12-class hardware` wording can be accepted when, and only when, they also match
verified connected iPhone 12-family hardware and the full post-probe manual
flow evidence requirements.

## Implementation Evidence

- Updated `IOSStageOneRealDeviceFlowEvidence.hasPhysicalIPhone12FamilyEvidence`
  to accept bounded positive `iPhone 12-class hardware` and `iPhone 12 class
  hardware` phrases as physical iPhone 12-family evidence.
- Added matching absence phrases, such as `without iPhone 12-class hardware`
  and `no iPhone 12 class hardware`, to keep blocker or negative evidence from
  satisfying the real-device gate.
- Preserved existing requirements that manual evidence must be step-specific,
  current, post-probe, tied to the current probe batch, and matched against a
  verified connected hardware signal such as `iPhone13,3`.
- Added
  `testIOSL12RealDeviceValidationAcceptsIPhone12ClassHardwareManualEvidence`.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-iphone12-class-evidence-hardening-20260510-0941.md`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationAcceptsIPhone12ClassHardwareManualEvidence` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 89 selected XCTest cases, 0 failures. |
| `swift test` | `ios/` | PASS | 264 XCTest cases, 0 failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS simulator inventory only | Exact `iPhone 12` simulator destination is installed and currently `Shutdown`. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | PASS command, BLOCKED physical gate | Command exited 0 and listed the Mac host, unavailable physical iOS/iPadOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | PASS command, BLOCKED physical gate | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained unavailable iPhone 15 Pro-class and iPad Pro 11-inch 4th generation-class records, but no connected physical iPhone 12-family hardware. |

An earlier focused test attempt failed while the negative fixture expectation
was being corrected from a step-action blocker to a hardware-absence blocker.
The final focused, L12 slice, and full SwiftPM validations above are the
current passing evidence for this batch.

## Current Physical Probe Summary

| Sanitized physical record | Connection | Eligibility |
| --- | --- | --- |
| iPhone 15 Pro-class iOS hardware (`iPhone16,1`) | unavailable | not iPhone 12-family and not connected |
| iPad Pro 11-inch 4th generation-class iPadOS hardware (`iPad14,4`) | unavailable | not iPhone 12-family and not connected |

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
status, and validation status needed for L12 reconciliation. It intentionally
omits device names, hostnames, serial numbers, UDIDs, ECIDs, local network
identifiers, full paths outside the iOS workspace, and full probe JSON.

## Supervisor Reconciliation Recommendation

Keep this checklist item open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This report is completion evidence for the bounded iOS L12 classifier
hardening batch, not for the physical real-device validation item. It does not
replace the required connected physical iPhone 12-family manual validation
flow.

Evidence path:

- `ios/docs/reports/stage1-ios-l12-iphone12-class-evidence-hardening-20260510-0941.md`
