# Stage 1 iOS L12 Real-Device Redaction And Blocker Refresh

- Generated: 2026-05-09T23:08:00Z
- Lane: iOS live lane
- Scope: `ios/**`
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo source: `Docs/todos_20260506.md`

## Implementation

This batch tightened the iOS L12 real-device validation evidence path without touching Android or the root Docs checklist.

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
  - Extended `IOSStageOneRealDeviceValidationReport` report sanitization to redact serial-number style probe tokens.
  - Extended the same sanitizer to redact ECID-style probe tokens.
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - Added XCTest coverage proving manual real-device evidence summaries redact serial-number and ECID tokens while still allowing a valid iPhone 12-family validation report to pass when all required evidence exists.

## Physical Device Probe

Commands run during this batch:

| Command | Result | Summary |
| --- | --- | --- |
| `xcrun xctrace list devices` | PASS | Command completed. It reported the local Mac, two offline physical iOS-family records, and an iPhone 12 simulator. It did not report a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. |
| `xcrun devicectl list devices --json-output -` | PASS | Command completed with a CoreDevice provider warning and a success JSON payload. It reported two paired but unavailable physical devices, neither connected and neither iPhone 12-family hardware. |

Current L12 physical-device status:

- Physical probe command coverage: complete for the two required probe commands.
- Connected physical iPhone 12-family devices: 0.
- iPhone 12 simulator availability: present, but simulator evidence does not complete the physical-device gate.
- Real-device validation complete: false.
- Blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available for the Stage 1 open, render, search, edit, save, and rotate flow.

The supervisor should keep `Run iOS iPhone 12-class real-device validation before parity-complete release claim` open.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDeviceReportRedactsSerialAndECIDProbeTokensFromManualEvidence` | PASS | 1 selected XCTest passed. |
| `swift test` | PASS | 250 XCTest cases passed with 0 failures. |
| `xcrun simctl list devices available | rg 'iPhone 12'` | PASS | iPhone 12 simulator destination is available. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | Build completed with `** BUILD SUCCEEDED **`. |
| `git -C .. diff --check -- ios` | PASS | No whitespace errors reported. |

## Checklist Impact

Supervisor reconciliation guidance:

- Keep open: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- Evidence path for the open blocker and redaction hardening: `ios/docs/reports/stage1-ios-l12-real-device-redaction-and-blocker-refresh-20260510-0708.md`.
- No root checklist item should be newly marked complete from this batch because the only remaining iOS-owned item requires an actual connected physical iPhone 12-family device and completed manual flow evidence.
