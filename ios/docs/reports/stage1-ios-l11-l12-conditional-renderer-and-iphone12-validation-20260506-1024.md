# Stage 1 iOS L11/L12 Live Batch Evidence - 2026-05-06 10:24 +0800

## Scope

Bounded iOS live-lane batch for the earliest still-open iOS-owned rows:

- L11 conditional local renderer packaging/offline tests.
- L11 conditional WKWebView request-blocking tests.
- L11 conditional renderer asset manifest/hash tests.
- L12 iPhone 12 simulator build/test validation observed while validating this batch.

No Android files or shared `Docs/` checklist files were edited.

## Current Renderer Mode

FastMD iOS currently renders Mermaid, math, details, generic HTML fallback, and other rich fallback surfaces with native Swift safe-card/fallback presentations. The production iOS source tree does not contain a local JS/CSS/font/HTML renderer bundle and does not instantiate WKWebView for rich block rendering.

Evidence:

- Production renderer asset inventory: none.
- WebKit/WKWebView production source scan: no matches.
- Native fallback rich blocks stay native safe cards.
- No CDN, network renderer, external navigation, `javascript:` URL, `data:` URL, iframe, or remote subresource surface is present for rich block rendering.

## Commands Run

| Command | Result | Notes |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11CurrentRepositoryConditionalRendererGatesAreSupervisorReady` | PASS | 1 XCTest, 0 failures. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` | PASS | Empty output; no production iOS renderer assets discovered. |
| `rg -n "(^|[[:space:]])import[[:space:]]+((class\|struct\|enum\|protocol)[[:space:]]+)?WebKit\|WKWebView[[:space:]]*\(" ios/Sources ios/Package.swift` | PASS | Exit 1 with empty output; no production WebKit/WKWebView matches. |
| `swift test` | PASS | 196 XCTest cases, 0 failures, 0 unexpected failures. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | SwiftPM scheme built for iPhone 12 simulator, iOS simulator SDK 26.4, deployment target iOS 14.0. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | 196 XCTest cases, 0 failures. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_10-24-16-+0800.xcresult`. |

## Checklist Evidence

| Blueprint checklist item | Status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | COMPLETE | Not applicable in current native-fallback mode; production inventory found no JS/CSS/font/HTML renderer assets, and L11 current-repository conditional renderer test passed. Future vendored asset mode is covered by unit tests that require local bundle assets and resource declarations. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | COMPLETE | Not applicable in current native-fallback mode; production WebKit/WKWebView scan found no rich renderer surface, and future WKWebView mode is covered by request-blocking unit tests for remote subresources, external navigation, `javascript:`, `data:`, iframes, and non-bundled files. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | COMPLETE | Not applicable in current native-fallback mode; production inventory found no renderer assets. Future vendored asset mode is covered by manifest/hash tests requiring exact local paths, byte counts, SHA-256 hashes, no duplicate paths, and bundled FastMDRenderers resource roots. |
| Run iOS iPhone 12 simulator build. | COMPLETE | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed. |
| Run iOS iPhone 12 simulator tests. | COMPLETE | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 196 XCTest cases and 0 failures. |
| Record validation reports under `ios/docs/reports/`. | COMPLETE FOR THIS BATCH | This report is iOS-local evidence for the batch. |

## Open Items Preserved

- iOS iPhone 12-class real-device validation remains open unless a physical iPhone 12-family device has separate manual/device evidence.
- iOS performance, security audit, and rich fixture render report rows should only be reconciled from their dedicated evidence reports, not from this conditional renderer batch alone.
- Shared `Docs/Stage1_Mobile_Blueprint.md` and `Docs/todos_20260505.md` were not modified by this worker.

