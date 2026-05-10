# Stage 1 iOS L12 JSON Availability Qualifier Hardening

- Generated local: 2026-05-10 11:37:30 CST
- Generated UTC: 2026-05-10T03:37:30Z
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
`devicectl` JSON parser so CoreDevice state strings such as
`available (unpaired)` and `available (not paired)` cannot be reduced to the
base `available` state and counted as connected iPhone 12-family hardware.

## Implementation Evidence

- Updated `IOSDevicectlDeviceListParser` JSON connection-state handling to
  fail closed when `deviceState`, `pairingState`, or `tunnelState` contains a
  disconnected qualifier.
- The disconnected qualifier list now applies consistently to JSON and table
  probe surfaces: `disconnected`, `not paired`, `offline`, `unpaired`, and
  `untrusted`.
- Added focused XCTest coverage proving `available (unpaired)` and
  `available (not paired)` JSON rows remain disconnected while a paired,
  connected iPhone 12-family row remains eligible.

Changed implementation files:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DevicectlJSONParserRejectsDisconnectedAvailabilityQualifiers` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test` | `ios/` | PASS | 270 XCTest cases executed, 0 failures, 0 unexpected failures, 45.708s test time. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS simulator inventory only | Exact `iPhone 12` simulator destination present in `Shutdown` state. This is not physical-device evidence. |
| `xcrun xctrace list devices` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0 and listed the Mac host, two offline physical iOS/iPadOS records, and simulator destinations. The exact `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained unavailable iPhone 15 Pro-class and unavailable iPad Pro 11-inch 4th generation-class records, but no connected physical iPhone 12-family device. |

## Xcode Project Blocker

No `.xcodeproj` or `.xcworkspace` exists under `ios/` in this SwiftPM skeleton.
Therefore an app-target `xcodebuild` physical-device install/test run was not
available in this batch. The real-device gate still requires connected eligible
hardware plus an app target/scheme capable of the manual open, render, search,
edit, save, and rotate validation flow.

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
gate passes after JSON availability qualifier hardening, and that the physical
iPhone 12-family gate is still blocked by lack of connected eligible hardware
and by the current SwiftPM-only skeleton lacking an app project/scheme for a
physical install/test flow.

Evidence path:

- `ios/docs/reports/stage1-ios-l12-json-availability-qualifier-hardening-20260510-1137.md`
