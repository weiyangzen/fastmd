# Stage 1 iOS L12 Negated Manual Evidence Hardening

- Generated: 2026-05-10T00:37:00Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: iOS-only L12 real-device validation evidence hardening
- Changed implementation surface: `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- Changed test surface: `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- No Android files or root Docs files were edited.

## Checklist Context

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` remains OPEN.
- This batch does not claim physical validation completion.
- The batch closes a validation-gate false-positive risk: manual evidence that contains a valid iPhone 12-family hardware token inside negated wording must not complete the physical real-device gate.

## Implementation Evidence

- Hardened `IOSStageOneRealDeviceFlowEvidence.hasPhysicalIPhone12FamilyEvidence` so manual summaries with nearby negated physical hardware claims such as `not on physical iPhone 12-family hardware iPhone13,3` are rejected even though they contain an otherwise valid hardware token.
- Kept positive evidence valid when a simulator reference is itself negated, such as `not a simulator, physical iPhone 12-family hardware iPhone13,3`.
- Added focused L12 tests:
  - `testIOSL12RealDeviceValidationRejectsNegatedHardwareSignalAsPhysicalManualEvidence`
  - `testIOSL12RealDeviceValidationAllowsPositivePhysicalEvidenceAfterSimulatorNegation`

## Automated Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | PASS | 82 selected tests, 0 failures |
| `swift test` | PASS | 257 tests, 0 failures |
| `git -C .. diff --check -- ios` | PASS | no whitespace errors reported |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | SwiftPM package scheme built `FastMDMobileCore` for iPhone 12 simulator destination; `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | SwiftPM package scheme ran 257 tests, 1 skipped, 0 failures; `** TEST SUCCEEDED **` |

Note: the xcodebuild commands resolve the SwiftPM package scheme from the current `ios/` skeleton. They validate the package target on the iPhone 12 simulator destination, not a full installed app target with an `.xcodeproj` app scheme.

## Physical Probe Commands

| Command | Result | Sanitized finding |
| --- | --- | --- |
| `xcrun xctrace list devices` | PASS | Connected host Mac only under physical devices; two iOS physical records listed under `Devices Offline`; exact `iPhone 12` simulator destination exists. |
| `xcrun devicectl list devices --json-output -` | PASS with CoreDevice provider warning | Two physical iOS records reported, both `tunnelState=unavailable`; no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. |

Sanitized physical inventory from the current probe:

| Source | Hardware | OS | Connection | Eligibility |
| --- | --- | --- | --- | --- |
| `xctrace` / `devicectl` | iPhone 15 Pro / iPhone16,1 | 26.1 | unavailable | not iPhone 12-family and not connected |
| `xctrace` / `devicectl` | iPad Pro / iPad14,4 | 26.3.1 | unavailable | not iPhone 12-family and not connected |

## Gate Decision

- Physical iPhone 12-family devices connected: 0
- Verified iPhone 12-family hardware evidence connected: 0
- Required manual flow evidence after current physical probe: not run
- Real-device validation complete: false
- Blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was reported by the current `xcrun xctrace list devices` and `xcrun devicectl list devices --json-output -` probes.

The supervisor should keep L12 physical iPhone 12-class real-device validation open until an eligible connected physical device completes the Stage 1 open, render, search, full-source edit, block-source edit, save, and rotate flow with step-specific manual evidence tied to the current probe batch.
