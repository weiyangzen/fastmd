# Stage 1 iOS L12 Real-Device Hardware Evidence Match - 2026-05-06 14:58 CST

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

- `ios/docs/reports/stage1-ios-l12-real-device-hardware-evidence-match-20260506-1458.md`

## Implementation Notes

- Added `blockedMismatchedPhysicalManualFlowEvidence` to the iOS real-device validation status model.
- Added verified hardware signal matching for real-device manual flow evidence.
- A future passed L12 physical-device report now requires every manual flow evidence row to reference the same verified connected iPhone 12-family hardware signal reported by the current device probe.
- This prevents a false completion where a connected `iPhone13,3` candidate is paired with manual evidence collected from a different iPhone 12-family device such as `iPhone13,2`.
- The generated report markdown now includes `Manual flow matches connected verified hardware: true/false` and marks mismatched step rows as `DEVICE-MISMATCH`.

## Current Local Device Probe

Probe commands:

```bash
xcrun simctl list devices available | rg 'iPhone 12'
xcrun xctrace list devices
xcrun devicectl list devices --json-output -
```

Observed at: `2026-05-06 14:58 +0800`

Current physical-device evidence, sanitized:

| Probe | Device class | Hardware / product type | OS | Connected | Eligible iPhone 12-family physical device |
| --- | --- | --- | --- | --- | --- |
| `simctl` | iPhone 12 simulator | simulator | not recorded | n/a | no |
| `xctrace` | Mac | unknown | unknown | yes | no |
| `xctrace` | iPhone-class physical device | unknown | 26.1 | no | no |
| `xctrace` | iPad-class physical device | unknown | 26.3.1 | no | no |
| `xctrace` simulator inventory | iPhone 12 | simulator | 26.4.1 | yes | no |
| `devicectl` | iPhone-class physical device | iPhone16,1 / iPhone 15 Pro | 26.1 | no | no |
| `devicectl` | iPad-class physical device | iPad14,4 / iPad Pro 11-inch 4th generation | 26.3.1 | no | no |

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
- No connected `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` physical product type was reported by `xcrun devicectl list devices --json-output -`.
- The available `iPhone 12` entry is a simulator destination, not physical hardware.
- No manual real-device Stage 1 open, render, search, full source edit, block source edit, save, and rotate evidence was generated in this batch.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 20 focused real-device validation tests with 0 failures. New coverage: `testIOSL12RealDeviceValidationRequiresManualEvidenceToMatchConnectedHardwareSignal`. |
| `swift test` from `ios/` | PASS | Executed 211 XCTest cases with 0 failures. Includes L1 canonical fixture matrix coverage and the full L11/L12 validation gate model coverage. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found an available `iPhone 12` simulator destination. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family validation | Connected device section listed the Mac only. Physical iOS-family devices were offline, and the `iPhone 12` entry was under simulators. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation | Command outcome was `success`, but discovered physical iOS-family devices were unavailable and not iPhone 12-family hardware. Device names, identifiers, serials, ECIDs, hostnames, and full local paths are intentionally omitted. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for this open blocker and improved completion guard:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-hardware-evidence-match-20260506-1458.md`

No iOS checklist completion claim is made from this batch. Completion still requires a connected physical iPhone 12-family device and current manual evidence for the full Stage 1 flow, with every step tied to the verified connected hardware signal.
