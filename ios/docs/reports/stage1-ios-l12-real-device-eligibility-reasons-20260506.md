# Stage 1 iOS L12 Real-Device Eligibility Reasons - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation and validation batch for the remaining iOS-owned L12 gate:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-eligibility-reasons-20260506.md`

## Implementation Notes

- Added `IOSStageOnePhysicalDeviceEligibilityReason`, a native Swift reason enum for every probed device candidate.
- Added `IOSStageOnePhysicalDeviceCandidate.eligibilityReason` so the real-device report distinguishes:
  - `eligibleIPhone12FamilyDevice`
  - `simulatorDestination`
  - `disconnectedPhysicalDevice`
  - `unsupportedHardwareFamily`
- Extended `IOSStageOneRealDeviceValidationReport.markdown` with an `Eligibility reason` column.
- Added XCTest coverage proving simulator, disconnected physical device, unsupported physical hardware, and eligible iPhone 12-family hardware are reported with distinct reasons.
- The completion guard remains fail-closed: no real-device checklist completion can occur without a fresh probe, passed SwiftPM/iPhone 12 simulator prerequisites, connected physical iPhone 12-family hardware, and timestamped manual evidence for the full Stage 1 flow.

## Current Probe Evidence

Probe commands:

```bash
xcrun xctrace list devices
xcrun devicectl list devices --json-output -
```

Observed at: `2026-05-06 00:58 +0800`.

Current physical-device evidence:

| Probe | Device | Hardware / product type | OS | Connected | Simulator | Eligibility reason |
| --- | --- | --- | --- | --- | --- | --- |
| `xctrace` | Mac | unknown | unknown | yes | no | unsupportedHardwareFamily |
| `xctrace` | Turbulence | unknown | 26.1 | no | no | disconnectedPhysicalDevice |
| `xctrace` | Wang Weiyang iPad | unknown | 26.3.1 | no | no | disconnectedPhysicalDevice |
| `xctrace` simulator inventory | iPhone 12 | unknown | 26.4.1 | yes | yes | simulatorDestination |
| `devicectl` | Turbulence | iPhone16,1 / iPhone 15 Pro | 26.1 | no | no | disconnectedPhysicalDevice |
| `devicectl` | Wang Weiyang iPad | iPad14,4 / iPad Pro 11-inch 4th generation | 26.3.1 | yes | no | unsupportedHardwareFamily |

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
- No connected `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` product type was reported by `xcrun devicectl list devices --json-output -`.
- The available `iPhone 12` entry is a simulator destination, not physical hardware.
- No manual real-device Stage 1 open, render, search, edit, save, and rotate evidence was generated in this batch.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 11 focused real-device report tests with 0 failures. New coverage includes `testIOSL12RealDeviceReportExplainsCandidateEligibilityReasons`. |
| `swift test` from `ios/` | PASS | Executed 135 XCTest cases with 0 failures. Includes L1 canonical fixture matrix coverage and the full L11/L12 validation gate model coverage. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Connected physical devices: `Mac` only. Offline physical iOS-family devices: `Turbulence` and an iPad. The `iPhone 12` entry is listed under simulators. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for real-device completion | Parsed physical device product types were `iPhone16,1` and `iPad14,4`; no connected `iPhone13,*` iPhone 12-family product type was present. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for the open blocker and improved validation guard:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-eligibility-reasons-20260506.md`

No iOS checklist completion claim is made from this batch. Completion still requires a connected physical iPhone 12-family device and manual evidence for the full Stage 1 open, render rich fixture, search, full source edit, block source edit, save writable document, and rotate reader flow.
