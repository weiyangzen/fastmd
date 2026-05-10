# Stage 1 iOS L11 Conditional Renderer Evidence Refresh - 2026-05-06 02:45 +0800

## Scope

Ran one bounded iOS-owned live-lane batch for the earliest still-open iOS-owned checklist lines in the authoritative blueprint.

Authoritative open lines addressed:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

This batch did not edit Android files, shared `Docs/**`, `.cron/**`, app entitlements, Info.plist files, renderer assets, WebKit runtime code, or network/CDN behavior.

## Current iOS Renderer Posture

The iOS Stage 1 renderer remains native Swift model rendering with native safe-card fallback presentations for rich Markdown blocks such as Mermaid and math. The current iOS tree does not vendor JavaScript, CSS, font, or HTML renderer assets, and there is no active WKWebView rich-rendering surface.

Current source evidence:

- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift` presents Mermaid and math as `NativeMarkdownRichFallbackSurface.nativeSafeCard`.
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift` models the conditional renderer gates, renderer asset inventory, platform-local bundled resource path checks, SHA-256 manifest verification, and WKWebView request-blocking policy.
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift` contains the executable L11 tests for native-fallback and future asset-present paths.

## Probe Results

| Probe | Command | Result |
| --- | --- | --- |
| Renderer asset inventory | `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` | PASS: returned no files. |
| Active WebKit surface probe | `rg -n "^(import WebKit)\|WKWebView\\(" ios/Sources ios/Tests` | PASS: no active import or constructor matches; only a test method name/string reference contains `WKWebView`. |

## Validation Results

| Validation | Result | Evidence |
| --- | --- | --- |
| L11-focused SwiftPM tests | PASS | `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` executed 32 tests with 0 failures. |
| Full SwiftPM tests | PASS | `swift test` from `ios/` executed 146 tests with 0 failures. |

## Executable Coverage Summary

The focused L11 suite covers the three conditional renderer checklist lines in both current and future modes:

- Native fallback mode keeps local renderer packaging/offline validation not applicable when no JS/CSS/font/HTML assets are present.
- Future vendored renderer assets must be discovered under iOS platform-local bundled resource paths and must be represented by exact SHA-256 manifest entries.
- Missing, tampered, duplicate, remote, and loose local renderer asset manifests are rejected.
- No active WKWebView rich surface keeps request-blocking validation not applicable in the current build.
- Future WKWebView rich surfaces are accepted only when local asset packaging, request blocking, external navigation blocking, remote subresource blocking, `javascript:` blocking, `data:` blocking, and iframe blocking are represented by policy evidence.
- Unsafe WKWebView rich surfaces are rejected by the conditional renderer audit.

Relevant test names observed in the focused run:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`
- `testIOSL11RendererAssetInventoryDetectsBundleAssetsAndWebKitSource`
- `testIOSL11RendererAssetInventoryFindsDeepBundledRendererAssets`
- `testIOSL11RendererAssetInventoryScansAllIOSTargetSourcesByDefault`
- `testIOSL11RendererAssetManifestEntriesRequireBundledResourcePaths`
- `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`
- `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`
- `testIOSL11RendererAssetManifestHashAuditRejectsDuplicateManifestPaths`
- `testIOSL11RendererAssetManifestHashAuditRejectsLooseLocalAssetPaths`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`
- `testIOSL11ConditionalRendererPackagingGateRejectsLooseLocalAssets`
- `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
- `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
- `testIOSL11ConditionalRendererReportCapturesNativeFallbackEvidence`
- `testIOSL11ConditionalRendererEvidenceBuilderProducesReproducibleNativeFallbackReport`
- `testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines`
- `testIOSL11ConditionalRendererChecklistItemsExposeFutureRequiredAssetGates`

## Checklist Evidence For Supervisor

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-conditional-renderer-evidence-refresh-20260506-0245.md`

Still open in this batch:

- L12 platform validation gates not directly run in this batch beyond SwiftPM validation remain under their existing platform-validation reports.
- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.` remains open unless a connected physical iPhone 12-family device completes the full manual flow.
