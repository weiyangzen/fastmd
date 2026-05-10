# Stage 1 iOS L12 Real-Device Current Probe - 2026-05-05

## Scope

Ran one bounded iOS-owned validation batch for the remaining physical-device gate:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch does not edit Android files, top-level `Docs/**`, `.cron/**`, Swift source, tests, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, JavaScript/CSS/font renderer assets, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-current-probe-20260505.md`

No Swift source files or XCTest files were changed in this batch.

## Current Local Device Probe

Command:

```bash
xcrun xctrace list devices
```

Result:

- Connected devices: `Mac` only.
- Offline devices: `Turbulence (26.1)` and `王威扬的iPad (26.3.1)`.
- Simulators include `iPhone 12 (26.4.1)`.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max devices: `0`.

The available `iPhone 12` entry is listed under `== Simulators ==`, so it cannot satisfy the blueprint's real-device validation gate. The required open, render, search, edit, save, and rotate flow was not run on physical iPhone 12-family hardware in this batch.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 122 tests with 0 failures. This includes the existing L12 real-device report tests proving simulator-only and incomplete-flow cases do not complete the physical-device gate. |
| `xcrun simctl list devices available \| rg -n "iPhone 12"` from `ios/` | PASS | Local CoreSimulator lists `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real device | No connected physical iPhone 12-family device was listed. The only connected device under `== Devices ==` was `Mac`; the `iPhone 12` entry appeared under `== Simulators ==`. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence from this batch:

- `ios/docs/reports/stage1-ios-l12-real-device-current-probe-20260505.md`
- `swift test` passed with 122 tests and 0 failures.
- `xcrun xctrace list devices` remains blocked for real-device completion because no connected physical iPhone 12-family device is available.

Supervisor can use prior iOS reports for already-completed simulator and reporting gates:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-current-20260505.md`
- `ios/docs/reports/stage1-ios-l12-performance-report-20260505.md`
- `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md`
- `ios/docs/reports/stage1-ios-l13-readme-reconciliation-refresh-20260505.md`
