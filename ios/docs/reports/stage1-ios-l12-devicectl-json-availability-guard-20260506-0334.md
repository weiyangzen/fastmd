# Stage 1 iOS L12 Devicectl JSON Availability Guard - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation batch for the remaining iOS L12 physical-device gate:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-devicectl-json-availability-guard-20260506-0334.md`

## Implementation Notes

- Tightened `IOSDevicectlDeviceListParser` JSON availability handling for real-device evidence.
- The parser now reads top-level `state` or `availability` fields when present.
- Explicit non-`available` state now wins over optimistic connection fields and marks the candidate disconnected.
- JSON candidates with neither availability state nor tunnel-state evidence now fail closed as disconnected.
- Existing positive evidence still works: `state: available` can mark a physical iPhone 12-family candidate connected, and tunnel evidence can continue to mark paired devices connected when state is absent.
- Table-output parsing remains unchanged.

## Current Device Probe

`xcrun devicectl list devices` completed but did not expose connected iPhone 12-family hardware:

| Device class | State | Hardware family |
| --- | --- | --- |
| iPhone 15 Pro-class physical device | unavailable | `iPhone16,1` |
| iPad Pro-class physical device | unavailable | `iPad14,4` |

`xcrun xctrace list devices` completed with:

- Connected physical devices: Mac only.
- Offline physical iOS-family devices: one iPhone 15 Pro-class device and one iPad Pro-class device.
- Simulators: includes `iPhone 12`.

The available `iPhone 12` entry is a simulator destination and does not satisfy the physical iPhone 12-family validation gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 23 focused L12 tests with 0 failures. New coverage: `testIOSL12DevicectlJSONParserUsesAvailabilityStateAndFailsClosedWithoutConnectionEvidence`. |
| `swift test` from `ios/` | PASS | Executed 150 XCTest cases with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|Stage1\|iPhone 15"` from `ios/` | PASS | Available simulator inventory includes `iPhone 12` and `Stage1 iPhone 15 Pro`. |
| `xcrun devicectl list devices` from `ios/` | BLOCKED for real-device completion | Listed unavailable iPhone 15 Pro-class and iPad Pro-class physical devices; no connected physical iPhone 12-family device was present. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Connected physical devices list contained only Mac; iPhone 12 appeared only under simulators. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for the open blocker and parser hardening:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-devicectl-json-availability-guard-20260506-0334.md`

No iOS checklist completion claim is made from this batch. Completion still requires a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max and current manual evidence for the full Stage 1 open, render rich fixture, search, full source edit, block source edit, save writable document, and rotate reader flow.
