# Stage 1 iOS L11 Conditional Renderer Live Closeout

Date: 2026-05-06 10:02 Asia/Shanghai

## Scope

This live-lane batch targets the earliest open iOS-owned checklist rows in L11:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

## Current Implementation Finding

The current iOS implementation remains on the native Swift/SwiftUI/UIKit fallback path for rich Markdown blocks. Mermaid, math, details/summary, video HTML, and generic HTML are represented as native safe fallback presentations. No production iOS renderer assets are currently vendored, and no production iOS WKWebView rich-renderer surface is currently present.

Because no production JS/CSS/font/HTML renderer assets are used, the three conditional L11 rows are satisfied by native-fallback automation and remain future-guarded by tests that also exercise the vendored-asset and request-blocked WKWebView modes.

## Evidence Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | 195 tests, 0 failures |
| `swift test --filter FastMDMobileCoreTests/testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems` from `ios/` | PASS | 1 selected test, 0 failures |
| `swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRendererEvidenceBuilderAcceptsRequestBlockedWKWebViewMode` from `ios/` | PASS | 1 selected test, 0 failures |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` from repo root | PASS | No production renderer asset paths printed |
| `rg -n "^[[:space:]]*import[[:space:]]+(@[A-Za-z0-9_]+[[:space:]]+)*(typealias\|class\|enum\|func\|let\|protocol\|struct\|var[[:space:]]+)?WebKit\\b\|\\bWKWebView[[:space:]]*(\\(\|\\.)" ios/Sources --glob '*.swift'` from repo root | PASS | Exit 1 with no matches, meaning no production WebKit/WKWebView rich-renderer source was found |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | 195 tests, 0 failures; `** TEST SUCCEEDED **`; xcresult at `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_10-02-42-+0800.xcresult` |

## Supervisor Checklist Recommendation

The supervisor can mark these iOS-owned blueprint rows complete using this report plus the passing test evidence above:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

The recommendation is limited to L11 conditional renderer automation. It does not claim the iPhone 12-family physical-device validation gate.

Additional L12 note: the documented iPhone 12 simulator build and test commands also passed during this batch. The real-device validation gate remains open until physical iPhone 12-family manual evidence exists.
