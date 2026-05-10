# Stage 1 iOS L11/L12 Live Lane Evidence

- Worker: FastMD Stage 1 Mobile iOS live lane
- Generated: 2026-05-05T22:38:14Z
- Local timezone during validation: Asia/Shanghai
- Scope: `ios/**` only
- Batch type: bounded iOS validation/evidence batch

## Summary

This batch preserves current iOS evidence for the remaining conditional renderer gates and refreshes the iPhone 12 simulator build/test gates. No Android files or shared `Docs/**` checklist files were edited.

The iOS implementation remains native Swift/SwiftUI/UIKit at this stage. Rich Mermaid/math blocks render as native safe fallback cards, with no vendored JS/CSS/font/HTML renderer assets and no WKWebView rich-rendering surface in `ios/Sources`.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 175 XCTest cases, 0 failures, 0 unexpected failures. |
| `xcodebuild -list` from `ios/` | PASS | SwiftPM exposes scheme `FastMDMobile`. |
| `xcrun simctl list devices available \| rg "iPhone 12"` | PASS | Available simulator: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **`; target built for `arm64-apple-ios14.0-simulator` using `iPhoneSimulator26.4.sdk`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | `** TEST SUCCEEDED **`; executed 175 XCTest cases, 0 failures, 0 unexpected failures. |
| `find ios \( -path 'ios/.build' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` | PASS | No production renderer asset files were discovered. |
| `rg -n "^\s*import\s+WebKit\b\|WKWebView\s*(\|\.)" ios/Sources \|\| true` | PASS | No `import WebKit` or `WKWebView` construction was found in iOS source. |

## iPhone 12 Simulator Evidence

- Scheme: `FastMDMobile`
- Destination: `platform=iOS Simulator,name=iPhone 12`
- Simulator UDID observed: `1B6FEADC-308B-4069-B734-3C9C207E633F`
- Build result: passed
- Test result: passed
- Test result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_06-37-53-+0800.xcresult`
- Test count: 175 XCTest cases
- Failure count: 0

## Conditional Renderer Evidence

Current production iOS tree:

- Vendored JS/CSS/font/HTML renderer assets: none discovered outside ignored validation artifacts.
- WKWebView rich renderer source: none discovered in `ios/Sources`.
- Rich Markdown fallback policy: Mermaid/math remain native safe fallback cards.
- Network/CDN rendering dependency: none.
- Existing unit-test evidence revalidated by `swift test` and iPhone 12 simulator `xcodebuild test`:
  - `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
  - `testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines`
  - `testIOSL11ConditionalRendererEvidenceBuilderAuditsCurrentSourceTreeFromMarkdownSource`
  - `testIOSL11ConditionalRendererReportCapturesNativeFallbackEvidence`
  - `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`
  - `testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames`

Because no local JS/CSS/font renderer assets and no WKWebView rich surface are used by production iOS code, the three L11 conditional renderer checklist items are satisfied as not-applicable native-fallback gates for the current implementation.

## Supervisor Checklist Recommendations

The supervising Docs reconciliation session can mark these items complete with this report as evidence:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: no production renderer assets discovered; native fallback gates pass in SwiftPM and iPhone 12 simulator tests.
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: no production WKWebView rich surface discovered; request-blocking policy tests still pass for future local WKWebView mode.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: no production renderer assets discovered; manifest/hash tests for future vendored mode pass.
- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 175 XCTest cases and 0 failures.

Still open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Reason: this batch did not attach or validate physical iPhone 12-class hardware.

