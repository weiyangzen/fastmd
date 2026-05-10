# Stage 1 iOS L12 Real-Device Hardware Identifier Guard - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation and validation batch for the earliest iOS-owned checklist item that remains open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-hardware-identifier-20260506.md`

## Implementation Notes

- Expanded `IOSStageOnePhysicalDeviceCandidate` iPhone 12-family eligibility to accept Apple product identifiers as hardware evidence:
  - `iPhone13,1`
  - `iPhone13,2`
  - `iPhone13,3`
  - `iPhone13,4`
- Kept the existing accepted marketing names:
  - `iPhone 12`
  - `iPhone 12 mini`
  - `iPhone 12 Pro`
  - `iPhone 12 Pro Max`
- This preserves support for custom-named physical devices, where the visible device name might be `Alice's iPhone` while separate local evidence supplies `hardwareModel: "iPhone13,2"`.
- Added a negative test proving non-iPhone-12 hardware identifiers such as `iPhone14,2` do not satisfy the gate.
- The real-device gate still requires:
  - a connected physical iPhone 12-family device,
  - a fresh device probe,
  - passing SwiftPM and iPhone 12 simulator prerequisites,
  - timestamped manual evidence for the full Stage 1 open, render, search, full source edit, block source edit, save writable document, and rotate flow.

## Current Local Device Probe

Command:

```text
xcrun xctrace list devices
```

Result:

- Connected physical devices: `Mac` only.
- Offline physical iOS-family devices: `Turbulence` and `王威扬的iPad`.
- Simulators include `iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)`.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max devices: `0`.

The available `iPhone 12` entry is under `== Simulators ==`, not `== Devices ==`. It cannot satisfy the blueprint's physical iPhone 12-family real-device gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 15 focused L12 tests with 0 failures. New coverage includes `testIOSL12RealDeviceValidationAcceptsIPhone12FamilyHardwareIdentifier` and `testIOSL12RealDeviceValidationRejectsNonIPhone12HardwareIdentifier`. |
| `swift test` from `ios/` | PASS | Executed 132 XCTest cases with 0 failures. This is the minimum required local SwiftPM validation for the current SwiftPM skeleton. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed. The local iPhone 12 is a simulator only. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for the open blocker and validator hardening:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-hardware-identifier-20260506.md`

No new blueprint checklist item should be marked complete from this batch. The batch advances the remaining L12 real-device gate by accepting the hardware identifier evidence format commonly available for custom-named physical devices, while still failing closed without connected iPhone 12-family hardware.
