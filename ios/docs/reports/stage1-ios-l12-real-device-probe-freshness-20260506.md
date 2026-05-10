# Stage 1 iOS L12 Real-Device Probe Freshness - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation and validation batch for the remaining iOS-owned L12 real-device gate:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Implementation

Added freshness enforcement to the native Swift L12 real-device validation model:

- `IOSStageOneRealDeviceValidationReport` now records `deviceProbeObservedAt` and a bounded `deviceProbeMaximumAge`.
- The report now exposes `hasCurrentDeviceProbeEvidence`.
- The report now blocks with `blockedStaleDeviceProbe` when the physical-device probe is missing, older than the accepted window, or newer than the report timestamp.
- `capturesRealDeviceGateEvidence` and `completesRequiredRealDeviceValidation` now require current physical-device probe evidence.
- Report Markdown now records the device-probe timestamp and whether it is current.
- Added XCTest coverage proving stale and future-dated device probes cannot satisfy the real-device validation gate, even when an eligible iPhone 12-family candidate and complete manual flow evidence are present.

This closes an evidence-quality gap for the physical-device gate: a report can no longer complete L12 from stale parsed `xcrun xctrace list devices` output.

## Current Device Probe

Command:

```text
xcrun xctrace list devices
```

Result:

- Connected physical devices: `Mac` only.
- Offline physical iOS-family devices: `Turbulence (26.1)` and an iPad.
- Simulators include `iPhone 12 (26.4.1)`.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max devices: `0`.

The available `iPhone 12` entry is under `== Simulators ==`, not `== Devices ==`. It cannot satisfy the blueprint's physical iPhone 12-family real-device gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 12 focused L12 tests with 0 failures. New coverage includes `testIOSL12RealDeviceValidationRequiresCurrentDeviceProbeEvidence`. |
| `swift test` from `ios/` | PASS | Executed 129 XCTest cases with 0 failures. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed. The local iPhone 12 is a simulator only. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination, executed 129 tests with 0 failures, and ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_00-25-15-+0800.xcresult`. |

## Supervisor Can Mark Complete

No new blueprint checklist item should be marked complete from this batch.

The batch advances evidence quality for:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

but this gate remains open because no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max is available.

## Remaining Blocker

No L12 real-device completion claim should be made from this batch. Completion still requires:

- a connected physical iPhone 12-family device,
- a fresh `xcrun xctrace list devices` probe captured during validation,
- passing SwiftPM and iPhone 12 simulator prerequisites,
- timestamped manual evidence for the full Stage 1 open, render, search, full source edit, block source edit, save writable document, and rotate reader flow.
