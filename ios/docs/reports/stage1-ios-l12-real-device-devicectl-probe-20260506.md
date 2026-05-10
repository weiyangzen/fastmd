# Stage 1 iOS L12 Real-Device Devicectl Probe - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation batch for the earliest remaining iOS-owned checklist item:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-devicectl-probe-20260506.md`

## Implementation Notes

- Added `IOSDevicectlDeviceListParser`, a native Swift parser for `xcrun devicectl list devices --json-output -`.
- The parser reads `deviceProperties.name`, `deviceProperties.osVersionNumber`, `hardwareProperties.productType`, `hardwareProperties.marketingName`, `hardwareProperties.reality`, and `connectionProperties.tunnelState`.
- Parsed `productType` values flow into `IOSStageOnePhysicalDeviceCandidate.hardwareModel`, so custom-named physical devices can satisfy the iPhone 12-family guard when devicectl reports `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4`.
- The parser treats `tunnelState == unavailable` and `pairingState == unpaired` as not connected, and treats `reality == virtual` as a simulator.
- Existing `xcrun xctrace list devices` parsing remains intact. The new parser is an additional evidence source for the same fail-closed real-device report model.

## Current Probe Evidence

Probe commands:

```bash
xcrun xctrace list devices
xcrun devicectl list devices --json-output -
```

Observed at: `2026-05-06 00:52 +0800`

Current physical-device evidence:

| Probe | Device | Hardware / product type | OS | Connected | Eligible iPhone 12-family physical device |
| --- | --- | --- | --- | --- | --- |
| `xctrace` | Mac | unknown | unknown | yes | no |
| `xctrace` | Turbulence | unknown | 26.1 | no | no |
| `xctrace` | Wang Weiyang iPad | unknown | 26.3.1 | no | no |
| `devicectl` | Turbulence | iPhone16,1 / iPhone 15 Pro | 26.1 | no | no |
| `devicectl` | Wang Weiyang iPad | iPad14,4 / iPad Pro 11-inch 4th generation | 26.3.1 | yes | no |
| simulator inventory | iPhone 12 | simulator | 26.4.1 | n/a | no |

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
- No `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` physical product type was reported by `xcrun devicectl list devices --json-output -`.
- The available `iPhone 12` destination is a simulator, not physical hardware.
- No manual real-device Stage 1 open, render, search, edit, save, and rotate evidence was generated in this batch.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12Devicectl` from `ios/` | PASS | Executed the focused devicectl parser XCTest with 0 failures. Verifies product identifier extraction, unavailable-device rejection, OS version normalization, and iPad non-eligibility. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 10 focused real-device report tests with 0 failures. Includes the new devicectl hardware-evidence path and the existing fail-closed real-device validation states. |
| `swift test` from `ios/` | PASS | Executed 134 XCTest cases with 0 failures. Includes L1 canonical fixture matrix coverage and the full L11/L12 validation gate model coverage. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Connected physical devices: `Mac` only. Offline physical iOS-family devices: `Turbulence` and an iPad. The `iPhone 12` entry is listed under simulators. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for real-device completion | Parsed physical device product types were `iPhone16,1` and `iPad14,4`; no connected `iPhone13,*` iPhone 12-family product type was present. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for the open blocker and improved validation guard:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-devicectl-probe-20260506.md`

No iOS checklist completion claim is made from this batch. Completion still requires a connected physical iPhone 12-family device and manual evidence for the full Stage 1 open, render rich fixture, search, full source edit, block source edit, save writable document, and rotate reader flow.
