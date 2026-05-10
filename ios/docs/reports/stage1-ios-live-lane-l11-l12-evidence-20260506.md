# Stage 1 iOS Live Lane L11/L12 Evidence - 2026-05-06

## Batch Scope

Advanced the earliest still-open iOS-owned checklist surface in the shared blueprint without editing shared Docs:

- L11 conditional local renderer packaging/offline gate.
- L11 conditional WKWebView request-blocking gate.
- L11 conditional renderer asset manifest/hash gate.
- L12 iPhone 12 simulator build/test evidence refresh.

No Android files, shared `Docs/` files, remote renderer runtime, WebKit renderer implementation, JS/CSS/font/HTML renderer asset, CDN dependency, entitlement, privacy manifest, or background mode was introduced.

## Implementation Evidence

The iOS implementation remains native Swift/SwiftUI/UIKit model code:

- Rich Mermaid and math blocks render as native safe-card fallbacks.
- `IOSRendererAssetInventory` recursively scans `ios/` for JS/CSS/font/HTML renderer assets and computes SHA-256 entries for any discovered assets.
- `IOSRendererAssetInventory` scans Swift sources for active WebKit rich-renderer code by detecting `import WebKit` or `WKWebView(` construction.
- `IOSLocalRendererConditionalGateAudit` keeps the three conditional renderer checklist gates satisfied only when native fallback is proven, or when future vendored assets are local bundled resources with passing manifest/hash validation.
- `IOSRendererAssetManifestHashAudit` rejects missing, tampered, remote, duplicate, non-iOS-local, and loose non-bundled asset entries.

Relevant implementation/test files:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Current Renderer Inventory

Command:

```sh
find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) | sort
```

Result:

- PASS: no JS/CSS/font/HTML renderer assets were found under `ios/`.
- PASS: L11 inventory tests confirm Swift source scanning finds no active WebKit rich-renderer code in the current native-fallback runtime.

## Conditional L11 Gate Results

| Blueprint checklist item | Result | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | PASS / not applicable native fallback | No JS/CSS/font/HTML renderer assets are present under `ios/`; native rich fallback cards require no renderer package. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | PASS / not applicable native fallback | No WKWebView rich surface is active; tests also cover future safe/unsafe WKWebView posture. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | PASS / not applicable native fallback | No vendored renderer assets exist now; tests cover future exact bundled-resource SHA-256 manifest acceptance and tamper/remote/loose-path rejection. |

Focused L11 validation:

```sh
cd ios
swift test --filter FastMDMobileCoreTests/testIOSL11
```

Result:

- PASS: 26 tests, 0 failures.
- Conditional renderer tests included:
  - `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
  - `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`
  - `testIOSL11RendererAssetInventoryDetectsBundleAssetsAndWebKitSource`
  - `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`
  - `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`
  - `testIOSL11RendererAssetManifestHashAuditRejectsLooseLocalAssetPaths`
  - `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`
  - `testIOSL11ConditionalRendererPackagingGateRejectsLooseLocalAssets`
  - `testIOSL11ConditionalRendererReportCapturesNativeFallbackEvidence`
  - `testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines`
  - `testIOSL11ConditionalRendererChecklistItemsExposeFutureRequiredAssetGates`

## Platform Validation

SwiftPM validation:

```sh
cd ios
swift test
```

Result:

- PASS: 135 tests, 0 failures.

iPhone 12 simulator discovery:

```sh
xcrun simctl list devices available | rg "iPhone 12|iPhone 15 Pro"
```

Result:

- PASS: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` is available.
- Additional available simulator: `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)`.

Xcode scheme discovery:

```sh
cd ios
xcodebuild -list
```

Result:

- PASS: SwiftPM workspace exposes scheme `FastMDMobile`.
- Note: xcodebuild emits `IDERunDestination: Supported platforms for the buildables in the current scheme is empty.` during SwiftPM package resolution, but build/test completed successfully.

iPhone 12 simulator build:

```sh
cd ios
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result:

- PASS: `** BUILD SUCCEEDED **`

iPhone 12 simulator tests:

```sh
cd ios
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result:

- PASS: 135 tests, 0 failures.
- PASS: `** TEST SUCCEEDED **`
- xcresult: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_01-07-49-+0800.xcresult`

## Remaining Open Gate

The iOS iPhone 12-class real-device validation gate remains open. This batch validated the iPhone 12 simulator and did not have connected physical iPhone 12-family hardware evidence or manual real-device flow evidence.

## Supervisor Reconciliation Candidates

The supervising session can reconcile these blueprint checklist items as complete based on the implementation and validation evidence above:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L13: `Record validation reports under ios/docs/reports/.`

Keep this gate open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
