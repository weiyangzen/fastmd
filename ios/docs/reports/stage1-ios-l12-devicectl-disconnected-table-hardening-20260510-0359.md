# Stage 1 iOS L12 Devicectl Disconnected Table Hardening Batch

## Scope

- Worker: FastMD Stage 1 Mobile iOS live lane.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Batch boundary: iOS-only implementation and validation evidence under `ios/**`.

## Summary

This bounded batch keeps the physical iPhone 12-family validation gate open, but
hardens the iOS physical-device probe parser against the current local
`devicectl` output shape.

The live probe reported a table row with `available (paired)` for an iPad while
the JSON payload for the same device reported `tunnelState = disconnected`.
The real-device gate now fails closed when JSON and table connection evidence
conflict: table evidence can still enrich hardware/model fields, but it cannot
upgrade a JSON-disconnected or JSON-unavailable tunnel into a connected device.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-devicectl-disconnected-table-hardening-20260510-0359.md`

## Implementation Evidence

- Added `hasExplicitConnectionEvidence` to `IOSStageOnePhysicalDeviceCandidate`.
- Updated `IOSDevicectlDeviceListParser.merge(jsonCandidates:tableCandidates:)`
  to merge connection status conservatively:
  - if both JSON and table have explicit connection evidence, both must say
    connected;
  - if only one side has explicit connection evidence, that side controls the
    result;
  - if neither side has explicit connection evidence, the candidate stays
    disconnected.
- Updated the L12 regression test for the live `available (paired)` plus
  `tunnelState = disconnected` shape.

## Live Probe Evidence

| Command | Result | Evidence |
| --- | --- | --- |
| `xcrun xctrace list devices` | BLOCKED for physical iPhone 12-family validation | Command exited 0. It listed the Mac host, offline physical iOS device records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. Physical inventory contained one unavailable iPhone 15 Pro-class record and one paired iPad Pro 11-inch 4th generation-class record whose JSON tunnel was disconnected. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS for simulator inventory only | Exact `iPhone 12` simulator destination was available in `Shutdown` state. |

## Validation

| Command | Working directory | Result | Notes |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DevicectlParserDoesNotUpgradeDisconnectedJSONTunnelFromTableAvailability` | `ios/` | PASS | 1 XCTest case, 0 failures. |
| `swift test` | `ios/` | PASS | 244 XCTest cases, 0 failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported. |

## Current L12 Physical-Device Status

- SwiftPM validation: pass.
- iPhone 12 simulator inventory: available.
- Physical iPhone 12-family validation: open.
- Blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max
  was available in the fresh physical probes, and no post-probe physical
  iPhone 12-family manual flow evidence was collected.

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Reconciliation

Still open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No new authoritative blueprint checklist item should be marked complete from
this batch. This report strengthens and refreshes blocker evidence for the
still-open physical-device gate, but it does not complete the required physical
iPhone 12-family flow.
