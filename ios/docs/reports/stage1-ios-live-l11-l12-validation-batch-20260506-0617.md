# Stage 1 iOS L11/L12 Live Validation Batch - 2026-05-06 06:17 CST

Worker: FastMD Stage 1 Mobile iOS live lane

Scope: iOS-owned validation and evidence only. No Android files or root Docs checklists were edited.

## Batch Selection

The earliest still-open iOS-owned checklist surface is L11 conditional local renderer automation, followed by L12 iOS validation/report evidence.

This batch validates the current native Swift fallback runtime and records fresh platform-local evidence for supervisor reconciliation.

## Changed iOS Files

- `ios/docs/reports/stage1-ios-live-l11-l12-validation-batch-20260506-0617.md`

## Renderer Asset Inventory

Command:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result: PASS. The command produced no output, so the current iOS source/package surface has no production JS/CSS/font/HTML renderer assets outside ignored build, test, report, and screenshot trees.

Current runtime conclusion:

- Ordinary Markdown rendering remains native Swift models for SwiftUI/UIKit integration.
- Mermaid and math rich surfaces render as native safe fallback cards.
- No WKWebView rich renderer source is present in the current production iOS source tree.
- L11 conditional asset packaging, WKWebView request blocking, and renderer manifest/hash gates are not applicable for the current native-fallback runtime, while future vendored-asset and WKWebView modes are covered by XCTest contract tests.

## Validation Commands

```bash
swift test --filter FastMDMobileCoreTests/testIOSL11
```

Result: PASS. Executed 48 selected L11 tests, 0 failures.

```bash
swift test
```

Result: PASS. Executed 172 tests, 0 failures.

```bash
xcrun simctl list devices available | rg 'iPhone 12'
```

Result: PASS. An available iPhone 12 simulator is present:

```text
iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
```

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result: PASS. Xcode built the SwiftPM-generated `FastMDMobile` scheme for `iPhone 12` simulator and ended with `BUILD SUCCEEDED`.

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result: PASS. Xcode ran 172 tests on the `iPhone 12` simulator destination with 0 failures and ended with `TEST SUCCEEDED`.

Result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_06-17-06-+0800.xcresult
```

```bash
xcrun xctrace list devices
xcrun devicectl list devices --json-output -
```

Result: BLOCKED for physical iPhone 12-family validation. The probes did not report any connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. Observed physical devices were unavailable or not iPhone 12-family hardware. The real-device open, render, search, edit, save, and rotate gate must stay open until eligible hardware is connected and manual flow evidence is captured.

## Supervisor Completion Recommendations

The supervisor can mark these iOS checklist items complete using this report plus the existing XCTest implementation evidence:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: `swift test --filter FastMDMobileCoreTests/testIOSL11` passed 48 L11 tests.
  - Evidence: renderer asset inventory found no production JS/CSS/font/HTML assets, so this conditional gate is not applicable for the current native-fallback runtime.
  - Implementation anchors: `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`, `testIOSL11ConditionalRendererEvidenceBuilderAuditsCurrentSourceTreeFromMarkdownSource`, and future vendored-asset packaging tests in `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`.

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: `swift test --filter FastMDMobileCoreTests/testIOSL11` passed.
  - Evidence: current runtime has no WKWebView rich surface; future WKWebView mode is covered by explicit request-blocking policy tests for remote subresources, external navigation, `javascript:` URLs, `data:` URLs, iframes, non-bundled files, and context mismatches.
  - Implementation anchors: `testIOSRichRendererRequestBlockingPolicyBlocksNetworkNavigationDataJavaScriptAndIFrames`, `testIOSL11ConditionalRendererWKWebViewGateRequiresExplicitRequestPolicy`, and `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`.

- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: `swift test --filter FastMDMobileCoreTests/testIOSL11` passed.
  - Evidence: current runtime has no vendored renderer assets; future asset mode is covered by manifest/hash audit tests for exact path matching, SHA-256/byte-count validation, duplicate rejection, missing/tampered rejection, remote rejection, and loose local path rejection.
  - Implementation anchors: `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`, `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`, `testIOSL11RendererAssetManifestHashAuditRejectsDuplicateManifestPaths`, and `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`.

- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed with `BUILD SUCCEEDED`.

- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 172 tests, 0 failures, `TEST SUCCEEDED`.

- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this report is platform-local under `ios/docs/reports/`.

Keep this iOS checklist item open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Blocker: no connected physical iPhone 12-family device is currently available. Simulator validation passed, but simulator evidence does not complete the physical-device gate.

