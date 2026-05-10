# Stage 1 iOS L12 Report Redaction And Physical Probe Batch

- Generated: 2026-05-10 03:48 CST
- Generated UTC: 2026-05-09T19:48Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Ownership: `ios/**` only
- Authoritative blueprint reviewed but not edited: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot reviewed but not edited: `Docs/todos_20260506.md`
- Selected open iOS-owned item: L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

## Scope

This bounded batch keeps the L12 physical iPhone 12-family validation gate open,
but hardens the iOS real-device validation report so pasted manual evidence from
device probes cannot leak CoreDevice hostnames or device identifiers.

The report already redacted device table rows by using generic evidence labels.
This batch extends redaction to free-form manual evidence summaries before they
are emitted into the Markdown report table.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-report-redaction-and-physical-probe-20260510-0348.md`

## Implementation Evidence

- Added report-level redaction for UUID-shaped identifiers.
- Added report-level redaction for compact physical-device identifiers shaped
  like Apple device UDIDs.
- Added report-level redaction for `.coredevice.local` hostnames.
- Kept existing Markdown table sanitization for line breaks and pipe
  characters.
- Added `testIOSL12RealDeviceReportRedactsProbeIdentifiersFromManualEvidence`
  to prove manual flow evidence remains usable for completion checks while the
  rendered report redacts sensitive probe fragments.

## Validation Commands

| Command | Working directory | Result | Evidence |
| --- | --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceReportRedactsProbeIdentifiersFromManualEvidence` | `ios/` | PASS | 1 XCTest case, 0 failures. |
| `swift test` | `ios/` | PASS | 244 XCTest cases, 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | `ios/` | PASS for simulator inventory only | Exact `iPhone 12` simulator destination was available in `Shutdown` state. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | `ios/` | PASS | 244 XCTest cases, 1 simulator-only skip, 0 failures; `.xcresult` at `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.10_03-47-17-+0800.xcresult`. |
| `xcrun xctrace list devices` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 and listed the Mac host, offline physical iOS device records, and simulator destinations. The `iPhone 12` entry appeared only under simulators, not as connected physical hardware. |
| `xcrun devicectl list devices --json-output -` | `ios/` | BLOCKED for physical iPhone 12-family validation | Command exited 0 with JSON `outcome` = `success`, after a local CoreDevice provider warning. Physical inventory contained one unavailable iPhone 15 Pro-class record and one available paired iPad Pro 11-inch 4th generation-class record. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |
| `git diff --check -- ios` | repository root | PASS | No whitespace errors reported. |

Raw device names, UUIDs, serial numbers, ECIDs, hostnames, local network
identifiers, and raw JSON payloads are intentionally omitted. Hardware signals
are limited to model classes needed to explain why the L12 physical gate remains
blocked.

## Current L12 Physical-Device Status

- SwiftPM validation: pass.
- iPhone 12 simulator validation: pass.
- Physical probe command coverage: both required commands were run in this
  batch.
- Real-device validation complete: false.
- Blocker: no connected physical iPhone 12-family device was available in the
  fresh physical probes, and no post-probe physical iPhone 12-family manual
  open-render-search-edit-save-rotate flow was collected.

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

Can mark complete from this batch:

- None. This batch provides implementation hardening plus fresh validation and
  blocker evidence, but it does not complete the required physical iPhone
  12-family validation.
