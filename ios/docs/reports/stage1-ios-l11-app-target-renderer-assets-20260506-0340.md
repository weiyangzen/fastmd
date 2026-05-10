# Stage 1 iOS L11 App-Target Renderer Asset Gate

- Generated: 2026-05-06T03:40:00+08:00
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**`
- Blueprint cluster: L11 automated conditional renderer gates

## Batch Summary

This batch hardens the iOS conditional renderer manifest/offline gate for future local rich-renderer assets.

The prior gate accepted these bundled renderer resource roots:

- `ios/Resources/FastMDRenderers/`
- `ios/Sources/FastMDMobileCore/Resources/FastMDRenderers/`

The iOS tree also has an app-target namespace under `ios/Sources/FastMDMobile/`. If a future native app target vendors Mermaid/math renderer assets there, the L11 manifest/hash audit should treat those files as valid bundled iOS resources, not as loose local files.

## Implementation Evidence

- Updated `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift` to include `ios/Sources/FastMDMobile/Resources/FastMDRenderers/` in `IOSRendererAssetManifestEntry.bundledRendererResourcePathPrefixes`.
- Updated `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`:
  - `testIOSL11RendererAssetManifestEntriesRequireBundledResourcePaths` now asserts the app-target renderer resource root is accepted.
  - Added `testIOSL11RendererAssetInventoryAcceptsAppTargetBundledRendererAssets`, which creates a temporary app-target renderer asset, inventories it, verifies the normalized platform-local path, checks bundled-resource classification, and verifies the manifest/hash audit passes.
- Revalidated the existing conditional WKWebView/request-blocking tests in the full SwiftPM run:
  - `testIOSRichRendererRequestBlockingPolicyAllowsOnlyBundledRendererFiles`
  - `testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames`
  - `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
  - `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`

## Validation

Commands were run from `ios/`.

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetInventoryAcceptsAppTargetBundledRendererAssets` | PASS | 1 selected test, 0 failures |
| `swift test` | PASS | 151 XCTest cases, 0 failures |

## Checklist Items Advanced

The supervisor can use this report as implementation and validation evidence for the iOS side of these L11 checklist items:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

This batch does not claim new L12 iPhone 12 simulator or real-device completion. The platform validation evidence here is the SwiftPM test gate required for the current iOS SwiftPM skeleton.
