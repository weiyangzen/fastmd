# Stage 1 iOS L11 Conditional Renderer Native Fallback Refresh - 2026-05-06 05:55 +0800

## Scope

- Lane: FastMD Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Selected batch: refresh the earliest open iOS-owned L11 conditional renderer evidence for the native fallback renderer path.
- Root `Docs/**`, `android/**`, and `.cron/**` were not edited.

## Implementation Evidence

- Native iOS implementation remains Swift/SwiftUI/UIKit oriented under `ios/Sources/FastMDMobileCore/**`.
- Ordinary Markdown and rich fallback blocks remain native:
  - Mermaid and math render as safe native source/readable fallback cards.
  - No production JS/CSS/font/HTML renderer assets are present under app/source resource paths.
  - No production WKWebView rich renderer source is imported or constructed under `ios/Sources`.
- Existing automated L11 gate implementation covers both the current native fallback mode and future conditional modes:
  - Native fallback not-applicable gate evidence: `IOSLocalRendererConditionalGateAudit`.
  - Renderer asset inventory and SHA-256 manifest checks: `IOSRendererAssetInventory` and `IOSRendererAssetManifestHashAudit`.
  - WKWebView request-blocking policy checks if a future local rich renderer surface is introduced: `IOSRichRendererRequestBlockingPolicy`.
  - Supervisor-facing checklist recommendations: `IOSConditionalRendererChecklistEvidence`.

## Renderer Asset Inventory

Command from repository root:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.html' -o -iname '*.htm' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' \) -print | sort
```

Result:

- PASS: empty output.
- Evidence meaning: no production iOS JS/CSS/font/HTML renderer asset is currently bundled or source-adjacent outside ignored build/test/report/screenshot paths.

## Validation

Command from `ios/`:

```bash
swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRenderer
```

Result:

- PASS: 16 tests executed, 0 failures, 0 unexpected failures.

Command from `ios/`:

```bash
swift test
```

Result:

- PASS: 169 tests executed, 0 failures, 0 unexpected failures.

Command from `ios/`:

```bash
xcrun simctl list devices available | rg 'iPhone 12'
```

Result:

- PASS: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` is available for simulator validation.

## Supervisor Checklist Recommendations

The supervisor can mark these iOS L11 checklist items complete based on the implemented automated gates plus this validation evidence:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Current status: satisfied as `notApplicableNativeFallback`.
  - Evidence: no production renderer assets were discovered; future vendored local bundle mode has packaging/offline gate tests.
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Current status: satisfied as `notApplicableNativeFallback`.
  - Evidence: no WKWebView rich surface is active; future WKWebView mode has explicit request-blocking policy tests for remote URLs, external navigation, `javascript:`, `data:`, iframe, and bundle-root traversal behavior.
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Current status: satisfied as `notApplicableNativeFallback`.
  - Evidence: no vendored renderer assets were discovered; future vendored asset mode has exact path, byte-count, duplicate-path, platform-local path, bundled-resource path, and SHA-256 verification tests.

## Remaining Boundary

- This batch does not claim physical iPhone 12-family real-device validation.
- The real-device gate remains open until a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 open, render, search, full-source edit, block edit, save, and rotate flow with recorded manual evidence.
