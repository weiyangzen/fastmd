# Stage 1 iOS L12 iPhone 12 Simulator Current Validation - 2026-05-05

## Scope

Ran one bounded iOS-owned validation batch for the Stage 1 iOS simulator gates after the local simulator set gained an available `iPhone 12` destination.

Changes are limited to `ios/**`. This batch does not edit Android files, top-level `Docs/**`, `.cron/**`, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, JS/CSS/font renderer assets, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-current-20260505.md`

No Swift source files were changed in this batch.

## Validation Evidence

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 20 focused L11 tests with 0 failures. This revalidated parser/source-range, renderer snapshot, conditional renderer, file/save/security, performance, memory, accessibility, and recovery gates used by the simulator validation surface. |
| `swift test` from `ios/` | PASS | Executed 116 XCTest cases with 0 failures. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`; the current iOS renderer remains native Swift fallback-only for rich Markdown surfaces. |
| `xcrun simctl list devices available \| rg "iPhone 12\|iPhone 15 Pro\|iPhone SE\|iPhone 16\|iPhone 17\|iPhone Air"` from `ios/` | PASS | Available simulator list includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`; package built for `arm64-apple-ios14.0-simulator` with the `FastMDMobile` SwiftPM scheme. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; executed 116 XCTest cases with 0 failures and produced `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.05_22-34-46-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device gate | The only visible physical devices are `Mac` plus two offline iOS-family devices: `Turbulence (26.1)` and `王威扬的iPad (26.3.1)`. The `iPhone 12 (26.4.1)` entry is listed under Simulators, not physical devices. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-current-20260505.md`
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed.
- `swift test --filter FastMDMobileCoreTests/testIOSL11` passed.
- `swift test` passed.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Residual blocker:

- No connected iPhone 12-family physical device was available in this batch. Real-device parity validation remains blocked until eligible hardware is connected and the full Stage 1 open, render, search, edit, save, and rotation flow is run on that device.
