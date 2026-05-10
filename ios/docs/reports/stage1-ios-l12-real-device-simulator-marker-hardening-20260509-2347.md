# Stage 1 iOS L12 Real-Device Simulator-Marker Hardening - 2026-05-09 23:47 +0800

## Batch Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Repository: `/Users/wangweiyang/GitHub/fastmd`.
- Ownership respected: only `ios/**` was written.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Implementation batch: harden iOS physical-device evidence parsing so `devicectl` JSON entries with explicit CoreSimulator / iOS Simulator markers cannot satisfy the physical iPhone 12-family gate, even when other fields contain iPhone 12-family names or product identifiers.

## Changed iOS Files

| File | Change |
| --- | --- |
| `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift` | Added simulator-marker detection for `devicectl` JSON device evidence across hardware, device, and connection properties before evaluating physical iPhone 12-family eligibility. |
| `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift` | Added coverage proving simulator-marked `devicectl` entries fail closed despite `reality = physical` and `productType = iPhone13,3`, while a true physical iPhone 12-family entry remains eligible. |

## Validation Results

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | Built the SwiftPM package and executed 226 XCTest cases with 0 failures and 0 unexpected failures. Test suite finished at 2026-05-09 23:42:51 +0800 after 15.608 seconds. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | `ios/` | PASS | Built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` against `iPhoneSimulator26.4.sdk`; command ended with `** BUILD SUCCEEDED **` at 2026-05-09 23:47:22 +0800. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | repo root | PASS for simulator inventory only | Found an available `iPhone 12` simulator destination in `Shutdown` state: `1B6FEADC-308B-4069-B734-3C9C207E633F`. This does not satisfy the physical-device gate. |
| `xcrun xctrace list devices` | repo root | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, two offline physical devices, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | repo root | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. The physical inventory contained non-iPhone-12-family hardware only: unavailable iPhone 15 Pro / `iPhone16,1` and paired iPad Pro 11-inch 4th generation / `iPad14,4`. |

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

The local environment supports SwiftPM validation, iPhone 12 simulator inventory, and iPhone 12 simulator build validation. The blueprint still requires a connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max before any parity-complete release claim. No connected physical iPhone 12-family device was available during this batch.

Because the required physical device was absent, no physical-device install/test run and no manual open-render-search-edit-save-rotate validation flow was performed in this batch.

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

No blueprint checklist item should be newly marked complete from this batch. The batch provides implementation hardening for the still-open L12 physical-device gate plus current blocker evidence, and confirms the iOS SwiftPM and iPhone 12 simulator build validations are passing.
