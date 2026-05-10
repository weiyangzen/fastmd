# Stage 1 iOS L11 Conditional Renderer Fresh Evidence

- Generated: 2026-05-06 07:05 CST
- Worker scope: iOS only
- Blueprint source read: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo snapshot read: `Docs/todos_20260505.md`
- Batch scope: earliest open iOS-owned L11 conditional renderer gates

## Batch Selection

The daily todo snapshot still lists these iOS-owned L11 items as open:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The current iOS Stage 1 implementation uses the native Swift Markdown path. Ordinary Markdown blocks render through `MarkdownParserAdapter` and `MarkdownNativeRenderer`; Mermaid and math render as native safe-card fallbacks. No JS/CSS/font/HTML renderer assets or WKWebView rich-rendering surface are present in production iOS sources for this batch.

## Current Inventory Evidence

Command:

```bash
find ios/Sources -name '*.swift' -type f | sort | wc -l
```

Result:

```text
9
```

Command:

```bash
find ios -path '*/.build' -prune -o -path '*/docs/reports' -prune -o -path '*/docs/screenshots' -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result:

```text
no production renderer assets found
```

Command:

```bash
rg -n '^\s*import\s+WebKit\b|WKWebView\s*(\(|\.)' ios/Sources --glob '*.swift'
```

Result:

```text
no production WebKit/WKWebView rich renderer source found
```

## Implementation Evidence

Relevant iOS source/test coverage already present in this lane:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`: `LocalRichRendererAssetPolicy`, `LocalRichRendererRuntimeAudit`, and `IOSRichRendererRequestBlockingPolicy`.
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`: native safe-card fallback presentation for Mermaid/math rich blocks without vendored renderer assets.
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`: renderer asset inventory, manifest/hash audit, WKWebView request-blocking gate, conditional checklist evidence, and report generation.
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`: current native fallback audit plus future-mode tests for vendored assets, WKWebView request blocking, and manifest/hash verification.

Key passing tests from this batch:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines`
- `testIOSL11ConditionalRendererEvidenceBuilderAuditsCurrentSourceTreeFromMarkdownSource`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`
- `testIOSL11ConditionalRendererPackagingGateRejectsLooseLocalAssets`
- `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
- `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
- `testIOSL11ConditionalRendererWKWebViewGateRequiresExplicitRequestPolicy`
- `testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems`

## Validation

Focused command:

```bash
cd ios && swift test --filter IOSL11Conditional
```

Result:

```text
PASS - 19 tests, 0 failures, 0 unexpected failures
```

Full SwiftPM command:

```bash
cd ios && swift test
```

Result:

```text
PASS - 178 tests, 0 failures, 0 unexpected failures
```

No Android validation was run or claimed. No iPhone 12 simulator or physical-device validation was run in this L11-only batch; those L12 platform validation items remain governed by their dedicated evidence reports.

## Supervisor Completion Recommendations

The supervisor can mark these blueprint checklist items complete from this iOS evidence:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L13: Record validation reports under `ios/docs/reports/`.

Evidence path:

```text
ios/docs/reports/stage1-ios-l11-conditional-renderer-fresh-evidence-20260506-0705.md
```

## Still Open / Not Claimed

- L12: Run iOS iPhone 12 simulator build.
- L12: Run iOS iPhone 12 simulator tests.
- L12: Run iOS iPhone 12-class real-device validation before parity-complete release claim.
- L12: Capture iOS performance report.
- L12: Capture iOS security audit report.
- L12: Capture rich fixture render report.
