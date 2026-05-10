# Stage 1 iOS L12 Real-Device Probe Refresh - 2026-05-06 13:35 CST

## Scope

One bounded iOS-owned validation batch for the earliest remaining iOS-owned checklist row:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch stayed under `ios/**`. No Android files, root `Docs/**` checklist files, `.cron/**`, app entitlements, Info.plist files, renderer assets, JavaScript/CSS/font dependencies, or network behavior were changed.

## Current Result

The iPhone 12-family real-device validation gate remains blocked.

Fresh local probes show:

- An available `iPhone 12` simulator destination exists.
- `xcrun xctrace list devices` reports the local Mac as connected, two physical devices as offline, and `iPhone 12` only under simulators.
- `xcrun devicectl list devices --json-output -` completed with `outcome: success`, after a CoreDevice provider warning, but the physical devices it reported are unavailable and are not iPhone 12-family hardware.
- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available for the required open, render, search, edit, save, and rotate flow.

Device identifiers, serial numbers, UDIDs, hostnames, personal device names, and raw JSON payloads are intentionally omitted from this report.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Built the SwiftPM package and executed 206 XCTest cases with 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found an available `iPhone 12` simulator destination. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed; the available iPhone 12 entry is a simulator. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for real-device completion | Command outcome was `success`, but listed physical devices were unavailable and not iPhone 12-family hardware. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Evidence: this report at `ios/docs/reports/stage1-ios-l12-real-device-probe-refresh-20260506-1335.md`.
  - Blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completed the Stage 1 open, render, search, edit, save, and rotate flow in this batch.

Supervisor can mark newly complete from this batch:

- None. This batch refreshes validation evidence for the remaining physical-device gate, but it does not complete that gate.
