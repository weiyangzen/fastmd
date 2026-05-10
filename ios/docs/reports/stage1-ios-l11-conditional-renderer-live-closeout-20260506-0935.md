# Stage 1 iOS L11 Conditional Renderer Live Closeout - 2026-05-06 09:35 CST

## Scope

Ran one bounded iOS-owned implementation/evidence batch for the earliest still-open
iOS checklist rows in `Docs/Stage1_Mobile_Blueprint.md`:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

This batch stayed under `ios/**`. It did not edit Android files, shared `Docs/**`,
`.cron/**`, app entitlements, privacy manifests, background modes, renderer assets,
or production WebKit runtime code.

## Current iOS Renderer Posture

- The production iOS Markdown implementation remains native Swift/SwiftUI/UIKit
  oriented.
- Ordinary Markdown blocks remain native.
- Mermaid, math, and unsupported rich blocks currently render as native safe-card
  fallbacks.
- No production JS/CSS/font/HTML renderer assets are vendored under active iOS
  production paths.
- No production `WebKit` import or `WKWebView` construction is present under
  `ios/Sources`.
- Future vendored-asset and WKWebView modes are covered by XCTest contracts before
  they can be claimed as release-safe.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Built the SwiftPM package and executed 193 XCTest cases with 0 failures. The run included current native-fallback L11 conditional renderer tests plus future-mode tests for vendored renderer assets, manifest/hash verification, and WKWebView request blocking. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No production-side iOS renderer JS/CSS/font/HTML assets were discovered. |
| `rg -n '^\s*(?:@_implementationOnly\s+)?import\s+(?:class\s+\|struct\s+\|enum\s+)?WebKit\b\|\bWKWebView\s*\(' ios/Sources` from repository root | PASS | No matches. No production iOS WebKit import or WKWebView rich-renderer construction was discovered. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. This confirms the local simulator exists for adjacent L12 gates, but this batch's completion claim is limited to the L11 conditional renderer rows above. |

## XCTest Coverage Called By This Batch

The passing `swift test` run includes these L11 conditional renderer coverage areas:

- Current-source native fallback inventory proves the three conditional rows are
  not applicable to the present runtime and can be reconciled as complete.
- Renderer asset inventory scans active iOS target sources and ignores generated
  build, test, report, and screenshot artifacts.
- Renderer asset packaging gates require declared bundled resource roots when
  JS/CSS/font/HTML renderer assets are present.
- Renderer manifest/hash gates reject missing, duplicate, remote, loose, query,
  fragment, whitespace, and tampered asset entries.
- WKWebView gates reject unsafe rich surfaces and require explicit request
  blocking before a local WebKit renderer can satisfy Stage 1.
- Request-blocking policy covers network URLs, external navigation,
  `javascript:` URLs, `data:` URLs, iframes, non-bundled file URLs, unsupported
  bundled asset types, and context mismatches.

## Supervisor Checklist Evidence

The supervisor can mark these iOS-owned L11 rows complete using this report plus
the native Swift implementation and XCTest source under `ios/`:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence path:

- `ios/docs/reports/stage1-ios-l11-conditional-renderer-live-closeout-20260506-0935.md`

## Still Open

No physical iPhone 12-family real-device validation was performed in this batch.
The L12 real-device row must stay open until connected iPhone 12-family hardware
passes the full Stage 1 open, render, search, edit, save, and rotate flow.
