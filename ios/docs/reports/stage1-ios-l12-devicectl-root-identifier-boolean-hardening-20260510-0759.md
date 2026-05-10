# Stage 1 iOS L12 Devicectl Root Identifier And Boolean Connection Hardening

- Generated: 2026-05-10 07:59:06 +0800
- Generated UTC: 2026-05-09T23:59:06Z
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

This batch advanced the L12 physical-device evidence parser. It does not claim
the physical-device gate complete.

## Implementation

- Hardened `IOSDevicectlDeviceListParser` so CoreDevice JSON can identify
  devices when newer or alternate schemas expose `id`, `udid`, or
  `deviceIdentifier` instead of only root `identifier`.
- Added fallback device-name aliases from root device fields while preserving
  the requirement for non-empty display and identifier evidence.
- Added explicit boolean connection evidence support for `connected`,
  `isConnected`, `available`, and `isAvailable` on root, device, or connection
  property dictionaries.
- Kept fail-closed behavior intact: unavailable, disconnected, unpaired,
  simulator-marked, non-physical, unsupported, and unverified iPhone 12-family
  candidates still cannot complete the physical iPhone 12-family validation
  gate.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-devicectl-root-identifier-boolean-hardening-20260510-0759.md`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DevicectlJSONParserAcceptsRootIdentifierAndBooleanConnectionFields` | `ios/` | PASS | 1 XCTest case, 0 failures. Covers root identifier aliases, boolean connection flags, and disconnected boolean fail-closed handling. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 79 XCTest cases, 0 failures. Covers L12 parser, simulator, performance, security, rich fixture, physical-device blocker, redaction, and reconciliation report contracts. |
| `swift test` | `ios/` | PASS | 254 XCTest cases, 0 failures, 0 unexpected failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found an available exact `iPhone 12` simulator destination in `Shutdown` state. This is not physical-device evidence. |
| `xcrun xctrace list devices` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0. It listed the Mac host as the only connected device, two offline physical iOS/iPadOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators. |
| `xcrun devicectl list devices --json-output -` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0 with JSON `outcome` = `success` after a local CoreDevice provider warning. Physical inventory contained unavailable non-iPhone-12-family iOS/iPadOS hardware only: iPhone 15 Pro-class / `iPhone16,1` and iPad Pro 11-inch 4th generation-class / `iPad14,4`. |

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

- `ios/docs/reports/stage1-ios-l12-devicectl-root-identifier-boolean-hardening-20260510-0759.md`
