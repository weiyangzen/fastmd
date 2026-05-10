# Stage 1 iOS L11/L12 Current Validation Report - 2026-05-05

## Scope

Ran one bounded iOS-owned validation batch against the earliest open iOS checklist items in the authoritative Stage 1 Mobile blueprint.

This batch is limited to `ios/**`. It does not edit Android files, top-level `Docs/**`, `.cron/**`, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, JS/CSS/font renderer assets, CDN dependencies, or network renderer behavior.

## Gate Evidence

### L11 Conditional Local Renderer Gates

The current iOS renderer remains native Swift/SwiftUI/UIKit model rendering. Mermaid and math rich blocks are rendered as native safe-card fallbacks; no local JS renderer, WKWebView rich surface, CSS, font, HTML renderer asset, CDN dependency, or remote subresource path is active.

Existing implementation and tests covering this gate:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Focused tests executed in this batch:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`
- `testIOSL11ConditionalRendererReportCapturesNativeFallbackEvidence`
- `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`
- `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`

Current inventory command returned no renderer assets:

```text
find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) | sort
```

Result: PASS, empty output.

### L12 iPhone 12 Simulator Build And Tests

The local simulator set currently includes an available `iPhone 12` simulator:

```text
iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
```

Build and test were run against the exact blueprint destination:

```text
platform=iOS Simulator,name=iPhone 12
```

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 20 focused L11 tests with 0 failures. Covered native fallback conditional renderer gates, renderer asset inventory, WKWebView-not-applicable evidence, and manifest/hash verification behavior. |
| `swift test` from `ios/` | PASS | Executed 116 tests with 0 failures. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -list` from `ios/` | PASS | Resolved SwiftPM workspace and listed scheme `FastMDMobile`. |
| `xcrun simctl list devices available \| rg "iPhone 12\|Stage1 iPhone 15 Pro\|iPhone 15\|iPhone 16\|iPhone 17\|iPhone Air\|iPhone SE"` from `ios/` | PASS | Confirmed available simulator `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`; built for `arm64-apple-ios14.0-simulator` with iPhoneSimulator26.4 SDK. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; executed 116 XCTest cases with 0 failures. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.05_22-27-50-+0800.xcresult`. |

## Checklist Items Supervisor Can Mark Complete

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence paths:

- `ios/docs/reports/stage1-ios-l11-l12-current-validation-20260505.md`
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.05_22-27-50-+0800.xcresult`

## Keep Open

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason: this batch validated the iPhone 12 simulator gates only. No connected iPhone 12-family physical device was validated during this batch.
