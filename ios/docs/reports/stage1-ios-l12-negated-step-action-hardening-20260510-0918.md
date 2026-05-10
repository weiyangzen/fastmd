# Stage 1 iOS L12 Negated Step Action Hardening

- Generated: 2026-05-10 09:18 CST
- Generated UTC: 2026-05-10T01:18Z
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

This bounded batch does not claim physical validation completion. It hardens
the iOS L12 evidence gate so negated manual flow rows such as "did not open
Markdown on physical iPhone 12-family hardware" cannot satisfy the
step-specific real-device flow requirement.

## Implementation Evidence

- Updated `IOSStageOneRealDeviceFlowEvidence.hasStepSpecificFlowEvidence` in
  `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`.
- Added a negated step-action detector for open, render, search, edit, save,
  and rotate evidence rows before accepting a manual row as step-specific
  completion evidence.
- Kept positive physical evidence valid when the negation is scoped to
  simulator-only language, such as `not simulator only; opened ... on physical
  iPhone 12-family hardware`.
- Added focused regression tests:
  - `testIOSL12RealDeviceValidationRejectsNegatedStepActionManualEvidence`
  - `testIOSL12RealDeviceValidationAllowsPositiveStepActionWithSimulatorNegation`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRejectsNegatedStepActionManualEvidence` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationAllowsPositiveStepActionWithSimulatorNegation` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 86 selected XCTest cases, 0 failures. |
| `swift test` | `ios/` | PASS | 261 XCTest cases, 0 failures. Swift Testing reported 0 tests in 0 suites with no failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported for iOS-owned changes before report creation. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | repository root | PASS simulator inventory | Found an exact `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `find ios -maxdepth 5 \( -name '*.xcodeproj' -o -name '*.xcworkspace' -o -name '*.xcscheme' \) -print` | repository root | PASS inventory | No checked-in iOS Xcode project, workspace, or shared scheme exists under `ios/`; Xcode resolves the package through SwiftPM. |
| `xcodebuild -list` | `ios/` | PASS | Xcode resolved package `FastMDMobile` and listed scheme `FastMDMobile`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | `ios/` | PASS | SwiftPM-resolved package scheme built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator`; `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | iPhone 12 simulator test run executed 261 XCTest cases with 1 simulator-only skip and 0 failures; `** TEST SUCCEEDED **`. |
| `xcrun xctrace list devices` | repository root | PASS command, BLOCKED physical gate | Probe exited 0. It listed the Mac host under devices, two unavailable physical iOS/iPadOS records under offline devices, and the exact `iPhone 12` entry only under simulators. |
| `xcrun devicectl list devices --json-output -` | repository root | PASS command, BLOCKED physical gate | Probe exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained unavailable iPhone 15 Pro-class and unavailable iPad Pro 11-inch 4th generation-class records. No connected physical iPhone 12-family hardware was present. |

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

- `ios/docs/reports/stage1-ios-l12-negated-step-action-hardening-20260510-0918.md`
