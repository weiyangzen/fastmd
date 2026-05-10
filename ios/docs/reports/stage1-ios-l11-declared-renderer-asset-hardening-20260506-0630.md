# Stage 1 iOS L11 Declared Renderer Asset Hardening - 2026-05-06 06:30 CST

Worker: FastMD Stage 1 Mobile iOS live lane

Scope: one bounded iOS-only implementation batch. No Android files, root Docs checklist files, or `.cron/**` files were edited.

## Batch Selection

The earliest still-open iOS-owned surface in `Docs/todos_20260505.md` is L11 conditional renderer automation:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

This batch tightens the first conditional gate for future vendored renderer mode. The current production runtime remains native fallback only, with no production JS/CSS/font/HTML renderer assets and no production WebKit rich renderer source.

## Implementation Evidence

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
  - Added `LocalRichRendererRuntimeAudit.allowedDeclaredAssetExtensions`.
  - Added `LocalRichRendererRuntimeAudit.declaredAssetNamesAreLocalBundleReferences`.
  - Changed vendored renderer `packagingStatus` so it remains `missingLocalAssets` unless declared asset names are safe bundled-relative references.
  - Rejected remote schemes, `javascript:` / `data:`-style names, absolute paths, traversal, backslashes, query strings, fragments, whitespace-padded names, and unsupported extensions before the runtime can claim packaged local assets.

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - Added coverage for valid nested bundled renderer references such as `mermaid/mermaid.min.mjs`, `math/katex.min.css`, `math/fonts/katex-main.woff2`, and `details/details-renderer.htm`.
  - Added coverage proving unsafe declared renderer asset names keep `packagingStatus == .missingLocalAssets` and `canRenderStageOneRichBlocksOffline == false`.

## Current Renderer Inventory

Command:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result: PASS. Empty output. No production iOS JS/CSS/font/HTML renderer assets were found outside ignored build, test, report, and screenshot trees.

## Validation

| Command | Result |
| --- | --- |
| `swift test --filter FastMDMobileCoreTests/testVendoredRichRendererRuntimeAudit` from `ios/` | PASS. 2 tests executed, 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRenderer` from `ios/` | PASS. 18 tests executed, 0 failures. |
| `swift test` from `ios/` | PASS. 175 tests executed, 0 failures. |
| `git diff --check -- ios` from repository root | PASS. No whitespace errors. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS. Available simulator: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS. Build ended with `BUILD SUCCEEDED`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS. 175 tests executed, 0 failures, test ended with `TEST SUCCEEDED`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_06-29-21-+0800.xcresult`. |
| `xcrun xctrace list devices` and `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical iPhone 12-family validation. Probes reported no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. Observed physical devices were unavailable and not iPhone 12-family hardware. |

## Supervisor Checklist Recommendations

The supervisor can use this report, together with the existing L11 conditional renderer XCTest implementation, as additional evidence for:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Current runtime: not applicable native fallback because no production renderer assets are present.
  - Future vendored mode: packaging now requires safe bundled-relative declared asset names and rejects remote, traversal, absolute, query, fragment, and unsupported references.

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Current runtime: not applicable native fallback because no production WebKit rich renderer source or WKWebView rich surface is active.
  - Future WKWebView mode remains covered by the existing request-blocking policy tests.

- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Current runtime: not applicable native fallback because no production renderer assets are present.
  - Future vendored mode remains covered by existing exact manifest, SHA-256, byte-count, duplicate, remote, loose path, and tamper rejection tests.

- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.

- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 175 tests and 0 failures.

- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this platform-local report.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Blocker: no connected physical iPhone 12-family hardware was available for the manual open, render, search, edit, save, and rotate flow.
