# Stage 1 iOS L12 Bounded Hardware Token And Blocker Refresh

- Generated: 2026-05-10 08:50 CST
- Generated UTC: 2026-05-10T00:50Z
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Authoritative source read but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily snapshot read but not edited: `Docs/todos_20260506.md`

## Batch Selection

The authoritative checklist shows L1 iOS canonical fixtures, L2 core
contracts, L4 iOS document entry, L5-L7, L9-L11, iPhone 12 simulator
build/test, iOS performance report, iOS security audit report, and rich
fixture render report are already complete.

The first still-open iOS-owned row remains:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch kept that gate fail-closed and tightened the iOS L12 evidence
classifier used by real-device validation reports.

## Implementation Evidence

- Hardened `IOSStageOneRealDeviceFlowEvidence.hasPhysicalIPhone12FamilyEvidence` so product identifiers and marketing-name hardware tokens must match bounded tokens, not arbitrary substrings.
- A product-token-only manual evidence row containing `iPhone13,30` now reports as missing valid physical iPhone 12-family evidence instead of being treated as a valid iPhone 12-family token that later mismatches connected hardware.
- Preserved existing behavior where explicit phrasing such as `physical iPhone 12-family hardware` still counts as physical-family evidence and is then checked against the connected verified hardware signal.
- Added focused regression coverage in `testIOSL12RealDeviceValidationRequiresBoundedHardwareTokenForPhysicalManualEvidence`.
- Updated `testIOSL12RealDeviceValidationRequiresBoundedHardwareSignalMatch` to keep the existing explicit-physical-family mismatch semantics intact.

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRequiresBoundedHardwareSignalMatch` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRequiresBoundedHardwareTokenForPhysicalManualEvidence` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 83 selected XCTest cases, 0 failures. |
| `swift test` | `ios/` | PASS | 258 XCTest cases, 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | repository root | PASS simulator inventory | Exact `iPhone 12` simulator destination is installed and currently `Shutdown`. This does not satisfy the physical-device gate. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | `ios/` | PASS | SwiftPM-resolved `FastMDMobile` scheme built `FastMDMobileCore` for the iPhone 12 simulator destination; `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | iPhone 12 simulator test run executed 258 XCTest cases with 1 skip and 0 failures; `** TEST SUCCEEDED **`. |
| `xcrun xctrace list devices` | repository root | PASS command, BLOCKED physical gate | Probe exited 0. It listed the Mac host, unavailable physical iOS/iPadOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | repository root | PASS command, BLOCKED physical gate | Probe exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical iOS/iPadOS inventory was unavailable; no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported for iOS-owned changes. |

An earlier focused `swift test --filter FastMDMobileCoreTests/testIOSL12`
attempt failed while the new test expectation was being corrected. The final
focused, L12 slice, full SwiftPM, and iPhone 12 simulator validations above
are the current evidence for this batch.

## Current Physical Probe Summary

| Sanitized physical record | Connection | Eligibility |
| --- | --- | --- |
| iPhone 15 Pro-class iOS hardware (`iPhone16,1`) | unavailable | not iPhone 12-family and not connected |
| iPad Pro 11-inch 4th generation-class iPadOS hardware (`iPad14,4`) | unavailable | not iPhone 12-family and not connected |

No connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12
Pro Max was available during this batch. Therefore no physical-device install,
manual open-render-search-edit-save-rotate flow, or physical real-device
completion claim was attempted.

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
omits raw device names, hostnames, serial numbers, UDIDs, ECIDs, local network
identifiers, full paths outside the iOS workspace, and full probe JSON.

## Supervisor Recommendation

Keep the following blueprint checklist item open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch is implementation hardening and current blocker evidence for the
still-open physical-device gate. It does not replace the required connected
physical iPhone 12-family manual validation flow.

Evidence path for reconciliation:

- `ios/docs/reports/stage1-ios-l12-bounded-hardware-token-and-blocker-refresh-20260510-0850.md`
