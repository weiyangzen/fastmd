# Stage 1 iOS L12 Real-Device Live Blocker - 2026-05-06 04:00 +0800

## Scope

Ran one bounded iOS-owned validation/reporting batch for the earliest remaining iOS-owned checklist item:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-live-blocker-20260506-0400.md`

No Swift implementation files or XCTest files were changed in this batch. Existing real-device validation model and parser coverage remains in:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Current Physical-Device Probe

Probe time:

```text
2026-05-06 04:00:30 +0800
```

Commands:

```bash
xcrun xctrace list devices
xcrun devicectl list devices --json-output /tmp/fastmd-ios-real-device-probe-20260506-live.json
```

Observed result:

- `xcrun xctrace list devices` listed `Mac` as the only connected device.
- `xcrun xctrace list devices` listed two offline physical iOS-family devices, but neither was connected.
- `xcrun devicectl list devices` returned success and listed physical iOS-family devices as `unavailable`.
- The unavailable iPhone-class device was `iPhone 15 Pro (iPhone16,1)`, not an iPhone 12-family model.
- The other unavailable iOS-family device was an iPad-class device, not an iPhone 12-family model.
- The local `iPhone 12` entry is available only under CoreSimulator, not as connected physical hardware.

Identifiers, serial numbers, hostnames, and UDIDs are intentionally omitted from this report. The blocker is device class and connection state, not device identity.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 153 XCTest cases with 0 failures. Includes L12 real-device parser/report guards and simulator prerequisite contract tests. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Command succeeded, but no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was listed. |
| `xcrun devicectl list devices --json-output /tmp/fastmd-ios-real-device-probe-20260506-live.json` from `ios/` | BLOCKED for real-device completion | Command succeeded, but physical iOS-family devices were unavailable and not connected iPhone 12-family hardware. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|iPhone"` from `ios/` | PASS for simulator availability only | CoreSimulator lists an `iPhone 12` simulator. This does not satisfy the physical real-device gate. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- No connected physical iPhone 12-family device is available in the local device set.
- The Stage 1 open, render, search, full source edit, block source edit, save writable document, and rotate reader flow cannot be validated on required physical hardware in this batch.

Evidence paths:

- `ios/docs/reports/stage1-ios-l12-real-device-live-blocker-20260506-0400.md`
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

No blueprint checklist item should be marked complete from this batch. The batch refreshes current blocker evidence for the real-device gate only.
