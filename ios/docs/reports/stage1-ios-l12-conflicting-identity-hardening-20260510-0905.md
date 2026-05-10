# Stage 1 iOS L12 Conflicting Identity Hardening

Date: 2026-05-10

## Scope

- Worker lane: iOS live lane.
- Ownership: `ios/**` only.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

The physical iPhone 12-family validation gate remains open because this host
still has no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max.
This batch tightened the iOS L12 evidence model so contradictory hardware
identity records cannot satisfy, or partially satisfy, the physical-device
gate.

## Implementation

- Hardened `IOSStageOnePhysicalDeviceCandidate` identity checks in `IOSAutomatedValidationGates.swift`.
- A candidate whose hardware evidence combines an iPhone 12-family marketing
  name with a non-iPhone-12 product identifier, such as `iPhone 12 Pro
  (iPhone16,1)`, now fails closed as unsupported hardware.
- The same guard is applied to both broad iPhone 12-family eligibility and
  verified hardware evidence, preventing manual evidence from matching against
  a conflicted candidate.
- Compatible identities, such as `iPhone 12 Pro (iPhone13,3)`, remain accepted
  and still expose both the product identifier and specific marketing-name
  manual evidence signals.
- Added
  `testIOSL12RealDeviceValidationRejectsConflictingMarketingNameAndProductIdentifier`.

## Validation

| Command | Working directory | Result | Notes |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationRejectsConflictingMarketingNameAndProductIdentifier` | `ios/` | PASS | 1 selected XCTest, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | 84 selected XCTest cases, 0 failures. |
| `swift test` | `ios/` | PASS | 259 XCTest cases, 0 failures. |
| `git -C .. diff --check -- ios` | `ios/` | PASS | No whitespace errors reported. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | repository root | PASS simulator inventory only | Exact `iPhone 12` simulator destination is installed and currently `Shutdown`. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | repository root | PASS command, BLOCKED physical gate | Command exited 0 and listed the Mac host, offline physical iOS/iPadOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | repository root | PASS command, BLOCKED physical gate | Command exited 0 with JSON `outcome = success` after a local CoreDevice provider warning. It reported unavailable physical iPhone 15 Pro-class and iPad Pro 11-inch 4th generation-class records, but no connected physical iPhone 12-family hardware. |

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

## Privacy Notes

This report records only hardware classes, product identifiers, connection
status, and validation status needed for L12 reconciliation. It intentionally
omits device names, UUIDs, serial numbers, ECIDs, hostnames, local user paths,
and full probe JSON.

## Supervisor Reconciliation Recommendation

Keep this checklist item open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This report is completion evidence for the bounded iOS L12 hardening batch, not
for the physical real-device validation item. It does not replace the required
connected physical iPhone 12-family manual validation flow.

Evidence path:

- `ios/docs/reports/stage1-ios-l12-conflicting-identity-hardening-20260510-0905.md`
