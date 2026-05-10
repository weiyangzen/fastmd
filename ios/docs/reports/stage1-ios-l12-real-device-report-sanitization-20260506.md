# Stage 1 iOS L12 Real-Device Report Sanitization - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation batch for the remaining iOS L12 real-device validation gate:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-report-sanitization-20260506.md`

## Implementation Notes

- Hardened `IOSStageOneRealDeviceValidationReport.markdown` so physical-device table fields are sanitized before being written into Markdown rows.
- Device name, hardware model, and OS version now pass through the existing `safeText(_:)` path, replacing table separators and line breaks with safe inline text.
- Added `testIOSL12RealDeviceReportSanitizesDeviceTableFields` to prove device names or hardware strings containing `|` or newlines cannot break the real-device evidence table.
- The completion guard remains fail-closed. The report still requires:
  - current device probe evidence,
  - passing SwiftPM and iPhone 12 simulator prerequisites,
  - a connected physical iPhone 12-family device,
  - timestamped manual evidence for every Stage 1 real-device flow step.

## Current Device Probe

Command:

```text
xcrun xctrace list devices
```

Observed at `2026-05-06 02:04 +0800`:

- Connected physical devices: `Mac` only.
- Offline physical iOS-family devices: `Turbulence (26.1)` and `Wang Weiyang iPad (26.3.1)`.
- Simulators include `iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)`.
- Connected physical iPhone 12-family devices: `0`.

Command:

```text
xcrun devicectl list devices --json-output -
```

Observed at `2026-05-06 02:04 +0800`:

- Outcome: `success`, after a provisioning parameter warning from CoreDevice.
- `Turbulence`: `iPhone16,1` / iPhone 15 Pro, `tunnelState=unavailable`.
- `Wang Weiyang iPad`: `iPad14,4` / iPad Pro 11-inch 4th generation, `tunnelState=unavailable`.
- Connected physical iPhone 12-family product types `iPhone13,1` through `iPhone13,4`: `0`.

The available `iPhone 12` is a simulator entry. It does not satisfy the physical iPhone 12-family real-device validation gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 12 focused L12 real-device report tests with 0 failures. Includes the new table-field sanitization case. |
| `swift test` from `ios/` | PASS | Executed 142 XCTest cases with 0 failures. This is the minimum required local SwiftPM validation for the current SwiftPM skeleton. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed. The local `iPhone 12` entry is a simulator. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for real-device completion | Parsed physical product types were `iPhone16,1` and `iPad14,4`, both unavailable; no connected `iPhone13,*` iPhone 12-family product type was present. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for the open blocker and report hardening:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-report-sanitization-20260506.md`

No new blueprint checklist item should be marked complete from this batch. The batch advances the remaining real-device gate by making its evidence report robust against malformed local device metadata, while still blocking completion until connected physical iPhone 12-family hardware and full manual flow evidence are available.
