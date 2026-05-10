# Stage 1 iOS L12 Same-Batch Gate Validation Refresh

- Generated local: 2026-05-10 12:07:42 CST
- Generated UTC: 2026-05-10T04:07:42Z
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Authoritative blueprint read but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot read but not edited: `Docs/todos_20260506.md`

## Batch Selection

The daily todo snapshot leaves one iOS-owned row open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No earlier iOS-owned L1/L2/L4/L5-L7/L9-L11 item is open. This bounded batch
therefore refreshed the L12 iOS validation evidence and confirmed the current
same-batch probe gate behavior already present in the iOS source tree.

## Implementation Evidence

Current iOS source tree contains the L12 same-batch physical probe guard in
`ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`:

- `IOSStageOneRealDeviceValidationReport` exposes
  `requiredProbeCommandBatchTolerance`, `requiredProbeCommandBatchSkew`, and
  `requiredProbeCommandsAreSameBatch`.
- `hasRequiredPhysicalProbeCommandCoverage` requires both required physical
  probe commands to be present, current, and observed within the same validation
  batch.
- `status` returns `blockedStaleRequiredProbeCommands` when required physical
  probe command observations are too far apart, even if both commands are
  individually current.
- The generated markdown report records required probe command skew and whether
  the required physical probe commands belong to the same batch.

Current regression coverage exists in
`ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`:

- `testIOSL12RealDeviceValidationRequiresRequiredProbeCommandsInSameBatch`
  verifies a 570-second skew between `xcrun xctrace list devices` and
  `xcrun devicectl list devices --json-output -` fails closed as
  `blockedStaleRequiredProbeCommands`.

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRequiresRequiredProbeCommandsInSameBatch` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 97 selected XCTest cases, 0 failures, 0 unexpected failures. |
| `swift test` | `ios/` | PASS | 272 XCTest cases, 0 failures, 0 unexpected failures, 47.722s test time. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS simulator inventory only | Exact `iPhone 12` simulator destination present in `Shutdown` state. This is not physical-device evidence. |
| `xcrun xctrace list devices` | `ios/` | PASS command, BLOCKED physical gate | Command exited 0. It listed the Mac host, two offline physical iOS/iPadOS records, and simulator destinations. The exact `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | PASS command, BLOCKED physical gate | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning: `No provider was found.` The physical inventory contained unavailable iPhone 15 Pro-class and unavailable iPad Pro 11-inch 4th generation-class records. No connected physical iPhone 12-family device was present. |
| `find . -maxdepth 2 \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -print \| sort` | `ios/` | BLOCKED app-target physical install/test | No `.xcodeproj` or `.xcworkspace` exists under `ios/`; this remains a SwiftPM library skeleton, so a physical app install/manual validation flow is not available from an iOS app target in this batch. |

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

This report is evidence for the current iOS L12 validation state and same-batch
probe gate coverage. It is not evidence that the physical real-device
validation item is complete.

Evidence path:

- `ios/docs/reports/stage1-ios-l12-same-batch-gate-validation-refresh-20260510-1207.md`
