# Stage 1 iOS L11 Conditional Renderer Evidence Refresh - 2026-05-06 04:06 CST

## Scope

One bounded iOS live-lane batch for the earliest still-open iOS-owned checklist cluster in the daily todo snapshot:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Changed files are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, production Swift source, XCTest source, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Implementation Evidence

The current iOS implementation remains native Swift package code with native Markdown rendering and native safe-card fallbacks for rich blocks such as Mermaid and math. No JS/CSS/font/HTML renderer asset is present under `ios/`, and no production source file imports WebKit or constructs `WKWebView`.

Existing iOS implementation and tests that support the three conditional L11 gates:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
  - `IOSRendererAssetInventory` discovers JS/CSS/font/HTML renderer assets and scans Swift sources for active rich-renderer WebKit use.
  - `IOSRendererAssetManifestHashAudit` verifies exact platform-local bundled renderer asset paths, positive byte counts, no duplicate manifest paths, and SHA-256 hash equality.
  - `IOSLocalRendererConditionalGateAudit` classifies local packaging/offline, WKWebView request blocking, and renderer manifest/hash gates as not applicable, satisfied, missing, or unsafe.
  - `IOSConditionalRendererGateReport` maps the audit result directly to the three blueprint checklist lines.
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - Current native fallback tests prove the three gates are not applicable for this runtime because no vendored renderer assets or WKWebView rich surface are active.
  - Future-trigger tests prove the gates become required when vendored JS/CSS/font assets or WKWebView rich surfaces are introduced.
  - Manifest tests accept exact bundled local assets and reject missing, tampered, duplicate, remote, and loose local asset paths.
  - WKWebView policy tests reject unsafe rich surfaces and accept only request-blocked local bundled surfaces.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11Conditional` from `ios/` | PASS | Executed 11 focused L11 conditional renderer tests with 0 failures. Covered native-fallback non-applicability, future asset-triggered manifest/hash gates, loose asset rejection, unsafe WKWebView rejection, request-blocked local WKWebView acceptance, report generation, and blueprint checklist mapping. |
| `swift test` from `ios/` | PASS | Executed 153 tests with 0 failures. This is the minimum required SwiftPM validation for the current iOS skeleton. |
| `xcodebuild test -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12'` from `ios/` | PASS | SwiftPM-generated scheme built and tested on the available iPhone 12 simulator. Executed 153 tests with 0 failures. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_04-06-17-+0800.xcresult`. |
| `find ios -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `rg -n "^\s*import\s+WebKit\b|\bWKWebView\s*\(" ios/Sources` from repository root | PASS | Empty output. No production iOS source imports WebKit or constructs `WKWebView`. |
| `rg -n "^\s*import\s+WebKit\b|\bWKWebView\s*\(" ios/Sources ios/Tests` from repository root | PASS with expected test-only matches | Matches are synthetic Swift source strings inside XCTest methods that deliberately verify WebKit detection behavior: lines 3067, 3116, 3120, and 3217 of `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`. No production source match exists. |

## Gate Interpretation

| Blueprint checklist item | Current iOS status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | Satisfied / not applicable for native fallback runtime | No JS/CSS/font/HTML renderer assets are present. Tests prove the current not-applicable path and prove local packaging/offline validation becomes required when vendored assets are introduced. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | Satisfied / not applicable for native fallback runtime | No production WebKit import or `WKWebView` construction is present. Tests prove unsafe WKWebView rich surfaces are blocked and request-blocked local bundled surfaces are accepted. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | Satisfied / not applicable for native fallback runtime, with future asset-path coverage implemented | No vendored renderer assets are discovered. Tests verify exact bundled local manifest and SHA-256 matching, including rejection of missing, tampered, duplicate, remote, and loose local entries. |

## Supervisor Reconciliation Recommendation

The supervisor can mark the three iOS L11 conditional renderer checklist items complete for the current native fallback implementation using this report as evidence. The triggering conditions are absent in the live iOS tree, and the existing tests also cover the required behavior if JS/CSS/font renderer assets or WKWebView rich renderer surfaces are added later.

