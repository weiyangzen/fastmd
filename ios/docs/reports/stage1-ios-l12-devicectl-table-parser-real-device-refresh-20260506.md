# Stage 1 iOS L12 Devicectl Table Parser And Real-Device Refresh - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation and validation batch for the remaining iOS L12 physical iPhone 12-family validation surface.

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-devicectl-table-parser-real-device-refresh-20260506.md`

## Implementation Notes

- Hardened `IOSDevicectlDeviceListParser` table-output parsing so it splits `devicectl` table rows on column spacing while preserving spaces inside device names and model names.
- Added XCTest coverage for table rows such as `Alice iPhone 12`, `QA Lab Phone`, and `Bob Pro Max`.
- The parser still extracts the hardware identifier from model text such as `iPhone 12 mini (iPhone13,1)` and uses that identifier for iPhone 12-family eligibility.
- This strengthens the L12 real-device probe path for machines where `devicectl --json-output -` emits both a human-readable table and JSON, or where the JSON section is absent.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 148 XCTest cases with 0 failures. New coverage: `testIOSL12DevicectlTableParserPreservesSpacesInsideDeviceAndModelNames`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12 completion | Connected physical devices: Mac only. Offline physical iOS-family devices include an iPhone 15 Pro-class device and an iPad-class device. The `iPhone 12` entry is listed under simulators, so it cannot satisfy the physical-device gate. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12 completion | Parsed physical product types were iPhone 15 Pro class and iPad class, both unavailable. No connected `iPhone13,*` iPhone 12-family product type was present. Serial-like identifiers are intentionally omitted from this report. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark newly complete from this batch:

- None. The only remaining iOS-owned L12 physical-device gate cannot complete without connected iPhone 12-family hardware and manual Stage 1 flow evidence.

Supervisor can keep using this as supporting evidence for:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- L13: `Record validation reports under ios/docs/reports/.`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available in this batch. Simulator inventory and parsed `devicectl` output cannot close the physical-device gate without real iPhone 12-family hardware plus manual open, render, search, edit, save, and rotate evidence.
