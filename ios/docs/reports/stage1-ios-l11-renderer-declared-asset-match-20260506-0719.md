# Stage 1 iOS L11 Renderer Declared Asset Match Batch

- Generated: 2026-05-06T07:19:53+08:00
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Blueprint source read: `Docs/Stage1_Mobile_Blueprint.md`
- Todo snapshot read: `Docs/todos_20260505.md`

## Batch Selection

The daily todo snapshot marks L1-L10 complete. The earliest iOS-owned open work remains L11 conditional renderer validation for renderer assets and local WKWebView surfaces.

This batch hardens the local renderer packaging/offline contract for any future vendored JS/CSS/font renderer assets. A vendored renderer mode now passes only when:

- declared renderer asset names are valid local bundle references
- discovered renderer asset paths are iOS-local bundled `FastMDRenderers` resources
- every declared asset is discovered under an allowed bundled renderer resource root
- every discovered bundled renderer asset is covered by the declared asset list

The current production iOS path is unchanged: rich Mermaid/math fallback blocks remain native safe cards, with no JS/CSS/font/HTML renderer assets and no WKWebView rich surface.

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-renderer-declared-asset-match-20260506-0719.md`

## Implementation Evidence

- Added `IOSLocalRendererConditionalGateAudit.declaredRendererAssetNamesMatchDiscoveredBundledAssets`.
- Updated `localRendererPackagingGateStatus` so future vendored renderer packaging fails closed on declared/discovered asset mismatch.
- Added XCTest coverage for:
  - discovered bundled asset missing from declarations
  - declared asset missing from discovered bundled assets
  - matching declared/discovered bundled JS and CSS assets
- Re-ran the production renderer asset inventory command. It returned no production JS/CSS/font/HTML renderer assets:

```sh
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result: empty output.

## Validation Commands

All commands were run from `ios/` on 2026-05-06.

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRendererPackagingGateRequiresDeclaredAssetsToMatchDiscoveredBundleAssets` | PASS | 1 XCTest case, 0 failures. |
| `swift test` | PASS | 179 XCTest cases, 0 failures, completed in 7.637 seconds. |

## Checklist Evidence

| Blueprint checklist item | Suggested status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | COMPLETE | Future vendored asset mode now fails closed unless declared asset names exactly match discovered bundled renderer assets; focused test and full `swift test` pass. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | COMPLETE | The existing manifest/hash gate remains required when assets are discovered, and this batch adds the missing declared/discovered asset-name match precondition before packaging can pass. |

## Gates To Keep Open

| Blueprint checklist item | Status | Reason |
| --- | --- | --- |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | Already covered by existing evidence; no new WKWebView implementation was added in this batch. |
| Run iOS iPhone 12-class real-device validation before parity-complete release claim. | OPEN | This batch did not run physical-device validation; previous reports record that no connected physical iPhone 12-family device was available. |
