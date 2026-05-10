# Stage 1 iOS L12 iPhone 12 Simulator Build/Test Evidence - 2026-05-06

## Scope

This bounded live-lane batch was limited to `ios/**`. It did not edit Android files, root `Docs/**`, `.cron/**`, Swift implementation source, XCTest source, renderer assets, WebKit surfaces, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

The batch revalidated the current native Swift/SwiftUI/UIKit Stage 1 iOS skeleton on the locally available iPhone 12 simulator destination.

## Environment

- Repository: `/Users/wangweiyang/GitHub/fastmd`
- iOS package: `/Users/wangweiyang/GitHub/fastmd/ios`
- Available simulator destination: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)`, runtime `iOS 26.4.1`
- SwiftPM/Xcode scheme: `FastMDMobile`
- Xcode selected by command output: `/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild`
- Simulator SDK observed in build output: `iPhoneSimulator26.4.sdk`
- Build target observed in build/test output: `arm64-apple-ios14.0-simulator`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `xcrun simctl list devices available \| rg 'iPhone 12\|iPhone 15\|iOS\|--'` from repository root | PASS | Listed an available `iPhone 12` simulator under iOS 26.4. |
| `xcodebuild -list` from `ios/` | PASS | Resolved the SwiftPM workspace and listed scheme `FastMDMobile`. |
| `swift test` from `ios/` | PASS | Executed 136 tests with 0 failures. Covered canonical fixture matrix, L11 gates, L12 report models, renderer/security/performance/accessibility/save paths, and native rich Markdown fallback behavior. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 18 focused L12 tests with 0 failures. Covered simulator validation report model, performance report model, security audit report model, rich fixture report model, and real-device prerequisite/report guards. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`; built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` against the iPhone simulator SDK. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; executed 136 tests with 0 failures on the iPhone 12 simulator. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_01-14-10-+0800.xcresult`. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcrun xctrace list devices 2>/dev/null \| rg 'iPhone\|iPad\|Connected\|Simulator\|=='` from repository root | BLOCKED for real-device gate | Physical-device listing did not show a connected iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. It showed an offline iPad and simulator destinations, including the iPhone 12 simulator. |
| `xcrun devicectl list devices --json-output -` from repository root | BLOCKED for real-device gate | Physical devices parsed from JSON were an iPhone 15 Pro (`productType` `iPhone16,1`, `hardwareModel` `D83AP`) and an iPad Pro (`productType` `iPad14,4`, `hardwareModel` `J618AP`). No iPhone 12-family physical device was present, so the real-device parity gate remains open. |

## Checklist Evidence

The supervising session can mark these iOS-owned L12 checklist items complete:

- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed in this report.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed in this report with 136 tests and 0 failures.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this report is stored under `ios/docs/reports/`.

These iOS-owned L12 checklist items should remain open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Blocker: no connected physical iPhone 12-family device was present in `xctrace` or `devicectl` output during this batch.

## Notes

- `xcodebuild` emitted `IDERunDestination: Supported platforms for the buildables in the current scheme is empty.` while resolving the SwiftPM package, but both the iPhone 12 simulator build and test actions completed successfully.
- The current iOS renderer remains native fallback-only for Mermaid/math rich blocks. No JS/CSS/font/HTML renderer assets or WKWebView rich-renderer surface were introduced or discovered.
