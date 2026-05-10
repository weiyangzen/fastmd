# Stage 1 iOS Live Lane L11/L12 Evidence Batch

Generated: 2026-05-06 07:08 Asia/Shanghai

Scope: iOS-owned evidence only. No Android files and no authoritative `Docs/` files were edited.

## Batch Selection

The daily todo snapshot shows L1 through L10 reconciled and the current iOS-open work concentrated in L11 conditional renderer gates and L12 platform validation. The canonical iOS fixture matrix is already implemented and was revalidated in this batch by `testCanonicalMarkdownFixtureMatrixExistsAndIsSeeded`.

This batch records current evidence for the earliest iOS-owned open items:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12: Run iOS iPhone 12 simulator build.
- L12: Run iOS iPhone 12 simulator tests.
- L12: Preserve blocker evidence for iOS iPhone 12-class real-device validation.

## Current Implementation Evidence

The current iOS Stage 1 implementation remains native Swift/SwiftUI/UIKit-oriented core code. Rich Mermaid/math blocks use native safe fallback cards in Stage 1; no production iOS JS/CSS/font renderer assets are currently required.

Current renderer asset inventory command:

```sh
find ios \( -path 'ios/.build' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result: no files returned.

Relevant XCTest coverage present and passing in this batch:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems`
- `testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines`
- `testIOSL11ConditionalRendererChecklistItemsExposeFutureRequiredAssetGates`
- `testIOSL11ConditionalRendererPackagingGateRejectsLooseLocalAssets`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`
- `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
- `testIOSL11ConditionalRendererWKWebViewGateRequiresExplicitRequestPolicy`
- `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
- `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`
- `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`
- `testIOSL11RendererAssetManifestHashAuditRejectsDuplicateManifestPaths`
- `testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames`

Conclusion: the three conditional L11 renderer checklist items are satisfied for the current native-fallback iOS implementation. Future introduction of vendored JS/CSS/font assets or WKWebView rich renderer surfaces is still guarded by failing tests until bundled asset packaging, request blocking, and manifest/hash audit evidence are supplied.

## Validation Commands

### SwiftPM

```sh
cd ios
swift test
```

Result: PASS.

Summary:

- Build complete.
- Executed 178 tests.
- Failures: 0.
- XCTest duration: 7.415 seconds, total suite duration 7.431 seconds.

### iPhone 12 Simulator Availability

```sh
xcrun simctl list devices available | rg 'iPhone 12'
```

Result: PASS.

Observed destination:

```text
iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
```

### Xcode Scheme Discovery

```sh
cd ios
xcodebuild -list
```

Result: PASS.

Observed scheme:

```text
FastMDMobile
```

### iPhone 12 Simulator Build

```sh
cd ios
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result: PASS.

Summary:

- Destination: `platform=iOS Simulator,name=iPhone 12`
- SDK: `iPhoneSimulator26.4.sdk`
- Target triple: `arm64-apple-ios14.0-simulator`
- Final result: `** BUILD SUCCEEDED **`

### iPhone 12 Simulator Tests

```sh
cd ios
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result: PASS.

Summary:

- Destination: `platform=iOS Simulator,name=iPhone 12`
- Executed 178 tests.
- Failures: 0.
- XCTest duration: 3.439 seconds, total suite duration 3.492 seconds.
- Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_07-07-34-+0800.xcresult`
- Final result: `** TEST SUCCEEDED **`

## Physical Device Probe

```sh
xcrun devicectl list devices --json-output -
```

Result: BLOCKED for iPhone 12-family real-device validation.

Observed physical devices:

- `Turbulence`, iPhone 15 Pro / `iPhone16,1`, unavailable.
- `wangweiyangdeiPad`, iPad Pro 11-inch 4th generation / `iPad14,4`, unavailable.

No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was reported.

```sh
xcrun xctrace list devices
```

Result: BLOCKED for iPhone 12-family real-device validation.

Observed:

- Connected host Mac only under `Devices`.
- Offline physical devices: iPhone 15 Pro and iPad Pro.
- iPhone 12 appears only under `Simulators`, not as a connected physical device.

The L12 real-device validation checklist item must remain open until a connected physical iPhone 12-family device completes the Stage 1 open, render, search, edit, save, and rotate flow with current manual evidence.

## Supervisor Checklist Recommendations

The supervising session can mark these iOS checklist items complete using this report plus the passing XCTest evidence:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: current iOS implementation uses native fallback only; renderer asset inventory returned none; conditional packaging tests pass and future vendored assets are guarded.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Evidence: current iOS source scan has no production WKWebView renderer surface; request-blocking policy tests pass for unsafe network, external navigation, `javascript:`, `data:`, iframe, and non-bundled file cases.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: no current vendored renderer assets; manifest/hash verification tests pass for satisfied, missing, tampered, duplicate, loose, query, fragment, whitespace, and remote-entry cases.
- L12: Run iOS iPhone 12 simulator build.
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- L12: Run iOS iPhone 12 simulator tests.
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed 178 tests with 0 failures.
- L13: Record validation reports under `ios/docs/reports/`.
  - Evidence: this iOS-local report.

Keep this item open:

- L12: Run iOS iPhone 12-class real-device validation before parity-complete release claim.
  - Blocker: no connected physical iPhone 12-family device was available. Current probes only found unavailable iPhone 15 Pro/iPad devices and an iPhone 12 simulator.
