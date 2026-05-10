# Stage 1 iOS L11/L12 Live Lane Batch - 2026-05-06 08:38 CST

## Scope

- Worker lane: FastMD Stage 1 Mobile iOS live lane.
- Ownership respected: iOS-only evidence under `ios/docs/reports/`.
- Batch focus: close the earliest still-open iOS-owned conditional renderer gates and refresh iPhone 12 simulator validation.
- Shared files intentionally not edited: `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`.
- Android files intentionally not edited.

## Current Implementation Evidence

FastMD iOS currently uses native Swift/SwiftUI/UIKit core contracts with native rich Markdown fallbacks for Stage 1 Mermaid/math blocks.

- Ordinary Markdown remains native: headings, paragraphs, inline styles, links, lists, task lists, tables, code fences, images, horizontal rules, footnotes, details/summary fallback, and generic HTML fallback.
- Mermaid and math render as safe native fallback cards for Stage 1.
- No production iOS renderer assets were discovered outside ignored generated/test/report paths.
- No production iOS WKWebView rich-renderer implementation was detected.
- Conditional local JS/CSS/font renderer gates are therefore not-applicable for the current native-fallback runtime, while future vendored-asset and WKWebView modes are covered by automated contract tests.

Inventory command run from repository root:

```sh
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print | sort
```

Result:

- Exit code: 0.
- Output: empty.
- Interpretation: no iOS production JS/CSS/font/HTML renderer assets are present.

Relevant automated tests observed passing in this batch include:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems`
- `testIOSL11CurrentRepositoryConditionalRendererGatesAreSupervisorReady`
- `testIOSL11ConditionalRendererPackagingGateRequiresSwiftPMBundleResourceDeclaration`
- `testIOSL11ConditionalRendererPackagingGateRequiresDeclaredAssetsToMatchDiscoveredBundleAssets`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`
- `testIOSL11ConditionalRendererWKWebViewGateRequiresExplicitRequestPolicy`
- `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
- `testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames`

## Validation Results

### SwiftPM

Command:

```sh
cd ios && swift test
```

Result:

- Status: pass.
- Executed: 188 tests.
- Failures: 0.
- Timing: 8.206 seconds in XCTest output.
- Platform: `x86_64-apple-macos14.0`.

### Xcode Scheme Discovery

Command:

```sh
cd ios && xcodebuild -list
```

Result:

- Status: pass.
- Discovered scheme: `FastMDMobile`.

### iPhone 12 Simulator Availability

Command:

```sh
cd ios && xcrun simctl list devices available
```

Result:

- Status: pass.
- Available iPhone 12 simulator found: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)`, iOS 26.4 runtime, Shutdown.
- Older iOS 14.1 runtime remains unavailable locally, but the Stage 1 command validates the iPhone 12 device class against the latest installed simulator SDK/runtime.

### iPhone 12 Simulator Build

Command:

```sh
cd ios && xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result:

- Status: pass.
- Terminal marker: `** BUILD SUCCEEDED **`.
- Build target triple observed: `arm64-apple-ios14.0-simulator`.
- SDK observed: `iPhoneSimulator26.4.sdk`.

### iPhone 12 Simulator Tests

Command:

```sh
cd ios && xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result:

- Status: pass.
- Terminal marker: `** TEST SUCCEEDED **`.
- Executed: 188 tests.
- Failures: 0.
- XCTest timing: 3.761 seconds.
- Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_08-37-49-+0800.xcresult`.

## Remaining Blockers

- iPhone 12-class real-device validation remains open because this batch only had simulator validation available through local tooling.
- No parity-complete release claim should be made until a physical iPhone 12-family or equivalent A14-class device validation report is recorded.

## Supervisor Checklist Candidates

The supervisor can mark these iOS-owned checklist items complete with this report and the cited automated tests:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: current runtime is native fallback only, production renderer asset inventory is empty, and future vendored-asset packaging gates are automated.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Evidence: current runtime has no WKWebView rich surface, and future WKWebView mode is tested for bundled-only request policy plus remote/navigation/javascript/data/iframe blocking.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: current runtime has no vendored JS/CSS/font assets, and future asset mode requires manifest/hash audit when assets exist.
- L12: Run iOS iPhone 12 simulator build.
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- L12: Run iOS iPhone 12 simulator tests.
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 188 tests and 0 failures.
- L13: Record validation reports under `ios/docs/reports/`.
  - Evidence: this report.
