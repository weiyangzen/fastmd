# Stage 1 iOS L11/L12 Conditional Renderer Live Evidence

- Generated: 2026-05-06 07:27 +0800
- Worker scope: iOS only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Daily snapshot source: `Docs/todos_20260505.md`

## Batch Scope

This batch advances the earliest still-open iOS-owned cluster: L11 conditional local renderer test gates.

The current iOS runtime path remains native Swift/SwiftUI/UIKit with native safe fallback cards for rich Markdown blocks. No JS/CSS/font/HTML renderer assets are present in the iOS app source tree, and no WebKit rich-renderer source is present in `ios/Sources`.

## Implementation Evidence

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
  - `LocalRichRendererAssetPolicy`
  - `LocalRichRendererRuntimeAudit`
  - `IOSRichRendererRequestBlockingPolicy`
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
  - `IOSRendererAssetInventory`
  - `IOSRendererAssetManifestHashAudit`
  - `IOSLocalRendererConditionalGateAudit`
  - `IOSConditionalRendererGateEvidenceBuilder`
  - `IOSConditionalRendererGateReport`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
  - `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`
  - `testIOSL11ConditionalRendererEvidenceBuilderAuditsCurrentSourceTreeFromMarkdownSource`
  - `testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems`
  - `testIOSL11ConditionalRendererEvidenceBuilderAcceptsRequestBlockedWKWebViewMode`
  - `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`
  - `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`
  - `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
  - `testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames`

## Current Renderer Inventory

Command:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result:

```text
No production iOS renderer assets found.
```

Interpretation:

- Local renderer packaging/offline gate is not applicable in the current native fallback runtime.
- WKWebView request-blocking gate is not applicable in the current native fallback runtime.
- Renderer asset manifest/hash gate is not applicable because no JS/CSS/font/HTML renderer assets are vendored.
- Future vendored renderer mode is still covered by tests that require bundled `FastMDRenderers` paths, exact manifest hashes/byte counts, and request-blocked local WKWebView policy before the gate can pass.

## Validation

Command:

```bash
cd ios && swift test
```

Result:

```text
PASS - 180 tests, 0 failures, 0 unexpected failures.
```

Command:

```bash
cd ios && xcrun simctl list devices available | rg 'iPhone 12'
```

Result:

```text
PASS - iPhone 12 simulator destination is available: 1B6FEADC-308B-4069-B734-3C9C207E633F.
```

Command:

```bash
cd ios && xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result:

```text
PASS - BUILD SUCCEEDED.
```

Command:

```bash
cd ios && xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result:

```text
PASS - TEST SUCCEEDED; 180 tests, 0 failures, 0 unexpected failures.
```

## Supervisor Completion Recommendations

The supervisor can mark these blueprint checklist items complete with this report plus the implementation/test files listed above:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- Run iOS iPhone 12 simulator build.
- Run iOS iPhone 12 simulator tests.
- Record validation reports under `ios/docs/reports/`.

The physical iPhone 12-family real-device validation gate should remain open until a connected iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the manual Stage 1 open, render, search, edit, save, and rotate flow.
