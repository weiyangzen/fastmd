# Stage 1 iOS L11 WKWebView Request Policy Evidence - 2026-05-06 02:02 CST

## Scope

Ran one bounded iOS-only live-lane implementation batch from `/Users/wangweiyang/GitHub/fastmd`.

Earliest still-open iOS-owned row advanced in this batch:

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`

No Android files, shared `Docs/**` files, `.cron/**` files, renderer assets, Xcode project files, entitlements, Info.plist files, privacy manifests, or background modes were edited.

## Implementation Evidence

Added an iOS-side native Swift request-blocking contract for any future local rich Markdown WKWebView surface:

- `IOSRichRendererRequestBlockingPolicy`
- `IOSRichRendererRequestContext`
- `IOSRichRendererRequestDecision`
- `IOSRichRendererRequestBlockReason`

The policy allows only `file://` requests rooted inside the bundled renderer resource directory and blocks:

- Remote HTTP/HTTPS document or subresource requests.
- External navigation.
- `javascript:` URLs.
- `data:` URLs.
- iframe loads.
- Loose local file paths outside the bundled renderer resource root.
- Missing URLs and unsupported schemes.

Current runtime remains native fallback-only:

- Mermaid and math rich blocks continue to render as native safe-card fallbacks.
- No JS/CSS/font/HTML renderer assets were introduced under `ios/`.
- No active WebKit rich renderer source is imported or constructed under `ios/Sources`.

## Test Evidence

Added XCTest coverage:

- `testIOSRichRendererRequestBlockingPolicyAllowsOnlyBundledRendererFiles`
- `testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames`

These tests verify that bundled local files are allowed while network requests, external navigation, `javascript:`, `data:`, iframe loads, and loose local files are blocked.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 141 XCTest cases with 0 failures in 1.923 seconds. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repo root | PASS | Empty output. No JS/CSS/font/HTML renderer assets found under `ios/`. |
| `rg -n "^(import WebKit)\|WKWebView\(" ios/Sources` from repo root | PASS | No matches. No active WebKit rich-renderer source usage found under `ios/Sources`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS WITH WARNING | Build targeted `arm64-apple-ios14.0-simulator` with iPhoneSimulator26.4 SDK and ended with `** BUILD SUCCEEDED **`. Xcode emitted the existing SwiftPM warning: `Supported platforms for the buildables in the current scheme is empty.` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS WITH WARNING | Executed 141 XCTest cases with 0 failures in 0.887 seconds and ended with `** TEST SUCCEEDED **`. Xcode emitted the same SwiftPM supported-platform warning. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_02-01-49-+0800.xcresult`. |

## Supervisor Checklist Mapping

Supervisor can mark complete with this evidence:

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L13: `Record validation reports under ios/docs/reports/.`

Supporting evidence path:

- `ios/docs/reports/stage1-ios-l11-wkwebview-request-policy-20260506-0202.md`

## Remaining iOS Gate

The iOS iPhone 12-class real-device validation gate remains open. This batch did not run a physical device validation flow.
