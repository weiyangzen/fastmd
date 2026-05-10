# Stage 1 iOS L12 Real-Device Report Redaction - 2026-05-06 13:59 CST

## Scope

This bounded iOS live-lane batch targeted the earliest remaining iOS-owned open checklist item:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

No Android files, root `Docs/**` checklist files, or `.cron/**` files were edited.

## Implementation

- Hardened `IOSStageOneRealDeviceValidationReport` so generated L12 physical-device report tables no longer include raw local device display names.
- Report rows now use non-personal evidence labels such as `simulator-destination-N`, `disconnected-physical-device-N`, `connected-non-iphone12-device-N`, `unverified-iphone12-family-device-N`, and `verified-iphone12-family-device-N`.
- The parser and validation model still keep candidate names internally for probe merging and eligibility classification, but the user-facing report output avoids personal device names from `xctrace` and `devicectl`.
- Updated focused L12 XCTest assertions to verify redacted labels and to reject personal names in generated real-device report markdown.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-report-redaction-20260506-1359.md`

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 32 selected L12 XCTest cases with 0 failures after updating the real-device report redaction contract. |
| `swift test` from `ios/` | PASS | Executed 207 XCTest cases with 0 failures. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | The local simulator inventory includes an available `iPhone 12` simulator destination. Simulator identifier is intentionally omitted here. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical iPhone 12-family validation | Connected physical devices listed: local Mac only. Physical iOS devices were listed only under the offline section, and the `iPhone 12` entry appeared under simulators, not connected physical devices. Device names and identifiers are intentionally omitted from this report. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation | Command outcome was `success`, but discovered physical iOS devices were unavailable and were not iPhone 12-family hardware. No connected verified `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` device was available for the required manual flow. Device names, hostnames, identifiers, serial numbers, ECIDs, and UDIDs are intentionally omitted from this report. |

## Current Physical-Device Result

The L12 physical-device validation gate remains open.

This machine currently has:

- Passing SwiftPM validation.
- An available iPhone 12 simulator destination.
- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max exposed by `xcrun xctrace list devices`.
- No connected verified iPhone 12-family product identifier exposed by `xcrun devicectl list devices --json-output -`.

The required physical-device flow still needs to be run on connected iPhone 12-family hardware:

- Open Markdown.
- Render the rich fixture.
- Search the document.
- Edit full source.
- Edit block source.
- Save a writable document.
- Rotate the reader.

## Checklist Reconciliation

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Supervisor can mark newly complete from this batch:

- None. This batch hardens the remaining physical-device evidence path and records fresh validation/blocker evidence, but it does not complete the physical iPhone 12-family validation row.

Evidence path:

- `ios/docs/reports/stage1-ios-l12-real-device-report-redaction-20260506-1359.md`
