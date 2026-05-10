# Stage 1 iOS L12 Current Validation Refresh

Generated: 2026-05-10 02:41 CST

## Scope

- Lane: FastMD Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Authoritative checklist inputs reviewed but not edited: `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260506.md`.

The authoritative blueprint and daily todo snapshot show all iOS implementation rows closed except the physical iPhone 12-family validation gate. This batch refreshed the local SwiftPM gate, the iPhone 12 simulator prerequisite gates, and the physical-device inventory probes. The physical-device gate remains open because no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available.

## Files Changed

- `ios/docs/reports/stage1-ios-l12-current-validation-refresh-20260510-0241.md`

## Validation

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | Build completed and XCTest ran 236 tests with 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Found an available exact `iPhone 12` simulator destination in `Shutdown` state. This does not satisfy the physical-device gate. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | `ios/` | PASS | Generated SwiftPM/Xcode iPhone 12 simulator build completed with `** BUILD SUCCEEDED **`. Xcode emitted `IDERunDestination: Supported platforms for the buildables in the current scheme is empty`, but the scheme resolved and the build succeeded. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | Generated SwiftPM/Xcode iPhone 12 simulator test completed with `** TEST SUCCEEDED **`; 236 XCTest cases ran with 1 skipped and 0 failures. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.10_02-40-12-+0800.xcresult`. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0. It listed the Mac host, offline physical iOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical inventory contained one unavailable iPhone 15 Pro-class record and one available paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

Device names, UUIDs, serial numbers, ECIDs, hostnames, local network identifiers, full JSON payloads, and user-specific labels are intentionally omitted from this report. Hardware signals are limited to the model classes needed to explain the L12 blocker.

## Current L12 Result

The L12 physical iPhone 12-family real-device validation gate remains open.

Current local validation supports the SwiftPM gate and the iPhone 12 simulator build/test prerequisite rows. The blueprint still requires a connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max before any parity-complete release claim.

Because the required physical iPhone 12-family hardware was absent during this batch, no physical-device install/test run and no manual open-render-search-edit-save-rotate flow could be executed.

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Supervisor Reconciliation Recommendation

No new blueprint checklist item should be marked complete from this batch.

Keep this item open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence this batch provides:

- Current iOS SwiftPM validation passed.
- Current generated SwiftPM/Xcode iPhone 12 simulator build/test prerequisites passed.
- Current physical-device probes show no connected physical iPhone 12-family hardware.
- Current blocker evidence path: `ios/docs/reports/stage1-ios-l12-current-validation-refresh-20260510-0241.md`.
