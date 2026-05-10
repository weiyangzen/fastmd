# Stage 1 iOS L12 Real-Device Multi-Probe Command Evidence - 2026-05-06 04:31 +0800

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

- `ios/docs/reports/stage1-ios-l12-real-device-multiprobe-command-evidence-20260506-0431.md`

## Implementation Notes

- Extended `IOSStageOneRealDeviceValidationReport` to preserve a normalized `probeCommands` list in addition to the existing single `probeCommand` compatibility field.
- The report now emits `Probe commands` in generated Markdown and uses the full command summary in stale-probe and no-device blocker text.
- The command list is trimmed, deduplicated in original order, and fails closed to `xcrun xctrace list devices` when empty.
- Added focused XCTest coverage for multi-probe command preservation and empty-command fallback.

This improves blocker evidence for the current real-device gate because the local validation uses multiple independent probes:

- `xcrun xctrace list devices`
- `xcrun devicectl list devices --json-output -`
- `xcrun simctl list devices available | rg -n "iPhone 12|iPhone 15|iPhone"`

## Current Physical-Device Probe

Observed at:

```text
2026-05-06 04:31:49 +0800
```

Probe results:

| Probe | Result |
| --- | --- |
| `xcrun xctrace list devices` | Command passed. Connected devices contained only `Mac`; offline iOS-family devices were present but disconnected. |
| `xcrun devicectl list devices --json-output -` | Command passed with `outcome` success. Physical iOS-family devices were unavailable: an iPhone 15 Pro (`iPhone16,1`) and an iPad Pro (`iPad14,4`). |
| `xcrun simctl list devices available | rg -n "iPhone 12|iPhone 15|iPhone"` | Command passed. An `iPhone 12` simulator is available, but simulator evidence does not satisfy the physical real-device gate. |

Current conclusion:

- Connected physical iPhone 12-family devices found: `0`
- Connected physical `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` hardware identifiers found: `0`
- Stage 1 physical open/render/search/edit/save/rotate flow: not run, because required hardware is absent

Identifiers, serial numbers, hostnames, and UDIDs are intentionally omitted from this report. The blocker is device class and connection state, not device identity.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 15 focused real-device report tests with 0 failures. Includes the new multi-probe command preservation and empty-command fallback coverage. |
| `swift test` from `ios/` | PASS | Executed 158 XCTest cases with 0 failures. Includes L1 canonical fixture matrix coverage plus L11/L12 validation-gate model coverage. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Command passed, but no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was listed. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for real-device completion | Command passed, but available physical iOS-family entries were unavailable and not connected iPhone 12-family hardware. |
| `xcrun simctl list devices available | rg -n "iPhone 12|iPhone 15|iPhone"` from `ios/` | PASS for simulator inventory only | The local `iPhone 12` entry is a simulator destination, not physical hardware. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- No connected physical iPhone 12-family device is available in the local device set.
- The available iPhone 12 simulator has already been validated in earlier iOS evidence, but simulator validation cannot replace the required physical real-device validation.
- The Stage 1 open, render rich fixture, search, full source edit, block source edit, save writable document, and rotate reader flow cannot be completed on required physical hardware in this batch.

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-multiprobe-command-evidence-20260506-0431.md`

No blueprint checklist item should be marked complete from this batch. This batch strengthens current blocker evidence for the remaining iOS real-device gate only.
