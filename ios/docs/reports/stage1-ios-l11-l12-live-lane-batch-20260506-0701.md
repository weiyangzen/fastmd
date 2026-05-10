# Stage 1 iOS Live Lane Batch - L11 Conditional Renderer And L12 Simulator Evidence

- Generated: 2026-05-06 07:01 Asia/Shanghai
- Worker scope: iOS only
- Blueprint source read: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot read: `Docs/todos_20260505.md`
- Changed implementation scope: platform-local iOS evidence only, because the earliest still-open iOS-owned checklist items are conditional validation/reporting gates and the native Swift renderer path already exists.

## Batch Selection

The daily todo snapshot lists the remaining iOS-relevant open cluster as:

- L11 conditional renderer gates:
  - Add local renderer packaging/offline tests if JS renderer assets are used.
  - Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12 iOS simulator/device validation gates and reports.

This batch closes fresh evidence for the L11 iOS conditional renderer gates and refreshes L12 iPhone 12 simulator build/test evidence. It does not touch Android, shared Docs, or cron files.

## Current Renderer Posture

The current iOS Stage 1 renderer path is native Swift:

- Ordinary Markdown blocks render through `MarkdownParserAdapter` and `MarkdownNativeRenderer`.
- Mermaid and math blocks render as native safe source cards.
- No JS/CSS/font/HTML renderer assets are present in production iOS paths.
- No active WKWebView rich rendering code is present in `ios/Sources`.
- WKWebView/request-blocking policy tests still exist for future local renderer mode, but the current production path does not require those conditional assets.

Source inventory commands run from repository root:

```bash
find ios/Sources -name '*.swift' -type f | sort | wc -l
```

Result:

```text
9
```

```bash
find ios -path '*/.build' -prune -o -path '*/docs/reports' -prune -o -path '*/docs/screenshots' -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result:

```text
no production renderer assets found
```

```bash
rg -n "^\s*import\s+WebKit\b|WKWebView\s*(\(|\.)" ios/Sources --glob '*.swift'
```

Result:

```text
no production WebKit/WKWebView rich renderer source found
```

## L11 Conditional Renderer Checklist Evidence

Automated focused validation:

```bash
cd ios && swift test --filter IOSL11Conditional
```

Result:

```text
PASS - 19 tests, 0 failures
```

Full SwiftPM validation:

```bash
cd ios && swift test
```

Result:

```text
PASS - 178 tests, 0 failures
```

Relevant passing test coverage includes:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines`
- `testIOSL11ConditionalRendererEvidenceBuilderProducesReproducibleNativeFallbackReport`
- `testIOSL11ConditionalRendererReportCapturesNativeFallbackEvidence`
- `testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems`
- `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`
- `testIOSL11RendererInventoryIgnoresWebKitNamesInsideCommentsAndStrings`
- `testIOSL11RendererInventoryDetectsRealWebKitImportAndWKWebViewConstruction`
- `testIOSL11ConditionalRendererPackagingGateRejectsLooseLocalAssets`
- `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
- `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`

Current gate statuses:

| Blueprint checklist item | Current iOS status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | Satisfied as not applicable for current native fallback path | No production JS/CSS/font/HTML renderer assets found; Swift tests cover native fallback and future asset-required mode. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | Satisfied as not applicable for current native fallback path | No production WebKit/WKWebView rich surface found; Swift tests cover request-blocked WKWebView mode if introduced later. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | Satisfied as not applicable for current native fallback path | No production vendored renderer assets found; Swift tests require manifest/hash verification when assets exist. |

## L12 iPhone 12 Simulator Evidence

The blueprint iOS simulator commands were run from `ios/`.

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result:

```text
PASS - ** BUILD SUCCEEDED **
```

Notes:

- Xcode resolved the SwiftPM package at `/Users/wangweiyang/GitHub/fastmd/ios`.
- The build used the iPhone Simulator SDK and iOS simulator deployment target 14.0.
- Xcode emitted `IDERunDestination: Supported platforms for the buildables in the current scheme is empty`, but this was non-fatal and the build succeeded.

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result:

```text
PASS - ** TEST SUCCEEDED **
PASS - 178 tests, 0 failures
```

Xcode result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_07-01-39-+0800.xcresult
```

## Still Open / Not Claimed

This batch does not claim iPhone 12-class real-device validation. No physical iPhone 12-family hardware validation was run in this batch.

This batch does not claim Instruments or real-device `os_signpost` timing snapshots. Existing XCTest performance coverage remains separate from the real-device performance gate.

## Supervisor Completion Recommendations

The supervisor can mark the following blueprint checklist items complete based on this report and the passing validation commands above:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12: Run iOS iPhone 12 simulator build.
- L12: Run iOS iPhone 12 simulator tests.
- L13: Record validation reports under `ios/docs/reports/`.

Evidence path:

```text
ios/docs/reports/stage1-ios-l11-l12-live-lane-batch-20260506-0701.md
```
