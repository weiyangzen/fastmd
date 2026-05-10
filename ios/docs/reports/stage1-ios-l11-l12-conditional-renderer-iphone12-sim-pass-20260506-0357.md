# Stage 1 iOS L11/L12 Conditional Renderer And iPhone 12 Simulator Pass - 2026-05-06 03:57 +0800

## Scope

Ran one bounded iOS-owned validation/reporting batch for the earliest remaining iOS checklist cluster:

- L11 conditional local renderer gates.
- L12 exact iPhone 12 simulator build.
- L12 exact iPhone 12 simulator tests.
- L12 physical iPhone 12-family real-device gate probe.

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-sim-pass-20260506-0357.md`

Existing implementation and test evidence used by this report remains in:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## L11 Conditional Renderer Gate Evidence

The iOS Stage 1 implementation remains on the native fallback path for rich blocks:

- Mermaid and math render as native safe cards.
- No JS/CSS/font/HTML renderer assets are present under `ios/`.
- No WebKit rich renderer source is active.
- Ordinary Markdown remains native.
- Existing future-path tests cover vendored bundle-only assets, request blocking, and manifest/hash enforcement if a local renderer is introduced later.

Current inventory command:

```bash
find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) | sort
```

Result:

```text
no JS/CSS/font/HTML renderer asset files found under ios/
```

Relevant XCTest coverage executed by `swift test`:

- `testIOSL11ConditionalLocalRendererGatesAreNotApplicableForNativeFallbackRuntime`
- `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`
- `testIOSL11RendererAssetInventoryDetectsBundleAssetsAndWebKitSource`
- `testIOSL11RendererAssetInventoryDetectsWhitespaceTolerantWebKitSource`
- `testIOSL11RendererAssetInventoryFindsDeepBundledRendererAssets`
- `testIOSL11RendererAssetInventoryScansAllIOSTargetSourcesByDefault`
- `testIOSL11RendererAssetManifestHashAuditAcceptsExactLocalManifest`
- `testIOSL11RendererAssetManifestHashAuditRejectsMissingTamperedOrRemoteEntries`
- `testIOSL11RendererAssetManifestHashAuditRejectsDuplicateManifestPaths`
- `testIOSL11ConditionalRendererManifestGateRequiresHashAuditWhenAssetsExist`
- `testIOSL11ConditionalRendererPackagingGateRejectsLooseLocalAssets`
- `testIOSL11ConditionalRendererWKWebViewGateBlocksUnsafeRichSurfaces`
- `testIOSL11ConditionalRendererWKWebViewGateAcceptsRequestBlockedLocalSurface`
- `testIOSL11ConditionalRendererReportCapturesNativeFallbackEvidence`
- `testIOSL11ConditionalRendererChecklistItemsMatchBlueprintOpenLines`

## L12 iPhone 12 Simulator Evidence

Exact simulator probe:

```bash
xcrun simctl list devices available | rg -n "iPhone 12|iPhone 15|Stage1|iPhone"
```

Result:

```text
iPhone 12 (26.4.1) (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
```

Exact build gate:

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result:

```text
PASS
** BUILD SUCCEEDED **
```

Exact test gate:

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result:

```text
PASS
Executed 153 tests, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

Result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_03-57-14-+0800.xcresult
```

## Physical Real-Device Probe

Required gate:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Probe commands:

```bash
xcrun xctrace list devices
xcrun devicectl list devices --json-output /tmp/fastmd-ios-devices-live-20260506.json
```

Result:

- `xcrun xctrace list devices` listed only `Mac` under connected `== Devices ==`.
- Offline devices included an unavailable iPhone 15 Pro and an unavailable iPad.
- `devicectl` returned success, but listed the same physical devices as unavailable.
- No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available.

Identifiers and serial numbers are intentionally omitted from this report because the blocker is device class and connection state.

Real-device completion remains:

```text
BLOCKED: no connected physical iPhone 12-family device was available for the Stage 1 open/render/search/edit/save/rotate flow.
```

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 153 tests with 0 failures. Includes L11 conditional renderer tests, L12 simulator report tests, security/rich fixture report tests, and real-device blocker contract tests. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|Stage1\|iPhone"` from repository root | PASS | Exact `iPhone 12` simulator was available: `1B6FEADC-308B-4069-B734-3C9C207E633F`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Xcode build completed with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Xcode test completed with `** TEST SUCCEEDED **`; 153 XCTest cases passed. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcrun xctrace list devices` from repository root | BLOCKED for real device | Command succeeded, but no connected physical iPhone 12-family device was listed. |
| `xcrun devicectl list devices --json-output /tmp/fastmd-ios-devices-live-20260506.json` from repository root | BLOCKED for real device | Command succeeded, but available physical devices were unavailable and not iPhone 12-family hardware. |

## Checklist Evidence

Supervisor can mark complete for the iOS lane:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-sim-pass-20260506-0357.md`

Supervisor should keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- Simulator validation has passed on the exact iPhone 12 destination, but the blueprint requires a connected physical iPhone 12-family device before the real-device gate can close.
