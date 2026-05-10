# Stage 1 iOS L11/L12 Live Closeout - 2026-05-06 12:15 +0800

Scope: one bounded iOS live-lane batch.

Authoritative sources read:

- `Docs/Stage1_Mobile_Blueprint.md`
- `Docs/todos_20260505.md`

Files under validation:

- `ios/Package.swift`
- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Sources/FastMDMobileCore/MarkdownNativeRenderer.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Batch Result

This batch did not change production Swift code. It records fresh platform-local evidence for already implemented iOS conditional-renderer gates and newly verified iPhone 12 simulator build/test gates.

The current iOS implementation remains native Swift/SwiftUI/UIKit-oriented core code. Mermaid/math rich blocks use native safe fallback cards in the current tree; no vendored JS/CSS/font/HTML renderer assets are present under production iOS paths.

## L11 Conditional Renderer Evidence

Current renderer mode: native fallback only.

Evidence commands:

```sh
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print | sort
```

Result: PASS. Command produced no output, meaning no production iOS JS/CSS/font/HTML renderer assets were discovered outside ignored build/test/report/screenshot paths.

```sh
rg -n '^[[:space:]]*import[[:space:]]+WebKit\b|\bWKWebView[[:space:]]*\(' ios/Sources || true
```

Result: PASS. Command produced no output, meaning no direct production `import WebKit` or `WKWebView(` construction was found.

SwiftPM test evidence:

```sh
cd ios
swift test
```

Result: PASS. Executed 204 tests, 0 failures, 0 unexpected failures, in 14.029 seconds.

Relevant passing tests include:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11ConditionalRendererPackagingGateRequiresDeclaredAssetsToMatchDiscoveredBundleAssets`
- `testIOSL11ConditionalRendererPackagingGateRequiresSwiftPMBundleResourceDeclaration`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`
- `testIOSL11ConditionalRendererWKWebViewGateRequiresExplicitRequestPolicy`
- `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
- `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
- `testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems`
- `testIOSL11CurrentRepositoryConditionalRendererGatesAreSupervisorReady`
- `testIOSL11CurrentSourceConditionalRendererCompletionEvidenceCapturesPassingValidationResults`

L11 supervisor recommendation:

| Blueprint item | Status supported by this report | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | Complete for current native-fallback tree; future vendored assets are covered by failing/required audit tests. | This report, `swift test`, no asset inventory output. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | Complete for current native-fallback tree; future WKWebView mode is covered by request-policy tests. | This report, `swift test`, no WebKit constructor/import output. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | Complete for current native-fallback tree; future vendored assets are covered by manifest/hash tests. | This report, `swift test`, no asset inventory output. |

## L12 iPhone 12 Simulator Evidence

Available destination probes:

```sh
xcrun simctl list devices available | rg 'iPhone 12|iPhone 12 Pro|iPhone 12 mini|iPhone 12 Pro Max' || true
```

Result: PASS. Found available simulator:

```text
iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
```

```sh
xcrun xctrace list devices 2>/dev/null | rg 'iPhone 12|iPhone 12 Pro|iPhone 12 mini|iPhone 12 Pro Max' || true
```

Result: PASS. Found available simulator:

```text
iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F)
```

Build command:

```sh
cd ios
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result: PASS. `** BUILD SUCCEEDED **`

Observed build details:

- Scheme: `FastMDMobile`
- Destination: `platform=iOS Simulator,name=iPhone 12`
- SDK: `iPhoneSimulator26.4.sdk`
- Deployment target emitted by build: `arm64-apple-ios14.0-simulator`
- Product target under the SwiftPM skeleton: `FastMDMobileCore`

Test command:

```sh
cd ios
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result: PASS. `** TEST SUCCEEDED **`

Simulator test summary:

- Executed 204 tests.
- Skipped 1 test.
- Failures: 0.
- Unexpected failures: 0.
- Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_12-14-08-+0800.xcresult`

The skipped test was `testIOSL11RendererAssetInventoryMatchesDocumentedCommandForCurrentTree`. It is intentionally skipped on iOS Simulator because process-based shell command parity runs under SwiftPM macOS; simulator validation still covers the same in-process inventory model.

L12 supervisor recommendation:

| Blueprint item | Status supported by this report | Evidence |
| --- | --- | --- |
| Run iOS iPhone 12 simulator build. | Complete. | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed. |
| Run iOS iPhone 12 simulator tests. | Complete. | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 204 tests, 1 intentional skip, 0 failures. |

## Real Device Gate

The iPhone 12-class real-device validation row remains open.

Probe command:

```sh
xcrun devicectl list devices
```

Result: BLOCKED for iPhone 12 real-device validation. The command reported CoreDevice provider warning text and listed no connected/available iPhone 12-family real device. The listed devices were unavailable and not iPhone 12-family hardware:

- `iPhone 15 Pro (iPhone16,1)`, unavailable.
- `iPad Pro (11-inch) (4th generation) (iPad14,4)`, unavailable.

Supervisor should not mark the iPhone 12-class real-device validation item complete from this report.

## Checklist Items Supported For Reconciliation

Supervisor can mark these blueprint checklist items complete, using this report as evidence:

- L11: Add local renderer packaging/offline tests if JS renderer assets are used.
- L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
- L12: Run iOS iPhone 12 simulator build.
- L12: Run iOS iPhone 12 simulator tests.
- L13: Record validation reports under `ios/docs/reports/`.

Supervisor should keep this item open:

- L12: Run iOS iPhone 12-class real-device validation before parity-complete release claim.
