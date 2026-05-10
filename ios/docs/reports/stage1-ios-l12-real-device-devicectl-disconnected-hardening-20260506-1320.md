# Stage 1 iOS L12 Real-Device Probe Hardening - 2026-05-06 13:20 CST

## Scope

One bounded iOS-owned implementation batch for the earliest remaining iOS-owned checklist row:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch stayed under `ios/**`. No Android files, root `Docs/**` checklist files, `.cron/**`, WebKit renderer code, JavaScript/CSS/font renderer assets, Info.plist files, entitlements, privacy manifests, background modes, CDN dependencies, or network renderer behavior were changed.

## Implementation

- Hardened `IOSDevicectlDeviceListParser` real-device connection classification.
- `devicectl` JSON and table states are now normalized case-insensitively and strip parenthesized suffixes such as `Available (paired)`.
- When `connectionProperties.tunnelState` is present, the parser now requires an explicit `connected` state. `disconnected` and `unavailable` fail closed and cannot satisfy the physical iPhone 12-family gate.
- Added focused XCTest coverage for a paired but disconnected iPhone 12-family device so it is not counted as connected or eligible.

## Current Physical-Device Result

The iPhone 12-family real-device validation gate remains blocked.

Current local probes show:

- An available `iPhone 12` simulator destination.
- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max.
- Physical devices reported by `devicectl` were unavailable and not iPhone 12-family hardware.

Device identifiers, serial numbers, UDIDs, hostnames, and personal device names are intentionally omitted from this report.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12Devicectl` from `ios/` | PASS | Executed 5 focused devicectl parser tests with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 205 XCTest cases with 0 failures. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found an available `iPhone 12` simulator destination. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed; the available iPhone 12 entry is a simulator. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for real-device completion | Command outcome was `success`, but physical devices were unavailable and not connected iPhone 12-family hardware. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Evidence: this report at `ios/docs/reports/stage1-ios-l12-real-device-devicectl-disconnected-hardening-20260506-1320.md`.
  - Blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completed the Stage 1 open, render, search, edit, save, and rotate flow in this batch.

Supervisor can mark newly complete from this batch:

- None. This batch hardens the remaining physical-device evidence path and records a current blocker, but it does not complete the physical iPhone 12-family validation row.
