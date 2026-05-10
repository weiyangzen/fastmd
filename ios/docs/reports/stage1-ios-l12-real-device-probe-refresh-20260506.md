# Stage 1 iOS L12 Real-Device Probe Refresh - 2026-05-06

## Scope

Ran one bounded iOS-owned validation batch for the earliest remaining iOS-owned checklist item:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-probe-refresh-20260506.md`

No Swift source or XCTest source files were changed in this batch.

## Current Probe Evidence

Probe command:

```bash
xcrun xctrace list devices
```

Observed at: `2026-05-06 00:45 +0800`

Current connected physical-device evidence:

| Device | Section | OS | Connected | Simulator | iPhone 12-family physical device |
| --- | --- | --- | --- | --- | --- |
| Mac | Devices | unknown | yes | no | no |
| Turbulence | Devices Offline | 26.1 | no | no | no |
| Wang Weiyang iPad | Devices Offline | 26.3.1 | no | no | no |
| iPhone 12 | Simulators | 26.4.1 | yes | yes | no |

The full `xctrace` output also lists many simulator destinations, including `iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)`. That entry is under `== Simulators ==`, so it cannot satisfy the physical iPhone 12-family validation gate.

Connected physical iPhone 12-family devices found:

- `0`

## Real-Device Gate Status

The iOS real-device gate remains blocked.

| Required real-device flow | Result |
| --- | --- |
| Open Markdown | OPEN |
| Render rich fixture | OPEN |
| Search document | OPEN |
| Full source edit | OPEN |
| Block source edit | OPEN |
| Save writable document | OPEN |
| Rotate reader | OPEN |

Blocker:

- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was reported by `xcrun xctrace list devices`.
- The available `iPhone 12` destination is a simulator, not physical hardware.
- No manual real-device Stage 1 open, render, search, edit, save, and rotate evidence was generated in this batch.

## Existing Implementation Guard

The existing iOS real-device validation model already fails closed for this state:

- `IOSXctraceDeviceListParser` classifies connected devices, offline devices, and simulators from `xcrun xctrace list devices`.
- `IOSStageOnePhysicalDeviceCandidate` accepts only connected physical iPhone 12-family marketing names or hardware identifiers.
- `IOSStageOneRealDeviceValidationReport` requires current probe evidence, prerequisite SwiftPM/simulator validation, eligible physical iPhone 12-family hardware, all required flow steps, and manual evidence for each step before completion.
- XCTest coverage includes blocked simulator-only probes, stale probes, missing prerequisite validation, custom-named iPhone 12-family hardware models, iPhone 12-family hardware identifiers, non-iPhone 12 hardware rejection, incomplete manual flow rejection, and full-flow pass behavior when eligible evidence is supplied.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 132 XCTest cases with 0 failures. Includes L12 real-device validation parser/report tests and L1 canonical fixture matrix coverage. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Connected physical devices: `Mac` only. Offline physical iOS-family devices: `Turbulence` and an iPad. The `iPhone 12` entry is listed under simulators. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|Stage1"` from `ios/` | PASS | Local simulator inventory includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1)`. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes after adding this report. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for the open blocker:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-probe-refresh-20260506.md`

No iOS checklist completion claim is made from this batch. Completion still requires a connected physical iPhone 12-family device and manual evidence for the full Stage 1 open, render rich fixture, search, full source edit, block source edit, save writable document, and rotate reader flow.
