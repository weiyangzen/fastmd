# Stage 1 iOS L11 WKWebView Request Policy Gate Batch

- Generated: 2026-05-06T05:33:00+08:00
- Lane: Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Blueprint area: L11 automated test gates, conditional local renderer request-blocking

## Implementation

This batch tightened the iOS conditional renderer audit for any future WKWebView rich-block path.

- `IOSLocalRendererConditionalGateAudit` now carries an optional `IOSRichRendererRequestBlockingPolicy`.
- Native fallback mode remains not applicable and unchanged.
- If a WKWebView rich surface is present, the audit now requires an explicit request-blocking policy in addition to the existing rich fallback, runtime, release posture, asset packaging, and manifest/hash checks.
- The WKWebView gate now proves sample blocking for:
  - remote renderer subresource: `https://cdn.example.com/fastmd-renderer.js`
  - external navigation: `https://example.com/out`
  - `javascript:` URL
  - `data:` URL
  - iframe navigation under the bundled renderer root
- A new regression test verifies that a superficially safe WKWebView fallback still fails the L11 gate when no request-blocking policy is attached.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-wkwebview-request-policy-required-20260506-0533.md`

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRenderer` | PASS | 16 tests, 0 failures |
| `swift test` | PASS | 167 tests, 0 failures |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | 167 tests, 0 failures; `** TEST SUCCEEDED **` |

The SwiftPM skeleton generated an Xcode package scheme for `FastMDMobile`; no no-project/no-scheme blocker was hit in this environment. This batch did not run physical iPhone 12-family real-device validation, so that platform gate remains open until hardware manual-flow evidence exists.

## Checklist Evidence

Supervisor can reconcile the following iOS-owned checklist item as complete for the current implementation state:

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - New/updated tests:
    - `testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames`
    - `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
    - `testIOSL11ConditionalRendererWKWebViewGateRequiresExplicitRequestPolicy`
    - `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
    - `testIOSL11ConditionalRendererReportCapturesSatisfiedWKWebViewMode`
    - `testIOSL11ConditionalRendererEvidenceBundleAcceptsSatisfiedBundledWKWebViewMode`
  - Implementation evidence: `IOSLocalRendererConditionalGateAudit.wkWebViewRequestPolicyBlocksForbiddenRequests` is required by `richFallbackSurfacesSatisfyRendererPolicy` and `wkWebViewRequestBlockingGateStatus` whenever `usesWKWebViewRichSurface` is true.

The other two conditional renderer L11 items remain covered by existing iOS evidence and full-suite validation, but this batch only materially changed the WKWebView request-blocking gate.
