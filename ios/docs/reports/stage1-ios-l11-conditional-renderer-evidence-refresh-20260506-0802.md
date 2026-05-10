# Stage 1 iOS L11 Conditional Renderer Evidence Refresh

- Batch: iOS live lane bounded validation/evidence batch
- Generated: 2026-05-06 08:02 Asia/Shanghai
- Scope: `ios/**` only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Todo snapshot: `Docs/todos_20260505.md`

## Batch Selection

The daily todo snapshot leaves the earliest iOS-owned open cluster in L11:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current iOS implementation uses native rich fallback cards for Mermaid/math instead of vendored JS/CSS/font renderers or a WKWebView rich surface. This makes the three conditional renderer gates not applicable for the active runtime, provided the repository continues to prove:

- no production renderer assets are discovered under `ios/**`
- no production WebKit rich-renderer source is detected
- future vendored renderer modes require local packaging, request blocking, bundle-resource declaration, and SHA-256 manifest verification before they can satisfy the same checklist

## Implementation Evidence

Existing iOS implementation and tests covering this batch:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Relevant automated coverage includes:

- `IOSRendererAssetInventory.discover(iosRoot:)`
- `IOSLocalRendererConditionalGateAudit`
- `IOSConditionalRendererGateEvidenceBuilder`
- `IOSRendererAssetManifestHashAudit`
- `IOSRendererBundleResourceDeclarationAudit`
- `IOSRichRendererRequestBlockingPolicy`
- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems`
- `testIOSL11CurrentRepositoryConditionalRendererGatesAreSupervisorReady`
- `testIOSL11ConditionalRendererEvidenceBuilderAcceptsRequestBlockedWKWebViewMode`
- `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`
- `testIOSL11RendererBundleResourceDeclarationAuditRequiresPackageResourceCoverage`
- `testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames`

Current inventory command checked by the L11 tests:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Current result for production iOS sources: no renderer asset files are present.

## Validation

Commands run from `/Users/wangweiyang/GitHub/fastmd/ios` unless noted otherwise.

```bash
swift test --filter FastMDMobileCoreTests/testIOSL11
```

Result: pass. Executed 59 tests, 0 failures.

```bash
swift test
```

Result: pass. Executed 186 tests, 0 failures.

```bash
xcrun simctl list devices available | rg 'iPhone 12'
```

Result: pass. Exact iPhone 12 simulator destination is available:

```text
iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
```

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result: pass. Xcode built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` and ended with `BUILD SUCCEEDED`.

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result: pass. Executed 186 tests, 0 failures on the iPhone 12 simulator destination and ended with `TEST SUCCEEDED`.

```bash
git -C .. diff --check -- ios
```

Result: pass. No whitespace errors reported.

## Supervisor Completion Recommendations

The supervisor can mark these L11 iOS checklist items complete with this evidence path:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Evidence path:

- `ios/docs/reports/stage1-ios-l11-conditional-renderer-evidence-refresh-20260506-0802.md`

Supporting implementation/test paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Platform Validation Notes

This batch does not claim the L12 physical iPhone 12-family real-device validation gate. That gate remains open until a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 open, render, search, edit, save, and rotate flow with recorded manual evidence.
