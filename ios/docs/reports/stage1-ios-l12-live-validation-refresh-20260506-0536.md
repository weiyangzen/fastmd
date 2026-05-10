# Stage 1 iOS L12 Live Validation Refresh - 2026-05-06 05:36 +0800

## Scope

Ran one bounded iOS-owned validation/evidence refresh batch for the earliest remaining iOS-owned Stage 1 items:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
- L13: `Record validation reports under ios/docs/reports/.`

This batch is limited to `ios/**`. No Android files, root `Docs/**`, `.cron/**`, WebKit surfaces, renderer assets, entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior were changed.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l12-live-validation-refresh-20260506-0536.md`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 167 XCTest cases with 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12\|Stage1'` from `ios/` | PASS | Listed `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Xcode resolved the SwiftPM `FastMDMobile` scheme for `arm64-apple-ios14.0-simulator` and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination and executed 167 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_05-35-51-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical-device completion | Connected devices listed only `Mac`. Offline physical iOS devices were `Turbulence (26.1)` and `王威扬的iPad (26.3.1)`. The `iPhone 12 (26.4.1)` entry appeared under simulators, not physical devices. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical-device completion | Parsed physical product types were `iPhone16,1` / iPhone 15 Pro and `iPad14,4` / iPad Pro 11-inch 4th generation, both unavailable. No connected `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` device was present. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer assets were found under `ios/`. |

## Current Device Evidence

Simulator:

- `iPhone 12`, identifier `1B6FEADC-308B-4069-B734-3C9C207E633F`, available and used for the build/test gates.

Physical-device probes:

| Probe | Device | Hardware / product type | OS | Connected | Eligible iPhone 12-family physical device |
| --- | --- | --- | --- | --- | --- |
| `xctrace` | Mac | unknown | unknown | yes | no |
| `xctrace` | Turbulence | unknown | 26.1 | no | no |
| `xctrace` | 王威扬的iPad | unknown | 26.3.1 | no | no |
| `devicectl` | Turbulence | iPhone16,1 / iPhone 15 Pro | 26.1 | no | no |
| `devicectl` | 王威扬的iPad | iPad14,4 / iPad Pro 11-inch 4th generation | 26.3.1 | no | no |
| simulator inventory | iPhone 12 | simulator | 26.4.1 | n/a | no |

Connected physical iPhone 12-family devices found: `0`.

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence paths:

- `ios/docs/reports/stage1-ios-l12-live-validation-refresh-20260506-0536.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Physical-device blocker:

- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was reported by `xcrun xctrace list devices`.
- No connected `iPhone13,1`, `iPhone13,2`, `iPhone13,3`, or `iPhone13,4` physical product type was reported by `xcrun devicectl list devices --json-output -`.
- The available `iPhone 12` destination is a simulator and cannot satisfy the real-device gate.
- No manual physical-device Stage 1 open, render, search, full source edit, block source edit, save, and rotate evidence was generated in this batch.
