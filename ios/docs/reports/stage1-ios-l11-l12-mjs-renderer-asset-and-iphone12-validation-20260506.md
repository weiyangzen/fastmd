# Stage 1 iOS L11/L12 Batch Evidence - MJS Renderer Assets And iPhone 12 Validation

- Generated: 2026-05-06T04:41:00+08:00
- Worker scope: iOS live lane, `ios/**` only
- Batch intent: close a conditional renderer asset inventory gap for JavaScript module renderer assets and refresh the smallest local iOS validation gates.

## Implementation Evidence

- Updated `IOSRendererAssetInventory.rendererAssetFileExtensions` to include `.mjs`.
- Updated `IOSRendererAssetInventory.defaultInventoryCommand` to scan `.mjs` alongside `.js`, `.css`, `.woff`, `.woff2`, `.ttf`, `.otf`, and `.html`.
- Added `testIOSL11RendererAssetInventoryTreatsJavaScriptModulesAsRendererAssets`.
- The new test creates a temporary bundled `ios/Resources/FastMDRenderers/.../*.mjs` asset, verifies discovery, byte count, SHA-256 hash, bundled resource path classification, and manifest/hash audit satisfaction.

## Renderer Asset Inventory

Command:

```bash
find ios -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) | sort
```

Result: PASS, no vendored JS/CSS/font/HTML renderer assets are currently present in the repository checkout.

Interpretation:

- Current Stage 1 iOS path remains native Swift/SwiftUI/UIKit with native safe cards for rich fallback blocks.
- If future Mermaid/math renderer assets are vendored as `.mjs`, they now enter the same platform-local bundled resource and SHA-256 manifest audit path as `.js`.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetInventoryTreatsJavaScriptModulesAsRendererAssets` | PASS | 1 XCTest, 0 failures |
| `swift test` | PASS | 159 XCTest cases, 0 failures |
| `git diff --check -- ios` | PASS | no whitespace errors |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS | iPhone 12 simulator available |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | `** TEST SUCCEEDED **`, 159 XCTest cases |
| `xcrun xctrace list devices` | BLOCKED for physical iPhone 12-family gate | no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max |
| `xcrun devicectl list devices --json-output -` | BLOCKED for physical iPhone 12-family gate | physical devices reported were unavailable and not iPhone 12-family |

Xcode test result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_04-40-02-+0800.xcresult
```

## Blueprint Checklist Evidence

The supervising session can consider the following iOS-owned checklist items complete or ready for reconciliation from this report plus the updated tests:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: `.mjs` renderer assets are now included in the inventory command and the bundled resource discovery test path; current checkout has no JS/CSS/font/HTML renderer assets, so the native fallback path remains not applicable.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: `testIOSL11RendererAssetInventoryTreatsJavaScriptModulesAsRendererAssets` verifies `.mjs` assets produce manifest entries with byte count and SHA-256 hash and satisfy `IOSRendererAssetManifestHashAudit`.
- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 159 XCTest cases.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this report is platform-local under `ios/docs/reports/`.

The following item must stay open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available in `xctrace` or `devicectl` output during this batch.

