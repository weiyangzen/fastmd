# Stage 1 iOS L12 iPhone 12 Simulator Pass Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L12 validation batch for the mandatory iPhone 12 simulator gates:

- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`

Changes are limited to `ios/**`. No Android files, root Docs checklist files, renderer assets, WebKit surface, app entitlements, privacy manifest, or background modes were changed.

## Environment

| Item | Evidence |
| --- | --- |
| Repository | `/Users/wangweiyang/GitHub/fastmd` |
| iOS package | `/Users/wangweiyang/GitHub/fastmd/ios` |
| Date | 2026-05-05 |
| Xcode command destination | `platform=iOS Simulator,name=iPhone 12` |
| Installed matching simulator | `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)`, available before validation |
| SwiftPM package target | `FastMDMobileCore` |
| Xcode scheme | `FastMDMobile` |
| Build target triple observed | `arm64-apple-ios14.0-simulator` |
| Simulator SDK observed | `iPhoneSimulator26.4.sdk` |
| Current validation run | 2026-05-05 23:45-23:48 +0800 |

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Listed `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)` as an available simulator. |
| `xcodebuild -list` from `ios/` | PASS | Resolved SwiftPM workspace `ios` and listed scheme `FastMDMobile`. Xcode emitted `Supported platforms for the buildables in the current scheme is empty`, but the package scheme still built and tested successfully on the explicit iPhone 12 simulator destination below. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12SimulatorValidationReport` from `ios/` | PASS | Executed 2 focused L12 simulator validation report tests with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 126 XCTest cases with 0 failures. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Xcode built the SwiftPM package for the iPhone 12 simulator destination and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 126 XCTest cases with 0 failures on the iPhone 12 simulator destination and ended with `** TEST SUCCEEDED **`. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `rg -n '^(import WebKit)\|WKWebView\(' ios/Sources/FastMDMobileCore` from repository root | PASS | No active WebKit rich-rendering source usage was found. |

Xcode test result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.05_23-47-22-+0800.xcresult
```

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence:

- `ios/docs/reports/stage1-ios-l12-iphone12-simulator-pass-20260505.md`
- `xcrun simctl list devices available | rg 'iPhone 12'` found an available iPhone 12 simulator.
- `xcodebuild -list` exposed SwiftPM scheme `FastMDMobile`.
- `swift test --filter FastMDMobileCoreTests/testIOSL12SimulatorValidationReport` passed from `ios/`.
- `swift test` passed from `ios/`.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed from `ios/`.
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed from `ios/`.
- Xcode iPhone 12 simulator test result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.05_23-47-22-+0800.xcresult`.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Residual blocker:

- This batch validated the iPhone 12 simulator only. It did not validate a physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max device or complete the manual open-render-search-edit-save-rotate real-device flow.
