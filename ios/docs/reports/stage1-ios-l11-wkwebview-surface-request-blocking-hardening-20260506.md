# Stage 1 iOS L11 WKWebView Surface Request-Blocking Hardening - 2026-05-06

## Scope

One bounded iOS-owned implementation batch for the earliest still-open iOS checklist cluster in the Stage 1 blueprint:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

No Android files, root `Docs/**` files, or `.cron/**` files were changed.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Tests:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l11-wkwebview-surface-request-blocking-hardening-20260506.md`

## Implementation Evidence

- Added `IOSLocalRendererConditionalGateAudit.wkWebViewRichSurfacesAreRequestBlocked`.
- Added `IOSLocalRendererConditionalGateAudit.richFallbackSurfacesSatisfyRendererPolicy`.
- Tightened `wkWebViewRequestBlockingGateStatus` so a future local WKWebView rich surface is not considered satisfied from release posture alone. The rendered rich fallback surface must also:
  - use `.localWKWebView`;
  - not claim native safe-card rendering;
  - require vendored renderer assets;
  - block network requests;
  - block external navigation;
  - block remote subresources.
- Updated `satisfiesStageOneConditionalRendererGates` to accept either the current native safe-card path or a future request-blocked local WKWebView rich surface with packaging and manifest gates satisfied.
- Added two focused XCTest cases:
  - `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
  - `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`

Current iOS runtime remains native fallback-only for Mermaid/math rich blocks. This batch did not introduce WebKit imports, `WKWebView` construction, JavaScript, CSS, HTML, font renderer assets, CDN dependencies, remote rendering, app entitlements, Info.plist changes, privacy manifests, or background modes.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRenderer` from `ios/` | PASS | Built `FastMDMobileCore` and executed 8 focused L11 conditional renderer tests, 0 failures. |
| `swift test` from `ios/` | PASS | Executed 144 tests, 0 failures. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repo root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `rg -n "^(import WebKit)\|WKWebView\(" ios/Sources/FastMDMobileCore` from repo root | PASS | Exit code 1 with no matches. No active WebKit import or WKWebView construction exists under iOS sources. |
| `git diff --check -- ios` from repo root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L13: `Record validation reports under ios/docs/reports/.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-wkwebview-surface-request-blocking-hardening-20260506.md`

Keep open:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

This batch ran SwiftPM validation only. It did not run xcodebuild simulator/device validation.
