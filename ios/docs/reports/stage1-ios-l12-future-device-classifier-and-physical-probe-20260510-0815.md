# Stage 1 iOS L12 Future Device Classifier And Physical Probe

- Generated: 2026-05-10T00:15:00Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: iOS-only L12 real-device validation hardening and current physical probe evidence
- Changed implementation surface: `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- Changed test surface: `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Checklist Context

- L12 `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` remains OPEN.
- This batch improves blocker classification for name-only future iPhone hardware rows and refreshes the current local physical-device probe evidence.
- No Android files or root Docs files were edited.

## Implementation Evidence

- Added numeric future iPhone name-only detection to the iOS physical-device evidence classifier.
- A connected physical row such as `iPhone 18 Pro Max` without a hardware identifier is now classified as connected unsupported iOS physical hardware instead of disappearing into the generic no-device blocker.
- Name-only `iPhone 12 Pro` still remains an iPhone 12-family candidate that cannot complete the gate without verified hardware model or product identifier evidence.

## Automated Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | PASS | 80 selected tests, 0 failures |
| `swift test` | PASS | 255 tests, 0 failures |
| `git -C .. diff --check -- ios` | PASS | no whitespace errors |

New focused test:

- `testIOSL12RealDeviceValidationClassifiesFutureNameOnlyIPhoneHardwareAsUnsupported`

## Physical Probe Commands

| Command | Result | Sanitized finding |
| --- | --- | --- |
| `xcrun xctrace list devices` | PASS | Connected host Mac only; two iOS physical records were listed under `Devices Offline`; exact `iPhone 12` simulator exists. |
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
