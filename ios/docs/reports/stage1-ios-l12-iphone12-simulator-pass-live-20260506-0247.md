# Stage 1 iOS L12 iPhone 12 Simulator Pass - 2026-05-06 02:47 CST

## Scope

Ran one bounded iOS-owned live-lane validation batch from `/Users/wangweiyang/GitHub/fastmd`.

Earliest open iOS-owned L12 gates advanced in this batch:

- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`

No Android files, shared `Docs/**` files, `.cron/**` files, source files, renderer assets, Xcode project files, entitlements, Info.plist files, privacy manifests, or background modes were edited.

## Environment Evidence

- Current iOS simulator inventory includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)` under iOS 26.4.
- Xcode accepted the blueprint destination string `platform=iOS Simulator,name=iPhone 12`.
- SwiftPM/Xcode built the package target for `arm64-apple-ios14.0-simulator` with the iPhoneSimulator26.4 SDK.
- Xcode emitted the existing SwiftPM warning: `Supported platforms for the buildables in the current scheme is empty.`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 146 XCTest cases with 0 failures in 1.770 seconds. |
| `xcrun simctl list devices available` from `ios/` | PASS | Listed `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)` under iOS 26.4. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS WITH WARNING | Build ended with `** BUILD SUCCEEDED **`; target triple was `arm64-apple-ios14.0-simulator`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS WITH WARNING | Executed 146 XCTest cases with 0 failures in 0.904 seconds and ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_02-47-41-+0800.xcresult`. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repo root | PASS | Empty output. No JS/CSS/font/HTML renderer assets found under `ios/`. |
| `rg -n "^(import WebKit)\|WKWebView\(" ios/Sources` from repo root | PASS | No matches. No active WKWebView rich-renderer source found under `ios/Sources`. |
| `xcrun devicectl list devices` from `ios/` | BLOCKED for real-device gate | Listed unavailable `iPhone 15 Pro (iPhone16,1)` and unavailable `iPad Pro (11-inch) (4th generation) (iPad14,4)`. No connected, available iPhone 12-family physical device was present. |

## Checklist Evidence

Supervisor can mark complete with this report:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

Supporting evidence path:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-pass-live-20260506-0247.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Real-device blocker:

- `xcrun devicectl list devices` did not show any connected, available iPhone 12-family physical device. The only listed devices were unavailable and not iPhone 12-family hardware, so the real-device parity-complete validation gate remains blocked in this environment.
