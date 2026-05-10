# Stage 1 iOS L12 Real-Device Hardware Model Guard - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation and validation batch for the earliest iOS-owned checklist item that remains open after simulator validation:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l12-real-device-hardware-model-20260506.md`

## Implementation Notes

- Added optional `hardwareModel` evidence to `IOSStageOnePhysicalDeviceCandidate`.
- Kept existing `xcrun xctrace list devices` parsing behavior unchanged; parsed devices continue to have `hardwareModel == nil`.
- Updated iPhone 12-family eligibility so a physical device can be accepted by either its visible device name or its supplied hardware model.
- This matters because physical iOS device listings often use a user-assigned device name instead of a marketing model name. A connected custom-named device such as `Alice's iPhone` can now satisfy the hardware-family guard only when separate evidence supplies `hardwareModel: "iPhone 12 Pro Max"` and all Stage 1 real-device flow steps are complete.
- The gate still fails closed when no connected physical iPhone 12-family device is present, when only an iPhone 12 simulator is present, or when the open/render/search/edit/save/rotate flow is incomplete.

## Current Local Device Probe

`xcrun xctrace list devices` reports:

- Connected physical devices: `Mac` only.
- Offline physical iOS devices: non-iPhone-12-family devices only.
- Simulators: includes `iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)`.
- Connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max devices: `0`.

The available `iPhone 12` entry is under the simulator section. It cannot satisfy the physical-device validation gate.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 127 XCTest cases with 0 failures. New coverage includes `testIOSL12RealDeviceValidationAcceptsCustomNamedIPhone12FamilyHardwareModel`. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `xcrun simctl list devices available \| rg -n "iPhone 12"` from `ios/` | PASS | Local CoreSimulator lists `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build resolved the SwiftPM `FastMDMobile` scheme for `arm64-apple-ios14.0-simulator` and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination and executed 127 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_00-12-22-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device completion | No connected physical iPhone 12-family device was listed. The only connected device was `Mac`; the `iPhone 12` entry appeared under simulators. |

## Checklist Evidence

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Evidence paths for the open blocker:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l12-real-device-hardware-model-20260506.md`

No L12 real-device completion claim should be made from this batch. Completion still requires a connected physical iPhone 12-family device and the full Stage 1 open, render, search, full source edit, block source edit, save writable document, and rotate reader flow.
