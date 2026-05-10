# Stage 1 iOS L12 Real-Device Live Blocker - 2026-05-06

## Scope

Ran one bounded iOS-owned L12 validation batch for the remaining physical iPhone 12-family validation gate.

Changes are limited to `ios/**`. This batch did not edit Android files, shared `Docs/**` files, `.cron/**`, Swift source, XCTest source, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-live-blocker-20260506.md`

No implementation files changed in this batch. The existing real-device validation contract and parser coverage remain in:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Current Device Probe

Required gate:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Result:

- BLOCKED: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max, and no other connected physical iPhone 12-family hardware identifier, was available to run the Stage 1 open/render/search/edit/save/rotate flow.

Observed device state:

| Probe | Result |
| --- | --- |
| `xcrun xctrace list devices` | PASS command; connected physical devices list contained only `Mac`. |
| `xcrun xctrace list devices` offline section | Listed `Turbulence (26.1)` and `王威扬的iPad (26.3.1)` as offline devices. |
| `xcrun devicectl list devices --json-output /tmp/fastmd-ios-devices-20260506.json` | PASS command; listed `Turbulence` as `iPhone 15 Pro (iPhone16,1)` with state `unavailable`, and `王威扬的iPad` as `iPad Pro (11-inch) (4th generation) (iPad14,4)` with state `unavailable`. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|Stage1\|iPhone"` | PASS command; iPhone 12 simulator remains available, but simulator evidence does not satisfy the physical real-device gate. |

Identifiers and serial numbers are intentionally omitted from this report because the blocker is device class and connection state, not a need to preserve full hardware identifiers in the evidence file.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12RealDevice` from `ios/` | PASS | Executed 11 focused real-device report contract tests with 0 failures. Coverage includes eligible iPhone 12-family hardware acceptance, non-iPhone-12 rejection, stale probe rejection, prerequisite checks, and required manual evidence checks. |
| `swift test` from `ios/` | PASS | Executed 136 tests with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- The current machine did not expose a connected physical iPhone 12-family device.
- The available iPhone 12 simulator has already been validated in earlier iOS evidence, but simulator validation cannot replace the required physical real-device validation.

Supervisor can use this report as fresh blocker evidence, not as completion evidence for the real-device gate.
