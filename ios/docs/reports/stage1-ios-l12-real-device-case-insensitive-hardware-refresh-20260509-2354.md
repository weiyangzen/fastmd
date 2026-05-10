# Stage 1 iOS L12 Real-Device Hardware Signal Refresh - 2026-05-09 23:54 +0800

## Batch Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Repository: `/Users/wangweiyang/GitHub/fastmd`.
- Ownership respected: only `ios/**` was written.
- Authoritative blueprint: `Docs/Stage1_Mobile_Blueprint.md`.
- Daily todo snapshot: `Docs/todos_20260506.md`.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

The todo snapshot and blueprint show L1 through L11 complete for iOS. The only
open iOS checklist item remains the physical iPhone 12-family validation gate.
This batch therefore hardened the iOS physical-device evidence gate and refreshed
local validation/probe evidence. It did not edit Android files, root `Docs/**`,
`.cron/**`, app entitlements, privacy manifests, renderer assets, or WebKit
surfaces.

## Changed iOS Files

| File | Change |
| --- | --- |
| `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift` | Normalized iPhone 12-family product identifiers and marketing names case-insensitively before eligibility and verified-hardware checks. The gate still requires a physical, connected iPhone 12-family candidate and still treats plain `iPhone 12` marketing-name-only evidence as unverified. |
| `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift` | Added L12 coverage for mixed-case hardware signals such as `IPHONE13,3` and `iphone 12 pro max`, while preserving fail-closed behavior for ambiguous plain `IPHONE 12` marketing evidence. |

## Validation Results

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | `ios/` | PASS | Built the SwiftPM package and executed 52 selected L12 XCTest cases with 0 failures and 0 unexpected failures. |
| `swift test` | `ios/` | PASS | Built the SwiftPM package and executed 227 XCTest cases with 0 failures and 0 unexpected failures. Test suite completed at 2026-05-09 23:53:22 +0800 after 19.181 seconds. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found one available `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical inventory contained non-iPhone-12-family hardware only: unavailable iPhone 15 Pro / `iPhone16,1` and paired iPad Pro 11-inch 4th generation / `iPad14,4`. |
| `git diff --check -- ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift` | repo root | PASS with repository caveat | No whitespace errors were reported. The local `ios/**` tree is currently untracked, so Git diff cannot show the source patch until the iOS tree is added to version control. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local paths, and simulator
identifiers are intentionally omitted from this report. Retained hardware
signals are limited to model classes and product identifiers needed to explain
the L12 blocker.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation, iPhone 12 simulator inventory,
and physical-device discovery probes. The blueprint still requires a connected
physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max before
any parity-complete release claim. No connected physical iPhone 12-family device
was available during this batch.

Because the required physical device was absent, no physical-device install/test
run and no manual open-render-search-edit-save-rotate validation flow was
performed in this batch.

## Required Physical Flow Status

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

Recommended checklist change:

- Keep L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` OPEN.

No blueprint checklist item should be newly marked complete from this batch. The
batch provides implementation hardening for the still-open L12 physical-device
gate plus current blocker evidence, and confirms the iOS SwiftPM validation
suite is passing after the change.
