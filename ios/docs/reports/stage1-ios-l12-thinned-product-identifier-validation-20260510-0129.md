# Stage 1 iOS L12 Thinned Product Identifier Validation

- Generated: 2026-05-10 01:29 CST
- Lane: FastMD Stage 1 Mobile iOS live lane
- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot: `Docs/todos_20260506.md`
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Scope

The authoritative checklist and daily snapshot show all earlier iOS-owned
implementation layers closed through L11. This batch advanced the remaining L12
real-device gate by hardening iOS physical-device evidence parsing for
CoreDevice thinned product identifiers such as `iPhone13,3-A`.

No Android files, root `Docs/**` files, `.cron/**` files, renderer assets,
entitlements, privacy manifests, or WebKit surfaces were edited.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-thinned-product-identifier-validation-20260510-0129.md`

## Implementation Evidence

- `IOSStageOnePhysicalDeviceCandidate` now canonicalizes iPhone 12-family
  thinned product identifiers before matching hardware evidence.
- Canonicalization accepts valid suffix forms for known iPhone 12-family product
  identifiers, for example `iPhone13,3-A` -> `iPhone13,3`.
- The same path applies to parenthesized hardware strings such as
  `iPhone 12 mini (iPhone13,1-A)`.
- The gate still fails closed for unsupported or malformed near misses such as
  `iPhone13,30-A` and `iPhone13,3-`.
- Simulator and physical-device requirements are unchanged: simulator records
  cannot satisfy the real-device gate, and completion still requires a connected
  physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max plus full manual flow
  evidence.

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12Devicectl` | `ios/` | PASS | Built SwiftPM debug package and executed 10 focused devicectl parser tests with 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceValidationCanonicalizesThinnedProductIdentifiers` | `ios/` | PASS | Executed the new L12 canonicalization test with 0 failures. |
| `swift test` | `ios/` | PASS | Executed 233 XCTest cases with 0 failures and 0 unexpected failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | `ios/` | PASS | Built the SwiftPM-generated `FastMDMobile` scheme for the iPhone 12 simulator destination. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | Executed 233 XCTest cases on the iPhone 12 simulator destination with 1 expected process-spawn parity skip and 0 failures. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, offline physical iOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning: `No provider was found.` The physical inventory contained an unavailable iPhone 15 Pro-class record and an available paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local user paths, and
simulator identifiers are intentionally omitted from this report. Retained
hardware signals are limited to model classes needed to explain the L12 blocker.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

SwiftPM validation, iPhone 12 simulator inventory, iPhone 12 simulator build,
and iPhone 12 simulator tests pass in this environment. The blueprint still
requires a connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or
iPhone 12 Pro Max before any parity-complete release claim.

Because the required physical iPhone 12-family hardware was absent during this
batch, no physical-device install/test run and no manual open-render-search-
edit-save-rotate validation flow was attempted or claimed.

## Required Physical Flow Still Open

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Checklist Recommendation

Keep open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Items this batch can support as evidence, but not newly close:

- Current iOS SwiftPM validation evidence for the still-open physical real-device gate.
- Current iOS iPhone 12 simulator build/test evidence for the still-open physical real-device gate.
- Current iOS physical-device blocker evidence showing no connected physical iPhone 12-family hardware.
- L12 physical-device evidence parser hardening for CoreDevice thinned product identifiers.

Can mark complete from this batch:

- None. This batch hardens L12 evidence handling and refreshes validation
  results, but it does not complete physical iPhone 12-family validation.
