# Stage 1 iOS L12 Devicectl Unpaired Table State Hardening

- Generated local: 2026-05-10 11:32:21 CST
- Generated UTC: 2026-05-10T03:32:21Z
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
`devicectl` table parser so parenthesized disconnected availability qualifiers
cannot make a physical iPhone 12-family row look connected.

## Implementation Evidence

- Updated `IOSDevicectlDeviceListParser` table-state handling so `available`
  rows with disconnected qualifiers such as `unpaired`, `offline`,
  `disconnected`, `untrusted`, or `not paired` fail closed as disconnected.
- Preserved the existing positive path for `available (paired)` rows.
- Added focused XCTest coverage that rejects `available (unpaired)` and
  `available (offline)` iPhone 12-family table rows while accepting
  `available (paired)`.

Changed implementation files:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DevicectlTableParserRejectsDisconnectedAvailabilityQualifiers` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test` | `ios/` | PASS | 269 XCTest cases executed, 0 failures, 0 unexpected failures, 48.821s test time. |
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
gate passes after the `devicectl` table-state hardening, and that the physical
iPhone 12-family gate is still blocked by lack of connected eligible hardware.

Evidence path:

- `ios/docs/reports/stage1-ios-l12-devicectl-unpaired-table-state-hardening-20260510-1132.md`
