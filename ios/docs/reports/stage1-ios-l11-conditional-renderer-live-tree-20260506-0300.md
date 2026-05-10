# Stage 1 iOS L11 Conditional Renderer Live Tree Evidence - 2026-05-06 03:00 +0800

## Scope

This was one bounded iOS-only live-lane batch. It refreshed evidence for the earliest open iOS-owned L11 conditional renderer gates without editing Android or the authoritative Docs checklist.

Blueprint checklist lines covered:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

## Live Tree Findings

The current iOS implementation remains native Swift/SwiftUI/UIKit with native rich Markdown fallback cards for Mermaid and math. No JS/CSS/font/HTML renderer assets are present under `ios/`, and no iOS source file imports WebKit or constructs `WKWebView`.

| Probe | Result | Evidence |
| --- | --- | --- |
| Renderer asset inventory | PASS / none found | `find ios -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` returned no files. |
| WebKit rich renderer source scan | PASS / none in sources | `rg -n "^import WebKit$|WKWebView\(" ios/Sources` returned no matches. |
| iOS source scan count | PASS | `find ios/Sources -type f -name '*.swift' \| sort \| wc -l` returned `9`. |
| iPhone 12 simulator inventory | PASS / available | `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|iPhone 16\|iPhone 17\|iPhone Air\|iPhone SE"` listed `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. This probe does not complete the physical-device gate. |

## Test Evidence

| Command | Result | Notes |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11Conditional` from `ios/` | PASS | Executed 9 focused conditional renderer tests with 0 failures. Covered native-fallback non-applicability, future vendored-asset manifest/hash requirements, loose asset rejection, unsafe WKWebView rejection, safe request-blocked WKWebView acceptance, report generation, and blueprint checklist text matching. |
| `swift test` from `ios/` | PASS | Executed 146 XCTest cases with 0 failures. This is the minimum required local SwiftPM validation for the current SwiftPM skeleton. |

## Checklist Evidence

The three L11 conditional renderer checklist items can be reconciled as satisfied for the current iOS implementation because their triggering conditions are absent and the tests also cover future required paths if JS/CSS/font assets or a WKWebView rich surface are introduced.

| Blueprint checklist item | Current iOS status | Completion evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | Not applicable native fallback; guarded for future assets. | No renderer assets found in live tree; focused tests include `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`, `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`, `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`, and `testIOSL11ConditionalRendererPackagingGateRejectsLooseLocalAssets`. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | Not applicable native fallback; guarded for future WKWebView rich surfaces. | No WebKit import or `WKWebView(` construction under `ios/Sources`; focused tests include `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces` and `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | Not applicable native fallback; guarded for future vendored assets. | No JS/CSS/font/HTML assets found in live tree; focused tests include `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`, `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`, `testIOSL11RendererAssetManifestHashAuditRejectsDuplicateManifestPaths`, and `testIOSL11RendererAssetManifestHashAuditRejectsLooseLocalAssetPaths`. |

## Remaining Open Gate

This batch does not claim the L12 physical iPhone 12-family real-device validation gate. A simulator destination is available, but parity-complete release evidence still requires a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max and a recorded manual Stage 1 flow covering open, rich render, search, full source edit, block source edit, save, and rotation.
