# Stage 1 iOS L12 Real-Device Live Probe - 2026-05-06 01:26 +0800

## Scope

Ran one bounded iOS-owned validation/reporting batch for the earliest remaining iOS-owned checklist item:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-live-probe-20260506-0126.md`

No Swift source files, XCTest files, README files, app manifests, or renderer assets were changed in this batch.

## Current Probe Evidence

Probe commands:

```bash
xcrun xctrace list devices
xcrun devicectl list devices --json-output -
xcrun simctl list devices available | rg -n "iPhone 12|Stage1|iPhone 15|iPhone"
```

Observed local device state:

| Probe | Device | Hardware / product type | OS | Connected | Simulator | Eligible iPhone 12-family physical device |
| --- | --- | --- | --- | --- | --- | --- |
| `xctrace` | Mac | unknown | unknown | yes | no | no |
| `xctrace` | Turbulence | unknown | 26.1 | no | no | no |
| `xctrace` | iPad | unknown | 26.3.1 | no | no | no |
| `devicectl` | Turbulence | iPhone16,1 / iPhone 15 Pro | 26.1 | no | no | no |
| `devicectl` | iPad | iPad14,4 / iPad Pro 11-inch 4th generation | 26.3.1 | no | no | no |
| `simctl` | iPhone 12 | simulator destination | 26.4.1 | n/a | yes | no |
| `simctl` | Stage1 iPhone 15 Pro | simulator destination | 18.6 | n/a | yes | no |

Connected physical iPhone 12-family devices found:

- `0`

Device identifiers, serial-like fields, ECIDs, UDIDs, and hostnames are intentionally omitted from this report. They are not required to prove the blocker, and preserving them would add avoidable local-device detail.

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
- No connected `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` product type was reported by `xcrun devicectl list devices --json-output -`.
- The available `iPhone 12` destination is a simulator, not physical hardware.
- No manual real-device Stage 1 open, render, search, edit, save, and rotate evidence was generated in this batch.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 11 focused real-device report contract tests with 0 failures. Coverage includes eligible iPhone 12-family hardware acceptance, non-iPhone-12 rejection, stale probe rejection, prerequisite checks, and required manual-evidence checks. |
| `swift test` from `ios/` | PASS | Executed 136 XCTest cases with 0 failures. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | Connected physical devices: Mac only. Offline physical iOS-family devices include an iPhone-like device and an iPad. The `iPhone 12` entry is listed under simulators. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for real-device completion | Listed an unavailable iPhone 15 Pro-class product type and an unavailable iPad-class product type; no connected `iPhone13,*` iPhone 12-family product type was present. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|Stage1\|iPhone 15\|iPhone"` from `ios/` | PASS | Available simulator inventory includes `iPhone 12` and `Stage1 iPhone 15 Pro`; simulator evidence does not satisfy the physical-device gate. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence path for this blocker refresh:

- `ios/docs/reports/stage1-ios-l12-real-device-live-probe-20260506-0126.md`

No iOS checklist completion claim is made from this batch. Completion still requires a connected physical iPhone 12-family device and timestamped manual evidence for the full Stage 1 open, render rich fixture, search, full source edit, block source edit, save writable document, and rotate reader flow.
