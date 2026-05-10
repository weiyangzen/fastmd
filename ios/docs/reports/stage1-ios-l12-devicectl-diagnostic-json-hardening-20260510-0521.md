# Stage 1 iOS L12 Devicectl Diagnostic JSON Hardening

- Generated: 2026-05-10 05:21 +0800
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Blueprint rows touched: L12 iOS iPhone 12-class real-device validation evidence
- Completion claim: no new checklist completion; physical iPhone 12-family validation remains open

## Implementation

`IOSDevicectlDeviceListParser` now scans `devicectl` output for the first valid JSON object that contains `result.devices` instead of trying to parse from the first `{` character in the stream.

This matters because the local `xcrun devicectl list devices --json-output -` output currently prints a CoreDevice diagnostic before the JSON payload:

- A diagnostic prefix contains `UserInfo={...}`.
- The real JSON payload starts later and includes `result.devices`.
- The table row may show `available (paired)` while JSON reports `tunnelState: disconnected`.

The gate must use the real `result.devices` JSON when present, so it does not upgrade a disconnected physical device based only on table availability.

Changed implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
  - Added `devicectlDeviceListJSONRoot(from:)`.
  - Added balanced-brace JSON object candidate scanning.
  - Kept the parser fail-closed: candidates are accepted only when the parsed object contains `result.devices`.

Changed tests:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - Added `testIOSL12DevicectlParserSkipsDiagnosticBracesBeforeJSONPayload`.
  - The regression fixture includes a diagnostic `UserInfo={...}` prefix before the valid JSON payload.
  - The test verifies JSON tunnel state stays disconnected even when the table says available.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12DevicectlParserSkipsDiagnosticBracesBeforeJSONPayload` | PASS | 1 test, 0 failures |
| `swift test` | PASS | 249 tests, 0 failures |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS | iPhone 12 simulator destination is present |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | SwiftPM-generated Xcode scheme built `FastMDMobileCore`; Xcode emitted `Supported platforms for the buildables in the current scheme is empty` but completed with `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | SwiftPM-generated Xcode scheme ran tests on iPhone 12 simulator; 249 tests, 1 skipped, 0 failures; `** TEST SUCCEEDED **` |
| `xcrun xctrace list devices` | PASS command, BLOCKED gate | No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max observed; only an iPhone 12 simulator was present |
| `xcrun devicectl list devices --json-output -` | PASS command, BLOCKED gate | No connected physical iPhone 12-family device observed; current output includes an unavailable iPhone 15 Pro-class record and an iPad Pro-class record whose JSON tunnel state is disconnected |

## Real-Device Gate Status

- Required physical probe command coverage: refreshed in this batch.
- Connected physical iPhone 12-family hardware: not present.
- Manual Stage 1 flow on physical iPhone 12-family hardware: not run.
- L12 checklist row `Run iOS iPhone 12-class real-device validation before parity-complete release claim`: keep open.

The supervisor should not mark the real-device validation row complete from this batch. This report only strengthens the current physical-device probe parser so the row remains blocked for the right reason.

## Supervisor Recommendation

No new authoritative checklist item should be marked complete.

Evidence path for reconciliation:

- `ios/docs/reports/stage1-ios-l12-devicectl-diagnostic-json-hardening-20260510-0521.md`
