# Stage 1 iOS L12 iPhone 12 Simulator Validation Pass - 2026-05-06 06:42 +0800

## Scope

Ran one bounded iOS-owned L12 validation batch against the exact iPhone 12 simulator destination required by the Stage 1 mobile blueprint.

This batch only writes iOS-local evidence under `ios/docs/reports/`.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- iOS package root: `/Users/wangweiyang/GitHub/fastmd/ios`
- Xcode scheme: `FastMDMobile`
- Required destination: `platform=iOS Simulator,name=iPhone 12`
- Available iPhone 12 simulator: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`
- Xcode resolved package: `FastMDMobile: /Users/wangweiyang/GitHub/fastmd/ios`
- iPhone simulator SDK observed in build logs: `iPhoneSimulator26.4.sdk`
- Deployment target observed in build logs: `arm64-apple-ios14.0-simulator`

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 175 tests with 0 failures. This is the minimum SwiftPM validation required while the iOS lane is a SwiftPM skeleton. |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 50 focused L11 tests with 0 failures. This revalidated parser contracts, source range mapping, fixture snapshots, layout safety, file access, save integrity, malicious fixtures, remote image privacy, conditional renderer gates, renderer asset inventory/hash checks, WKWebView request-blocking policy, diagnostics redaction, performance, memory stress, accessibility smoke, and process recovery. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -list` from `ios/` | PASS | Resolved workspace `ios` and scheme `FastMDMobile`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build completed against the exact destination and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the exact destination. Executed 175 tests with 0 failures. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_06-42-28-+0800.xcresult`. Xcode ended with `** TEST SUCCEEDED **`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS files. |
| `xcrun xctrace list devices` from `ios/` | PASS probe, real-device gate still OPEN | Listed the Mac, offline physical devices, and the iPhone 12 simulator. No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available for the required manual Stage 1 flow. |
| `xcrun devicectl list devices --json-output -` from `ios/` | PASS probe with warning, real-device gate still OPEN | Command outcome was success and JSON listed unavailable physical devices: `iPhone 15 Pro (iPhone16,1)` and `iPad Pro (11-inch) (4th generation) (iPad14,4)`. Neither is connected eligible iPhone 12-family hardware. Devicectl also printed `No provider was found.` before JSON output, but still returned successful device-list JSON. |

## Real-Device Blocker

The iPhone 12-class real-device gate remains open. The available physical-device probes did not report a connected physical iPhone 12-family device.

Observed physical devices:

- `Turbulence`, iPhone 15 Pro, product type `iPhone16,1`, unavailable.
- `王威扬的iPad`, iPad Pro 11-inch 4th generation, product type `iPad14,4`, unavailable.

Observed iPhone 12 device:

- `iPhone 12`, identifier `1B6FEADC-308B-4069-B734-3C9C207E633F`, simulator, not physical hardware.

The parity-complete release claim still requires a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max to complete the Stage 1 open, render, search, edit, save, and rotate flow with recorded manual evidence.

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence path:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-pass-live-20260506-0642.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
