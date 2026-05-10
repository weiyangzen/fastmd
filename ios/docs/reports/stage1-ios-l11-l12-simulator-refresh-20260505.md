# Stage 1 iOS L11/L12 Simulator Refresh - 2026-05-05

## Scope

One bounded iOS-owned validation/evidence refresh for the earliest still-open iOS checklist rows in the daily snapshot:

- L11 conditional local renderer gates.
- L12 iOS iPhone 12 simulator build.
- L12 iOS iPhone 12 simulator tests.

No Android files, root Docs checklist files, app entitlements, Info.plist files, privacy manifests, renderer assets, WebKit code, JavaScript, CSS, fonts, or HTML renderer assets were changed.

## Current iOS Renderer Posture

- Ordinary Markdown rendering remains native Swift model rendering.
- Mermaid/math rich blocks use native safe-card fallback in this SwiftPM skeleton.
- No vendored JS/CSS/font/HTML renderer assets are present under `ios/`.
- No WKWebView rich-renderer surface is present.
- No CDN, network renderer, remote subresource dependency, `javascript:` URL path, `data:` URL path, iframe path, or external-navigation renderer path is active.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 26 focused L11 tests with 0 failures. Covered conditional renderer native-fallback evidence, renderer asset inventory, WebKit source scanning, manifest/hash acceptance and rejection, loose-path rejection, and future vendored-asset gate behavior. |
| `swift test` from `ios/` | PASS | Executed 126 tests with 0 failures. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from repository root | PASS | Local simulator set includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built the SwiftPM `FastMDMobile` scheme for the iPhone 12 simulator destination. Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the exact `platform=iOS Simulator,name=iPhone 12` destination. Executed 126 XCTest cases with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.05_23-57-38-+0800.xcresult`. |
| `xcrun xctrace list devices` from repository root | BLOCKED for real-device gate | Physical device list contains Mac plus offline iPad devices. The iPhone 12-family entry available in this environment is under `== Simulators ==`, not a connected physical device. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-l12-simulator-refresh-20260505.md`
- Existing supporting report: `ios/docs/reports/stage1-ios-l11-renderer-manifest-hash-20260505.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available for this batch, so the real-device open, render, search, edit, save, and rotate validation cannot be claimed.
