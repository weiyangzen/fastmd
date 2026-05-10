# Stage 1 iOS L12 Live Validation Batch

- Generated: 2026-05-10 05:39:56 +0800
- Generated UTC: 2026-05-09T21:39:56Z
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Authoritative blueprint reviewed but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot reviewed but not edited: `Docs/todos_20260506.md`

## Batch Selection

The authoritative blueprint and daily todo snapshot show no earlier open
iOS-owned implementation item. L1 iOS canonical fixtures, L2 core contracts,
L4 document entry, L5-L7, L9-L11, iPhone 12 simulator build/test, iOS
performance report, iOS security audit report, and rich fixture render report
are already complete.

The selected open iOS-owned row for this bounded batch is:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Batch Result

No blueprint checklist item should be marked complete from this batch.

The local SwiftPM and iPhone 12 simulator validation gates pass. Fresh
physical-device probe commands also ran successfully, but they did not show a
connected physical iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro
Max. Therefore no physical install/test run and no manual
open-render-search-edit-save-rotate flow could be run on required hardware.

## Changed iOS Files

- `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260510-0539.md`

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test` | `ios/` | PASS | 249 XCTest cases, 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Exact `iPhone 12` simulator destination available in `Shutdown` state. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | 249 XCTest cases, 1 simulator-only skip, 0 failures. `.xcresult` at `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.10_05-39-12-+0800.xcresult`. |
| `xcrun xctrace list devices` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0. It listed the Mac host, offline physical iOS records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | PASS command, BLOCKED physical gate | Probe exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical inventory contained an unavailable iPhone 15 Pro-class record and a paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

## Current L12 Physical-Device Status

| Required physical iPhone 12-family flow | Status |
| --- | --- |
| Open Markdown document on physical iPhone 12-family hardware | OPEN |
| Render rich Markdown fixture on physical iPhone 12-family hardware | OPEN |
| Search within document on physical iPhone 12-family hardware | OPEN |
| Full source edit on physical iPhone 12-family hardware | OPEN |
| Block source edit on physical iPhone 12-family hardware | OPEN |
| Save writable document on physical iPhone 12-family hardware | OPEN |
| Rotate reader on physical iPhone 12-family hardware | OPEN |

## Privacy And Redaction

This report records only the device classes and validation status needed for
L12 reconciliation. It intentionally omits raw device names, hostnames, serial
numbers, UDIDs, ECIDs, full paths outside the relevant test result path, and
full probe JSON.

## Supervisor Recommendation

Keep the following blueprint checklist item open:

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Can mark complete from this batch:

- None.

Evidence path for reconciliation:

- `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260510-0539.md`
