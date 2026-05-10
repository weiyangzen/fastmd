# Stage 1 iOS L12 Devicectl Table Real-Device Probe - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation batch for the earliest remaining iOS checklist gate:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-devicectl-table-real-device-probe-20260506.md`

## Implementation Notes

- Extended `IOSDevicectlDeviceListParser` to parse the table output emitted by local `xcrun devicectl list devices` when JSON output is unavailable.
- The table fallback extracts device name, identifier, availability state, and hardware identifier from model strings such as `iPhone 15 Pro (iPhone16,1)` and `iPad Pro (11-inch) (4th generation) (iPad14,4)`.
- The parser accepts only known CoreDevice table states (`available`, `unavailable`) so leading CoreDevice warning text is ignored instead of being treated as a candidate device.
- The real-device report gate still fails closed: only connected physical iPhone 12-family hardware identifiers or marketing names (`iPhone13,1` through `iPhone13,4`, or iPhone 12 family names) can satisfy eligibility.

## Current Device Probe

Probe command:

```bash
xcrun devicectl list devices
```

Observed at: `2026-05-06 01:41 +0800`

Current output:

```text
Failed to load provisioning paramter list due to error: Error Domain=com.apple.dt.CoreDeviceError Code=1002 "No provider was found." UserInfo={NSLocalizedDescription=No provider was found.}.
`devicectl manage create` may support a reduced set of arguments.
Name         Hostname                             Identifier                             State         Model
----------   ----------------------------------   ------------------------------------   -----------   ----------------------------------------------
Turbulence   Turbulence.coredevice.local          0CBD6373-CEB0-5A7E-B47F-F6A136CFD179   unavailable   iPhone 15 Pro (iPhone16,1)
王威扬的iPad     wangweiyangdeiPad.coredevice.local   99297749-FED4-550D-A57A-E741118B99E1   unavailable   iPad Pro (11-inch) (4th generation) (iPad14,4)
```

Parsed physical candidates:

| Device | Hardware model | Connected | Eligible iPhone 12-family physical device | Eligibility reason |
| --- | --- | --- | --- | --- |
| Turbulence | `iPhone16,1` | no | no | disconnected physical device |
| 王威扬的iPad | `iPad14,4` | no | no | disconnected physical device |

Connected physical iPhone 12-family devices found: `0`.

Simulator inventory command:

```bash
xcrun simctl list devices available | rg "iPhone 12|iPhone 15|Stage1"
```

Result:

```text
Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)
iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
```

The `iPhone 12` entry is a simulator destination and does not satisfy the physical iPhone 12-family validation gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 19 focused L12 tests with 0 failures. Includes new `testIOSL12DevicectlDeviceListParserExtractsHardwareIdentifiersFromTableOutput` coverage plus existing simulator, performance, security, rich render, and real-device report gates. |
| `swift test` from `ios/` | PASS | Executed 138 XCTest cases with 0 failures. |
| `xcrun devicectl list devices` from repository root | BLOCKED for real-device completion | Listed an unavailable iPhone 15 Pro (`iPhone16,1`) and an unavailable iPad (`iPad14,4`); no connected physical iPhone 12-family device was present. |
| `xcrun simctl list devices available \| rg "iPhone 12\|iPhone 15\|Stage1"` from repository root | PASS | Local simulator inventory includes `iPhone 12` and `Stage1 iPhone 15 Pro`. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for the open blocker:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-devicectl-table-real-device-probe-20260506.md`

No iOS checklist completion claim is made from this batch. Completion still requires a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max and manual evidence for the full Stage 1 open, render rich fixture, search, full source edit, block source edit, save writable document, and rotate reader flow.
