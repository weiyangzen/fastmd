# Stage 1 iOS L12 Real-Device Probe Refresh - 2026-05-06 05:10 CST

## Scope

Ran one bounded iOS-owned L12 validation refresh for the remaining physical iPhone 12-family validation gate:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, shared `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Implementation Evidence

No Swift implementation files changed in this batch because the native real-device validation contract is already implemented and covered under:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

The existing contract parses `xcrun xctrace list devices` and `xcrun devicectl list devices --json-output -`, distinguishes simulators from physical devices, accepts only connected iPhone 12-family hardware (`iPhone13,1` through `iPhone13,4` or matching iPhone 12 marketing names), requires current probe evidence, requires SwiftPM plus iPhone 12 simulator prerequisites, and requires manual evidence for the full open/render/search/edit/save/rotate Stage 1 flow before the gate can pass.

## Current Probe Results

Probe timestamp:

- UTC: `2026-05-05T21:10:21Z`
- Local: `2026-05-06 05:10 CST`

| Probe | Result | Evidence |
| --- | --- | --- |
| `xcrun xctrace list devices` | PASS command, gate BLOCKED | Connected physical devices list contained only `Mac`. Offline devices included `Turbulence` and `王威扬的iPad`. Simulator list included `iPhone 12`, which does not satisfy the physical-device gate. |
| `xcrun devicectl list devices --json-output -` | PASS command, gate BLOCKED | Listed `Turbulence` as physical `iPhone 15 Pro (iPhone16,1)` with unavailable tunnel state, and `王威扬的iPad` as physical `iPad Pro (11-inch) (4th generation) (iPad14,4)` with unavailable tunnel state. No connected iPhone 12-family physical device was available. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|Stage1\|iPhone"` | PASS command, simulator-only evidence | The `iPhone 12` simulator is present and available, but simulator validation cannot complete the physical iPhone 12-family real-device gate. |

Identifiers, serial numbers, UDIDs, and ECIDs are intentionally omitted from this report. The blocker is the absence of connected physical iPhone 12-family hardware, not a need to preserve private device identifiers.

## Gate Status

| Checklist item | Status | Evidence |
| --- | --- | --- |
| `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` | OPEN / BLOCKED | No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was reported by either physical-device probe. The available iPhone 12 simulator remains simulator-only evidence. |

## Supervisor Guidance

Keep the L12 physical real-device gate open.

This report is fresh blocker evidence only. It is not completion evidence for the real-device gate. The gate should close only after a connected physical iPhone 12-family device completes the Stage 1 open, rich fixture render, search, full source edit, block source edit, save, and rotate flow with current manual evidence.
