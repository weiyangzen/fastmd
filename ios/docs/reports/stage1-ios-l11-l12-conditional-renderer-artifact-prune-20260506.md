# Stage 1 iOS L11/L12 Conditional Renderer Artifact Prune - 2026-05-06

## Scope

This bounded iOS live-lane batch stayed inside `ios/**`.

Changed iOS files:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-artifact-prune-20260506.md`

No Android files, root `Docs/**` files, `.cron/**` files, renderer assets, WebKit renderer code, entitlements, Info.plist files, privacy manifests, or background modes were edited.

## Implementation

- Hardened `IOSRendererAssetInventory.discover` to prune generated/non-product iOS paths while walking the package:
  - `ios/.build`
  - `ios/docs/reports`
  - `ios/docs/screenshots`
- Kept production renderer asset detection active for real iOS bundled renderer resource roots:
  - `ios/Resources/FastMDRenderers/`
  - `ios/Sources/FastMDMobile/Resources/FastMDRenderers/`
  - `ios/Sources/FastMDMobileCore/Resources/FastMDRenderers/`
- Added XCTest coverage proving generated SwiftPM output, validation reports, and screenshot placeholders do not falsely reopen the conditional renderer gates.
- Added XCTest coverage proving the current native fallback renderer mode still satisfies the three conditional L11 gates with no discovered renderer assets and no WKWebView rich surface.

## Current Renderer Posture

- Ordinary and rich Markdown rendering remains native Swift model/presentation code.
- Mermaid/math rich blocks remain safe native fallback cards in this Stage 1 implementation.
- No JS/CSS/font/HTML renderer assets are present under product iOS paths.
- No `import WebKit` or `WKWebView` production rich-renderer surface is present under `ios/Sources`.
- Future vendored renderer assets and WKWebView surfaces remain covered by existing positive and negative tests:
  - vendored assets must be under approved bundled `FastMDRenderers` roots;
  - manifest paths must exactly match discovered assets;
  - SHA-256 hashes and byte counts must match;
  - WKWebView rich surfaces must block network requests, external navigation, `javascript:` URLs, `data:` URLs, iframes, remote subresources, and non-bundled local files.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetInventory --filter FastMDMobileCoreTests/testIOSL11ConditionalRenderer` from `ios/` | PASS | 25 focused L11 renderer inventory/conditional renderer tests, 0 failures. Includes new generated-artifact prune coverage. |
| `swift test` from `ios/` | PASS | 166 XCTest cases, 0 failures. |
| `find ios -path 'ios/.build' -prune -o -path 'ios/docs/reports' -prune -o -path 'ios/docs/screenshots' -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No product-path JS/CSS/font/HTML renderer assets discovered under `ios/`. |
| `rg -n "^\s*import\s+WebKit\b\|\bWKWebView\s*(\|\.)" ios/Sources` from repository root | PASS | Exit 1 with no matches. No production WebKit rich-renderer source was found. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from repository root | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **` for the SwiftPM package scheme targeting `arm64-apple-ios14.0-simulator`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; 166 XCTest cases, 0 failures. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_05-21-57-+0800.xcresult`. |

## Blueprint Checklist Evidence

Supervisor can mark these iOS-owned checklist items complete based on this report plus the tests above:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: current native fallback mode has no product-path JS/CSS/font/HTML renderer assets; tests prove generated artifacts are pruned and future vendored assets require local bundled packaging.
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: current native fallback mode has no production WebKit rich renderer; tests prove future WKWebView rich surfaces must be request-blocked.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: current native fallback mode has no vendored assets; tests prove future assets require exact bundled path, byte count, and SHA-256 manifest matching.
- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 166 XCTest cases and 0 failures.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this file.

## Still Open

- L12 iOS iPhone 12-class real-device validation remains open; this batch only validated the local iPhone 12 simulator.
- App Store/release-device parity should not be claimed from this report alone.
