# Stage 1 iOS L12 Live Validation Batch

- Generated: 2026-05-10 07:25 CST
- Generated UTC: 2026-05-09T23:25Z
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Authoritative source read but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily snapshot read but not edited: `Docs/todos_20260506.md`

## Batch Selection

The blueprint and daily todo snapshot show the earlier iOS-owned implementation
layers already reconciled. The first still-open iOS-owned row is:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch therefore refreshed the iOS validation evidence and physical-device
blocker status. No Android files or root Docs checklist files were edited.

## Result

No blueprint checklist item should be newly marked complete from this batch.

The local SwiftPM and iPhone 12 simulator validation gates passed. The physical
device probes also ran, but they did not show a connected physical iPhone 12,
iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max. Because no matching
physical device was available, the Stage 1 physical open, render, search, edit,
save, and rotate flow was not attempted and the L12 real-device gate remains
open.

## Changed iOS Files

- `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260510-0725.md`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | Build completed, then 250 XCTest cases executed with 0 failures and 0 unexpected failures in 21.862 seconds of test execution time. The overall XCTest suite completed in 21.883 seconds. Swift Testing reported 0 tests in 0 suites with no failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS simulator inventory | Probe exited 0 and found an exact `iPhone 12` simulator destination in `Shutdown` state. Device identifier omitted. |
| `xcodebuild -list` | `ios/` | PASS | Xcode resolved the SwiftPM workspace and listed scheme `FastMDMobile`. No checked-in `.xcodeproj` or `.xcworkspace` exists; the scheme is provided through the SwiftPM package workspace. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | `ios/` | PASS | Build resolved package `FastMDMobile`, targeted the iPhone 12 simulator SDK path, and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | Test run executed 250 XCTest cases with 1 simulator-only skip and 0 failures. The run ended with `** TEST SUCCEEDED **`. |
| `xcrun xctrace list devices` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0. It listed the Mac host, physical iOS/iPadOS records only under the offline section, and an `iPhone 12` entry only under simulators. |
| `xcrun devicectl list devices --json-output -` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0 with JSON `outcome` = `success` after a local CoreDevice provider warning. Physical inventory contained unavailable iPhone 15 Pro-class and unavailable iPad Pro 11-inch 4th generation-class records. No connected physical iPhone 12-family hardware was present. |

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

This report records only the device classes and validation status needed for L12
reconciliation. It intentionally omits raw device names, hostnames, serial
numbers, UDIDs, ECIDs, local network identifiers, full paths outside the iOS
workspace, and full probe JSON.

## Supervisor Recommendation

Keep the following blueprint checklist item open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No newly open iOS checklist item is ready to mark complete from this batch.

Evidence path for reconciliation:

- `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260510-0725.md`
