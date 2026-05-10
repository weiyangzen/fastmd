# Stage 1 iOS L11/L12 Conditional Renderer And iPhone 12 Simulator Evidence - 2026-05-06

## Scope

Ran one bounded iOS-owned live-lane batch for the earliest still-open iOS checklist cluster.

This batch did not edit Android files, top-level Docs files, `.cron/**`, Swift source, tests, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

Changed files are limited to this iOS report under `ios/docs/reports/`.

## Current iOS Renderer Posture

The iOS Stage 1 renderer remains native Swift model rendering with native safe-card fallbacks for rich blocks such as Mermaid and math.

No JavaScript, CSS, font, or HTML renderer asset is currently vendored under `ios/`, and no active WebKit rich-rendering surface is present in `ios/Sources`.

Current command evidence:

| Probe | Result | Evidence |
| --- | --- | --- |
| Renderer asset inventory | PASS | `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` returned no files. |
| Active iOS source WebKit probe | PASS | `rg -n "^(import WebKit)\|WKWebView\\(" ios/Sources` returned no matches. |
| L11 conditional renderer tests | PASS | `swift test --filter FastMDMobileCoreTests/testIOSL11` executed 29 tests with 0 failures. |
| Full SwiftPM validation | PASS | `swift test` executed 139 tests with 0 failures. |

Existing implementation evidence remains in:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

The L11 conditional renderer tests cover both the current native-fallback path and future asset-present paths:

- native fallback keeps local renderer packaging/offline gate not applicable;
- no active WKWebView rich surface keeps request-blocking gate not applicable;
- manifest/hash verification is required and tested when renderer assets are discovered;
- missing, tampered, duplicated, remote, and loose local renderer asset manifests are rejected;
- bundled iOS renderer resource paths are accepted only under the platform-local bundled resource prefixes.

## iPhone 12 Simulator Evidence

The required iPhone 12 simulator destination is now present in the local simulator set:

```text
iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)
```

Validation results:

| Command | Result | Evidence |
| --- | --- | --- |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Xcode built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator`; output ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Xcode ran `FastMDMobileCoreTests` on the iPhone 12 simulator; executed 139 tests with 0 failures; output ended with `** TEST SUCCEEDED **`. |

Xcode test result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_01-57-05-+0800.xcresult
```

## Real-Device Gate

The iPhone 12-class physical device validation gate remains open.

Current `xcrun xctrace list devices` evidence:

- connected physical devices: `Mac` only;
- offline devices: `Turbulence (26.1)`, `王威扬的iPad (26.3.1)`;
- `iPhone 12 (26.4.1)` appears under Simulators, not connected physical devices.

Blocker:

```text
No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max class device was available for the full open, render, search, edit, save, and rotate real-device flow.
```

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
- `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-pass-20260506.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

