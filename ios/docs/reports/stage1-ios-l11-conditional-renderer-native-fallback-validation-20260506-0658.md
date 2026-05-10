# Stage 1 iOS L11 Conditional Renderer Native Fallback Validation - 2026-05-06 06:58 +0800

## Scope

Ran one bounded iOS-owned evidence batch for the earliest still-open iOS checklist cluster in `Docs/Stage1_Mobile_Blueprint.md`: L11 conditional renderer automation.

This batch stayed inside `ios/**`. It did not edit Android files, root `Docs/**`, `.cron/**`, Swift sources, XCTest sources, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, WebKit runtime code, or network renderer behavior.

## Current Implementation Evidence

The current iOS implementation remains native Swift/SwiftUI/UIKit-oriented core code. Mermaid, math, and unsafe HTML surfaces are represented by native fallback contracts and sanitized native presentations; no production WKWebView rich renderer is active.

Existing implementation and test evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift` contains the renderer asset inventory, SHA-256 manifest audit, conditional renderer gate audit, report/evidence builder, and WKWebView request-blocking policy models.
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift` contains current-source native fallback tests, future vendored renderer asset tests, manifest/hash rejection tests, and WKWebView request-blocking policy tests.
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift` keeps Mermaid/math as native safe-card fallbacks and does not require bundled JS/CSS/font renderer assets.

## Source Tree Probes

| Probe | Result | Evidence |
| --- | --- | --- |
| Production renderer asset inventory | PASS | `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.html' -o -iname '*.htm' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' \) -print \| sort` returned empty output. No production JS/CSS/font/HTML renderer assets are present under `ios/`. |
| Production WebKit surface scan | PASS | `rg -n "^[[:space:]]*import[[:space:]]+WebKit\|WKWebView[[:space:]]*\(" ios/Sources` returned no matches. Exit code was 1 because ripgrep found no production WebKit imports or `WKWebView(` construction sites. |

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 52 focused L11 XCTest cases with 0 failures. Covered current native fallback evidence, conditional renderer checklist matching, renderer asset inventory, WebKit source scanning, bundled asset acceptance, loose asset rejection, manifest/hash verification, WKWebView request-blocking policy, malicious fixtures, remote image privacy, layout safety, performance, memory, accessibility, diagnostics redaction, and recovery gates. |
| `swift test` from `ios/` | PASS | Executed 178 XCTest cases with 0 failures. This is the minimum SwiftPM validation required while the iOS lane remains a SwiftPM skeleton. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors were reported after adding this report. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: current source tree uses native fallback only and has zero production JS/CSS/font/HTML renderer assets. Existing tests cover native-fallback not-applicable status plus future vendored-asset packaging requirements.
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: current source tree has no production WebKit rich renderer surface. Existing tests cover native-fallback not-applicable status plus future WKWebView request-blocking requirements for network, external navigation, `javascript:`, `data:`, iframe, non-bundled file, and unsupported asset-type requests.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: current source tree has no vendored renderer assets. Existing tests cover native-fallback not-applicable status plus future manifest/hash acceptance and rejection cases, including missing, tampered, duplicate, remote, query/fragment, whitespace, and loose local asset paths.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this report is platform-local under `ios/docs/reports/`.

Evidence path:

- `ios/docs/reports/stage1-ios-l11-conditional-renderer-native-fallback-validation-20260506-0658.md`

## Still Open

This batch does not complete the physical iPhone 12-family real-device gate. That remains blocked until connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max hardware is available for the required open, render, search, edit, save, and rotate flow.
