# Stage 1 iOS Live Lane L11/L12 Evidence - 2026-05-06 01:54 CST

## Scope

Ran one bounded iOS-only live-lane batch from `/Users/wangweiyang/GitHub/fastmd`.

Earliest still-open iOS-owned rows from the current blueprint/todo snapshot were:

- L11 conditional local renderer packaging/offline tests.
- L11 conditional WebView/WKWebView request-blocking tests.
- L11 conditional renderer asset manifest/hash verification tests.
- L12 iOS iPhone 12 simulator build.
- L12 iOS iPhone 12 simulator tests.

No Android files, shared `Docs/**` files, `.cron/**` files, source code, test code, renderer assets, Xcode project files, entitlements, Info.plist files, privacy manifests, or background modes were edited.

## Implementation Evidence

Current iOS runtime stays native Swift/SwiftUI/UIKit:

- Ordinary Markdown render contracts remain native.
- Mermaid and math rich blocks render as native safe-card fallbacks.
- No JS/CSS/font/HTML renderer assets are vendored under `ios/`.
- No active WebKit rich-renderer source usage was found under `ios/Sources`.

Existing implementation and tests providing the gate contracts:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Relevant XCTest coverage included in this validation:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11ConditionalRendererChecklistItemsExposeFutureRequiredAssetGates`
- `testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines`
- `testIOSL11ConditionalRendererEvidenceBuilderProducesReproducibleNativeFallbackReport`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`
- `testIOSL11ConditionalRendererPackagingGateRejectsLooseLocalAssets`
- `testIOSL11ConditionalRendererReportCapturesNativeFallbackEvidence`
- `testIOSL11RendererAssetInventoryDetectsBundleAssetsAndWebKitSource`
- `testIOSL11RendererAssetInventoryScansAllIOSTargetSourcesByDefault`
- `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`
- `testIOSL11RendererAssetManifestEntriesRequireBundledResourcePaths`
- `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`
- `testIOSL11RendererAssetManifestHashAuditRejectsDuplicateManifestPaths`
- `testIOSL11RendererAssetManifestHashAuditRejectsLooseLocalAssetPaths`
- `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`
- `testIOSL12SimulatorValidationReportCapturesIPhone12BuildAndTestGates`
- `testIOSL12SimulatorValidationReportKeepsGatesOpenWhenDestinationOrTestsFail`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 139 XCTest cases with 0 failures in 1.893 seconds. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repo root | PASS | Empty output. No JS/CSS/font/HTML renderer assets found under `ios/`. |
| `rg -n "^(import WebKit)\|WKWebView\(" ios/Sources` from repo root | PASS | No matches. No active WebKit rich-renderer source usage found under `ios/Sources`. |
| `xcodebuild -list` from `ios/` | PASS WITH WARNING | Found SwiftPM workspace `ios` and scheme `FastMDMobile`. Xcode also emitted `Supported platforms for the buildables in the current scheme is empty.` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build targeted `arm64-apple-ios14.0-simulator` with iPhoneSimulator26.4 SDK and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 139 XCTest cases with 0 failures in 0.890 seconds and ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_01-53-51-+0800.xcresult`. |

The `xcodebuild -list`, build, and test invocations all emitted the same Xcode warning about an empty supported-platform set for the SwiftPM scheme buildables. The iPhone 12 simulator build and test commands still completed successfully, so this is recorded as a warning rather than a blocker for the simulator gates.

## Supervisor Checklist Mapping

Supervisor can mark complete with this evidence:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence path for this batch:

- `ios/docs/reports/stage1-ios-live-lane-l11-l12-simulator-evidence-20260506-0154.md`

## Remaining iOS Gate

The iOS iPhone 12-class real-device validation gate remains open. This batch did not run a physical device validation flow.
